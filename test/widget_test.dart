import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AquaFlowApp()));

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify that the app starts with loading or login screen
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}