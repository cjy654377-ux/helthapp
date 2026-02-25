// 챌린지 통합 서비스
// 운동/식단/수분 데이터 변경 시 관련 챌린지 진행상황을 자동 업데이트
//
// 워크아웃 완료 → workout/volume 챌린지 업데이트
// 식단 기록 추가 → diet 챌린지 업데이트
// 수분 목표 달성 → water 챌린지 업데이트

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/features/community/providers/challenge_providers.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';

/// 챌린지 통합 서비스
///
/// 운동 기록, 식단 기록, 수분 섭취 등의 데이터 변경을 감지하여
/// 참여 중인 챌린지의 진행상황을 자동으로 업데이트합니다.
class ChallengeIntegrationService {
  final Ref _ref;

  ChallengeIntegrationService(this._ref) {
    _watchWorkouts();
    _watchDiet();
    _watchHydration();
  }

  /// 운동 기록 변경 감지
  ///
  /// workoutHistoryProvider 상태(WorkoutRecord 리스트)를 감시합니다.
  /// 새 기록이 추가되면 workout(운동 일수) 및 volume(총 볼륨) 챌린지를 업데이트합니다.
  void _watchWorkouts() {
    _ref.listen<List<WorkoutRecord>>(workoutHistoryProvider, (previous, next) {
      if (previous == null) return;
      final prevCount = previous.length;
      final nextCount = next.length;
      if (nextCount > prevCount) {
        _updateWorkoutChallenges(next);
      }
    });
  }

  /// 식단 기록 변경 감지
  ///
  /// dietProvider 상태(DailyDietState)의 meals 리스트를 감시합니다.
  /// 새 식사가 추가되면 diet 챌린지를 업데이트합니다.
  void _watchDiet() {
    _ref.listen<DailyDietState>(dietProvider, (previous, next) {
      if (previous == null) return;
      if (next.meals.length > previous.meals.length) {
        _updateDietChallenges();
      }
    });
  }

  /// 수분 목표 달성 감지
  ///
  /// isWaterGoalReachedProvider가 false에서 true로 전환되면
  /// water 챌린지를 업데이트합니다.
  void _watchHydration() {
    _ref.listen<bool>(isWaterGoalReachedProvider, (previous, next) {
      if (previous == false && next == true) {
        _updateWaterChallenges();
      }
    });
  }

  /// 운동 챌린지 진행상황 업데이트
  ///
  /// - workout 타입: 챌린지 시작일 이후 운동한 고유 날짜 수를 계산하여 절대값 설정
  /// - volume 타입: 챌린지 시작일 이후 총 볼륨 합산하여 절대값 설정
  void _updateWorkoutChallenges(List<WorkoutRecord> records) {
    final challengeState = _ref.read(challengeProvider);
    final notifier = _ref.read(challengeProvider.notifier);

    for (final challenge in challengeState.activeChallenges) {
      if (challenge.type == ChallengeType.workout) {
        // 챌린지 시작일 이후 운동한 고유 날짜 수 계산
        final uniqueDays = records
            .where((r) => !r.date.isBefore(challenge.startDate))
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .length;
        notifier.setProgress(
          challengeId: challenge.id,
          value: uniqueDays.toDouble(),
        );
      } else if (challenge.type == ChallengeType.volume) {
        // 챌린지 시작일 이후 총 볼륨 합산
        final totalVolume = records
            .where((r) => !r.date.isBefore(challenge.startDate))
            .fold<double>(0, (sum, r) => sum + r.totalVolume);
        notifier.setProgress(
          challengeId: challenge.id,
          value: totalVolume,
        );
      }
    }
  }

  /// 식단 챌린지 진행상황 업데이트
  ///
  /// diet 타입 챌린지에 대해 진행값을 1 증가시킵니다.
  /// (식단 기록 연속일수를 추적하는 챌린지)
  void _updateDietChallenges() {
    final challengeState = _ref.read(challengeProvider);
    final notifier = _ref.read(challengeProvider.notifier);

    for (final challenge in challengeState.activeChallenges) {
      if (challenge.type == ChallengeType.diet) {
        notifier.addProgress(challengeId: challenge.id, delta: 1.0);
      }
    }
  }

  /// 수분 챌린지 진행상황 업데이트
  ///
  /// water 타입 챌린지에 대해 진행값을 1 증가시킵니다.
  /// (수분 목표 달성 일수를 추적하는 챌린지)
  void _updateWaterChallenges() {
    final challengeState = _ref.read(challengeProvider);
    final notifier = _ref.read(challengeProvider.notifier);

    for (final challenge in challengeState.activeChallenges) {
      if (challenge.type == ChallengeType.water) {
        notifier.addProgress(challengeId: challenge.id, delta: 1.0);
      }
    }
  }
}

/// 챌린지 통합 서비스 Provider
///
/// 앱 시작 시 HealthApp 위젯에서 ref.watch하여
/// 서비스를 생성하고 활성 상태로 유지합니다.
final challengeIntegrationProvider =
    Provider<ChallengeIntegrationService>((ref) {
  final service = ChallengeIntegrationService(ref);
  ref.onDispose(() {});
  return service;
});
