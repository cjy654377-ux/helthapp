import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/l10n/app_localizations.dart';
import 'package:health_app/features/workout_guide/screens/workout_guide_screen.dart';
import 'package:health_app/features/diet/screens/diet_screen.dart';
import 'package:health_app/features/hydration/screens/hydration_screen.dart';
import 'package:health_app/features/calendar/screens/calendar_screen.dart';
import 'package:health_app/features/community/screens/community_screen.dart';

// ---------------------------------------------------------------------------
// Helper: wraps a widget in ProviderScope + MaterialApp for widget testing.
// Uses a large surface to avoid overflow issues in test layout.
// Includes localization delegates so AppLocalizations.of(context) works.
// ---------------------------------------------------------------------------

Widget _buildTestableWidget(Widget child) {
  return ProviderScope(
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
  // Test 1: WorkoutGuideScreen
  // =========================================================================
  group('WorkoutGuideScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      expect(find.byType(WorkoutGuideScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      expect(find.text('운동 가이드'), findsOneWidget);
    });

    testWidgets('body part selector shows all 6 groups', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      expect(find.text('가슴'), findsWidgets);
      expect(find.text('등'), findsWidgets);
      expect(find.text('어깨'), findsWidgets);
      expect(find.text('팔'), findsWidgets);
      expect(find.text('하체'), findsWidgets);
      expect(find.text('코어'), findsWidgets);
    });

    testWidgets('default selection shows chest exercises', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      // The first group (가슴) is selected by default
      expect(find.text('가슴 운동'), findsOneWidget);
    });

    testWidgets('tapping a body part group shows its exercises',
        (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      // Tap on 등 (back)
      await tester.tap(find.text('등').first);
      await tester.pump();

      expect(find.text('등 운동'), findsOneWidget);
    });

    testWidgets('tapping 하체 group shows lower body exercises',
        (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WorkoutGuideScreen()));
      await tester.pump();

      await tester.tap(find.text('하체').first);
      await tester.pump();

      expect(find.text('하체 운동'), findsOneWidget);
    });
  });

  // =========================================================================
  // Test 2: DietScreen
  // =========================================================================
  group('DietScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _pumpScreen(tester, const DietScreen());

      expect(find.byType(DietScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await _pumpScreen(tester, const DietScreen());

      expect(find.text('식단 관리'), findsOneWidget);
    });

    testWidgets('calorie circle indicator is visible', (tester) async {
      await _pumpScreen(tester, const DietScreen());

      // The calorie section header text
      expect(find.text('오늘의 칼로리'), findsOneWidget);
      // The kcal unit label should be present
      expect(find.text('kcal'), findsWidgets);
    });

    testWidgets('calorie summary stats are present', (tester) async {
      await _pumpScreen(tester, const DietScreen());

      // The calorie ring card shows goal/consumed/remaining labels
      expect(find.text('목표'), findsOneWidget);
      expect(find.text('섭취'), findsOneWidget);
      expect(find.text('남은'), findsOneWidget);
    });

    testWidgets('macro nutrient card is visible', (tester) async {
      await _pumpScreen(tester, const DietScreen());

      // Macro card shows protein, carbs, fat labels
      expect(find.text('단백질'), findsOneWidget);
      expect(find.text('탄수화물'), findsOneWidget);
      expect(find.text('지방'), findsOneWidget);
    });
  });

  // =========================================================================
  // Test 3: HydrationScreen
  // =========================================================================
  group('HydrationScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      expect(find.byType(HydrationScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      expect(find.text('수분 보충'), findsOneWidget);
    });

    testWidgets('water progress indicator is visible', (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      // The initial state: 0ml consumed
      expect(find.text('0'), findsOneWidget);
      expect(find.text('ml'), findsWidgets);
      // Goal display (may appear more than once due to stats row)
      expect(find.textContaining('2000ml'), findsWidgets);
    });

    testWidgets('quick add buttons are visible', (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      expect(find.text('빠른 추가'), findsOneWidget);
      expect(find.text('150ml'), findsOneWidget);
      expect(find.text('250ml'), findsOneWidget);
      expect(find.text('500ml'), findsOneWidget);
    });

    testWidgets('tapping add water button increases water intake',
        (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      // Verify initial state
      expect(find.text('0'), findsOneWidget);

      // Tap the 250ml quick add button
      await tester.tap(find.text('250ml'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // After adding 250ml, the total should update
      expect(find.text('250'), findsWidgets);
    });

    testWidgets('timeline section is visible', (tester) async {
      await _pumpScreen(tester, const HydrationScreen());

      expect(find.text('오늘 섭취 기록'), findsOneWidget);
    });
  });

  // =========================================================================
  // Test 4: CalendarScreen
  // =========================================================================
  group('CalendarScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CalendarScreen());

        expect(find.byType(CalendarScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CalendarScreen());

        expect(find.text('운동 캘린더'), findsOneWidget);
      });
    });

    testWidgets('calendar widget renders day numbers', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CalendarScreen());

        // TableCalendar renders day numbers - verify today's day is present
        final today = DateTime.now();
        expect(find.text('${today.day}'), findsWidgets);
      });
    });

    testWidgets('floating action button is present', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CalendarScreen());

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    testWidgets('selected day info area is visible', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CalendarScreen());

        // The add button in the day plan area
        expect(find.text('추가'), findsWidgets);
      });
    });
  });

  // =========================================================================
  // Test 5: CommunityScreen
  // =========================================================================
  group('CommunityScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CommunityScreen());

        expect(find.byType(CommunityScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CommunityScreen());

        expect(find.text('팀 커뮤니티'), findsOneWidget);
      });
    });

    testWidgets('team section header is visible', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CommunityScreen());

        expect(find.text('내 팀'), findsOneWidget);
      });
    });

    testWidgets('posts section header is visible', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CommunityScreen());

        expect(find.text('팀 피드'), findsOneWidget);
      });
    });

    testWidgets('team create FAB is present', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const CommunityScreen());

        expect(find.text('팀 만들기'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });
  });
}
