import 'package:flutter_test/flutter_test.dart';
import 'package:zenvix/main.dart';

void main() {
  testWidgets('Zenvix app loads successfully',
      (WidgetTester tester) async {

    // Build the app
    await tester.pumpWidget(const ZenvixApp());

    // Verify app loaded
    expect(find.byType(ZenvixApp), findsOneWidget);
  });
}
