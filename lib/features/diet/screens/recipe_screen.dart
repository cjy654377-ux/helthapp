// 레시피 & 식단 플래너 화면
// Tab 1: 레시피 그리드 (필터, 상세 바텀시트)
// Tab 2: 오늘의 식단 계획 (생성, 스왑, 식단 연동)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/features/diet/providers/recipe_provider.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/core/widgets/common_states.dart';

// ---------------------------------------------------------------------------
// RecipeScreen – 메인 화면
// ---------------------------------------------------------------------------

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '레시피 & 식단 플래너',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: '레시피'),
            Tab(icon: Icon(Icons.calendar_today_outlined), text: '식단 플랜'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RecipeListTab(),
          _MealPlanTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: 레시피 목록
// ---------------------------------------------------------------------------

class _RecipeListTab extends ConsumerWidget {
  const _RecipeListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(filteredRecipesProvider);
    final filter = ref.watch(recipeFilterProvider);

    return Column(
      children: [
        // 필터 바
        _RecipeFilterBar(filter: filter),

        // 레시피 그리드
        Expanded(
          child: recipes.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.restaurant_outlined,
                  title: '레시피 없음',
                  subtitle: '필터를 변경해보세요',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (ctx, i) => _RecipeCard(recipe: recipes[i]),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 필터 바
// ---------------------------------------------------------------------------

class _RecipeFilterBar extends ConsumerWidget {
  final RecipeFilterState filter;
  const _RecipeFilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 전체
          _FilterChip(
            label: '전체',
            selected: filter.selectedMealType == null,
            onSelected: (_) =>
                ref.read(recipeFilterProvider.notifier).setMealType(null),
          ),
          const SizedBox(width: 8),
          // 식사 타입 필터
          ...RecipeMealType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: _mealTypeLabel(type),
                  selected: filter.selectedMealType == type,
                  onSelected: (_) => ref
                      .read(recipeFilterProvider.notifier)
                      .setMealType(type),
                ),
              )),
          // 저칼로리 필터
          _FilterChip(
            label: '저칼로리',
            selected: filter.maxCalories == 300,
            onSelected: (_) {
              if (filter.maxCalories == 300) {
                ref.read(recipeFilterProvider.notifier).setMaxCalories(null);
              } else {
                ref
                    .read(recipeFilterProvider.notifier)
                    .setMaxCalories(300);
              }
            },
          ),
        ],
      ),
    );
  }

  String _mealTypeLabel(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return '아침';
      case RecipeMealType.lunch:
        return '점심';
      case RecipeMealType.dinner:
        return '저녁';
      case RecipeMealType.snack:
        return '간식';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: selected ? Colors.orange : Colors.grey,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? Colors.orange.withValues(alpha: 0.5)
            : Colors.grey.withValues(alpha: 0.3),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ---------------------------------------------------------------------------
// 레시피 카드
// ---------------------------------------------------------------------------

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRecipeDetail(context, recipe),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 플레이스홀더
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 110,
                width: double.infinity,
                color: _mealTypeColor(recipe.mealType)
                    .withValues(alpha: 0.12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _mealTypeIcon(recipe.mealType),
                      size: 36,
                      color: _mealTypeColor(recipe.mealType),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mealTypeLabel(recipe.mealType),
                      style: TextStyle(
                        fontSize: 11,
                        color: _mealTypeColor(recipe.mealType),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 내용
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${recipe.totalCalories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${recipe.totalTimeMinutes}분',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      _DifficultyDot(difficulty: recipe.difficulty),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(recipe: recipe),
    );
  }

  Color _mealTypeColor(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return Colors.amber;
      case RecipeMealType.lunch:
        return Colors.orange;
      case RecipeMealType.dinner:
        return Colors.indigo;
      case RecipeMealType.snack:
        return Colors.green;
    }
  }

  IconData _mealTypeIcon(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return Icons.wb_sunny_outlined;
      case RecipeMealType.lunch:
        return Icons.light_mode_outlined;
      case RecipeMealType.dinner:
        return Icons.nightlight_round;
      case RecipeMealType.snack:
        return Icons.cookie_outlined;
    }
  }

  String _mealTypeLabel(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return '아침';
      case RecipeMealType.lunch:
        return '점심';
      case RecipeMealType.dinner:
        return '저녁';
      case RecipeMealType.snack:
        return '간식';
    }
  }
}

