import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/report_draft.dart';
import 'vehicle_screen.dart';

class EvidenceScreen extends StatefulWidget {
  final ReportDraft draft;
  const EvidenceScreen({super.key, required this.draft});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  static const _videoExts = ['.mp4', '.mov', '.3gp', '.mkv', '.webm', '.avi'];

  Future<void> _pick(Future<XFile?> Function() action) async {
    setState(() => _busy = true);
    try {
      final file = await action();
      if (file == null) return;

      // Copiamos el archivo a una carpeta permanente de la app
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'evidencias'));
      await dir.create(recursive: true);
      var ext = p.extension(file.path).toLowerCase();
      if (ext.isEmpty) ext = '.jpg';
      final dest =
          p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(file.path).copy(dest);

      widget.draft.evidenciaPath = dest;
      widget.draft.esVideo = _videoExts.contains(ext);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo cargar: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _preview() {
    final path = widget.draft.evidenciaPath;
    if (path == null) {
      return const Center(child: Text('Aún no hay evidencia'));
    }
    if (widget.draft.esVideo) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 64),
          const SizedBox(height: 8),
          Text('Video: ${p.basename(path)}'),
        ],
      );
    }
    return Image.file(File(path), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final tiene = widget.draft.evidenciaPath != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Sube la evidencia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paso 1/4'),
            const LinearProgressIndicator(value: 0.25),
            const SizedBox(height: 12),
            const Text('Enfoca la placa y el humo del vehículo.'),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _preview(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () => _pick(
                      () => _picker.pickImage(source: ImageSource.camera)),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tomar foto'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () => _pick(() => _picker.pickVideo(
                      source: ImageSource.camera,
                      maxDuration: const Duration(seconds: 30))),
              icon: const Icon(Icons.videocam),
              label: const Text('Grabar video'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _pick(() => _picker.pickMedia()),
              icon: const Icon(Icons.photo_library),
              label: const Text('Subir desde galería'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: tiene
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VehicleScreen(draft: widget.draft)))
                  : null,
              child: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}