// 사전 제작 운동 프로그램 상태 관리
// WorkoutProgram, ProgramWeek, ProgramDay, ProgramExercise, ActiveProgram 모델
// 5개 내장 프로그램 + SharedPreferences 기반 활성 프로그램 영속성

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/models/workout_model.dart';

// ---------------------------------------------------------------------------
// SharedPreferences 키
// ---------------------------------------------------------------------------

abstract final class _ProgramKeys {
  static const String activeProgram = 'active_program_json';
}

// ---------------------------------------------------------------------------
// 데이터 모델
// ---------------------------------------------------------------------------

/// 프로그램 내 개별 운동 항목
class ProgramExercise {
  final String exerciseId;
  final int sets;
  final String reps; // "8-12" 또는 "5" 같은 범위 표현 허용
  final int restSeconds;
  final String? notes;

  const ProgramExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'sets': sets,
        'reps': reps,
        'rest_seconds': restSeconds,
        'notes': notes,
      };

  factory ProgramExercise.fromJson(Map<String, dynamic> json) =>
      ProgramExercise(
        exerciseId: json['exercise_id'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as String,
        restSeconds: json['rest_seconds'] as int? ?? 90,
        notes: json['notes'] as String?,
      );
}

/// 프로그램의 하루 운동 계획
class ProgramDay {
  final int dayNumber; // 1-based
  final String name; // 예: "Push Day", "Upper A"
  final List<ProgramExercise> exercises;
  final bool restDay;

  const ProgramDay({
    required this.dayNumber,
    required this.name,
    this.exercises = const [],
    this.restDay = false,
  });

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'rest_day': restDay,
      };

  factory ProgramDay.fromJson(Map<String, dynamic> json) => ProgramDay(
        dayNumber: json['day_number'] as int,
        name: json['name'] as String,
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        restDay: json['rest_day'] as bool? ?? false,
      );
}

/// 프로그램의 한 주 계획
class ProgramWeek {
  final int weekNumber; // 1-based
  final List<ProgramDay> days;

  const ProgramWeek({
    required this.weekNumber,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory ProgramWeek.fromJson(Map<String, dynamic> json) => ProgramWeek(
        weekNumber: json['week_number'] as int,
        days: (json['days'] as List<dynamic>)
            .map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

/// 전체 운동 프로그램 정의
class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final int durationWeeks;
  final int daysPerWeek;
  final String splitType; // TODO: l10n
  final List<ProgramWeek> weeks;
  final List<String> tags;
  final bool isPremium;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.daysPerWeek,
    required this.splitType,
    required this.weeks,
    this.tags = const [],
    this.isPremium = false,
  });
}

/// 현재 진행 중인 활성 프로그램 상태
class ActiveProgram {
  final String programId;
  final DateTime startDate;
  final int currentWeek; // 1-based
  final int currentDay; // 1-based (프로그램 주 내 일)
  final List<String> completedDayKeys; // "week1_day1" 형식

  const ActiveProgram({
    required this.programId,
    required this.startDate,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.completedDayKeys = const [],
  });

  ActiveProgram copyWith({
    String? programId,
    DateTime? startDate,
    int? currentWeek,
    int? currentDay,
    List<String>? completedDayKeys,
  }) {
    return ActiveProgram(
      programId: programId ?? this.programId,
      startDate: startDate ?? this.startDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      completedDayKeys: completedDayKeys ?? this.completedDayKeys,
    );
  }

  Map<String, dynamic> toJson() => {
        'program_id': programId,
        'start_date': startDate.toIso8601String(),
        'current_week': currentWeek,
        'current_day': currentDay,
        'completed_day_keys': completedDayKeys,
      };

