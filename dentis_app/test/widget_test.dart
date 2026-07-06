import 'package:flutter_test/flutter_test.dart';

import 'package:dentis_app/main.dart';

void main() {
  testWidgets('login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DentisApp());

    expect(find.text('Ingresar al sistema'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
