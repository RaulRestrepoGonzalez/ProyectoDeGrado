import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class PostRepository {
  final Dio _dio;

  PostRepository({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<List<dynamic>> getFeed() async {
    try {
      final response = await _dio.get('/posts/feed');
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getPostDetails(String id) async {
    try {
      final response = await _dio.get('/posts/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> createPost({
    required String contenido,
    String tipoPost = 'GENERAL',
    int? vacantes,
    double? precio,
    List<String> evidencias = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'contenido': contenido,
        'tipoPost': tipoPost,
        if (vacantes != null) 'vacantes': vacantes,
        if (precio != null) 'precio': precio,
      });

      for (var path in evidencias) {
        formData.files.add(MapEntry(
          'evidencias',
          await MultipartFile.fromFile(path),
        ));
      }

      await _dio.post('/posts', data: formData);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final response = await _dio.post('/posts/$postId/like');
      return response.data; // { status, hasLiked, likesCount }
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String postId) async {
    try {
      final response = await _dio.post('/posts/$postId/favorito');
      return response.data; // { status, hasFavorited }
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> comment(String postId, String texto) async {
    try {
      await _dio.post('/posts/$postId/comentarios', data: {'texto': texto});
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> blockPost(String postId) async {
    try {
      await _dio.post('/posts/$postId/bloquear');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> reportPost(String postId, String motivo, String? comentariosOpcionales) async {
    try {
      await _dio.post('/posts/$postId/denunciar', data: {
        'motivo': motivo,
        'comentariosOpcionales': comentariosOpcionales,
      });
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
