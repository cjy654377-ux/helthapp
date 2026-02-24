// 운동 데이터베이스 및 AI 기반 추천 시스템
// 40개 이상의 운동 데이터 (부위별 6-8개)
// AI 추천: 최근 운동 기록 기반 스마트 추천

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// 운동 데이터베이스 시드 데이터 (43개 운동)
// ---------------------------------------------------------------------------

/// 전체 운동 데이터베이스
const List<Exercise> kAllExercises = [
  // ── 가슴 (Chest) - 7개 ────────────────────────────────────────────────────
  Exercise(
    id: 'chest_001',
    name: '바벨 벤치프레스',
    nameEn: 'Barbell Bench Press',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.triceps, BodyPart.shoulders],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '벤치에 누워 어깨너비보다 약간 넓게 바를 잡는다',
      '바를 라랙에서 들어 가슴 위로 가져온다',
      '숨을 들이쉬며 바를 가슴 중앙으로 천천히 내린다',
      '가슴에 닿기 직전 잠시 멈춘다',
      '숨을 내쉬며 바를 힘차게 밀어 올린다',
    ],
    tips: [
      '허리를 자연스럽게 아치형으로 유지',
      '발은 바닥에 단단히 고정',
      '어깨뼈를 뒤로 모아 가슴을 열어준다',
    ],
  ),
  Exercise(
    id: 'chest_002',
    name: '덤벨 플라이',
    nameEn: 'Dumbbell Fly',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.shoulders],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '벤치에 누워 양손에 덤벨을 들고 팔을 펴서 위로 올린다',
      '팔꿈치를 약간 구부린 상태로 유지',
      '숨을 들이쉬며 팔을 좌우로 천천히 내린다',
      '가슴이 완전히 스트레칭될 때까지 내린다',
      '숨을 내쉬며 원위치로 돌아온다',
    ],
    tips: [
      '팔꿈치를 완전히 펴지 않는다 (부상 방지)',
      '무게보다 가동 범위에 집중',
    ],
  ),
  Exercise(
    id: 'chest_003',
    name: '인클라인 덤벨 프레스',
    nameEn: 'Incline Dumbbell Press',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.triceps, BodyPart.shoulders],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '벤치를 30-45도로 세운다',
      '어깨너비로 덤벨을 잡고 가슴 위쪽 높이로 위치',
      '숨을 내쉬며 덤벨을 위로 밀어 올린다',
      '팔을 완전히 펴지 않고 약간 구부린 채로 유지',
      '숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['상부 가슴 발달에 효과적', '벤치 각도는 30도가 최적'],
  ),
  Exercise(
    id: 'chest_004',
    name: '딥스 (가슴)',
    nameEn: 'Chest Dips',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.triceps, BodyPart.shoulders],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '평행봉을 잡고 팔을 펴서 올라간다',
      '몸을 약간 앞으로 기울여 가슴에 자극이 가도록 한다',
      '숨을 들이쉬며 팔꿈치를 구부려 천천히 내려간다',
      '팔꿈치가 90도 각도가 될 때까지 내린다',
      '숨을 내쉬며 힘차게 밀어 올린다',
    ],
    tips: ['몸을 앞으로 기울일수록 가슴에 더 자극', '삼두 위주라면 몸을 수직으로 유지'],
  ),
  Exercise(
    id: 'chest_005',
    name: '케이블 크로스오버',
    nameEn: 'Cable Crossover',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.shoulders],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '케이블 머신 중앙에 서서 양손에 케이블을 잡는다',
      '팔을 좌우로 벌린 상태에서 시작',
      '숨을 내쉬며 양팔을 앞으로 모아 가슴 앞에서 교차',
      '가슴 근육의 수축을 느끼며 잠시 유지',
      '숨을 들이쉬며 천천히 원위치로',
    ],
    tips: ['팔꿈치는 항상 약간 구부린 상태', '상-중-하 높이 변화로 다양한 자극 가능'],
  ),
  Exercise(
    id: 'chest_006',
    name: '푸쉬업',
    nameEn: 'Push-Up',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.triceps, BodyPart.shoulders],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '어깨너비보다 약간 넓게 손을 짚고 엎드린다',
      '몸을 일자로 유지',
      '숨을 들이쉬며 팔꿈치를 구부려 가슴이 바닥에 닿도록 내린다',
      '숨을 내쉬며 힘차게 밀어 올린다',
    ],
    tips: ['코어에 힘을 줘 몸이 처지지 않도록', '손 위치를 좁히면 삼두에 더 자극'],
  ),
  Exercise(
    id: 'chest_007',
    name: '스미스머신 벤치프레스',
    nameEn: 'Smith Machine Bench Press',
    bodyPart: BodyPart.chest,
    secondaryBodyParts: [BodyPart.triceps, BodyPart.shoulders],
    equipment: Equipment.smithMachine,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '스미스머신 바 아래 벤치를 위치시킨다',
      '어깨너비보다 넓게 바를 잡는다',
      '숨을 들이쉬며 바를 가슴으로 내린다',
      '숨을 내쉬며 힘차게 밀어 올린다',
    ],
    tips: ['프리웨이트보다 안전하게 연습 가능', '발 위치를 바꿔 가슴 하부/상부 자극 조절'],
  ),

  // ── 등 (Back) - 7개 ──────────────────────────────────────────────────────
  Exercise(
    id: 'back_001',
    name: '바벨 데드리프트',
    nameEn: 'Barbell Deadlift',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings, BodyPart.quadriceps],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.advanced,
    isCompound: true,
    instructions: [
      '바벨 앞에 어깨너비로 서서 발을 바 아래에 위치',
      '엉덩이를 뒤로 빼고 허리를 편 채로 바를 잡는다',
      '코어와 등을 단단히 잡아준다',
      '숨을 들이쉬고 바를 다리를 따라 힘차게 들어 올린다',
      '힙을 앞으로 밀며 완전히 서 있는 자세로 완성',
      '숨을 내쉬며 천천히 내려놓는다',
    ],
    tips: [
      '등을 절대 굽히지 않는다',
      '바는 항상 몸에 가깝게 유지',
      '처음에는 가벼운 무게로 폼 완성',
    ],
  ),
  Exercise(
    id: 'back_002',
    name: '랫풀다운',
    nameEn: 'Lat Pulldown',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.biceps],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '광배근 머신에 앉아 넓게 바를 잡는다',
      '가슴을 열고 상체를 약간 뒤로 기운다',
      '숨을 내쉬며 바를 가슴 위쪽으로 당긴다',
      '팔꿈치를 최대한 뒤로 당겨 등이 수축되는 것을 느낀다',
      '숨을 들이쉬며 천천히 원위치로',
    ],
    tips: ['가슴을 들어 등 자극 극대화', '팔꿈치로 당기는 느낌으로'],
  ),
  Exercise(
    id: 'back_003',
    name: '바벨 로우',
    nameEn: 'Barbell Row',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.biceps, BodyPart.shoulders],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '어깨너비로 서서 상체를 45도로 굽힌다',
      '바를 오버핸드로 어깨너비보다 넓게 잡는다',
      '숨을 내쉬며 바를 복부 쪽으로 당긴다',
      '팔꿈치가 등 뒤로 최대한 당겨지도록',
      '숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['허리는 중립 자세 유지', '머리부터 꼬리뼈까지 일직선'],
  ),
  Exercise(
    id: 'back_004',
    name: '시티드 케이블 로우',
    nameEn: 'Seated Cable Row',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.biceps],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '로우 머신에 앉아 발판에 발을 고정하고 핸들을 잡는다',
      '허리를 펴고 상체를 수직으로 세운다',
      '숨을 내쉬며 핸들을 복부로 당긴다',
      '팔꿈치를 최대한 뒤로 당겨 등을 수축',
      '숨을 들이쉬며 천천히 원위치',
    ],
    tips: ['허리가 앞뒤로 흔들리지 않도록', '등 근육으로 당기는 느낌에 집중'],
  ),
  Exercise(
    id: 'back_005',
    name: '풀업',
    nameEn: 'Pull-Up',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.biceps],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '철봉을 어깨너비보다 넓게 오버핸드로 잡는다',
      '팔을 완전히 펴서 매달린다',
      '숨을 내쉬며 턱이 철봉 위로 올라올 때까지 당긴다',
      '등이 완전히 수축되는 것을 느낀다',
      '숨을 들이쉬며 천천히 내려간다',
    ],
    tips: ['몸이 흔들리지 않도록 코어에 힘', '어깨를 귀에서 멀리 내린 채로 시작'],
  ),
  Exercise(
    id: 'back_006',
    name: '원암 덤벨 로우',
    nameEn: 'One-Arm Dumbbell Row',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.biceps],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '벤치에 한쪽 무릎과 손을 짚고 반대 손에 덤벨',
      '허리를 평행하게 유지',
      '숨을 내쉬며 덤벨을 옆구리로 당긴다',
      '팔꿈치가 등 위로 올라오도록',
      '숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['어깨가 들리지 않도록', '회전 없이 직선으로 당기기'],
  ),
  Exercise(
    id: 'back_007',
    name: '하이퍼익스텐션',
    nameEn: 'Hyperextension',
    bodyPart: BodyPart.back,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '하이퍼익스텐션 기구에 엎드려 골반을 패드에 고정',
      '팔짱을 끼거나 머리 뒤에 손을 놓는다',
      '숨을 들이쉬며 상체를 아래로 내린다',
      '숨을 내쉬며 몸을 일직선으로 들어 올린다',
      '허리를 과도하게 젖히지 않는다',
    ],
    tips: ['천천히 움직여 허리 근육을 자극', '무게를 들면 난이도 상승'],
  ),

  // ── 어깨 (Shoulders) - 6개 ───────────────────────────────────────────────
  Exercise(
    id: 'shoulder_001',
    name: '바벨 오버헤드 프레스',
    nameEn: 'Barbell Overhead Press',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [BodyPart.triceps],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '어깨너비로 서서 바를 어깨 높이에 위치',
      '코어에 힘을 주고 허리를 편다',
      '숨을 내쉬며 바를 머리 위로 힘차게 밀어 올린다',
      '팔을 완전히 펴고 잠시 유지',
      '숨을 들이쉬며 천천히 내려온다',
    ],
    tips: ['복근에 힘을 줘 허리가 꺾이지 않도록', '바가 귀 옆으로 지나가도록'],
  ),
  Exercise(
    id: 'shoulder_002',
    name: '덤벨 레터럴 레이즈',
    nameEn: 'Dumbbell Lateral Raise',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '양손에 덤벨을 들고 허벅지 옆에 위치',
      '팔꿈치를 약간 구부린다',
      '숨을 내쉬며 팔을 옆으로 어깨 높이까지 들어 올린다',
      '잠깐 유지 후 숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['어깨 높이 이상 올리지 않는다', '새끼손가락이 엄지손가락보다 약간 높게'],
  ),
  Exercise(
    id: 'shoulder_003',
    name: '덤벨 프론트 레이즈',
    nameEn: 'Dumbbell Front Raise',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '덤벨을 허벅지 앞에 위치',
      '팔을 앞으로 어깨 높이까지 올린다',
      '잠깐 유지 후 천천히 내린다',
    ],
    tips: ['전면 삼각근 고립', '몸통 반동 최소화'],
  ),
  Exercise(
    id: 'shoulder_004',
    name: '페이스 풀',
    nameEn: 'Face Pull',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [BodyPart.back],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '케이블을 눈 높이에 맞추고 로프 핸들을 잡는다',
      '한 발 뒤로 서서 몸을 약간 뒤로 기운다',
      '숨을 내쉬며 로프를 얼굴 쪽으로 당긴다',
      '팔꿈치가 어깨 높이로 올라오도록',
    ],
    tips: ['후면 삼각근 + 외회전근 강화', '어깨 건강에 필수적인 운동'],
  ),
  Exercise(
    id: 'shoulder_005',
    name: '아놀드 프레스',
    nameEn: 'Arnold Press',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [BodyPart.triceps],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '덤벨을 어깨 높이에 들고 손바닥이 자신을 향하도록',
      '밀어 올리면서 손목을 바깥으로 돌린다',
      '머리 위에서 손바닥이 앞을 향하도록 완성',
      '내리면서 반대로 손목을 돌린다',
    ],
    tips: ['3D 어깨 운동으로 전체 삼각근 발달', '천천히 회전하며 자극 집중'],
  ),
  Exercise(
    id: 'shoulder_006',
    name: '업라이트 로우',
    nameEn: 'Upright Row',
    bodyPart: BodyPart.shoulders,
    secondaryBodyParts: [BodyPart.biceps, BodyPart.back],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '바벨을 좁게 잡고 허벅지 앞에 위치',
      '숨을 내쉬며 바를 턱 아래까지 당겨 올린다',
      '팔꿈치가 손보다 항상 위에 위치',
      '숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['측면 삼각근과 승모근 동시 발달', '너무 높이 올리면 어깨 충돌 위험'],
  ),

  // ── 이두 (Biceps) - 6개 ──────────────────────────────────────────────────
  Exercise(
    id: 'biceps_001',
    name: '바벨 컬',
    nameEn: 'Barbell Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '어깨너비로 바벨을 언더핸드로 잡는다',
      '팔꿈치를 몸에 고정',
      '숨을 내쉬며 바벨을 어깨 쪽으로 컬',
      '이두근이 완전히 수축될 때까지',
      '숨을 들이쉬며 천천히 내린다',
    ],
    tips: ['팔꿈치가 앞뒤로 움직이지 않도록', '몸통 반동 금지'],
  ),
  Exercise(
    id: 'biceps_002',
    name: '덤벨 해머 컬',
    nameEn: 'Dumbbell Hammer Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '덤벨을 양손에 들고 손목이 중립 위치',
      '엄지손가락이 위를 향한 채로',
      '숨을 내쉬며 덤벨을 어깨 쪽으로 올린다',
      '천천히 내린다',
    ],
    tips: ['상완근과 전완근도 동시 발달', '교대 또는 동시에 수행'],
  ),
  Exercise(
    id: 'biceps_003',
    name: '인클라인 덤벨 컬',
    nameEn: 'Incline Dumbbell Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '벤치를 45도로 세우고 등을 기댄다',
      '팔을 완전히 내린 채로 시작',
      '이두근에 최대 스트레칭',
      '숨을 내쉬며 올리고 수축 유지',
    ],
    tips: ['이두근 최대 스트레칭 가능', '피크 컨트랙션에 집중'],
  ),
  Exercise(
    id: 'biceps_004',
    name: '컨센트레이션 컬',
    nameEn: 'Concentration Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '벤치에 앉아 팔꿈치를 허벅지 안쪽에 고정',
      '덤벨을 아래로 내린 채로 시작',
      '숨을 내쉬며 최대한 올린다',
      '이두근 피크 수축을 느끼며 유지',
    ],
    tips: ['이두근 피크 향상에 효과적', '천천히 컨트롤'],
  ),
  Exercise(
    id: 'biceps_005',
    name: 'EZ바 컬',
    nameEn: 'EZ Bar Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.ezBar,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      'EZ바를 손목 중립 각도로 잡는다',
      '팔꿈치 고정',
      '컬하여 이두 수축',
      '천천히 내린다',
    ],
    tips: ['손목 부담이 바벨보다 적음', '손 너비에 따라 자극 부위 변화'],
  ),
  Exercise(
    id: 'biceps_006',
    name: '케이블 컬',
    nameEn: 'Cable Curl',
    bodyPart: BodyPart.biceps,
    secondaryBodyParts: [],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '케이블 하단 풀리에 바를 연결',
      '어깨너비로 잡고 서서',
      '팔꿈치 고정 후 컬',
      '지속적인 텐션 유지',
    ],
    tips: ['전 구간 텐션 유지가 덤벨/바벨보다 뛰어남'],
  ),

  // ── 삼두 (Triceps) - 6개 ─────────────────────────────────────────────────
  Exercise(
    id: 'triceps_001',
    name: '클로즈그립 벤치프레스',
    nameEn: 'Close-Grip Bench Press',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [BodyPart.chest, BodyPart.shoulders],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '벤치에 누워 어깨너비로 바를 좁게 잡는다',
      '팔꿈치를 몸에 붙인 채로',
      '숨을 들이쉬며 가슴으로 내린다',
      '숨을 내쉬며 삼두로 밀어 올린다',
    ],
    tips: ['팔꿈치가 벌어지지 않도록', '삼두 최대 운동 중 하나'],
  ),
  Exercise(
    id: 'triceps_002',
    name: '트라이셉스 푸시다운',
    nameEn: 'Triceps Pushdown',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '케이블 상단에 바 또는 로프를 연결',
      '팔꿈치를 몸에 고정',
      '숨을 내쉬며 아래로 밀어 완전히 편다',
      '삼두 수축을 느끼며 유지',
      '천천히 원위치',
    ],
    tips: ['팔꿈치 위치 고정이 핵심', '완전한 가동 범위로'],
  ),
  Exercise(
    id: 'triceps_003',
    name: '오버헤드 트라이셉스 익스텐션',
    nameEn: 'Overhead Triceps Extension',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '덤벨을 양손으로 잡고 머리 위로 올린다',
      '팔꿈치를 귀 옆에 고정',
      '숨을 들이쉬며 뒤로 내린다',
      '숨을 내쉬며 위로 밀어 올린다',
    ],
    tips: ['장두(long head) 발달에 최고', '팔꿈치가 벌어지지 않도록'],
  ),
  Exercise(
    id: 'triceps_004',
    name: '라잉 트라이셉스 익스텐션 (스컬크러셔)',
    nameEn: 'Lying Triceps Extension',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [],
    equipment: Equipment.ezBar,
    difficulty: DifficultyLevel.intermediate,
    isCompound: false,
    instructions: [
      '벤치에 누워 EZ바를 어깨 위로 든다',
      '팔꿈치를 고정한 채 이마 쪽으로 내린다',
      '삼두로 밀어 올린다',
    ],
    tips: ['팔꿈치 방향을 천장으로 고정', '천천히 컨트롤'],
  ),
  Exercise(
    id: 'triceps_005',
    name: '벤치 딥스',
    nameEn: 'Bench Dips',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [BodyPart.chest, BodyPart.shoulders],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '벤치 끝에 손을 짚고 다리를 앞으로 뻗는다',
      '엉덩이를 벤치 앞으로 뺀다',
      '팔꿈치를 구부려 몸을 내린다',
      '삼두로 밀어 올린다',
    ],
    tips: ['다리를 높이 올릴수록 난이도 상승', '삼두 고립에 효과적'],
  ),
  Exercise(
    id: 'triceps_006',
    name: '케이블 오버헤드 익스텐션',
    nameEn: 'Cable Overhead Extension',
    bodyPart: BodyPart.triceps,
    secondaryBodyParts: [],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '케이블을 뒤쪽에 두고 로프를 머리 위로',
      '팔꿈치 고정 후 앞으로 뻗는다',
      '삼두 수축 느끼기',
    ],
    tips: ['지속적인 텐션 유지', '장두 발달에 효과적'],
  ),

  // ── 하체 대퇴 (Quadriceps) - 5개 ─────────────────────────────────────────
  Exercise(
    id: 'quad_001',
    name: '바벨 스쿼트',
    nameEn: 'Barbell Squat',
    bodyPart: BodyPart.quadriceps,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '바벨을 승모근 위에 올리고 어깨너비로 선다',
      '발끝을 약간 바깥으로 향하게',
      '숨을 들이쉬며 엉덩이를 뒤로 빼며 내려간다',
      '허벅지가 바닥과 평행할 때까지',
      '숨을 내쉬며 힘차게 일어선다',
    ],
    tips: [
      '무릎이 발끝 방향으로 유지',
      '등을 절대 굽히지 않는다',
      '깊이보다 자세가 우선',
    ],
  ),
  Exercise(
    id: 'quad_002',
    name: '레그 프레스',
    nameEn: 'Leg Press',
    bodyPart: BodyPart.quadriceps,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
    equipment: Equipment.machine,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '레그프레스 머신에 앉아 발을 플랫폼 중간에 위치',
      '안전장치를 풀고 플랫폼을 밀어낸다',
      '무릎을 구부려 천천히 내려온다',
      '힘차게 밀어 올린다',
    ],
    tips: ['무릎이 발끝을 벗어나지 않도록', '발 위치로 자극 부위 조절'],
  ),
  Exercise(
    id: 'quad_003',
    name: '레그 익스텐션',
    nameEn: 'Leg Extension',
    bodyPart: BodyPart.quadriceps,
    secondaryBodyParts: [],
    equipment: Equipment.machine,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '레그 익스텐션 머신에 앉아 발목 패드에 발을 넣는다',
      '숨을 내쉬며 다리를 완전히 편다',
      '대퇴사두 수축 유지',
      '천천히 내린다',
    ],
    tips: ['대퇴사두 고립 운동', '무릎 부상 있으면 주의'],
  ),
  Exercise(
    id: 'quad_004',
    name: '런지',
    nameEn: 'Lunge',
    bodyPart: BodyPart.quadriceps,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: true,
    instructions: [
      '허리를 편 채로 선다',
      '한 발을 앞으로 크게 내딛는다',
      '뒤 무릎이 바닥에 닿기 직전까지 내린다',
      '앞발로 힘차게 밀어 원위치',
    ],
    tips: ['앞 무릎이 발끝을 넘지 않도록', '덤벨 들면 난이도 상승'],
  ),
  Exercise(
    id: 'quad_005',
    name: '불가리안 스플릿 스쿼트',
    nameEn: 'Bulgarian Split Squat',
    bodyPart: BodyPart.quadriceps,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.hamstrings],
    equipment: Equipment.dumbbell,
    difficulty: DifficultyLevel.advanced,
    isCompound: true,
    instructions: [
      '뒷발을 벤치 위에 올린다',
      '앞발을 멀리 내딛고 균형 잡는다',
      '뒤 무릎이 바닥에 닿기 직전까지 내린다',
      '앞 허벅지로 힘차게 밀어 올린다',
    ],
    tips: ['균형 잡기가 어려우면 맨몸으로 연습', '고관절 유연성 향상에도 효과적'],
  ),

  // ── 햄스트링 (Hamstrings) - 3개 ──────────────────────────────────────────
  Exercise(
    id: 'ham_001',
    name: '루마니안 데드리프트',
    nameEn: 'Romanian Deadlift',
    bodyPart: BodyPart.hamstrings,
    secondaryBodyParts: [BodyPart.glutes, BodyPart.back],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '바벨을 어깨너비로 잡고 선다',
      '무릎을 약간 구부린 채로 고정',
      '엉덩이를 뒤로 빼며 상체를 숙인다',
      '햄스트링이 스트레칭될 때까지',
      '엉덩이로 힘차게 밀어 일어선다',
    ],
    tips: ['등을 절대 굽히지 않는다', '바를 항상 몸에 가깝게'],
  ),
  Exercise(
    id: 'ham_002',
    name: '레그 컬',
    nameEn: 'Leg Curl',
    bodyPart: BodyPart.hamstrings,
    secondaryBodyParts: [],
    equipment: Equipment.machine,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '레그컬 머신에 엎드려 발목 패드에 발을 넣는다',
      '숨을 내쉬며 다리를 구부려 엉덩이 쪽으로',
      '햄스트링 수축 유지',
      '천천히 내린다',
    ],
    tips: ['햄스트링 고립 운동', '앉아서 하는 시티드 레그컬도 가능'],
  ),
  Exercise(
    id: 'ham_003',
    name: '굿모닝',
    nameEn: 'Good Morning',
    bodyPart: BodyPart.hamstrings,
    secondaryBodyParts: [BodyPart.back, BodyPart.glutes],
    equipment: Equipment.barbell,
    difficulty: DifficultyLevel.intermediate,
    isCompound: true,
    instructions: [
      '바벨을 승모근 위에 올리고 선다',
      '무릎을 약간 구부린 채로',
      '허리를 편 채 상체를 앞으로 굽힌다',
      '수평에 가깝게 내린 뒤 일어선다',
    ],
    tips: ['허리 근력도 동시에 발달', '처음에는 빈 바로 시작'],
  ),

  // ── 종아리 (Calves) - 2개 ────────────────────────────────────────────────
  Exercise(
    id: 'calf_001',
    name: '스탠딩 카프 레이즈',
    nameEn: 'Standing Calf Raise',
    bodyPart: BodyPart.calves,
    secondaryBodyParts: [],
    equipment: Equipment.machine,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '카프 레이즈 머신 또는 계단 가장자리에 선다',
      '발뒤꿈치를 천천히 들어 올린다',
      '종아리 수축을 느끼며 잠시 유지',
      '천천히 뒤꿈치를 내린다',
    ],
    tips: ['전 가동 범위로 수행', '느리게 움직여야 효과적'],
  ),
  Exercise(
    id: 'calf_002',
    name: '시티드 카프 레이즈',
    nameEn: 'Seated Calf Raise',
    bodyPart: BodyPart.calves,
    secondaryBodyParts: [],
    equipment: Equipment.machine,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '시티드 카프 레이즈 머신에 앉아 무릎 패드를 조정',
      '발뒤꿈치를 들어 올린다',
      '수축 유지 후 내린다',
    ],
    tips: ['앉은 자세로 가자미근 발달에 효과적'],
  ),

  // ── 코어/복근 (Abs) - 5개 ─────────────────────────────────────────────────
  Exercise(
    id: 'abs_001',
    name: '크런치',
    nameEn: 'Crunch',
    bodyPart: BodyPart.abs,
    secondaryBodyParts: [],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '바닥에 누워 무릎을 구부린다',
      '손을 머리 뒤에 가볍게 얹는다',
      '숨을 내쉬며 상체를 말아 올린다',
      '복근 수축을 느끼며 유지',
      '천천히 내려온다',
    ],
    tips: ['목을 당기지 말고 복근으로', '허리가 바닥에서 떨어지지 않도록'],
  ),
  Exercise(
    id: 'abs_002',
    name: '플랭크',
    nameEn: 'Plank',
    bodyPart: BodyPart.abs,
    secondaryBodyParts: [BodyPart.back, BodyPart.shoulders],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '팔꿈치를 어깨 아래에 두고 엎드린다',
      '몸을 일직선으로 유지',
      '복근과 엉덩이에 힘을 주며 자세 유지',
    ],
    tips: ['엉덩이가 올라가거나 처지지 않도록', '호흡을 계속 유지'],
  ),
  Exercise(
    id: 'abs_003',
    name: '레그 레이즈',
    nameEn: 'Leg Raise',
    bodyPart: BodyPart.abs,
    secondaryBodyParts: [],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.intermediate,
    isCompound: false,
    instructions: [
      '바닥에 누워 손을 엉덩이 아래에 넣는다',
      '다리를 합쳐 90도로 올린다',
      '천천히 바닥에 거의 닿을 때까지 내린다',
      '허리가 들리지 않도록 유의',
    ],
    tips: ['하복부 발달에 효과적', '무릎을 약간 구부리면 난이도 낮아짐'],
  ),
  Exercise(
    id: 'abs_004',
    name: '러시안 트위스트',
    nameEn: 'Russian Twist',
    bodyPart: BodyPart.abs,
    secondaryBodyParts: [],
    equipment: Equipment.bodyweight,
    difficulty: DifficultyLevel.beginner,
    isCompound: false,
    instructions: [
      '바닥에 앉아 무릎을 구부리고 상체를 약간 뒤로 기운다',
      '양손을 모으거나 메디신볼/덤벨 들기',
      '좌우로 번갈아 상체를 돌린다',
    ],
    tips: ['복사근 발달에 효과적', '무게 추가로 난이도 상승'],
  ),
  Exercise(
    id: 'abs_005',
    name: '케이블 크런치',
    nameEn: 'Cable Crunch',
    bodyPart: BodyPart.abs,
    secondaryBodyParts: [],
    equipment: Equipment.cable,
    difficulty: DifficultyLevel.intermediate,
    isCompound: false,
    instructions: [
      '케이블 상단 풀리에 로프를 연결',
      '무릎 꿇고 앉아 로프를 머리 옆에',
      '복근으로 상체를 말아 내린다',
      '무게를 추가할 수 있어 점진적 과부하 가능',
    ],
    tips: ['복근에 가장 효과적인 유산소 운동', '엉덩이가 뒤로 빠지지 않도록'],
  ),
];

