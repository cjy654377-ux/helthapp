// 운동 일정 캘린더 상태 관리
// CalendarNotifier: 날짜별 운동 계획 관리, 스플릿 템플릿, 반복 일정

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';

// ---------------------------------------------------------------------------
// WorkoutPlanEntry - 캘린더 단일 운동 계획 항목
// ---------------------------------------------------------------------------

/// 캘린더에 등록된 단일 운동 계획
class WorkoutPlanEntry {
  final String id;
  final String title; // 계획 이름 (예: "가슴 & 삼두")
  final List<String> targetBodyParts; // 오늘 운동할 부위
  final List<String> exerciseIds; // 계획된 운동 ID 목록
  final bool isCompleted; // 완료 여부
  final bool isRecurring; // 반복 일정 여부
  final int? recurringWeekday; // 반복 요일 (1=월 ~ 7=일, null이면 비반복)
  final String? notes;
  final String? splitType; // 스플릿 타입 (ppl/upper_lower/full_body)

  const WorkoutPlanEntry({
    required this.id,
    required this.title,
    this.targetBodyParts = const [],
    this.exerciseIds = const [],
    this.isCompleted = false,
    this.isRecurring = false,
    this.recurringWeekday,
    this.notes,
    this.splitType,
  });

  WorkoutPlanEntry copyWith({
    String? id,
    String? title,
    List<String>? targetBodyParts,
    List<String>? exerciseIds,
    bool? isCompleted,
    bool? isRecurring,
    int? recurringWeekday,
    String? notes,
    String? splitType,
  }) {
    return WorkoutPlanEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      targetBodyParts: targetBodyParts ?? this.targetBodyParts,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringWeekday: recurringWeekday ?? this.recurringWeekday,
      notes: notes ?? this.notes,
      splitType: splitType ?? this.splitType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target_body_parts': targetBodyParts,
        'exercise_ids': exerciseIds,
        'is_completed': isCompleted,
        'is_recurring': isRecurring,
        'recurring_weekday': recurringWeekday,
        'notes': notes,
        'split_type': splitType,
      };

  factory WorkoutPlanEntry.fromJson(Map<String, dynamic> json) =>
      WorkoutPlanEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        targetBodyParts:
            List<String>.from(json['target_body_parts'] as List? ?? []),
        exerciseIds:
            List<String>.from(json['exercise_ids'] as List? ?? []),
        isCompleted: json['is_completed'] as bool? ?? false,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurringWeekday: json['recurring_weekday'] as int?,
        notes: json['notes'] as String?,
        splitType: json['split_type'] as String?,
      );
}

// ---------------------------------------------------------------------------
// CalendarState - 캘린더 전체 상태
// ---------------------------------------------------------------------------

/// 캘린더 상태 (날짜 -> 운동 계획 목록 맵)
class CalendarState {
  final Map<String, List<WorkoutPlanEntry>> plans; // dateKey -> 계획 목록
  final DateTime selectedDate; // 현재 선택된 날짜
  final DateTime focusedMonth; // 현재 보고 있는 월

  const CalendarState({
    this.plans = const {},
    required this.selectedDate,
    required this.focusedMonth,
  });

  /// dateKey 생성 (yyyy-MM-dd)
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 특정 날짜의 계획 조회
  List<WorkoutPlanEntry> getPlansForDate(DateTime date) {
    final key = dateKey(date);
    final datePlans = plans[key] ?? [];

    // 반복 일정도 포함
    final recurringPlans = plans.values
        .expand((entries) => entries)
        .where((entry) =>
            entry.isRecurring &&
            entry.recurringWeekday == date.weekday)
        .toList();

    // 중복 제거
    final allIds = datePlans.map((p) => p.id).toSet();
    final uniqueRecurring =
        recurringPlans.where((p) => !allIds.contains(p.id)).toList();

    return [...datePlans, ...uniqueRecurring];
  }

