// 수분 섭취 추적 상태 관리
// HydrationNotifier: 일일 물 섭취 기록, 타이머, 알림 시간 관리

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/core/constants/app_constants.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';

// ---------------------------------------------------------------------------
// DailyHydrationState - 일일 수분 섭취 상태
// ---------------------------------------------------------------------------

/// 하루 수분 섭취 전체 상태
class DailyHydrationState {
  final DateTime date;
  final List<WaterIntakeEntry> entries; // 개별 섭취 기록
  final int goalMl; // 하루 목표 섭취량 (ml)
  final List<int> reminderHours; // 알림 시간 목록 (예: [9, 12, 15, 18, 21])

  const DailyHydrationState({
    required this.date,
    this.entries = const [],
    this.goalMl = AppDefaults.dailyWaterGoalMl,
    this.reminderHours = AppDefaults.defaultReminderHours,
  });

  /// 하루 총 섭취량 (ml)
  int get totalMl => entries.fold(0, (sum, e) => sum + e.amountMl);

  /// 남은 섭취량 (ml)
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  /// 달성률 (0.0 ~ 1.0)
  double get progress => (totalMl / goalMl).clamp(0.0, 1.0);

  /// 목표 달성 여부
  bool get isGoalReached => totalMl >= goalMl;

  /// 섭취 비율 (%)
  int get progressPercent => (progress * 100).round();

