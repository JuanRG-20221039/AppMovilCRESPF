import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_crespf/screens/login.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build the LoginScreen inside a MaterialApp to provide necessary context.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verify that the title text is present.
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Verify that two text fields are present (usuario y contraseña).
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify that the "Entrar" button exists.
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });
}