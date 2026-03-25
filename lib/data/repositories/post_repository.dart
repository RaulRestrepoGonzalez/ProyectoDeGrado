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
        formData.files.add(
          MapEntry('evidencias', await MultipartFile.fromFile(path)),
        );
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

  Future<void> reportPost(
    String postId,
    String motivo,
    String? comentariosOpcionales,
  ) async {
    try {
      await _dio.post(
        '/posts/$postId/denunciar',
        data: {
          'motivo': motivo,
          'comentariosOpcionales': comentariosOpcionales,
        },
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de espera agotado. Verifica tu conexión a internet.';

        case DioExceptionType.connectionError:
          return 'No se puede conectar al servidor. Verifica que el backend esté ejecutándose.';

        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Sesión expirada. Inicia sesión nuevamente.';
          } else if (error.response?.statusCode == 403) {
            return 'No tienes permisos para esta acción.';
          } else if (error.response?.statusCode == 404) {
            return 'Recurso no encontrado.';
          } else if (error.response?.statusCode == 500) {
            return 'Error interno del servidor. Inténtalo más tarde.';
          }
          break;

        case DioExceptionType.cancel:
          return 'Operación cancelada.';

        case DioExceptionType.unknown:
        default:
          // Verificar si es un error de DNS o conectividad
          if (error.message?.contains('Failed host lookup') ?? false) {
            return 'No se puede resolver la dirección del servidor. Verifica tu conexión.';
          }
          if (error.message?.contains('Network is unreachable') ?? false) {
            return 'Red no disponible. Verifica tu conexión a internet.';
          }
          break;
      }

      // Si hay respuesta del servidor, extraer mensaje específico
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data.containsKey('errors') &&
              data['errors'] is List &&
              (data['errors'] as List).isNotEmpty) {
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
