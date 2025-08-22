import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tension_data.dart'; // Importa la clase que creaste

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
    final List<Map<String, dynamic>> maps = await db.query('tension_data');

    return List.generate(maps.length, (i) {
      return TensionData.fromMap(maps[i]);
    });
  }

  // Agrega más métodos aquí para actualizar y eliminar datos si lo necesitas
}
