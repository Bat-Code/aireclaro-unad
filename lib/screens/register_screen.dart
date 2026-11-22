import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _doc = TextEditingController();
  final _fecha = TextEditingController();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _tel = TextEditingController();
  final _pass = TextEditingController();
  bool _acepta = false;
  bool _loading = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      _fecha.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acepta) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debes aceptar el tratamiento de datos personales')));
      return;
    }
    setState(() => _loading = true);
    final error = await AuthService.register(
      email: _email.text.trim(),
      documento: _doc.text.trim(),
      fechaNacimiento: _fecha.text,
      nombres: _nombres.text.trim(),
      apellidos: _apellidos.text.trim(),
      telefono: _tel.text.trim(),
      password: _pass.text,
      aceptaDatos: _acepta,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cuenta creada. Ya puedes iniciar sesión')));
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType? type,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            _field('Correo electrónico', _email,
                type: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null),
            _field('Documento de identidad', _doc, type: TextInputType.number),
            _field('Fecha de nacimiento', _fecha,
                readOnly: true, onTap: _pickDate),
            _field('Nombres', _nombres),
            _field('Apellidos', _apellidos),
            _field('Teléfono', _tel, type: TextInputType.phone),
            _field('Contraseña', _pass,
                obscure: true,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Mínimo 6 caracteres'
                    : null),
            CheckboxListTile(
              value: _acepta,
              onChanged: (v) => setState(() => _acepta = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                  'Acepto el tratamiento de mis datos personales (Ley 1581 de 2012)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Crear cuenta'),
            ),
          ]),
        ),
      ),
    );
  }
}