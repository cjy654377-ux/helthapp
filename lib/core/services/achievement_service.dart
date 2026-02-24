// 업적/배지 시스템 서비스 - 게이미피케이션 요소
// 운동, 식단, 수분, 커뮤니티 활동에 따른 업적 달성을 관리합니다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/services/local_storage_service.dart';

// ---------------------------------------------------------------------------
// Achievement 모델
// ---------------------------------------------------------------------------

/// 업적/배지 정보 모델
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // 이모지 아이콘
  final AchievementCategory category;
  final int requiredCount; // 달성에 필요한 횟수/수치 (0이면 1회 달성)
  final int points; // 획득 포인트

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.requiredCount = 1,
    this.points = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Achievement(id: $id, title: $title)';
}

/// 업적 카테고리 열거형
enum AchievementCategory {
  workout('운동'),
  diet('식단'),
  hydration('수분'),
  community('커뮤니티'),
  streak('연속 기록'),
  special('특별');

  final String label;
  const AchievementCategory(this.label);
}

// ---------------------------------------------------------------------------
// AchievementProgress 모델
// ---------------------------------------------------------------------------

/// 미달성 업적의 진행 상황 모델
class AchievementProgress {
  final Achievement achievement;
  final int currentCount; // 현재 진행 횟수
  final bool isUnlocked; // 달성 여부

  const AchievementProgress({
    required this.achievement,
    required this.currentCount,
    required this.isUnlocked,
  });

  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (achievement.requiredCount <= 0) return isUnlocked ? 1.0 : 0.0;
    return (currentCount / achievement.requiredCount).clamp(0.0, 1.0);
  }

  /// 남은 횟수
  int get remaining =>
      (achievement.requiredCount - currentCount).clamp(0, achievement.requiredCount);

  AchievementProgress copyWith({
    Achievement? achievement,
    int? currentCount,
    bool? isUnlocked,
  }) {
    return AchievementProgress(
      achievement: achievement ?? this.achievement,
      currentCount: currentCount ?? this.currentCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  @override
  String toString() =>
      'AchievementProgress(id: ${achievement.id}, $currentCount/${achievement.requiredCount})';
}

// ---------------------------------------------------------------------------
// UserStats 모델 - 업적 체크에 필요한 통계
// ---------------------------------------------------------------------------

/// 업적 달성 체크에 필요한 사용자 통계 데이터
class UserStats {
  final int totalWorkouts; // 총 운동 횟수
  final int currentStreak; // 현재 연속 운동 일수
  final int longestStreak; // 최장 연속 운동 일수
  final double maxSessionVolume; // 단일 세션 최대 볼륨 (kg)
  final bool hasPersonalRecord; // 개인 기록 달성 여부
  final int totalWaterGoalDays; // 수분 목표 달성 일수
  final int dietLogStreak; // 연속 식단 기록 일수
  final bool hasJoinedTeam; // 팀 가입 여부
  final int totalCaloriesBurned; // 총 소모 칼로리
  final int totalWorkoutMinutes; // 총 운동 시간 (분)
  final int uniqueExerciseCount; // 수행한 고유 운동 종목 수
  final int teamInteractions; // 팀 활동 횟수 (게시글, 댓글 등)
  final double bodyWeightChange; // 체중 변화량 (kg, 음수=감소)
  final int morningWorkoutCount; // 오전 운동 횟수 (6~12시)
  final int consecutiveWaterDays; // 연속 수분 목표 달성 일수

  const UserStats({
    this.totalWorkouts = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.maxSessionVolume = 0.0,
    this.hasPersonalRecord = false,
    this.totalWaterGoalDays = 0,
    this.dietLogStreak = 0,
    this.hasJoinedTeam = false,
    this.totalCaloriesBurned = 0,
    this.totalWorkoutMinutes = 0,
    this.uniqueExerciseCount = 0,
    this.teamInteractions = 0,
    this.bodyWeightChange = 0.0,
    this.morningWorkoutCount = 0,
    this.consecutiveWaterDays = 0,
  });

  UserStats copyWith({
    int? totalWorkouts,
    int? currentStreak,
    int? longestStreak,
    double? maxSessionVolume,
    bool? hasPersonalRecord,
    int? totalWaterGoalDays,
    int? dietLogStreak,
    bool? hasJoinedTeam,
    int? totalCaloriesBurned,
    int? totalWorkoutMinutes,
    int? uniqueExerciseCount,
    int? teamInteractions,
    double? bodyWeightChange,
    int? morningWorkoutCount,
    int? consecutiveWaterDays,
  }) {
    return UserStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      maxSessionVolume: maxSessionVolume ?? this.maxSessionVolume,
      hasPersonalRecord: hasPersonalRecord ?? this.hasPersonalRecord,
      totalWaterGoalDays: totalWaterGoalDays ?? this.totalWaterGoalDays,
      dietLogStreak: dietLogStreak ?? this.dietLogStreak,
      hasJoinedTeam: hasJoinedTeam ?? this.hasJoinedTeam,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      totalWorkoutMinutes: totalWorkoutMinutes ?? this.totalWorkoutMinutes,
      uniqueExerciseCount: uniqueExerciseCount ?? this.uniqueExerciseCount,
      teamInteractions: teamInteractions ?? this.teamInteractions,
      bodyWeightChange: bodyWeightChange ?? this.bodyWeightChange,
      morningWorkoutCount: morningWorkoutCount ?? this.morningWorkoutCount,
      consecutiveWaterDays: consecutiveWaterDays ?? this.consecutiveWaterDays,
    );
  }
}

