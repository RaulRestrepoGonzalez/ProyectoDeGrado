import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class UserRepository {
  final Dio _dio;

  UserRepository({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/perfil');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String userId) async {
    try {
      final response = await _dio.post('/users/$userId/seguir');
      return response.data;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? nombre,
    String? rol,
    String? telefono,
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      if (nombre != null) formData.fields.add(MapEntry('nombre', nombre));
      if (rol != null) formData.fields.add(MapEntry('rol', rol));
      if (telefono != null) formData.fields.add(MapEntry('telefono', telefono));

      if (imagePath != null) {
         formData.files.add(
           MapEntry(
             'fotoPerfil',
             await MultipartFile.fromFile(imagePath),
           ),
         );
      }

      final response = await _dio.put('/users/me/perfil', data: formData);
      return response.data['data']['usuario'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data.containsKey('errors') && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
             return data['errors'][0]['message'] ?? 'Error de validación';
          }
          if (data.containsKey('message')) {
            return data['message'];
          }
        }
      }
      return 'Error de red o servidor no disponible.';
    }
    return error.toString();
  }
}
