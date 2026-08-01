import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gezayo_app/main.dart';
import 'package:gezayo_app/core/services/storage_service.dart';

void main() {
  testWidgets('GezaYoApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final pref = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService(pref)),
        ],
        child: const GezaYoApp(),
      ),
    );

    expect(find.byType(GezaYoApp), findsOneWidget);

    // Advance 3 seconds for splash screen navigation
    await tester.pump(const Duration(seconds: 3));
  });
}
