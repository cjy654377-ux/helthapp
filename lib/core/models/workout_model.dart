// 운동 관련 데이터 모델
// Exercise, WorkoutLog, WorkoutPlan 등의 불변 클래스 정의

/// 신체 부위 열거형
enum BodyPart {
  chest('가슴'),
  back('등'),
  shoulders('어깨'),
  biceps('이두'),
  triceps('삼두'),
  forearms('전완'),
  abs('복근'),
  glutes('둔근'),
  quadriceps('대퇴사두'),
  hamstrings('햄스트링'),
  calves('종아리'),
  fullBody('전신'),
  cardio('유산소');

  final String label;
  const BodyPart(this.label);
}

/// 운동 기구 열거형
enum Equipment {
  barbell('바벨'),
  dumbbell('덤벨'),
  machine('머신'),
  cable('케이블'),
  bodyweight('맨몸'),
  resistanceBand('밴드'),
  kettlebell('케틀벨'),
  ezBar('EZ바'),
  smithMachine('스미스머신'),
  none('없음');

  final String label;
  const Equipment(this.label);
}

/// 운동 난이도 열거형
enum DifficultyLevel {
  beginner('초급'),
  intermediate('중급'),
  advanced('고급');

  final String label;
  const DifficultyLevel(this.label);
}

// ---------------------------------------------------------------------------
// Exercise 모델
// ---------------------------------------------------------------------------

/// 개별 운동 동작을 표현하는 불변 클래스
class Exercise {
  final String id;
  final String name; // 운동 이름 (한국어)
  final String nameEn; // 운동 이름 (영어)
  final BodyPart bodyPart; // 주요 자극 부위
  final List<BodyPart> secondaryBodyParts; // 보조 자극 부위
  final Equipment equipment; // 필요 기구
  final DifficultyLevel difficulty; // 난이도
  final List<String> instructions; // 동작 설명 (단계별)
  final String? imageUrl; // 운동 이미지 URL
  final String? videoUrl; // 운동 영상 URL
  final List<String> tips; // 운동 팁
  final bool isCompound; // 복합 운동 여부

  const Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.bodyPart,
    this.secondaryBodyParts = const [],
    required this.equipment,
    required this.difficulty,
    required this.instructions,
    this.imageUrl,
    this.videoUrl,
    this.tips = const [],
    this.isCompound = false,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? nameEn,
    BodyPart? bodyPart,
    List<BodyPart>? secondaryBodyParts,
    Equipment? equipment,
    DifficultyLevel? difficulty,
    List<String>? instructions,
    String? imageUrl,
    String? videoUrl,
    List<String>? tips,
    bool? isCompound,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      bodyPart: bodyPart ?? this.bodyPart,
      secondaryBodyParts: secondaryBodyParts ?? this.secondaryBodyParts,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      tips: tips ?? this.tips,
      isCompound: isCompound ?? this.isCompound,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      bodyPart: BodyPart.values.firstWhere(
        (e) => e.name == json['body_part'],
        orElse: () => BodyPart.fullBody,
      ),
      secondaryBodyParts: (json['secondary_body_parts'] as List<dynamic>? ?? [])
          .map(
            (e) => BodyPart.values.firstWhere(
              (b) => b.name == e,
              orElse: () => BodyPart.fullBody,
            ),
          )
          .toList(),
      equipment: Equipment.values.firstWhere(
        (e) => e.name == json['equipment'],
        orElse: () => Equipment.none,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      tips: List<String>.from(json['tips'] as List? ?? []),
      isCompound: json['is_compound'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'body_part': bodyPart.name,
      'secondary_body_parts': secondaryBodyParts.map((e) => e.name).toList(),
      'equipment': equipment.name,
      'difficulty': difficulty.name,
      'instructions': instructions,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'tips': tips,
      'is_compound': isCompound,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Exercise(id: $id, name: $name)';
}

// ---------------------------------------------------------------------------
// WorkoutSet 모델 - 하나의 운동 세트 기록
// ---------------------------------------------------------------------------

/// 운동 세트 1회 기록
class WorkoutSet {
  final int setNumber; // 세트 번호
  final int reps; // 반복 횟수
  final double weight; // 무게 (kg)
  final int? restSeconds; // 휴식 시간 (초)
  final bool isWarmUp; // 워밍업 세트 여부
  final String? note; // 메모

  const WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.restSeconds,
    this.isWarmUp = false,
    this.note,
  });

  /// 볼륨 (무게 × 횟수)
  double get volume => weight * reps;

  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? restSeconds,
    bool? isWarmUp,
    String? note,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      isWarmUp: isWarmUp ?? this.isWarmUp,
      note: note ?? this.note,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      restSeconds: json['rest_seconds'] as int?,
      isWarmUp: json['is_warm_up'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'is_warm_up': isWarmUp,
      'note': note,
    };
  }

  @override
  String toString() =>
      'WorkoutSet(set: $setNumber, reps: $reps, weight: ${weight}kg)';
}

