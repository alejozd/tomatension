import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tension_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tension_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tension_data(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sistole INTEGER,
            diastole INTEGER,
            ritmoCardiaco INTEGER,
            fechaHora TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertTensionData(TensionData data) async {
    final db = await database;
    await db.insert(
      'tension_data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TensionData>> getTensionData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tension_data',
      orderBy: 'fechaHora DESC',
    ); // Ordenar por fecha descendente

    return List.generate(maps.length, (i) {
      return TensionData.fromMap(maps[i]);
    });
  }

  // Nuevo método para obtener datos dentro de un rango de fechas
  Future<List<TensionData>> getTensionDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tension_data',
      where: 'fechaHora >= ? AND fechaHora <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1))
            .toIso8601String(), // Incluye hasta el final del día
      ],
      orderBy: 'fechaHora DESC', // Ordenar por fecha descendente
    );

    return List.generate(maps.length, (i) {
      return TensionData.fromMap(maps[i]);
    });
  }
}
