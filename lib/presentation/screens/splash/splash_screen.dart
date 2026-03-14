import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // Inicializa auth service mientras la UI está corriendo
    await AuthService.instance.init();

    // Aseguramos un mínimo de 2 segundos de pantalla de carga para buena UX
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (!mounted) return;

    final isLoggedIn = AuthService.instance.isAuthenticated.value;
    context.go(isLoggedIn ? '/home' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1320), Color(0xFF0F2B4F), Color(0xFF102B50)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, size: 68, color: Colors.white70),
              const SizedBox(height: 12),
              const Text(
                'MusicApp Valledupar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Conecta músicos y agrupaciones',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: AuthService.instance.authStateMessage,
                builder: (context, message, _) {
                  return Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
