// 식단 및 영양 추적 상태 관리
// DietNotifier: 일일 식단 기록 관리
// FoodDatabaseProvider: 한국 음식 중심 데이터베이스 (30개 이상)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';

// ---------------------------------------------------------------------------
// 음식 데이터베이스 시드 데이터 (32개 한국 음식 중심)
// ---------------------------------------------------------------------------

/// 전체 음식 데이터베이스
const List<FoodItem> kAllFoodItems = [
  // ── 밥/주식 ────────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_001',
    name: '흰쌀밥',
    nameEn: 'Steamed Rice',
    servingSize: 210,
    servingUnit: 'g',
    calories: 313,
    protein: 5.7,
    carbs: 68.8,
    fat: 0.6,
    fiber: 0.4,
    sodium: 3,
  ),
  FoodItem(
    id: 'food_002',
    name: '현미밥',
    nameEn: 'Brown Rice',
    servingSize: 210,
    servingUnit: 'g',
    calories: 294,
    protein: 6.3,
    carbs: 62.1,
    fat: 1.9,
    fiber: 2.1,
    sodium: 3,
  ),
  FoodItem(
    id: 'food_003',
    name: '고구마',
    nameEn: 'Sweet Potato',
    servingSize: 100,
    servingUnit: 'g',
    calories: 86,
    protein: 1.6,
    carbs: 20.1,
    fat: 0.1,
    fiber: 2.5,
    sodium: 55,
  ),
  FoodItem(
    id: 'food_004',
    name: '감자',
    nameEn: 'Potato',
    servingSize: 100,
    servingUnit: 'g',
    calories: 66,
    protein: 1.8,
    carbs: 15.2,
    fat: 0.1,
    fiber: 1.5,
    sodium: 6,
  ),
  FoodItem(
    id: 'food_005',
    name: '오트밀',
    nameEn: 'Oatmeal',
    servingSize: 40,
    servingUnit: 'g',
    calories: 152,
    protein: 5.5,
    carbs: 26.2,
    fat: 2.6,
    fiber: 3.5,
    sodium: 3,
  ),

  // ── 단백질 식품 ────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_006',
    name: '닭가슴살 (삶은)',
    nameEn: 'Boiled Chicken Breast',
    servingSize: 100,
    servingUnit: 'g',
    calories: 109,
    protein: 23.1,
    carbs: 0,
    fat: 1.2,
    sodium: 70,
  ),
  FoodItem(
    id: 'food_007',
    name: '달걀',
    nameEn: 'Egg',
    servingSize: 50,
    servingUnit: 'g',
    calories: 75,
    protein: 6.5,
    carbs: 0.4,
    fat: 5.0,
    cholesterol: 186,
    sodium: 63,
  ),
  FoodItem(
    id: 'food_008',
    name: '연어 (구운)',
    nameEn: 'Grilled Salmon',
    servingSize: 100,
    servingUnit: 'g',
    calories: 195,
    protein: 27.0,
    carbs: 0,
    fat: 9.0,
    sodium: 59,
  ),
  FoodItem(
    id: 'food_009',
    name: '참치캔 (물에 담긴)',
    nameEn: 'Canned Tuna in Water',
    servingSize: 100,
    servingUnit: 'g',
    calories: 99,
    protein: 22.0,
    carbs: 0,
    fat: 0.9,
    sodium: 247,
  ),
  FoodItem(
    id: 'food_010',
    name: '두부 (단단한)',
    nameEn: 'Firm Tofu',
    servingSize: 100,
    servingUnit: 'g',
    calories: 76,
    protein: 8.1,
    carbs: 1.9,
    fat: 4.2,
    sodium: 9,
  ),
  FoodItem(
    id: 'food_011',
    name: '소고기 (안심, 구운)',
    nameEn: 'Grilled Beef Tenderloin',
    servingSize: 100,
    servingUnit: 'g',
    calories: 179,
    protein: 26.2,
    carbs: 0,
    fat: 7.7,
    sodium: 54,
  ),
  FoodItem(
    id: 'food_012',
    name: '돼지고기 (삼겹살, 구운)',
    nameEn: 'Grilled Pork Belly',
    servingSize: 100,
    servingUnit: 'g',
    calories: 331,
    protein: 14.1,
    carbs: 0,
    fat: 29.9,
    sodium: 61,
  ),

  // ── 한식 요리 ──────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_013',
    name: '김치찌개',
    nameEn: 'Kimchi Jjigae',
    servingSize: 300,
    servingUnit: 'ml',
    calories: 174,
    protein: 12.0,
    carbs: 14.1,
    fat: 7.2,
    sodium: 1740,
  ),
  FoodItem(
    id: 'food_014',
    name: '된장찌개',
    nameEn: 'Doenjang Jjigae',
    servingSize: 300,
    servingUnit: 'ml',
    calories: 129,
    protein: 8.7,
    carbs: 10.2,
    fat: 5.6,
    sodium: 1560,
  ),
  FoodItem(
    id: 'food_015',
    name: '비빔밥',
    nameEn: 'Bibimbap',
    servingSize: 400,
    servingUnit: 'g',
    calories: 560,
    protein: 18.4,
    carbs: 89.6,
    fat: 14.4,
    sodium: 1420,
  ),
  FoodItem(
    id: 'food_016',
    name: '김치볶음밥',
    nameEn: 'Kimchi Fried Rice',
    servingSize: 300,
    servingUnit: 'g',
    calories: 468,
    protein: 11.7,
    carbs: 75.9,
    fat: 14.1,
    sodium: 1260,
  ),
  FoodItem(
    id: 'food_017',
    name: '삼겹살 구이 (쌈 포함)',
    nameEn: 'Grilled Pork Belly with Wraps',
    servingSize: 200,
    servingUnit: 'g',
    calories: 620,
    protein: 22.0,
    carbs: 8.0,
    fat: 55.0,
    sodium: 820,
  ),
  FoodItem(
    id: 'food_018',
    name: '떡볶이',
    nameEn: 'Tteokbokki',
    servingSize: 250,
    servingUnit: 'g',
    calories: 380,
    protein: 8.0,
    carbs: 76.5,
    fat: 5.0,
    sodium: 1890,
  ),
  FoodItem(
    id: 'food_019',
    name: '순두부찌개',
    nameEn: 'Sundubu Jjigae',
    servingSize: 300,
    servingUnit: 'ml',
    calories: 141,
    protein: 11.4,
    carbs: 7.8,
    fat: 6.6,
    sodium: 1520,
  ),
  FoodItem(
    id: 'food_020',
    name: '불고기',
    nameEn: 'Bulgogi',
    servingSize: 150,
    servingUnit: 'g',
    calories: 255,
    protein: 19.5,
    carbs: 13.5,
    fat: 12.0,
    sodium: 750,
  ),

  // ── 채소/반찬 ──────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_021',
    name: '김치',
    nameEn: 'Kimchi',
    servingSize: 50,
    servingUnit: 'g',
    calories: 16,
    protein: 1.1,
    carbs: 2.7,
    fat: 0.3,
    fiber: 1.2,
    sodium: 490,
  ),
  FoodItem(
    id: 'food_022',
    name: '시금치 나물',
    nameEn: 'Spinach Namul',
    servingSize: 80,
    servingUnit: 'g',
    calories: 32,
    protein: 2.7,
    carbs: 2.6,
    fat: 1.0,
    fiber: 1.8,
    sodium: 280,
  ),
  FoodItem(
    id: 'food_023',
    name: '브로콜리 (생)',
    nameEn: 'Raw Broccoli',
    servingSize: 100,
    servingUnit: 'g',
    calories: 34,
    protein: 2.8,
    carbs: 6.6,
    fat: 0.4,
    fiber: 2.6,
    sodium: 33,
  ),
  FoodItem(
    id: 'food_024',
    name: '아보카도',
    nameEn: 'Avocado',
    servingSize: 100,
    servingUnit: 'g',
    calories: 160,
    protein: 2.0,
    carbs: 8.5,
    fat: 14.7,
    fiber: 6.7,
    sodium: 7,
  ),

  // ── 과일 ──────────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_025',
    name: '바나나',
    nameEn: 'Banana',
    servingSize: 120,
    servingUnit: 'g',
    calories: 107,
    protein: 1.3,
    carbs: 27.2,
    fat: 0.4,
    fiber: 3.1,
    sugar: 14.4,
    sodium: 1,
  ),
  FoodItem(
    id: 'food_026',
    name: '사과',
    nameEn: 'Apple',
    servingSize: 180,
    servingUnit: 'g',
    calories: 95,
    protein: 0.5,
    carbs: 25.1,
    fat: 0.3,
    fiber: 4.4,
    sugar: 18.9,
    sodium: 2,
  ),
  FoodItem(
    id: 'food_027',
    name: '블루베리',
    nameEn: 'Blueberry',
    servingSize: 100,
    servingUnit: 'g',
    calories: 57,
    protein: 0.7,
    carbs: 14.5,
    fat: 0.3,
    fiber: 2.4,
    sugar: 9.96,
    sodium: 1,
  ),

  // ── 유제품/보충제 ──────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_028',
    name: '그릭 요거트 (무가당)',
    nameEn: 'Plain Greek Yogurt',
    servingSize: 170,
    servingUnit: 'g',
    calories: 100,
    protein: 17.0,
    carbs: 6.0,
    fat: 0.7,
    sodium: 60,
  ),
  FoodItem(
    id: 'food_029',
    name: '우유 (저지방)',
    nameEn: 'Low-Fat Milk',
    servingSize: 240,
    servingUnit: 'ml',
    calories: 102,
    protein: 8.2,
    carbs: 12.5,
    fat: 2.4,
    sodium: 107,
  ),
  FoodItem(
    id: 'food_030',
    name: '프로틴 쉐이크 (바닐라)',
    nameEn: 'Protein Shake Vanilla',
    brand: '일반',
    servingSize: 33,
    servingUnit: 'g',
    calories: 120,
    protein: 25.0,
    carbs: 3.0,
    fat: 1.5,
    sodium: 130,
  ),
  FoodItem(
    id: 'food_031',
    name: '코티지 치즈',
    nameEn: 'Cottage Cheese',
    servingSize: 113,
    servingUnit: 'g',
    calories: 98,
    protein: 11.0,
    carbs: 3.4,
    fat: 4.5,
    sodium: 318,
  ),

  // ── 견과류/기타 ────────────────────────────────────────────────────────────
  FoodItem(
    id: 'food_032',
    name: '아몬드',
    nameEn: 'Almond',
    servingSize: 28,
    servingUnit: 'g',
    calories: 164,
    protein: 6.0,
    carbs: 6.1,
    fat: 14.2,
    fiber: 3.5,
    sodium: 0,
  ),
  FoodItem(
    id: 'food_033',
    name: '땅콩버터',
    nameEn: 'Peanut Butter',
    servingSize: 32,
    servingUnit: 'g',
    calories: 188,
    protein: 8.0,
    carbs: 6.9,
    fat: 16.1,
    fiber: 1.9,
    sugar: 3.4,
    sodium: 147,
  ),
  FoodItem(
    id: 'food_034',
    name: '현미 프로틴 바',
    nameEn: 'Brown Rice Protein Bar',
    brand: '일반',
    servingSize: 60,
    servingUnit: 'g',
    calories: 220,
    protein: 20.0,
    carbs: 24.0,
    fat: 6.0,
    fiber: 3.0,
    sodium: 200,
  ),
];

