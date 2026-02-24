import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Exercise tests
  // ---------------------------------------------------------------------------
  group('Exercise', () {
    test('creation with required fields', () {
      const exercise = Exercise(
        id: 'bench_press',
        name: '벤치프레스',
        nameEn: 'Bench Press',
        bodyPart: BodyPart.chest,
        equipment: Equipment.barbell,
        difficulty: DifficultyLevel.intermediate,
        instructions: ['바에 누워', '내린 후 밀어올린다'],
        isCompound: true,
      );

      expect(exercise.id, 'bench_press');
      expect(exercise.name, '벤치프레스');
      expect(exercise.nameEn, 'Bench Press');
      expect(exercise.bodyPart, BodyPart.chest);
      expect(exercise.equipment, Equipment.barbell);
      expect(exercise.difficulty, DifficultyLevel.intermediate);
      expect(exercise.isCompound, isTrue);
      expect(exercise.secondaryBodyParts, isEmpty);
      expect(exercise.tips, isEmpty);
    });

    test('creation with optional secondary body parts and tips', () {
      const exercise = Exercise(
        id: 'squat',
        name: '스쿼트',
        nameEn: 'Squat',
        bodyPart: BodyPart.quadriceps,
        secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
        equipment: Equipment.barbell,
        difficulty: DifficultyLevel.intermediate,
        instructions: ['바를 등에 지고', '앉았다 일어선다'],
        tips: ['무릎이 발끝을 넘지 않도록'],
        isCompound: true,
      );

      expect(exercise.secondaryBodyParts,
          containsAll([BodyPart.glutes, BodyPart.hamstrings]));
      expect(exercise.tips, contains('무릎이 발끝을 넘지 않도록'));
    });

    test('copyWith updates specified fields only', () {
      const original = Exercise(
        id: 'pullup',
        name: '풀업',
        nameEn: 'Pull-up',
        bodyPart: BodyPart.back,
        equipment: Equipment.bodyweight,
        difficulty: DifficultyLevel.intermediate,
        instructions: ['매달려서 턱걸이'],
      );

      final updated = original.copyWith(difficulty: DifficultyLevel.advanced);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.difficulty, DifficultyLevel.advanced);
    });

    test('equality is based on id', () {
      const e1 = Exercise(
        id: 'deadlift',
        name: '데드리프트',
        nameEn: 'Deadlift',
        bodyPart: BodyPart.back,
        equipment: Equipment.barbell,
        difficulty: DifficultyLevel.advanced,
        instructions: ['바를 들어올린다'],
      );

      const e2 = Exercise(
        id: 'deadlift',
        name: '다른 이름',
        nameEn: 'Different Name',
        bodyPart: BodyPart.fullBody,
        equipment: Equipment.dumbbell,
        difficulty: DifficultyLevel.beginner,
        instructions: [],
      );

      expect(e1, equals(e2));
    });

    test('toJson / fromJson roundtrip', () {
      const exercise = Exercise(
        id: 'row',
        name: '바벨 로우',
        nameEn: 'Barbell Row',
        bodyPart: BodyPart.back,
        secondaryBodyParts: [BodyPart.biceps],
        equipment: Equipment.barbell,
        difficulty: DifficultyLevel.intermediate,
        instructions: ['허리를 숙이고', '당긴다'],
        tips: ['등을 곧게'],
        isCompound: true,
        imageUrl: 'https://example.com/row.jpg',
      );

      final json = exercise.toJson();
      final restored = Exercise.fromJson(json);

      expect(restored.id, exercise.id);
      expect(restored.name, exercise.name);
      expect(restored.nameEn, exercise.nameEn);
      expect(restored.bodyPart, exercise.bodyPart);
      expect(restored.secondaryBodyParts, exercise.secondaryBodyParts);
      expect(restored.equipment, exercise.equipment);
      expect(restored.difficulty, exercise.difficulty);
      expect(restored.instructions, exercise.instructions);
      expect(restored.tips, exercise.tips);
      expect(restored.isCompound, exercise.isCompound);
      expect(restored.imageUrl, exercise.imageUrl);
    });

    test('fromJson with unknown enum values falls back to defaults', () {
      final json = {
        'id': 'unknown_ex',
        'name': '모르는 운동',
        'name_en': 'Unknown',
        'body_part': 'nonexistent_part',
        'secondary_body_parts': ['also_nonexistent'],
        'equipment': 'nonexistent_equipment',
        'difficulty': 'nonexistent_difficulty',
        'instructions': <String>[],
        'tips': <String>[],
        'is_compound': false,
      };

      final exercise = Exercise.fromJson(json);
      expect(exercise.bodyPart, BodyPart.fullBody);
      expect(exercise.equipment, Equipment.none);
      expect(exercise.difficulty, DifficultyLevel.beginner);
      expect(exercise.secondaryBodyParts, [BodyPart.fullBody]);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutSet tests
  // ---------------------------------------------------------------------------
  group('WorkoutSet', () {
    test('volume calculation is weight times reps', () {
      const set = WorkoutSet(setNumber: 1, reps: 10, weight: 80.0);
      expect(set.volume, closeTo(800.0, 0.001));
    });

    test('volume with fractional weight', () {
      const set = WorkoutSet(setNumber: 2, reps: 8, weight: 77.5);
      expect(set.volume, closeTo(620.0, 0.001));
    });

    test('volume when weight is zero', () {
      const set = WorkoutSet(setNumber: 1, reps: 15, weight: 0.0, isWarmUp: true);
      expect(set.volume, closeTo(0.0, 0.001));
    });

    test('default fields are correct', () {
      const set = WorkoutSet(setNumber: 1, reps: 12, weight: 60.0);
      expect(set.isWarmUp, isFalse);
      expect(set.restSeconds, isNull);
      expect(set.note, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = WorkoutSet(
        setNumber: 1,
        reps: 10,
        weight: 100.0,
        restSeconds: 120,
        isWarmUp: false,
        note: 'test note',
      );
      final updated = original.copyWith(weight: 110.0);
      expect(updated.weight, 110.0);
      expect(updated.reps, original.reps);
      expect(updated.restSeconds, original.restSeconds);
      expect(updated.note, original.note);
    });

    test('toJson / fromJson roundtrip', () {
      const set = WorkoutSet(
        setNumber: 3,
        reps: 6,
        weight: 120.0,
        restSeconds: 180,
        isWarmUp: false,
        note: 'heavy set',
      );

      final json = set.toJson();
      final restored = WorkoutSet.fromJson(json);

      expect(restored.setNumber, set.setNumber);
      expect(restored.reps, set.reps);
      expect(restored.weight, set.weight);
      expect(restored.restSeconds, set.restSeconds);
      expect(restored.isWarmUp, set.isWarmUp);
      expect(restored.note, set.note);
    });

    test('fromJson with integer weight converts to double', () {
      final json = {
        'set_number': 1,
        'reps': 10,
        'weight': 80, // integer in JSON
        'rest_seconds': null,
        'is_warm_up': false,
        'note': null,
      };
      final set = WorkoutSet.fromJson(json);
      expect(set.weight, isA<double>());
      expect(set.weight, 80.0);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutExerciseEntry tests
  // ---------------------------------------------------------------------------
  group('WorkoutExerciseEntry', () {
    const exercise = Exercise(
      id: 'curl',
      name: '바벨 컬',
      nameEn: 'Barbell Curl',
      bodyPart: BodyPart.biceps,
      equipment: Equipment.barbell,
      difficulty: DifficultyLevel.beginner,
      instructions: ['컬 동작'],
    );

    test('totalVolume sums all sets', () {
      const entry = WorkoutExerciseEntry(
        exercise: exercise,
        sets: [
          WorkoutSet(setNumber: 1, reps: 15, weight: 20.0, isWarmUp: true),
          WorkoutSet(setNumber: 2, reps: 10, weight: 30.0),
          WorkoutSet(setNumber: 3, reps: 10, weight: 30.0),
          WorkoutSet(setNumber: 4, reps: 8, weight: 35.0),
        ],
      );
      // 300 + 300 + 280 + warmup 300 = 1180
      expect(entry.totalVolume, closeTo(1180.0, 0.001));
    });

    test('effectiveSetCount excludes warmup sets', () {
      const entry = WorkoutExerciseEntry(
        exercise: exercise,
        sets: [
          WorkoutSet(setNumber: 1, reps: 15, weight: 20.0, isWarmUp: true),
          WorkoutSet(setNumber: 2, reps: 10, weight: 30.0),
          WorkoutSet(setNumber: 3, reps: 10, weight: 30.0),
        ],
      );
      expect(entry.effectiveSetCount, 2);
    });

    test('effectiveSetCount with no warmup sets', () {
      const entry = WorkoutExerciseEntry(
        exercise: exercise,
        sets: [
          WorkoutSet(setNumber: 1, reps: 10, weight: 30.0),
          WorkoutSet(setNumber: 2, reps: 10, weight: 30.0),
        ],
      );
      expect(entry.effectiveSetCount, 2);
    });

    test('toJson / fromJson roundtrip', () {
      const entry = WorkoutExerciseEntry(
        exercise: exercise,
        sets: [
          WorkoutSet(setNumber: 1, reps: 10, weight: 30.0),
          WorkoutSet(setNumber: 2, reps: 10, weight: 35.0),
        ],
        note: 'felt strong',
      );

      final json = entry.toJson();
      final restored = WorkoutExerciseEntry.fromJson(json);

      expect(restored.exercise.id, entry.exercise.id);
      expect(restored.sets.length, entry.sets.length);
      expect(restored.sets[0].weight, entry.sets[0].weight);
      expect(restored.sets[1].weight, entry.sets[1].weight);
      expect(restored.note, entry.note);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutLog tests
  // ---------------------------------------------------------------------------
  group('WorkoutLog', () {
    const benchExercise = Exercise(
      id: 'bench',
      name: '벤치프레스',
      nameEn: 'Bench Press',
      bodyPart: BodyPart.chest,
      equipment: Equipment.barbell,
      difficulty: DifficultyLevel.intermediate,
      instructions: [],
    );

    const squatExercise = Exercise(
      id: 'squat',
      name: '스쿼트',
      nameEn: 'Squat',
      bodyPart: BodyPart.quadriceps,
      equipment: Equipment.barbell,
      difficulty: DifficultyLevel.intermediate,
      instructions: [],
    );

    test('totalVolume sums all exercise volumes', () {
      final log = WorkoutLog(
        id: 'log1',
        date: DateTime(2024, 1, 15),
        exercises: const [
          WorkoutExerciseEntry(
            exercise: benchExercise,
            sets: [
              WorkoutSet(setNumber: 1, reps: 10, weight: 80.0),
              WorkoutSet(setNumber: 2, reps: 10, weight: 80.0),
            ],
          ),
          WorkoutExerciseEntry(
            exercise: squatExercise,
            sets: [
              WorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
              WorkoutSet(setNumber: 2, reps: 10, weight: 100.0),
            ],
          ),
        ],
        durationMinutes: 60,
      );
      // bench: 1600, squat: 2000 = 3600
      expect(log.totalVolume, closeTo(3600.0, 0.001));
    });

    test('totalSets counts all sets across exercises', () {
      final log = WorkoutLog(
        id: 'log2',
        date: DateTime(2024, 1, 15),
        exercises: const [
          WorkoutExerciseEntry(
            exercise: benchExercise,
            sets: [
              WorkoutSet(setNumber: 1, reps: 10, weight: 80.0),
              WorkoutSet(setNumber: 2, reps: 10, weight: 80.0),
              WorkoutSet(setNumber: 3, reps: 8, weight: 85.0),
            ],
          ),
          WorkoutExerciseEntry(
            exercise: squatExercise,
            sets: [
              WorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
              WorkoutSet(setNumber: 2, reps: 10, weight: 100.0),
            ],
          ),
        ],
        durationMinutes: 75,
      );
      expect(log.totalSets, 5);
    });

    test('totalVolume is zero for empty exercises', () {
      final log = WorkoutLog(
        id: 'log3',
        date: DateTime(2024, 1, 15),
        exercises: const [],
        durationMinutes: 0,
      );
      expect(log.totalVolume, 0.0);
    });

    test('equality is based on id', () {
      final log1 = WorkoutLog(
        id: 'same_id',
        date: DateTime(2024, 1, 1),
        exercises: const [],
        durationMinutes: 30,
      );
      final log2 = WorkoutLog(
        id: 'same_id',
        date: DateTime(2025, 6, 15),
        exercises: const [],
        durationMinutes: 90,
        title: 'Different Title',
      );
      expect(log1, equals(log2));
    });

    test('toJson / fromJson roundtrip', () {
      final original = WorkoutLog(
        id: 'log_roundtrip',
        date: DateTime(2024, 3, 10, 9, 30),
        title: '가슴 & 어깨',
        exercises: const [
          WorkoutExerciseEntry(
            exercise: benchExercise,
            sets: [
              WorkoutSet(setNumber: 1, reps: 12, weight: 60.0, isWarmUp: true),
              WorkoutSet(setNumber: 2, reps: 10, weight: 80.0),
            ],
          ),
        ],
        durationMinutes: 45,
        note: '컨디션 좋음',
        mood: 'good',
        bodyWeight: 75.5,
      );

      final json = original.toJson();
      final restored = WorkoutLog.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.title, original.title);
      expect(restored.exercises.length, original.exercises.length);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.note, original.note);
      expect(restored.mood, original.mood);
      expect(restored.bodyWeight, original.bodyWeight);
    });
  });

  // ---------------------------------------------------------------------------
  // PersonalRecord tests
  // ---------------------------------------------------------------------------
  group('PersonalRecord', () {
    test('estimatedOneRepMax uses Epley formula', () {
      // weight * (1 + reps / 30)
      final pr = PersonalRecord(
        exerciseId: 'bench',
        exerciseName: '벤치프레스',
        weight: 100.0,
        reps: 5,
        date: DateTime(2024, 1, 1),
      );
      // 100 * (1 + 5/30) ≈ 116.67
      expect(pr.estimatedOneRepMax, closeTo(116.67, 0.01));
    });

    test('estimatedOneRepMax for single rep equals weight', () {
      final pr = PersonalRecord(
        exerciseId: 'squat',
        exerciseName: '스쿼트',
        weight: 150.0,
        reps: 1,
        date: DateTime(2024, 1, 1),
      );
      // 150 * (1 + 1/30) = 155
      expect(pr.estimatedOneRepMax, closeTo(155.0, 0.01));
    });

    test('toJson / fromJson roundtrip', () {
      final pr = PersonalRecord(
        exerciseId: 'deadlift',
        exerciseName: '데드리프트',
        weight: 180.0,
        reps: 3,
        date: DateTime(2024, 5, 20),
      );

      final json = pr.toJson();
      final restored = PersonalRecord.fromJson(json);

      expect(restored.exerciseId, pr.exerciseId);
      expect(restored.exerciseName, pr.exerciseName);
      expect(restored.weight, pr.weight);
      expect(restored.reps, pr.reps);
      expect(restored.date, pr.date);
    });

    test('copyWith updates specified fields', () {
      final original = PersonalRecord(
        exerciseId: 'ohp',
        exerciseName: '오버헤드프레스',
        weight: 60.0,
        reps: 5,
        date: DateTime(2024, 1, 1),
      );
      final updated = original.copyWith(weight: 65.0, reps: 3);
      expect(updated.weight, 65.0);
      expect(updated.reps, 3);
      expect(updated.exerciseId, original.exerciseId);
      expect(updated.exerciseName, original.exerciseName);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutPlan tests
  // ---------------------------------------------------------------------------
  group('WorkoutPlan', () {
    test('getDayPlan returns correct day', () {
      final plan = WorkoutPlan(
        id: 'plan1',
        name: '4분할',
        days: const [
          WorkoutPlanDay(weekday: 1, exerciseIds: ['bench', 'ohp'], planName: '가슴&어깨'),
          WorkoutPlanDay(weekday: 3, exerciseIds: ['squat', 'deadlift'], planName: '하체'),
        ],
        startDate: DateTime(2024, 1, 1),
      );

      expect(plan.getDayPlan(1)?.planName, '가슴&어깨');
      expect(plan.getDayPlan(3)?.planName, '하체');
      expect(plan.getDayPlan(2), isNull);
    });

    test('isRestDay returns true for days without plan', () {
      final plan = WorkoutPlan(
        id: 'plan2',
        name: '3분할',
        days: const [
          WorkoutPlanDay(weekday: 1, exerciseIds: ['bench']),
          WorkoutPlanDay(weekday: 3, exerciseIds: ['squat']),
          WorkoutPlanDay(weekday: 5, exerciseIds: ['deadlift']),
        ],
        startDate: DateTime(2024, 1, 1),
      );

      expect(plan.isRestDay(2), isTrue);
      expect(plan.isRestDay(4), isTrue);
      expect(plan.isRestDay(6), isTrue);
      expect(plan.isRestDay(7), isTrue);
      expect(plan.isRestDay(1), isFalse);
    });

    test('toJson / fromJson roundtrip', () {
      final original = WorkoutPlan(
        id: 'plan_rt',
        name: '5분할',
        description: '고급 분할 루틴',
        days: const [
          WorkoutPlanDay(weekday: 1, exerciseIds: ['bench', 'incline'], planName: '가슴'),
          WorkoutPlanDay(weekday: 2, exerciseIds: ['squat', 'leg_press'], planName: '하체'),
        ],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isActive: true,
      );

      final json = original.toJson();
      final restored = WorkoutPlan.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.days.length, original.days.length);
      expect(restored.days[0].planName, original.days[0].planName);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.isActive, original.isActive);
    });
  });

  // ---------------------------------------------------------------------------
  // SetEntry / ExerciseEntry tests (from workout_providers)
  // ---------------------------------------------------------------------------
  group('SetEntry', () {
    test('volume is weight times reps only when completed', () {
      const completedSet = SetEntry(
        setNumber: 1, weight: 80.0, reps: 10, isCompleted: true,
      );
      const incompleteSet = SetEntry(
        setNumber: 2, weight: 80.0, reps: 10, isCompleted: false,
      );
      expect(completedSet.volume, closeTo(800.0, 0.001));
      expect(incompleteSet.volume, closeTo(0.0, 0.001));
    });

    test('toJson / fromJson roundtrip', () {
      const original = SetEntry(
        setNumber: 2, weight: 90.0, reps: 8, isCompleted: true, isWarmup: false,
      );
      final json = original.toJson();
      final restored = SetEntry.fromJson(json);
      expect(restored.setNumber, original.setNumber);
      expect(restored.weight, original.weight);
      expect(restored.reps, original.reps);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.isWarmup, original.isWarmup);
    });
  });

  group('ExerciseEntry', () {
    test('totalVolume sums only completed sets', () {
      const entry = ExerciseEntry(
        exerciseId: 'bench',
        name: '벤치프레스',
        bodyPart: BodyPart.chest,
        sets: [
          SetEntry(setNumber: 1, weight: 60.0, reps: 15, isCompleted: true, isWarmup: true),
          SetEntry(setNumber: 2, weight: 80.0, reps: 10, isCompleted: true),
          SetEntry(setNumber: 3, weight: 80.0, reps: 10, isCompleted: false),
          SetEntry(setNumber: 4, weight: 85.0, reps: 8, isCompleted: true),
        ],
      );
      // 900 + 800 + 0 + 680 = 2380
      expect(entry.totalVolume, closeTo(2380.0, 0.001));
    });

    test('completedSets counts only completed sets', () {
      const entry = ExerciseEntry(
        exerciseId: 'squat',
        name: '스쿼트',
        bodyPart: BodyPart.quadriceps,
        sets: [
          SetEntry(setNumber: 1, weight: 60.0, reps: 15, isCompleted: true, isWarmup: true),
          SetEntry(setNumber: 2, weight: 100.0, reps: 10, isCompleted: true),
          SetEntry(setNumber: 3, weight: 100.0, reps: 10, isCompleted: false),
        ],
      );
      expect(entry.completedSets, 2);
    });

    test('toJson / fromJson roundtrip', () {
      const original = ExerciseEntry(
        exerciseId: 'deadlift',
        name: '데드리프트',
        bodyPart: BodyPart.back,
        sets: [
          SetEntry(setNumber: 1, weight: 100.0, reps: 5, isCompleted: true),
          SetEntry(setNumber: 2, weight: 120.0, reps: 3, isCompleted: false),
        ],
      );
      final json = original.toJson();
      final restored = ExerciseEntry.fromJson(json);
      expect(restored.exerciseId, original.exerciseId);
      expect(restored.name, original.name);
      expect(restored.bodyPart, original.bodyPart);
      expect(restored.sets.length, original.sets.length);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutRecord tests (from workout_providers)
  // ---------------------------------------------------------------------------
  group('WorkoutRecord', () {
    test('durationMinutes converts from seconds', () {
      final record = WorkoutRecord(
        id: 'rec1',
        date: DateTime(2024, 1, 1),
        durationSeconds: 3723, // 1h 2min 3sec
        exercises: const [],
        totalVolume: 0,
      );
      expect(record.durationMinutes, 62);
    });

    test('targetedBodyParts returns unique body parts', () {
      final record = WorkoutRecord(
        id: 'rec2',
        date: DateTime(2024, 1, 1),
        durationSeconds: 3600,
        exercises: const [
          ExerciseEntry(
            exerciseId: 'bench',
            name: '벤치프레스',
            bodyPart: BodyPart.chest,
            sets: [],
          ),
          ExerciseEntry(
            exerciseId: 'incline',
            name: '인클라인 프레스',
            bodyPart: BodyPart.chest,
            sets: [],
          ),
          ExerciseEntry(
            exerciseId: 'ohp',
            name: '오버헤드프레스',
            bodyPart: BodyPart.shoulders,
            sets: [],
          ),
        ],
        totalVolume: 5000.0,
      );
      expect(record.targetedBodyParts.length, 2);
      expect(record.targetedBodyParts, containsAll([BodyPart.chest, BodyPart.shoulders]));
    });

    test('toJson / fromJson roundtrip', () {
      final original = WorkoutRecord(
        id: 'rec_rt',
        date: DateTime(2024, 6, 1, 10, 30),
        durationSeconds: 5400,
        exercises: const [
          ExerciseEntry(
            exerciseId: 'squat',
            name: '스쿼트',
            bodyPart: BodyPart.quadriceps,
            sets: [
              SetEntry(setNumber: 1, weight: 100.0, reps: 10, isCompleted: true),
            ],
          ),
        ],
        totalVolume: 1000.0,
        notes: '좋은 세션',
      );

      final json = original.toJson();
      final restored = WorkoutRecord.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.exercises.length, original.exercises.length);
      expect(restored.totalVolume, original.totalVolume);
      expect(restored.notes, original.notes);
    });
  });
}
