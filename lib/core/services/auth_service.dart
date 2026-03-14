import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Servicio simple para manejar la sesión del usuario.
/// Mantiene ValueNotifiers para que la UI pueda reaccionar a cambios.
class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  final ValueNotifier<String> authStateMessage = ValueNotifier('Verificando sesión...');

  String? _cachedToken;

  /// Inicializa el estado a partir de los tokens almacenados.
  Future<void> init() async {
    authStateMessage.value = 'Iniciando sesión segura...';
    // During widget tests avoid network calls but still read stored tokens.
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      authStateMessage.value = 'Modo test - inicialización limitada';
      final token = await _readFromStorage(_tokenKey);
      _cachedToken = token;
      if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
        isAuthenticated.value = true;
      } else {
        isAuthenticated.value = false;
      }
      return;
    }
    try {
      final token = await _readFromStorage(_tokenKey);
      final refreshToken = await _readFromStorage(_refreshTokenKey);
      _cachedToken = token;

      if (token == null || token.isEmpty) {
        isAuthenticated.value = false;
        return;
      }

      if (JwtDecoder.isExpired(token)) {
        authStateMessage.value = 'Renovando token de sesión...';
        final newToken = await _refreshTokens(refreshToken);
        isAuthenticated.value = newToken != null;
      } else {
        isAuthenticated.value = true;
      }
    } catch (_) {
      isAuthenticated.value = false;
    }
  }

  Future<String?> getToken() async {
    if (_cachedToken != null && !JwtDecoder.isExpired(_cachedToken!)) {
      return _cachedToken;
    }

    final token = await _readFromStorage(_tokenKey);
    final refreshToken = await _readFromStorage(_refreshTokenKey);

    if (token == null || token.isEmpty) return null;

    if (!JwtDecoder.isExpired(token)) {
      _cachedToken = token;
      return token;
    }

    return await _refreshTokens(refreshToken);
  }

  Future<String?> _refreshTokens(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return null;
    }

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final res = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = res.data['token'] as String?;
      final newRefresh = res.data['refreshToken'] as String?;

      if (newAccess == null || newRefresh == null) {
        await logout();
        return null;
      }

      await saveTokens(newAccess, newRefresh);
      return newAccess;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _cachedToken = accessToken;
    isAuthenticated.value = true;
    
    await _writeToStorage(_tokenKey, accessToken);
    await _writeToStorage(_refreshTokenKey, refreshToken);
  }

  Future<Map<String, String>?> getStoredTokens() async {
    final token = await _readFromStorage(_tokenKey);
    final refreshToken = await _readFromStorage(_refreshTokenKey);
    if (token != null && refreshToken != null) {
      return {'token': token, 'refreshToken': refreshToken};
    }
    return null;
  }

  Future<void> logout() async {
    // Attempt backend logout if we have a token
    try {
      if (_cachedToken != null) {
        final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000/api';
        final dio = Dio(BaseOptions(baseUrl: baseUrl));
        await dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $_cachedToken'}),
        );
      }
    } catch (_) {}

    _cachedToken = null;
    isAuthenticated.value = false;
    
    await _deleteFromStorage(_tokenKey);
    await _deleteFromStorage(_refreshTokenKey);
  }

  Future<void> _writeToStorage(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _readFromStorage(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
