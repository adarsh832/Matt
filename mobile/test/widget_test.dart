import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaatApp());

    // Verify that the splash screen renders with the app name
    expect(find.text('Maat'), findsOneWidget);
    expect(find.text('Local AI'), findsOneWidget);
  });
}
