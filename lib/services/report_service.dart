import 'dart:io';
import '../db/app_database.dart';
import '../models/report_draft.dart';
import 'auth_service.dart';
import 'pdf_service.dart';

class CreatedReport {
  final int id;
  final String numero;
  final String pdfPath;
  CreatedReport(this.id, this.numero, this.pdfPath);
}

class ReportService {
  static Future<CreatedReport> create(ReportDraft d) async {
    final db = await AppDatabase.instance;
    final userId = AuthService.currentUser!['id'] as int;

    final id = await db.insert('reports', {
      'user_id': userId,
      'numero': 'PENDIENTE',
      'placa': d.placa,
      'color_humo': d.colorHumo,
      'descripcion': d.descripcion,
      'evidencia_path': d.evidenciaPath,
      'latitud': d.latitud,
      'longitud': d.longitud,
      'fecha_hora': d.fechaHora!.toIso8601String(),
      'estado': 'Generado',
    });

    final numero =
        'AC-${DateTime.now().year}-${id.toString().padLeft(5, '0')}';

    try {
      final pdfPath = await PdfService.generate(numero: numero, d: d);
      await db.update('reports', {'numero': numero, 'pdf_path': pdfPath},
          where: 'id = ?', whereArgs: [id]);
      return CreatedReport(id, numero, pdfPath);
    } catch (e) {
      await db.delete('reports', where: 'id = ?', whereArgs: [id]);
      rethrow;
    }
  }

  /// Reportes del usuario con sesión iniciada, del más reciente al más antiguo.
  static Future<List<Map<String, dynamic>>> listForCurrentUser() async {
    final db = await AppDatabase.instance;
    final userId = AuthService.currentUser!['id'] as int;
    return db.query('reports',
        where: 'user_id = ? AND numero != ?',
        whereArgs: [userId, 'PENDIENTE'],
        orderBy: 'id DESC');
  }

  static Future<void> updateEstado(int id, String estado) async {
    final db = await AppDatabase.instance;
    await db.update('reports', {'estado': estado},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Borra el registro y sus archivos (PDF y evidencia).
  static Future<void> delete(Map<String, dynamic> r) async {
    final db = await AppDatabase.instance;
    await db.delete('reports', where: 'id = ?', whereArgs: [r['id']]);
    for (final key in ['pdf_path', 'evidencia_path']) {
      final path = r[key] as String?;
      if (path != null) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    }
  }
}