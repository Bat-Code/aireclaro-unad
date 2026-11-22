import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class SuccessScreen extends StatelessWidget {
  final String numero;
  final String pdfPath;
  final String? videoPath;
  const SuccessScreen({
    super.key,
    required this.numero,
    required this.pdfPath,
    this.videoPath,
  });

  Future<void> _open(BuildContext context) async {
    final r = await OpenFilex.open(pdfPath);
    if (r.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo abrir el PDF: ${r.message}')));
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(
      subject: 'Solicitud PQRSD AireClaro $numero',
      text: 'Solicitud PQRSD generada con AireClaro. Radicado interno $numero',
      files: [
        XFile(pdfPath),
        if (videoPath != null) XFile(videoPath!),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Reporte generado'),
          automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(children: [
          const SizedBox(height: 16),
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 8),
          const Text('¡Reporte generado con éxito!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('N.º $numero',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Abrir PDF'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: const Text('Enviar o guardar'),
          ),
          const SizedBox(height: 24),
          const Text('Cómo hacer seguimiento',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '1. Envía el PDF (y el video, si tu evidencia es un video) por correo '
            'a la entidad competente usando el botón "Enviar o guardar".\n'
            '2. Conserva el número de radicado que te entregue la entidad.\n'
            '3. Por regla general, la entidad tiene 15 días hábiles para responder '
            'un derecho de petición (Ley 1755 de 2015).\n'
            '4. Si no hay respuesta en ese plazo, puedes reiterar tu solicitud.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Volver al menú principal'),
          ),
        ]),
      ),
    );
  }
}