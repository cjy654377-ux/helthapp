// Repository Provider 정의
// 기본값: Local 구현체 (SharedPreferences)
// Firebase 연동 후 인증 상태에 따라 Firestore 구현체로 전환

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/local_data_repository.dart';

/// 운동 기록 Repository Provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return LocalWorkoutRepository();
});

/// 식단 Repository Provider
final dietRepositoryProvider = Provider<DietRepository>((ref) {
  return LocalDietRepository();
});

/// 수분 섭취 Repository Provider
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return LocalHydrationRepository();
});

/// 캘린더 Repository Provider
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return LocalCalendarRepository();
});

/// 커뮤니티 Repository Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return LocalCommunityRepository();
});
