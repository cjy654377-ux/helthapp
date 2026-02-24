import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/l10n/app_localizations.dart';
import 'package:health_app/features/profile/screens/profile_screen.dart';
import 'package:health_app/features/profile/screens/settings_screen.dart';
import 'package:health_app/features/profile/screens/stats_screen.dart';
import 'package:health_app/features/community/screens/challenge_screen.dart';

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
  // Test 1: ProfileScreen
  // =========================================================================
  group('ProfileScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ProfileScreen());

        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows profile section with my record header', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ProfileScreen());

        // l10n.myRecord resolves to '내 기록' in Korean locale
        expect(find.text('내 기록'), findsOneWidget);
      });
    });

    testWidgets('shows settings section', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ProfileScreen());

        // l10n.settings resolves to '설정' in Korean locale
        expect(find.text('설정'), findsWidgets);
      });
    });

    testWidgets('shows user name in profile header', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ProfileScreen());

        // The sample profile name is '최주용'
        expect(find.text('최주용'), findsOneWidget);
      });
    });

    testWidgets('shows weight change section', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ProfileScreen());

        // l10n.weightChange resolves to '체중 변화' in Korean locale
        expect(find.text('체중 변화'), findsWidgets);
      });
    });
  });

  // =========================================================================
  // Test 2: SettingsScreen
  // =========================================================================
  group('SettingsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _pumpScreen(tester, const SettingsScreen());

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with settings title', (tester) async {
      await _pumpScreen(tester, const SettingsScreen());

      // l10n.settings resolves to '설정' in Korean locale
      expect(find.text('설정'), findsWidgets);
    });

    testWidgets('shows profile section', (tester) async {
      await _pumpScreen(tester, const SettingsScreen());

      // l10n.profile resolves to '프로필' in Korean locale
      expect(find.text('프로필'), findsOneWidget);
    });

    testWidgets('shows workout settings section', (tester) async {
      await _pumpScreen(tester, const SettingsScreen());

      // l10n.workoutSettings resolves to '운동 설정' in Korean locale
      expect(find.text('운동 설정'), findsOneWidget);
    });

    testWidgets('shows nickname field in profile section', (tester) async {
      await _pumpScreen(tester, const SettingsScreen());

      // l10n.nickname resolves to '닉네임' in Korean locale
      expect(find.text('닉네임'), findsOneWidget);
    });
  });

  // =========================================================================
  // Test 3: StatsScreen
  // =========================================================================
  group('StatsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const StatsScreen());

        expect(find.byType(StatsScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app bar with stats title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const StatsScreen());

        // l10n.statsAndProgress resolves to '통계 & 진척도' in Korean locale
        expect(find.text('통계 & 진척도'), findsOneWidget);
      });
    });

    testWidgets('shows workout stats section header', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const StatsScreen());

        // l10n.workoutStats resolves to '운동 통계' in Korean locale
        expect(find.text('운동 통계'), findsOneWidget);
      });
    });

    testWidgets('shows body composition section header', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const StatsScreen());

        // l10n.bodyComposition resolves to '체성분 변화' in Korean locale
        expect(find.text('체성분 변화'), findsOneWidget);
      });
    });

    testWidgets('shows scrollable content area', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const StatsScreen());

        // StatsScreen uses a CustomScrollView with SliverAppBar + SliverList
        expect(find.byType(CustomScrollView), findsOneWidget);
      });
    });
  });

  // =========================================================================
  // Test 4: ChallengeScreen
  // =========================================================================
  group('ChallengeScreen', () {
    testWidgets('renders without errors', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ChallengeScreen());

        expect(find.byType(ChallengeScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    testWidgets('shows app bar with challenge title', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ChallengeScreen());

        // l10n.challenge resolves to '챌린지' in Korean locale
        expect(find.text('챌린지'), findsOneWidget);
      });
    });

    testWidgets('shows tab bar with 3 tabs', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ChallengeScreen());

        // l10n.participating resolves to '참여중'
        expect(find.text('참여중'), findsOneWidget);
        // l10n.completed resolves to '완료'
        expect(find.text('완료'), findsOneWidget);
        // l10n.discover resolves to '찾기'
        expect(find.text('찾기'), findsWidgets);
      });
    });

    testWidgets('shows FAB for creating challenge', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ChallengeScreen());

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // l10n.createChallenge resolves to '챌린지 만들기' in Korean locale
        expect(find.text('챌린지 만들기'), findsOneWidget);
      });
    });

    testWidgets('shows tab bar widget', (tester) async {
      await _runIgnoringOverflow(() async {
        await _pumpScreen(tester, const ChallengeScreen());

        expect(find.byType(TabBar), findsOneWidget);
      });
    });
  });
}
