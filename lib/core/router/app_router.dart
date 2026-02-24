// 앱 라우터 설정 - go_router를 사용한 네비게이션 구성
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/widgets/bottom_nav_scaffold.dart';
import 'package:health_app/features/home/screens/home_screen.dart';
import 'package:health_app/features/home/screens/onboarding_screen.dart';
import 'package:health_app/features/home/screens/splash_screen.dart';
import 'package:health_app/features/workout_guide/screens/workout_guide_screen.dart';
import 'package:health_app/features/workout_log/screens/workout_log_screen.dart';
import 'package:health_app/features/community/screens/community_screen.dart';
import 'package:health_app/features/community/screens/challenge_screen.dart';
import 'package:health_app/features/diet/screens/diet_screen.dart';
import 'package:health_app/features/hydration/screens/hydration_screen.dart';
import 'package:health_app/features/calendar/screens/calendar_screen.dart';
import 'package:health_app/features/profile/screens/profile_screen.dart';
import 'package:health_app/features/profile/screens/settings_screen.dart';
import 'package:health_app/features/profile/screens/stats_screen.dart';
import 'package:health_app/features/auth/screens/login_screen.dart';

// ---------------------------------------------------------------------------
// 라우트 경로 상수
// ---------------------------------------------------------------------------

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String workoutGuide = '/workout-guide';
  static const String workoutLog = '/workout-log';
  static const String community = '/community';
  static const String challenges = '/challenges';
  static const String diet = '/diet';
  static const String hydration = '/hydration';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String stats = '/stats';
  static const String login = '/login';

  // 프라이빗 생성자 - 인스턴스화 방지
  AppRoutes._();
}

// ---------------------------------------------------------------------------
// 라우터 Provider
// ---------------------------------------------------------------------------

/// 앱 전체에서 사용되는 GoRouter 인스턴스를 제공하는 Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

// ---------------------------------------------------------------------------
// AppRouter
// ---------------------------------------------------------------------------

class AppRouter {
  // 바텀 탭 인덱스와 경로 매핑
  // 탭 순서: 홈(0), 운동(1), 커뮤니티(2), 식단(3), 캘린더(4)
  static const List<String> _tabRoots = [
    AppRoutes.home,
    AppRoutes.workoutGuide,
    AppRoutes.community,
    AppRoutes.diet,
    AppRoutes.calendar,
  ];

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    routes: [
      // ------------------------------------------------------------------
      // 스플래시 라우트 - 앱 시작 시 초기화 및 온보딩 분기 처리
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ------------------------------------------------------------------
      // 로그인 라우트 - 바텀 네비게이션 없이 전체 화면
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ------------------------------------------------------------------
      // 온보딩 라우트 - 바텀 네비게이션 없이 전체 화면
      // ------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ------------------------------------------------------------------
      // Shell Route - 바텀 네비게이션을 포함하는 셸
      // StatefulShellRoute.indexedStack을 사용하여 각 탭의 상태를 유지합니다.
      // ------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(
            currentIndex: navigationShell.currentIndex,
            navigationShell: navigationShell,
          );
        },
        branches: [
          // 탭 0: 홈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // 탭 1: 운동 (운동 가이드 + 운동 기록을 하나의 탭으로)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workoutGuide,
                name: 'workout-guide',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: WorkoutGuideScreen(),
                ),
                routes: [
                  // 운동 기록은 운동 가이드의 서브 라우트
                  GoRoute(
                    path: 'log',
                    name: 'workout-log',
                    builder: (context, state) => const WorkoutLogScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 탭 2: 커뮤니티
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                name: 'community',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CommunityScreen(),
                ),
              ),
            ],
          ),

          // 탭 3: 식단 (식단 + 수분 섭취)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.diet,
                name: 'diet',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DietScreen(),
                ),
                routes: [
                  // 수분 섭취는 식단 탭의 서브 라우트
                  GoRoute(
                    path: 'hydration',
                    name: 'hydration',
                    builder: (context, state) => const HydrationScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 탭 4: 캘린더 (캘린더 + 프로필)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
                routes: [
                  // 프로필은 캘린더 탭의 서브 라우트
                  GoRoute(
                    path: 'profile',
                    name: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ------------------------------------------------------------------
      // 독립 라우트 - 바텀 네비게이션 없이 전체 화면으로 표시
      // ------------------------------------------------------------------

      // 설정 화면
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // 통계 화면
      GoRoute(
        path: AppRoutes.stats,
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),

      // 챌린지 화면
      GoRoute(
        path: AppRoutes.challenges,
        name: 'challenges',
        builder: (context, state) => const ChallengeScreen(),
      ),
    ],

    // 에러 페이지 처리
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('페이지를 찾을 수 없음')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '요청한 페이지를 찾을 수 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );

  // 프라이빗 생성자 - 인스턴스화 방지
  AppRouter._();

  /// 현재 경로로부터 탭 인덱스를 반환합니다.
  static int getTabIndexFromPath(String path) {
    for (int i = 0; i < _tabRoots.length; i++) {
      if (path.startsWith(_tabRoots[i])) {
        return i;
      }
    }
    return 0;
  }
}
