// 트레이너 주도 영상 운동 데이터 및 상태 관리
// VideoWorkout 모델, VideoCategory 열거형, 관련 Provider 정의

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// VideoCategory 열거형
// ---------------------------------------------------------------------------

/// 영상 운동 카테고리
enum VideoCategory {
  strength('근력'),
  cardio('유산소'),
  yoga('요가'),
  hiit('HIIT'),
  stretching('스트레칭'),
  warmup('워밍업'),
  cooldown('쿨다운');

  final String label;
  const VideoCategory(this.label);
}

// ---------------------------------------------------------------------------
// VideoWorkout 모델
// ---------------------------------------------------------------------------

/// 트레이너 주도 영상 운동 항목
class VideoWorkout {
  final String id;
  final String title;
  final String trainerName;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final int durationMinutes;
  final String difficulty; // "초급" | "중급" | "고급"
  final List<String> bodyParts;
  final VideoCategory category;
  final bool isPremium;
  final int viewCount;

  const VideoWorkout({
    required this.id,
    required this.title,
    required this.trainerName,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationMinutes,
    required this.difficulty,
    required this.bodyParts,
    required this.category,
    this.isPremium = false,
    this.viewCount = 0,
  });
}

// ---------------------------------------------------------------------------
// 내장 영상 운동 데이터 (15개 이상)
// ---------------------------------------------------------------------------

