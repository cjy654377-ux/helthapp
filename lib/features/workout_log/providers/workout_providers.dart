// 운동 기록 상태 관리 - 현재 세션 및 히스토리
// WorkoutSessionNotifier: 진행 중인 운동 세션
// WorkoutHistoryNotifier: 저장된 운동 기록 관리

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';

// ---------------------------------------------------------------------------
// 추가 상태 클래스 정의 (workout_model에 없는 것들)
// ---------------------------------------------------------------------------

/// 현재 세션에서 개별 운동의 세트 항목
class SetEntry {
  final int setNumber;
  final double weight; // 무게 (kg)
  final int reps; // 반복 횟수
  final bool isCompleted; // 완료 여부
  final bool isWarmup; // 워밍업 세트 여부

  const SetEntry({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.isWarmup = false,
  });

  /// 볼륨 계산 (완료된 세트만)
  double get volume => isCompleted ? weight * reps : 0;

  SetEntry copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
    bool? isWarmup,
  }) {
    return SetEntry(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }

  Map<String, dynamic> toJson() => {
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'is_completed': isCompleted,
        'is_warmup': isWarmup,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        setNumber: json['set_number'] as int,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
        isCompleted: json['is_completed'] as bool? ?? false,
        isWarmup: json['is_warmup'] as bool? ?? false,
      );
}

/// 현재 세션에서 개별 운동 항목 (Exercise + SetEntry 목록)
class ExerciseEntry {
  final String exerciseId;
  final String name;
  final BodyPart bodyPart;
  final List<SetEntry> sets;

  const ExerciseEntry({
    required this.exerciseId,
    required this.name,
    required this.bodyPart,
    required this.sets,
  });

  /// 총 볼륨 (완료된 세트 기준)
  double get totalVolume => sets.fold(0, (sum, s) => sum + s.volume);

  /// 완료된 세트 수
  int get completedSets => sets.where((s) => s.isCompleted).length;

