import 'package:flutter_test/flutter_test.dart';

import 'package:agro_plus/main.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(const AgroPlusApp());
    await tester.pumpAndSettle();

    expect(find.text('AgroPlus'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
