// 레시피 및 식단 플래너 상태 관리
// Recipe, RecipeIngredient, MealPlan, MealPlanPreference 모델
// 20개 내장 레시피 + 식단 생성 로직

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/models/diet_model.dart';

// ---------------------------------------------------------------------------
// 열거형
// ---------------------------------------------------------------------------

/// 레시피 난이도
enum RecipeDifficulty { easy, medium, hard }

/// 레시피 식사 타입 (MealType과 독립적 – 레시피에 특화)
enum RecipeMealType { breakfast, lunch, dinner, snack }

// ---------------------------------------------------------------------------
// 데이터 모델
// ---------------------------------------------------------------------------

/// 레시피 재료 항목
class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });
}

/// 레시피 정보
class Recipe {
  final String id;
  final String name; // 한국어 이름
  final String nameEn; // 영어 이름
  final String description;
  final String? imageUrl; // null이면 플레이스홀더 사용
  final List<RecipeIngredient> ingredients;
  final List<String> instructions; // 조리 단계별 설명
  final int prepTimeMinutes; // 준비 시간
  final int cookTimeMinutes; // 조리 시간
  final int servings; // 인분
  final double totalCalories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> tags; // 예: ['고단백', '저칼로리', '비건']
  final RecipeDifficulty difficulty;
  final RecipeMealType mealType;

  const Recipe({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tags = const [],
    required this.difficulty,
    required this.mealType,
  });

  /// 총 조리 시간 (분)
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;
}

/// 날짜별 식단 계획
class MealPlan {
  final DateTime date;
  final Map<RecipeMealType, Recipe> meals; // 각 식사 타입별 레시피

  const MealPlan({
    required this.date,
    required this.meals,
  });

  /// 하루 총 칼로리
  double get totalCalories =>
      meals.values.fold(0, (sum, r) => sum + r.totalCalories);

  /// 하루 총 단백질
  double get totalProtein =>
      meals.values.fold(0, (sum, r) => sum + r.protein);

  /// 하루 총 탄수화물
  double get totalCarbs =>
      meals.values.fold(0, (sum, r) => sum + r.carbs);

  /// 하루 총 지방
  double get totalFat =>
      meals.values.fold(0, (sum, r) => sum + r.fat);

  MealPlan copyWith({
    DateTime? date,
    Map<RecipeMealType, Recipe>? meals,
  }) {
    return MealPlan(
      date: date ?? this.date,
      meals: meals ?? this.meals,
    );
  }
}

/// 식단 계획 선호도 설정
class MealPlanPreference {
  final double targetCalories;
  final List<String> dietaryRestrictions; // 예: ['비건', '글루텐 프리']
  final List<String> excludedIngredients; // 제외할 재료

  const MealPlanPreference({
    this.targetCalories = 2000,
    this.dietaryRestrictions = const [],
    this.excludedIngredients = const [],
  });

  MealPlanPreference copyWith({
    double? targetCalories,
    List<String>? dietaryRestrictions,
    List<String>? excludedIngredients,
  }) {
    return MealPlanPreference(
      targetCalories: targetCalories ?? this.targetCalories,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
    );
  }
}

// ---------------------------------------------------------------------------
// 내장 레시피 시드 데이터 (20개)
// ---------------------------------------------------------------------------