// ---------------------------------------------------------------------------
// DailyDietState - 일일 식단 상태
// ---------------------------------------------------------------------------

/// 하루 식단 전체 상태
class DailyDietState {
  final DateTime date;
  final List<Meal> meals; // 하루 식사 기록
  final NutritionGoal goal; // 영양 목표
  final bool isLoading;

  const DailyDietState({
    required this.date,
    this.meals = const [],
    this.goal = NutritionGoal.standard,
    this.isLoading = false,
  });

  /// 총 칼로리
  double get totalCalories =>
      meals.fold(0, (sum, m) => sum + m.totalCalories);

  /// 총 단백질
  double get totalProtein =>
      meals.fold(0, (sum, m) => sum + m.totalProtein);

  /// 총 탄수화물
  double get totalCarbs =>
      meals.fold(0, (sum, m) => sum + m.totalCarbs);

  /// 총 지방
  double get totalFat =>
      meals.fold(0, (sum, m) => sum + m.totalFat);

  /// 남은 칼로리
  double get remainingCalories => goal.calories - totalCalories;

  /// 칼로리 달성률 (0~1)
  double get calorieProgress =>
      (totalCalories / goal.calories).clamp(0.0, 1.0);

  /// 단백질 달성률 (0~1)
  double get proteinProgress =>
      (totalProtein / goal.protein).clamp(0.0, 1.0);

