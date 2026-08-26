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
    String? telefono,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'nombre': nombre,
          'rol': rol,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        },
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> requestPasswordRecovery({required String identifier}) async {
    try {
      final response = await _dio.post(
        '/auth/recovery/request',
        data: {'identifier': identifier},
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final whatsappUrl = response.data['whatsappUrl'] as String?;
      if (whatsappUrl == null || whatsappUrl.isEmpty) {
        throw Exception('No se pudo preparar la conversación de WhatsApp.');
      }
      return whatsappUrl;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> resetPassword({
    required String identifier,
    required String codigo,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/recovery/reset',
        data: {
          'identifier': identifier,
          'codigo': codigo,
          'newPassword': newPassword,
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
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'El servidor está tardando en responder. Verifica tu conexión e inténtalo nuevamente.';
      }
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
