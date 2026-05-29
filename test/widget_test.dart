import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvio/main.dart';

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build NuvioApp wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: NuvioApp(),
      ),
    );

    // Verify Nuvio app name logo is present on Splash screen
    expect(find.text('Nuvio'), findsOneWidget);
  });
}
