import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/services/achievement_service.dart';

// ---------------------------------------------------------------------------
// Fake AchievementRepository for testing (avoids SharedPreferences)
// ---------------------------------------------------------------------------

class FakeAchievementRepository implements AchievementRepository {
  List<String> _unlockedIds = [];
  Map<String, int> _progressCounts = {};

  @override
  Future<List<String>> loadUnlockedIds() async => List.from(_unlockedIds);

  @override
  Future<void> saveUnlockedIds(List<String> ids) async {
    _unlockedIds = List.from(ids);
  }

  @override
  Future<Map<String, int>> loadProgressCounts() async =>
      Map.from(_progressCounts);

  @override
  Future<void> saveProgressCounts(Map<String, int> counts) async {
    _progressCounts = Map.from(counts);
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // Achievement model tests
  // ---------------------------------------------------------------------------
  group('Achievement model', () {
    test('has correct fields', () {
      const a = Achievement(
        id: 'test_ach',
        titleKey: 'achievementTestTitle',
        descriptionKey: 'achievementTestDesc',
        icon: '🏆',
        category: AchievementCategory.workout,
        requiredCount: 10,
        points: 50,
      );
      expect(a.id, 'test_ach');
      expect(a.titleKey, 'achievementTestTitle');
      expect(a.requiredCount, 10);
      expect(a.points, 50);
      expect(a.category, AchievementCategory.workout);
    });

    test('equality is based on id', () {
      const a1 = Achievement(
        id: 'same',
        titleKey: 'keyA',
        descriptionKey: 'descKeyA',
        icon: '🔥',
        category: AchievementCategory.workout,
      );
      const a2 = Achievement(
        id: 'same',
        titleKey: 'keyB',
        descriptionKey: 'descKeyB',
        icon: '⭐',
        category: AchievementCategory.diet,
      );
      expect(a1, equals(a2));
    });

    test('default requiredCount is 1 and points is 10', () {
      const a = Achievement(
        id: 'default_ach',
        titleKey: 'achievementDefaultTitle',
        descriptionKey: 'achievementDefaultDesc',
        icon: '✅',
        category: AchievementCategory.streak,
      );
      expect(a.requiredCount, 1);
      expect(a.points, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // AchievementProgress model tests
  // ---------------------------------------------------------------------------
  group('AchievementProgress', () {
    const achievement = Achievement(
      id: 'prog_test',
      titleKey: 'achievementProgTestTitle',
      descriptionKey: 'achievementProgTestDesc',
      icon: '🎯',
      category: AchievementCategory.workout,
      requiredCount: 10,
      points: 20,
    );

    test('progress ratio is currentCount / requiredCount', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 5,
        isUnlocked: false,
      );
      expect(progress.progress, closeTo(0.5, 0.001));
    });

    test('progress is clamped to 1.0 when count exceeds required', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 15,
        isUnlocked: false,
      );
      expect(progress.progress, closeTo(1.0, 0.001));
    });

    test('progress is 0 when count is 0', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 0,
        isUnlocked: false,
      );
      expect(progress.progress, closeTo(0.0, 0.001));
    });

    test('progress returns 1.0 when unlocked', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 10,
        isUnlocked: true,
      );
      expect(progress.progress, closeTo(1.0, 0.001));
    });

