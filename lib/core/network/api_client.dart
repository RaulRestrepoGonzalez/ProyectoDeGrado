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
      envBase = null;
    }

    final baseUrl = envBase ?? 'https://proyectodegrado-90yf.onrender.com/api';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Resolver URL automáticamente si no existe en .env
    if (envBase == null || envBase.isEmpty) {
      resolveBaseUrl()
          .then((resolved) {
            if (resolved != null && resolved.isNotEmpty) {
              dio.options.baseUrl = resolved;

              try {
                dotenv.env['BASE_URL'] = resolved;
              } catch (_) {}
            }
          })
          .catchError((_) {});
    }

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
          final isNetworkError =
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.unknown;

          if (isNetworkError) {
            try {
              final resolved = await resolveBaseUrl();

              if (resolved != null &&
                  resolved.isNotEmpty &&
                  resolved != dio.options.baseUrl) {
                dio.options.baseUrl = resolved;

                final response = await dio.fetch(e.requestOptions);
                return handler.resolve(response);
              }
            } catch (_) {}
          }

          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
