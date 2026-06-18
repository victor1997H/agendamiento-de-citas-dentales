import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(
      await getDatabasesPath(),
      'dentis.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            email TEXT,
            telefono TEXT,
            password TEXT,
            sincronizado INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  static Future<int> guardarUsuario(
    Map<String, dynamic> usuario,
  ) async {
    final db = await database;

    return await db.insert(
      'usuarios',
      usuario,
    );
  }

  static Future<List<Map<String, dynamic>>>
      obtenerPendientes() async {
    final db = await database;

    return await db.query(
      'usuarios',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  static Future<void> marcarSincronizado(
    int id,
  ) async {
    final db = await database;

    await db.update(
      'usuarios',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}