    test('remaining is requiredCount - currentCount', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 3,
        isUnlocked: false,
      );
      expect(progress.remaining, 7);
    });

    test('remaining is 0 when at or past required count', () {
      const progress = AchievementProgress(
        achievement: achievement,
        currentCount: 10,
        isUnlocked: false,
      );
      expect(progress.remaining, 0);

      const overProgress = AchievementProgress(
        achievement: achievement,
        currentCount: 15,
        isUnlocked: false,
      );
      expect(overProgress.remaining, 0);
    });

    test('progress for zero requiredCount achievement', () {
      const zeroAch = Achievement(
        id: 'zero_req',
        titleKey: 'achievementZeroReqTitle',
        descriptionKey: 'achievementZeroReqDesc',
        icon: '✨',
        category: AchievementCategory.special,
        requiredCount: 0,
      );

      const locked = AchievementProgress(
        achievement: zeroAch,
        currentCount: 0,
        isUnlocked: false,
      );
      expect(locked.progress, 0.0);

      const unlocked = AchievementProgress(
        achievement: zeroAch,
        currentCount: 0,
        isUnlocked: true,
      );
      expect(unlocked.progress, 1.0);
    });

    test('copyWith updates specified fields', () {
      const original = AchievementProgress(
        achievement: achievement,
        currentCount: 5,
        isUnlocked: false,
      );
      final updated = original.copyWith(currentCount: 8);
      expect(updated.currentCount, 8);
      expect(updated.isUnlocked, original.isUnlocked);
      expect(updated.achievement, original.achievement);
    });
  });

  // ---------------------------------------------------------------------------
  // UserStats model tests
  // ---------------------------------------------------------------------------
  group('UserStats', () {
    test('all default values are zero / false', () {
      const stats = UserStats();
      expect(stats.totalWorkouts, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.maxSessionVolume, 0.0);
      expect(stats.hasPersonalRecord, isFalse);
      expect(stats.totalWaterGoalDays, 0);
      expect(stats.dietLogStreak, 0);
      expect(stats.hasJoinedTeam, isFalse);
      expect(stats.consecutiveWaterDays, 0);
    });

    test('copyWith updates only specified fields', () {
      const original = UserStats(totalWorkouts: 5, currentStreak: 3);
      final updated = original.copyWith(totalWorkouts: 10);
      expect(updated.totalWorkouts, 10);
      expect(updated.currentStreak, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // AchievementService static data tests
  // ---------------------------------------------------------------------------
  group('AchievementService static data', () {
    test('achievements list is not empty', () {
      expect(AchievementService.achievements, isNotEmpty);
    });

    test('achievements list has at least 15 achievements', () {
      expect(AchievementService.achievements.length,
          greaterThanOrEqualTo(15));
    });

    test('all achievement ids are unique', () {
      final ids = AchievementService.achievements.map((a) => a.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('first_workout achievement exists with correct config', () {
      final ach = AchievementService.achievements
          .firstWhere((a) => a.id == 'first_workout');
      expect(ach.category, AchievementCategory.workout);
      expect(ach.requiredCount, 1);
      expect(ach.points, 10);
    });

    test('streak achievements exist with correct required counts', () {
      final streak3 = AchievementService.achievements
          .firstWhere((a) => a.id == 'streak_3');
      final streak7 = AchievementService.achievements
          .firstWhere((a) => a.id == 'streak_7');
      final streak30 = AchievementService.achievements
          .firstWhere((a) => a.id == 'streak_30');

      expect(streak3.requiredCount, 3);
      expect(streak3.category, AchievementCategory.streak);
      expect(streak7.requiredCount, 7);
      expect(streak30.requiredCount, 30);
    });

    test('volume_1000 achievement exists', () {
      final ach = AchievementService.achievements
          .firstWhere((a) => a.id == 'volume_1000');
      expect(ach.category, AchievementCategory.workout);
      expect(ach.points, greaterThan(0));
    });

    test('all achievements have non-empty titleKey, descriptionKey, and icon', () {
      for (final ach in AchievementService.achievements) {
        expect(ach.titleKey, isNotEmpty,
            reason: 'Achievement ${ach.id} has empty titleKey');
        expect(ach.descriptionKey, isNotEmpty,
            reason: 'Achievement ${ach.id} has empty descriptionKey');
        expect(ach.icon, isNotEmpty,
            reason: 'Achievement ${ach.id} has empty icon');
      }
    });

    test('all achievements have positive points', () {
      for (final ach in AchievementService.achievements) {
        expect(ach.points, greaterThan(0),
            reason: 'Achievement ${ach.id} has non-positive points');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // AchievementService logic tests
  // ---------------------------------------------------------------------------
  group('AchievementService logic', () {
    late AchievementService service;

    setUp(() {
      service = AchievementService(FakeAchievementRepository());
    });

    test('initial state has no unlocked achievements', () {
      expect(service.unlockedAchievements, isEmpty);
      expect(service.unlockedCount, 0);
      expect(service.totalCount, AchievementService.achievements.length);
      expect(service.completionRate, 0.0);
      expect(service.totalPoints, 0);
    });

    test('isUnlocked returns false before any achievement unlocked', () {
      expect(service.isUnlocked('first_workout'), isFalse);
      expect(service.isUnlocked('streak_3'), isFalse);
    });

    test('checkAchievements unlocks first_workout when totalWorkouts >= 1',
        () async {
      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('first_workout'), isTrue);
    });

    test('checkAchievements does not unlock first_workout when no workouts',
        () async {
      const stats = UserStats(totalWorkouts: 0);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('first_workout'), isFalse);
    });

    test('checkAchievements unlocks streak_3 when currentStreak >= 3',
        () async {
      const stats = UserStats(currentStreak: 3);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('streak_3'), isTrue);
    });

    test('checkAchievements unlocks streak_3 via longestStreak >= 3',
        () async {
      const stats = UserStats(longestStreak: 3);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('streak_3'), isTrue);
    });

    test('checkAchievements unlocks streak_7 when longestStreak >= 7',
        () async {
      const stats = UserStats(longestStreak: 7);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('streak_7'), isTrue);
    });

    test('checkAchievements unlocks streak_30 when currentStreak >= 30',
        () async {
      const stats = UserStats(currentStreak: 30);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('streak_30'), isTrue);
    });

    test('streak_7 unlock also satisfies streak_3 condition', () async {
      const stats = UserStats(currentStreak: 7);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('streak_3'), isTrue);
      expect(service.isUnlocked('streak_7'), isTrue);
    });

    test(
        'checkAchievements unlocks volume_1000 when maxSessionVolume >= 1000',
        () async {
      const stats = UserStats(maxSessionVolume: 1000.0);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('volume_1000'), isTrue);
    });

    test('volume_1000 not unlocked when volume just under threshold',
        () async {
      const stats = UserStats(maxSessionVolume: 999.9);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('volume_1000'), isFalse);
    });

    test(
        'checkAchievements unlocks pr_first when hasPersonalRecord is true',
        () async {
      const stats = UserStats(hasPersonalRecord: true);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('pr_first'), isTrue);
    });

    test(
        'checkAchievements unlocks water_first_goal when totalWaterGoalDays >= 1',
        () async {
      const stats = UserStats(totalWaterGoalDays: 1);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('water_first_goal'), isTrue);
    });

    test(
        'checkAchievements unlocks water_master when totalWaterGoalDays >= 7',
        () async {
      const stats = UserStats(totalWaterGoalDays: 7);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('water_first_goal'), isTrue);
      expect(service.isUnlocked('water_master'), isTrue);
    });

    test(
        'checkAchievements unlocks water_streak_30 when consecutiveWaterDays >= 30',
        () async {
      const stats = UserStats(consecutiveWaterDays: 30);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('water_streak_30'), isTrue);
    });

    test('checkAchievements unlocks workout_10 when totalWorkouts >= 10',
        () async {
      const stats = UserStats(totalWorkouts: 10);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('workout_10'), isTrue);
    });

    test('checkAchievements unlocks workout_50 when totalWorkouts >= 50',
        () async {
      const stats = UserStats(totalWorkouts: 50);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('workout_10'), isTrue);
      expect(service.isUnlocked('workout_50'), isTrue);
    });

    test('checkAchievements unlocks workout_100 when totalWorkouts >= 100',
        () async {
      const stats = UserStats(totalWorkouts: 100);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('workout_100'), isTrue);
    });

    test('checkAchievements unlocks team_join when hasJoinedTeam is true',
        () async {
      const stats = UserStats(hasJoinedTeam: true);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('team_join'), isTrue);
    });

    test(
        'checkAchievements unlocks social_butterfly when teamInteractions >= 10',
        () async {
      const stats = UserStats(teamInteractions: 10);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('social_butterfly'), isTrue);
    });

    test(
        'checkAchievements unlocks body_transformation when weight change >= 5kg',
        () async {
      const lose5 = UserStats(bodyWeightChange: -5.0);
      await service.checkAchievements(lose5);
      expect(service.isUnlocked('body_transformation'), isTrue);
    });

    test(
        'body_transformation requires at least 5kg change in either direction',
        () async {
      // Positive 5kg change also qualifies
      const gain5 = UserStats(bodyWeightChange: 5.0);
      await service.checkAchievements(gain5);
      expect(service.isUnlocked('body_transformation'), isTrue);

      // Under threshold does not qualify
      final fresh = AchievementService(FakeAchievementRepository());
      const under = UserStats(bodyWeightChange: 4.9);
      await fresh.checkAchievements(under);
      expect(fresh.isUnlocked('body_transformation'), isFalse);
    });

    test('already unlocked achievements are not re-unlocked', () async {
      int callbackCount = 0;
      service.onAchievementUnlocked = (_) => callbackCount++;

      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);
      final firstCount = callbackCount;

      await service.checkAchievements(stats); // same stats again
      expect(callbackCount, firstCount); // no new callbacks
    });

    test('onAchievementUnlocked callback is called for each new achievement',
        () async {
      final unlocked = <String>[];
      service.onAchievementUnlocked = (a) => unlocked.add(a.id);

      const stats = UserStats(
        totalWorkouts: 1,
        hasPersonalRecord: true,
        currentStreak: 3,
      );
      await service.checkAchievements(stats);

      expect(unlocked, contains('first_workout'));
      expect(unlocked, contains('pr_first'));
      expect(unlocked, contains('streak_3'));
    });

    test('unlockedCount increases after checkAchievements', () async {
      expect(service.unlockedCount, 0);
      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);
      expect(service.unlockedCount, greaterThan(0));
    });

    test('completionRate calculation', () async {
      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);
      final expectedRate =
          service.unlockedCount / AchievementService.achievements.length;
      expect(service.completionRate, closeTo(expectedRate, 0.001));
    });

    test('totalPoints sums points of all unlocked achievements', () async {
      const stats = UserStats(
        totalWorkouts: 1,
        hasPersonalRecord: true,
      );
      await service.checkAchievements(stats);

      int expectedPoints = 0;
      for (final ach in AchievementService.achievements) {
        if (service.isUnlocked(ach.id)) {
          expectedPoints += ach.points;
        }
      }
      expect(service.totalPoints, expectedPoints);
    });

    test('lockedAchievements does not include unlocked achievements',
        () async {
      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);

      final locked = service.lockedAchievements;
      expect(
        locked.any((p) => p.achievement.id == 'first_workout'),
        isFalse,
      );
    });

    test('allAchievementProgress returns progress for all achievements',
        () async {
      const stats = UserStats(totalWorkouts: 5);
      await service.checkAchievements(stats);

      final all = service.allAchievementProgress;
      expect(all.length, AchievementService.achievements.length);
    });

    test('allAchievementProgress marks first_workout as unlocked after check',
        () async {
      const stats = UserStats(totalWorkouts: 1);
      await service.checkAchievements(stats);
      final all = service.allAchievementProgress;
      final firstWorkout =
          all.firstWhere((p) => p.achievement.id == 'first_workout');
      expect(firstWorkout.isUnlocked, isTrue);
    });

    test('achievementsByCategory filters correctly', () {
      final workoutAchs =
          service.achievementsByCategory(AchievementCategory.workout);
      expect(workoutAchs, isNotEmpty);
      for (final a in workoutAchs) {
        expect(a.category, AchievementCategory.workout);
      }

      final streakAchs =
          service.achievementsByCategory(AchievementCategory.streak);
      expect(streakAchs, isNotEmpty);
      for (final a in streakAchs) {
        expect(a.category, AchievementCategory.streak);
      }
    });

    test('unlockAchievement manually unlocks an achievement', () async {
      expect(service.isUnlocked('first_workout'), isFalse);
      await service.unlockAchievement('first_workout');
      expect(service.isUnlocked('first_workout'), isTrue);
    });

    test('unlockAchievement for nonexistent id is safe', () async {
      await service.unlockAchievement('nonexistent_achievement_id');
      expect(service.unlockedCount, 0);
    });

    test('unlockAchievement calls callback', () async {
      Achievement? received;
      service.onAchievementUnlocked = (a) => received = a;
      await service.unlockAchievement('first_workout');
      expect(received?.id, 'first_workout');
    });

    test('unlockAchievement is idempotent', () async {
      await service.unlockAchievement('first_workout');
      await service.unlockAchievement('first_workout');
      expect(service.unlockedCount, 1);
    });

    test('resetAchievement removes a specific achievement', () async {
      await service.unlockAchievement('first_workout');
      expect(service.isUnlocked('first_workout'), isTrue);

      await service.resetAchievement('first_workout');
      expect(service.isUnlocked('first_workout'), isFalse);
    });

    test('resetAll clears all unlocked achievements', () async {
      const stats = UserStats(
        totalWorkouts: 100,
        currentStreak: 30,
        hasPersonalRecord: true,
        maxSessionVolume: 2000.0,
      );
      await service.checkAchievements(stats);
      expect(service.unlockedCount, greaterThan(0));

      await service.resetAll();
      expect(service.unlockedCount, 0);
      expect(service.totalPoints, 0);
      expect(service.completionRate, 0.0);
    });

    test('morning_warrior unlocks when morningWorkoutCount >= 10', () async {
      const stats = UserStats(morningWorkoutCount: 10);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('morning_warrior'), isTrue);
    });

    test('variety_10 unlocks when uniqueExerciseCount >= 10', () async {
      const stats = UserStats(uniqueExerciseCount: 10);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('variety_10'), isTrue);
    });

    test('diet achievements unlock correctly', () async {
      const stats = UserStats(dietLogStreak: 7);
      await service.checkAchievements(stats);
      expect(service.isUnlocked('diet_first_log'), isTrue);
      expect(service.isUnlocked('diet_streak_7'), isTrue);
    });
  });
}
