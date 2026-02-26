// 특수 운동 프로그램 (임산부 / 시니어 / 재활)
// WorkoutProgram 모델 재사용, 안전 중심의 운동 구성

import 'package:health_app/features/workout_guide/providers/programs_provider.dart';
import 'package:health_app/core/models/workout_model.dart';

// ---------------------------------------------------------------------------
// 임산부 프로그램 헬퍼 (트라이메스터별)
// ---------------------------------------------------------------------------

/// 임산부 1분기 주 (1-12주) – 가벼운 유산소 + 수정 코어 + 유연성
ProgramWeek _buildPregnancyT1Week(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: '가벼운 유산소',
        exercises: [
          // 걷기 (유산소): 저강도 지속 운동
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '20분', restSeconds: 60, notes: '빠른 걷기, 숨이 차지 않을 정도'),
          // 어깨 원운동
          ProgramExercise(exerciseId: 'shoulder_002', sets: 2, reps: '15', restSeconds: 60, notes: '가벼운 중량만'),
          // 스탠딩 카프 레이즈
          ProgramExercise(exerciseId: 'calf_001', sets: 2, reps: '15', restSeconds: 45),
          // 골반 기울기 (코어 안전 운동)
          ProgramExercise(exerciseId: 'abs_pelvic_tilt', sets: 2, reps: '10', restSeconds: 45, notes: '무릎 굽히고 서서 실시'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: '수정 근력',
        exercises: [
          // 스쿼트 (수정버전 – 의자 보조)
          ProgramExercise(exerciseId: 'quad_001', sets: 2, reps: '12', restSeconds: 90, notes: '의자를 뒤에 두고 실시, 깊게 내려가지 않기'),
          // 월 푸시업
          ProgramExercise(exerciseId: 'chest_006', sets: 2, reps: '12', restSeconds: 60, notes: '벽에 기대어 실시'),
          // 시티드 로우 (밴드)
          ProgramExercise(exerciseId: 'back_004', sets: 2, reps: '12', restSeconds: 60, notes: '저항 밴드 사용'),
          // 클램쉘 (고관절 강화)
          ProgramExercise(exerciseId: 'glute_clam', sets: 2, reps: '15', restSeconds: 45, notes: '옆으로 누운 자세'),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: '유연성 & 코어',
        exercises: [
          // 캣-카우 스트레치
          ProgramExercise(exerciseId: 'stretch_cat_cow', sets: 2, reps: '10', restSeconds: 30, notes: '천천히, 호흡과 함께'),
          // 수정 버드독
          ProgramExercise(exerciseId: 'abs_bird_dog', sets: 2, reps: '10', restSeconds: 45, notes: '네발 기기 자세'),
          // 힙 힌지 스트레치
          ProgramExercise(exerciseId: 'stretch_hip', sets: 2, reps: '30sec', restSeconds: 30),
          // 어깨 스트레치
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

/// 임산부 2분기 주 (13-27주) – 저충격 근력 + 안정성
ProgramWeek _buildPregnancyT2Week(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: '저충격 근력 A',
        exercises: [
          // 수정 스쿼트
          ProgramExercise(exerciseId: 'quad_001', sets: 3, reps: '10', restSeconds: 90, notes: '발판 또는 의자 보조, 얕게 실시'),
          // 인클라인 덤벨 프레스 (누운 자세 대신 앉아서)
          ProgramExercise(exerciseId: 'chest_003', sets: 2, reps: '12', restSeconds: 90, notes: '45도 인클라인 벤치, 낮은 중량'),
          // 시티드 로우
          ProgramExercise(exerciseId: 'back_004', sets: 3, reps: '12', restSeconds: 75),
          // 사이드 레그 레이즈
          ProgramExercise(exerciseId: 'glute_side_leg', sets: 2, reps: '15', restSeconds: 45, notes: '옆으로 서서 실시'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: '안정성 트레이닝',
        exercises: [
          // 수정 플랭크 (서서)
          ProgramExercise(exerciseId: 'abs_standing_plank', sets: 2, reps: '20sec', restSeconds: 60, notes: '벽에 기대 앞으로 기울기'),
          // 단일 레그 데드리프트 (경량)
          ProgramExercise(exerciseId: 'ham_001', sets: 2, reps: '10', restSeconds: 90, notes: '극도로 가볍게, 균형 위주'),
          // 밴드 힙 어브덕션
          ProgramExercise(exerciseId: 'glute_band_abduct', sets: 2, reps: '15', restSeconds: 45),
          // 시티드 카프 레이즈
          ProgramExercise(exerciseId: 'calf_002', sets: 2, reps: '15', restSeconds: 45, notes: '앉아서 실시'),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: '저충격 유산소 & 스트레칭',
        exercises: [
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '25분', restSeconds: 60, notes: '편안한 속도'),
          ProgramExercise(exerciseId: 'stretch_cat_cow', sets: 2, reps: '10', restSeconds: 30),
          ProgramExercise(exerciseId: 'stretch_hip', sets: 2, reps: '30sec', restSeconds: 30),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

/// 임산부 3분기 주 (28-40주) – 부드러운 움직임 + 호흡 + 골반 기저근
ProgramWeek _buildPregnancyT3Week(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: '부드러운 이동성',
        exercises: [
          ProgramExercise(exerciseId: 'stretch_cat_cow', sets: 2, reps: '10', restSeconds: 30, notes: '4발 자세, 천천히'),
          ProgramExercise(exerciseId: 'stretch_hip', sets: 3, reps: '30sec', restSeconds: 30, notes: '고관절 스트레칭'),
          ProgramExercise(exerciseId: 'abs_pelvic_tilt', sets: 3, reps: '10', restSeconds: 45, notes: '골반 기울기'),
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '15분', restSeconds: 60, notes: '편안한 속도'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: '호흡 & 골반 기저근',
        exercises: [
          ProgramExercise(exerciseId: 'breath_deep', sets: 3, reps: '10', restSeconds: 30, notes: '횡격막 호흡 연습'),
          ProgramExercise(exerciseId: 'pelvic_floor', sets: 3, reps: '10', restSeconds: 45, notes: '케겔 운동'),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 2, reps: '30sec', restSeconds: 30),
          ProgramExercise(exerciseId: 'stretch_cat_cow', sets: 2, reps: '8', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 5, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

// ---------------------------------------------------------------------------
// 시니어 프로그램 헬퍼 (60+)
// ---------------------------------------------------------------------------

/// 시니어 균형 & 이동성 주
ProgramWeek _buildSeniorBalanceWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: '의자 운동',
        exercises: [
          ProgramExercise(exerciseId: 'senior_chair_squat', sets: 2, reps: '10', restSeconds: 90, notes: '의자에 앉았다 일어서기'),
          ProgramExercise(exerciseId: 'senior_seated_march', sets: 2, reps: '20', restSeconds: 60, notes: '앉아서 무릎 들기'),
          ProgramExercise(exerciseId: 'senior_seated_row', sets: 2, reps: '12', restSeconds: 75, notes: '밴드 사용'),
          ProgramExercise(exerciseId: 'senior_ankle_roll', sets: 2, reps: '10', restSeconds: 30, notes: '발목 원운동'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: '서서 균형',
        exercises: [
          ProgramExercise(exerciseId: 'senior_stand_balance', sets: 3, reps: '30sec', restSeconds: 60, notes: '한 발로 서기 (벽 보조 허용)'),
          ProgramExercise(exerciseId: 'senior_heel_toe_walk', sets: 2, reps: '10m', restSeconds: 60, notes: '발뒤꿈치-발끝 걷기'),
          ProgramExercise(exerciseId: 'calf_001', sets: 2, reps: '15', restSeconds: 60, notes: '의자 잡고 실시'),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: '걷기 & 유연성',
        exercises: [
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '20분', restSeconds: 60, notes: '편안한 속도, 평지 선호'),
          ProgramExercise(exerciseId: 'stretch_hip', sets: 2, reps: '30sec', restSeconds: 30),
          ProgramExercise(exerciseId: 'stretch_cat_cow', sets: 2, reps: '8', restSeconds: 30),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

/// 시니어 근력 강화 주
ProgramWeek _buildSeniorStrengthWeek(int weekNumber) {
  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      const ProgramDay(
        dayNumber: 1,
        name: '상체 강화',
        exercises: [
          ProgramExercise(exerciseId: 'chest_006', sets: 2, reps: '12', restSeconds: 90, notes: '벽 또는 낮은 인클라인에서 푸시업'),
          ProgramExercise(exerciseId: 'back_004', sets: 2, reps: '12', restSeconds: 90, notes: '밴드 로우'),
          ProgramExercise(exerciseId: 'shoulder_002', sets: 2, reps: '12', restSeconds: 75, notes: '아주 가벼운 중량'),
          ProgramExercise(exerciseId: 'biceps_001', sets: 2, reps: '12', restSeconds: 60, notes: '가벼운 밴드 또는 덤벨'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 3,
        name: '하체 강화',
        exercises: [
          ProgramExercise(exerciseId: 'senior_chair_squat', sets: 3, reps: '10', restSeconds: 120, notes: '천천히, 의자에서 일어서기'),
          ProgramExercise(exerciseId: 'calf_001', sets: 2, reps: '15', restSeconds: 75, notes: '의자 잡고 실시'),
          ProgramExercise(exerciseId: 'senior_hip_ext', sets: 2, reps: '12', restSeconds: 75, notes: '의자 잡고 뒤로 다리 올리기'),
          ProgramExercise(exerciseId: 'senior_seated_march', sets: 2, reps: '20', restSeconds: 60),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      const ProgramDay(
        dayNumber: 5,
        name: '유산소 & 코어',
        exercises: [
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '25분', restSeconds: 60),
          ProgramExercise(exerciseId: 'senior_stand_balance', sets: 3, reps: '30sec', restSeconds: 60),
          ProgramExercise(exerciseId: 'abs_pelvic_tilt', sets: 2, reps: '10', restSeconds: 60, notes: '서서 실시'),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

// ---------------------------------------------------------------------------
// 재활 프로그램 헬퍼
// ---------------------------------------------------------------------------

/// 어깨 재활 주
ProgramWeek _buildShoulderRehabWeek(int weekNumber) {
  // 주차별 강도 조절
  final restSeconds = weekNumber <= 2 ? 120 : 90;
  final reps = weekNumber <= 2 ? '10' : '12';

  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      ProgramDay(
        dayNumber: 1,
        name: '회전근개 강화',
        exercises: [
          ProgramExercise(exerciseId: 'rehab_shoulder_ext_rotation', sets: 3, reps: reps, restSeconds: restSeconds, notes: '밴드 외회전, 팔꿈치 90도 고정'),
          ProgramExercise(exerciseId: 'rehab_shoulder_int_rotation', sets: 3, reps: reps, restSeconds: restSeconds, notes: '밴드 내회전'),
          ProgramExercise(exerciseId: 'shoulder_004', sets: 3, reps: reps, restSeconds: restSeconds, notes: '페이스 풀 – 경량'),
          ProgramExercise(exerciseId: 'rehab_shoulder_press_low', sets: 2, reps: '10', restSeconds: restSeconds, notes: '매우 낮은 중량 프레스'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 3,
        name: '견갑 안정화',
        exercises: [
          ProgramExercise(exerciseId: 'rehab_scapular_retract', sets: 3, reps: reps, restSeconds: restSeconds, notes: '견갑골 모아주기'),
          ProgramExercise(exerciseId: 'back_004', sets: 3, reps: reps, restSeconds: restSeconds, notes: '케이블 로우 – 경량'),
          ProgramExercise(exerciseId: 'rehab_shoulder_pendulum', sets: 2, reps: '30sec', restSeconds: 90, notes: '어깨 진자 운동'),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 3, reps: '30sec', restSeconds: 30, notes: '어깨 스트레칭'),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 5,
        name: '저강도 움직임',
        exercises: [
          ProgramExercise(exerciseId: 'rehab_shoulder_ext_rotation', sets: 2, reps: reps, restSeconds: 90),
          ProgramExercise(exerciseId: 'rehab_scapular_retract', sets: 2, reps: reps, restSeconds: 90),
          ProgramExercise(exerciseId: 'stretch_shoulder', sets: 3, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

/// 무릎 재활 주
ProgramWeek _buildKneeRehabWeek(int weekNumber) {
  final reps = weekNumber <= 2 ? '10' : '12';
  final restSeconds = weekNumber <= 2 ? 120 : 90;

  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      ProgramDay(
        dayNumber: 1,
        name: '대퇴사두근 강화',
        exercises: [
          ProgramExercise(exerciseId: 'rehab_quad_sets', sets: 3, reps: reps, restSeconds: restSeconds, notes: '누워서 무릎 펴기 (수건 아래)'),
          ProgramExercise(exerciseId: 'rehab_straight_leg_raise', sets: 3, reps: reps, restSeconds: restSeconds, notes: '직선 다리 들기'),
          ProgramExercise(exerciseId: 'senior_chair_squat', sets: 2, reps: '8', restSeconds: 120, notes: '짧은 범위만, 통증 없는 범위'),
          ProgramExercise(exerciseId: 'calf_001', sets: 2, reps: '15', restSeconds: 60, notes: '의자 잡고'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 3,
        name: '슬굴근 유연성',
        exercises: [
          ProgramExercise(exerciseId: 'rehab_hamstring_stretch', sets: 3, reps: '30sec', restSeconds: 30, notes: '누워서 다리 들기 스트레칭'),
          ProgramExercise(exerciseId: 'ham_002', sets: 2, reps: reps, restSeconds: restSeconds, notes: '라잉 레그 컬 – 매우 가볍게'),
          ProgramExercise(exerciseId: 'rehab_quad_sets', sets: 2, reps: '10', restSeconds: 90),
          ProgramExercise(exerciseId: 'stretch_hip', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 5,
        name: '기능적 움직임',
        exercises: [
          ProgramExercise(exerciseId: 'senior_chair_squat', sets: 3, reps: reps, restSeconds: 90),
          ProgramExercise(exerciseId: 'calf_001', sets: 2, reps: '15', restSeconds: 60),
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '15분', restSeconds: 60, notes: '통증 없는 속도'),
          ProgramExercise(exerciseId: 'rehab_hamstring_stretch', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

/// 허리 재활 주
ProgramWeek _buildBackRehabWeek(int weekNumber) {
  final reps = weekNumber <= 2 ? '8' : '10';
  final restSeconds = weekNumber <= 2 ? 120 : 90;

  return ProgramWeek(
    weekNumber: weekNumber,
    days: [
      ProgramDay(
        dayNumber: 1,
        name: '코어 안정화',
        exercises: [
          ProgramExercise(exerciseId: 'abs_bird_dog', sets: 3, reps: reps, restSeconds: restSeconds, notes: '버드독 – 천천히'),
          ProgramExercise(exerciseId: 'abs_dead_bug', sets: 3, reps: reps, restSeconds: restSeconds, notes: '데드버그'),
          ProgramExercise(exerciseId: 'abs_pelvic_tilt', sets: 2, reps: '10', restSeconds: 60, notes: '골반 기울기'),
          ProgramExercise(exerciseId: 'rehab_cat_camel', sets: 2, reps: '10', restSeconds: 45, notes: '캣-카멜'),
        ],
      ),
      const ProgramDay(dayNumber: 2, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 3,
        name: '허리 & 고관절 스트레칭',
        exercises: [
          ProgramExercise(exerciseId: 'stretch_hip', sets: 3, reps: '30sec', restSeconds: 30, notes: '고관절 굴곡근 스트레칭'),
          ProgramExercise(exerciseId: 'rehab_child_pose', sets: 3, reps: '30sec', restSeconds: 30, notes: '차일드 포즈'),
          ProgramExercise(exerciseId: 'rehab_piriformis_stretch', sets: 2, reps: '30sec', restSeconds: 30, notes: '이상근 스트레칭'),
          ProgramExercise(exerciseId: 'abs_bird_dog', sets: 2, reps: '8', restSeconds: 90),
        ],
      ),
      const ProgramDay(dayNumber: 4, name: '휴식', restDay: true),
      ProgramDay(
        dayNumber: 5,
        name: '기능적 움직임',
        exercises: [
          ProgramExercise(exerciseId: 'cardio_walk', sets: 1, reps: '15분', restSeconds: 60, notes: '통증 없는 속도'),
          ProgramExercise(exerciseId: 'abs_bird_dog', sets: 2, reps: reps, restSeconds: 90),
          ProgramExercise(exerciseId: 'stretch_hip', sets: 2, reps: '30sec', restSeconds: 30),
          ProgramExercise(exerciseId: 'rehab_child_pose', sets: 2, reps: '30sec', restSeconds: 30),
        ],
      ),
      const ProgramDay(dayNumber: 6, name: '휴식', restDay: true),
      const ProgramDay(dayNumber: 7, name: '휴식', restDay: true),
    ],
  );
}

// ---------------------------------------------------------------------------
// 특수 프로그램 목록
// ---------------------------------------------------------------------------

final List<WorkoutProgram> kSpecialPrograms = [
  // ── 임산부 프로그램 ─────────────────────────────────────────────────────

  // 1분기 (4주)
  WorkoutProgram(
    id: 'prog_pregnancy_t1',
    name: '임산부 1분기 운동 (1-12주)',
    description: '임신 초기를 위한 안전한 운동 프로그램.\n'
        '가벼운 유산소, 수정 코어 운동, 유연성 훈련으로 구성.\n'
        '주 3회 운동.\n\n'
        '주의: 의사와 상담 후 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 3,
    splitType: '임산부',
    tags: ['임산부', '1분기', '안전', '저강도'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildPregnancyT1Week(i + 1)),
  ),

  // 2분기 (6주)
  WorkoutProgram(
    id: 'prog_pregnancy_t2',
    name: '임산부 2분기 운동 (13-27주)',
    description: '임신 중기를 위한 저충격 근력 + 안정성 프로그램.\n'
        '바로 누운 자세 운동 제외, 앉거나 선 자세 위주.\n'
        '주 3회 운동.\n\n'
        '주의: 의사와 상담 후 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 6,
    daysPerWeek: 3,
    splitType: '임산부',
    tags: ['임산부', '2분기', '안전', '저충격'],
    isPremium: false,
    weeks: List.generate(6, (i) => _buildPregnancyT2Week(i + 1)),
  ),

  // 3분기 (4주)
  WorkoutProgram(
    id: 'prog_pregnancy_t3',
    name: '임산부 3분기 운동 (28-40주)',
    description: '임신 후기를 위한 부드러운 이동성 + 출산 준비 프로그램.\n'
        '호흡 운동, 골반 기저근 강화(케겔), 부드러운 스트레칭.\n'
        '주 2회 운동.\n\n'
        '주의: 의사와 상담 후 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 2,
    splitType: '임산부',
    tags: ['임산부', '3분기', '안전', '출산준비'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildPregnancyT3Week(i + 1)),
  ),

  // ── 시니어 프로그램 (60+) ─────────────────────────────────────────────

  // 균형 & 이동성 (4주)
  WorkoutProgram(
    id: 'prog_senior_balance',
    name: '시니어 균형 & 이동성 (4주)',
    description: '60세 이상을 위한 균형감각과 이동성 향상 프로그램.\n'
        '의자 운동, 서서 균형 훈련, 걷기로 구성.\n'
        '주 3회 운동, 충분한 휴식.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 3,
    splitType: '시니어',
    tags: ['시니어', '균형', '이동성', '저충격'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildSeniorBalanceWeek(i + 1)),
  ),

  // 근력 강화 (6주)
  WorkoutProgram(
    id: 'prog_senior_strength',
    name: '시니어 근력 강화 (6주)',
    description: '60세 이상을 위한 안전한 근력 강화 프로그램.\n'
        '가벼운 저항 밴드와 기계 위주, 앉아서 가능한 운동 포함.\n'
        '긴 휴식 시간과 낮은 강도.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 6,
    daysPerWeek: 3,
    splitType: '시니어',
    tags: ['시니어', '근력', '저충격', '기계운동'],
    isPremium: false,
    weeks: List.generate(6, (i) => _buildSeniorStrengthWeek(i + 1)),
  ),

  // ── 재활 프로그램 ─────────────────────────────────────────────────────

  // 어깨 재활 (4주)
  WorkoutProgram(
    id: 'prog_rehab_shoulder',
    name: '어깨 재활 프로그램 (4주)',
    description: '회전근개 손상 또는 어깨 불편함을 위한 재활 프로그램.\n'
        '회전근개 강화, 견갑 안정화, 가동성 운동.\n'
        '저항 밴드 위주, 통증 없는 범위에서만 실시.\n\n'
        '주의: 의사 또는 물리치료사 지도 하에 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 3,
    splitType: '재활',
    tags: ['재활', '어깨', '저강도', '밴드운동'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildShoulderRehabWeek(i + 1)),
  ),

  // 무릎 재활 (4주)
  WorkoutProgram(
    id: 'prog_rehab_knee',
    name: '무릎 재활 프로그램 (4주)',
    description: '무릎 부상 또는 통증 회복을 위한 재활 프로그램.\n'
        '대퇴사두근 강화, 슬굴근 유연성, 기능적 움직임 회복.\n'
        '통증 없는 범위에서만 실시, 의자 운동 위주.\n\n'
        '주의: 의사 또는 물리치료사 지도 하에 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 3,
    splitType: '재활',
    tags: ['재활', '무릎', '저강도', '기능회복'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildKneeRehabWeek(i + 1)),
  ),

  // 허리 재활 (4주)
  WorkoutProgram(
    id: 'prog_rehab_back',
    name: '허리 재활 프로그램 (4주)',
    description: '허리 통증 또는 요추 부상 회복을 위한 재활 프로그램.\n'
        '코어 안정화, 허리 & 고관절 스트레칭, 자세 교정.\n'
        '버드독, 데드버그, 캣-카멜 등 안전한 운동 위주.\n\n'
        '주의: 의사 또는 물리치료사 지도 하에 진행하세요.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 4,
    daysPerWeek: 3,
    splitType: '재활',
    tags: ['재활', '허리', '코어', '자세교정'],
    isPremium: false,
    weeks: List.generate(4, (i) => _buildBackRehabWeek(i + 1)),
  ),
];
