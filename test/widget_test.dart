import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:app_crespf/screens/login.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      // Set a larger surface size to prevent overflow during tests
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Build the LoginScreen inside a MaterialApp.
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Verify that the title text is present.
      expect(find.text('Iniciar sesión'), findsOneWidget);

      // Verify that two text fields are present (usuario y contraseña).
      expect(find.byType(TextField), findsNWidgets(2));

      // Verify that the "Entrar" button exists.
      expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    });
  });
}