  /// 탄수화물 달성률 (0~1)
  double get carbsProgress =>
      (totalCarbs / goal.carbs).clamp(0.0, 1.0);

  /// 지방 달성률 (0~1)
  double get fatProgress => (totalFat / goal.fat).clamp(0.0, 1.0);

  /// 식사 타입별 조회
  List<Meal> getMealsByType(MealType type) =>
      meals.where((m) => m.type == type).toList();

  /// 매크로 비율 (단백질/탄수화물/지방)
  Map<String, double> get macroRatios {
    final proteinCal = totalProtein * 4;
    final carbsCal = totalCarbs * 4;
    final fatCal = totalFat * 9;
    final total = proteinCal + carbsCal + fatCal;

    if (total == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': proteinCal / total,
      'carbs': carbsCal / total,
      'fat': fatCal / total,
    };
  }

  DailyDietState copyWith({
    DateTime? date,
    List<Meal>? meals,
    NutritionGoal? goal,
    bool? isLoading,
  }) {
    return DailyDietState(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      goal: goal ?? this.goal,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'goal': goal.toJson(),
      };

  factory DailyDietState.fromJson(Map<String, dynamic> json) => DailyDietState(
        date: DateTime.parse(json['date'] as String),
        meals: (json['meals'] as List<dynamic>)
            .map((m) => Meal.fromJson(m as Map<String, dynamic>))
            .toList(),
        goal: NutritionGoal.fromJson(json['goal'] as Map<String, dynamic>),
      );
}

// ---------------------------------------------------------------------------
// DietNotifier - 일일 식단 상태 관리
// ---------------------------------------------------------------------------

class DietNotifier extends StateNotifier<DailyDietState> {
  DietNotifier(this._repo)
      : super(DailyDietState(date: DateTime.now())) {
    _load();
  }