/// 아침 레시피 (5개)
const List<Recipe> _breakfastRecipes = [
  // 1. 오트밀
  Recipe(
    id: 'recipe_b001',
    name: '오트밀 볼',
    nameEn: 'Oatmeal Bowl',
    description: '귀리와 우유로 만드는 영양 가득 아침 식사. 바나나와 견과류로 풍미를 더했습니다.',
    ingredients: [
      RecipeIngredient(name: '귀리 (오트밀)', amount: 80, unit: 'g'),
      RecipeIngredient(name: '저지방 우유', amount: 200, unit: 'ml'),
      RecipeIngredient(name: '바나나', amount: 120, unit: 'g'),
      RecipeIngredient(name: '아몬드', amount: 15, unit: 'g'),
      RecipeIngredient(name: '꿀', amount: 10, unit: 'g'),
    ],
    instructions: [
      '냄비에 우유를 붓고 중불로 가열합니다.',
      '귀리를 넣고 5분간 저으면서 끓입니다.',
      '그릇에 담고 슬라이스한 바나나를 올립니다.',
      '아몬드를 뿌리고 꿀을 살짝 드리즐합니다.',
    ],
    prepTimeMinutes: 2,
    cookTimeMinutes: 8,
    servings: 1,
    totalCalories: 450,
    protein: 16,
    carbs: 70,
    fat: 12,
    tags: ['고탄수', '에너지', '채식'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.breakfast,
  ),

  // 2. 계란 토스트
  Recipe(
    id: 'recipe_b002',
    name: '계란 아보카도 토스트',
    nameEn: 'Egg Avocado Toast',
    description: '통밀 토스트에 아보카도와 반숙 계란을 올린 단백질 풍부한 아침 메뉴.',
    ingredients: [
      RecipeIngredient(name: '통밀 식빵', amount: 80, unit: 'g'),
      RecipeIngredient(name: '계란', amount: 100, unit: 'g'),
      RecipeIngredient(name: '아보카도', amount: 80, unit: 'g'),
      RecipeIngredient(name: '소금', amount: 1, unit: 'g'),
      RecipeIngredient(name: '후추', amount: 0.5, unit: 'g'),
      RecipeIngredient(name: '레몬즙', amount: 5, unit: 'ml'),
    ],
    instructions: [
      '식빵을 토스터에 넣고 노릇하게 구워냅니다.',
      '아보카도를 반으로 잘라 씨를 제거하고 숟가락으로 과육을 꺼냅니다.',
      '아보카도에 레몬즙, 소금, 후추를 넣고 포크로 으깹니다.',
      '프라이팬에 계란을 반숙으로 조리합니다.',
      '토스트에 아보카도 스프레드를 바르고 계란을 올립니다.',
    ],
    prepTimeMinutes: 5,
    cookTimeMinutes: 5,
    servings: 1,
    totalCalories: 380,
    protein: 18,
    carbs: 32,
    fat: 20,
    tags: ['고단백', '건강지방', '포만감'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.breakfast,
  ),

  // 3. 그릭요거트 볼
  Recipe(
    id: 'recipe_b003',
    name: '그릭요거트 볼',
    nameEn: 'Greek Yogurt Bowl',
    description: '무가당 그릭요거트에 신선한 베리류와 그래놀라를 곁들인 고단백 아침 메뉴.',
    ingredients: [
      RecipeIngredient(name: '무가당 그릭요거트', amount: 200, unit: 'g'),
      RecipeIngredient(name: '블루베리', amount: 80, unit: 'g'),
      RecipeIngredient(name: '딸기', amount: 80, unit: 'g'),
      RecipeIngredient(name: '그래놀라', amount: 30, unit: 'g'),
      RecipeIngredient(name: '꿀', amount: 10, unit: 'g'),
      RecipeIngredient(name: '치아씨드', amount: 5, unit: 'g'),
    ],
    instructions: [
      '그릭요거트를 그릇에 담습니다.',
      '블루베리와 슬라이스한 딸기를 올립니다.',
      '그래놀라를 뿌립니다.',
      '꿀을 드리즐하고 치아씨드를 뿌려 완성합니다.',
    ],
    prepTimeMinutes: 5,
    cookTimeMinutes: 0,
    servings: 1,
    totalCalories: 320,
    protein: 20,
    carbs: 45,
    fat: 6,
    tags: ['고단백', '프로바이오틱', '무조리'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.breakfast,
  ),

  // 4. 닭가슴살 샐러드 랩
  Recipe(
    id: 'recipe_b004',
    name: '닭가슴살 샐러드 랩',
    nameEn: 'Chicken Breast Salad Wrap',
    description: '저지방 고단백 닭가슴살과 신선한 채소를 통밀 또띠아에 싸서 만드는 간편한 아침.',
    ingredients: [
      RecipeIngredient(name: '닭가슴살 (삶은)', amount: 100, unit: 'g'),
      RecipeIngredient(name: '통밀 또띠아', amount: 60, unit: 'g'),
      RecipeIngredient(name: '로메인 상추', amount: 50, unit: 'g'),
      RecipeIngredient(name: '방울토마토', amount: 60, unit: 'g'),
      RecipeIngredient(name: '오이', amount: 50, unit: 'g'),
      RecipeIngredient(name: '허니머스타드 소스', amount: 15, unit: 'g'),
    ],
    instructions: [
      '닭가슴살을 얇게 슬라이스합니다.',
      '로메인 상추, 방울토마토, 오이를 준비합니다.',
      '또띠아를 전자레인지에 30초 데웁니다.',
      '또띠아에 허니머스타드 소스를 바릅니다.',
      '채소와 닭가슴살을 올리고 단단하게 롤링합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 0,
    servings: 1,
    totalCalories: 310,
    protein: 28,
    carbs: 34,
    fat: 6,
    tags: ['고단백', '저지방', '다이어트'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.breakfast,
  ),

  // 5. 바나나 스무디
  Recipe(
    id: 'recipe_b005',
    name: '바나나 프로틴 스무디',
    nameEn: 'Banana Protein Smoothie',
    description: '바나나와 프로틴 파우더를 블렌딩한 에너지 넘치는 아침 음료.',
    ingredients: [
      RecipeIngredient(name: '바나나', amount: 120, unit: 'g'),
      RecipeIngredient(name: '저지방 우유', amount: 250, unit: 'ml'),
      RecipeIngredient(name: '프로틴 파우더 (바닐라)', amount: 33, unit: 'g'),
      RecipeIngredient(name: '땅콩버터', amount: 16, unit: 'g'),
      RecipeIngredient(name: '얼음', amount: 100, unit: 'g'),
    ],
    instructions: [
      '바나나를 조각내어 블렌더에 넣습니다.',
      '우유, 프로틴 파우더, 땅콩버터, 얼음을 넣습니다.',
      '30초간 강하게 블렌딩합니다.',
      '컵에 따라 바로 마십니다.',
    ],
    prepTimeMinutes: 5,
    cookTimeMinutes: 0,
    servings: 1,
    totalCalories: 420,
    protein: 35,
    carbs: 50,
    fat: 9,
    tags: ['고단백', '에너지', '음료'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.breakfast,
  ),
];

/// 점심 레시피 (5개)
const List<Recipe> _lunchRecipes = [
  // 1. 닭가슴살 도시락
  Recipe(
    id: 'recipe_l001',
    name: '닭가슴살 도시락',
    nameEn: 'Chicken Breast Lunchbox',
    description: '삶은 닭가슴살, 현미밥, 브로콜리로 구성된 균형 잡힌 헬스 도시락.',
    ingredients: [
      RecipeIngredient(name: '닭가슴살', amount: 150, unit: 'g'),
      RecipeIngredient(name: '현미밥', amount: 210, unit: 'g'),
      RecipeIngredient(name: '브로콜리', amount: 100, unit: 'g'),
      RecipeIngredient(name: '당근', amount: 50, unit: 'g'),
      RecipeIngredient(name: '올리브오일', amount: 5, unit: 'ml'),
      RecipeIngredient(name: '소금', amount: 2, unit: 'g'),
      RecipeIngredient(name: '후추', amount: 1, unit: 'g'),
    ],
    instructions: [
      '닭가슴살에 소금, 후추로 밑간을 합니다.',
      '끓는 물에 닭가슴살을 15분간 삶습니다.',
      '브로콜리와 당근을 한 입 크기로 잘라 데칩니다.',
      '채소에 올리브오일, 소금으로 간을 합니다.',
      '도시락 용기에 현미밥, 닭가슴살, 채소를 담습니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    servings: 1,
    totalCalories: 520,
    protein: 45,
    carbs: 65,
    fat: 8,
    tags: ['고단백', '저지방', '다이어트', '도시락'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.lunch,
  ),

  // 2. 연어 포케볼
  Recipe(
    id: 'recipe_l002',
    name: '연어 포케볼',
    nameEn: 'Salmon Poke Bowl',
    description: '신선한 연어와 아보카도, 현미밥을 하와이안 스타일로 구성한 영양 만점 볼.',
    ingredients: [
      RecipeIngredient(name: '신선한 연어', amount: 120, unit: 'g'),
      RecipeIngredient(name: '현미밥', amount: 180, unit: 'g'),
      RecipeIngredient(name: '아보카도', amount: 80, unit: 'g'),
      RecipeIngredient(name: '오이', amount: 60, unit: 'g'),
      RecipeIngredient(name: '에다마메', amount: 50, unit: 'g'),
      RecipeIngredient(name: '간장', amount: 15, unit: 'ml'),
      RecipeIngredient(name: '참기름', amount: 5, unit: 'ml'),
      RecipeIngredient(name: '깨', amount: 3, unit: 'g'),
    ],
    instructions: [
      '연어를 1.5cm 큐브로 잘라 간장, 참기름에 5분 마리네이드합니다.',
      '오이를 슬라이스하고 아보카도를 큐브로 자릅니다.',
      '에다마메를 끓는 물에 3분간 데칩니다.',
      '그릇에 현미밥을 깔고 모든 재료를 가지런히 올립니다.',
      '깨를 뿌려 완성합니다.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 5,
    servings: 1,
    totalCalories: 590,
    protein: 38,
    carbs: 58,
    fat: 20,
    tags: ['오메가3', '고단백', '건강지방'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.lunch,
  ),

  // 3. 비빔밥
  Recipe(
    id: 'recipe_l003',
    name: '건강 비빔밥',
    nameEn: 'Healthy Bibimbap',
    description: '계란, 다양한 나물, 현미밥으로 만드는 건강한 한식 비빔밥.',
    ingredients: [
      RecipeIngredient(name: '현미밥', amount: 210, unit: 'g'),
      RecipeIngredient(name: '계란', amount: 50, unit: 'g'),
      RecipeIngredient(name: '시금치 나물', amount: 80, unit: 'g'),
      RecipeIngredient(name: '콩나물', amount: 80, unit: 'g'),
      RecipeIngredient(name: '당근 채', amount: 60, unit: 'g'),
      RecipeIngredient(name: '오이 채', amount: 60, unit: 'g'),
      RecipeIngredient(name: '고추장', amount: 20, unit: 'g'),
      RecipeIngredient(name: '참기름', amount: 5, unit: 'ml'),
    ],
    instructions: [
      '시금치, 콩나물을 각각 데쳐 참기름, 소금으로 무칩니다.',
      '당근과 오이를 채 썰어 프라이팬에 살짝 볶습니다.',
      '계란을 반숙으로 프라이합니다.',
      '그릇에 현미밥을 담고 각 나물을 돌려 담습니다.',
      '가운데 계란을 올리고 고추장을 곁들입니다.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 510,
    protein: 18,
    carbs: 85,
    fat: 10,
    tags: ['한식', '채식', '균형'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.lunch,
  ),

  // 4. 고구마 치킨 볼
  Recipe(
    id: 'recipe_l004',
    name: '고구마 치킨 볼',
    nameEn: 'Sweet Potato Chicken Bowl',
    description: '구운 고구마와 닭가슴살, 시금치를 조합한 든든한 헬시 볼.',
    ingredients: [
      RecipeIngredient(name: '닭가슴살', amount: 150, unit: 'g'),
      RecipeIngredient(name: '고구마', amount: 200, unit: 'g'),
      RecipeIngredient(name: '시금치', amount: 80, unit: 'g'),
      RecipeIngredient(name: '방울토마토', amount: 80, unit: 'g'),
      RecipeIngredient(name: '올리브오일', amount: 10, unit: 'ml'),
      RecipeIngredient(name: '마늘 (다진)', amount: 5, unit: 'g'),
      RecipeIngredient(name: '소금', amount: 2, unit: 'g'),
      RecipeIngredient(name: '파프리카 파우더', amount: 2, unit: 'g'),
    ],
    instructions: [
      '고구마를 큐브로 잘라 200°C 오븐에서 25분 굽습니다.',
      '닭가슴살에 파프리카 파우더, 소금으로 밑간합니다.',
      '프라이팬에 올리브오일로 닭가슴살을 양면 익힙니다.',
      '같은 팬에 마늘, 시금치를 볶습니다.',
      '그릇에 모든 재료를 담고 방울토마토로 장식합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 30,
    servings: 1,
    totalCalories: 490,
    protein: 40,
    carbs: 55,
    fat: 11,
    tags: ['고단백', '복합탄수화물', '포만감'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.lunch,
  ),

  // 5. 두부 스테이크
  Recipe(
    id: 'recipe_l005',
    name: '두부 스테이크 덮밥',
    nameEn: 'Tofu Steak Rice Bowl',
    description: '두부를 바삭하게 구워 특제 소스와 함께 밥 위에 올린 고단백 채식 메뉴.',
    ingredients: [
      RecipeIngredient(name: '단단한 두부', amount: 200, unit: 'g'),
      RecipeIngredient(name: '현미밥', amount: 210, unit: 'g'),
      RecipeIngredient(name: '간장', amount: 20, unit: 'ml'),
      RecipeIngredient(name: '미림', amount: 10, unit: 'ml'),
      RecipeIngredient(name: '설탕', amount: 5, unit: 'g'),
      RecipeIngredient(name: '참기름', amount: 5, unit: 'ml'),
      RecipeIngredient(name: '대파', amount: 20, unit: 'g'),
      RecipeIngredient(name: '깨', amount: 3, unit: 'g'),
    ],
    instructions: [
      '두부를 키친타올로 눌러 물기를 제거합니다.',
      '두부를 1.5cm 두께로 슬라이스합니다.',
      '간장, 미림, 설탕, 참기름을 섞어 소스를 만듭니다.',
      '프라이팬에 두부를 노릇하게 양면 굽습니다.',
      '소스를 붓고 졸입니다.',
      '밥 위에 두부를 올리고 대파, 깨를 뿌립니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 450,
    protein: 22,
    carbs: 70,
    fat: 10,
    tags: ['채식', '비건', '고단백'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.lunch,
  ),
];

/// 저녁 레시피 (5개)
const List<Recipe> _dinnerRecipes = [
  // 1. 스테이크 + 채소
  Recipe(
    id: 'recipe_d001',
    name: '그릴 스테이크 & 채소',
    nameEn: 'Grilled Steak & Vegetables',
    description: '양념한 소고기 안심과 계절 채소를 그릴에 구운 고단백 저녁 메뉴.',
    ingredients: [
      RecipeIngredient(name: '소고기 안심', amount: 180, unit: 'g'),
      RecipeIngredient(name: '아스파라거스', amount: 100, unit: 'g'),
      RecipeIngredient(name: '방울토마토', amount: 100, unit: 'g'),
      RecipeIngredient(name: '버섯', amount: 100, unit: 'g'),
      RecipeIngredient(name: '올리브오일', amount: 10, unit: 'ml'),
      RecipeIngredient(name: '소금', amount: 3, unit: 'g'),
      RecipeIngredient(name: '후추', amount: 2, unit: 'g'),
      RecipeIngredient(name: '로즈마리', amount: 2, unit: 'g'),
    ],
    instructions: [
      '스테이크를 실온에 30분 방치합니다.',
      '소금, 후추, 로즈마리로 스테이크를 양념합니다.',
      '채소에 올리브오일, 소금으로 밑간합니다.',
      '강한 불의 그릴팬에 스테이크를 원하는 익힘 정도로 굽습니다.',
      '채소는 스테이크 옆에서 동시에 굽습니다.',
      '스테이크를 3분 레스팅 후 서빙합니다.',
    ],
    prepTimeMinutes: 35,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 480,
    protein: 42,
    carbs: 12,
    fat: 28,
    tags: ['고단백', '저탄수', '케토'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.dinner,
  ),

  // 2. 연어 구이
  Recipe(
    id: 'recipe_d002',
    name: '레몬 허브 연어 구이',
    nameEn: 'Lemon Herb Baked Salmon',
    description: '레몬과 허브로 향을 낸 오븐 구이 연어. 오메가3가 풍부한 건강식.',
    ingredients: [
      RecipeIngredient(name: '연어 필렛', amount: 180, unit: 'g'),
      RecipeIngredient(name: '레몬', amount: 50, unit: 'g'),
      RecipeIngredient(name: '올리브오일', amount: 10, unit: 'ml'),
      RecipeIngredient(name: '딜 (허브)', amount: 5, unit: 'g'),
      RecipeIngredient(name: '마늘 (다진)', amount: 5, unit: 'g'),
      RecipeIngredient(name: '소금', amount: 2, unit: 'g'),
      RecipeIngredient(name: '후추', amount: 1, unit: 'g'),
    ],
    instructions: [
      '오븐을 200°C로 예열합니다.',
      '연어에 올리브오일, 마늘, 소금, 후추를 바릅니다.',
      '레몬 슬라이스와 딜을 연어 위에 올립니다.',
      '오븐 팬에 연어를 올리고 12~15분 굽습니다.',
      '레몬즙을 살짝 뿌려 서빙합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 380,
    protein: 40,
    carbs: 3,
    fat: 22,
    tags: ['오메가3', '고단백', '저탄수', '글루텐프리'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.dinner,
  ),

  // 3. 닭가슴살 파스타
  Recipe(
    id: 'recipe_d003',
    name: '닭가슴살 토마토 파스타',
    nameEn: 'Chicken Breast Tomato Pasta',
    description: '닭가슴살과 토마토소스로 만드는 고단백 이탈리안 파스타.',
    ingredients: [
      RecipeIngredient(name: '통밀 파스타', amount: 80, unit: 'g'),
      RecipeIngredient(name: '닭가슴살', amount: 120, unit: 'g'),
      RecipeIngredient(name: '토마토 소스', amount: 150, unit: 'g'),
      RecipeIngredient(name: '마늘', amount: 10, unit: 'g'),
      RecipeIngredient(name: '양파', amount: 60, unit: 'g'),
      RecipeIngredient(name: '올리브오일', amount: 10, unit: 'ml'),
      RecipeIngredient(name: '바질', amount: 5, unit: 'g'),
      RecipeIngredient(name: '파르메산 치즈', amount: 15, unit: 'g'),
    ],
    instructions: [
      '파스타를 소금물에 알덴테로 삶습니다.',
      '닭가슴살을 한 입 크기로 자릅니다.',
      '올리브오일에 마늘, 양파를 볶습니다.',
      '닭가슴살을 넣고 완전히 익힙니다.',
      '토마토 소스를 넣고 5분 졸입니다.',
      '파스타를 넣고 버무립니다.',
      '바질, 파르메산 치즈를 뿌려 완성합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    servings: 1,
    totalCalories: 540,
    protein: 38,
    carbs: 68,
    fat: 12,
    tags: ['이탈리안', '고단백', '균형'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.dinner,
  ),

  // 4. 소고기 볶음밥
  Recipe(
    id: 'recipe_d004',
    name: '소고기 현미 볶음밥',
    nameEn: 'Beef Brown Rice Fried Rice',
    description: '다진 소고기와 채소를 넣은 영양 가득 볶음밥.',
    ingredients: [
      RecipeIngredient(name: '현미밥', amount: 210, unit: 'g'),
      RecipeIngredient(name: '소고기 다진 것', amount: 100, unit: 'g'),
      RecipeIngredient(name: '계란', amount: 100, unit: 'g'),
      RecipeIngredient(name: '당근', amount: 50, unit: 'g'),
      RecipeIngredient(name: '완두콩', amount: 50, unit: 'g'),
      RecipeIngredient(name: '간장', amount: 15, unit: 'ml'),
      RecipeIngredient(name: '참기름', amount: 5, unit: 'ml'),
      RecipeIngredient(name: '식용유', amount: 10, unit: 'ml'),
    ],
    instructions: [
      '당근을 잘게 다집니다.',
      '강한 불에 식용유를 두르고 소고기를 볶습니다.',
      '당근, 완두콩을 넣고 함께 볶습니다.',
      '밥을 넣고 간장을 더해 볶습니다.',
      '가운데를 비우고 계란을 스크램블합니다.',
      '전체를 섞고 참기름으로 마무리합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 580,
    protein: 32,
    carbs: 75,
    fat: 16,
    tags: ['한식', '균형', '포만감'],
    difficulty: RecipeDifficulty.medium,
    mealType: RecipeMealType.dinner,
  ),

  // 5. 두부 찌개
  Recipe(
    id: 'recipe_d005',
    name: '순두부 찌개',
    nameEn: 'Soft Tofu Jjigae',
    description: '부드러운 순두부와 해산물로 만드는 전통 한국식 찌개.',
    ingredients: [
      RecipeIngredient(name: '순두부', amount: 300, unit: 'g'),
      RecipeIngredient(name: '바지락', amount: 100, unit: 'g'),
      RecipeIngredient(name: '계란', amount: 50, unit: 'g'),
      RecipeIngredient(name: '고추장', amount: 15, unit: 'g'),
      RecipeIngredient(name: '고춧가루', amount: 5, unit: 'g'),
      RecipeIngredient(name: '마늘', amount: 5, unit: 'g'),
      RecipeIngredient(name: '참기름', amount: 5, unit: 'ml'),
      RecipeIngredient(name: '멸치 육수', amount: 300, unit: 'ml'),
    ],
    instructions: [
      '냄비에 참기름, 마늘을 볶습니다.',
      '고추장, 고춧가루를 넣고 볶습니다.',
      '멸치 육수를 붓고 끓입니다.',
      '바지락을 넣고 입이 열릴 때까지 끓입니다.',
      '순두부를 숟가락으로 떠서 넣습니다.',
      '마지막에 계란을 깨 넣고 살짝 익혀 서빙합니다.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 15,
    servings: 1,
    totalCalories: 240,
    protein: 20,
    carbs: 12,
    fat: 12,
    tags: ['한식', '저칼로리', '단백질'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.dinner,
  ),
];

/// 간식 레시피 (5개)
const List<Recipe> _snackRecipes = [
  // 1. 프로틴바
  Recipe(
    id: 'recipe_s001',
    name: '홈메이드 프로틴바',
    nameEn: 'Homemade Protein Bar',
    description: '귀리, 프로틴 파우더, 땅콩버터로 만드는 고단백 홈메이드 스낵.',
    ingredients: [
      RecipeIngredient(name: '귀리 가루', amount: 100, unit: 'g'),
      RecipeIngredient(name: '프로틴 파우더', amount: 66, unit: 'g'),
      RecipeIngredient(name: '땅콩버터', amount: 64, unit: 'g'),
      RecipeIngredient(name: '꿀', amount: 40, unit: 'g'),
      RecipeIngredient(name: '다크초콜릿 칩', amount: 30, unit: 'g'),
    ],
    instructions: [
      '모든 재료를 볼에 넣고 잘 섞습니다.',
      '유산지를 깐 팬에 반죽을 펼쳐 누릅니다.',
      '냉동실에서 30분 굳힙니다.',
      '적당한 크기로 잘라 보관합니다.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 0,
    servings: 6,
    totalCalories: 200,
    protein: 18,
    carbs: 22,
    fat: 8,
    tags: ['고단백', '에너지바', '홈메이드'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.snack,
  ),

  // 2. 견과류 믹스
  Recipe(
    id: 'recipe_s002',
    name: '허니 로스티드 견과류 믹스',
    nameEn: 'Honey Roasted Nut Mix',
    description: '아몬드, 호두, 캐슈넛을 꿀에 버무려 구운 건강 스낵.',
    ingredients: [
      RecipeIngredient(name: '아몬드', amount: 28, unit: 'g'),
      RecipeIngredient(name: '호두', amount: 14, unit: 'g'),
      RecipeIngredient(name: '캐슈넛', amount: 14, unit: 'g'),
      RecipeIngredient(name: '꿀', amount: 10, unit: 'g'),
      RecipeIngredient(name: '시나몬', amount: 1, unit: 'g'),
      RecipeIngredient(name: '소금', amount: 0.5, unit: 'g'),
    ],
    instructions: [
      '오븐을 160°C로 예열합니다.',
      '견과류에 꿀, 시나몬, 소금을 버무립니다.',
      '오븐 팬에 펼쳐 10~12분 굽습니다.',
      '완전히 식힌 후 보관합니다.',
    ],
    prepTimeMinutes: 5,
    cookTimeMinutes: 12,
    servings: 2,
    totalCalories: 220,
    protein: 6,
    carbs: 16,
    fat: 16,
    tags: ['건강지방', '에너지', '간편'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.snack,
  ),

  // 3. 삶은 계란
  Recipe(
    id: 'recipe_s003',
    name: '완숙 계란 & 소금',
    nameEn: 'Hard-Boiled Eggs',
    description: '단순하고 영양 밀도 높은 최고의 단백질 스낵.',
    ingredients: [
      RecipeIngredient(name: '계란', amount: 100, unit: 'g'),
      RecipeIngredient(name: '소금', amount: 1, unit: 'g'),
    ],
    instructions: [
      '냄비에 물을 끓입니다.',
      '계란을 조심스럽게 넣고 12분 삶습니다.',
      '찬물에 바로 담가 식힙니다.',
      '껍질을 벗기고 소금과 함께 먹습니다.',
    ],
    prepTimeMinutes: 2,
    cookTimeMinutes: 12,
    servings: 1,
    totalCalories: 150,
    protein: 13,
    carbs: 1,
    fat: 10,
    tags: ['고단백', '간편', '저탄수'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.snack,
  ),

  // 4. 고구마
  Recipe(
    id: 'recipe_s004',
    name: '찐 고구마',
    nameEn: 'Steamed Sweet Potato',
    description: '자연 단맛의 고구마는 운동 전후 완벽한 복합 탄수화물 스낵.',
    ingredients: [
      RecipeIngredient(name: '고구마', amount: 150, unit: 'g'),
    ],
    instructions: [
      '고구마를 깨끗이 씻습니다.',
      '찜기에 물을 올리고 고구마를 넣습니다.',
      '20~25분간 쪄냅니다.',
      '이쑤시개로 찔러 보아 부드러우면 완성입니다.',
    ],
    prepTimeMinutes: 3,
    cookTimeMinutes: 25,
    servings: 1,
    totalCalories: 129,
    protein: 2.4,
    carbs: 30,
    fat: 0.2,
    tags: ['복합탄수화물', '운동전후', '채식'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.snack,
  ),

  // 5. 프로틴 쉐이크
  Recipe(
    id: 'recipe_s005',
    name: '초콜릿 프로틴 쉐이크',
    nameEn: 'Chocolate Protein Shake',
    description: '운동 후 근육 회복을 위한 빠르게 흡수되는 고단백 음료.',
    ingredients: [
      RecipeIngredient(name: '프로틴 파우더 (초코)', amount: 33, unit: 'g'),
      RecipeIngredient(name: '저지방 우유', amount: 250, unit: 'ml'),
      RecipeIngredient(name: '코코아 파우더', amount: 5, unit: 'g'),
      RecipeIngredient(name: '얼음', amount: 100, unit: 'g'),
    ],
    instructions: [
      '모든 재료를 블렌더에 넣습니다.',
      '30초간 블렌딩합니다.',
      '컵에 따라 바로 마십니다.',
    ],
    prepTimeMinutes: 3,
    cookTimeMinutes: 0,
    servings: 1,
    totalCalories: 230,
    protein: 30,
    carbs: 18,
    fat: 4,
    tags: ['고단백', '운동후', '음료'],
    difficulty: RecipeDifficulty.easy,
    mealType: RecipeMealType.snack,
  ),
];

/// 전체 내장 레시피 목록
const List<Recipe> kBuiltInRecipes = [
  ..._breakfastRecipes,
  ..._lunchRecipes,
  ..._dinnerRecipes,
  ..._snackRecipes,
];

// ---------------------------------------------------------------------------
// MealPlanState
// ---------------------------------------------------------------------------

/// 식단 플래너 전체 상태
class MealPlanState {
  final MealPlan? currentPlan; // 오늘의 식단 계획
  final MealPlanPreference preference; // 사용자 선호도
  final bool isGenerating; // 생성 중 여부

  const MealPlanState({
    this.currentPlan,
    this.preference = const MealPlanPreference(),
    this.isGenerating = false,
  });

  MealPlanState copyWith({
    MealPlan? currentPlan,
    MealPlanPreference? preference,
    bool? isGenerating,
    bool clearPlan = false,
  }) {
    return MealPlanState(
      currentPlan: clearPlan ? null : (currentPlan ?? this.currentPlan),
      preference: preference ?? this.preference,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

// ---------------------------------------------------------------------------
// MealPlanNotifier
// ---------------------------------------------------------------------------

/// 식단 플래너 상태 관리
/// 칼로리 배분: 아침 30%, 점심 35%, 저녁 25%, 간식 10%
class MealPlanNotifier extends StateNotifier<MealPlanState> {
  MealPlanNotifier() : super(const MealPlanState());

  /// 선호도 업데이트
  void updatePreference(MealPlanPreference preference) {
    state = state.copyWith(preference: preference);
  }

  /// 목표 칼로리 업데이트
  void setTargetCalories(double calories) {
    state = state.copyWith(
      preference: state.preference.copyWith(targetCalories: calories),
    );
  }

  /// 선호도에 맞는 식단 계획 생성
  Future<void> generatePlan([MealPlanPreference? preference]) async {
    final pref = preference ?? state.preference;
    state = state.copyWith(isGenerating: true);

    try {
      // 칼로리 배분 비율
      final breakfastTarget = pref.targetCalories * 0.30;
      final lunchTarget = pref.targetCalories * 0.35;
      final dinnerTarget = pref.targetCalories * 0.25;
      final snackTarget = pref.targetCalories * 0.10;

      // 각 식사 타입별 가장 적합한 레시피 선택
      final breakfast = _pickBestRecipe(
        RecipeMealType.breakfast,
        breakfastTarget,
        pref,
      );
      final lunch = _pickBestRecipe(
        RecipeMealType.lunch,
        lunchTarget,
        pref,
      );
      final dinner = _pickBestRecipe(
        RecipeMealType.dinner,
        dinnerTarget,
        pref,
      );
      final snack = _pickBestRecipe(
        RecipeMealType.snack,
        snackTarget,
        pref,
      );

      final meals = <RecipeMealType, Recipe>{};
      if (breakfast != null) meals[RecipeMealType.breakfast] = breakfast;
      if (lunch != null) meals[RecipeMealType.lunch] = lunch;
      if (dinner != null) meals[RecipeMealType.dinner] = dinner;
      if (snack != null) meals[RecipeMealType.snack] = snack;

      state = state.copyWith(
        currentPlan: MealPlan(date: DateTime.now(), meals: meals),
        isGenerating: false,
        preference: pref,
      );
    } catch (_) {
      state = state.copyWith(isGenerating: false);
    }
  }

  /// 특정 식사 교체 (대안 레시피로 스왑)
  void swapMeal(RecipeMealType mealType, Recipe newRecipe) {
    final current = state.currentPlan;
    if (current == null) return;

    final updatedMeals = Map<RecipeMealType, Recipe>.from(current.meals);
    updatedMeals[mealType] = newRecipe;

    state = state.copyWith(
      currentPlan: current.copyWith(meals: updatedMeals),
    );
  }

  /// 식단 계획 저장 (현재는 메모리 내 유지, 필요 시 SharedPreferences 연동 가능)
  void savePlan() {
    // TODO: SharedPreferences 또는 Firebase에 저장
  }

  // ---------------------------------------------------------------------------
  // 내부 헬퍼
  // ---------------------------------------------------------------------------

  /// 목표 칼로리에 가장 가까운 레시피 선택
  Recipe? _pickBestRecipe(
    RecipeMealType mealType,
    double targetCalories,
    MealPlanPreference pref,
  ) {
    final candidates = kBuiltInRecipes
        .where((r) => r.mealType == mealType)
        .where((r) => _matchesPreference(r, pref))
        .toList();

    if (candidates.isEmpty) return null;

    // 목표 칼로리와의 차이가 가장 적은 레시피 선택
    candidates.sort((a, b) {
      final diffA = (a.totalCalories - targetCalories).abs();
      final diffB = (b.totalCalories - targetCalories).abs();
      return diffA.compareTo(diffB);
    });

    return candidates.first;
  }

  /// 선호도 필터 (제외 재료 체크)
  bool _matchesPreference(Recipe recipe, MealPlanPreference pref) {
    if (pref.excludedIngredients.isEmpty) return true;

    // 제외 재료가 포함된 레시피 필터링
    for (final excluded in pref.excludedIngredients) {
      final hasExcluded = recipe.ingredients.any(
        (ing) => ing.name.contains(excluded),
      );
      if (hasExcluded) return false;
    }

    return true;
  }
}

// ---------------------------------------------------------------------------
// 레시피 필터 상태
// ---------------------------------------------------------------------------

/// 레시피 목록 필터 상태
class RecipeFilterState {
  final RecipeMealType? selectedMealType;
  final double? maxCalories;
  final List<String> selectedTags;

  const RecipeFilterState({
    this.selectedMealType,
    this.maxCalories,
    this.selectedTags = const [],
  });

  RecipeFilterState copyWith({
    RecipeMealType? selectedMealType,
    double? maxCalories,
    List<String>? selectedTags,
    bool clearMealType = false,
    bool clearCalories = false,
  }) {
    return RecipeFilterState(
      selectedMealType:
          clearMealType ? null : (selectedMealType ?? this.selectedMealType),
      maxCalories:
          clearCalories ? null : (maxCalories ?? this.maxCalories),
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

class RecipeFilterNotifier extends StateNotifier<RecipeFilterState> {
  RecipeFilterNotifier() : super(const RecipeFilterState());

  void setMealType(RecipeMealType? type) {
    state = state.copyWith(
      selectedMealType: type,
      clearMealType: type == null,
    );
  }

  void setMaxCalories(double? max) {
    state = state.copyWith(
      maxCalories: max,
      clearCalories: max == null,
    );
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  void clearAll() {
    state = const RecipeFilterState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 전체 레시피 목록
final recipesProvider = Provider<List<Recipe>>((ref) => kBuiltInRecipes);

/// 레시피 필터 Provider
final recipeFilterProvider =
    StateNotifierProvider<RecipeFilterNotifier, RecipeFilterState>(
  (ref) => RecipeFilterNotifier(),
);

/// 필터 적용된 레시피 목록
final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final recipes = ref.watch(recipesProvider);
  final filter = ref.watch(recipeFilterProvider);

  return recipes.where((recipe) {
    // 식사 타입 필터
    if (filter.selectedMealType != null &&
        recipe.mealType != filter.selectedMealType) {
      return false;
    }

    // 칼로리 필터
    if (filter.maxCalories != null &&
        recipe.totalCalories > filter.maxCalories!) {
      return false;
    }

    // 태그 필터
    if (filter.selectedTags.isNotEmpty) {
      final hasAllTags = filter.selectedTags
          .every((tag) => recipe.tags.contains(tag));
      if (!hasAllTags) return false;
    }

    return true;
  }).toList();
});

/// 식단 플래너 Provider
final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, MealPlanState>(
  (ref) => MealPlanNotifier(),
);

/// 오늘의 식단 계획 Provider
final todayMealPlanProvider = Provider<MealPlan?>((ref) {
  return ref.watch(mealPlanProvider).currentPlan;
});

/// 식사 타입별 대안 레시피 Provider (스왑용)
final alternativeRecipesProvider =
    Provider.family<List<Recipe>, RecipeMealType>((ref, mealType) {
  final allRecipes = ref.watch(recipesProvider);
  final currentPlan = ref.watch(todayMealPlanProvider);
  final currentRecipe = currentPlan?.meals[mealType];

  return allRecipes
      .where((r) => r.mealType == mealType && r.id != currentRecipe?.id)
      .toList();
});

// ---------------------------------------------------------------------------
// FoodItem 변환 헬퍼 (레시피 -> 식단 연동용)
// ---------------------------------------------------------------------------

/// 레시피 1인분을 FoodItem으로 변환 (식단 로그 연동용)
FoodItem recipeToFoodItem(Recipe recipe) {
  return FoodItem(
    id: 'recipe_food_${recipe.id}',
    name: recipe.name,
    nameEn: recipe.nameEn,
    servingSize: 1,
    servingUnit: '인분',
    calories: recipe.totalCalories,
    protein: recipe.protein,
    carbs: recipe.carbs,
    fat: recipe.fat,
  );
}
