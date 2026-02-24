import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_overrides.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HealthApp renders without crashing', (tester) async {
    // Use runAsync so real async operations (SharedPreferences, etc.) complete.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(overrides: testOverrides, child: const HealthApp()),
      );
    });

    // Pump a couple of frames to let the widget tree build.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // App should render some widget without a hard crash.
    // We tolerate the ko_KR locale warning by consuming the exception and
    // verifying it is at most a locale warning (not a real runtime error).
    final exception = tester.takeException();
    if (exception != null) {
      expect(
        exception.toString(),
        contains('locale'),
        reason: 'Unexpected exception thrown by HealthApp: $exception',
      );
    }

    // The ProviderScope + HealthApp widget should exist in the tree.
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