// ---------------------------------------------------------------------------
// WorkoutExerciseEntry - 운동 기록 내 하나의 운동 항목
// ---------------------------------------------------------------------------

/// 운동 기록 세션 내에서 특정 운동의 세트 모음
class WorkoutExerciseEntry {
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final String? note;

  const WorkoutExerciseEntry({
    required this.exercise,
    required this.sets,
    this.note,
  });

  /// 총 볼륨 (모든 세트의 볼륨 합산)
  double get totalVolume =>
      sets.fold(0, (sum, set) => sum + set.volume);

  /// 유효 세트 수 (워밍업 제외)
  int get effectiveSetCount =>
      sets.where((s) => !s.isWarmUp).length;

  WorkoutExerciseEntry copyWith({
    Exercise? exercise,
    List<WorkoutSet>? sets,
    String? note,
  }) {
    return WorkoutExerciseEntry(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      note: note ?? this.note,
    );
  }

  factory WorkoutExerciseEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseEntry(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets.map((e) => e.toJson()).toList(),
      'note': note,
    };
  }
}

// ---------------------------------------------------------------------------
// WorkoutLog 모델 - 운동 세션 기록
// ---------------------------------------------------------------------------

/// 하나의 운동 세션 전체 기록
class WorkoutLog {
  final String id;
  final DateTime date; // 운동 날짜
  final String? title; // 세션 제목 (예: "가슴 & 삼두")
  final List<WorkoutExerciseEntry> exercises; // 수행한 운동 목록
  final int durationMinutes; // 총 운동 시간 (분)
  final String? note; // 전체 세션 메모
  final String? mood; // 운동 컨디션 (good/normal/bad)
  final double? bodyWeight; // 운동 당일 체중 (kg)

  const WorkoutLog({
    required this.id,
    required this.date,
    this.title,
    required this.exercises,
    required this.durationMinutes,
    this.note,
    this.mood,
    this.bodyWeight,
  });

  /// 세션의 총 볼륨
  double get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  /// 세션의 총 세트 수
  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  WorkoutLog copyWith({
    String? id,
    DateTime? date,
    String? title,
    List<WorkoutExerciseEntry>? exercises,
    int? durationMinutes,
    String? note,
    String? mood,
    double? bodyWeight,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      bodyWeight: bodyWeight ?? this.bodyWeight,
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) =>
              WorkoutExerciseEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      durationMinutes: json['duration_minutes'] as int,
      note: json['note'] as String?,
      mood: json['mood'] as String?,
      bodyWeight: json['body_weight'] != null
          ? (json['body_weight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration_minutes': durationMinutes,
      'note': note,
      'mood': mood,
      'body_weight': bodyWeight,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutLog(id: $id, date: $date, exercises: ${exercises.length})';
}

// ---------------------------------------------------------------------------
// WorkoutPlan 모델 - 캘린더 스케줄 계획
// ---------------------------------------------------------------------------

/// 요일별 운동 계획
class WorkoutPlanDay {
  /// 0=월요일 ~ 6=일요일
  final int weekday;
  final List<String> exerciseIds; // 계획된 운동 ID 목록
  final String? planName; // 계획 이름 (예: "가슴 운동", "하체 운동")
  final String? note;

  const WorkoutPlanDay({
    required this.weekday,
    required this.exerciseIds,
    this.planName,
    this.note,
  });

  WorkoutPlanDay copyWith({
    int? weekday,
    List<String>? exerciseIds,
    String? planName,
    String? note,
  }) {
    return WorkoutPlanDay(
      weekday: weekday ?? this.weekday,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      planName: planName ?? this.planName,
      note: note ?? this.note,
    );
  }

  factory WorkoutPlanDay.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanDay(
      weekday: json['weekday'] as int,
      exerciseIds: List<String>.from(json['exercise_ids'] as List? ?? []),
      planName: json['plan_name'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'exercise_ids': exerciseIds,
      'plan_name': planName,
      'note': note,
    };
  }
}

/// 주간 운동 계획
class WorkoutPlan {
  final String id;
  final String name; // 플랜 이름 (예: "4분할 운동 계획")
  final String? description;
  final List<WorkoutPlanDay> days; // 요일별 계획
  final DateTime startDate; // 시작일
  final DateTime? endDate; // 종료일 (null이면 무기한)
  final bool isActive; // 현재 활성화 여부

  const WorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    required this.days,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  /// 특정 요일의 계획 반환 (없으면 null)
  WorkoutPlanDay? getDayPlan(int weekday) {
    try {
      return days.firstWhere((d) => d.weekday == weekday);
    } catch (_) {
      return null;
    }
  }

  /// 휴식일 여부
  bool isRestDay(int weekday) => getDayPlan(weekday) == null;

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutPlanDay>? days,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      days: (json['days'] as List<dynamic>)
          .map((e) => WorkoutPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'days': days.map((e) => e.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorkoutPlan(id: $id, name: $name)';
}