  factory ActiveProgram.fromJson(Map<String, dynamic> json) => ActiveProgram(
        programId: json['program_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        currentWeek: json['current_week'] as int? ?? 1,
        currentDay: json['current_day'] as int? ?? 1,
        completedDayKeys:
            List<String>.from(json['completed_day_keys'] as List? ?? []),
      );

  /// 특정 날짜 완료 여부 확인
  bool isDayCompleted(int week, int day) =>
      completedDayKeys.contains('week${week}_day$day');

  /// 전체 완료율 (completed days / total program days)
  double progressPercent(WorkoutProgram program) {
    int totalWorkDays = 0;
    for (final week in program.weeks) {
      for (final day in week.days) {
        if (!day.restDay) totalWorkDays++;
      }
    }
    if (totalWorkDays == 0) return 0;
    return completedDayKeys.length / totalWorkDays;
  }
}

// ---------------------------------------------------------------------------
// 내장 프로그램 시드 데이터
// ---------------------------------------------------------------------------

// ── 헬퍼: 반복 주 생성 ────────────────────────────────────────────────────

/// PPL 주를 주어진 weekNumber로 생성
ProgramWeek _buildPplWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: 'Push Day A',
        exercises: [
          ProgramExercise(exerciseId: 'chest_001', sets: 4, reps: '6-8', restSeconds: 120), // 바벨 벤치프레스
          ProgramExercise(exerciseId: 'chest_003', sets: 3, reps: '8-12', restSeconds: 90),  // 인클라인 덤벨 프레스
          ProgramExercise(exerciseId: 'shoulder_001', sets: 3, reps: '6-10', restSeconds: 120), // OHP
          ProgramExercise(exerciseId: 'shoulder_002', sets: 3, reps: '12-15', restSeconds: 60), // 레터럴 레이즈
          ProgramExercise(exerciseId: 'triceps_001', sets: 3, reps: '8-10', restSeconds: 90), // 클로즈그립 BP
          ProgramExercise(exerciseId: 'triceps_002', sets: 3, reps: '10-12', restSeconds: 60), // 푸시다운
        ],
      ),
      const ProgramDay(
        dayNumber: 2,
        name: 'Pull Day A',
        exercises: [
          ProgramExercise(exerciseId: 'back_001', sets: 4, reps: '5-6', restSeconds: 180), // 데드리프트
          ProgramExercise(exerciseId: 'back_002', sets: 4, reps: '8-12', restSeconds: 90),  // 랫풀다운
          ProgramExercise(exerciseId: 'back_003', sets: 3, reps: '8-10', restSeconds: 90),  // 바벨 로우
          ProgramExercise(exerciseId: 'back_006', sets: 3, reps: '10-12', restSeconds: 75), // 원암 덤벨 로우
          ProgramExercise(exerciseId: 'biceps_001', sets: 3, reps: '10-12', restSeconds: 60), // 바벨 컬
          ProgramExercise(exerciseId: 'biceps_002', sets: 3, reps: '12-15', restSeconds: 60), // 해머 컬
        ],
      ),
      const ProgramDay(
        dayNumber: 3,
        name: 'Legs Day A',
        exercises: [
          ProgramExercise(exerciseId: 'quad_001', sets: 4, reps: '6-8', restSeconds: 180), // 바벨 스쿼트
          ProgramExercise(exerciseId: 'ham_001', sets: 3, reps: '8-10', restSeconds: 120), // RDL
          ProgramExercise(exerciseId: 'quad_002', sets: 3, reps: '10-12', restSeconds: 90),  // 레그 프레스
          ProgramExercise(exerciseId: 'ham_002', sets: 3, reps: '10-12', restSeconds: 75), // 레그 컬
          ProgramExercise(exerciseId: 'quad_004', sets: 3, reps: '12', restSeconds: 60),    // 런지
          ProgramExercise(exerciseId: 'calf_001', sets: 4, reps: '15-20', restSeconds: 45), // 카프 레이즈
        ],
      ),
      const ProgramDay(dayNumber: 4, name: 'Rest', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: 'Push Day B',
        exercises: [
          ProgramExercise(exerciseId: 'chest_007', sets: 4, reps: '8-10', restSeconds: 90), // 스미스 BP
          ProgramExercise(exerciseId: 'chest_002', sets: 3, reps: '12-15', restSeconds: 75), // 덤벨 플라이
          ProgramExercise(exerciseId: 'shoulder_005', sets: 3, reps: '10-12', restSeconds: 90), // 아놀드 프레스
          ProgramExercise(exerciseId: 'shoulder_004', sets: 3, reps: '12-15', restSeconds: 60), // 페이스 풀
          ProgramExercise(exerciseId: 'triceps_003', sets: 3, reps: '10-12', restSeconds: 75), // OHT 익스텐션
          ProgramExercise(exerciseId: 'triceps_005', sets: 3, reps: '12-15', restSeconds: 60), // 벤치 딥스
        ],
      ),
      const ProgramDay(
        dayNumber: 6,
        name: 'Pull Day B',
        exercises: [
          ProgramExercise(exerciseId: 'back_005', sets: 4, reps: '6-8', restSeconds: 120), // 풀업
          ProgramExercise(exerciseId: 'back_004', sets: 4, reps: '10-12', restSeconds: 90),  // 시티드 케이블 로우
          ProgramExercise(exerciseId: 'back_007', sets: 3, reps: '12-15', restSeconds: 75), // 하이퍼익스텐션
          ProgramExercise(exerciseId: 'shoulder_006', sets: 3, reps: '10-12', restSeconds: 75), // 업라이트 로우
          ProgramExercise(exerciseId: 'biceps_003', sets: 3, reps: '10-12', restSeconds: 60), // 인클라인 컬
          ProgramExercise(exerciseId: 'biceps_005', sets: 3, reps: '12-15', restSeconds: 60), // EZ바 컬
        ],
      ),
      const ProgramDay(dayNumber: 7, name: 'Rest', restDay: true),
    ],
  );
}