  /// 해당 월의 운동 있는 날짜 목록
  List<DateTime> getWorkoutDaysInMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    for (var day = monthStart;
        !day.isAfter(monthEnd);
        day = day.add(const Duration(days: 1))) {
      if (getPlansForDate(day).isNotEmpty) {
        days.add(day);
      }
    }
    return days;
  }

  CalendarState copyWith({
    Map<String, List<WorkoutPlanEntry>>? plans,
    DateTime? selectedDate,
    DateTime? focusedMonth,
  }) {
    return CalendarState(
      plans: plans ?? this.plans,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
    );
  }

  Map<String, dynamic> toJson() => {
        'plans': plans.map(
          (key, value) =>
              MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
      };

  factory CalendarState.fromJson(Map<String, dynamic> json) {
    final plansJson =
        json['plans'] as Map<String, dynamic>? ?? {};
    final plans = plansJson.map((key, value) {
      final entries = (value as List<dynamic>)
          .map((e) =>
              WorkoutPlanEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return MapEntry(key, entries);
    });
    final now = DateTime.now();
    return CalendarState(
      plans: plans,
      selectedDate: now,
      focusedMonth: now,
    );
  }
}

// ---------------------------------------------------------------------------
// 스플릿 템플릿 정의
// ---------------------------------------------------------------------------

/// PPL 스플릿 템플릿
const Map<int, String> kPPLTemplate = {
  DateTime.monday: 'Push (가슴, 어깨, 삼두)',
  DateTime.tuesday: 'Pull (등, 이두)',
  DateTime.wednesday: 'Legs (하체, 종아리)',
  DateTime.thursday: 'Push (가슴, 어깨, 삼두)',
  DateTime.friday: 'Pull (등, 이두)',
  DateTime.saturday: 'Legs (하체, 종아리)',
  // 일요일: 휴식
};

/// 상하체 스플릿 템플릿
const Map<int, String> kUpperLowerTemplate = {
  DateTime.monday: '상체 (가슴, 등, 어깨, 팔)',
  DateTime.tuesday: '하체 (대퇴, 햄스트링, 종아리)',
  DateTime.wednesday: '휴식 또는 유산소',
  DateTime.thursday: '상체 (가슴, 등, 어깨, 팔)',
  DateTime.friday: '하체 (대퇴, 햄스트링, 종아리)',
  // 주말: 휴식
};

/// 풀바디 스플릿 템플릿
const Map<int, String> kFullBodyTemplate = {
  DateTime.monday: '전신 운동 A',
  DateTime.wednesday: '전신 운동 B',
  DateTime.friday: '전신 운동 C',
  // 나머지: 휴식
};

// ---------------------------------------------------------------------------
// CalendarNotifier
// ---------------------------------------------------------------------------

class CalendarNotifier
    extends StateNotifier<CalendarState> {
  CalendarNotifier(this._repo)
      : super(CalendarState(
          selectedDate: DateTime.now(),
          focusedMonth: DateTime.now(),
        )) {
    _load();
  }

  final CalendarRepository _repo;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── 영속성 ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final rawPlans = await _repo.loadAllPlans();
      final plans = rawPlans.map((key, value) {
        final entries = value
            .map((e) => WorkoutPlanEntry.fromJson(e))
            .toList();
        return MapEntry(key, entries);
      });
      if (_disposed) return;
      state = state.copyWith(plans: plans);
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final rawPlans = state.plans.map((key, value) {
        return MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        );
      });
      await _repo.saveAllPlans(rawPlans);
    } catch (_) {}
  }

  // ── 날짜 선택 ─────────────────────────────────────────────────────────────

  /// 날짜 선택
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// 월 이동
  void changeFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: month);
  }

  // ── 계획 CRUD ─────────────────────────────────────────────────────────────

  /// 운동 계획 추가
  Future<void> addPlan(
    DateTime date,
    WorkoutPlanEntry plan,
  ) async {
    final key = CalendarState.dateKey(date);
    final existingPlans = List<WorkoutPlanEntry>.from(
        state.plans[key] ?? []);
    existingPlans.add(plan);

    final updatedPlans = Map<String, List<WorkoutPlanEntry>>.from(state.plans)
      ..[key] = existingPlans;

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 운동 계획 삭제
  Future<void> removePlan(DateTime date, String planId) async {
    final key = CalendarState.dateKey(date);
    final existingPlans = List<WorkoutPlanEntry>.from(
        state.plans[key] ?? []);
    existingPlans.removeWhere((p) => p.id == planId);

    final updatedPlans = Map<String, List<WorkoutPlanEntry>>.from(state.plans)
      ..[key] = existingPlans;

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 계획 완료/미완료 토글
  Future<void> togglePlanComplete(DateTime date, String planId) async {
    final key = CalendarState.dateKey(date);
    final existingPlans = (state.plans[key] ?? []).map((plan) {
      if (plan.id != planId) return plan;
      return plan.copyWith(isCompleted: !plan.isCompleted);
    }).toList();

    final updatedPlans = Map<String, List<WorkoutPlanEntry>>.from(state.plans)
      ..[key] = existingPlans;

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  // ── 스플릿 템플릿 적용 ────────────────────────────────────────────────────

  /// PPL 스플릿 4주 적용
  Future<void> applyPPLSplit({int weeks = 4}) async {
    final startDate = DateTime.now();
    final updatedPlans =
        Map<String, List<WorkoutPlanEntry>>.from(state.plans);

    for (int day = 0; day < weeks * 7; day++) {
      final date = startDate.add(Duration(days: day));
      final weekday = date.weekday;
      final splitName = kPPLTemplate[weekday];

      if (splitName != null) {
        final key = CalendarState.dateKey(date);
        final plan = WorkoutPlanEntry(
          id: const Uuid().v4(),
          title: splitName,
          isRecurring: false,
          splitType: 'ppl',
        );
        final existing = List<WorkoutPlanEntry>.from(
            updatedPlans[key] ?? []);
        existing.add(plan);
        updatedPlans[key] = existing;
      }
    }

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 상하체 스플릿 4주 적용
  Future<void> applyUpperLowerSplit({int weeks = 4}) async {
    final startDate = DateTime.now();
    final updatedPlans =
        Map<String, List<WorkoutPlanEntry>>.from(state.plans);

    for (int day = 0; day < weeks * 7; day++) {
      final date = startDate.add(Duration(days: day));
      final weekday = date.weekday;
      final splitName = kUpperLowerTemplate[weekday];

      if (splitName != null && !splitName.contains('휴식')) {
        final key = CalendarState.dateKey(date);
        final plan = WorkoutPlanEntry(
          id: const Uuid().v4(),
          title: splitName,
          isRecurring: false,
          splitType: 'upper_lower',
        );
        final existing = List<WorkoutPlanEntry>.from(
            updatedPlans[key] ?? []);
        existing.add(plan);
        updatedPlans[key] = existing;
      }
    }

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 풀바디 스플릿 4주 적용
  Future<void> applyFullBodySplit({int weeks = 4}) async {
    final startDate = DateTime.now();
    final updatedPlans =
        Map<String, List<WorkoutPlanEntry>>.from(state.plans);

    for (int day = 0; day < weeks * 7; day++) {
      final date = startDate.add(Duration(days: day));
      final weekday = date.weekday;
      final splitName = kFullBodyTemplate[weekday];

      if (splitName != null) {
        final key = CalendarState.dateKey(date);
        final plan = WorkoutPlanEntry(
          id: const Uuid().v4(),
          title: splitName,
          isRecurring: false,
          splitType: 'full_body',
        );
        final existing = List<WorkoutPlanEntry>.from(
            updatedPlans[key] ?? []);
        existing.add(plan);
        updatedPlans[key] = existing;
      }
    }

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 반복 일정 추가 (매주 특정 요일)
  Future<void> addRecurringPlan(
    int weekday,
    String title, {
    List<String> exerciseIds = const [],
    String? splitType,
  }) async {
    final plan = WorkoutPlanEntry(
      id: const Uuid().v4(),
      title: title,
      exerciseIds: exerciseIds,
      isRecurring: true,
      recurringWeekday: weekday,
      splitType: splitType,
    );

    // 반복 일정은 특별 키로 저장
    const recurringKey = '__recurring__';
    final existing = List<WorkoutPlanEntry>.from(
        state.plans[recurringKey] ?? []);
    existing.add(plan);

    final updatedPlans = Map<String, List<WorkoutPlanEntry>>.from(state.plans)
      ..[recurringKey] = existing;

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }

  /// 특정 날짜 이후의 모든 계획 삭제 (리셋)
  Future<void> clearPlansFrom(DateTime fromDate) async {
    final updatedPlans =
        Map<String, List<WorkoutPlanEntry>>.from(state.plans);
    final keysToRemove = <String>[];

    for (final entry in updatedPlans.entries) {
      if (entry.key == '__recurring__') continue;
      try {
        final parts = entry.key.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (!date.isBefore(fromDate)) {
          keysToRemove.add(entry.key);
        }
      } catch (_) {}
    }

    for (final key in keysToRemove) {
      updatedPlans.remove(key);
    }

    state = state.copyWith(plans: updatedPlans);
    await _save();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 캘린더 전체 상태 Provider
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>(
  (ref) {
    final repo = ref.watch(calendarRepositoryProvider);
    return CalendarNotifier(repo);
  },
);

/// 선택된 날짜 Provider
final selectedDateProvider = Provider<DateTime>((ref) {
  return ref.watch(calendarProvider).selectedDate;
});

/// 선택된 날짜의 운동 계획 Provider
final selectedDatePlansProvider = Provider<List<WorkoutPlanEntry>>((ref) {
  final calendarState = ref.watch(calendarProvider);
  return calendarState.getPlansForDate(calendarState.selectedDate);
});

/// 오늘의 운동 계획 Provider
final todayWorkoutPlansProvider = Provider<List<WorkoutPlanEntry>>((ref) {
  final calendarState = ref.watch(calendarProvider);
  return calendarState.getPlansForDate(DateTime.now());
});

/// 현재 월 운동 있는 날짜 Provider
final currentMonthWorkoutDaysProvider = Provider<List<DateTime>>((ref) {
  final calendarState = ref.watch(calendarProvider);
  return calendarState.getWorkoutDaysInMonth(calendarState.focusedMonth);
});

/// 오늘 운동 계획 완료 여부 Provider
final isTodayWorkoutCompletedProvider = Provider<bool>((ref) {
  final plans = ref.watch(todayWorkoutPlansProvider);
  if (plans.isEmpty) return false;
  return plans.every((p) => p.isCompleted);
});

/// WorkoutPlan 모델과의 호환용 Provider (기존 WorkoutPlan 사용하는 화면 지원)
final activeWorkoutPlanProvider = Provider<WorkoutPlan?>((ref) {
  // 현재 활성화된 스플릿 계획 (PPL/상하체/풀바디)
  // 실제 구현 시 사용자 설정에 따라 반환
  return null;
});
