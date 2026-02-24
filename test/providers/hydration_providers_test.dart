import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_overrides.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

WaterIntakeEntry _makeEntry(String id, int amountMl) {
  return WaterIntakeEntry(
    id: id,
    time: DateTime(2024, 1, 1, 9, 0),
    amountMl: amountMl,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // DailyHydrationState tests (pure model logic)
  // ---------------------------------------------------------------------------
  group('DailyHydrationState', () {
    test('initial state has correct defaults', () {
      final state = DailyHydrationState(date: DateTime(2024, 1, 1));
      expect(state.entries, isEmpty);
      expect(state.goalMl, 2000);
      expect(state.reminderHours, [9, 12, 15, 18, 21]);
      expect(state.totalMl, 0);
      expect(state.progress, 0.0);
      expect(state.isGoalReached, isFalse);
    });

    test('totalMl sums all entries', () {
      final state = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [
          _makeEntry('e1', 250),
          _makeEntry('e2', 500),
          _makeEntry('e3', 350),
        ],
        goalMl: 2000,
      );
      expect(state.totalMl, 1100);
    });

    test('remainingMl clamps to 0 when total exceeds goal', () {
      final state = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 3000)],
        goalMl: 2000,
      );
      expect(state.remainingMl, 0);
    });

    test('remainingMl is correct when under goal', () {
      final state = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 800)],
        goalMl: 2000,
      );
      expect(state.remainingMl, 1200);
    });

    test('progress is clamped between 0 and 1', () {
      final under = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 500)],
        goalMl: 2000,
      );
      expect(under.progress, closeTo(0.25, 0.001));

      final over = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 5000)],
        goalMl: 2000,
      );
      expect(over.progress, closeTo(1.0, 0.001));
    });

    test('isGoalReached is true when total meets goal', () {
      final notReached = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 1999)],
        goalMl: 2000,
      );
      expect(notReached.isGoalReached, isFalse);

      final reached = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 2000)],
        goalMl: 2000,
      );
      expect(reached.isGoalReached, isTrue);
    });

    test('progressPercent rounds to nearest integer', () {
      final state = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 1500)],
        goalMl: 2000,
      );
      // 1500/2000 = 75%
      expect(state.progressPercent, 75);
    });

    test('copyWith updates only specified fields', () {
      final original = DailyHydrationState(
        date: DateTime(2024, 1, 1),
        entries: [_makeEntry('e1', 500)],
        goalMl: 2000,
        reminderHours: const [9, 12, 18],
      );

      final updated = original.copyWith(goalMl: 2500);
      expect(updated.goalMl, 2500);
      expect(updated.entries, original.entries);
      expect(updated.reminderHours, original.reminderHours);
      expect(updated.date, original.date);
    });

    test('toJson / fromJson roundtrip', () {
      final original = DailyHydrationState(
        date: DateTime(2024, 6, 15),
        entries: [
          _makeEntry('e1', 250),
          _makeEntry('e2', 500),
        ],
        goalMl: 2500,
        reminderHours: const [8, 12, 16, 20],
      );

      final json = original.toJson();
      final restored = DailyHydrationState.fromJson(json);

      expect(restored.date, original.date);
      expect(restored.entries.length, original.entries.length);
      expect(restored.goalMl, original.goalMl);
      expect(restored.reminderHours, original.reminderHours);
    });
  });

  // ---------------------------------------------------------------------------
  // HydrationNotifier tests
  // ---------------------------------------------------------------------------
  group('HydrationNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(overrides: testOverrides);
      // 프로바이더 초기화 - async _loadFromPrefs 완료 대기
      container.read(hydrationProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty entries and 2000ml goal', () {
      final state = container.read(hydrationProvider);
      expect(state.entries, isEmpty);
      expect(state.goalMl, 2000);
      expect(state.totalMl, 0);
    });

    test('addWater increases total water intake', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      final state = container.read(hydrationProvider);
      expect(state.totalMl, 250);
      expect(state.entries.length, 1);
      expect(state.entries[0].amountMl, 250);
    });

    test('addWater with note stores the note', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(300, note: '운동 후');
      final state = container.read(hydrationProvider);
      expect(state.entries[0].note, '운동 후');
    });

    test('add150ml adds 150ml', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.add150ml();
      expect(container.read(hydrationProvider).totalMl, 150);
    });

    test('add250ml adds 250ml', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.add250ml();
      expect(container.read(hydrationProvider).totalMl, 250);
    });

    test('add500ml adds 500ml', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.add500ml();
      expect(container.read(hydrationProvider).totalMl, 500);
    });

    test('multiple addWater calls accumulate correctly', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      await notifier.addWater(500);
      await notifier.addWater(350);
      expect(container.read(hydrationProvider).totalMl, 1100);
      expect(container.read(hydrationProvider).entries.length, 3);
    });

    test('progress updates after adding water', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(1000);
      final state = container.read(hydrationProvider);
      expect(state.progress, closeTo(0.5, 0.001));
    });

    test('isGoalReached becomes true when goal is met', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(2000);
      expect(container.read(hydrationProvider).isGoalReached, isTrue);
    });

    test('removeEntry removes the specified entry', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      await notifier.addWater(500);

      final entries = container.read(hydrationProvider).entries;
      expect(entries.length, 2);

      final firstId = entries[0].id;
      await notifier.removeEntry(firstId);

      final updatedState = container.read(hydrationProvider);
      expect(updatedState.entries.length, 1);
      expect(updatedState.entries[0].amountMl, 500);
    });

    test('removeEntry for nonexistent id is a no-op', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      await notifier.removeEntry('nonexistent_id');
      expect(container.read(hydrationProvider).entries.length, 1);
    });

    test('resetToday clears all entries', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      await notifier.addWater(500);
      await notifier.resetToday();

      final state = container.read(hydrationProvider);
      expect(state.entries, isEmpty);
      expect(state.totalMl, 0);
    });

    test('setDailyGoal updates the goal', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setDailyGoal(3000);
      expect(container.read(hydrationProvider).goalMl, 3000);
    });

    test('progress recalculates after goal change', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(1000);
      await notifier.setDailyGoal(2000);
      expect(container.read(hydrationProvider).progress, closeTo(0.5, 0.001));

      await notifier.setDailyGoal(1000);
      expect(container.read(hydrationProvider).progress, closeTo(1.0, 0.001));
    });

    test('setReminderHours sorts and deduplicates hours', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setReminderHours([20, 8, 12, 8, 16, 25]); // 25 is invalid
      final state = container.read(hydrationProvider);
      // 25 filtered out, duplicates removed, sorted
      expect(state.reminderHours, [8, 12, 16, 20]);
    });

    test('addReminderHour appends and sorts', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setReminderHours([9, 18]);
      await notifier.addReminderHour(12);
      expect(container.read(hydrationProvider).reminderHours, [9, 12, 18]);
    });

    test('addReminderHour ignores invalid hours', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setReminderHours([9, 18]);
      await notifier.addReminderHour(24); // invalid
      await notifier.addReminderHour(-1); // invalid
      expect(container.read(hydrationProvider).reminderHours, [9, 18]);
    });

    test('addReminderHour ignores duplicate hours', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setReminderHours([9, 12]);
      await notifier.addReminderHour(9); // already exists
      expect(container.read(hydrationProvider).reminderHours, [9, 12]);
    });

    test('removeReminderHour removes specified hour', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.setReminderHours([9, 12, 18]);
      await notifier.removeReminderHour(12);
      expect(container.read(hydrationProvider).reminderHours, [9, 18]);
    });
  });

  // ---------------------------------------------------------------------------
  // Derived providers tests
  // ---------------------------------------------------------------------------
  group('Hydration derived providers', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(overrides: testOverrides);
      // 프로바이더 초기화 - async _loadFromPrefs 완료 대기
      container.read(hydrationProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('todayWaterIntakeProvider reflects total ml', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(750);
      expect(container.read(todayWaterIntakeProvider), 750);
    });

    test('waterProgressProvider reflects progress ratio', () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(1000);
      expect(container.read(waterProgressProvider), closeTo(0.5, 0.001));
    });

    test('isWaterGoalReachedProvider is true when goal met', () async {
      final notifier = container.read(hydrationProvider.notifier);
      expect(container.read(isWaterGoalReachedProvider), isFalse);
      await notifier.addWater(2000);
      expect(container.read(isWaterGoalReachedProvider), isTrue);
    });

    test('remainingWaterProvider decreases as water is added', () async {
      final notifier = container.read(hydrationProvider.notifier);
      expect(container.read(remainingWaterProvider), 2000);
      await notifier.addWater(500);
      expect(container.read(remainingWaterProvider), 1500);
      await notifier.addWater(1500);
      expect(container.read(remainingWaterProvider), 0);
    });

    test('waterTimelineProvider returns entries in reverse chronological order',
        () async {
      final notifier = container.read(hydrationProvider.notifier);
      await notifier.addWater(250);
      await notifier.addWater(500);
      await notifier.addWater(150);

      final timeline = container.read(waterTimelineProvider);
      expect(timeline.length, 3);
      // Most recent first (last added = highest time)
      expect(timeline[0].amountMl, 150);
      expect(timeline[2].amountMl, 250);
    });

    test('waterQuickAddOptionsProvider returns default quick add options', () {
      final options = container.read(waterQuickAddOptionsProvider);
      expect(options, isNotEmpty);
      expect(options.any((o) => o.amountMl == 250), isTrue);
      expect(options.any((o) => o.amountMl == 500), isTrue);
    });
  });
}
