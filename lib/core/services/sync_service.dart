import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/constants/app_constants.dart';
import 'package:health_app/core/repositories/local_data_repository.dart';
import 'package:health_app/core/repositories/firestore_data_repository.dart';

// 로컬 → Firestore 데이터 동기화 서비스
class SyncService {
  final String uid;

  SyncService({required this.uid});

  /// 첫 로그인 시 로컬 데이터를 Firestore로 마이그레이션
  /// SharedPreferences에 'synced_{uid}' 키로 동기화 완료 여부 관리
  Future<void> migrateLocalToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'synced_$uid';

    // 이미 동기화 완료면 스킵
    if (prefs.getBool(syncKey) == true) return;

    // 각 로컬 레포지토리에서 데이터 읽기
    final localWorkout = LocalWorkoutRepository();
    final localDiet = LocalDietRepository();
    final localHydration = LocalHydrationRepository();
    final localCalendar = LocalCalendarRepository();
    final localCommunity = LocalCommunityRepository();

    // Firestore 레포지토리에 쓰기
    final fsWorkout = FirestoreWorkoutRepository(uid: uid);
    final fsDiet = FirestoreDietRepository(uid: uid);
    final fsHydration = FirestoreHydrationRepository(uid: uid);
    final fsCalendar = FirestoreCalendarRepository(uid: uid);
    final fsCommunity = FirestoreCommunityRepository(uid: uid);

    // 1. 운동 기록 마이그레이션
    final workouts = await localWorkout.loadHistory();
    if (workouts.isNotEmpty) {
      await fsWorkout.saveAllRecords(workouts);
    }

    final prs = await localWorkout.loadPersonalRecords();
    if (prs.isNotEmpty) {
      await fsWorkout.savePersonalRecords(prs);
    }

    // 2. 식단 마이그레이션 - 최근 7일치
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = AppDefaults.dateKey(date);
      final meals = await localDiet.loadMeals(dateKey);
      if (meals.isNotEmpty) {
        await fsDiet.saveMeals(dateKey, meals);
      }
    }

    final nutritionGoal = await localDiet.loadNutritionGoal();
    await fsDiet.saveNutritionGoal(nutritionGoal);

    final recentFoods = await localDiet.loadRecentFoodIds();
    if (recentFoods.isNotEmpty) {
      await fsDiet.saveRecentFoodIds(recentFoods);
    }

    // 3. 수분 마이그레이션 - 최근 7일치
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = AppDefaults.dateKey(date);
      final hydData = await localHydration.loadHydrationData(dateKey);
      if (hydData.isNotEmpty) {
        await fsHydration.saveHydrationData(dateKey, hydData);
      }
    }

    final hydSettings = await localHydration.loadHydrationSettings();
    if (hydSettings.isNotEmpty) {
      await fsHydration.saveHydrationSettings(hydSettings);
    }

    // 4. 캘린더 마이그레이션
    final plans = await localCalendar.loadAllPlans();
    if (plans.isNotEmpty) {
      await fsCalendar.saveAllPlans(plans);
    }

    // 5. 커뮤니티 프로필 마이그레이션
    final userProfile = await localCommunity.loadCurrentUser();
    if (userProfile != null) {
      await fsCommunity.saveCurrentUser(userProfile);
    }

    final teams = await localCommunity.loadMyTeams();
    if (teams.isNotEmpty) {
      await fsCommunity.saveMyTeams(teams);
    }

    // 6. 챌린지 마이그레이션
    final localChallenge = LocalChallengeRepository();
    final fsChallenge = FirestoreChallengeRepository(uid: uid);

    final activeChallenges = await localChallenge.loadActiveChallenges();
    if (activeChallenges.isNotEmpty) {
      await fsChallenge.saveActiveChallenges(activeChallenges);
    }

    final completedChallenges = await localChallenge.loadCompletedChallenges();
    if (completedChallenges.isNotEmpty) {
      await fsChallenge.saveCompletedChallenges(completedChallenges);
    }

    // 7. 업적 마이그레이션
    final localAchievement = LocalAchievementRepository();
    final fsAchievement = FirestoreAchievementRepository(uid: uid);

    final unlockedIds = await localAchievement.loadUnlockedIds();
    if (unlockedIds.isNotEmpty) {
      await fsAchievement.saveUnlockedIds(unlockedIds);
    }

    final progressCounts = await localAchievement.loadProgressCounts();
    if (progressCounts.isNotEmpty) {
      await fsAchievement.saveProgressCounts(progressCounts);
    }

    // 동기화 완료 표시
    await prefs.setBool(syncKey, true);
  }
}

/// SyncService Riverpod Provider
final syncServiceProvider = Provider.family<SyncService, String>((ref, uid) {
  return SyncService(uid: uid);
});
