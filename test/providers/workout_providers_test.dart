import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _bench = Exercise(
  id: 'bench_press',
  name: '벤치프레스',
  nameEn: 'Bench Press',
  bodyPart: BodyPart.chest,
  equipment: Equipment.barbell,
  difficulty: DifficultyLevel.intermediate,
  instructions: [],
);

const _squat = Exercise(
  id: 'squat',
  name: '스쿼트',
  nameEn: 'Squat',
  bodyPart: BodyPart.quadriceps,
  equipment: Equipment.barbell,
  difficulty: DifficultyLevel.intermediate,
  instructions: [],
);

const _deadlift = Exercise(
  id: 'deadlift',
  name: '데드리프트',
  nameEn: 'Deadlift',
  bodyPart: BodyPart.back,
  equipment: Equipment.barbell,
  difficulty: DifficultyLevel.advanced,
  instructions: [],
);

void main() {
  // ---------------------------------------------------------------------------
  // WorkoutSessionNotifier tests
  // ---------------------------------------------------------------------------
  group('WorkoutSessionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is inactive with no exercises', () {
      final state = container.read(workoutSessionProvider);
      expect(state.isActive, isFalse);
      expect(state.exercises, isEmpty);
      expect(state.totalVolume, closeTo(0.0, 0.001));
      expect(state.totalCompletedSets, 0);
      expect(state.hasStarted, isFalse);
    });

    test('startSession activates the session', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      final state = container.read(workoutSessionProvider);
      expect(state.isActive, isTrue);
      expect(state.hasStarted, isTrue);
      expect(state.startTime, isNotNull);
    });

    test('addExercise adds exercise with default sets', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      final state = container.read(workoutSessionProvider);

      expect(state.exercises.length, 1);
      expect(state.exercises[0].exerciseId, _bench.id);
      expect(state.exercises[0].name, _bench.name);
      expect(state.exercises[0].bodyPart, _bench.bodyPart);
      // Default: 1 warmup + 3 work sets
      expect(state.exercises[0].sets.length, 4);
      expect(state.exercises[0].sets[0].isWarmup, isTrue);
    });

    test('addExercise does not add duplicate exercise', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.addExercise(_bench); // duplicate
      final state = container.read(workoutSessionProvider);
      expect(state.exercises.length, 1);
    });

    test('addExercise can add multiple different exercises', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.addExercise(_squat);
      notifier.addExercise(_deadlift);
      final state = container.read(workoutSessionProvider);
      expect(state.exercises.length, 3);
    });

    test('removeExercise removes specified exercise', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.addExercise(_squat);
      notifier.removeExercise(_bench.id);

      final state = container.read(workoutSessionProvider);
      expect(state.exercises.length, 1);
      expect(state.exercises[0].exerciseId, _squat.id);
    });

    test('removeExercise for nonexistent id is a no-op', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.removeExercise('nonexistent_id');
      final state = container.read(workoutSessionProvider);
      expect(state.exercises.length, 1);
    });

    test('addSet appends a new set using last set values', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      // Update last set weight so new set inherits it
      notifier.updateSet(_bench.id, 3, weight: 80.0, reps: 8);
      final before = container.read(workoutSessionProvider);
      final setCountBefore = before.exercises[0].sets.length;

      notifier.addSet(_bench.id);
      final state = container.read(workoutSessionProvider);
      expect(state.exercises[0].sets.length, setCountBefore + 1);
      // New set should inherit last set's values
      expect(state.exercises[0].sets.last.weight, 80.0);
      expect(state.exercises[0].sets.last.reps, 8);
    });

    test('removeSet removes the correct set and reindexes', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      // Default sets: indices 0,1,2,3
      notifier.removeSet(_bench.id, 1); // remove index 1

      final state = container.read(workoutSessionProvider);
      expect(state.exercises[0].sets.length, 3);
      // After reindexing, set numbers should be 1,2,3
      expect(state.exercises[0].sets[0].setNumber, 1);
      expect(state.exercises[0].sets[1].setNumber, 2);
      expect(state.exercises[0].sets[2].setNumber, 3);
    });

    test('updateSet changes weight and reps', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.updateSet(_bench.id, 1, weight: 100.0, reps: 5);

      final state = container.read(workoutSessionProvider);
      expect(state.exercises[0].sets[1].weight, 100.0);
      expect(state.exercises[0].sets[1].reps, 5);
      // Other sets unchanged
      expect(state.exercises[0].sets[0].weight, 0.0);
    });

    test('toggleSetComplete marks set as completed', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      expect(container.read(workoutSessionProvider).exercises[0].sets[1].isCompleted, isFalse);

      notifier.toggleSetComplete(_bench.id, 1);
      expect(container.read(workoutSessionProvider).exercises[0].sets[1].isCompleted, isTrue);

      // Toggle back
      notifier.toggleSetComplete(_bench.id, 1);
      expect(container.read(workoutSessionProvider).exercises[0].sets[1].isCompleted, isFalse);
    });

    test('totalVolume calculation reflects completed sets', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      // Set up set 1 (index 1) with weight 80 * 10 = 800
      notifier.updateSet(_bench.id, 1, weight: 80.0, reps: 10);
      notifier.toggleSetComplete(_bench.id, 1);
      // Set up set 2 (index 2) with weight 80 * 10 = 800
      notifier.updateSet(_bench.id, 2, weight: 80.0, reps: 10);
      notifier.toggleSetComplete(_bench.id, 2);

      final state = container.read(workoutSessionProvider);
      expect(state.totalVolume, closeTo(1600.0, 0.001));
    });

    test('totalCompletedSets counts completed sets', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.addExercise(_bench);
      notifier.addExercise(_squat);

      notifier.toggleSetComplete(_bench.id, 1);
      notifier.toggleSetComplete(_bench.id, 2);
      notifier.toggleSetComplete(_squat.id, 1);

      final state = container.read(workoutSessionProvider);
      expect(state.totalCompletedSets, 3);
    });

    test('cancelSession resets state', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      notifier.cancelSession();

      final state = container.read(workoutSessionProvider);
      expect(state.isActive, isFalse);
      expect(state.exercises, isEmpty);
    });

    test('completeSession returns null when not active', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      final record = notifier.completeSession();
      expect(record, isNull);
    });

    test('completeSession returns null when no exercises', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      final record = notifier.completeSession();
      expect(record, isNull);
    });

    test('completeSession returns WorkoutRecord and resets state', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      notifier.updateSet(_bench.id, 1, weight: 80.0, reps: 10);
      notifier.toggleSetComplete(_bench.id, 1);

      final record = notifier.completeSession(notes: 'great workout');
      expect(record, isNotNull);
      expect(record!.notes, 'great workout');
      expect(record.exercises.length, 1);

      // State should be reset
      final state = container.read(workoutSessionProvider);
      expect(state.isActive, isFalse);
      expect(state.exercises, isEmpty);
    });

    test('detectPRs identifies new personal records', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      notifier.updateSet(_bench.id, 1, weight: 100.0, reps: 5);
      notifier.toggleSetComplete(_bench.id, 1);

      // No existing PRs - should be new PR
      final newPRs = notifier.detectPRs([]);
      expect(newPRs, contains(_bench.id));
    });

    test('detectPRs detects improvement over existing PR', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      notifier.updateSet(_bench.id, 1, weight: 110.0, reps: 5);
      notifier.toggleSetComplete(_bench.id, 1);

      final existingPR = PersonalRecord(
        exerciseId: _bench.id,
        exerciseName: _bench.name,
        weight: 100.0,
        reps: 5,
        date: DateTime(2024, 1, 1),
      );

      final newPRs = notifier.detectPRs([existingPR]);
      expect(newPRs, contains(_bench.id));
    });

    test('detectPRs does not flag when no improvement', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      notifier.updateSet(_bench.id, 1, weight: 90.0, reps: 5);
      notifier.toggleSetComplete(_bench.id, 1);

      final existingPR = PersonalRecord(
        exerciseId: _bench.id,
        exerciseName: _bench.name,
        weight: 100.0,
        reps: 5,
        date: DateTime(2024, 1, 1),
      );

      final newPRs = notifier.detectPRs([existingPR]);
      expect(newPRs, isNot(contains(_bench.id)));
    });

    test('detectPRs does not include warmup sets', () {
      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.startSession();
      notifier.addExercise(_bench);
      // index 0 is warmup by default
      notifier.updateSet(_bench.id, 0, weight: 200.0, reps: 15);
      notifier.toggleSetComplete(_bench.id, 0);

      // Only warmup completed - should not detect as PR
      final newPRs = notifier.detectPRs([]);
      expect(newPRs, isNot(contains(_bench.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutHistoryNotifier tests (pure logic, no SharedPreferences)
  // ---------------------------------------------------------------------------
  group('WorkoutHistoryNotifier - initial state', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty list', () {
      // Before async load completes, state is empty
      final history = container.read(workoutHistoryProvider);
      expect(history, isEmpty);
    });

    test('personal records are initially empty', () {
      final notifier = container.read(workoutHistoryProvider.notifier);
      expect(notifier.personalRecords, isEmpty);
    });

    test('weeklyVolume is zero when no records', () {
      final notifier = container.read(workoutHistoryProvider.notifier);
      expect(notifier.weeklyVolume, closeTo(0.0, 0.001));
    });

    test('currentStreak is zero when no records', () {
      final notifier = container.read(workoutHistoryProvider.notifier);
      expect(notifier.currentStreak, 0);
    });

    test('monthlyWorkoutDays is zero when no records', () {
      final notifier = container.read(workoutHistoryProvider.notifier);
      expect(notifier.monthlyWorkoutDays, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutHistoryNotifier – PR detection logic
  // ---------------------------------------------------------------------------
  group('WorkoutHistoryNotifier - PR detection', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    WorkoutRecord makeRecord({
      required String id,
      required String exerciseId,
      required String exerciseName,
      required double weight,
      required int reps,
      bool completed = true,
      bool warmup = false,
    }) {
      return WorkoutRecord(
        id: id,
        date: DateTime.now(),
        durationSeconds: 3600,
        exercises: [
          ExerciseEntry(
            exerciseId: exerciseId,
            name: exerciseName,
            bodyPart: BodyPart.chest,
            sets: [
              SetEntry(
                setNumber: 1,
                weight: weight,
                reps: reps,
                isCompleted: completed,
                isWarmup: warmup,
              ),
            ],
          ),
        ],
        totalVolume: completed && !warmup ? weight * reps : 0.0,
      );
    }

    test('saving a record with a new exercise creates a PR', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      final record = makeRecord(
        id: 'r1',
        exerciseId: 'bench_press',
        exerciseName: '벤치프레스',
        weight: 80.0,
        reps: 10,
      );
      await notifier.saveRecord(record);

      final pr = notifier.getPRForExercise('bench_press');
      expect(pr, isNotNull);
      expect(pr!.weight, 80.0);
      expect(pr.reps, 10);
    });

    test('saving a heavier record updates PR', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(makeRecord(
        id: 'r1', exerciseId: 'bench_press', exerciseName: '벤치프레스',
        weight: 80.0, reps: 10,
      ));
      await notifier.saveRecord(makeRecord(
        id: 'r2', exerciseId: 'bench_press', exerciseName: '벤치프레스',
        weight: 90.0, reps: 8,
      ));

      final pr = notifier.getPRForExercise('bench_press');
      expect(pr!.weight, 90.0);
    });

    test('saving a lighter record does not update PR', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(makeRecord(
        id: 'r1', exerciseId: 'bench_press', exerciseName: '벤치프레스',
        weight: 90.0, reps: 8,
      ));
      await notifier.saveRecord(makeRecord(
        id: 'r2', exerciseId: 'bench_press', exerciseName: '벤치프레스',
        weight: 80.0, reps: 10,
      ));

      final pr = notifier.getPRForExercise('bench_press');
      expect(pr!.weight, 90.0); // Still the heavier one
    });

    test('same weight but more reps updates PR', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(makeRecord(
        id: 'r1', exerciseId: 'ohp', exerciseName: '오버헤드프레스',
        weight: 60.0, reps: 5,
      ));
      await notifier.saveRecord(makeRecord(
        id: 'r2', exerciseId: 'ohp', exerciseName: '오버헤드프레스',
        weight: 60.0, reps: 8,
      ));

      final pr = notifier.getPRForExercise('ohp');
      expect(pr!.reps, 8);
    });

    test('warmup sets are excluded from PR detection', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(makeRecord(
        id: 'r_warmup',
        exerciseId: 'curl',
        exerciseName: '컬',
        weight: 50.0,
        reps: 15,
        warmup: true,
      ));
      final pr = notifier.getPRForExercise('curl');
      expect(pr, isNull);
    });

    test('incomplete sets are excluded from PR detection', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(makeRecord(
        id: 'r_incomplete',
        exerciseId: 'curl',
        exerciseName: '컬',
        weight: 50.0,
        reps: 12,
        completed: false,
      ));
      final pr = notifier.getPRForExercise('curl');
      expect(pr, isNull);
    });

    test('getPRForExercise returns null for unknown exercise', () {
      final notifier = container.read(workoutHistoryProvider.notifier);
      expect(notifier.getPRForExercise('nonexistent'), isNull);
    });

    test('deleteRecord removes the record', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      final record = makeRecord(
        id: 'to_delete',
        exerciseId: 'bench_press',
        exerciseName: '벤치프레스',
        weight: 80.0,
        reps: 10,
      );
      await notifier.saveRecord(record);
      expect(container.read(workoutHistoryProvider).length, 1);

      await notifier.deleteRecord('to_delete');
      expect(container.read(workoutHistoryProvider), isEmpty);
    });

    test('saving duplicate record is ignored', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      final record = makeRecord(
        id: 'dup',
        exerciseId: 'bench_press',
        exerciseName: '벤치프레스',
        weight: 80.0,
        reps: 10,
      );
      await notifier.saveRecord(record);
      await notifier.saveRecord(record); // duplicate
      expect(container.read(workoutHistoryProvider).length, 1);
    });

    test('getRecordsByBodyPart filters correctly', () async {
      final notifier = container.read(workoutHistoryProvider.notifier);
      await notifier.saveRecord(WorkoutRecord(
        id: 'chest_rec',
        date: DateTime.now(),
        durationSeconds: 3600,
        exercises: const [
          ExerciseEntry(
            exerciseId: 'bench',
            name: '벤치프레스',
            bodyPart: BodyPart.chest,
            sets: [],
          ),
        ],
        totalVolume: 0.0,
      ));
      await notifier.saveRecord(WorkoutRecord(
        id: 'back_rec',
        date: DateTime.now(),
        durationSeconds: 3600,
        exercises: const [
          ExerciseEntry(
            exerciseId: 'row',
            name: '로우',
            bodyPart: BodyPart.back,
            sets: [],
          ),
        ],
        totalVolume: 0.0,
      ));

      final chestRecords = notifier.getRecordsByBodyPart(BodyPart.chest);
      expect(chestRecords.length, 1);
      expect(chestRecords[0].id, 'chest_rec');
    });
  });
}
