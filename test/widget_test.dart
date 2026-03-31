import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cursova/main.dart';

void main() {
  testWidgets('App compiles and launches smoke test', (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp(isFirstRun: true));


    expect(find.byType(MyApp), findsOneWidget);
  });
}