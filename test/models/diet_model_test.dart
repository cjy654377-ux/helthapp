import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/models/diet_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FoodItem tests
  // ---------------------------------------------------------------------------
  group('FoodItem', () {
    const chicken = FoodItem(
      id: 'chicken_breast',
      name: '닭가슴살',
      nameEn: 'Chicken Breast',
      servingSize: 100.0,
      servingUnit: 'g',
      calories: 165.0,
      protein: 31.0,
      carbs: 0.0,
      fat: 3.6,
    );

    test('creation with required fields', () {
      expect(chicken.id, 'chicken_breast');
      expect(chicken.name, '닭가슴살');
      expect(chicken.servingSize, 100.0);
      expect(chicken.servingUnit, 'g');
      expect(chicken.calories, 165.0);
      expect(chicken.protein, 31.0);
      expect(chicken.carbs, 0.0);
      expect(chicken.fat, 3.6);
      expect(chicken.isFavorite, isFalse);
    });

    test('caloriesFor scales by amount relative to serving size', () {
      // 200g serving = 2x calories
      expect(chicken.caloriesFor(200.0), closeTo(330.0, 0.001));
      // 50g serving = 0.5x calories
      expect(chicken.caloriesFor(50.0), closeTo(82.5, 0.001));
      // exactly 100g = base calories
      expect(chicken.caloriesFor(100.0), closeTo(165.0, 0.001));
    });

    test('proteinFor scales correctly', () {
      expect(chicken.proteinFor(200.0), closeTo(62.0, 0.001));
      expect(chicken.proteinFor(150.0), closeTo(46.5, 0.001));
    });

    test('carbsFor scales correctly', () {
      const rice = FoodItem(
        id: 'rice',
        name: '쌀밥',
        servingSize: 100.0,
        servingUnit: 'g',
        calories: 130.0,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
      );
      expect(rice.carbsFor(200.0), closeTo(56.0, 0.001));
    });

    test('fatFor scales correctly', () {
      const egg = FoodItem(
        id: 'egg',
        name: '계란',
        servingSize: 50.0,
        servingUnit: '개',
        calories: 78.0,
        protein: 6.0,
        carbs: 0.6,
        fat: 5.0,
      );
      expect(egg.fatFor(100.0), closeTo(10.0, 0.001));
    });

    test('macroRatioByCalorie is correct proportions', () {
      // protein = 31g * 4 = 124 kcal
      // carbs = 0g * 4 = 0 kcal
      // fat = 3.6g * 9 = 32.4 kcal
      // total = 156.4 kcal
      final ratio = chicken.macroRatioByCalorie;
      expect(ratio['protein']!, closeTo(124 / 156.4, 0.001));
      expect(ratio['carbs']!, closeTo(0.0, 0.001));
      expect(ratio['fat']!, closeTo(32.4 / 156.4, 0.001));

      // Ratios sum to ~1.0
      final sum = ratio['protein']! + ratio['carbs']! + ratio['fat']!;
      expect(sum, closeTo(1.0, 0.001));
    });

    test('macroRatioByCalorie returns zeros when all macros are zero', () {
      const zeroFood = FoodItem(
        id: 'zero',
        name: '무영양',
        servingSize: 100.0,
        servingUnit: 'g',
        calories: 0.0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
      );
      final ratio = zeroFood.macroRatioByCalorie;
      expect(ratio['protein'], 0.0);
      expect(ratio['carbs'], 0.0);
      expect(ratio['fat'], 0.0);
    });

    test('equality is based on id', () {
      const food1 = FoodItem(
        id: 'same_id',
        name: '음식1',
        servingSize: 100.0,
        servingUnit: 'g',
        calories: 100.0,
        protein: 10.0,
        carbs: 10.0,
        fat: 5.0,
      );
      const food2 = FoodItem(
        id: 'same_id',
        name: '완전히 다른 음식',
        servingSize: 200.0,
        servingUnit: 'ml',
        calories: 500.0,
        protein: 50.0,
        carbs: 50.0,
        fat: 20.0,
      );
      expect(food1, equals(food2));
    });

    test('toJson / fromJson roundtrip', () {
      const original = FoodItem(
        id: 'full_food',
        name: '완전식품',
        nameEn: 'Full Food',
        brand: 'BrandX',
        servingSize: 150.0,
        servingUnit: 'g',
        calories: 200.0,
        protein: 20.0,
        carbs: 15.0,
        fat: 8.0,
        fiber: 3.0,
        sugar: 5.0,
        sodium: 300.0,
        saturatedFat: 2.0,
        transFat: 0.0,
        cholesterol: 50.0,
        imageUrl: 'https://example.com/food.jpg',
        barcode: '1234567890',
        isFavorite: true,
      );

      final json = original.toJson();
      final restored = FoodItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.nameEn, original.nameEn);
      expect(restored.brand, original.brand);
      expect(restored.servingSize, original.servingSize);
      expect(restored.servingUnit, original.servingUnit);
      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
      expect(restored.fiber, original.fiber);
      expect(restored.sugar, original.sugar);
      expect(restored.sodium, original.sodium);
      expect(restored.saturatedFat, original.saturatedFat);
      expect(restored.transFat, original.transFat);
      expect(restored.cholesterol, original.cholesterol);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.barcode, original.barcode);
      expect(restored.isFavorite, original.isFavorite);
    });

    test('fromJson with integer nutrient values converts to double', () {
      final json = {
        'id': 'int_food',
        'name': '정수 음식',
        'serving_size': 100,
        'serving_unit': 'g',
        'calories': 100,
        'protein': 10,
        'carbs': 20,
        'fat': 5,
        'is_favorite': false,
      };
      final food = FoodItem.fromJson(json);
      expect(food.calories, isA<double>());
      expect(food.protein, isA<double>());
      expect(food.carbs, isA<double>());
      expect(food.fat, isA<double>());
    });

    test('copyWith only changes specified fields', () {
      final updated = chicken.copyWith(isFavorite: true, brand: 'FreshFarm');
      expect(updated.isFavorite, isTrue);
      expect(updated.brand, 'FreshFarm');
      expect(updated.id, chicken.id);
      expect(updated.calories, chicken.calories);
    });
  });

  // ---------------------------------------------------------------------------
  // MealFoodEntry tests
  // ---------------------------------------------------------------------------
  group('MealFoodEntry', () {
    const food = FoodItem(
      id: 'oats',
      name: '오트밀',
      servingSize: 40.0,
      servingUnit: 'g',
      calories: 150.0,
      protein: 5.0,
      carbs: 27.0,
      fat: 2.5,
    );

    test('actualCalories reflects amount', () {
      const entry = MealFoodEntry(food: food, amount: 80.0); // 2 servings
      expect(entry.actualCalories, closeTo(300.0, 0.001));
    });

    test('actualProtein reflects amount', () {
      const entry = MealFoodEntry(food: food, amount: 80.0);
      expect(entry.actualProtein, closeTo(10.0, 0.001));
    });

    test('actualCarbs reflects amount', () {
      const entry = MealFoodEntry(food: food, amount: 80.0);
      expect(entry.actualCarbs, closeTo(54.0, 0.001));
    });

    test('actualFat reflects amount', () {
      const entry = MealFoodEntry(food: food, amount: 80.0);
      expect(entry.actualFat, closeTo(5.0, 0.001));
    });

    test('toJson / fromJson roundtrip', () {
      const original = MealFoodEntry(food: food, amount: 120.0);
      final json = original.toJson();
      final restored = MealFoodEntry.fromJson(json);
      expect(restored.food.id, original.food.id);
      expect(restored.amount, original.amount);
    });
  });

  // ---------------------------------------------------------------------------
  // Meal tests
  // ---------------------------------------------------------------------------
  group('Meal', () {
    const food1 = FoodItem(
      id: 'food1',
      name: '음식1',
      servingSize: 100.0,
      servingUnit: 'g',
      calories: 200.0,
      protein: 20.0,
      carbs: 30.0,
      fat: 5.0,
    );
    const food2 = FoodItem(
      id: 'food2',
      name: '음식2',
      servingSize: 100.0,
      servingUnit: 'g',
      calories: 100.0,
      protein: 5.0,
      carbs: 20.0,
      fat: 2.0,
    );

    test('totalCalories sums all food entries', () {
      final meal = Meal(
        id: 'meal1',
        type: MealType.lunch,
        dateTime: DateTime(2024, 1, 1, 12, 0),
        foods: const [
          MealFoodEntry(food: food1, amount: 100.0), // 200 kcal
          MealFoodEntry(food: food2, amount: 200.0), // 200 kcal
        ],
      );
      expect(meal.totalCalories, closeTo(400.0, 0.001));
    });

    test('totalProtein sums all food entries', () {
      final meal = Meal(
        id: 'meal2',
        type: MealType.breakfast,
        dateTime: DateTime(2024, 1, 1, 8, 0),
        foods: const [
          MealFoodEntry(food: food1, amount: 150.0), // 30g protein
          MealFoodEntry(food: food2, amount: 100.0), // 5g protein
        ],
      );
      expect(meal.totalProtein, closeTo(35.0, 0.001));
    });

    test('empty meal has zero totals', () {
      final meal = Meal(
        id: 'empty_meal',
        type: MealType.snack,
        dateTime: DateTime(2024, 1, 1, 15, 0),
        foods: const [],
      );
      expect(meal.totalCalories, 0.0);
      expect(meal.totalProtein, 0.0);
      expect(meal.totalCarbs, 0.0);
      expect(meal.totalFat, 0.0);
    });

    test('equality is based on id', () {
      final meal1 = Meal(
        id: 'same',
        type: MealType.breakfast,
        dateTime: DateTime(2024, 1, 1),
        foods: const [],
      );
      final meal2 = Meal(
        id: 'same',
        type: MealType.dinner,
        dateTime: DateTime(2025, 6, 1),
        foods: const [],
        note: 'different note',
      );
      expect(meal1, equals(meal2));
    });

    test('toJson / fromJson roundtrip', () {
      final original = Meal(
        id: 'meal_rt',
        type: MealType.lunch,
        dateTime: DateTime(2024, 3, 15, 12, 30),
        foods: const [
          MealFoodEntry(food: food1, amount: 200.0),
        ],
        note: '점심',
      );
      final json = original.toJson();
      final restored = Meal.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.dateTime, original.dateTime);
      expect(restored.foods.length, original.foods.length);
      expect(restored.note, original.note);
    });

    test('fromJson with unknown meal type falls back to snack', () {
      final json = {
        'id': 'unknown_type_meal',
        'type': 'completely_unknown',
        'date_time': DateTime(2024, 1, 1).toIso8601String(),
        'foods': <dynamic>[],
        'note': null,
        'image_url': null,
      };
      final meal = Meal.fromJson(json);
      expect(meal.type, MealType.snack);
    });
  });

  // ---------------------------------------------------------------------------
  // NutritionGoal tests
  // ---------------------------------------------------------------------------
  group('NutritionGoal', () {
    test('standard constant has correct default values', () {
      expect(NutritionGoal.standard.calories, 2000.0);
      expect(NutritionGoal.standard.protein, 150.0);
      expect(NutritionGoal.standard.carbs, 200.0);
      expect(NutritionGoal.standard.fat, 67.0);
      expect(NutritionGoal.standard.waterMl, 2000);
    });

    test('toJson / fromJson roundtrip', () {
      const original = NutritionGoal(
        calories: 2500.0,
        protein: 180.0,
        carbs: 250.0,
        fat: 80.0,
        fiber: 30.0,
        waterMl: 2500,
      );

      final json = original.toJson();
      final restored = NutritionGoal.fromJson(json);

      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
      expect(restored.fiber, original.fiber);
      expect(restored.waterMl, original.waterMl);
    });

    test('fromJson defaults waterMl to 2000 when missing', () {
      final json = {
        'calories': 2000.0,
        'protein': 150.0,
        'carbs': 200.0,
        'fat': 67.0,
      };
      final goal = NutritionGoal.fromJson(json);
      expect(goal.waterMl, 2000);
    });
  });

  // ---------------------------------------------------------------------------
  // DailyNutrition tests
  // ---------------------------------------------------------------------------
  group('DailyNutrition', () {
    const goal = NutritionGoal(
      calories: 2000.0,
      protein: 150.0,
      carbs: 200.0,
      fat: 67.0,
    );

    const food = FoodItem(
      id: 'test_food',
      name: '테스트 음식',
      servingSize: 100.0,
      servingUnit: 'g',
      calories: 400.0,
      protein: 30.0,
      carbs: 50.0,
      fat: 10.0,
    );

    test('progress ratios are clamped between 0 and 1', () {
      // Over goal scenario
      final over = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: [
          Meal(
            id: 'm1',
            type: MealType.breakfast,
            dateTime: DateTime(2024, 1, 1, 8, 0),
            foods: const [
              MealFoodEntry(food: food, amount: 1000.0), // 4000 kcal
            ],
          ),
        ],
        goal: goal,
      );
      expect(over.calorieProgress, closeTo(1.0, 0.001)); // clamped to 1.0

      // Under goal scenario
      final under = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: const [],
        goal: goal,
      );
      expect(under.calorieProgress, closeTo(0.0, 0.001));
    });

    test('calorieProgress is correct partial fill', () {
      final daily = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: [
          Meal(
            id: 'm1',
            type: MealType.lunch,
            dateTime: DateTime(2024, 1, 1, 12, 0),
            foods: const [
              MealFoodEntry(food: food, amount: 100.0), // 400 kcal
            ],
          ),
        ],
        goal: goal, // 2000 kcal goal
      );
      // 400 / 2000 = 0.2
      expect(daily.calorieProgress, closeTo(0.2, 0.001));
    });

    test('proteinProgress calculates correctly', () {
      final daily = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: [
          Meal(
            id: 'm1',
            type: MealType.breakfast,
            dateTime: DateTime(2024, 1, 1, 8, 0),
            foods: const [
              MealFoodEntry(food: food, amount: 100.0), // 30g protein
            ],
          ),
        ],
        goal: goal, // 150g goal
      );
      // 30 / 150 = 0.2
      expect(daily.proteinProgress, closeTo(0.2, 0.001));
    });

    test('remainingCalories is difference from goal', () {
      final daily = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: [
          Meal(
            id: 'm1',
            type: MealType.lunch,
            dateTime: DateTime(2024, 1, 1, 12, 0),
            foods: const [
              MealFoodEntry(food: food, amount: 100.0), // 400 kcal
            ],
          ),
        ],
        goal: goal,
      );
      expect(daily.remainingCalories, closeTo(1600.0, 0.001));
    });

    test('caloriesByMealType sums correct meal type', () {
      final daily = DailyNutrition(
        date: DateTime(2024, 1, 1),
        meals: [
          Meal(
            id: 'm_breakfast',
            type: MealType.breakfast,
            dateTime: DateTime(2024, 1, 1, 8, 0),
            foods: const [MealFoodEntry(food: food, amount: 100.0)], // 400 kcal
          ),
          Meal(
            id: 'm_lunch',
            type: MealType.lunch,
            dateTime: DateTime(2024, 1, 1, 12, 0),
            foods: const [MealFoodEntry(food: food, amount: 100.0)], // 400 kcal
          ),
          Meal(
            id: 'm_snack',
            type: MealType.snack,
            dateTime: DateTime(2024, 1, 1, 15, 0),
            foods: const [MealFoodEntry(food: food, amount: 50.0)], // 200 kcal
          ),
        ],
        goal: goal,
      );
      expect(daily.caloriesByMealType(MealType.breakfast), closeTo(400.0, 0.001));
      expect(daily.caloriesByMealType(MealType.lunch), closeTo(400.0, 0.001));
      expect(daily.caloriesByMealType(MealType.snack), closeTo(200.0, 0.001));
      expect(daily.caloriesByMealType(MealType.dinner), closeTo(0.0, 0.001));
    });

    test('toJson / fromJson roundtrip', () {
      final original = DailyNutrition(
        date: DateTime(2024, 5, 1),
        meals: [
          Meal(
            id: 'meal_1',
            type: MealType.breakfast,
            dateTime: DateTime(2024, 5, 1, 7, 30),
            foods: const [MealFoodEntry(food: food, amount: 100.0)],
          ),
        ],
        goal: goal,
      );

      final json = original.toJson();
      final restored = DailyNutrition.fromJson(json);

      expect(restored.date, original.date);
      expect(restored.meals.length, original.meals.length);
      expect(restored.goal.calories, original.goal.calories);
    });
  });

  // ---------------------------------------------------------------------------
  // WaterIntakeEntry tests
  // ---------------------------------------------------------------------------
  group('WaterIntakeEntry', () {
    test('creation with required fields', () {
      final entry = WaterIntakeEntry(
        id: 'w1',
        time: DateTime(2024, 1, 1, 9, 0),
        amountMl: 250,
      );
      expect(entry.id, 'w1');
      expect(entry.amountMl, 250);
      expect(entry.note, isNull);
    });

    test('toJson / fromJson roundtrip', () {
      final original = WaterIntakeEntry(
        id: 'w_rt',
        time: DateTime(2024, 3, 15, 14, 30),
        amountMl: 500,
        note: '운동 후',
      );
      final json = original.toJson();
      final restored = WaterIntakeEntry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.time, original.time);
      expect(restored.amountMl, original.amountMl);
      expect(restored.note, original.note);
    });
  });

  // ---------------------------------------------------------------------------
  // DailyWaterIntake tests
  // ---------------------------------------------------------------------------
  group('DailyWaterIntake', () {
    test('totalMl sums all entries', () {
      final daily = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 9, 0), amountMl: 250),
          WaterIntakeEntry(id: 'w2', time: DateTime(2024, 1, 1, 12, 0), amountMl: 500),
          WaterIntakeEntry(id: 'w3', time: DateTime(2024, 1, 1, 15, 0), amountMl: 350),
        ],
        goalMl: 2000,
      );
      expect(daily.totalMl, 1100);
    });

    test('remainingMl is clamped to zero when goal exceeded', () {
      final over = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 8, 0), amountMl: 2500),
        ],
        goalMl: 2000,
      );
      expect(over.remainingMl, 0); // clamped to 0, not negative
    });

    test('progress ratio is between 0 and 1', () {
      final half = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 10, 0), amountMl: 1000),
        ],
        goalMl: 2000,
      );
      expect(half.progress, closeTo(0.5, 0.001));

      final over = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 8, 0), amountMl: 3000),
        ],
        goalMl: 2000,
      );
      expect(over.progress, closeTo(1.0, 0.001));
    });

    test('isGoalReached when total meets goal', () {
      final notReached = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 9, 0), amountMl: 1999),
        ],
        goalMl: 2000,
      );
      expect(notReached.isGoalReached, isFalse);

      final reached = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 1, 1, 9, 0), amountMl: 2000),
        ],
        goalMl: 2000,
      );
      expect(reached.isGoalReached, isTrue);
    });

    test('default goalMl is 2000', () {
      final daily = DailyWaterIntake(
        date: DateTime(2024, 1, 1),
        entries: const [],
      );
      expect(daily.goalMl, 2000);
    });

    test('toJson / fromJson roundtrip', () {
      final original = DailyWaterIntake(
        date: DateTime(2024, 6, 15),
        entries: [
          WaterIntakeEntry(id: 'w1', time: DateTime(2024, 6, 15, 8, 0), amountMl: 300),
          WaterIntakeEntry(id: 'w2', time: DateTime(2024, 6, 15, 13, 0), amountMl: 500),
        ],
        goalMl: 2500,
      );
      final json = original.toJson();
      final restored = DailyWaterIntake.fromJson(json);

      expect(restored.date, original.date);
      expect(restored.entries.length, original.entries.length);
      expect(restored.goalMl, original.goalMl);
      expect(restored.totalMl, original.totalMl);
    });
  });
}
