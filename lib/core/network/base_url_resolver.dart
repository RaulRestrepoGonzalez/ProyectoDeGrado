import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Intenta resolver una URL base para el backend probando candidatos
/// y consultando /health. Devuelve el primer candidato válido.
Future<String?> resolveBaseUrl() async {
  final envBase = dotenv.env['BASE_URL'];

  final candidates = <String>[];

  if (envBase != null && envBase.trim().isNotEmpty) {
    candidates.add(envBase.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  candidates.add('https://proyectodegrado-90yf.onrender.com/api');

  // También probar hosts definidos en .env
  final hostsEnv = dotenv.env['BASE_HOSTS'] ?? dotenv.env['BASE_HOST'];

  if (hostsEnv != null && hostsEnv.isNotEmpty) {
    final hosts = hostsEnv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final h in hosts) {
      final host = h
          .replaceFirst(RegExp(r'^https?://'), '')
          .replaceFirst(RegExp(r':\d+$'), '');
      candidates.add('http://$host:3000/api');
    }
  }

  candidates.addAll(const [
    'http://10.0.2.2:3000/api',
    'http://10.0.3.2:3000/api',
    'http://localhost:3000/api',
    'http://127.0.0.1:3000/api',
  ]);

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  final uniqueCandidates = candidates.toSet().toList();
  final results = await Future.wait(
    uniqueCandidates.map((candidate) async {
      final ok = await _testCandidate(dio, candidate);
      return ok ? candidate : null;
    }),
  );

  for (final result in results) {
    if (result != null) return result;
  }

  return null;
}

Future<bool> _testCandidate(Dio dio, String candidate) async {
  try {
    final healthUrl = candidate.endsWith('/api')
        ? candidate.replaceFirst('/api', '/health')
        : '$candidate/health';

    final res = await dio.get(
      healthUrl,
      options: Options(responseType: ResponseType.json),
    );

    if (res.statusCode == 200) {
      final data = res.data;

      if (data is Map && data['status'] == 'ok') {
        return true;
      }
    }
  } catch (e) {
    debugPrint('Error verificando $candidate: $e');
  }

  return false;
}
