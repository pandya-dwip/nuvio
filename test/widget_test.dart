import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvio/main.dart';
import 'package:nuvio/screens/home_screen.dart';

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

    // Pump and settle to let the transition delayed timer complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('Home Screen empty state test', (WidgetTester tester) async {
    // Build HomeScreen inside MaterialApp and ProviderScope directly to isolate
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify Search Bar is present
    expect(find.text('Search notes & checklists...'), findsOneWidget);

    // Verify EmptyState illustration is present (A blank canvas text)
    expect(find.text('A blank canvas'), findsOneWidget);
  });
}
