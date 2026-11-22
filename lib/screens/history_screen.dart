import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../services/report_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  static const _videoExts = ['.mp4', '.mov', '.3gp', '.mkv', '.webm', '.avi'];

  @override
  void initState() {
    super.initState();
    _future = ReportService.listForCurrentUser();
  }

  void _reload() {
    setState(() {
      _future = ReportService.listForCurrentUser();
    });
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openPdf(Map<String, dynamic> r) async {
    final path = r['pdf_path'] as String?;
    if (path == null || !File(path).existsSync()) {
      _msg('El archivo PDF ya no existe');
      return;
    }
    final res = await OpenFilex.open(path);
    if (res.type != ResultType.done) {
      _msg('No se pudo abrir el PDF: ${res.message}');
    }
  }

  Future<void> _share(Map<String, dynamic> r) async {
    final pdf = r['pdf_path'] as String?;
    if (pdf == null || !File(pdf).existsSync()) {
      _msg('El archivo PDF ya no existe');
      return;
    }
    final ev = r['evidencia_path'] as String?;
    final esVideo = ev != null &&
        _videoExts.any((e) => ev.toLowerCase().endsWith(e)) &&
        File(ev).existsSync();

    await SharePlus.instance.share(ShareParams(
      subject: 'Solicitud PQRSD AireClaro ${r['numero']}',
      text: 'Solicitud PQRSD generada con AireClaro. Radicado interno ${r['numero']}',
      files: [XFile(pdf), if (esVideo) XFile(ev)],
    ));

    if (!mounted || r['estado'] == 'Enviado') return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('¿Ya enviaste la solicitud?'),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'Marcar como Enviado',
        onPressed: () async {
          await ReportService.updateEstado(r['id'] as int, 'Enviado');
          if (mounted) _reload();
        },
      ),
    ));
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: Text(
            '¿Eliminar el reporte ${r['numero']}? Se borrarán también el PDF y la evidencia.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await ReportService.delete(r);
    if (mounted) _reload();
  }

  void _showActions(Map<String, dynamic> r) {
    final fecha =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(r['fecha_hora']));
    final enviado = r['estado'] == 'Enviado';
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(children: [
          ListTile(
            title: Text('${r['numero']}  ·  ${r['placa']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '$fecha\nHumo: ${r['color_humo']}  ·  Estado: ${r['estado']}'),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Abrir PDF'),
            onTap: () {
              Navigator.pop(sheet);
              _openPdf(r);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Enviar o guardar de nuevo'),
            onTap: () {
              Navigator.pop(sheet);
              _share(r);
            },
          ),
          if (!enviado)
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Marcar como Enviado'),
              onTap: () async {
                Navigator.pop(sheet);
                await ReportService.updateEstado(r['id'] as int, 'Enviado');
                if (mounted) _reload();
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(sheet);
              _delete(r);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('Aún no has generado reportes'));
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    final enviado = r['estado'] == 'Enviado';
                    final fecha = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(r['fecha_hora']));
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text('${r['placa']}  ·  ${r['numero']}'),
                      subtitle: Text(fecha),
                      trailing: Chip(
                        label: Text(r['estado']),
                        backgroundColor: enviado
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                      ),
                      onTap: () => _showActions(r),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al inicio'),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}