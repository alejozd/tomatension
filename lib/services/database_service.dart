import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tension_data.dart';

class DatabaseService {
  static Database? _database;
  static Timer? _retryTimer;
  static bool _isRetryInProgress = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = await getDatabasesPath();
    final String dbPath = join(path, 'tension_data.db');
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE TensionData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sistole INTEGER,
        diastole INTEGER,
        ritmoCardiaco INTEGER,
        fechaHora TEXT
      )
    ''');

    await _createPendingSyncTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPendingSyncTable(db);
    }
  }

  Future<void> _createPendingSyncTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingSyncTensionData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER NOT NULL,
        sistole INTEGER NOT NULL,
        diastole INTEGER NOT NULL,
        ritmoCardiaco INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> migrateDataFromExternalDb(String externalDbPath) async {
    Database? externalDb;
    try {
      print('Intentando migrar datos desde: $externalDbPath');
      externalDb = await openReadOnlyDatabase(externalDbPath);
      print('Base de datos externa abierta exitosamente.');

      final List<Map<String, dynamic>> xamarinRecords = await externalDb.query(
        'TensionData',
      );
      print(
        'Se encontraron ${xamarinRecords.length} registros en la base de datos externa.',
      );

      if (xamarinRecords.isNotEmpty) {
        final db = await database;
        await db.transaction((txn) async {
          for (final record in xamarinRecords) {
            try {
              final tensionData = TensionData.fromMap(record);
              await txn.insert(
                'TensionData',
                tensionData.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              print(
                'Registro migrado: ${tensionData.fechaHora} - ${tensionData.sistole}/${tensionData.diastole}',
              );
            } catch (e) {
              print('ERROR al migrar un registro: $record. Error: $e');
            }
          }
        });
        print('Todos los registros migrados a la base de datos de Flutter.');
      }
    } catch (e) {
      print(
        'ERROR durante la migración de datos desde la base de datos externa: $e',
      );
      rethrow;
    } finally {
      if (externalDb != null && externalDb.isOpen) {
        await externalDb.close();
        print('Base de datos externa cerrada.');
      }
    }
  }

  Future<void> closeDatabase() async {
    _retryTimer?.cancel();
    _retryTimer = null;

    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<int> insertTensionData(TensionData data) async {
    final db = await database;
    return db.insert(
      'TensionData',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncTensionDataWithRetry(
    TensionData data, {
    int pacienteId = 1,
  }) async {
    final bool synced = await _sendSyncRequest(
      pacienteId: pacienteId,
      sistole: data.sistole,
      diastole: data.diastole,
      ritmoCardiaco: data.ritmoCardiaco,
      fechaRegistro: data.fechaHora.toIso8601String().split('.').first,
    );

    if (synced) {
      unawaited(_retryPendingSyncQueue());
      return;
    }

    await _enqueuePendingSync(
      pacienteId: pacienteId,
      sistole: data.sistole,
      diastole: data.diastole,
      ritmoCardiaco: data.ritmoCardiaco,
      fechaRegistro: data.fechaHora.toIso8601String().split('.').first,
    );
    _scheduleRetry();
  }

  Future<bool> _sendSyncRequest({
    required int pacienteId,
    required int sistole,
    required int diastole,
    required int ritmoCardiaco,
    required String fechaRegistro,
  }) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client
          .postUrl(Uri.parse('https://api.zdevs.uk/api/toma-tension/sync'))
          .timeout(const Duration(seconds: 8));

      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'paciente_id': pacienteId,
            'sistole': sistole,
            'diastole': diastole,
            'ritmoCardiaco': ritmoCardiaco,
            'fecha_registro': fechaRegistro,
          }),
        ),
      );

      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      final String responseBody = await response.transform(utf8.decoder).join();
      print(
        'No se pudo sincronizar con el backend. '
        'Status: ${response.statusCode}, Response: $responseBody',
      );
      return false;
    } catch (e) {
      print('Error al sincronizar toma de tensión: $e');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _enqueuePendingSync({
    required int pacienteId,
    required int sistole,
    required int diastole,
    required int ritmoCardiaco,
    required String fechaRegistro,
  }) async {
    final db = await database;
    await db.insert('PendingSyncTensionData', {
      'paciente_id': pacienteId,
      'sistole': sistole,
      'diastole': diastole,
      'ritmoCardiaco': ritmoCardiaco,
      'fecha_registro': fechaRegistro,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      unawaited(_retryPendingSyncQueue());
    });
  }

  Future<void> _retryPendingSyncQueue() async {
    if (_isRetryInProgress) {
      return;
    }

    _isRetryInProgress = true;
    try {
      final db = await database;
      final List<Map<String, dynamic>> pendingItems = await db.query(
        'PendingSyncTensionData',
        orderBy: 'id ASC',
        limit: 25,
      );

      if (pendingItems.isEmpty) {
        return;
      }

      for (final pending in pendingItems) {
        final bool synced = await _sendSyncRequest(
          pacienteId: pending['paciente_id'] as int,
          sistole: pending['sistole'] as int,
          diastole: pending['diastole'] as int,
          ritmoCardiaco: pending['ritmoCardiaco'] as int,
          fechaRegistro: pending['fecha_registro'] as String,
        );

        if (!synced) {
          _scheduleRetry();
          return;
        }

        await db.delete(
          'PendingSyncTensionData',
          where: 'id = ?',
          whereArgs: [pending['id']],
        );
      }

      final int remaining = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM PendingSyncTensionData'),
          ) ??
          0;

      if (remaining > 0) {
        _scheduleRetry();
      }
    } finally {
      _isRetryInProgress = false;
    }
  }

  Future<List<TensionData>> getTensionData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('TensionData');
    return List.generate(maps.length, (i) {
      return TensionData.fromMap(maps[i]);
    });
  }

  Future<List<TensionData>> getTensionDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final DateTime startOfDay = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final DateTime endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
      999,
    );

    final List<Map<String, dynamic>> maps = await db.query(
      'TensionData',
      where: 'fechaHora BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'fechaHora ASC',
    );
    return List.generate(maps.length, (i) {
      return TensionData.fromMap(maps[i]);
    });
  }

  Future<int> updateTensionData(TensionData data) async {
    final db = await database;
    return db.update(
      'TensionData',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> deleteTensionData(int id) async {
    final db = await database;
    return db.delete('TensionData', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTensionDataCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) FROM TensionData',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
