import 'package:flutter/material.dart';
import '../models/report_draft.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import 'success_screen.dart';

class PetitionerScreen extends StatefulWidget {
  final ReportDraft draft;
  const PetitionerScreen({super.key, required this.draft});

  @override
  State<PetitionerScreen> createState() => _PetitionerScreenState();
}

class _PetitionerScreenState extends State<PetitionerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _doc;
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  late final TextEditingController _tel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = AuthService.currentUser ?? {};
    _doc = TextEditingController(text: '${u['documento'] ?? ''}');
    _nombre = TextEditingController(
        text: '${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}'.trim());
    _correo = TextEditingController(text: '${u['email'] ?? ''}');
    _tel = TextEditingController(text: '${u['telefono'] ?? ''}');
  }

  @override
  void dispose() {
    _doc.dispose();
    _nombre.dispose();
    _correo.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final d = widget.draft;
    d.docPeticionario = _doc.text.trim();
    d.nombrePeticionario = _nombre.text.trim();
    d.correoPeticionario = _correo.text.trim();
    d.telPeticionario = _tel.text.trim();

    setState(() => _loading = true);
    try {
      final r = await ReportService.create(d);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            numero: r.numero,
            pdfPath: r.pdfPath,
            videoPath: d.esVideo ? d.evidenciaPath : null,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el reporte: $e')));
    }
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? type, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del peticionario')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            const Text('Paso 4/4'),
            const LinearProgressIndicator(value: 1),
            const SizedBox(height: 16),
            _field('Documento de identidad', _doc, type: TextInputType.number),
            _field('Nombre completo', _nombre),
            _field('Correo electrónico', _correo,
                type: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null),
            _field('Teléfono', _tel, type: TextInputType.phone),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton(
                  onPressed: _generate, child: const Text('Generar')),
          ]),
        ),
      ),
    );
  }
}