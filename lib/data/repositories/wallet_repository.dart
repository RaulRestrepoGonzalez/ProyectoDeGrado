import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class WalletRepository {
  final Dio _dio;

  WalletRepository({Dio? dio}) : _dio = dio ?? ApiClient.create();

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _dio.get('/wallet/me');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> purchasePlan(String plan) async {
    try {
      final response = await _dio.post('/wallet/comprar', data: {'plan': plan});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'];
    }
    return error.toString();
  }
}
