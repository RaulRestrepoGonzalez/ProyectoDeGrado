import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musicapp_valledupar/core/services/auth_service.dart';
import 'package:musicapp_valledupar/main.dart';

String _createFakeJwt({required int expiresInSeconds}) {
  final header = base64Url.encode(
    utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})),
  );

  final payload = base64Url.encode(
    utf8.encode(
      json.encode({
        'email': 'persisted@usuario.com',
        'rol': 'musico',
        'exp':
            (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) +
            expiresInSeconds,
      }),
    ),
  );

  // La firma no se valida en jwt_decoder, así que puede ser cualquier valor.
  final signature = base64Url.encode(utf8.encode('signature'));

  return '$header.$payload.$signature';
}

void main() {
  testWidgets('When token is persisted, app skips login and goes to home', (
    WidgetTester tester,
  ) async {
    // Configura un token válido en el almacenamiento seguro.
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': _createFakeJwt(expiresInSeconds: 3600),
    });

    await AuthService.instance.init();

    await tester.pumpWidget(const MyApp());

    // Espera al delay de splash + la navegación.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Explorar'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);
  });
}
