import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'base_url_resolver.dart';

import '../services/auth_service.dart';

class ApiClient {
  ApiClient._();

  static Dio create() {
    String? envBase;
    try {
      envBase = dotenv.env['BASE_URL'];
    } catch (_) {
      envBase =
          null; // dotenv not initialized (tests), will fallback to defaults
    }
    final baseUrl = envBase ?? 'http://10.0.2.2:3000/api';

    // Si no hay BASE_URL en .env, lanzamos la resolución en background
    if (envBase == null || envBase.isEmpty) {
      // Evitar ejecutar resolveBaseUrl durante tests si dotenv no está inicializado.
      resolveBaseUrl()
          .then((resolved) {
            if (resolved != null && resolved.isNotEmpty) {
              try {
                dotenv.env['BASE_URL'] = resolved;
              } catch (_) {
                // ignore: dotenv not initialized in test environment
              }
            }
          })
          .catchError((_) {});
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.instance.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Si la petición falla por conexión (socket/resolve), intentar resolver BASE_URL y reintentar una vez
          final isNetworkError =
              (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.unknown);
          if (isNetworkError) {
            try {
              final resolved = await resolveBaseUrl();
              if (resolved != null &&
                  resolved.isNotEmpty &&
                  dio.options.baseUrl != resolved) {
                dio.options.baseUrl = resolved;
                // reconstruir la petición original y reintentar
                final opts = e.requestOptions;
                try {
                  final response = await dio.fetch(opts);
                  return handler.resolve(response);
                } catch (e2) {
                  return handler.next(e);
                }
              }
            } catch (_) {
              // ignore and forward original error
            }
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