class _DifficultyDot extends StatelessWidget {
  final RecipeDifficulty difficulty;
  const _DifficultyDot({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      RecipeDifficulty.easy => ('쉬움', Colors.green),
      RecipeDifficulty.medium => ('보통', Colors.orange),
      RecipeDifficulty.hard => ('어려움', Colors.red),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 레시피 상세 바텀시트
// ---------------------------------------------------------------------------

class _RecipeDetailSheet extends ConsumerWidget {
  final Recipe recipe;
  const _RecipeDetailSheet({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // 헤더
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.nameEn,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 설명
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // 시간 & 인분 정보
                  _InfoChipRow(recipe: recipe),
                  const SizedBox(height: 16),

                  // 영양 정보 카드
                  _NutritionCard(recipe: recipe),
                  const SizedBox(height: 20),

                  // 재료
                  const Text(
                    '재료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ing.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 조리 방법
                  const Text(
                    '조리 방법',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.instructions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 태그
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: recipe.tags
                        .map((tag) => Chip(
                              label: Text(
                                '#$tag',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor:
                                  Colors.orange.withValues(alpha: 0.1),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // 식단에 추가 버튼
                  _AddToDietButton(recipe: recipe),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChipRow extends StatelessWidget {
  final Recipe recipe;
  const _InfoChipRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.timer_outlined,
          label: '${recipe.prepTimeMinutes}분 준비',
        ),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.local_fire_department_outlined,
          label: '${recipe.cookTimeMinutes}분 조리',
        ),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.people_outline,
          label: '${recipe.servings}인분',
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Recipe recipe;
  const _NutritionCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '영양 정보 (1인분)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientStat(
                label: '칼로리',
                value: recipe.totalCalories.toStringAsFixed(0),
                unit: 'kcal',
                color: Colors.orange,
              ),
              _NutrientStat(
                label: '단백질',
                value: recipe.protein.toStringAsFixed(0),
                unit: 'g',
                color: Colors.blue,
              ),
              _NutrientStat(
                label: '탄수화물',
                value: recipe.carbs.toStringAsFixed(0),
                unit: 'g',
                color: Colors.amber,
              ),
              _NutrientStat(
                label: '지방',
                value: recipe.fat.toStringAsFixed(0),
                unit: 'g',
                color: Colors.red.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 식단에 추가 버튼
// ---------------------------------------------------------------------------

class _AddToDietButton extends ConsumerWidget {
  final Recipe recipe;
  const _AddToDietButton({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _addToDiet(context, ref),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('식단에 추가'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _addToDiet(BuildContext context, WidgetRef ref) async {
    // 레시피를 FoodItem으로 변환하여 해당 식사 타입의 새 Meal에 추가
    final food = recipeToFoodItem(recipe);
    final mealType = _toMealType(recipe.mealType);

    // 해당 식사 타입의 Meal 생성 후 food 추가
    await ref.read(dietProvider.notifier).addMeal(mealType);

    final dietState = ref.read(dietProvider);
    final meals = dietState.getMealsByType(mealType);

    if (meals.isNotEmpty) {
      final mealId = meals.last.id;
      await ref
          .read(dietProvider.notifier)
          .addFoodToMeal(mealId, food, 1);
    }

    if (context.mounted) {
      Navigator.pop(context); // 바텀시트 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name}이(가) 식단에 추가되었습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  MealType _toMealType(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return MealType.breakfast;
      case RecipeMealType.lunch:
        return MealType.lunch;
      case RecipeMealType.dinner:
        return MealType.dinner;
      case RecipeMealType.snack:
        return MealType.snack;
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 2: 오늘의 식단 플랜
// ---------------------------------------------------------------------------

class _MealPlanTab extends ConsumerWidget {
  const _MealPlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(mealPlanProvider);
    final plan = planState.currentPlan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 목표 칼로리 설정
        _CalorieTargetCard(currentTarget: planState.preference.targetCalories),
        const SizedBox(height: 16),

        // 생성 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: planState.isGenerating
                ? null
                : () => ref
                    .read(mealPlanProvider.notifier)
                    .generatePlan(),
            icon: planState.isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(planState.isGenerating ? '생성 중...' : '식단 계획 생성'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (plan == null)
          const EmptyStateWidget(
            icon: Icons.restaurant_menu_outlined,
            title: '식단 계획이 없습니다',
            subtitle: '위 버튼을 눌러 오늘의 식단을 생성하세요',
          )
        else ...[
          // 하루 요약
          _DayNutritionSummary(plan: plan),
          const SizedBox(height: 16),

          // 각 식사 카드
          ...RecipeMealType.values
              .where((type) => plan.meals.containsKey(type))
              .map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MealPlanCard(
                      mealType: type,
                      recipe: plan.meals[type]!,
                    ),
                  )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 목표 칼로리 카드
// ---------------------------------------------------------------------------

class _CalorieTargetCard extends ConsumerStatefulWidget {
  final double currentTarget;
  const _CalorieTargetCard({required this.currentTarget});

  @override
  ConsumerState<_CalorieTargetCard> createState() => _CalorieTargetCardState();
}

class _CalorieTargetCardState extends ConsumerState<_CalorieTargetCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentTarget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '하루 목표 칼로리',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixText: 'kcal',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (val) {
                  final calories = double.tryParse(val);
                  if (calories != null && calories > 0) {
                    ref
                        .read(mealPlanProvider.notifier)
                        .setTargetCalories(calories);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 하루 영양 요약
// ---------------------------------------------------------------------------

class _DayNutritionSummary extends StatelessWidget {
  final MealPlan plan;
  const _DayNutritionSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 영양 합계',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutrientStat(
                  label: '칼로리',
                  value: plan.totalCalories.toStringAsFixed(0),
                  unit: 'kcal',
                  color: Colors.orange,
                ),
                _NutrientStat(
                  label: '단백질',
                  value: plan.totalProtein.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.blue,
                ),
                _NutrientStat(
                  label: '탄수화물',
                  value: plan.totalCarbs.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.amber,
                ),
                _NutrientStat(
                  label: '지방',
                  value: plan.totalFat.toStringAsFixed(0),
                  unit: 'g',
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 식단 플랜 카드 (식사 타입별)
// ---------------------------------------------------------------------------

class _MealPlanCard extends ConsumerWidget {
  final RecipeMealType mealType;
  final Recipe recipe;

  const _MealPlanCard({
    required this.mealType,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alternatives = ref.watch(alternativeRecipesProvider(mealType));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _mealTypeColor(mealType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _mealTypeIcon(mealType),
                    size: 16,
                    color: _mealTypeColor(mealType),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _mealTypeLabel(mealType),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _mealTypeColor(mealType),
                  ),
                ),
                const Spacer(),
                // 스왑 버튼
                TextButton.icon(
                  onPressed: alternatives.isEmpty
                      ? null
                      : () => _showSwapSheet(context, ref, alternatives),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('교체', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 레시피 정보
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      recipe.totalCalories.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 매크로 미니 요약
            Row(
              children: [
                _MiniMacro(label: '단', value: '${recipe.protein.toStringAsFixed(0)}g', color: Colors.blue),
                const SizedBox(width: 8),
                _MiniMacro(label: '탄', value: '${recipe.carbs.toStringAsFixed(0)}g', color: Colors.amber),
                const SizedBox(width: 8),
                _MiniMacro(label: '지', value: '${recipe.fat.toStringAsFixed(0)}g', color: Colors.red.shade300),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addToDiet(context, ref),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('식단 추가', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSwapSheet(
    BuildContext context,
    WidgetRef ref,
    List<Recipe> alternatives,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SwapRecipeSheet(
        mealType: mealType,
        alternatives: alternatives,
        onSwap: (newRecipe) {
          ref.read(mealPlanProvider.notifier).swapMeal(mealType, newRecipe);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _addToDiet(BuildContext context, WidgetRef ref) async {
    final food = recipeToFoodItem(recipe);
    final mealTypeDiet = _toMealType(mealType);

    await ref.read(dietProvider.notifier).addMeal(mealTypeDiet);
    final dietState = ref.read(dietProvider);
    final meals = dietState.getMealsByType(mealTypeDiet);

    if (meals.isNotEmpty) {
      await ref
          .read(dietProvider.notifier)
          .addFoodToMeal(meals.last.id, food, 1);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name}이(가) 식단에 추가되었습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  MealType _toMealType(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return MealType.breakfast;
      case RecipeMealType.lunch:
        return MealType.lunch;
      case RecipeMealType.dinner:
        return MealType.dinner;
      case RecipeMealType.snack:
        return MealType.snack;
    }
  }

  Color _mealTypeColor(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return Colors.amber;
      case RecipeMealType.lunch:
        return Colors.orange;
      case RecipeMealType.dinner:
        return Colors.indigo;
      case RecipeMealType.snack:
        return Colors.green;
    }
  }

  IconData _mealTypeIcon(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return Icons.wb_sunny_outlined;
      case RecipeMealType.lunch:
        return Icons.light_mode_outlined;
      case RecipeMealType.dinner:
        return Icons.nightlight_round;
      case RecipeMealType.snack:
        return Icons.cookie_outlined;
    }
  }

  String _mealTypeLabel(RecipeMealType type) {
    switch (type) {
      case RecipeMealType.breakfast:
        return '아침';
      case RecipeMealType.lunch:
        return '점심';
      case RecipeMealType.dinner:
        return '저녁';
      case RecipeMealType.snack:
        return '간식';
    }
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 스왑 레시피 시트
// ---------------------------------------------------------------------------

class _SwapRecipeSheet extends StatelessWidget {
  final RecipeMealType mealType;
  final List<Recipe> alternatives;
  final ValueChanged<Recipe> onSwap;

  const _SwapRecipeSheet({
    required this.mealType,
    required this.alternatives,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '대체 레시피 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: alternatives.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final recipe = alternatives[i];
                return ListTile(
                  title: Text(recipe.name),
                  subtitle: Text(
                    '${recipe.totalCalories.toStringAsFixed(0)} kcal · ${recipe.totalTimeMinutes}분',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () => onSwap(recipe),
                    child: const Text('선택'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
