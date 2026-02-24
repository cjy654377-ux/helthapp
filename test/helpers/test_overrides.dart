// 테스트용 Repository Override
// Firebase 의존성 없이 Local 구현체를 직접 주입
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/repositories/repository_providers.dart';
import 'package:health_app/core/repositories/local_data_repository.dart';

/// 테스트에서 사용할 Repository Provider Override 목록
/// Firebase 초기화 없이 Local(SharedPreferences) 구현체 사용
final testOverrides = <Override>[
  workoutRepositoryProvider.overrideWithValue(LocalWorkoutRepository()),
  dietRepositoryProvider.overrideWithValue(LocalDietRepository()),
  hydrationRepositoryProvider.overrideWithValue(LocalHydrationRepository()),
  calendarRepositoryProvider.overrideWithValue(LocalCalendarRepository()),
  communityRepositoryProvider.overrideWithValue(LocalCommunityRepository()),
  challengeRepositoryProvider.overrideWithValue(LocalChallengeRepository()),
  achievementRepositoryProvider.overrideWithValue(LocalAchievementRepository()),
];
