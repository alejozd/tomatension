import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tension_data.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'tension_data.db');
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE TensionData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sistole INTEGER,
        diastole INTEGER,
        ritmoCardiaco INTEGER,
        fechaHora TEXT
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
          for (var record in xamarinRecords) {
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
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<int> insertTensionData(TensionData data) async {
    final db = await database;
    return await db.insert(
      'TensionData',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncTensionData(TensionData data, {int pacienteId = 1}) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client.postUrl(
        Uri.parse('https://api.zdevs.uk/api/toma-tension/sync'),
      );

      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'paciente_id': pacienteId,
            'sistole': data.sistole,
            'diastole': data.diastole,
            'ritmoCardiaco': data.ritmoCardiaco,
            'fecha_registro': data.fechaHora.toIso8601String().split('.').first,
          }),
        ),
      );

      final HttpClientResponse response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String responseBody = await response.transform(utf8.decoder).join();
        print(
          'No se pudo sincronizar con el backend. '
          'Status: ${response.statusCode}, Response: $responseBody',
        );
      }
    } catch (e) {
      print('Error al sincronizar toma de tensión: $e');
    } finally {
      client.close(force: true);
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
    return await db.update(
      'TensionData',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> deleteTensionData(int id) async {
    final db = await database;
    return await db.delete('TensionData', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTensionDataCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) FROM TensionData',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
