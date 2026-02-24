// 식단 관련 데이터 모델
// FoodItem, Meal, DailyNutrition, WaterIntake 등의 불변 클래스 정의

import 'package:health_app/core/constants/app_constants.dart';

/// 식사 타입 열거형
enum MealType {
  breakfast('아침'),
  lunch('점심'),
  dinner('저녁'),
  snack('간식'),
  postWorkout('운동 후 식사'),
  preWorkout('운동 전 식사');

  final String label;
  const MealType(this.label);
}

// ---------------------------------------------------------------------------
// FoodItem 모델 - 개별 음식 아이템
// ---------------------------------------------------------------------------

/// 개별 식품 정보를 표현하는 불변 클래스
class FoodItem {
  final String id;
  final String name; // 음식 이름 (한국어)
  final String? nameEn; // 음식 이름 (영어)
  final String? brand; // 브랜드/제조사
  final double servingSize; // 1회 제공량 (g 또는 ml)
  final String servingUnit; // 제공 단위 (g, ml, 개, 조각 등)

  // 영양소 (1회 제공량 기준)
  final double calories; // 칼로리 (kcal)
  final double protein; // 단백질 (g)
  final double carbs; // 탄수화물 (g)
  final double fat; // 지방 (g)
  final double? fiber; // 식이섬유 (g)
  final double? sugar; // 당류 (g)
  final double? sodium; // 나트륨 (mg)
  final double? saturatedFat; // 포화지방 (g)
  final double? transFat; // 트랜스지방 (g)
  final double? cholesterol; // 콜레스테롤 (mg)

  final String? imageUrl; // 음식 이미지 URL
  final String? barcode; // 바코드 번호
  final bool isFavorite; // 즐겨찾기 여부

  const FoodItem({
    required this.id,
    required this.name,
    this.nameEn,
    this.brand,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.saturatedFat,
    this.transFat,
    this.cholesterol,
    this.imageUrl,
    this.barcode,
    this.isFavorite = false,
  });

  /// 특정 양에 대한 칼로리 계산
  double caloriesFor(double amount) => calories * (amount / servingSize);

  /// 특정 양에 대한 단백질 계산
  double proteinFor(double amount) => protein * (amount / servingSize);

  /// 특정 양에 대한 탄수화물 계산
  double carbsFor(double amount) => carbs * (amount / servingSize);

  /// 특정 양에 대한 지방 계산
  double fatFor(double amount) => fat * (amount / servingSize);