// ---------------------------------------------------------------------------
// AchievementService
// ---------------------------------------------------------------------------

/// 업적/배지 시스템 서비스
///
/// 업적 목록은 하드코딩되어 있으며, 달성 상태는 LocalStorageService를 통해
/// 영속적으로 저장됩니다.
class AchievementService {
  AchievementService(this._storageService);

  final LocalStorageService _storageService;

  // 달성된 업적 ID 세트 (메모리 캐시)
  final Set<String> _unlockedIds = {};

  // 업적별 진행 카운트 맵 (메모리 캐시)
  final Map<String, int> _progressCounts = {};

  // 새로 달성된 업적 콜백
  void Function(Achievement achievement)? onAchievementUnlocked;

  // ---------------------------------------------------------------------------
  // 전체 업적 목록 (하드코딩 - 최소 15개)
  // ---------------------------------------------------------------------------

  /// 앱의 전체 업적 목록
  static const List<Achievement> achievements = [
    // --- 운동 카테고리 ---
    Achievement(
      id: 'first_workout',
      title: '첫 운동',
      description: '첫 번째 운동 기록을 완료했습니다',
      icon: '💪',
      category: AchievementCategory.workout,
      requiredCount: 1,
      points: 10,
    ),
    Achievement(
      id: 'workout_10',
      title: '운동 마니아',
      description: '운동 기록을 10회 완료했습니다',
      icon: '🏋️',
      category: AchievementCategory.workout,
      requiredCount: 10,
      points: 20,
    ),
    Achievement(
      id: 'workout_50',
      title: '헬스 중독자',
      description: '운동 기록을 50회 완료했습니다',
      icon: '🔥',
      category: AchievementCategory.workout,
      requiredCount: 50,
      points: 50,
    ),
    Achievement(
      id: 'workout_100',
      title: '운동의 신',
      description: '운동 기록을 100회 완료했습니다',
      icon: '⚡',
      category: AchievementCategory.workout,
      requiredCount: 100,
      points: 100,
    ),
    Achievement(
      id: 'volume_1000',
      title: '1톤 클럽',
      description: '한 세션에 총 볼륨 1,000kg을 달성했습니다',
      icon: '🏆',
      category: AchievementCategory.workout,
      requiredCount: 1,
      points: 30,
    ),
    Achievement(
      id: 'pr_first',
      title: '새 기록!',
      description: '첫 개인 최고 기록(PR)을 달성했습니다',
      icon: '🥇',
      category: AchievementCategory.workout,
      requiredCount: 1,
      points: 15,
    ),
    Achievement(
      id: 'morning_warrior',
      title: '새벽 전사',
      description: '오전 운동을 10회 완료했습니다',
      icon: '🌅',
      category: AchievementCategory.workout,
      requiredCount: 10,
      points: 25,
    ),
    Achievement(
      id: 'variety_10',
      title: '만능 운동인',
      description: '10가지 이상의 다양한 운동을 수행했습니다',
      icon: '🎯',
      category: AchievementCategory.workout,
      requiredCount: 10,
      points: 20,
    ),

    // --- 연속 기록 카테고리 ---
    Achievement(
      id: 'streak_3',
      title: '3일 연속',
      description: '3일 연속으로 운동했습니다',
      icon: '🔥',
      category: AchievementCategory.streak,
      requiredCount: 3,
      points: 15,
    ),
    Achievement(
      id: 'streak_7',
      title: '일주일 연속',
      description: '7일 연속으로 운동했습니다',
      icon: '⭐',
      category: AchievementCategory.streak,
      requiredCount: 7,
      points: 30,
    ),
    Achievement(
      id: 'streak_30',
      title: '한 달 연속',
      description: '30일 연속으로 운동했습니다',
      icon: '🌟',
      category: AchievementCategory.streak,
      requiredCount: 30,
      points: 100,
    ),

    // --- 수분 카테고리 ---
    Achievement(
      id: 'water_first_goal',
      title: '수분 첫 목표!',
      description: '처음으로 하루 수분 섭취 목표를 달성했습니다',
      icon: '💧',
      category: AchievementCategory.hydration,
      requiredCount: 1,
      points: 10,
    ),
    Achievement(
      id: 'water_master',
      title: '수분 마스터',
      description: '수분 섭취 목표를 7일 달성했습니다',
      icon: '🌊',
      category: AchievementCategory.hydration,
      requiredCount: 7,
      points: 25,
    ),
    Achievement(
      id: 'water_streak_30',
      title: '수분 왕',
      description: '30일 연속 수분 섭취 목표를 달성했습니다',
      icon: '🏄',
      category: AchievementCategory.hydration,
      requiredCount: 30,
      points: 80,
    ),

    // --- 식단 카테고리 ---
    Achievement(
      id: 'diet_first_log',
      title: '식단 시작',
      description: '첫 번째 식단을 기록했습니다',
      icon: '🥗',
      category: AchievementCategory.diet,
      requiredCount: 1,
      points: 10,
    ),
    Achievement(
      id: 'diet_streak_7',
      title: '식단 기록왕',
      description: '7일 연속 식단을 기록했습니다',
      icon: '📊',
      category: AchievementCategory.diet,
      requiredCount: 7,
      points: 30,
    ),

    // --- 커뮤니티 카테고리 ---
    Achievement(
      id: 'team_join',
      title: '팀 플레이어',
      description: '팀에 가입했습니다',
      icon: '👥',
      category: AchievementCategory.community,
      requiredCount: 1,
      points: 15,
    ),
    Achievement(
      id: 'social_butterfly',
      title: '소셜 버터플라이',
      description: '팀 활동(게시글/댓글)을 10회 이상 했습니다',
      icon: '🦋',
      category: AchievementCategory.community,
      requiredCount: 10,
      points: 20,
    ),

    // --- 특별 카테고리 ---
    Achievement(
      id: 'body_transformation',
      title: '변신 성공',
      description: '체중 변화 목표를 달성했습니다',
      icon: '✨',
      category: AchievementCategory.special,
      requiredCount: 1,
      points: 50,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 초기화 / 데이터 로드
  // ---------------------------------------------------------------------------

  /// 저장된 업적 데이터 로드
  Future<void> loadAchievements() async {
    try {
      final settings = await _storageService.loadUserSettings();

      // 달성된 업적 ID 로드
      final unlockedList = settings['unlocked_achievements'];
      if (unlockedList is List) {
        _unlockedIds.clear();
        _unlockedIds.addAll(unlockedList.whereType<String>());
      }

      // 업적 진행 카운트 로드
      final progressMap = settings['achievement_progress'];
      if (progressMap is Map<String, dynamic>) {
        _progressCounts.clear();
        for (final entry in progressMap.entries) {
          final value = entry.value;
          if (value is int) {
            _progressCounts[entry.key] = value;
          }
        }
      }
    } catch (_) {
      // 로드 실패 시 기본값(빈 상태) 유지
    }
  }

  /// 업적 데이터 저장
  Future<void> _saveAchievements() async {
    try {
      await _storageService.saveSettingValue(
        'unlocked_achievements',
        _unlockedIds.toList(),
      );
      await _storageService.saveSettingValue(
        'achievement_progress',
        Map<String, dynamic>.from(_progressCounts),
      );
    } catch (_) {
      // 저장 실패 시 조용히 처리
    }
  }

  // ---------------------------------------------------------------------------
  // 업적 달성 체크
  // ---------------------------------------------------------------------------

  /// 사용자 통계 기반 업적 달성 체크
  ///
  /// [stats]: 최신 사용자 통계 데이터
  /// 새로 달성된 업적이 있으면 [onAchievementUnlocked] 콜백 호출
  Future<void> checkAchievements(UserStats stats) async {
    final newlyUnlocked = <Achievement>[];

    for (final achievement in achievements) {
      if (_unlockedIds.contains(achievement.id)) continue;

      final shouldUnlock = _evaluateAchievement(achievement, stats);

      if (shouldUnlock) {
        _unlockedIds.add(achievement.id);
        newlyUnlocked.add(achievement);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      // 진행 카운트 업데이트
      _updateProgressCounts(stats);

      // 저장
      await _saveAchievements();

      // 콜백 호출 (UI에서 축하 메시지 표시용)
      for (final achievement in newlyUnlocked) {
        onAchievementUnlocked?.call(achievement);
      }
    } else {
      // 달성은 없어도 진행 카운트는 업데이트
      _updateProgressCounts(stats);
    }
  }

  /// 업적 달성 조건 평가
  bool _evaluateAchievement(Achievement achievement, UserStats stats) {
    switch (achievement.id) {
      // 운동 횟수
      case 'first_workout':
        return stats.totalWorkouts >= 1;
      case 'workout_10':
        return stats.totalWorkouts >= 10;
      case 'workout_50':
        return stats.totalWorkouts >= 50;
      case 'workout_100':
        return stats.totalWorkouts >= 100;

      // 볼륨/기록
      case 'volume_1000':
        return stats.maxSessionVolume >= 1000;
      case 'pr_first':
        return stats.hasPersonalRecord;

      // 오전 운동
      case 'morning_warrior':
        return stats.morningWorkoutCount >= 10;

      // 다양한 운동
      case 'variety_10':
        return stats.uniqueExerciseCount >= 10;

      // 연속 운동
      case 'streak_3':
        return stats.currentStreak >= 3 || stats.longestStreak >= 3;
      case 'streak_7':
        return stats.currentStreak >= 7 || stats.longestStreak >= 7;
      case 'streak_30':
        return stats.currentStreak >= 30 || stats.longestStreak >= 30;

      // 수분
      case 'water_first_goal':
        return stats.totalWaterGoalDays >= 1;
      case 'water_master':
        return stats.totalWaterGoalDays >= 7;
      case 'water_streak_30':
        return stats.consecutiveWaterDays >= 30;

      // 식단
      case 'diet_first_log':
        return stats.dietLogStreak >= 1;
      case 'diet_streak_7':
        return stats.dietLogStreak >= 7;

      // 커뮤니티
      case 'team_join':
        return stats.hasJoinedTeam;
      case 'social_butterfly':
        return stats.teamInteractions >= 10;

      // 체형 변화
      case 'body_transformation':
        return stats.bodyWeightChange.abs() >= 5.0;

      default:
        return false;
    }
  }

  /// 업적 진행 카운트 업데이트 (메모리 캐시)
  void _updateProgressCounts(UserStats stats) {
    _progressCounts['first_workout'] = stats.totalWorkouts.clamp(0, 1);
    _progressCounts['workout_10'] = stats.totalWorkouts.clamp(0, 10);
    _progressCounts['workout_50'] = stats.totalWorkouts.clamp(0, 50);
    _progressCounts['workout_100'] = stats.totalWorkouts.clamp(0, 100);
    _progressCounts['volume_1000'] =
        stats.maxSessionVolume >= 1000 ? 1 : 0;
    _progressCounts['pr_first'] = stats.hasPersonalRecord ? 1 : 0;
    _progressCounts['morning_warrior'] =
        stats.morningWorkoutCount.clamp(0, 10);
    _progressCounts['variety_10'] =
        stats.uniqueExerciseCount.clamp(0, 10);
    _progressCounts['streak_3'] =
        stats.longestStreak.clamp(0, 3);
    _progressCounts['streak_7'] =
        stats.longestStreak.clamp(0, 7);
    _progressCounts['streak_30'] =
        stats.longestStreak.clamp(0, 30);
    _progressCounts['water_first_goal'] =
        stats.totalWaterGoalDays.clamp(0, 1);
    _progressCounts['water_master'] =
        stats.totalWaterGoalDays.clamp(0, 7);
    _progressCounts['water_streak_30'] =
        stats.consecutiveWaterDays.clamp(0, 30);
    _progressCounts['diet_first_log'] =
        stats.dietLogStreak.clamp(0, 1);
    _progressCounts['diet_streak_7'] =
        stats.dietLogStreak.clamp(0, 7);
    _progressCounts['team_join'] = stats.hasJoinedTeam ? 1 : 0;
    _progressCounts['social_butterfly'] =
        stats.teamInteractions.clamp(0, 10);
    _progressCounts['body_transformation'] =
        stats.bodyWeightChange.abs() >= 5.0 ? 1 : 0;
  }

  // ---------------------------------------------------------------------------
  // 업적 조회
  // ---------------------------------------------------------------------------

  /// 달성된 업적 목록 (달성 순서 보장 불가, 정렬 필요 시 별도 처리)
  List<Achievement> get unlockedAchievements {
    return achievements
        .where((a) => _unlockedIds.contains(a.id))
        .toList();
  }

  /// 미달성 업적 목록 (진행률 포함)
  List<AchievementProgress> get lockedAchievements {
    return achievements
        .where((a) => !_unlockedIds.contains(a.id))
        .map(
          (a) => AchievementProgress(
            achievement: a,
            currentCount: _progressCounts[a.id] ?? 0,
            isUnlocked: false,
          ),
        )
        .toList();
  }

  /// 전체 업적 진행 상황 목록 (달성 + 미달성 모두)
  List<AchievementProgress> get allAchievementProgress {
    return achievements.map((a) {
      final isUnlocked = _unlockedIds.contains(a.id);
      return AchievementProgress(
        achievement: a,
        currentCount: isUnlocked
            ? a.requiredCount
            : (_progressCounts[a.id] ?? 0),
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  /// 카테고리별 업적 목록
  List<Achievement> achievementsByCategory(AchievementCategory category) {
    return achievements.where((a) => a.category == category).toList();
  }

  /// 특정 업적 달성 여부 확인
  bool isUnlocked(String achievementId) =>
      _unlockedIds.contains(achievementId);

  /// 달성 업적 수
  int get unlockedCount => _unlockedIds.length;

  /// 전체 업적 수
  int get totalCount => achievements.length;

  /// 달성률 (0.0 ~ 1.0)
  double get completionRate {
    if (achievements.isEmpty) return 0.0;
    return unlockedCount / achievements.length;
  }

  /// 총 획득 포인트
  int get totalPoints {
    return achievements
        .where((a) => _unlockedIds.contains(a.id))
        .fold(0, (sum, a) => sum + a.points);
  }

  /// 수동으로 특정 업적 달성 처리 (테스트/관리자용)
  Future<void> unlockAchievement(String achievementId) async {
    if (_unlockedIds.contains(achievementId)) return;

    final achievement = achievements.where((a) => a.id == achievementId).firstOrNull;
    if (achievement == null) return;

    _unlockedIds.add(achievementId);
    _progressCounts[achievementId] = achievement.requiredCount;
    await _saveAchievements();
    onAchievementUnlocked?.call(achievement);
  }

  /// 특정 업적 달성 취소 (테스트/관리자용)
  Future<void> resetAchievement(String achievementId) async {
    _unlockedIds.remove(achievementId);
    _progressCounts.remove(achievementId);
    await _saveAchievements();
  }

  /// 모든 업적 초기화 (데이터 리셋용)
  Future<void> resetAll() async {
    _unlockedIds.clear();
    _progressCounts.clear();
    await _saveAchievements();
  }
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

/// AchievementService Provider
final achievementServiceProvider = Provider<AchievementService>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return AchievementService(storageService);
});

/// 달성 업적 목록 Provider
final unlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.unlockedAchievements;
});

/// 미달성 업적 진행 목록 Provider
final lockedAchievementsProvider = Provider<List<AchievementProgress>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.lockedAchievements;
});

/// 전체 업적 진행 상황 Provider
final allAchievementProgressProvider =
    Provider<List<AchievementProgress>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.allAchievementProgress;
});

/// 업적 달성률 Provider
final achievementCompletionRateProvider = Provider<double>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.completionRate;
});

/// 총 획득 포인트 Provider
final achievementTotalPointsProvider = Provider<int>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.totalPoints;
});
