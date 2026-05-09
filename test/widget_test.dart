import 'package:flutter_test/flutter_test.dart';
import 'package:zenvix/main.dart';

void main() {
  testWidgets('Zenvix app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ZenvixApp());

    expect(find.byType(ZenvixApp), findsOneWidget);
  }); 
}