  ExerciseEntry copyWith({
    String? exerciseId,
    String? name,
    BodyPart? bodyPart,
    List<SetEntry>? sets,
  }) {
    return ExerciseEntry(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      bodyPart: bodyPart ?? this.bodyPart,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'name': name,
        'body_part': bodyPart.name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
        exerciseId: json['exercise_id'] as String,
        name: json['name'] as String,
        bodyPart: BodyPart.values.firstWhere(
          (e) => e.name == json['body_part'],
          orElse: () => BodyPart.fullBody,
        ),
        sets: (json['sets'] as List<dynamic>)
            .map((s) => SetEntry.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// 저장된 운동 기록 (히스토리용)
class WorkoutRecord {
  final String id;
  final DateTime date;
  final int durationSeconds; // 운동 총 시간 (초)
  final List<ExerciseEntry> exercises;
  final double totalVolume;
  final String? notes;

  const WorkoutRecord({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.exercises,
    required this.totalVolume,
    this.notes,
  });

  /// 운동 시간 (분)
  int get durationMinutes => durationSeconds ~/ 60;

  /// 자극한 부위 목록 (중복 제거)
  List<BodyPart> get targetedBodyParts =>
      exercises.map((e) => e.bodyPart).toSet().toList();

  WorkoutRecord copyWith({
    String? id,
    DateTime? date,
    int? durationSeconds,
    List<ExerciseEntry>? exercises,
    double? totalVolume,
    String? notes,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      exercises: exercises ?? this.exercises,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'duration_seconds': durationSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'total_volume': totalVolume,
        'notes': notes,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        durationSeconds: json['duration_seconds'] as int,
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalVolume: (json['total_volume'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}

/// 개인 기록 (PR)
class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  /// 1RM 추정 (Epley 공식)
  double get estimatedOneRepMax => weight * (1 + reps / 30);

  PersonalRecord copyWith({
    String? exerciseId,
    String? exerciseName,
    double? weight,
    int? reps,
    DateTime? date,
  }) {
    return PersonalRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'weight': weight,
        'reps': reps,
        'date': date.toIso8601String(),
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        exerciseId: json['exercise_id'] as String,
        exerciseName: json['exercise_name'] as String,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

// ---------------------------------------------------------------------------
// WorkoutSessionState - 현재 진행 중인 운동 세션 상태
// ---------------------------------------------------------------------------

/// 현재 운동 세션 전체 상태
class WorkoutSessionState {
  final String sessionId;
  final List<ExerciseEntry> exercises; // 추가된 운동 목록
  final DateTime? startTime; // 세션 시작 시각
  final bool isActive; // 세션 활성 여부
  final int restTimerSeconds; // 휴식 타이머 남은 시간 (초)
  final bool isRestTimerRunning; // 휴식 타이머 작동 중 여부
  final int elapsedSeconds; // 경과 시간 (초)
  final List<String> newPrExerciseIds; // 이번 세션에서 PR 달성한 운동 ID

  const WorkoutSessionState({
    required this.sessionId,
    this.exercises = const [],
    this.startTime,
    this.isActive = false,
    this.restTimerSeconds = 0,
    this.isRestTimerRunning = false,
    this.elapsedSeconds = 0,
    this.newPrExerciseIds = const [],
  });

  /// 총 볼륨 계산
  double get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  /// 총 완료 세트 수
  int get totalCompletedSets =>
      exercises.fold(0, (sum, e) => sum + e.completedSets);

  /// 세션 시작 여부
  bool get hasStarted => startTime != null;

  WorkoutSessionState copyWith({
    String? sessionId,
    List<ExerciseEntry>? exercises,
    DateTime? startTime,
    bool? isActive,
    int? restTimerSeconds,
    bool? isRestTimerRunning,
    int? elapsedSeconds,
    List<String>? newPrExerciseIds,
  }) {
    return WorkoutSessionState(
      sessionId: sessionId ?? this.sessionId,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      isActive: isActive ?? this.isActive,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      isRestTimerRunning: isRestTimerRunning ?? this.isRestTimerRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      newPrExerciseIds: newPrExerciseIds ?? this.newPrExerciseIds,
    );
  }
}

// ---------------------------------------------------------------------------
// WorkoutSessionNotifier - 현재 세션 상태 관리
// ---------------------------------------------------------------------------

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier() : super(WorkoutSessionState(sessionId: const Uuid().v4()));

  Timer? _elapsedTimer;
  Timer? _restTimer;

  // ── 세션 제어 ─────────────────────────────────────────────────────────────

  /// 운동 세션 시작
  void startSession() {
    state = state.copyWith(
      startTime: DateTime.now(),
      isActive: true,
    );
    _startElapsedTimer();
  }

  /// 세션 취소 (기록 저장 없이)
  void cancelSession() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = WorkoutSessionState(sessionId: const Uuid().v4());
  }

  /// 경과 시간 타이머 시작
  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  // ── 운동 관리 ─────────────────────────────────────────────────────────────

  /// 운동 추가
  void addExercise(Exercise exercise) {
    // 이미 추가된 운동인지 확인
    final exists = state.exercises.any((e) => e.exerciseId == exercise.id);
    if (exists) return;

    final entry = ExerciseEntry(
      exerciseId: exercise.id,
      name: exercise.name,
      bodyPart: exercise.bodyPart,
      sets: [
        // 기본 워밍업 세트 1개 + 작업 세트 3개 자동 추가
        const SetEntry(setNumber: 1, weight: 0, reps: 15, isWarmup: true),
        const SetEntry(setNumber: 2, weight: 0, reps: 10),
        const SetEntry(setNumber: 3, weight: 0, reps: 10),
        const SetEntry(setNumber: 4, weight: 0, reps: 10),
      ],
    );

    state = state.copyWith(
      exercises: [...state.exercises, entry],
    );
  }

  /// 운동 삭제
  void removeExercise(String exerciseId) {
    state = state.copyWith(
      exercises: state.exercises
          .where((e) => e.exerciseId != exerciseId)
          .toList(),
    );
  }

  // ── 세트 관리 ─────────────────────────────────────────────────────────────

  /// 세트 추가
  void addSet(String exerciseId) {
    final exercises = state.exercises.map((entry) {
      if (entry.exerciseId != exerciseId) return entry;

      final nextSetNumber = entry.sets.length + 1;
      // 마지막 세트의 무게/반복수를 기본값으로 사용
      final lastSet = entry.sets.isNotEmpty ? entry.sets.last : null;
      final newSet = SetEntry(
        setNumber: nextSetNumber,
        weight: lastSet?.weight ?? 0,
        reps: lastSet?.reps ?? 10,
      );

      return entry.copyWith(sets: [...entry.sets, newSet]);
    }).toList();

    state = state.copyWith(exercises: exercises);
  }

  /// 세트 삭제
  void removeSet(String exerciseId, int setIndex) {
    final exercises = state.exercises.map((entry) {
      if (entry.exerciseId != exerciseId) return entry;

      final newSets = List<SetEntry>.from(entry.sets)..removeAt(setIndex);
      // 세트 번호 재정렬
      final reindexed = newSets
          .asMap()
          .entries
          .map((e) => e.value.copyWith(setNumber: e.key + 1))
          .toList();

      return entry.copyWith(sets: reindexed);
    }).toList();

    state = state.copyWith(exercises: exercises);
  }

  /// 세트 수정 (무게/반복수)
  void updateSet(
    String exerciseId,
    int setIndex, {
    double? weight,
    int? reps,
    bool? isWarmup,
  }) {
    final exercises = state.exercises.map((entry) {
      if (entry.exerciseId != exerciseId) return entry;

      final newSets = entry.sets.asMap().entries.map((e) {
        if (e.key != setIndex) return e.value;
        return e.value.copyWith(
          weight: weight,
          reps: reps,
          isWarmup: isWarmup,
        );
      }).toList();

      return entry.copyWith(sets: newSets);
    }).toList();

    state = state.copyWith(exercises: exercises);
  }

  /// 세트 완료 토글
  void toggleSetComplete(String exerciseId, int setIndex) {
    final exercises = state.exercises.map((entry) {
      if (entry.exerciseId != exerciseId) return entry;

      final newSets = entry.sets.asMap().entries.map((e) {
        if (e.key != setIndex) return e.value;
        return e.value.copyWith(isCompleted: !e.value.isCompleted);
      }).toList();

      return entry.copyWith(sets: newSets);
    }).toList();

    state = state.copyWith(exercises: exercises);

    // 세트 완료 시 휴식 타이머 자동 시작 (90초)
    startRestTimer(90);
  }

  // ── 휴식 타이머 ───────────────────────────────────────────────────────────

  /// 휴식 타이머 시작
  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimerSeconds: seconds,
      isRestTimerRunning: true,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimerSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(isRestTimerRunning: false, restTimerSeconds: 0);
      } else {
        state = state.copyWith(
          restTimerSeconds: state.restTimerSeconds - 1,
        );
      }
    });
  }

  /// 휴식 타이머 정지
  void stopRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(
      isRestTimerRunning: false,
      restTimerSeconds: 0,
    );
  }

  /// PR 감지 (이전 기록과 비교)
  List<String> detectPRs(List<PersonalRecord> existingPRs) {
    final newPRs = <String>[];

    for (final exercise in state.exercises) {
      for (final set in exercise.sets) {
        if (!set.isCompleted || set.isWarmup) continue;

        final existingPR = existingPRs
            .where((pr) => pr.exerciseId == exercise.exerciseId)
            .toList();

        if (existingPR.isEmpty) {
          // 처음 기록이면 PR
          newPRs.add(exercise.exerciseId);
        } else {
          final pr = existingPR.first;
          // 현재 무게가 이전 PR보다 높으면 PR
          if (set.weight > pr.weight ||
              (set.weight == pr.weight && set.reps > pr.reps)) {
            newPRs.add(exercise.exerciseId);
          }
        }
      }
    }

    state = state.copyWith(newPrExerciseIds: newPRs.toSet().toList());
    return newPRs;
  }

  /// 세션 완료 - WorkoutRecord 반환
  WorkoutRecord? completeSession({String? notes}) {
    if (!state.isActive || state.exercises.isEmpty) return null;

    _elapsedTimer?.cancel();
    _restTimer?.cancel();

    final record = WorkoutRecord(
      id: const Uuid().v4(),
      date: state.startTime ?? DateTime.now(),
      durationSeconds: state.elapsedSeconds,
      exercises: state.exercises,
      totalVolume: state.totalVolume,
      notes: notes,
    );

    // 세션 초기화
    state = WorkoutSessionState(sessionId: const Uuid().v4());

    return record;
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// WorkoutHistoryNotifier - 운동 기록 히스토리 관리
// ---------------------------------------------------------------------------

class WorkoutHistoryNotifier extends StateNotifier<List<WorkoutRecord>> {
  WorkoutHistoryNotifier(this._repo) : super([]) {
    _load();
  }

  final WorkoutRepository _repo;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // 개인 기록 (별도 관리)
  List<PersonalRecord> _personalRecords = [];
  List<PersonalRecord> get personalRecords => _personalRecords;

  // ── 영속성 ────────────────────────────────────────────────────────────────

  /// Repository에서 기록 로드
  Future<void> _load() async {
    try {
      // 운동 기록 로드
      final history = await _repo.loadHistory();
      if (_disposed) return;
      state = List<WorkoutRecord>.from(history)
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬

      // PR 기록 로드
      final prs = await _repo.loadPersonalRecords();
      if (_disposed) return;
      _personalRecords = prs;
    } catch (_) {
      // 로드 실패 시 빈 상태 유지
    }
  }

  /// Repository에 기록 저장
  Future<void> _save() async {
    try {
      await _repo.saveAllRecords(state);
      await _repo.savePersonalRecords(_personalRecords);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  // ── 기록 관리 ─────────────────────────────────────────────────────────────

  /// 새 운동 기록 저장 + PR 업데이트
  Future<void> saveRecord(WorkoutRecord record) async {
    // 중복 저장 방지
    final exists = state.any((r) => r.id == record.id);
    if (exists) return;

    // PR 업데이트
    _updatePersonalRecords(record);

    state = [record, ...state]..sort((a, b) => b.date.compareTo(a.date));
    await _save();
  }

  /// 기록 삭제
  Future<void> deleteRecord(String recordId) async {
    state = state.where((r) => r.id != recordId).toList();
    await _save();
  }

  /// PR 업데이트 내부 로직
  void _updatePersonalRecords(WorkoutRecord record) {
    for (final exercise in record.exercises) {
      for (final set in exercise.sets) {
        if (!set.isCompleted || set.isWarmup) continue;

        final existingIndex = _personalRecords
            .indexWhere((pr) => pr.exerciseId == exercise.exerciseId);

        if (existingIndex == -1) {
          // 새로운 운동 PR
          _personalRecords.add(PersonalRecord(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.name,
            weight: set.weight,
            reps: set.reps,
            date: record.date,
          ));
        } else {
          final existing = _personalRecords[existingIndex];
          // 더 높은 무게 또는 같은 무게에서 더 많은 반복 시 PR 업데이트
          if (set.weight > existing.weight ||
              (set.weight == existing.weight && set.reps > existing.reps)) {
            _personalRecords[existingIndex] = PersonalRecord(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.name,
              weight: set.weight,
              reps: set.reps,
              date: record.date,
            );
          }
        }
      }
    }
  }

  // ── 조회 기능 ─────────────────────────────────────────────────────────────

  /// 날짜별 기록 조회
  List<WorkoutRecord> getRecordsByDate(DateTime date) {
    return state.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  /// 특정 기간 기록 조회
  List<WorkoutRecord> getRecordsByDateRange(DateTime start, DateTime end) {
    return state.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 부위별 기록 조회
  List<WorkoutRecord> getRecordsByBodyPart(BodyPart bodyPart) {
    return state.where((r) {
      return r.exercises.any((e) => e.bodyPart == bodyPart);
    }).toList();
  }

  /// 특정 운동의 PR 조회
  PersonalRecord? getPRForExercise(String exerciseId) {
    try {
      return _personalRecords.firstWhere((pr) => pr.exerciseId == exerciseId);
    } catch (_) {
      return null;
    }
  }

  // ── 통계 ─────────────────────────────────────────────────────────────────

  /// 주간 볼륨 (최근 7일)
  double get weeklyVolume {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return state
        .where((r) => r.date.isAfter(weekAgo))
        .fold(0, (sum, r) => sum + r.totalVolume);
  }

  /// 월간 운동일 수
  int get monthlyWorkoutDays {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final uniqueDays = state
        .where((r) => r.date.isAfter(monthStart))
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();
    return uniqueDays.length;
  }

  /// 연속 운동일 수 (streak)
  int get currentStreak {
    if (state.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    while (true) {
      final hasWorkout = state.any((r) =>
          r.date.year == checkDate.year &&
          r.date.month == checkDate.month &&
          r.date.day == checkDate.day);

      if (!hasWorkout) break;

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// 주간 운동 횟수 (요일별)
  Map<int, int> get weeklyWorkoutFrequency {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentRecords = state.where((r) => r.date.isAfter(weekAgo));

    final freq = <int, int>{};
    for (final r in recentRecords) {
      final weekday = r.date.weekday;
      freq[weekday] = (freq[weekday] ?? 0) + 1;
    }
    return freq;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 현재 운동 세션 Provider
final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>(
  (ref) => WorkoutSessionNotifier(),
);

/// 운동 기록 히스토리 Provider
final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, List<WorkoutRecord>>(
  (ref) {
    final repo = ref.watch(workoutRepositoryProvider);
    return WorkoutHistoryNotifier(repo);
  },
);

/// 개인 기록(PR) Provider - WorkoutHistoryNotifier에서 파생
final personalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  final notifier = ref.watch(workoutHistoryProvider.notifier);
  ref.watch(workoutHistoryProvider); // 변경 감지용
  return notifier.personalRecords;
});

/// 오늘의 운동 기록 Provider
final todayWorkoutRecordsProvider = Provider<List<WorkoutRecord>>((ref) {
  final history = ref.watch(workoutHistoryProvider);
  final today = DateTime.now();
  return history.where((r) {
    return r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day;
  }).toList();
});

/// 주간 볼륨 Provider
final weeklyVolumeProvider = Provider<double>((ref) {
  ref.watch(workoutHistoryProvider);
  return ref.read(workoutHistoryProvider.notifier).weeklyVolume;
});

/// 현재 연속 운동일 Provider
final currentStreakProvider = Provider<int>((ref) {
  ref.watch(workoutHistoryProvider);
  return ref.read(workoutHistoryProvider.notifier).currentStreak;
});
