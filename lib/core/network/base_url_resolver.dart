import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Intenta resolver una URL base para el backend probando candidatos
/// y consultando /health. Devuelve el primer candidato válido.
Future<String?> resolveBaseUrl() async {
  final envBase = dotenv.env['BASE_URL'];

  if (envBase != null && envBase.isNotEmpty) {
    return envBase;
  }

  final candidates = <String>['https://proyectodegrado-90yf.onrender.com/api'];

  // También probar hosts definidos en .env
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

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  for (final candidate in candidates) {
    final ok = await _testCandidate(dio, candidate);

    if (ok) {
      return candidate;
    }
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
    print('Error verificando $candidate: $e');
  }

  return false;
}