  final DietRepository _repo;

  // ── 영속성 ────────────────────────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      'diet_${date.year}_${date.month}_${date.day}';

  /// Repository에서 오늘 식단 로드
  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      // 영양 목표 로드
      final goal = await _repo.loadNutritionGoal();

      // 오늘 식단 로드
      final today = DateTime.now();
      final meals = await _repo.loadMeals(_dateKey(today));

      state = DailyDietState(
        date: today,
        meals: meals,
        goal: goal,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Repository에 저장
  Future<void> _save() async {
    try {
      await _repo.saveMeals(_dateKey(state.date), state.meals);
      await _repo.saveNutritionGoal(state.goal);
    } catch (_) {}
  }

  // ── 날짜 전환 ─────────────────────────────────────────────────────────────

  /// 특정 날짜 식단 로드
  Future<void> loadDate(DateTime date) async {
    try {
      final meals = await _repo.loadMeals(_dateKey(date));
      state = DailyDietState(
        date: date,
        meals: meals,
        goal: state.goal,
      );
    } catch (_) {}
  }

  // ── 식사 관리 ─────────────────────────────────────────────────────────────

  /// 식사 추가
  Future<void> addMeal(MealType type) async {
    final meal = Meal(
      id: const Uuid().v4(),
      type: type,
      dateTime: DateTime.now(),
      foods: const [],
    );
    state = state.copyWith(meals: [...state.meals, meal]);
    await _save();
  }

  /// 식사에 음식 추가
  Future<void> addFoodToMeal(
      String mealId, FoodItem food, double amount) async {
    final meals = state.meals.map((meal) {
      if (meal.id != mealId) return meal;

      final entry = MealFoodEntry(food: food, amount: amount);
      return meal.copyWith(foods: [...meal.foods, entry]);
    }).toList();

    state = state.copyWith(meals: meals);
    await _save();
  }

  /// 식사에서 음식 삭제
  Future<void> removeFoodFromMeal(String mealId, int foodIndex) async {
    final meals = state.meals.map((meal) {
      if (meal.id != mealId) return meal;

      final newFoods = List<MealFoodEntry>.from(meal.foods)
        ..removeAt(foodIndex);
      return meal.copyWith(foods: newFoods);
    }).toList();

    state = state.copyWith(meals: meals);
    await _save();
  }

  /// 음식 섭취량 수정
  Future<void> updateFoodAmount(
      String mealId, int foodIndex, double newAmount) async {
    final meals = state.meals.map((meal) {
      if (meal.id != mealId) return meal;

      final newFoods = meal.foods.asMap().entries.map((e) {
        if (e.key != foodIndex) return e.value;
        return e.value.copyWith(amount: newAmount);
      }).toList();

      return meal.copyWith(foods: newFoods);
    }).toList();

    state = state.copyWith(meals: meals);
    await _save();
  }

  /// 식사 전체 삭제
  Future<void> removeMeal(String mealId) async {
    state = state.copyWith(
      meals: state.meals.where((m) => m.id != mealId).toList(),
    );
    await _save();
  }

  // ── 목표 관리 ─────────────────────────────────────────────────────────────

  /// 영양 목표 업데이트
  Future<void> updateGoal(NutritionGoal newGoal) async {
    state = state.copyWith(goal: newGoal);
    await _save();
  }

  /// 체중 기반 목표 자동 설정 (린벌크 기준)
  Future<void> setGoalByWeight(double bodyWeightKg) async {
    // 린벌크 기준: 칼로리 = 체중 × 33, 단백질 = 체중 × 2g
    final calories = bodyWeightKg * 33;
    final protein = bodyWeightKg * 2;
    final carbs = (calories * 0.45) / 4; // 45% 탄수화물
    final fat = (calories * 0.25) / 9; // 25% 지방

    await updateGoal(NutritionGoal(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      waterMl: 2000,
    ));
  }

  // ── 통계 ─────────────────────────────────────────────────────────────────

  /// 주간 평균 칼로리 계산
  Future<double> getWeeklyAverageCalories() async {
    try {
      final total = <double>[];

      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final meals = await _repo.loadMeals(_dateKey(date));
        if (meals.isNotEmpty) {
          final dayCals = meals.fold<double>(
              0, (sum, m) => sum + m.totalCalories);
          total.add(dayCals);
        }
      }

      if (total.isEmpty) return 0;
      return total.reduce((a, b) => a + b) / total.length;
    } catch (_) {
      return 0;
    }
  }
}

// ---------------------------------------------------------------------------
// FoodDatabaseNotifier - 음식 데이터베이스 관리
// ---------------------------------------------------------------------------

class FoodDatabaseState {
  final List<FoodItem> allFoods;
  final String searchQuery;
  final List<FoodItem> recentFoods; // 최근 사용한 음식

