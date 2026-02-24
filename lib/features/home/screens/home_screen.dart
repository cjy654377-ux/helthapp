import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/l10n/app_localizations.dart';

import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/features/calendar/providers/calendar_providers.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final userNicknameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_nickname') ?? '사용자';
});

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colorScheme, ref),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GreetingCard(colorScheme: colorScheme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: _WorkoutSummaryCard()),
                    const SizedBox(width: 12),
                    const Expanded(child: _HydrationCard()),
                  ],
                ),
                const SizedBox(height: 16),
                const _CalorieCard(),
                const SizedBox(height: 16),
                const _UpcomingWorkoutCard(),
                const SizedBox(height: 16),
                const _QuickActions(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, ColorScheme colorScheme, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nickname = ref.watch(userNicknameProvider).valueOrNull ?? l10n.defaultUser;
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      backgroundColor: colorScheme.primaryContainer,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.greeting(nickname),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
              ),
              Text(
                l10n.healthyDay,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting Card
// ---------------------------------------------------------------------------

class _GreetingCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _GreetingCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final weekdays = [l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun];
    final dayLabel = weekdays[now.weekday - 1];

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dateFormatMonthDay(now.month, now.day, dayLabel),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.headingToGoal,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout Summary Card
// ---------------------------------------------------------------------------

class _WorkoutSummaryCard extends ConsumerWidget {
  const _WorkoutSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayRecords = ref.watch(todayWorkoutRecordsProvider);

    final completedExercises =
        todayRecords.fold<int>(0, (sum, r) => sum + r.exercises.length);
    final totalVolume =
        todayRecords.fold<double>(0, (sum, r) => sum + r.totalVolume);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  l10n.todayWorkout,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$completedExercises개',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.completedExercises,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${totalVolume.toStringAsFixed(0)} kg',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            Text(
              l10n.totalVolume,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration Card
// ---------------------------------------------------------------------------

class _HydrationCard extends ConsumerWidget {
  const _HydrationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hydrationState = ref.watch(hydrationProvider);
    final hydration = hydrationState.totalMl;
    final goal = hydrationState.goalMl;
    final percent = hydrationState.progress;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, size: 18, color: Colors.cyan),
                const SizedBox(width: 6),
                Text(
                  l10n.hydrationIntake,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CircularPercentIndicator(
              radius: 42,
              lineWidth: 7,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(percent * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              progressColor: Colors.cyan,
              backgroundColor: Colors.cyan.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 8),
            Text(
              '$hydration / $goal ml',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(hydrationProvider.notifier).addWater(250),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('250ml', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  foregroundColor: Colors.cyan,
                  side: const BorderSide(color: Colors.cyan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calorie Card
// ---------------------------------------------------------------------------

class _CalorieCard extends ConsumerWidget {
  const _CalorieCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dietState = ref.watch(dietProvider);

    final goalCalories = dietState.goal.calories.toInt();
    final consumed = dietState.totalCalories.toInt();
    final percent = (dietState.totalCalories / dietState.goal.calories).clamp(0.0, 1.0);
    final remaining = goalCalories - consumed;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_dining, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  l10n.calorieIntake,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CalorieStat(
                  label: l10n.goal,
                  value: '$goalCalories',
                  unit: l10n.kcal,
                  color: Colors.grey,
                ),
                _CalorieStat(
                  label: l10n.consumed,
                  value: '$consumed',
                  unit: l10n.kcal,
                  color: Colors.orange,
                ),
                _CalorieStat(
                  label: l10n.remaining,
                  value: '$remaining',
                  unit: l10n.kcal,
                  color: remaining > 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _CalorieStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Workout Card
// ---------------------------------------------------------------------------

class _UpcomingWorkoutCard extends ConsumerWidget {
  const _UpcomingWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final plans = ref.watch(todayWorkoutPlansProvider);
    final upcomingPlan = plans.where((p) => !p.isCompleted).firstOrNull;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: upcomingPlan == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.upcomingWorkout,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.noWorkoutPlan,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.upcomingWorkout,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      const Spacer(),
                      if (upcomingPlan.targetBodyParts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            upcomingPlan.targetBodyParts.first,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.purple),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    upcomingPlan.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (upcomingPlan.targetBodyParts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: upcomingPlan.targetBodyParts
                          .map(
                            (part) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(part,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickStart,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fitness_center,
                label: l10n.startWorkout,
                color: Colors.blue,
                onTap: () => context.push(AppRoutes.workoutLog),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant,
                label: l10n.logDiet,
                color: Colors.orange,
                onTap: () => context.push(AppRoutes.diet),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.water_drop,
                label: l10n.drinkWater,
                color: Colors.cyan,
                onTap: () => context.push(AppRoutes.hydration),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
