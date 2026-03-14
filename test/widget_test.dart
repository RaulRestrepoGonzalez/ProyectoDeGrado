// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musicapp_valledupar/main.dart';

void main() {
  testWidgets('Splash -> Auth screen flow', (WidgetTester tester) async {
    // Load environment variables as the app expects them.
    await dotenv.load(fileName: '.env');

    await tester.pumpWidget(const MyApp());

    // Splash should show app name soon.
    expect(find.text('MusicApp Valledupar'), findsOneWidget);

    // Wait for splash navigation (splash ensures minimum 2 seconds).
    await tester.pump(const Duration(milliseconds: 2500));
    // Avoid pumpAndSettle in case of pending async ops; advance a few frames instead.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Validate that the auth screen is shown.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Aún no tienes cuenta? Regístrate'), findsOneWidget);
  });
}
