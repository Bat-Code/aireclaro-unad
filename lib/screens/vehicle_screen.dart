import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/report_draft.dart';
import 'location_screen.dart';

class VehicleScreen extends StatefulWidget {
  final ReportDraft draft;
  const VehicleScreen({super.key, required this.draft});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placa;
  late final TextEditingController _desc;
  final _speech = stt.SpeechToText();
  static const _colores = ['Negro', 'Blanco', 'Gris', 'Azul'];
  late String _color;
  bool _listening = false;
  bool _colorError = false;

  @override
  void initState() {
    super.initState();
    _placa = TextEditingController(text: widget.draft.placa);
    _desc = TextEditingController(text: widget.draft.descripcion);
    _color = widget.draft.colorHumo;
  }

  @override
  void dispose() {
    _speech.stop();
    _placa.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dictado no disponible o permiso de micrófono denegado')));
      return;
    }
    final base = _desc.text;
    setState(() => _listening = true);
    await _speech.listen(onResult: (r) {
      if (!mounted) return;
      setState(() {
        _desc.text =
            base.isEmpty ? r.recognizedWords : '$base ${r.recognizedWords}';
      });
    });
  }

  void _next() {
    final okForm = _formKey.currentState!.validate();
    setState(() => _colorError = _color.isEmpty);
    if (!okForm || _color.isEmpty) return;

    widget.draft.placa = _placa.text.trim().toUpperCase();
    widget.draft.colorHumo = _color;
    widget.draft.descripcion = _desc.text.trim();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => LocationScreen(draft: widget.draft)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del vehículo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            const Text('Paso 2/4'),
            const LinearProgressIndicator(value: 0.5),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placa,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Placa del vehículo', hintText: 'MKL473'),
              validator: (v) {
                final t = (v ?? '').trim().toUpperCase();
                if (!RegExp(r'^[A-Z]{3}\d{2}[A-Z0-9]$').hasMatch(t)) {
                  return 'Formato inválido (ej: MKL473)';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text('Color del humo'),
            Wrap(
              spacing: 8,
              children: _colores
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _color == c,
                        onSelected: (_) => setState(() {
                          _color = c;
                          _colorError = false;
                        }),
                      ))
                  .toList(),
            ),
            if (_colorError)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Selecciona un color',
                    style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
                suffixIcon: IconButton(
                  tooltip: 'Dictar',
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? Colors.red : null),
                  onPressed: _toggleDictation,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _next, child: const Text('Siguiente')),
          ]),
        ),
      ),
    );
  }
}