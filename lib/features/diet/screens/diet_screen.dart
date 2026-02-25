import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/core/widgets/common_states.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// MealType UI helpers (extension only – enum lives in diet_model.dart)
// ---------------------------------------------------------------------------

extension MealTypeUiExt on MealType {
  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.light_mode_outlined;
      case MealType.dinner:
        return Icons.nightlight_round;
      case MealType.snack:
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast:
        return Colors.amber;
      case MealType.lunch:
        return Colors.orange;
      case MealType.dinner:
        return Colors.indigo;
      case MealType.snack:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ---------------------------------------------------------------------------
// DietScreen
// ---------------------------------------------------------------------------

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietState = ref.watch(dietProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.dietManagement,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: l10n.tooltipCalendar,
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalorieRingCard(dietState: dietState),
          const SizedBox(height: 16),
          _MacroCard(dietState: dietState),
          const SizedBox(height: 16),
          if (dietState.totalCalories == 0 && dietState.meals.isEmpty)
            EmptyStateWidget(
              icon: Icons.restaurant_outlined,
              title: l10n.noMealsRecorded,
              subtitle: l10n.addMealToStart,
            )
          else
            ...[
              MealType.breakfast,
              MealType.lunch,
              MealType.dinner,
              MealType.snack,
            ].map(
              (type) => _MealTypeSectionCard(mealType: type),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calorie Ring Card
// ---------------------------------------------------------------------------

class _CalorieRingCard extends StatelessWidget {
  final DailyDietState dietState;
  const _CalorieRingCard({required this.dietState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = dietState.calorieProgress;
    final totalCalories = dietState.totalCalories;
    final goalCalories = dietState.goal.calories;
    final remaining = goalCalories - totalCalories;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.todayCalories,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 80,
              lineWidth: 14,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    totalCalories.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.kcal,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              progressColor: Colors.orange,
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CalorieLabel(
                  label: l10n.goal,
                  value: goalCalories.toStringAsFixed(0),
                  color: Colors.grey,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                ),
                _CalorieLabel(
                  label: l10n.consumed,
                  value: totalCalories.toStringAsFixed(0),
                  color: Colors.orange,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                ),
                _CalorieLabel(
                  label: remaining >= 0 ? l10n.remaining : l10n.exceeded,
                  value: remaining.abs().toStringAsFixed(0),
                  color: remaining >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CalorieLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          l10n.kcal,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Macro Card
// ---------------------------------------------------------------------------

class _MacroCard extends StatelessWidget {
  final DailyDietState dietState;
  const _MacroCard({required this.dietState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratios = dietState.macroRatios;
    final proteinPct = ratios['protein'] ?? 0.0;
    final carbsPct = ratios['carbs'] ?? 0.0;
    final fatPct = ratios['fat'] ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.macroNutrients,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: [
                    if (proteinPct > 0)
                      Flexible(
                        flex: (proteinPct * 100).round(),
                        child: Container(color: Colors.blue),
                      ),
                    if (carbsPct > 0)
                      Flexible(
                        flex: (carbsPct * 100).round(),
                        child: Container(color: Colors.orange),
                      ),
                    if (fatPct > 0)
                      Flexible(
                        flex: (fatPct * 100).round(),
                        child: Container(color: Colors.red.shade300),
                      ),
                    // Ensure row is never fully empty
                    if (proteinPct == 0 && carbsPct == 0 && fatPct == 0)
                      Expanded(
                        child: Container(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroStat(
                  label: l10n.protein,
                  value: '${dietState.totalProtein.toStringAsFixed(0)}g',
                  percent: proteinPct,
                  color: Colors.blue,
                ),
                _MacroStat(
                  label: l10n.carbs,
                  value: '${dietState.totalCarbs.toStringAsFixed(0)}g',
                  percent: carbsPct,
                  color: Colors.orange,
                ),
                _MacroStat(
                  label: l10n.fat,
                  value: '${dietState.totalFat.toStringAsFixed(0)}g',
                  percent: fatPct,
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

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;

  const _MacroStat({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '${(percent * 100).toInt()}%',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meal Type Section Card
// Renders one collapsible section per MealType. Each existing Meal under that
// type becomes its own sub-section with food rows. If no meals exist for the
// type yet, an "add meal" button is shown instead.
// ---------------------------------------------------------------------------

class _MealTypeSectionCard extends ConsumerStatefulWidget {
  final MealType mealType;

  const _MealTypeSectionCard({required this.mealType});

  @override
  ConsumerState<_MealTypeSectionCard> createState() =>
      _MealTypeSectionCardState();
}

class _MealTypeSectionCardState extends ConsumerState<_MealTypeSectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dietState = ref.watch(dietProvider);
    final meals = dietState.getMealsByType(widget.mealType);
    final color = widget.mealType.color;

    // Aggregate totals across all meals of this type
    final totalCalories =
        meals.fold<double>(0, (s, m) => s + m.totalCalories);
    final totalFoods = meals.fold<int>(0, (s, m) => s + m.foods.length);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.mealType.icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mealType.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          meals.isEmpty
                              ? l10n.noMealRecord
                              : l10n.foodCountCalories(
                                  totalFoods,
                                  totalCalories.toStringAsFixed(0),
                                ),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Add meal button (when meals exist, adds another meal of same type)
                  if (meals.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showAddFoodDialog(
                        context,
                        meals.last.id,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.add),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded body
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (meals.isEmpty)
              _EmptyMealPlaceholder(
                mealType: widget.mealType,
                onAddMeal: () async {
                  await ref
                      .read(dietProvider.notifier)
                      .addMeal(widget.mealType);
                },
              )
            else
              ...meals.map(
                (meal) => _MealBlock(meal: meal),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, String mealId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFoodSheet(mealId: mealId),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty meal placeholder – shown when a MealType has no meals yet
// ---------------------------------------------------------------------------

class _EmptyMealPlaceholder extends StatelessWidget {
  final MealType mealType;
  final VoidCallback onAddMeal;

  const _EmptyMealPlaceholder({
    required this.mealType,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = mealType.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Text(
            l10n.noMealTypeRecord(mealType.label),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddMeal,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.addMealTypeLabel(mealType.label)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal block – a single Meal's food entries with a remove-meal action
// ---------------------------------------------------------------------------

class _MealBlock extends ConsumerWidget {
  final Meal meal;

  const _MealBlock({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Per-meal sub-header with add-food and remove-meal actions
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mealFoodCountCalories(
                    meal.foods.length,
                    meal.totalCalories.toStringAsFixed(0),
                  ),
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ),
              // Add food to this specific meal
              GestureDetector(
                onTap: () => _showAddFoodDialog(context, ref, meal.id),
                child: const Icon(Icons.add_circle_outline,
                    size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              // Remove this entire meal
              GestureDetector(
                onTap: () =>
                    ref.read(dietProvider.notifier).removeMeal(meal.id),
                child: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (meal.foods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Text(
              l10n.addFoodPrompt,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.7)),
            ),
          )
        else
          ...meal.foods.asMap().entries.map(
                (entry) => _FoodRow(
                  foodEntry: entry.value,
                  onRemove: () => ref
                      .read(dietProvider.notifier)
                      .removeFoodFromMeal(meal.id, entry.key),
                ),
              ),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref, String mealId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddFoodSheet(mealId: mealId),
    );
  }
}

// ---------------------------------------------------------------------------
// Food Row
// ---------------------------------------------------------------------------

class _FoodRow extends StatelessWidget {
  final MealFoodEntry foodEntry;
  final VoidCallback onRemove;

  const _FoodRow({required this.foodEntry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final food = foodEntry.food;
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(food.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        '${l10n.protein} ${foodEntry.actualProtein.toStringAsFixed(0)}g · '
        '${l10n.carbs} ${foodEntry.actualCarbs.toStringAsFixed(0)}g · '
        '${l10n.fat} ${foodEntry.actualFat.toStringAsFixed(0)}g',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${foodEntry.actualCalories.toStringAsFixed(0)} ${l10n.kcal}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Food Bottom Sheet
// ---------------------------------------------------------------------------

class _AddFoodSheet extends ConsumerStatefulWidget {
  final String mealId;

  const _AddFoodSheet({required this.mealId});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final TextEditingController _searchController = TextEditingController();
  FoodItem? _selectedFood;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear search on open
    ref.read(foodDatabaseProvider.notifier).search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(foodDatabaseProvider.notifier).search(query);
  }

  Future<void> _addFood() async {
    final food = _selectedFood;
    if (food == null) return;

    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty
        ? food.servingSize
        : double.tryParse(amountText) ?? food.servingSize;

    await ref
        .read(dietProvider.notifier)
        .addFoodToMeal(widget.mealId, food, amount);
    await ref.read(foodDatabaseProvider.notifier).addToRecent(food);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredFoods = ref.watch(filteredFoodsProvider);
    final recentFoods = ref.watch(recentFoodsProvider);
    final isSearching = _searchController.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addFood,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchFoodHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Selected food + amount field
          if (_selectedFood != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFood!.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        Text(
                          l10n.servingReference(
                            _selectedFood!.servingSize.toStringAsFixed(0),
                            _selectedFood!.servingUnit,
                            _selectedFood!.calories.toStringAsFixed(0),
                          ),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText:
                            _selectedFood!.servingSize.toStringAsFixed(0),
                        hintStyle: const TextStyle(fontSize: 12),
                        suffixText: _selectedFood!.servingUnit,
                        suffixStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recent foods (shown when not searching)
          if (!isSearching && recentFoods.isNotEmpty) ...[
            Text(
              l10n.recentFoods,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentFoods
                  .take(6)
                  .map(
                    (food) => ActionChip(
                      label: Text(food.name),
                      onPressed: () {
                        setState(() {
                          _selectedFood = food;
                          _amountController.clear();
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Search results
          if (isSearching || recentFoods.isEmpty) ...[
            if (!isSearching && recentFoods.isEmpty)
              Text(
                l10n.frequentFoods,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            if (isSearching)
              Text(
                l10n.searchResultCount(filteredFoods.length),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: filteredFoods.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noSearchResultsFood,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredFoods.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final food = filteredFoods[i];
                        final isSelected =
                            _selectedFood?.id == food.id;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor:
                              Colors.orange.withValues(alpha: 0.08),
                          title: Text(food.name,
                              style:
                                  const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            '${food.calories.toStringAsFixed(0)} kcal / '
                            '${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.orange, size: 18)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedFood = food;
                              _amountController.clear();
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedFood != null ? _addFood : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.confirmAdd),
            ),
          ),
        ],
      ),
    );
  }
}
