import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'base_url_resolver.dart';

import '../services/auth_service.dart';

class ApiClient {
  ApiClient._();

  static const _productionBaseUrl =
      'https://proyectodegrado-90yf.onrender.com/api';
  static Future<String?>? _baseUrlResolution;

  static Dio create() {
    String? envBase;

    try {
      envBase = dotenv.env['BASE_URL'];
    } catch (_) {
      envBase = null;
    }

    final configuredUrl = envBase?.trim();
    final baseUrl = kReleaseMode
      ? _productionBaseUrl
      : (configuredUrl ?? _productionBaseUrl);

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Resolver URL automáticamente si no existe en .env
    if (!kReleaseMode && (configuredUrl == null || configuredUrl.isEmpty)) {
      _resolveBaseUrlOnce()
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

          if (isNetworkError && !kReleaseMode) {
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

  static Future<String?> _resolveBaseUrlOnce() {
    _baseUrlResolution ??= resolveBaseUrl();
    return _baseUrlResolution!;
  }
}
