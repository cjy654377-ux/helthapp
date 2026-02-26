import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/l10n/app_localizations.dart';

import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/features/calendar/providers/calendar_providers.dart';
import 'package:health_app/features/profile/screens/settings_screen.dart';
import 'package:health_app/features/profile/screens/recovery_heatmap_screen.dart';
import 'package:health_app/features/profile/screens/meditation_screen.dart';
import 'package:health_app/features/workout_guide/providers/exercise_database_provider.dart';

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
                const _TrainingTipsCard(),
                const SizedBox(height: 16),
                const _RecoverySummaryCard(),
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
    final nickname = ref.watch(settingsProvider).nickname.isEmpty
        ? l10n.defaultUser
        : ref.watch(settingsProvider).nickname;
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
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.self_improvement,
                label: '명상',
                color: const Color(0xFF7E57C2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MeditationScreen(),
                  ),
                ),
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

  // VoidCallback은 const가 불가능하므로 const 인스턴스 생성은 호출부에 달려 있음.
  // 내부에서 const로 고정 가능한 값은 const로 선언.
  static const _borderRadius = BorderRadius.all(Radius.circular(16));
  static const _padding = EdgeInsets.symmetric(vertical: 16);
  static const _iconSize = 26.0;
  static const _textStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

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
      borderRadius: _borderRadius,
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: _borderRadius,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: _iconSize),
            const SizedBox(height: 6),
            Text(
              label,
              style: _textStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Training Tips Card (점진적 과부하 추천 카드)
// ---------------------------------------------------------------------------

class _TrainingTipsCard extends ConsumerWidget {
  const _TrainingTipsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    final suggestions = ref.watch(sessionSuggestionsProvider);

    // 운동 기록이 없으면 카드 미표시
    if (history.isEmpty || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 상위 3개 제안만 표시
    final topSuggestions = suggestions.take(3).toList();
    // 운동 이름 조회용 맵
    final allExercises = ref.watch(exerciseDatabaseProvider).allExercises;
    final exerciseMap = {for (final e in allExercises) e.id: e.name};

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 18,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                const Text(
                  '오늘의 트레이닝 팁',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '점진적 과부하',
                    style: TextStyle(fontSize: 10, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 제안 목록
            ...topSuggestions.map((suggestion) {
              final exerciseName =
                  exerciseMap[suggestion.exerciseId] ?? suggestion.exerciseId;
              return _TrainingTipRow(
                exerciseName: exerciseName,
                suggestion: suggestion,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TrainingTipRow extends StatelessWidget {
  final String exerciseName;
  final ProgressiveOverloadSuggestion suggestion;

  const _TrainingTipRow({
    required this.exerciseName,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    // 진행 유형별 아이콘과 색상
    final (icon, color) = switch (suggestion.progressionType) {
      ProgressionType.weightIncrease => (Icons.arrow_upward, Colors.green),
      ProgressionType.repIncrease => (Icons.add_circle_outline, Colors.blue),
      ProgressionType.deload => (Icons.arrow_downward, Colors.orange),
      ProgressionType.maintain => (Icons.horizontal_rule, Colors.grey),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.reason,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 추천 수치
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${suggestion.suggestedWeight.toStringAsFixed(suggestion.suggestedWeight % 1 == 0 ? 0 : 1)}kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '× ${suggestion.suggestedReps}회',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery Summary Card (홈 화면 회복 요약 카드)
// ---------------------------------------------------------------------------

class _RecoverySummaryCard extends ConsumerWidget {
  const _RecoverySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3 = ref.watch(top3FatiguedMusclesProvider);

    // 표시할 근육이 없으면 카드를 표시하지 않음
    if (top3.isEmpty) return const SizedBox.shrink();

    // 가장 피로한 상태 확인
    final hasFatigued = top3.any(
      (m) => m.status == RecoveryStatus.fatigued,
    );
    final color = hasFatigued ? Colors.red : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.monitor_heart, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  'Muscle Recovery', // TODO: l10n
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecoveryHeatmapScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'View Map', // TODO: l10n
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 상위 3개 피로 근육
            ...top3.map((muscle) => _RecoveryMuscleRow(data: muscle)),
          ],
        ),
      ),
    );
  }
}

class _RecoveryMuscleRow extends StatelessWidget {
  final MuscleRecoveryData data;

  const _RecoveryMuscleRow({required this.data});

  String _timeAgo(Duration? duration) {
    if (duration == null) return '-';
    if (duration.inDays >= 1) return '${duration.inDays}일 전'; // TODO: l10n
    if (duration.inHours >= 1) return '${duration.inHours}시간 전'; // TODO: l10n
    return '${duration.inMinutes}분 전'; // TODO: l10n
  }

  @override
  Widget build(BuildContext context) {
    final color = data.status.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.bodyPart.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.status.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(data.timeSinceWorkout),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