const List<VideoWorkout> _builtInVideoWorkouts = [
  // ── HIIT ──────────────────────────────────────────────────────────────────

  VideoWorkout(
    id: 'v_hiit_01',
    title: '전신 버닝 HIIT 10분',
    trainerName: '김지수 트레이너',
    description:
        '짧고 강렬한 10분 전신 HIIT 운동입니다. 버피, 점프 스쿼트, 마운틴 클라이머 등 9가지 동작으로 구성되어 있습니다. 초보자도 강도를 조절하며 따라할 수 있습니다.',
    thumbnailUrl: 'https://picsum.photos/seed/hiit01/640/360',
    videoUrl: 'https://example.com/videos/hiit_10min_full_body.mp4',
    durationMinutes: 10,
    difficulty: '초급',
    bodyParts: ['전신'],
    category: VideoCategory.hiit,
    viewCount: 12400,
  ),
  VideoWorkout(
    id: 'v_hiit_02',
    title: '15분 타바타 지방 연소',
    trainerName: '박성민 트레이너',
    description:
        '타바타 인터벌 방식(20초 운동 / 10초 휴식)으로 구성된 15분 루틴입니다. 총 8라운드, 4가지 동작을 반복합니다. 심폐 기능 향상과 지방 연소에 효과적입니다.',
    thumbnailUrl: 'https://picsum.photos/seed/hiit02/640/360',
    videoUrl: 'https://example.com/videos/tabata_15min.mp4',
    durationMinutes: 15,
    difficulty: '중급',
    bodyParts: ['전신', '코어'],
    category: VideoCategory.hiit,
    viewCount: 9870,
  ),
  VideoWorkout(
    id: 'v_hiit_03',
    title: '고강도 20분 AMRAP 챌린지',
    trainerName: '이현우 트레이너',
    description:
        'AMRAP(As Many Rounds As Possible) 방식의 20분 고강도 루틴입니다. 케틀벨 스윙, 박스 점프, 풀업 등 복합 동작으로 구성됩니다. 고급자를 위한 체력 극한 도전입니다.',
    thumbnailUrl: 'https://picsum.photos/seed/hiit03/640/360',
    videoUrl: 'https://example.com/videos/amrap_20min.mp4',
    durationMinutes: 20,
    difficulty: '고급',
    bodyParts: ['전신', '등', '하체'],
    category: VideoCategory.hiit,
    isPremium: true,
    viewCount: 7230,
  ),

  // ── 요가 / 스트레칭 ────────────────────────────────────────────────────────

  VideoWorkout(
    id: 'v_yoga_01',
    title: '아침 15분 기초 요가 플로우',
    trainerName: '최유진 트레이너',
    description:
        '하루를 활기차게 시작하는 15분 아침 요가입니다. 태양 경배 자세를 기본으로 하며, 몸의 긴장을 풀고 에너지를 깨우는 데 초점을 맞춥니다. 요가 초보자에게 적합합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/yoga01/640/360',
    videoUrl: 'https://example.com/videos/morning_yoga_15min.mp4',
    durationMinutes: 15,
    difficulty: '초급',
    bodyParts: ['전신', '코어'],
    category: VideoCategory.yoga,
    viewCount: 18600,
  ),
  VideoWorkout(
    id: 'v_yoga_02',
    title: '취침 전 전신 이완 요가 20분',
    trainerName: '최유진 트레이너',
    description:
        '수면의 질을 높이는 20분 저녁 요가 루틴입니다. 깊은 호흡과 함께 등, 엉덩이, 햄스트링의 긴장을 풀어줍니다. 파라사바사나, 수프타 마첸드라아사나 등의 자세를 포함합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/yoga02/640/360',
    videoUrl: 'https://example.com/videos/bedtime_yoga_20min.mp4',
    durationMinutes: 20,
    difficulty: '초급',
    bodyParts: ['등', '엉덩이', '하체'],
    category: VideoCategory.yoga,
    viewCount: 15200,
  ),
  VideoWorkout(
    id: 'v_stretch_01',
    title: '운동 후 전신 스트레칭 15분',
    trainerName: '정다은 트레이너',
    description:
        '운동 후 근육 회복을 위한 15분 전신 스트레칭 루틴입니다. 주요 근육군을 체계적으로 늘려 근육통을 예방하고 유연성을 향상시킵니다.',
    thumbnailUrl: 'https://picsum.photos/seed/stretch01/640/360',
    videoUrl: 'https://example.com/videos/post_workout_stretch_15min.mp4',
    durationMinutes: 15,
    difficulty: '초급',
    bodyParts: ['전신'],
    category: VideoCategory.stretching,
    viewCount: 22100,
  ),
  VideoWorkout(
    id: 'v_yoga_03',
    title: '중급 파워 요가 30분',
    trainerName: '최유진 트레이너',
    description:
        '근력과 유연성을 동시에 기르는 30분 파워 요가 세션입니다. 전사 자세 시리즈, 밸런스 포즈, 역전 자세 등 도전적인 시퀀스를 포함합니다. 기초 요가 경험이 있는 분께 적합합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/yoga03/640/360',
    videoUrl: 'https://example.com/videos/power_yoga_30min.mp4',
    durationMinutes: 30,
    difficulty: '중급',
    bodyParts: ['전신', '코어', '어깨'],
    category: VideoCategory.yoga,
    isPremium: true,
    viewCount: 8900,
  ),

  // ── 근력 ──────────────────────────────────────────────────────────────────

  VideoWorkout(
    id: 'v_str_01',
    title: '덤벨 전신 근력 루틴 20분',
    trainerName: '박성민 트레이너',
    description:
        '덤벨 한 쌍만으로 할 수 있는 20분 전신 근력 운동입니다. 스쿼트, 루마니안 데드리프트, 덤벨 로우, 숄더 프레스 등 주요 복합 운동을 포함합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/str01/640/360',
    videoUrl: 'https://example.com/videos/dumbbell_strength_20min.mp4',
    durationMinutes: 20,
    difficulty: '초급',
    bodyParts: ['전신', '등', '어깨', '하체'],
    category: VideoCategory.strength,
    viewCount: 31400,
  ),
  VideoWorkout(
    id: 'v_str_02',
    title: '상체 집중 근력 훈련 25분',
    trainerName: '이현우 트레이너',
    description:
        '가슴, 등, 어깨, 팔을 집중적으로 공략하는 25분 상체 루틴입니다. 바벨 벤치프레스, 바벨 로우, 오버헤드 프레스를 중심으로 구성됩니다. 홈짐 또는 일반 헬스장에서 모두 사용 가능합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/str02/640/360',
    videoUrl: 'https://example.com/videos/upper_body_strength_25min.mp4',
    durationMinutes: 25,
    difficulty: '중급',
    bodyParts: ['가슴', '등', '어깨', '팔'],
    category: VideoCategory.strength,
    isPremium: true,
    viewCount: 14700,
  ),
  VideoWorkout(
    id: 'v_str_03',
    title: '하체 파워 빌딩 30분',
    trainerName: '박성민 트레이너',
    description:
        '스쿼트, 레그 프레스, 루마니안 데드리프트, 레그 컬로 구성된 30분 하체 근력 루틴입니다. 대퇴사두, 햄스트링, 둔근을 균형 있게 단련합니다. 중급자 이상을 대상으로 합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/str03/640/360',
    videoUrl: 'https://example.com/videos/lower_body_power_30min.mp4',
    durationMinutes: 30,
    difficulty: '중급',
    bodyParts: ['하체', '둔근', '햄스트링'],
    category: VideoCategory.strength,
    isPremium: true,
    viewCount: 11200,
  ),

  // ── 유산소 ────────────────────────────────────────────────────────────────

  VideoWorkout(
    id: 'v_cardio_01',
    title: '저충격 실내 걷기 운동 15분',
    trainerName: '정다은 트레이너',
    description:
        '관절에 부담 없는 저충격 실내 유산소 운동입니다. 장소를 이동하지 않고 걷기, 사이드 스텝, 무릎 들기 동작을 결합해 심박수를 높입니다. 체력 회복기나 초보자에게 적합합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/cardio01/640/360',
    videoUrl: 'https://example.com/videos/low_impact_walk_15min.mp4',
    durationMinutes: 15,
    difficulty: '초급',
    bodyParts: ['전신', '하체'],
    category: VideoCategory.cardio,
    viewCount: 27500,
  ),
  VideoWorkout(
    id: 'v_cardio_02',
    title: '댄스 피트니스 20분',
    trainerName: '김지수 트레이너',
    description:
        '음악에 맞춰 즐겁게 땀 흘리는 20분 댄스 피트니스 루틴입니다. 살사, 힙합, 팝 리듬을 혼합한 안무로 구성되며 칼로리 소모 효과가 뛰어납니다.',
    thumbnailUrl: 'https://picsum.photos/seed/cardio02/640/360',
    videoUrl: 'https://example.com/videos/dance_fitness_20min.mp4',
    durationMinutes: 20,
    difficulty: '초급',
    bodyParts: ['전신'],
    category: VideoCategory.cardio,
    viewCount: 19800,
  ),
  VideoWorkout(
    id: 'v_cardio_03',
    title: '스텝 에어로빅 인터벌 25분',
    trainerName: '정다은 트레이너',
    description:
        '스텝 박스를 활용한 인터벌 에어로빅 세션입니다. 고강도 인터벌과 능동적 회복 구간을 번갈아가며 심폐 기능을 효과적으로 향상시킵니다. 중급자 이상 권장입니다.',
    thumbnailUrl: 'https://picsum.photos/seed/cardio03/640/360',
    videoUrl: 'https://example.com/videos/step_aerobics_25min.mp4',
    durationMinutes: 25,
    difficulty: '중급',
    bodyParts: ['전신', '하체'],
    category: VideoCategory.cardio,
    isPremium: true,
    viewCount: 8300,
  ),

  // ── 워밍업 / 쿨다운 ────────────────────────────────────────────────────────

  VideoWorkout(
    id: 'v_warm_01',
    title: '운동 전 동적 워밍업 5분',
    trainerName: '이현우 트레이너',
    description:
        '부상 예방을 위한 5분 동적 워밍업 루틴입니다. 레그 스윙, 암 서클, 힙 오프너, 월드 그레이티스트 스트레치를 순서대로 수행합니다. 모든 운동 전에 권장됩니다.',
    thumbnailUrl: 'https://picsum.photos/seed/warm01/640/360',
    videoUrl: 'https://example.com/videos/dynamic_warmup_5min.mp4',
    durationMinutes: 5,
    difficulty: '초급',
    bodyParts: ['전신'],
    category: VideoCategory.warmup,
    viewCount: 45200,
  ),
  VideoWorkout(
    id: 'v_cool_01',
    title: '근육 회복 쿨다운 10분',
    trainerName: '최유진 트레이너',
    description:
        '운동 후 심박수를 안정적으로 낮추고 근육 회복을 돕는 10분 쿨다운입니다. 정적 스트레칭과 깊은 호흡을 결합하여 다음 날의 근육통을 최소화합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/cool01/640/360',
    videoUrl: 'https://example.com/videos/cooldown_10min.mp4',
    durationMinutes: 10,
    difficulty: '초급',
    bodyParts: ['전신'],
    category: VideoCategory.cooldown,
    viewCount: 33700,
  ),
  VideoWorkout(
    id: 'v_warm_02',
    title: '하체 집중 워밍업 7분',
    trainerName: '박성민 트레이너',
    description:
        '스쿼트 또는 데드리프트 세션 전에 하체와 엉덩이를 충분히 활성화하는 7분 워밍업입니다. 글루트 브리지, 클램쉘, 밴드 워크, 어드덕터 스트레칭을 포함합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/warm02/640/360',
    videoUrl: 'https://example.com/videos/lower_body_warmup_7min.mp4',
    durationMinutes: 7,
    difficulty: '초급',
    bodyParts: ['하체', '둔근'],
    category: VideoCategory.warmup,
    viewCount: 19400,
  ),
  VideoWorkout(
    id: 'v_stretch_02',
    title: '상체 심층 스트레칭 15분',
    trainerName: '정다은 트레이너',
    description:
        '책상 근무자와 상체 운동 후 모두에게 효과적인 15분 상체 집중 스트레칭입니다. 흉근, 광배근, 승모근, 목 측면을 체계적으로 이완합니다.',
    thumbnailUrl: 'https://picsum.photos/seed/stretch02/640/360',
    videoUrl: 'https://example.com/videos/upper_body_stretch_15min.mp4',
    durationMinutes: 15,
    difficulty: '초급',
    bodyParts: ['가슴', '등', '어깨'],
    category: VideoCategory.stretching,
    viewCount: 16900,
  ),
];

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 전체 영상 운동 목록 Provider
final videoWorkoutsProvider = Provider<List<VideoWorkout>>((ref) {
  return _builtInVideoWorkouts;
});

