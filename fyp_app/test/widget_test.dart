import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_app/app.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Use runAsync for tests that involve timers or animations if needed,
    // but for a simple smoke test, pumping the widget is enough.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen text appears.
    expect(find.text('AI Teaching Assistant'), findsOneWidget);

    // We skip waiting for the 3-second timer in this simple test 
    // to avoid "Timer still pending" errors.
  });
}
