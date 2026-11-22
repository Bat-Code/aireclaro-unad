import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'aireclaro.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            documento TEXT NOT NULL,
            fecha_nacimiento TEXT NOT NULL,
            nombres TEXT NOT NULL,
            apellidos TEXT NOT NULL,
            telefono TEXT NOT NULL,
            salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            acepta_datos INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reports(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            numero TEXT NOT NULL,
            placa TEXT NOT NULL,
            color_humo TEXT,
            descripcion TEXT,
            evidencia_path TEXT,
            latitud REAL,
            longitud REAL,
            fecha_hora TEXT NOT NULL,
            estado TEXT NOT NULL,
            pdf_path TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');
      },
    );
  }
}