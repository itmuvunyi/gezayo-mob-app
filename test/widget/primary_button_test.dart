import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gezayo_app/core/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton displays text and triggers callback',
      (WidgetTester tester) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Submit Request',
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Submit Request'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(wasPressed, true);
  });

  testWidgets('PrimaryButton displays loading indicator when isLoading is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Submit Request',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
