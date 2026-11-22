import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report_draft.dart';

class PdfService {
  static pw.Widget _h(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
        child: pw.Text(t,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      );

  static pw.Widget _row(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 130,
                child: pw.Text(k,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(child: pw.Text(v)),
          ],
        ),
      );

  /// Genera el PDF y devuelve la ruta del archivo.
  static Future<String> generate({
    required String numero,
    required ReportDraft d,
  }) async {
    final doc = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(d.fechaHora!);
    final hoy = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final lat = d.latitud!.toStringAsFixed(6);
    final lng = d.longitud!.toStringAsFixed(6);
    final tipo = d.esVideo ? 'video' : 'fotografía';

    pw.ImageProvider? imagen;
    if (!d.esVideo && d.evidenciaPath != null) {
      imagen = pw.MemoryImage(await File(d.evidenciaPath!).readAsBytes());
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        footer: (ctx) => pw.Text(
          'Documento generado con AireClaro (prototipo) - Radicado interno $numero - Pág. ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        build: (ctx) => [
          pw.Text('SOLICITUD FORMAL - PQRSD',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.Text('Radicado interno: $numero'),
          pw.Text('Fecha de generación: $hoy'),
          pw.SizedBox(height: 14),
          pw.Text('Señores'),
          pw.Text('Autoridad ambiental y de tránsito competente',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Corredor Soacha - Bogotá'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Asunto: Petición por vehículo con emisión visible de humo contaminante, placa ${d.placa}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Respetados señores:\n\n'
            'Yo, ${d.nombrePeticionario}, identificado(a) con documento de identidad No. ${d.docPeticionario}, '
            'en ejercicio del derecho de petición consagrado en el artículo 23 de la Constitución Política '
            'de Colombia y regulado por la Ley 1755 de 2015, me permito poner en su conocimiento lo siguiente:',
            textAlign: pw.TextAlign.justify,
          ),
          _h('HECHOS'),
          pw.Text(
            '1. El día $fecha, en el corredor Soacha - Bogotá (ubicación detallada más abajo), '
            'observé un vehículo de placa ${d.placa} emitiendo humo de color ${d.colorHumo.toLowerCase()}.\n'
            '2. Como soporte adjunto $tipo registrada en el momento de los hechos.'
            '${d.descripcion.isNotEmpty ? '\n3. Descripción adicional: ${d.descripcion}' : ''}',
            textAlign: pw.TextAlign.justify,
          ),
          _h('PETICIÓN'),
          pw.Text(
            'Con fundamento en lo anterior, solicito respetuosamente:\n'
            '1. Verificar el estado de emisiones del vehículo identificado con la placa ${d.placa}.\n'
            '2. Adelantar las actuaciones de control y sanción a que haya lugar, conforme a la normatividad '
            'ambiental y de tránsito vigente.\n'
            '3. Informarme por escrito sobre las actuaciones adelantadas.',
            textAlign: pw.TextAlign.justify,
          ),
          _h('DATOS DEL REPORTE'),
          _row('Placa', d.placa),
          _row('Color del humo', d.colorHumo),
          _row('Fecha y hora', fecha),
          _row('Coordenadas', '$lat, $lng'),
          _row('Mapa', 'https://www.google.com/maps?q=$lat,$lng'),
          _h('EVIDENCIA'),
          if (imagen != null)
            pw.Center(
              child: pw.Image(imagen, height: 260, fit: pw.BoxFit.contain),
            )
          else
            pw.Text(
              'La evidencia es un video, que se entrega como archivo adjunto '
              'junto con este documento (${d.evidenciaPath == null ? '' : p.basename(d.evidenciaPath!)}).',
            ),
          _h('NOTIFICACIONES'),
          _row('Correo electrónico', d.correoPeticionario),
          _row('Teléfono', d.telPeticionario),
          pw.SizedBox(height: 36),
          pw.Text('Atentamente,'),
          pw.SizedBox(height: 28),
          pw.Text('______________________________'),
          pw.Text(d.nombrePeticionario,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('C.C. ${d.docPeticionario}'),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final out = Directory(p.join(dir.path, 'reportes'));
    await out.create(recursive: true);
    final path = p.join(out.path, '$numero.pdf');
    await File(path).writeAsBytes(await doc.save());
    return path;
  }
}