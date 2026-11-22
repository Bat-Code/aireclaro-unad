import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_database.dart';

class AuthService {
  static Map<String, dynamic>? currentUser;

  static String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String _hash(String pass, String salt) =>
      sha256.convert(utf8.encode('$salt$pass')).toString();

  /// Devuelve null si todo salió bien, o el mensaje de error.
  static Future<String?> register({
    required String email,
    required String documento,
    required String fechaNacimiento,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String password,
    required bool aceptaDatos,
  }) async {
    final db = await AppDatabase.instance;
    final existe = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()], limit: 1);
    if (existe.isNotEmpty) return 'Ya existe una cuenta con ese correo';

    final salt = _newSalt();
    await db.insert('users', {
      'email': email.toLowerCase(),
      'documento': documento,
      'fecha_nacimiento': fechaNacimiento,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'salt': salt,
      'password_hash': _hash(password, salt),
      'acepta_datos': aceptaDatos ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    return null;
  }

  static Future<bool> login(String email, String password) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()], limit: 1);
    if (rows.isEmpty) return false;
    final u = rows.first;
    if (_hash(password, u['salt'] as String) != u['password_hash']) {
      return false;
    }
    currentUser = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', u['id'] as int);
    return true;
  }

  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return;
    final db = await AppDatabase.instance;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) currentUser = rows.first;
  }

  static Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
}