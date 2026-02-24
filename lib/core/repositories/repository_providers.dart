// Repository Provider 정의
// 인증 상태에 따라 Local(SharedPreferences) 또는 Firestore 구현체 전환

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/local_data_repository.dart';
import 'package:health_app/core/repositories/firestore_data_repository.dart';
import 'package:health_app/features/auth/providers/auth_providers.dart';

/// 운동 기록 Repository Provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreWorkoutRepository(uid: authState.user!.uid);
  }
  return LocalWorkoutRepository();
});

/// 식단 Repository Provider
final dietRepositoryProvider = Provider<DietRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreDietRepository(uid: authState.user!.uid);
  }
  return LocalDietRepository();
});

/// 수분 섭취 Repository Provider
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreHydrationRepository(uid: authState.user!.uid);
  }
  return LocalHydrationRepository();
});

/// 캘린더 Repository Provider
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreCalendarRepository(uid: authState.user!.uid);
  }
  return LocalCalendarRepository();
});

/// 커뮤니티 Repository Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreCommunityRepository(uid: authState.user!.uid);
  }
  return LocalCommunityRepository();
});

/// 챌린지 Repository Provider
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isAuthenticated && authState.user != null) {
    return FirestoreChallengeRepository(uid: authState.user!.uid);
  }
  return LocalChallengeRepository();
});
