import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'secure_field_codec.dart';

class LocalDatabase {
  static const List<String> _protectedCitaFields = [
    'paciente',
    'servicio',
    'notas',
  ];

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

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createUsuariosTable(db);
        await _createCitasTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCitasTable(db);
        }
        if (oldVersion < 3) {
          await _removeStoredPasswords(db);
        }
      },
    );

    await _encryptLegacyCitaData(db);
    return db;
  }

  static Future<void> _createUsuariosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        email TEXT,
        telefono TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _removeStoredPasswords(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(usuarios)');
    final hasPasswordColumn = columns.any(
      (column) => column['name'] == 'password',
    );

    if (!hasPasswordColumn) {
      return;
    }

    await db.execute('ALTER TABLE usuarios RENAME TO usuarios_legacy');
    await _createUsuariosTable(db);
    await db.execute('''
      INSERT INTO usuarios(id, nombre, email, telefono, sincronizado)
      SELECT id, nombre, email, telefono, sincronizado
      FROM usuarios_legacy
    ''');
    await db.execute('DROP TABLE usuarios_legacy');
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
    final safeUser = Map<String, dynamic>.from(usuario)..remove('password');

    return await db.insert(
      'usuarios',
      safeUser,
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
    final protectedCita = await _protectCitaFields({
      'remoto_id': cita['id'],
      'paciente': cita['paciente'],
      'servicio': cita['servicio'] ?? 'Consulta Dental',
      'fecha': cita['fecha'],
      'estado': cita['estado'] ?? 'pendiente',
      'notas': cita['notas'],
      'sincronizado': cita['sincronizado'] ?? 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    return await db.insert(
      'citas',
      protectedCita,
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerCitasLocales() async {
    final db = await database;

    final rows = await db.query(
      'citas',
      orderBy: 'fecha ASC',
    );

    return await _revealCitaRows(rows);
  }

  static Future<List<Map<String, dynamic>>> obtenerCitasPendientes() async {
    final db = await database;

    final rows = await db.query(
      'citas',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'fecha ASC',
    );

    return await _revealCitaRows(rows);
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

  static Future<void> _encryptLegacyCitaData(Database db) async {
    final rows = await db.query('citas');

    for (final row in rows) {
      final update = <String, dynamic>{};

      for (final field in _protectedCitaFields) {
        final value = row[field];
        if (value == null ||
            SecureFieldCodec.isEncrypted(value) ||
            value.toString().isEmpty) {
          continue;
        }

        update[field] = await SecureFieldCodec.encryptNullable(value);
      }

      if (update.isNotEmpty) {
        await db.update(
          'citas',
          update,
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  static Future<Map<String, dynamic>> _protectCitaFields(
    Map<String, dynamic> cita,
  ) async {
    final protected = Map<String, dynamic>.from(cita);

    for (final field in _protectedCitaFields) {
      protected[field] = await SecureFieldCodec.encryptNullable(cita[field]);
    }

    return protected;
  }

  static Future<List<Map<String, dynamic>>> _revealCitaRows(
    List<Map<String, dynamic>> rows,
  ) async {
    final revealedRows = <Map<String, dynamic>>[];

    for (final row in rows) {
      final revealed = Map<String, dynamic>.from(row);

      for (final field in _protectedCitaFields) {
        revealed[field] = await SecureFieldCodec.decryptNullable(row[field]);
      }

      revealedRows.add(revealed);
    }

    return revealedRows;
  }
}
