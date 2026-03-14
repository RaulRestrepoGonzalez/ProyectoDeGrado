import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Intenta resolver una URL base para el backend probando candidatos
/// y consultando /health. Devuelve el primer candidato válido.
Future<String?> resolveBaseUrl() async {
  final envBase = dotenv.env['BASE_URL'];
  if (envBase != null && envBase.isNotEmpty) return envBase;

  final candidates = <String>[
    'http://10.0.2.2:3000/api', // Android emulator
    'http://10.0.3.2:3000/api', // Genymotion
    'http://localhost:3000/api', // iOS simulator or web
  ];

  // También probar la IP local del ordenador (si está definida en .env como BASE_HOSTS)
  final hostsEnv = dotenv.env['BASE_HOSTS'] ?? dotenv.env['BASE_HOST'];
  if (hostsEnv != null && hostsEnv.isNotEmpty) {
    final hosts = hostsEnv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final h in hosts) {
      candidates.add('http://$h:3000/api');
    }
  }

  // Intentar cada candidato con timeout corto
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ),
  );

  for (final c in candidates) {
    try {
      final res = await dio.get(
        '${c.replaceAll(RegExp(r"/+"), '/')}health',
        options: Options(responseType: ResponseType.json),
      );
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == 'ok') {
          return c;
        }
      }
    } catch (_) {
      // ignora y sigue
    }
  }

  return null;
}