// ---------------------------------------------------------------------------
// ExerciseDatabaseState - 운동 데이터베이스 상태
// ---------------------------------------------------------------------------

class ExerciseDatabaseState {
  final List<Exercise> allExercises; // 전체 운동 목록
  final BodyPart? selectedBodyPart; // 선택된 부위 필터
  final Equipment? selectedEquipment; // 선택된 기구 필터
  final DifficultyLevel? selectedDifficulty; // 선택된 난이도 필터
  final String searchQuery; // 검색어

  const ExerciseDatabaseState({
    required this.allExercises,
    this.selectedBodyPart,
    this.selectedEquipment,
    this.selectedDifficulty,
    this.searchQuery = '',
  });

  /// 현재 필터/검색이 적용된 운동 목록
  List<Exercise> get filteredExercises {
    return allExercises.where((exercise) {
      // 부위 필터
      if (selectedBodyPart != null &&
          exercise.bodyPart != selectedBodyPart) {
        return false;
      }
      // 기구 필터
      if (selectedEquipment != null &&
          exercise.equipment != selectedEquipment) {
        return false;
      }
      // 난이도 필터
      if (selectedDifficulty != null &&
          exercise.difficulty != selectedDifficulty) {
        return false;
      }
      // 검색어 필터
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return exercise.name.toLowerCase().contains(query) ||
            exercise.nameEn.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  ExerciseDatabaseState copyWith({
    List<Exercise>? allExercises,
    BodyPart? selectedBodyPart,
    bool clearBodyPart = false,
    Equipment? selectedEquipment,
    bool clearEquipment = false,
    DifficultyLevel? selectedDifficulty,
    bool clearDifficulty = false,
    String? searchQuery,
  }) {
    return ExerciseDatabaseState(
      allExercises: allExercises ?? this.allExercises,
      selectedBodyPart: clearBodyPart ? null : (selectedBodyPart ?? this.selectedBodyPart),
      selectedEquipment: clearEquipment ? null : (selectedEquipment ?? this.selectedEquipment),
      selectedDifficulty: clearDifficulty ? null : (selectedDifficulty ?? this.selectedDifficulty),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ---------------------------------------------------------------------------
// ExerciseDatabaseNotifier
// ---------------------------------------------------------------------------

class ExerciseDatabaseNotifier
    extends StateNotifier<ExerciseDatabaseState> {
  ExerciseDatabaseNotifier()
      : super(const ExerciseDatabaseState(allExercises: kAllExercises));

  /// 부위별 필터
  void filterByBodyPart(BodyPart? bodyPart) {
    if (bodyPart == null) {
      state = state.copyWith(clearBodyPart: true);
    } else {
      state = state.copyWith(selectedBodyPart: bodyPart);
    }
  }

  /// 기구별 필터
  void filterByEquipment(Equipment? equipment) {
    if (equipment == null) {
      state = state.copyWith(clearEquipment: true);
    } else {
      state = state.copyWith(selectedEquipment: equipment);
    }
  }

  /// 난이도별 필터
  void filterByDifficulty(DifficultyLevel? difficulty) {
    if (difficulty == null) {
      state = state.copyWith(clearDifficulty: true);
    } else {
      state = state.copyWith(selectedDifficulty: difficulty);
    }
  }

  /// 검색
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 모든 필터 초기화
  void clearFilters() {
    state = state.copyWith(
      clearBodyPart: true,
      clearEquipment: true,
      clearDifficulty: true,
      searchQuery: '',
    );
  }

  /// ID로 운동 조회
  Exercise? getExerciseById(String id) {
    try {
      return state.allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 복합 운동만 조회
  List<Exercise> getCompoundExercises() {
    return state.allExercises.where((e) => e.isCompound).toList();
  }

  /// 부위별 운동 수 통계
  Map<BodyPart, int> get exerciseCountByBodyPart {
    final counts = <BodyPart, int>{};
    for (final exercise in state.allExercises) {
      counts[exercise.bodyPart] = (counts[exercise.bodyPart] ?? 0) + 1;
    }
    return counts;
  }
}

// ---------------------------------------------------------------------------
// WorkoutSplitType - 운동 스플릿 종류
// ---------------------------------------------------------------------------

enum WorkoutSplitType {
  ppl('PPL (밀기/당기기/하체)'),
  upperLower('상하체 분할'),
  fullBody('전신 운동'),
  fourSplit('4분할 (가슴/등/어깨/하체)');

  final String label;
  const WorkoutSplitType(this.label);
}

// ---------------------------------------------------------------------------
// WorkoutRecommender - AI 기반 운동 추천
// ---------------------------------------------------------------------------

class WorkoutRecommender {
  final List<WorkoutRecord> history;
  final List<Exercise> allExercises;

  const WorkoutRecommender({
    required this.history,
    required this.allExercises,
  });

  /// 최근 운동한 부위 목록 (최근 2일)
  List<BodyPart> get recentlyWorkedBodyParts {
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final recentRecords =
        history.where((r) => r.date.isAfter(twoDaysAgo)).toList();

    final parts = <BodyPart>{};
    for (final record in recentRecords) {
      for (final exercise in record.exercises) {
        parts.add(exercise.bodyPart);
      }
    }
    return parts.toList();
  }

  /// 가장 오래 운동하지 않은 부위 (약점 부위)
  List<BodyPart> get weakBodyParts {
    final bodyPartLastWorked = <BodyPart, DateTime>{};

    for (final record in history) {
      for (final exercise in record.exercises) {
        final part = exercise.bodyPart;
        final existing = bodyPartLastWorked[part];
        if (existing == null || record.date.isAfter(existing)) {
          bodyPartLastWorked[part] = record.date;
        }
      }
    }

    // 운동한 적 없는 부위
    final neverWorked = BodyPart.values
        .where((p) =>
            p != BodyPart.fullBody &&
            p != BodyPart.cardio &&
            !bodyPartLastWorked.containsKey(p))
        .toList();

    if (neverWorked.isNotEmpty) return neverWorked;

    // 오래된 순으로 정렬
    final sorted = bodyPartLastWorked.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// 오늘 추천 운동 생성 (최근 운동 부위 제외)
  List<Exercise> getTodayRecommendations({int count = 6}) {
    final excluded = recentlyWorkedBodyParts.toSet();
    final candidates = allExercises
        .where((e) => !excluded.contains(e.bodyPart))
        .toList();

    if (candidates.isEmpty) {
      // 모든 부위를 최근에 운동했으면 전체에서 추천
      final shuffled = List<Exercise>.from(allExercises)..shuffle();
      return shuffled.take(count).toList();
    }

    // 부위별로 고르게 선택
    final byBodyPart = <BodyPart, List<Exercise>>{};
    for (final e in candidates) {
      byBodyPart.putIfAbsent(e.bodyPart, () => []).add(e);
    }

    final recommended = <Exercise>[];
    final parts = byBodyPart.keys.toList()..shuffle();

    for (final part in parts) {
      if (recommended.length >= count) break;
      final exercises = byBodyPart[part]!..shuffle();
      recommended.add(exercises.first);
    }

    // 부족하면 추가
    if (recommended.length < count) {
      final remaining = candidates
          .where((e) => !recommended.contains(e))
          .toList()
        ..shuffle();
      recommended.addAll(
          remaining.take(count - recommended.length));
    }

    return recommended.take(count).toList();
  }

  /// PPL 스플릿 기반 추천
  List<Exercise> getPPLRecommendation() {
    final today = DateTime.now().weekday;
    // 월/목: Push (가슴, 어깨, 삼두)
    // 화/금: Pull (등, 이두)
    // 수/토: Legs (하체, 종아리)
    // 일: 휴식

    final pushParts = {BodyPart.chest, BodyPart.shoulders, BodyPart.triceps};
    final pullParts = {BodyPart.back, BodyPart.biceps};
    final legParts = {
      BodyPart.quadriceps,
      BodyPart.hamstrings,
      BodyPart.calves,
      BodyPart.glutes
    };

    Set<BodyPart> targetParts;
    switch (today) {
      case DateTime.monday:
      case DateTime.thursday:
        targetParts = pushParts;
      case DateTime.tuesday:
      case DateTime.friday:
        targetParts = pullParts;
      case DateTime.wednesday:
      case DateTime.saturday:
        targetParts = legParts;
      default:
        return []; // 일요일 휴식
    }

    return allExercises
        .where((e) => targetParts.contains(e.bodyPart))
        .take(6)
        .toList();
  }

  /// 상하체 스플릿 기반 추천
  List<Exercise> getUpperLowerRecommendation() {
    final today = DateTime.now().weekday;
    final upperParts = {
      BodyPart.chest,
      BodyPart.back,
      BodyPart.shoulders,
      BodyPart.biceps,
      BodyPart.triceps,
    };
    final lowerParts = {
      BodyPart.quadriceps,
      BodyPart.hamstrings,
      BodyPart.calves,
      BodyPart.glutes,
    };

    // 홀수일: 상체, 짝수일: 하체
    final targetParts = today.isOdd ? upperParts : lowerParts;

    return allExercises
        .where((e) => targetParts.contains(e.bodyPart))
        .take(6)
        .toList();
  }

  /// 진행적 과부하 추천 (+2.5kg 또는 +1rep)
  ProgressiveOverloadSuggestion? getProgressiveOverloadSuggestion(
    String exerciseId,
    List<PersonalRecord> personalRecords,
  ) {
    final pr = personalRecords
        .where((p) => p.exerciseId == exerciseId)
        .toList();

    if (pr.isEmpty) return null;

    final latest = pr.first;

    // 10회 이상이면 무게 증가, 미만이면 반복수 증가
    if (latest.reps >= 10) {
      return ProgressiveOverloadSuggestion(
        exerciseId: exerciseId,
        suggestedWeight: latest.weight + 2.5,
        suggestedReps: latest.reps - 2,
        reason: '이전 기록 ${latest.weight}kg×${latest.reps}회 → 무게 +2.5kg',
      );
    } else {
      return ProgressiveOverloadSuggestion(
        exerciseId: exerciseId,
        suggestedWeight: latest.weight,
        suggestedReps: latest.reps + 1,
        reason: '이전 기록 ${latest.weight}kg×${latest.reps}회 → 반복수 +1회',
      );
    }
  }

  /// 스플릿 타입별 추천
  List<Exercise> getRecommendationBySplit(WorkoutSplitType split) {
    switch (split) {
      case WorkoutSplitType.ppl:
        return getPPLRecommendation();
      case WorkoutSplitType.upperLower:
        return getUpperLowerRecommendation();
      case WorkoutSplitType.fullBody:
        return getTodayRecommendations(count: 8);
      case WorkoutSplitType.fourSplit:
        return _getFourSplitRecommendation();
    }
  }

  /// 4분할 추천
  List<Exercise> _getFourSplitRecommendation() {
    final today = DateTime.now().weekday;
    BodyPart targetPart;
    switch (today) {
      case DateTime.monday:
        targetPart = BodyPart.chest;
      case DateTime.tuesday:
        targetPart = BodyPart.back;
      case DateTime.thursday:
        targetPart = BodyPart.shoulders;
      case DateTime.friday:
        targetPart = BodyPart.quadriceps;
      default:
        return getTodayRecommendations(count: 6);
    }

    return allExercises
        .where((e) => e.bodyPart == targetPart)
        .take(5)
        .toList();
  }
}

/// 진행적 과부하 추천 결과
class ProgressiveOverloadSuggestion {
  final String exerciseId;
  final double suggestedWeight;
  final int suggestedReps;
  final String reason;

  const ProgressiveOverloadSuggestion({
    required this.exerciseId,
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.reason,
  });
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 운동 데이터베이스 Provider
final exerciseDatabaseProvider =
    StateNotifierProvider<ExerciseDatabaseNotifier, ExerciseDatabaseState>(
  (ref) => ExerciseDatabaseNotifier(),
);

/// 필터링된 운동 목록 Provider
final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final dbState = ref.watch(exerciseDatabaseProvider);
  return dbState.filteredExercises;
});

/// 부위별 운동 Provider (파라미터화)
final exercisesByBodyPartProvider =
    Provider.family<List<Exercise>, BodyPart>((ref, bodyPart) {
  final allExercises = ref.watch(exerciseDatabaseProvider).allExercises;
  return allExercises.where((e) => e.bodyPart == bodyPart).toList();
});

/// AI 운동 추천 Provider
final workoutRecommenderProvider = Provider<WorkoutRecommender>((ref) {
  final history = ref.watch(workoutHistoryProvider);
  return WorkoutRecommender(
    history: history,
    allExercises: kAllExercises,
  );
});

/// 오늘 추천 운동 Provider
final todayRecommendedExercisesProvider = Provider<List<Exercise>>((ref) {
  final recommender = ref.watch(workoutRecommenderProvider);
  return recommender.getTodayRecommendations();
});

/// 약점 부위 Provider
final weakBodyPartsProvider = Provider<List<BodyPart>>((ref) {
  final recommender = ref.watch(workoutRecommenderProvider);
  return recommender.weakBodyParts;
});

/// 현재 선택된 스플릿 Provider
final selectedSplitProvider =
    StateProvider<WorkoutSplitType>((ref) => WorkoutSplitType.ppl);

/// 스플릿 기반 추천 운동 Provider
final splitBasedRecommendationsProvider = Provider<List<Exercise>>((ref) {
  final recommender = ref.watch(workoutRecommenderProvider);
  final split = ref.watch(selectedSplitProvider);
  return recommender.getRecommendationBySplit(split);
});
