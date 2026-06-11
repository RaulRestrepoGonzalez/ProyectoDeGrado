import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String?;
      final refreshToken = response.data['refreshToken'] as String?;

      if (token == null || refreshToken == null) {
        throw Exception('No se recibieron credenciales válidas del servidor');
      }

      return {'token': token, 'refreshToken': refreshToken};
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'nombre': nombre,
          'rol': rol,
        },
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> refreshToken() async {
    try {
      final response = await _dio.post('/auth/refresh');
      final token = response.data['token'] as String?;
      if (token == null) {
        throw Exception('No se recibió token de refresco');
      }
      return token;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(dynamic error) {
    print("ERROR COMPLETO: $error");

    if (error is DioException) {
      print("STATUS: ${error.response?.statusCode}");
      print("DATA: ${error.response?.data}");

      if (error.response?.data != null) {
        final data = error.response!.data;

        if (data is Map) {
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
        }
      }
    }

    return error.toString();
  }
}
