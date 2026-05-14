import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sistema_medicamentos_movil/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('Register page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
  });
}
