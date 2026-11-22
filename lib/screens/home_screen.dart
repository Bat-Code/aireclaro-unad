import 'package:flutter/material.dart';
import '../models/report_draft.dart';
import '../services/auth_service.dart';
import 'evidence_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nombre = AuthService.currentUser?['nombres'] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Hola, $nombre!')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EvidenceScreen(draft: ReportDraft()))),
                child: const Text('Nuevo reporte'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: FilledButton.tonal(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HistoryScreen())),
                child: const Text('Mis reportes'),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}