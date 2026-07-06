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
      version: 2,
      onCreate: (db, version) async {
        await _createUsuariosTable(db);
        await _createCitasTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCitasTable(db);
        }
      },
    );
  }

  static Future<void> _createUsuariosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        email TEXT,
        telefono TEXT,
        password TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _createCitasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS citas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remoto_id INTEGER,
        paciente TEXT NOT NULL,
        servicio TEXT NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        notas TEXT,
        sincronizado INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
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

  static Future<List<Map<String, dynamic>>> obtenerPendientes() async {
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

  static Future<int> guardarCitaLocal(
    Map<String, dynamic> cita,
  ) async {
    final db = await database;

    return await db.insert(
      'citas',
      {
        'remoto_id': cita['id'],
        'paciente': cita['paciente'],
        'servicio': cita['servicio'] ?? 'Consulta Dental',
        'fecha': cita['fecha'],
        'estado': cita['estado'] ?? 'pendiente',
        'notas': cita['notas'],
        'sincronizado': cita['sincronizado'] ?? 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerCitasLocales() async {
    final db = await database;

    return await db.query(
      'citas',
      orderBy: 'fecha ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerCitasPendientes() async {
    final db = await database;

    return await db.query(
      'citas',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'fecha ASC',
    );
  }

  static Future<void> marcarCitaSincronizada(
    int id, {
    int? remotoId,
  }) async {
    final db = await database;

    await db.update(
      'citas',
      {
        'sincronizado': 1,
        if (remotoId != null) 'remoto_id': remotoId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