/// Upper/Lower 주 생성
ProgramWeek _buildUpperLowerWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: 'Upper A',
        exercises: [
          ProgramExercise(exerciseId: 'chest_001', sets: 3, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'back_002', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_001', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'back_006', sets: 3, reps: '10-12', restSeconds: 75),
          ProgramExercise(exerciseId: 'biceps_001', sets: 2, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'triceps_002', sets: 2, reps: '12-15', restSeconds: 60),
        ],
      ),
      const ProgramDay(
        dayNumber: 2,
        name: 'Lower A',
        exercises: [
          ProgramExercise(exerciseId: 'quad_001', sets: 3, reps: '8-10', restSeconds: 150),
          ProgramExercise(exerciseId: 'ham_001', sets: 3, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'quad_002', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'ham_002', sets: 3, reps: '10-12', restSeconds: 75),
          ProgramExercise(exerciseId: 'calf_001', sets: 3, reps: '15-20', restSeconds: 45),
          ProgramExercise(exerciseId: 'abs_001', sets: 3, reps: '15-20', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 3, name: 'Rest', restDay: true),
      const ProgramDay(
        dayNumber: 4,
        name: 'Upper B',
        exercises: [
          ProgramExercise(exerciseId: 'chest_003', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'back_003', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_002', sets: 3, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'back_005', sets: 3, reps: '6-8', restSeconds: 120),
          ProgramExercise(exerciseId: 'biceps_002', sets: 2, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'triceps_001', sets: 2, reps: '10-12', restSeconds: 75),
        ],
      ),
      const ProgramDay(
        dayNumber: 5,
        name: 'Lower B',
        exercises: [
          ProgramExercise(exerciseId: 'quad_004', sets: 3, reps: '10', restSeconds: 90),
          ProgramExercise(exerciseId: 'ham_003', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'quad_003', sets: 3, reps: '12-15', restSeconds: 75),
          ProgramExercise(exerciseId: 'quad_005', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'calf_002', sets: 3, reps: '15-20', restSeconds: 45),
          ProgramExercise(exerciseId: 'abs_002', sets: 3, reps: '30-60 sec', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: 'Rest', restDay: true),
      const ProgramDay(dayNumber: 7, name: 'Rest', restDay: true),
    ],
  );
}

/// Full Body 주 생성
ProgramWeek _buildFullBodyWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: 'Full Body A',
        exercises: [
          ProgramExercise(exerciseId: 'quad_001', sets: 3, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'chest_001', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'back_002', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_001', sets: 2, reps: '8-10', restSeconds: 75),
          ProgramExercise(exerciseId: 'biceps_001', sets: 2, reps: '10-12', restSeconds: 60),
          ProgramExercise(exerciseId: 'abs_001', sets: 3, reps: '15', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: 'Rest', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: 'Full Body B',
        exercises: [
          ProgramExercise(exerciseId: 'ham_001', sets: 3, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'back_003', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'chest_003', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_002', sets: 2, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'triceps_002', sets: 2, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'abs_002', sets: 3, reps: '30-45 sec', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: 'Rest', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: 'Full Body C',
        exercises: [
          ProgramExercise(exerciseId: 'quad_002', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'chest_006', sets: 3, reps: '10-15', restSeconds: 75),
          ProgramExercise(exerciseId: 'back_005', sets: 3, reps: '6-8', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_005', sets: 2, reps: '10-12', restSeconds: 75),
          ProgramExercise(exerciseId: 'biceps_002', sets: 2, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'abs_003', sets: 3, reps: '12-15', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: 'Rest', restDay: true),
      const ProgramDay(dayNumber: 7, name: 'Rest', restDay: true),
    ],
  );
}

/// 5/3/1 Wendler 주 생성 (4주 사이클)
/// week 1=5s week, 2=3s week, 3=5/3/1 week, 4=deload week
ProgramWeek _buildWendlerWeek(int weekNumber) {
  // 각 주차별 rep 스킴
  final repSchemes = {
    1: '5',     // 5s week: 65%×5, 75%×5, 85%×5+
    2: '3',     // 3s week: 70%×3, 80%×3, 90%×3+
    3: '5/3/1', // 5/3/1 week: 75%×5, 85%×3, 95%×1+
    4: '5',     // Deload: 40%×5, 50%×5, 60%×5
  };
  final scheme = repSchemes[weekNumber] ?? '5';

  // 분할: 월=OHP, 수=데드, 금=BP, 토=스쿼트
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      ProgramDay(
        dayNumber: 1,
        name: 'OHP Day ($scheme)',
        exercises: [
          ProgramExercise(exerciseId: 'shoulder_001', sets: 3, reps: scheme, restSeconds: 180, notes: 'Main lift'),
          ProgramExercise(exerciseId: 'chest_006', sets: 5, reps: '10', restSeconds: 60, notes: 'Assistance'),
          ProgramExercise(exerciseId: 'back_002', sets: 5, reps: '10', restSeconds: 60, notes: 'Assistance'),
          ProgramExercise(exerciseId: 'abs_002', sets: 3, reps: '30-60 sec', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: 'Rest', restDay: true),
      ProgramDay(
        dayNumber: 3,
        name: 'Deadlift Day ($scheme)',
        exercises: [
          ProgramExercise(exerciseId: 'back_001', sets: 3, reps: scheme, restSeconds: 240, notes: 'Main lift'),
          ProgramExercise(exerciseId: 'quad_004', sets: 5, reps: '10', restSeconds: 60, notes: 'Assistance'),
          ProgramExercise(exerciseId: 'abs_001', sets: 5, reps: '10', restSeconds: 45, notes: 'Assistance'),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: 'Rest', restDay: true),
      ProgramDay(
        dayNumber: 5,
        name: 'Bench Day ($scheme)',
        exercises: [
          ProgramExercise(exerciseId: 'chest_001', sets: 3, reps: scheme, restSeconds: 180, notes: 'Main lift'),
          ProgramExercise(exerciseId: 'back_002', sets: 5, reps: '10', restSeconds: 60, notes: 'Assistance'),
          ProgramExercise(exerciseId: 'triceps_002', sets: 5, reps: '10', restSeconds: 60, notes: 'Assistance'),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: 'Rest', restDay: true),
      ProgramDay(
        dayNumber: 7,
        name: 'Squat Day ($scheme)',
        exercises: [
          ProgramExercise(exerciseId: 'quad_001', sets: 3, reps: scheme, restSeconds: 240, notes: 'Main lift'),
          ProgramExercise(exerciseId: 'ham_001', sets: 5, reps: '10', restSeconds: 75, notes: 'Assistance'),
          ProgramExercise(exerciseId: 'abs_002', sets: 5, reps: '30 sec', restSeconds: 30, notes: 'Assistance'),
        ],
      ),
    ],
  );
}

/// Bro Split 주 생성 (5-day)
ProgramWeek _buildBroSplitWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: 'Chest Day',
        exercises: [
          ProgramExercise(exerciseId: 'chest_001', sets: 4, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'chest_003', sets: 4, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'chest_004', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'chest_002', sets: 3, reps: '12-15', restSeconds: 75),
          ProgramExercise(exerciseId: 'chest_005', sets: 3, reps: '12-15', restSeconds: 60),
        ],
      ),
      const ProgramDay(
        dayNumber: 2,
        name: 'Back Day',
        exercises: [
          ProgramExercise(exerciseId: 'back_001', sets: 4, reps: '5-6', restSeconds: 180),
          ProgramExercise(exerciseId: 'back_005', sets: 4, reps: '6-8', restSeconds: 120),
          ProgramExercise(exerciseId: 'back_002', sets: 4, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'back_003', sets: 3, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'back_004', sets: 3, reps: '10-12', restSeconds: 75),
        ],
      ),
      const ProgramDay(
        dayNumber: 3,
        name: 'Shoulders Day',
        exercises: [
          ProgramExercise(exerciseId: 'shoulder_001', sets: 4, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'shoulder_002', sets: 4, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'shoulder_003', sets: 3, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'shoulder_005', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'shoulder_004', sets: 3, reps: '12-15', restSeconds: 60),
        ],
      ),
      const ProgramDay(
        dayNumber: 4,
        name: 'Arms Day',
        exercises: [
          ProgramExercise(exerciseId: 'biceps_001', sets: 4, reps: '10-12', restSeconds: 75),
          ProgramExercise(exerciseId: 'triceps_001', sets: 4, reps: '8-10', restSeconds: 90),
          ProgramExercise(exerciseId: 'biceps_002', sets: 3, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'triceps_002', sets: 3, reps: '12-15', restSeconds: 60),
          ProgramExercise(exerciseId: 'biceps_005', sets: 3, reps: '10-12', restSeconds: 60),
          ProgramExercise(exerciseId: 'triceps_003', sets: 3, reps: '10-12', restSeconds: 60),
        ],
      ),
      const ProgramDay(
        dayNumber: 5,
        name: 'Legs Day',
        exercises: [
          ProgramExercise(exerciseId: 'quad_001', sets: 4, reps: '8-10', restSeconds: 150),
          ProgramExercise(exerciseId: 'ham_001', sets: 4, reps: '8-10', restSeconds: 120),
          ProgramExercise(exerciseId: 'quad_002', sets: 3, reps: '10-12', restSeconds: 90),
          ProgramExercise(exerciseId: 'ham_002', sets: 3, reps: '10-12', restSeconds: 75),
          ProgramExercise(exerciseId: 'calf_001', sets: 4, reps: '15-20', restSeconds: 45),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: 'Rest', restDay: true),
      const ProgramDay(dayNumber: 7, name: 'Rest', restDay: true),
    ],
  );
}

// ── 내장 프로그램 목록 ─────────────────────────────────────────────────────

final List<WorkoutProgram> kBuiltInPrograms = [
  // 1. PPL (6-day, 8 weeks, intermediate)
  WorkoutProgram(
    id: 'prog_ppl_8wk',
    name: 'PPL 8주 프로그램', // TODO: l10n
    description: '밀기(Push)/당기기(Pull)/하체(Legs) 3분할로 주 6일 훈련. '
        '근육 성장과 근력 향상에 최적화된 중급자 프로그램.', // TODO: l10n
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 8,
    daysPerWeek: 6,
    splitType: 'PPL',
    tags: ['근비대', '중급', '6일분할'],
    weeks: List.generate(8, (i) => _buildPplWeek(i + 1)),
  ),

  // 2. Upper/Lower (4-day, 8 weeks, beginner-intermediate)
  WorkoutProgram(
    id: 'prog_ul_8wk',
    name: '상하체 분할 8주', // TODO: l10n
    description: '상체/하체 2분할로 주 4일 훈련. '
        '초급자부터 중급자까지 적합한 균형 잡힌 프로그램.', // TODO: l10n
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 8,
    daysPerWeek: 4,
    splitType: 'Upper/Lower',
    tags: ['균형', '초중급', '4일분할'],
    weeks: List.generate(8, (i) => _buildUpperLowerWeek(i + 1)),
  ),

  // 3. Full Body 3x (3-day, 6 weeks, beginner)
  WorkoutProgram(
    id: 'prog_fullbody_6wk',
    name: '전신 운동 6주', // TODO: l10n
    description: '주 3일 전신 운동으로 기초 체력과 근력을 기르는 초급자 프로그램. '
        '각 운동일에 전신의 주요 근군을 모두 자극.', // TODO: l10n
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 6,
    daysPerWeek: 3,
    splitType: 'Full Body',
    tags: ['초급', '전신', '3일분할'],
    weeks: List.generate(6, (i) => _buildFullBodyWeek(i + 1)),
  ),

  // 4. 5/3/1 Wendler (4-day, 4-week cycle)
  WorkoutProgram(
    id: 'prog_531_4wk',
    name: '5/3/1 웬들러', // TODO: l10n
    description: 'Jim Wendler의 5/3/1 프로그램. '
        '4대 리프트(스쿼트/데드/벤치/OHP) 중심의 근력 향상 프로그램. '
        '4주 사이클 반복.', // TODO: l10n
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 4,
    daysPerWeek: 4,
    splitType: '4 Split',
    tags: ['근력', '중급', '파워리프팅'],
    weeks: List.generate(4, (i) => _buildWendlerWeek(i + 1)),
  ),

  // 5. Bro Split (5-day, 8 weeks, intermediate)
  WorkoutProgram(
    id: 'prog_bro_8wk',
    name: '브로 스플릿 8주', // TODO: l10n
    description: '가슴/등/어깨/팔/하체 5분할로 주 5일 훈련. '
        '각 부위에 집중 자극을 주는 전통적인 보디빌딩 프로그램.', // TODO: l10n
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 8,
    daysPerWeek: 5,
    splitType: 'Bro Split',
    tags: ['보디빌딩', '중급', '5일분할'],
    weeks: List.generate(8, (i) => _buildBroSplitWeek(i + 1)),
  ),
];

// ---------------------------------------------------------------------------
// ActiveProgramNotifier - 활성 프로그램 상태 관리
// ---------------------------------------------------------------------------

class ActiveProgramNotifier extends StateNotifier<ActiveProgram?> {
  ActiveProgramNotifier() : super(null) {
    _load();
  }

  // ── 영속성 ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_ProgramKeys.activeProgram);
      if (json == null) return;
      final map = jsonDecode(json) as Map<String, dynamic>;
      state = ActiveProgram.fromJson(map);
    } catch (_) {
      // 로드 실패 시 null 유지
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state == null) {
        await prefs.remove(_ProgramKeys.activeProgram);
      } else {
        await prefs.setString(
          _ProgramKeys.activeProgram,
          jsonEncode(state!.toJson()),
        );
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }

  // ── 프로그램 제어 ─────────────────────────────────────────────────────────

  /// 프로그램 시작
  Future<void> startProgram(String programId) async {
    state = ActiveProgram(
      programId: programId,
      startDate: DateTime.now(),
      currentWeek: 1,
      currentDay: 1,
    );
    await _save();
  }

  /// 현재 날 완료 처리 및 다음 날로 진행
  Future<void> completeDay(WorkoutProgram program) async {
    final current = state;
    if (current == null) return;

    final week = program.weeks.firstWhere(
      (w) => w.weekNumber == current.currentWeek,
      orElse: () => program.weeks.first,
    );

    // 완료된 날 키 추가
    final dayKey = 'week${current.currentWeek}_day${current.currentDay}';
    final updatedKeys = [...current.completedDayKeys, dayKey];

    // 다음 날 계산 (휴식일 건너뜀)
    int nextDay = current.currentDay + 1;
    int nextWeek = current.currentWeek;

    // 현재 주의 모든 날을 소화했으면 다음 주로
    if (nextDay > week.days.length) {
      nextDay = 1;
      nextWeek = current.currentWeek + 1;
      // 전체 프로그램 완료 시 리셋
      if (nextWeek > program.durationWeeks) {
        state = current.copyWith(completedDayKeys: updatedKeys);
        await _save();
        return;
      }
    }

    state = current.copyWith(
      currentWeek: nextWeek,
      currentDay: nextDay,
      completedDayKeys: updatedKeys,
    );
    await _save();
  }

  /// 현재 날 스킵 (다음 날로 이동)
  Future<void> skipDay(WorkoutProgram program) async {
    final current = state;
    if (current == null) return;

    final week = program.weeks.firstWhere(
      (w) => w.weekNumber == current.currentWeek,
      orElse: () => program.weeks.first,
    );

    int nextDay = current.currentDay + 1;
    int nextWeek = current.currentWeek;

    if (nextDay > week.days.length) {
      nextDay = 1;
      nextWeek = current.currentWeek + 1;
      if (nextWeek > program.durationWeeks) return;
    }

    state = current.copyWith(
      currentWeek: nextWeek,
      currentDay: nextDay,
    );
    await _save();
  }

  /// 프로그램 포기
  Future<void> abandonProgram() async {
    state = null;
    await _save();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 전체 프로그램 목록 Provider
final programsProvider = Provider<List<WorkoutProgram>>((ref) {
  return kBuiltInPrograms;
});

/// 활성 프로그램 Provider
final activeProgramProvider =
    StateNotifierProvider<ActiveProgramNotifier, ActiveProgram?>(
  (ref) => ActiveProgramNotifier(),
);

/// 현재 활성 프로그램의 WorkoutProgram 객체 Provider
final activeProgramDetailProvider = Provider<WorkoutProgram?>((ref) {
  final active = ref.watch(activeProgramProvider);
  if (active == null) return null;
  try {
    return kBuiltInPrograms.firstWhere((p) => p.id == active.programId);
  } catch (_) {
    return null;
  }
});

/// 현재 진행해야 할 ProgramDay Provider
final currentProgramDayProvider = Provider<ProgramDay?>((ref) {
  final active = ref.watch(activeProgramProvider);
  final program = ref.watch(activeProgramDetailProvider);
  if (active == null || program == null) return null;

  try {
    final week = program.weeks.firstWhere(
      (w) => w.weekNumber == active.currentWeek,
    );
    return week.days.firstWhere(
      (d) => d.dayNumber == active.currentDay,
    );
  } catch (_) {
    return null;
  }
});
