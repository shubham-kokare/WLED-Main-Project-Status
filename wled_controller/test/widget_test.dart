import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wled_controller/main.dart';

void main() {
  testWidgets('WLED Studio App smoke test', (WidgetTester tester) async {
    // Build WledApp wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: WledApp(),
      ),
    );

    // Verify AppBar renders
    expect(find.text('WLED Studio'), findsOneWidget);
  });
}