  const FoodDatabaseState({
    required this.allFoods,
    this.searchQuery = '',
    this.recentFoods = const [],
  });

  List<FoodItem> get filteredFoods {
    if (searchQuery.isEmpty) return allFoods;

    final query = searchQuery.toLowerCase();
    return allFoods.where((food) {
      return food.name.toLowerCase().contains(query) ||
          (food.nameEn?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  FoodDatabaseState copyWith({
    List<FoodItem>? allFoods,
    String? searchQuery,
    List<FoodItem>? recentFoods,
  }) {
    return FoodDatabaseState(
      allFoods: allFoods ?? this.allFoods,
      searchQuery: searchQuery ?? this.searchQuery,
      recentFoods: recentFoods ?? this.recentFoods,
    );
  }
}

class FoodDatabaseNotifier extends StateNotifier<FoodDatabaseState> {
  FoodDatabaseNotifier(this._repo)
      : super(const FoodDatabaseState(allFoods: kAllFoodItems)) {
    _loadRecentFoods();
  }

  final DietRepository _repo;

  Future<void> _loadRecentFoods() async {
    try {
      final recentIds = await _repo.loadRecentFoodIds();
      final recentFoods = recentIds
          .map((id) {
            try {
              return state.allFoods.firstWhere((f) => f.id == id);
            } catch (_) {
              return null;
            }
          })
          .whereType<FoodItem>()
          .toList();
      state = state.copyWith(recentFoods: recentFoods);
    } catch (_) {}
  }

  /// 검색
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 최근 음식에 추가
  Future<void> addToRecent(FoodItem food) async {
    final updated = [
      food,
      ...state.recentFoods.where((f) => f.id != food.id),
    ].take(10).toList();

    state = state.copyWith(recentFoods: updated);

    try {
      await _repo.saveRecentFoodIds(updated.map((f) => f.id).toList());
    } catch (_) {}
  }

  /// ID로 음식 조회
  FoodItem? getFoodById(String id) {
    try {
      return state.allFoods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 고단백 음식 상위 10개
  List<FoodItem> get highProteinFoods {
    final sorted = List<FoodItem>.from(state.allFoods)
      ..sort((a, b) {
        final aPer100 = a.protein / a.servingSize * 100;
        final bPer100 = b.protein / b.servingSize * 100;
        return bPer100.compareTo(aPer100);
      });
    return sorted.take(10).toList();
  }

  /// 저칼로리 음식 상위 10개
  List<FoodItem> get lowCalorieFoods {
    final sorted = List<FoodItem>.from(state.allFoods)
      ..sort((a, b) => a.calories.compareTo(b.calories));
    return sorted.take(10).toList();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 오늘 식단 Provider
final dietProvider =
    StateNotifierProvider<DietNotifier, DailyDietState>(
  (ref) {
    final repo = ref.watch(dietRepositoryProvider);
    return DietNotifier(repo);
  },
);

/// 음식 데이터베이스 Provider
final foodDatabaseProvider =
    StateNotifierProvider<FoodDatabaseNotifier, FoodDatabaseState>(
  (ref) {
    final repo = ref.watch(dietRepositoryProvider);
    return FoodDatabaseNotifier(repo);
  },
);

/// 검색된 음식 목록 Provider
final filteredFoodsProvider = Provider<List<FoodItem>>((ref) {
  return ref.watch(foodDatabaseProvider).filteredFoods;
});

/// 고단백 음식 Provider
final highProteinFoodsProvider = Provider<List<FoodItem>>((ref) {
  ref.watch(foodDatabaseProvider);
  return ref.read(foodDatabaseProvider.notifier).highProteinFoods;
});

/// 최근 음식 Provider
final recentFoodsProvider = Provider<List<FoodItem>>((ref) {
  return ref.watch(foodDatabaseProvider).recentFoods;
});

/// 오늘 총 칼로리 Provider
final todayCaloriesProvider = Provider<double>((ref) {
  return ref.watch(dietProvider).totalCalories;
});

/// 오늘 칼로리 달성률 Provider
final calorieProgressProvider = Provider<double>((ref) {
  return ref.watch(dietProvider).calorieProgress;
});

/// 아침 식사 Provider
final breakfastMealsProvider = Provider<List<Meal>>((ref) {
  return ref.watch(dietProvider).getMealsByType(MealType.breakfast);
});

/// 점심 식사 Provider
final lunchMealsProvider = Provider<List<Meal>>((ref) {
  return ref.watch(dietProvider).getMealsByType(MealType.lunch);
});

/// 저녁 식사 Provider
final dinnerMealsProvider = Provider<List<Meal>>((ref) {
  return ref.watch(dietProvider).getMealsByType(MealType.dinner);
});

/// 간식 Provider
final snackMealsProvider = Provider<List<Meal>>((ref) {
  return ref.watch(dietProvider).getMealsByType(MealType.snack);
});