  DailyHydrationState copyWith({
    DateTime? date,
    List<WaterIntakeEntry>? entries,
    int? goalMl,
    List<int>? reminderHours,
  }) {
    return DailyHydrationState(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      goalMl: goalMl ?? this.goalMl,
      reminderHours: reminderHours ?? this.reminderHours,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'goal_ml': goalMl,
        'reminder_hours': reminderHours,
      };

  factory DailyHydrationState.fromJson(Map<String, dynamic> json) =>
      DailyHydrationState(
        date: DateTime.parse(json['date'] as String),
        entries: (json['entries'] as List<dynamic>)
            .map((e) =>
                WaterIntakeEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        goalMl: json['goal_ml'] as int? ?? 2000,
        reminderHours:
            List<int>.from(json['reminder_hours'] as List? ?? [9, 12, 15, 18, 21]),
      );
}

// ---------------------------------------------------------------------------
// HydrationNotifier - 수분 섭취 상태 관리
// ---------------------------------------------------------------------------

class HydrationNotifier extends StateNotifier<DailyHydrationState> {
  HydrationNotifier(this._repo)
      : super(DailyHydrationState(date: DateTime.now())) {
    _load();
  }

  final HydrationRepository _repo;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── 영속성 ────────────────────────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      'hydration_${date.year}_${date.month}_${date.day}';

  Future<void> _load() async {
    try {
      // 설정 로드 (목표/알림)
      int goalMl = AppDefaults.dailyWaterGoalMl;
      List<int> reminderHours = AppDefaults.defaultReminderHours;

      final settings = await _repo.loadHydrationSettings();
      goalMl = settings['goal_ml'] as int? ?? 2000;
      reminderHours = List<int>.from(
          settings['reminder_hours'] as List? ?? [9, 12, 15, 18, 21]);

      // 오늘 섭취 기록 로드
      final today = DateTime.now();
      final data = await _repo.loadHydrationData(_dateKey(today));
      List<WaterIntakeEntry> entries = [];

      if (data.isNotEmpty) {
        final hydState = DailyHydrationState.fromJson(data);
        entries = hydState.entries;
      }

      if (_disposed) return;
      state = DailyHydrationState(
        date: today,
        entries: entries,
        goalMl: goalMl,
        reminderHours: reminderHours,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      // 오늘 기록 저장
      await _repo.saveHydrationData(_dateKey(state.date), state.toJson());
      // 설정 저장
      await _repo.saveHydrationSettings({
        'goal_ml': state.goalMl,
        'reminder_hours': state.reminderHours,
      });
    } catch (_) {}
  }

  // ── 수분 추가 ─────────────────────────────────────────────────────────────

  /// 물 추가 (+150ml)
  Future<void> add150ml() => addWater(150);

  /// 물 추가 (+250ml)
  Future<void> add250ml() => addWater(250);

  /// 물 추가 (+500ml)
  Future<void> add500ml() => addWater(500);

  /// 물 추가 (사용자 지정 ml)
  Future<void> addWater(int amountMl, {String? note}) async {
    final entry = WaterIntakeEntry(
      id: const Uuid().v4(),
      time: DateTime.now(),
      amountMl: amountMl,
      note: note,
    );
    state = state.copyWith(
      entries: [...state.entries, entry],
    );
    await _save();
  }

  /// 기록 삭제
  Future<void> removeEntry(String entryId) async {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != entryId).toList(),
    );
    await _save();
  }

  /// 오늘 전체 기록 초기화
  Future<void> resetToday() async {
    state = state.copyWith(entries: []);
    await _save();
  }

  // ── 목표 및 설정 ──────────────────────────────────────────────────────────

  /// 일일 목표 설정
  Future<void> setDailyGoal(int goalMl) async {
    state = state.copyWith(goalMl: goalMl);
    await _save();
  }

  /// 알림 시간 설정
  Future<void> setReminderHours(List<int> hours) async {
    // 유효한 시간(0-23) 정렬
    final validHours = hours
        .where((h) => h >= 0 && h <= 23)
        .toSet()
        .toList()
      ..sort();
    state = state.copyWith(reminderHours: validHours);
    await _save();
  }

  /// 알림 시간 추가
  Future<void> addReminderHour(int hour) async {
    if (hour < 0 || hour > 23) return;
    if (state.reminderHours.contains(hour)) return;

    final newHours = [...state.reminderHours, hour]..sort();
    await setReminderHours(newHours);
  }

  /// 알림 시간 제거
  Future<void> removeReminderHour(int hour) async {
    await setReminderHours(
        state.reminderHours.where((h) => h != hour).toList());
  }

  // ── 날짜 전환 ─────────────────────────────────────────────────────────────

  /// 특정 날짜 기록 로드
  Future<DailyHydrationState?> loadDate(DateTime date) async {
    try {
      final data = await _repo.loadHydrationData(_dateKey(date));
      if (data.isNotEmpty) {
        return DailyHydrationState.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── 통계 ─────────────────────────────────────────────────────────────────

  /// 주간 통계 (각 날짜의 총 섭취량)
  Future<Map<DateTime, int>> getWeeklyStats() async {
    final stats = <DateTime, int>{};
    try {
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        final data = await _repo.loadHydrationData(_dateKey(date));
        if (data.isNotEmpty) {
          final hydState = DailyHydrationState.fromJson(data);
          stats[dateOnly] = hydState.totalMl;
        } else {
          stats[dateOnly] = 0;
        }
      }
    } catch (_) {}
    return stats;
  }

  /// 주간 평균 섭취량 (ml)
  Future<double> getWeeklyAverage() async {
    final stats = await getWeeklyStats();
    if (stats.isEmpty) return 0;

    final total = stats.values.fold(0, (sum, v) => sum + v);
    return total / stats.length;
  }

  /// 연속 목표 달성일 (streak)
  Future<int> getGoalStreak() async {
    int streak = 0;
    try {
      DateTime checkDate = DateTime.now();

      while (true) {
        final data = await _repo.loadHydrationData(_dateKey(checkDate));
        if (data.isEmpty) break;

        final hydState = DailyHydrationState.fromJson(data);
        if (!hydState.isGoalReached) break;

        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } catch (_) {}
    return streak;
  }
}

// ---------------------------------------------------------------------------
// 수분 빠른 추가 옵션
// ---------------------------------------------------------------------------

/// 빠른 추가 옵션 모델
class WaterQuickAddOption {
  final int amountMl;
  final String label;
  final String emoji;

  const WaterQuickAddOption({
    required this.amountMl,
    required this.label,
    required this.emoji,
  });
}

/// 기본 빠른 추가 옵션 목록
const List<WaterQuickAddOption> kWaterQuickAddOptions = [
  WaterQuickAddOption(amountMl: 150, label: '150ml', emoji: '🥤'),
  WaterQuickAddOption(amountMl: 250, label: '250ml', emoji: '🥛'),
  WaterQuickAddOption(amountMl: 350, label: '350ml', emoji: '🫗'),
  WaterQuickAddOption(amountMl: 500, label: '500ml', emoji: '🍶'),
  WaterQuickAddOption(amountMl: 700, label: '700ml', emoji: '🧃'),
  WaterQuickAddOption(amountMl: 1000, label: '1L', emoji: '🫙'),
];

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 오늘 수분 섭취 Provider
final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, DailyHydrationState>(
  (ref) {
    final repo = ref.watch(hydrationRepositoryProvider);
    return HydrationNotifier(repo);
  },
);

/// 오늘 총 수분 섭취량 Provider
final todayWaterIntakeProvider = Provider<int>((ref) {
  return ref.watch(hydrationProvider).totalMl;
});

/// 수분 섭취 달성률 Provider
final waterProgressProvider = Provider<double>((ref) {
  return ref.watch(hydrationProvider).progress;
});

/// 오늘 수분 목표 달성 여부 Provider
final isWaterGoalReachedProvider = Provider<bool>((ref) {
  return ref.watch(hydrationProvider).isGoalReached;
});

/// 남은 수분 섭취량 Provider
final remainingWaterProvider = Provider<int>((ref) {
  return ref.watch(hydrationProvider).remainingMl;
});

/// 수분 타임라인 Provider (역순 - 최신 먼저)
final waterTimelineProvider = Provider<List<WaterIntakeEntry>>((ref) {
  final entries = ref.watch(hydrationProvider).entries;
  return [...entries]..sort((a, b) => b.time.compareTo(a.time));
});

/// 빠른 추가 옵션 Provider
final waterQuickAddOptionsProvider =
    Provider<List<WaterQuickAddOption>>((ref) => kWaterQuickAddOptions);