  /// 탄단지 비율 (칼로리 기준)
  Map<String, double> get macroRatioByCalorie {
    final proteinCal = protein * 4;
    final carbsCal = carbs * 4;
    final fatCal = fat * 9;
    final total = proteinCal + carbsCal + fatCal;
    if (total == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    return {
      'protein': proteinCal / total,
      'carbs': carbsCal / total,
      'fat': fatCal / total,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? brand,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? saturatedFat,
    double? transFat,
    double? cholesterol,
    String? imageUrl,
    String? barcode,
    bool? isFavorite,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      brand: brand ?? this.brand,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      transFat: transFat ?? this.transFat,
      cholesterol: cholesterol ?? this.cholesterol,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      brand: json['brand'] as String?,
      servingSize: (json['serving_size'] as num).toDouble(),
      servingUnit: json['serving_unit'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      sugar: json['sugar'] != null ? (json['sugar'] as num).toDouble() : null,
      sodium:
          json['sodium'] != null ? (json['sodium'] as num).toDouble() : null,
      saturatedFat: json['saturated_fat'] != null
          ? (json['saturated_fat'] as num).toDouble()
          : null,
      transFat: json['trans_fat'] != null
          ? (json['trans_fat'] as num).toDouble()
          : null,
      cholesterol: json['cholesterol'] != null
          ? (json['cholesterol'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      barcode: json['barcode'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'brand': brand,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturated_fat': saturatedFat,
      'trans_fat': transFat,
      'cholesterol': cholesterol,
      'image_url': imageUrl,
      'barcode': barcode,
      'is_favorite': isFavorite,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FoodItem(id: $id, name: $name, cal: ${calories}kcal)';
}

// ---------------------------------------------------------------------------
// MealFoodEntry - 식사에 포함된 개별 음식 항목
// ---------------------------------------------------------------------------

/// 식사에 포함된 음식의 섭취량과 함께 기록
class MealFoodEntry {
  final FoodItem food;
  final double amount; // 섭취량 (servingUnit 기준)

  const MealFoodEntry({
    required this.food,
    required this.amount,
  });

  /// 섭취량에 따른 실제 칼로리
  double get actualCalories => food.caloriesFor(amount);

  /// 섭취량에 따른 실제 단백질
  double get actualProtein => food.proteinFor(amount);

  /// 섭취량에 따른 실제 탄수화물
  double get actualCarbs => food.carbsFor(amount);

  /// 섭취량에 따른 실제 지방
  double get actualFat => food.fatFor(amount);

  MealFoodEntry copyWith({FoodItem? food, double? amount}) {
    return MealFoodEntry(
      food: food ?? this.food,
      amount: amount ?? this.amount,
    );
  }

  factory MealFoodEntry.fromJson(Map<String, dynamic> json) {
    return MealFoodEntry(
      food: FoodItem.fromJson(json['food'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food': food.toJson(),
      'amount': amount,
    };
  }
}

// ---------------------------------------------------------------------------
// Meal 모델 - 식사 기록
// ---------------------------------------------------------------------------

/// 한 끼 식사 기록
class Meal {
  final String id;
  final MealType type; // 아침/점심/저녁/간식
  final DateTime dateTime; // 식사 시간
  final List<MealFoodEntry> foods; // 섭취한 음식 목록
  final String? note; // 메모
  final String? imageUrl; // 식사 사진 URL

  const Meal({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.foods,
    this.note,
    this.imageUrl,
  });

  /// 식사의 총 칼로리
  double get totalCalories =>
      foods.fold(0, (sum, entry) => sum + entry.actualCalories);

  /// 식사의 총 단백질
  double get totalProtein =>
      foods.fold(0, (sum, entry) => sum + entry.actualProtein);

  /// 식사의 총 탄수화물
  double get totalCarbs =>
      foods.fold(0, (sum, entry) => sum + entry.actualCarbs);

  /// 식사의 총 지방
  double get totalFat =>
      foods.fold(0, (sum, entry) => sum + entry.actualFat);

  Meal copyWith({
    String? id,
    MealType? type,
    DateTime? dateTime,
    List<MealFoodEntry>? foods,
    String? note,
    String? imageUrl,
  }) {
    return Meal(
      id: id ?? this.id,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      foods: foods ?? this.foods,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      type: MealType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MealType.snack,
      ),
      dateTime: DateTime.parse(json['date_time'] as String),
      foods: (json['foods'] as List<dynamic>)
          .map((e) => MealFoodEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'date_time': dateTime.toIso8601String(),
      'foods': foods.map((e) => e.toJson()).toList(),
      'note': note,
      'image_url': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Meal(id: $id, type: ${type.label}, cal: ${totalCalories.toStringAsFixed(0)}kcal)';
}

// ---------------------------------------------------------------------------
// NutritionGoal 모델 - 영양 목표
// ---------------------------------------------------------------------------

/// 일일 영양 목표
class NutritionGoal {
  final double calories; // 목표 칼로리 (kcal)
  final double protein; // 목표 단백질 (g)
  final double carbs; // 목표 탄수화물 (g)
  final double fat; // 목표 지방 (g)
  final double? fiber; // 목표 식이섬유 (g)
  final int waterMl; // 목표 수분 (ml)

  const NutritionGoal({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.waterMl = 2000,
  });

  /// 기본 목표 (2000kcal, 탄40/단30/지30)
  static const NutritionGoal standard = NutritionGoal(
    calories: 2000,
    protein: 150,
    carbs: 200,
    fat: 67,
    fiber: 25,
    waterMl: 2000,
  );

  NutritionGoal copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? waterMl,
  }) {
    return NutritionGoal(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      waterMl: waterMl ?? this.waterMl,
    );
  }

  factory NutritionGoal.fromJson(Map<String, dynamic> json) {
    return NutritionGoal(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber:
          json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      waterMl: json['water_ml'] as int? ?? 2000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'water_ml': waterMl,
    };
  }
}

// ---------------------------------------------------------------------------
// DailyNutrition 모델 - 일일 영양 요약
// ---------------------------------------------------------------------------

/// 하루의 영양 섭취 요약
class DailyNutrition {
  final DateTime date;
  final List<Meal> meals; // 하루 전체 식사 기록
  final NutritionGoal goal; // 해당 날짜의 목표

  const DailyNutrition({
    required this.date,
    required this.meals,
    required this.goal,
  });

  /// 하루 총 칼로리
  double get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);

  /// 하루 총 단백질
  double get totalProtein =>
      meals.fold(0, (sum, meal) => sum + meal.totalProtein);

  /// 하루 총 탄수화물
  double get totalCarbs =>
      meals.fold(0, (sum, meal) => sum + meal.totalCarbs);

  /// 하루 총 지방
  double get totalFat =>
      meals.fold(0, (sum, meal) => sum + meal.totalFat);

  /// 남은 칼로리
  double get remainingCalories => goal.calories - totalCalories;

  /// 칼로리 달성률
  double get calorieProgress =>
      (totalCalories / goal.calories).clamp(0.0, 1.0);

  /// 단백질 달성률
  double get proteinProgress =>
      (totalProtein / goal.protein).clamp(0.0, 1.0);

  /// 탄수화물 달성률
  double get carbsProgress => (totalCarbs / goal.carbs).clamp(0.0, 1.0);

  /// 지방 달성률
  double get fatProgress => (totalFat / goal.fat).clamp(0.0, 1.0);

  /// 식사 타입별 칼로리 반환
  double caloriesByMealType(MealType type) {
    return meals
        .where((m) => m.type == type)
        .fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  DailyNutrition copyWith({
    DateTime? date,
    List<Meal>? meals,
    NutritionGoal? goal,
  }) {
    return DailyNutrition(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      goal: goal ?? this.goal,
    );
  }

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
      goal: NutritionGoal.fromJson(json['goal'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meals': meals.map((e) => e.toJson()).toList(),
      'goal': goal.toJson(),
    };
  }

  @override
  String toString() =>
      'DailyNutrition(date: $date, cal: ${totalCalories.toStringAsFixed(0)}/${goal.calories}kcal)';
}

// ---------------------------------------------------------------------------
// WaterIntake 모델 - 수분 섭취 기록
// ---------------------------------------------------------------------------

/// 단일 수분 섭취 기록
class WaterIntakeEntry {
  final String id;
  final DateTime time; // 섭취 시각
  final int amountMl; // 섭취량 (ml)
  final String? note; // 메모 (예: "운동 전", "커피")

  const WaterIntakeEntry({
    required this.id,
    required this.time,
    required this.amountMl,
    this.note,
  });

  WaterIntakeEntry copyWith({
    String? id,
    DateTime? time,
    int? amountMl,
    String? note,
  }) {
    return WaterIntakeEntry(
      id: id ?? this.id,
      time: time ?? this.time,
      amountMl: amountMl ?? this.amountMl,
      note: note ?? this.note,
    );
  }

  factory WaterIntakeEntry.fromJson(Map<String, dynamic> json) {
    return WaterIntakeEntry(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      amountMl: json['amount_ml'] as int,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'amount_ml': amountMl,
      'note': note,
    };
  }

  @override
  String toString() => 'WaterIntakeEntry(id: $id, ${amountMl}ml @ $time)';
}

/// 하루 수분 섭취 요약
class DailyWaterIntake {
  final DateTime date;
  final List<WaterIntakeEntry> entries; // 개별 섭취 기록
  final int goalMl; // 하루 목표 섭취량 (ml)

  const DailyWaterIntake({
    required this.date,
    required this.entries,
    this.goalMl = AppDefaults.dailyWaterGoalMl,
  });

  /// 하루 총 섭취량
  int get totalMl => entries.fold(0, (sum, e) => sum + e.amountMl);

  /// 남은 섭취량
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  /// 달성률 (0.0 ~ 1.0)
  double get progress => (totalMl / goalMl).clamp(0.0, 1.0);

  /// 목표 달성 여부
  bool get isGoalReached => totalMl >= goalMl;

  DailyWaterIntake copyWith({
    DateTime? date,
    List<WaterIntakeEntry>? entries,
    int? goalMl,
  }) {
    return DailyWaterIntake(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      goalMl: goalMl ?? this.goalMl,
    );
  }

  factory DailyWaterIntake.fromJson(Map<String, dynamic> json) {
    return DailyWaterIntake(
      date: DateTime.parse(json['date'] as String),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => WaterIntakeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      goalMl: json['goal_ml'] as int? ?? 2000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'goal_ml': goalMl,
    };
  }

  @override
  String toString() =>
      'DailyWaterIntake(date: $date, $totalMl/${goalMl}ml)';
}
