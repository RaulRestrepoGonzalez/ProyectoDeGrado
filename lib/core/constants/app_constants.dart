class AppConstants {
  AppConstants._();

  static const String appName = 'MusicApp Valledupar';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://api.example.com',
  );

  // Definir otros valores constantes (géneros, tipos de contrato, etc.)
  static const List<String> genres = ['Vallenato', 'Cumbia', 'Vallenato-Pop'];
}