/// 카테고리별 그룹화된 영상 운동 Provider
final videoWorkoutCategoriesProvider =
    Provider<Map<VideoCategory, List<VideoWorkout>>>((ref) {
  final all = ref.watch(videoWorkoutsProvider);
  final grouped = <VideoCategory, List<VideoWorkout>>{};

  for (final video in all) {
    grouped.putIfAbsent(video.category, () => []).add(video);
  }

  return grouped;
});

/// 추천 영상 Provider (랜덤 선택, 프리미엄 제외)
final featuredVideoProvider = Provider<VideoWorkout?>((ref) {
  final all = ref.watch(videoWorkoutsProvider);
  final freVideos = all.where((v) => !v.isPremium).toList();
  if (freVideos.isEmpty) return null;

  // 조회수가 높은 상위 5개 중에서 랜덤 선택하여 다양성 제공
  final sorted = List<VideoWorkout>.from(freVideos)
    ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
  final topFive = sorted.take(5).toList();
  final random = Random();
  return topFive[random.nextInt(topFive.length)];
});

/// 특정 카테고리 영상 목록 Provider
final videosByCategory =
    Provider.family<List<VideoWorkout>, VideoCategory?>((ref, category) {
  final all = ref.watch(videoWorkoutsProvider);
  if (category == null) return all;
  return all.where((v) => v.category == category).toList();
});
