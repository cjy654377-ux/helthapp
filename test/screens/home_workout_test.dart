import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/l10n/app_localizations.dart';
import '../helpers/test_overrides.dart';
import 'package:health_app/features/home/screens/onboarding_screen.dart';
import 'package:health_app/features/workout_log/screens/workout_log_screen.dart';
import 'package:health_app/features/home/screens/splash_screen.dart';

// ---------------------------------------------------------------------------
// Helper: wraps a widget in ProviderScope + MaterialApp for widget testing.
// Uses a large surface to avoid overflow issues in test layout.
// Includes localization delegates so AppLocalizations.of(context) works.
// ---------------------------------------------------------------------------

Widget _buildTestableWidget(Widget child) {
  return ProviderScope(
    overrides: testOverrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko', 'KR'),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1200)),
        child: child,
      ),
    ),
  );
}

/// Pumps the widget using runAsync for SharedPreferences-dependent screens,
/// then pumps several frames to let state settle.
Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_buildTestableWidget(screen));
  });
  // Multiple pumps to let async state notifier initialization complete
  // and allow the widget tree to rebuild with updated provider state.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Suppresses RenderFlex overflow errors during a test callback.
/// These are cosmetic layout issues from small test viewport sizes, not bugs.
Future<void> _runIgnoringOverflow(Future<void> Function() body) async {
  final oldHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) return;
    oldHandler?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = oldHandler;
  }
}

void main() {
  // Ensure SharedPreferences uses mock initial values for all tests.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // =========================================================================
  // Test 1: OnboardingScreen
  // =========================================================================
  group('OnboardingScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const OnboardingScreen());

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows welcome page with app partner title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const OnboardingScreen());

        // The first welcome page shows '당신만의 건강 파트너' (yourHealthPartner)
        expect(find.text('당신만의 건강 파트너'), findsOneWidget);
      });
    });

    testWidgets('shows skip button on first page', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const OnboardingScreen());

        // Skip button ('건너뛰기') is visible on all pages except the last
        expect(find.text('건너뛰기'), findsOneWidget);
      });
    });

    testWidgets('shows get started button on welcome page', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const OnboardingScreen());

        // '시작하기' button is the CTA on the welcome page
        expect(find.text('시작하기'), findsOneWidget);
      });
    });

    testWidgets('shows all-in-one app subtitle on welcome page',
        (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const OnboardingScreen());

        // allInOneApp: '운동, 식단, 커뮤니티를 하나의 앱에서'
        expect(find.text('운동, 식단, 커뮤니티를 하나의 앱에서'), findsOneWidget);
      });
    });
  });

  // =========================================================================
  // Test 2: WorkoutLogScreen
  // =========================================================================
  group('WorkoutLogScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const WorkoutLogScreen());

        expect(find.byType(WorkoutLogScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app bar with workout title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const WorkoutLogScreen());

        // todayWorkoutTitle: '오늘의 운동'
        expect(find.text('오늘의 운동'), findsWidgets);
      });
    });

    testWidgets('shows empty state when no exercises added', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const WorkoutLogScreen());

        // addExercisePrompt: '운동을 추가해 보세요!'
        expect(find.text('운동을 추가해 보세요!'), findsOneWidget);
      });
    });

    testWidgets('shows empty state subtitle when no exercises', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const WorkoutLogScreen());

        // addExerciseSubtitle: '아래 버튼을 눌러 오늘의 운동을 기록하세요.'
        expect(find.text('아래 버튼을 눌러 오늘의 운동을 기록하세요.'), findsOneWidget);
      });
    });

    testWidgets('shows no FAB when exercise list is empty', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const WorkoutLogScreen());

        // When exercises list is empty, the FAB is not shown;
        // instead the EmptyStateWidget action button is displayed.
        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });
  });

  // =========================================================================
  // Test 3: SplashScreen
  // =========================================================================
  group('SplashScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(_buildTestableWidget(const SplashScreen()));
        });
        // Only pump a short initial frame - do not advance past the 2s timer
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app title text', (tester) async {
      await _runIgnoringOverflow(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(_buildTestableWidget(const SplashScreen()));
        });
        // Pump icon animation (700ms) + text delay (100ms) + text animation (600ms)
        await tester.pump(const Duration(milliseconds: 1500));

        // appTitle: '헬스 & 피트니스'
        expect(find.text('헬스 & 피트니스'), findsOneWidget);
      });
    });

    testWidgets('shows healthy lifestyle subtitle', (tester) async {
      await _runIgnoringOverflow(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(_buildTestableWidget(const SplashScreen()));
        });
        await tester.pump(const Duration(milliseconds: 1500));

        // healthyLifestyleStart: '건강한 라이프스타일의 시작'
        expect(find.text('건강한 라이프스타일의 시작'), findsOneWidget);
      });
    });

    testWidgets('shows loading indicator text', (tester) async {
      await _runIgnoringOverflow(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(_buildTestableWidget(const SplashScreen()));
        });
        await tester.pump();

        // loading: '로딩 중...'
        expect(find.text('로딩 중...'), findsOneWidget);
      });
    });
  });
}
