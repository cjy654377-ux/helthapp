// 챌린지/게이미피케이션 시스템 상태 관리
// ChallengeNotifier: 챌린지 생성/참가/탈퇴, 진행상황 업데이트, 완료 체크

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// 열거형 정의
// ---------------------------------------------------------------------------

/// 챌린지 유형
enum ChallengeType {
  workout('운동'), // N일 연속 운동
  volume('볼륨'), // 총 볼륨 목표 달성
  steps('걸음수'), // 일일 걸음수
  water('수분'), // 수분 섭취 목표
  diet('식단'), // 식단 기록 연속
  custom('커스텀'); // 사용자 정의

  final String label;
  const ChallengeType(this.label);
}

/// 챌린지 범위
enum ChallengeScope {
  personal('개인'),
  team('팀');

  final String label;
  const ChallengeScope(this.label);
}

// ---------------------------------------------------------------------------
// Challenge 모델
// ---------------------------------------------------------------------------

/// 챌린지 데이터 모델 (불변)
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeScope scope;
  final String? teamId; // 팀 챌린지인 경우
  final DateTime startDate;
  final DateTime endDate;
  final double targetValue; // 목표값 (예: 7일, 10000볼륨 등)
  final Map<String, double> participantProgress; // userId -> progress
  final List<String> participantIds;
  final String creatorId;
  final bool isActive;
  final String? reward; // 보상 설명

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.scope,
    this.teamId,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.participantProgress,
    required this.participantIds,
    required this.creatorId,
    required this.isActive,
    this.reward,
  });

  /// 챌린지가 완료되었는지 여부 (종료일이 지났거나 목표 달성)
  bool get isCompleted {
    if (DateTime.now().isAfter(endDate)) return true;
    // 개인 챌린지: 내 진행률이 목표치 이상
    for (final progress in participantProgress.values) {
      if (progress >= targetValue) return true;
    }
    return false;
  }

  /// 남은 일수
  int get remainingDays {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// 총 기간 (일)
  int get totalDays => endDate.difference(startDate).inDays;

  /// 특정 사용자의 진행률 (0.0 ~ 1.0)
  double progressRatioFor(String userId) {
    final progress = participantProgress[userId] ?? 0.0;
    if (targetValue <= 0) return 0.0;
    final ratio = progress / targetValue;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  /// 특정 사용자의 절대 진행값
  double progressValueFor(String userId) {
    return participantProgress[userId] ?? 0.0;
  }

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeScope? scope,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
    double? targetValue,
    Map<String, double>? participantProgress,
    List<String>? participantIds,
    String? creatorId,
    bool? isActive,
    String? reward,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      teamId: teamId ?? this.teamId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetValue: targetValue ?? this.targetValue,
      participantProgress:
          participantProgress ?? this.participantProgress,
      participantIds: participantIds ?? this.participantIds,
      creatorId: creatorId ?? this.creatorId,
      isActive: isActive ?? this.isActive,
      reward: reward ?? this.reward,
    );
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final progressRaw =
        json['participant_progress'] as Map<String, dynamic>? ?? {};
    final progressMap = progressRaw
        .map((k, v) => MapEntry(k, (v as num).toDouble()));

    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.custom,
      ),
      scope: ChallengeScope.values.firstWhere(
        (e) => e.name == json['scope'],
        orElse: () => ChallengeScope.personal,
      ),
      teamId: json['team_id'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      targetValue: (json['target_value'] as num).toDouble(),
      participantProgress: progressMap,
      participantIds:
          List<String>.from(json['participant_ids'] as List? ?? []),
      creatorId: json['creator_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      reward: json['reward'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'scope': scope.name,
      'team_id': teamId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_value': targetValue,
      'participant_progress': participantProgress,
      'participant_ids': participantIds,
      'creator_id': creatorId,
      'is_active': isActive,
      'reward': reward,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Challenge &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Challenge(id: $id, title: $title, type: ${type.label})';
}

// ---------------------------------------------------------------------------
// 프리셋 챌린지 데이터
// ---------------------------------------------------------------------------

/// 프리셋 챌린지 레코드 타입: (제목, 유형, 목표값, 설명, 기간일수, 범위, 보상)
typedef PresetChallengeData = (
  String title,
  ChallengeType type,
  double targetValue,
  String description,
  int durationDays,
  ChallengeScope scope,
  String reward
);

const List<PresetChallengeData> kPresetChallenges = [
  // 개인 챌린지
  (
    '7일 연속 운동',
    ChallengeType.workout,
    7.0,
    '7일 동안 매일 운동하세요! 꾸준함이 습관이 됩니다.',
    7,
    ChallengeScope.personal,
    '7일 연속 운동 배지'
  ),
  (
    '30일 운동 마스터',
    ChallengeType.workout,
    30.0,
    '30일 연속 운동 달성! 당신은 진정한 운동 마스터입니다.',
    30,
    ChallengeScope.personal,
    '운동 마스터 배지 + 프로필 프레임'
  ),
  (
    '주간 볼륨 킹',
    ChallengeType.volume,
    50000.0,
    '이번 주 총 볼륨 50,000kg 달성에 도전하세요.',
    7,
    ChallengeScope.personal,
    '볼륨 킹 배지'
  ),
  (
    '수분 챌린지',
    ChallengeType.water,
    7.0,
    '7일 연속 수분 목표를 달성하세요. 건강의 기본은 수분입니다.',
    7,
    ChallengeScope.personal,
    '수분 챌린지 배지'
  ),
  (
    '식단 기록왕',
    ChallengeType.diet,
    14.0,
    '14일 연속 식단을 기록하세요. 기록이 변화를 만듭니다.',
    14,
    ChallengeScope.personal,
    '식단 기록왕 배지'
  ),
  // 팀 챌린지
  (
    '팀 대항전: 볼륨',
    ChallengeType.volume,
    100000.0,
    '팀원 합산 볼륨 100,000kg 달성! 함께하면 더 강해집니다.',
    14,
    ChallengeScope.team,
    '팀 볼륨 챔피언 배지'
  ),
  (
    '팀 걸음수 챌린지',
    ChallengeType.steps,
    500000.0,
    '팀원 합산 50만 걸음 달성! 매일 조금씩 움직여요.',
    7,
    ChallengeScope.team,
    '팀 걸음수 챌린지 배지'
  ),
];

// ---------------------------------------------------------------------------
// ChallengeState
// ---------------------------------------------------------------------------

/// 챌린지 전체 상태
class ChallengeState {
  final List<Challenge> activeChallenges; // 참여 중인 챌린지
  final List<Challenge> completedChallenges; // 완료된 챌린지
  final List<Challenge> availableChallenges; // 참여 가능한 챌린지 (프리셋)
  final bool isLoading;
  final String? errorMessage;

  const ChallengeState({
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.availableChallenges = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChallengeState copyWith({
    List<Challenge>? activeChallenges,
    List<Challenge>? completedChallenges,
    List<Challenge>? availableChallenges,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChallengeState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      availableChallenges: availableChallenges ?? this.availableChallenges,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// ChallengeNotifier
// ---------------------------------------------------------------------------

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  ChallengeNotifier(this._repo) : super(const ChallengeState()) {
    _initialize();
  }

  final ChallengeRepository _repo;
  static const String _currentUserId = 'user_local';

  // ── 초기화 ────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _loadFromPrefs();
      _buildAvailableChallenges();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 프리셋 챌린지에서 아직 참가하지 않은 챌린지를 availableChallenges로 구성
  void _buildAvailableChallenges() {
    final now = DateTime.now();
    final activeIds =
        state.activeChallenges.map((c) => c.title).toSet();
    final completedIds =
        state.completedChallenges.map((c) => c.title).toSet();

    final available = kPresetChallenges
        .where((preset) =>
            !activeIds.contains(preset.$1) &&
            !completedIds.contains(preset.$1))
        .map((preset) {
      return Challenge(
        id: 'preset_${preset.$1.hashCode}',
        title: preset.$1,
        type: preset.$2,
        targetValue: preset.$3,
        description: preset.$4,
        scope: preset.$6,
        startDate: now,
        endDate: now.add(Duration(days: preset.$5)),
        participantProgress: const {},
        participantIds: const [],
        creatorId: 'system',
        isActive: true,
        reward: preset.$7,
      );
    }).toList();

    state = state.copyWith(
      availableChallenges: available,
      isLoading: false,
    );
  }

  // ── 영속성 ────────────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final activeData = await _repo.loadActiveChallenges();
      List<Challenge> active = activeData
          .map((c) => Challenge.fromJson(c))
          .toList();

      final completedData = await _repo.loadCompletedChallenges();
      List<Challenge> completed = completedData
          .map((c) => Challenge.fromJson(c))
          .toList();

      // 만료된 활성 챌린지를 완료로 이동
      final now = DateTime.now();
      final stillActive = active.where((c) => !now.isAfter(c.endDate)).toList();
      final expired = active.where((c) => now.isAfter(c.endDate)).toList();
      final newCompleted = [...completed, ...expired];

      state = state.copyWith(
        activeChallenges: stillActive,
        completedChallenges: newCompleted,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      await _repo.saveActiveChallenges(
        state.activeChallenges.map((c) => c.toJson()).toList(),
      );
      await _repo.saveCompletedChallenges(
        state.completedChallenges.map((c) => c.toJson()).toList(),
      );
    } catch (_) {}
  }

  // ── 챌린지 생성 ───────────────────────────────────────────────────────────

  /// 커스텀 챌린지 생성
  Future<void> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
    ChallengeScope scope = ChallengeScope.personal,
    String? teamId,
    String? reward,
  }) async {
    final challenge = Challenge(
      id: const Uuid().v4(),
      title: title,
      description: description,
      type: type,
      scope: scope,
      teamId: teamId,
      startDate: startDate,
      endDate: endDate,
      targetValue: targetValue,
      participantProgress: {_currentUserId: 0.0},
      participantIds: [_currentUserId],
      creatorId: _currentUserId,
      isActive: true,
      reward: reward,
    );

    state = state.copyWith(
      activeChallenges: [...state.activeChallenges, challenge],
    );
    _buildAvailableChallenges();
    await _saveToPrefs();
  }

  /// 프리셋 챌린지 참가
  Future<void> joinPresetChallenge(String presetId) async {
    final preset = state.availableChallenges
        .where((c) => c.id == presetId)
        .firstOrNull;
    if (preset == null) return;

    // 이미 참가 중인지 확인
    final alreadyJoined =
        state.activeChallenges.any((c) => c.title == preset.title);
    if (alreadyJoined) return;

    final now = DateTime.now();
    final durationDays = preset.endDate.difference(preset.startDate).inDays;

    final challenge = Challenge(
      id: const Uuid().v4(),
      title: preset.title,
      description: preset.description,
      type: preset.type,
      scope: preset.scope,
      teamId: preset.teamId,
      startDate: now,
      endDate: now.add(Duration(days: durationDays)),
      targetValue: preset.targetValue,
      participantProgress: {_currentUserId: 0.0},
      participantIds: [_currentUserId],
      creatorId: _currentUserId,
      isActive: true,
      reward: preset.reward,
    );

    state = state.copyWith(
      activeChallenges: [...state.activeChallenges, challenge],
    );
    _buildAvailableChallenges();
    await _saveToPrefs();
  }

  // ── 챌린지 참가/탈퇴 ─────────────────────────────────────────────────────

  /// 챌린지 탈퇴
  Future<void> leaveChallenge(String challengeId) async {
    state = state.copyWith(
      activeChallenges: state.activeChallenges
          .where((c) => c.id != challengeId)
          .toList(),
    );
    _buildAvailableChallenges();
    await _saveToPrefs();
  }

  // ── 진행상황 업데이트 ─────────────────────────────────────────────────────

  /// 챌린지 진행상황 증분 업데이트 (delta만큼 더하기)
  Future<void> addProgress({
    required String challengeId,
    required double delta,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;

    final updatedActive = state.activeChallenges.map((c) {
      if (c.id != challengeId) return c;
      final current = c.participantProgress[uid] ?? 0.0;
      final newProgress = current + delta;
      final updatedMap = Map<String, double>.from(c.participantProgress)
        ..[uid] = newProgress;
      return c.copyWith(participantProgress: updatedMap);
    }).toList();

    state = state.copyWith(activeChallenges: updatedActive);
    await _checkCompletion(challengeId);
    await _saveToPrefs();
  }

  /// 챌린지 진행상황 절대값 설정
  Future<void> setProgress({
    required String challengeId,
    required double value,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;

    final updatedActive = state.activeChallenges.map((c) {
      if (c.id != challengeId) return c;
      final updatedMap = Map<String, double>.from(c.participantProgress)
        ..[uid] = value;
      return c.copyWith(participantProgress: updatedMap);
    }).toList();

    state = state.copyWith(activeChallenges: updatedActive);
    await _checkCompletion(challengeId);
    await _saveToPrefs();
  }

  // ── 완료 체크 ─────────────────────────────────────────────────────────────

  /// 특정 챌린지의 완료 여부를 체크하고, 완료된 경우 completedChallenges로 이동
  Future<void> _checkCompletion(String challengeId) async {
    final challenge = state.activeChallenges
        .where((c) => c.id == challengeId)
        .firstOrNull;
    if (challenge == null) return;

    final myProgress =
        challenge.participantProgress[_currentUserId] ?? 0.0;
    final isGoalReached = myProgress >= challenge.targetValue;
    final isExpired = DateTime.now().isAfter(challenge.endDate);

    if (isGoalReached || isExpired) {
      final completed =
          challenge.copyWith(isActive: false);
      state = state.copyWith(
        activeChallenges: state.activeChallenges
            .where((c) => c.id != challengeId)
            .toList(),
        completedChallenges: [
          ...state.completedChallenges,
          completed,
        ],
      );
      _buildAvailableChallenges();
    }
  }

  /// 만료된 모든 활성 챌린지를 완료로 이동
  Future<void> checkAllExpired() async {
    final now = DateTime.now();
    final expired =
        state.activeChallenges.where((c) => now.isAfter(c.endDate)).toList();
    if (expired.isEmpty) return;

    final stillActive = state.activeChallenges
        .where((c) => !now.isAfter(c.endDate))
        .toList();
    final newCompleted = [
      ...state.completedChallenges,
      ...expired.map((c) => c.copyWith(isActive: false)),
    ];

    state = state.copyWith(
      activeChallenges: stillActive,
      completedChallenges: newCompleted,
    );
    _buildAvailableChallenges();
    await _saveToPrefs();
  }

  // ── 샘플 데이터 주입 (데모용) ─────────────────────────────────────────────

  /// 샘플 챌린지 데이터를 주입합니다 (처음 실행 시 또는 데모 목적)
  Future<void> injectSampleChallenges() async {
    if (state.activeChallenges.isNotEmpty ||
        state.completedChallenges.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    final sampleActive = [
      Challenge(
        id: const Uuid().v4(),
        title: '7일 연속 운동',
        description: '7일 동안 매일 운동하세요! 꾸준함이 습관이 됩니다.',
        type: ChallengeType.workout,
        scope: ChallengeScope.personal,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        targetValue: 7.0,
        participantProgress: {_currentUserId: 3.0},
        participantIds: [_currentUserId],
        creatorId: _currentUserId,
        isActive: true,
        reward: '7일 연속 운동 배지',
      ),
      Challenge(
        id: const Uuid().v4(),
        title: '수분 챌린지',
        description: '7일 연속 수분 목표를 달성하세요.',
        type: ChallengeType.water,
        scope: ChallengeScope.personal,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 6)),
        targetValue: 7.0,
        participantProgress: {_currentUserId: 1.0},
        participantIds: [_currentUserId],
        creatorId: _currentUserId,
        isActive: true,
        reward: '수분 챌린지 배지',
      ),
    ];

    final sampleCompleted = [
      Challenge(
        id: const Uuid().v4(),
        title: '식단 기록왕',
        description: '14일 연속 식단을 기록하세요.',
        type: ChallengeType.diet,
        scope: ChallengeScope.personal,
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.subtract(const Duration(days: 6)),
        targetValue: 14.0,
        participantProgress: {_currentUserId: 14.0},
        participantIds: [_currentUserId],
        creatorId: _currentUserId,
        isActive: false,
        reward: '식단 기록왕 배지',
      ),
    ];

    state = state.copyWith(
      activeChallenges: sampleActive,
      completedChallenges: sampleCompleted,
    );
    _buildAvailableChallenges();
    await _saveToPrefs();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 챌린지 전체 상태 Provider
final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeState>(
  (ref) {
    final repo = ref.watch(challengeRepositoryProvider);
    return ChallengeNotifier(repo);
  },
);

/// 활성(참여 중) 챌린지 목록 Provider
final activeChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(challengeProvider).activeChallenges;
});

/// 완료된 챌린지 목록 Provider
final completedChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(challengeProvider).completedChallenges;
});

/// 참여 가능한 챌린지 목록 Provider
final availableChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(challengeProvider).availableChallenges;
});

/// 특정 챌린지 조회 Provider (family)
final challengeByIdProvider =
    Provider.family<Challenge?, String>((ref, id) {
  final state = ref.watch(challengeProvider);
  final allChallenges = [
    ...state.activeChallenges,
    ...state.completedChallenges,
    ...state.availableChallenges,
  ];
  try {
    return allChallenges.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

/// 챌린지 로딩 상태 Provider
final challengeLoadingProvider = Provider<bool>((ref) {
  return ref.watch(challengeProvider).isLoading;
});
