import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Intenta resolver una URL base para el backend probando candidatos
/// y consultando /health. Devuelve el primer candidato válido.
Future<String?> resolveBaseUrl() async {
  final envBase = dotenv.env['BASE_URL'];
  if (envBase != null && envBase.isNotEmpty) return envBase;

  final candidates = <String>[
    'http://192.168.1.9:3000/api', // IP local más común
    'http://localhost:3000/api', // localhost
    'http://10.0.2.2:3000/api', // Android emulator
    'http://10.0.3.2:3000/api', // Genymotion
    'http://127.0.0.1:3000/api', // localhost alternativo
  ];

  // Agregar IPs dinámicas de la red local
  try {
    // En un entorno real, podríamos usar network_info_plus para obtener IPs
    // Por ahora, probamos rangos comunes
    for (int i = 1; i <= 255; i++) {
      candidates.add('http://192.168.1.$i:3000/api');
      if (candidates.length >= 20)
        break; // Limitar para no hacer demasiadas peticiones
    }
  } catch (_) {}

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

  // Intentar cada candidato con timeout corto (paralelo para ser más rápido)
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // Probar candidatos en paralelo para ser más eficiente
  final futures = candidates.map((candidate) => _testCandidate(dio, candidate));
  final results = await Future.wait(futures);

  for (int i = 0; i < results.length; i++) {
    if (results[i]) {
      return candidates[i];
    }
  }

  return null;
}

Future<bool> _testCandidate(Dio dio, String candidate) async {
  try {
    final res = await dio.get(
      '${candidate.replaceAll(RegExp(r"/+"), '/')}health',
      options: Options(responseType: ResponseType.json),
    );
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map && data['status'] == 'ok') {
        return true;
      }
    }
  } catch (_) {
    // ignora y sigue
  }
  return false;
}
