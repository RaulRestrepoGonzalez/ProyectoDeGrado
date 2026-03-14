import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class SearchRepository {
  final Dio _dio;

  SearchRepository({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, List<dynamic>>> searchAll(String query) async {
    try {
      // Endpoint sugerido. Modificar si el backend usa otra ruta (ej: /posts/search, /users/search separados)
      final response = await _dio.get('/search', queryParameters: {'q': query});
      
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      
      return {
        'publicaciones': data['posts'] ?? [],
        'perfiles': data['users'] ?? [],
        'convocatorias': data['convocatorias'] ?? [],
      };
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
             return data['errors'][0]['message'] ?? 'Error en la búsqueda';
          }
          if (data.containsKey('message')) {
            return data['message'];
          }
        }
      }
      return 'Error de red en la búsqueda.';
    }
    return error.toString();
  }
}
