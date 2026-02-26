// 앱 라우터 설정 - go_router를 사용한 네비게이션 구성
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/l10n/app_localizations.dart';

import 'package:health_app/core/widgets/bottom_nav_scaffold.dart';
import 'package:health_app/features/home/screens/home_screen.dart';
import 'package:health_app/features/home/screens/onboarding_screen.dart';
import 'package:health_app/features/home/screens/splash_screen.dart';
import 'package:health_app/features/workout_guide/screens/workout_guide_screen.dart';
import 'package:health_app/features/workout_guide/screens/programs_screen.dart';
import 'package:health_app/features/workout_guide/screens/video_workout_screen.dart';
import 'package:health_app/features/workout_log/screens/workout_log_screen.dart';
import 'package:health_app/features/profile/screens/recovery_heatmap_screen.dart';
import 'package:health_app/features/community/screens/community_screen.dart';
import 'package:health_app/features/community/screens/challenge_screen.dart';
import 'package:health_app/features/community/screens/social_feed_screen.dart';
import 'package:health_app/features/community/screens/leaderboard_screen.dart';
import 'package:health_app/features/diet/screens/diet_screen.dart';
import 'package:health_app/features/diet/screens/recipe_screen.dart';
import 'package:health_app/features/diet/screens/meal_photo_screen.dart';
import 'package:health_app/features/diet/screens/voice_logging_screen.dart';
import 'package:health_app/features/hydration/screens/hydration_screen.dart';
import 'package:health_app/features/calendar/screens/calendar_screen.dart';
import 'package:health_app/features/profile/screens/profile_screen.dart';
import 'package:health_app/features/profile/screens/settings_screen.dart';
import 'package:health_app/features/profile/screens/stats_screen.dart';
import 'package:health_app/features/profile/screens/habit_tracker_screen.dart';
import 'package:health_app/features/profile/screens/body_measurements_screen.dart';
import 'package:health_app/features/profile/screens/data_export_screen.dart';
import 'package:health_app/features/auth/screens/login_screen.dart';
import 'package:health_app/features/profile/screens/health_sync_screen.dart';

// ---------------------------------------------------------------------------
// 라우트 경로 상수
// ---------------------------------------------------------------------------

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String workoutGuide = '/workout-guide';
  static const String workoutLog = '/workout-guide/log';
  static const String community = '/community';
  static const String challenges = '/challenges';
  static const String diet = '/diet';
  static const String hydration = '/diet/hydration';
  static const String mealPhoto = '/diet/photo';
  static const String voiceLogging = '/diet/voice';
  static const String recipes = '/diet/recipes';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String stats = '/stats';
  static const String login = '/login';

  // 커뮤니티 서브 라우트
  static const String socialFeed = '/community/feed';
  static const String leaderboard = '/community/leaderboard';

  // 운동 프로그램 / 회복 히트맵
  static const String programs = '/workout-guide/programs';
  static const String videoWorkouts = '/workout-guide/videos';
  static const String recoveryHeatmap = '/recovery-heatmap';

  // 프로필 서브 화면
  static const String habitTracker = '/profile/habits';
  static const String bodyMeasurements = '/profile/measurements';
  static const String dataExport = '/profile/export';

  static const String healthSync = '/health-sync';

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
                  // 사전 제작 프로그램
                  GoRoute(
                    path: 'programs',
                    name: 'programs',
                    builder: (context, state) => const ProgramsScreen(),
                  ),
                  // 트레이너 주도 영상 운동 라이브러리
                  GoRoute(
                    path: 'videos',
                    name: 'video-workouts',
                    builder: (context, state) => const VideoWorkoutScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 탭 2: 커뮤니티 (소셜 피드 / 리더보드를 서브 라우트로 포함)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                name: 'community',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CommunityScreen(),
                ),
                routes: [
                  // 소셜 활동 피드
                  GoRoute(
                    path: 'feed',
                    name: 'social-feed',
                    builder: (context, state) => const SocialFeedScreen(),
                  ),
                  // 리더보드
                  GoRoute(
                    path: 'leaderboard',
                    name: 'leaderboard',
                    builder: (context, state) => const LeaderboardScreen(),
                  ),
                ],
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
                  // AI 음식 사진 인식
                  GoRoute(
                    path: 'photo',
                    name: 'meal-photo',
                    builder: (context, state) => const MealPhotoScreen(),
                  ),
                  // 음성 식단 기록
                  GoRoute(
                    path: 'voice',
                    name: 'voice-logging',
                    builder: (context, state) => const VoiceLoggingScreen(),
                  ),
                  // 레시피 & 식단 플래너
                  GoRoute(
                    path: 'recipes',
                    name: 'recipes',
                    builder: (context, state) => const RecipeScreen(),
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

      // 회복 히트맵
      GoRoute(
        path: AppRoutes.recoveryHeatmap,
        name: 'recovery-heatmap',
        builder: (context, state) => const RecoveryHeatmapScreen(),
      ),

      // 습관 추적기
      GoRoute(
        path: AppRoutes.habitTracker,
        name: 'habit-tracker',
        builder: (context, state) => const HabitTrackerScreen(),
      ),

      // 신체 측정
      GoRoute(
        path: AppRoutes.bodyMeasurements,
        name: 'body-measurements',
        builder: (context, state) => const BodyMeasurementsScreen(),
      ),

      // 데이터 내보내기
      GoRoute(
        path: AppRoutes.dataExport,
        name: 'data-export',
        builder: (context, state) => const DataExportScreen(),
      ),

      // Apple Health / Google Fit 동기화 화면
      GoRoute(
        path: AppRoutes.healthSync,
        name: 'health-sync',
        builder: (context, state) => const HealthSyncScreen(),
      ),
    ],

    // 에러 페이지 처리
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pageNotFound)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.requestedPageNotFound,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // 디버그 모드에서만 에러 상세 표시
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  state.error?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.goHome),
              ),
            ],
          ),
        ),
      );
    },
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
