// 통계 & 진척도 화면 – 운동/체성분/영양/업적 섹션을 포함한 종합 통계 스크린
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:health_app/core/constants/app_constants.dart';
import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/core/services/achievement_service.dart';
import 'package:health_app/core/widgets/common_states.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Local data models
// ---------------------------------------------------------------------------

class _WorkoutDayEntry {
  final String weekLabel; // e.g. '1주'
  final int days;
  const _WorkoutDayEntry(this.weekLabel, this.days);
}

class _VolumeEntry {
  final String monthLabel; // e.g. '9월'
  final double volume; // kg
  const _VolumeEntry(this.monthLabel, this.volume);
}

class _WeightEntry {
  final String weekLabel;
  final double weight;
  const _WeightEntry(this.weekLabel, this.weight);
}

class _MuscleGroupRatio {
  final String name;
  final double ratio;
  final Color color;
  const _MuscleGroupRatio(this.name, this.ratio, this.color);
}

class _Top5Exercise {
  final String name;
  final int count;
  final Color color;
  const _Top5Exercise(this.name, this.count, this.color);
}

class _NutritionDayEntry {
  final String dayLabel;
  final int calories;
  const _NutritionDayEntry(this.dayLabel, this.calories);
}

class _Achievement {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String earnedDate;
  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.earnedDate,
  });
}

// ---------------------------------------------------------------------------
// Provider (weight log state – local, no dedicated provider exists)
// ---------------------------------------------------------------------------

class _WeightLogState {
  final List<_WeightEntry> entries;
  const _WeightLogState(this.entries);
  _WeightLogState copyWith({List<_WeightEntry>? entries}) =>
      _WeightLogState(entries ?? this.entries);
}

class _WeightLogNotifier extends StateNotifier<_WeightLogState> {
  _WeightLogNotifier() : super(const _WeightLogState([]));

  void addEntry(double weight, String todayLabel) {
    final newEntry = _WeightEntry(todayLabel, weight);
    state = state.copyWith(entries: [...state.entries, newEntry]);
  }
}

final _weightLogProvider =
    StateNotifierProvider<_WeightLogNotifier, _WeightLogState>(
  (ref) => _WeightLogNotifier(),
);

// ---------------------------------------------------------------------------
// Helper functions – derive chart data from provider records
// ---------------------------------------------------------------------------

/// Compute weekly workout days for the last 8 weeks from workout records.
List<_WorkoutDayEntry> _computeWeeklyWorkoutDays(
    List<WorkoutRecord> records, AppLocalizations l10n) {
  final now = DateTime.now();
  final labels = [
    '-8', '-7', '-6', '-5', '-4', '-3', '-2', l10n.weeklyWorkoutDays,
  ];

  return List.generate(8, (i) {
    // i=0 → 8 weeks ago, i=7 → this week
    final weeksAgo = 7 - i;
    final todayWeekday = now.weekday; // 1=Mon..7=Sun
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: todayWeekday - 1 + weeksAgo * 7));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final daysInWeek = records
        .where((r) =>
            !r.date.isBefore(weekStart) && r.date.isBefore(weekEnd))
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet()
        .length;

    return _WorkoutDayEntry(labels[i], daysInWeek);
  });
}

/// Compute monthly total volume for the last 6 months from workout records.
List<_VolumeEntry> _computeMonthlyVolume(
    List<WorkoutRecord> records, AppLocalizations l10n) {
  final now = DateTime.now();
  final monthNames = [
    l10n.jan, l10n.feb, l10n.mar, l10n.apr, l10n.may, l10n.jun,
    l10n.jul, l10n.aug, l10n.sep, l10n.oct, l10n.nov, l10n.dec,
  ];

  return List.generate(6, (i) {
    // i=0 → 5 months ago, i=5 → this month
    final monthsAgo = 5 - i;
    final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
    final year = targetDate.year;
    final month = targetDate.month;

    final volume = records
        .where((r) => r.date.year == year && r.date.month == month)
        .fold<double>(0, (sum, r) => sum + r.totalVolume);

    return _VolumeEntry(monthNames[month - 1], volume);
  });
}

/// Compute muscle group ratios from workout records.
List<_MuscleGroupRatio> _computeMuscleGroupRatios(
    List<WorkoutRecord> records, AppLocalizations l10n) {
  final groupColors = {
    l10n.chest: const Color(0xFF1565C0),
    l10n.back: const Color(0xFF388E3C),
    l10n.legs: const Color(0xFFFF9800),
    l10n.shoulders: const Color(0xFF9C27B0),
    l10n.arms: const Color(0xFFE53935),
    l10n.core: const Color(0xFF00ACC1),
    '전신': const Color(0xFF795548),
    '유산소': const Color(0xFF607D8B),
  };

  // Map BodyPart to display group names
  String bodyPartGroup(BodyPart bp) {
    switch (bp) {
      case BodyPart.chest:
        return l10n.chest;
      case BodyPart.back:
        return l10n.back;
      case BodyPart.shoulders:
        return l10n.shoulders;
      case BodyPart.biceps:
      case BodyPart.triceps:
      case BodyPart.forearms:
        return l10n.arms;
      case BodyPart.quadriceps:
      case BodyPart.hamstrings:
      case BodyPart.calves:
      case BodyPart.glutes:
        return l10n.legs;
      case BodyPart.abs:
        return l10n.core;
      case BodyPart.fullBody:
        return '전신';
      case BodyPart.cardio:
        return '유산소';
    }
  }

  final counts = <String, int>{};
  int total = 0;

  for (final record in records) {
    for (final exercise in record.exercises) {
      final group = bodyPartGroup(exercise.bodyPart);
      counts[group] = (counts[group] ?? 0) + 1;
      total++;
    }
  }

  if (total == 0) return [];

  // Sort by count descending, take top 5
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(5).toList();

  return top.map((e) {
    return _MuscleGroupRatio(
      e.key,
      e.value / total,
      groupColors[e.key] ?? const Color(0xFF757575),
    );
  }).toList();
}

/// Compute top 5 most frequent exercises from workout records.
List<_Top5Exercise> _computeTop5Exercises(List<WorkoutRecord> records) {
  const exerciseColors = [
    Color(0xFF1565C0),
    Color(0xFF388E3C),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE53935),
  ];

  final counts = <String, int>{};
  for (final record in records) {
    for (final exercise in record.exercises) {
      counts[exercise.name] = (counts[exercise.name] ?? 0) + 1;
    }
  }

  if (counts.isEmpty) return [];

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(5).toList();

  return top.asMap().entries.map((e) {
    return _Top5Exercise(
      e.value.key,
      e.value.value,
      exerciseColors[e.key % exerciseColors.length],
    );
  }).toList();
}

/// Build weekly nutrition entries: today's actual data for the matching weekday,
/// 0 for other days (no historical diet data available).
List<_NutritionDayEntry> _computeWeeklyNutrition(
    double todayCalories, AppLocalizations l10n) {
  final dayLabels = [
    l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun,
  ];
  final todayWeekday = DateTime.now().weekday; // 1=Mon..7=Sun

  return List.generate(7, (i) {
    final weekday = i + 1;
    final cal = (weekday == todayWeekday) ? todayCalories.round() : 0;
    return _NutritionDayEntry(dayLabels[i], cal);
  });
}

/// Build weekly hydration data: today's actual data for the matching weekday,
/// 0 for other days (no historical hydration data available).
List<int> _computeWeeklyHydration(int todayMl) {
  final todayWeekday = DateTime.now().weekday; // 1=Mon..7=Sun
  return List.generate(7, (i) {
    final weekday = i + 1;
    return (weekday == todayWeekday) ? todayMl : 0;
  });
}

/// Map achievement icon emoji to IconData.
IconData _achievementIcon(String emoji) {
  switch (emoji) {
    case '💪':
      return Icons.fitness_center;
    case '🏋️':
      return Icons.fitness_center;
    case '🔥':
      return Icons.local_fire_department;
    case '⚡':
      return Icons.bolt;
    case '🏆':
      return Icons.emoji_events;
    case '🥇':
      return Icons.military_tech;
    case '🌅':
      return Icons.wb_sunny;
    case '🎯':
      return Icons.gps_fixed;
    case '⭐':
      return Icons.star;
    case '🌟':
      return Icons.star_border;
    case '💧':
      return Icons.water_drop;
    case '🌊':
      return Icons.waves;
    case '🏄':
      return Icons.surfing;
    case '🥗':
      return Icons.restaurant;
    case '📊':
      return Icons.bar_chart;
    case '👥':
      return Icons.group;
    case '🦋':
      return Icons.flutter_dash;
    case '✨':
      return Icons.auto_awesome;
    default:
      return Icons.emoji_events;
  }
}

/// ARB 키를 업적 제목 번역 문자열로 변환
String _resolveAchievementTitle(String titleKey, AppLocalizations l10n) {
  switch (titleKey) {
    case 'achievementFirstWorkoutTitle':
      return l10n.achievementFirstWorkoutTitle;
    case 'achievementWorkout10Title':
      return l10n.achievementWorkout10Title;
    case 'achievementWorkout50Title':
      return l10n.achievementWorkout50Title;
    case 'achievementWorkout100Title':
      return l10n.achievementWorkout100Title;
    case 'achievementVolume1000Title':
      return l10n.achievementVolume1000Title;
    case 'achievementPrFirstTitle':
      return l10n.achievementPrFirstTitle;
    case 'achievementMorningWarriorTitle':
      return l10n.achievementMorningWarriorTitle;
    case 'achievementVariety10Title':
      return l10n.achievementVariety10Title;
    case 'achievementStreak3Title':
      return l10n.achievementStreak3Title;
    case 'achievementStreak7Title':
      return l10n.achievementStreak7Title;
    case 'achievementStreak30Title':
      return l10n.achievementStreak30Title;
    case 'achievementWaterFirstGoalTitle':
      return l10n.achievementWaterFirstGoalTitle;
    case 'achievementWaterMasterTitle':
      return l10n.achievementWaterMasterTitle;
    case 'achievementWaterStreak30Title':
      return l10n.achievementWaterStreak30Title;
    case 'achievementDietFirstLogTitle':
      return l10n.achievementDietFirstLogTitle;
    case 'achievementDietStreak7Title':
      return l10n.achievementDietStreak7Title;
    case 'achievementTeamJoinTitle':
      return l10n.achievementTeamJoinTitle;
    case 'achievementSocialButterflyTitle':
      return l10n.achievementSocialButterflyTitle;
    case 'achievementBodyTransformationTitle':
      return l10n.achievementBodyTransformationTitle;
    default:
      return titleKey;
  }
}

/// ARB 키를 업적 설명 번역 문자열로 변환
String _resolveAchievementDesc(String descKey, AppLocalizations l10n) {
  switch (descKey) {
    case 'achievementFirstWorkoutDesc':
      return l10n.achievementFirstWorkoutDesc;
    case 'achievementWorkout10Desc':
      return l10n.achievementWorkout10Desc;
    case 'achievementWorkout50Desc':
      return l10n.achievementWorkout50Desc;
    case 'achievementWorkout100Desc':
      return l10n.achievementWorkout100Desc;
    case 'achievementVolume1000Desc':
      return l10n.achievementVolume1000Desc;
    case 'achievementPrFirstDesc':
      return l10n.achievementPrFirstDesc;
    case 'achievementMorningWarriorDesc':
      return l10n.achievementMorningWarriorDesc;
    case 'achievementVariety10Desc':
      return l10n.achievementVariety10Desc;
    case 'achievementStreak3Desc':
      return l10n.achievementStreak3Desc;
    case 'achievementStreak7Desc':
      return l10n.achievementStreak7Desc;
    case 'achievementStreak30Desc':
      return l10n.achievementStreak30Desc;
    case 'achievementWaterFirstGoalDesc':
      return l10n.achievementWaterFirstGoalDesc;
    case 'achievementWaterMasterDesc':
      return l10n.achievementWaterMasterDesc;
    case 'achievementWaterStreak30Desc':
      return l10n.achievementWaterStreak30Desc;
    case 'achievementDietFirstLogDesc':
      return l10n.achievementDietFirstLogDesc;
    case 'achievementDietStreak7Desc':
      return l10n.achievementDietStreak7Desc;
    case 'achievementTeamJoinDesc':
      return l10n.achievementTeamJoinDesc;
    case 'achievementSocialButterflyDesc':
      return l10n.achievementSocialButterflyDesc;
    case 'achievementBodyTransformationDesc':
      return l10n.achievementBodyTransformationDesc;
    default:
      return descKey;
  }
}

/// Map achievement category to a color.
Color _achievementColor(AchievementCategory category) {
  switch (category) {
    case AchievementCategory.workout:
      return const Color(0xFF1565C0);
    case AchievementCategory.diet:
      return const Color(0xFF4CAF50);
    case AchievementCategory.hydration:
      return Colors.cyan;
    case AchievementCategory.community:
      return const Color(0xFF9C27B0);
    case AchievementCategory.streak:
      return Colors.orange;
    case AchievementCategory.special:
      return const Color(0xFFFFB300);
  }
}

// ---------------------------------------------------------------------------
// StatsScreen
// ---------------------------------------------------------------------------

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weightState = ref.watch(_weightLogProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // ── Workout data from providers ──────────────────────────────────────────
    final records = ref.watch(workoutHistoryProvider);
    final currentStreak = ref.watch(currentStreakProvider);

    final workoutDays = _computeWeeklyWorkoutDays(records, l10n);
    final volumeData = _computeMonthlyVolume(records, l10n);
    final muscleGroups = _computeMuscleGroupRatios(records, l10n);
    final top5 = _computeTop5Exercises(records);

    final avgMinutes = records.isEmpty
        ? 0.0
        : records.map((r) => r.durationSeconds / 60.0).reduce((a, b) => a + b) /
            records.length;

    // ── Diet data from providers ─────────────────────────────────────────────
    final dietState = ref.watch(dietProvider);
    final macroRatios = dietState.macroRatios;
    final proteinRatio = macroRatios['protein'] ?? 0.0;
    final carbsRatio = macroRatios['carbs'] ?? 0.0;
    final fatRatio = macroRatios['fat'] ?? 0.0;
    final nutritionWeek = _computeWeeklyNutrition(dietState.totalCalories, l10n);

    // ── Hydration data from providers ────────────────────────────────────────
    final hydrationState = ref.watch(hydrationProvider);
    final hydrationWeek = _computeWeeklyHydration(hydrationState.totalMl);

    // ── Achievement data from providers ──────────────────────────────────────
    final unlockedAchievements = ref.watch(unlockedAchievementsProvider);
    final totalAchievements = AchievementService.achievements.length;
    final earnedAchievements = unlockedAchievements.length;

    // Convert unlocked achievements to local _Achievement model
    // titleKey/descriptionKey를 l10n으로 변환하여 현재 언어에 맞는 문자열 사용
    final achievementCards = unlockedAchievements.map((a) {
      return _Achievement(
        icon: _achievementIcon(a.icon),
        title: _resolveAchievementTitle(a.titleKey, l10n),
        description: _resolveAchievementDesc(a.descriptionKey, l10n),
        color: _achievementColor(a.category),
        earnedDate: '',
      );
    }).toList();

    // Longest streak: use currentStreak as best-known (no separate historical provider)
    final longestStreak = currentStreak;

    // ── Body composition (local state) ───────────────────────────────────────
    final hasWeightData = weightState.entries.isNotEmpty;
    final targetWeight = 70.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.statsAndProgress,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              ),
            ),
          ),

          // All sections
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Section 1: 운동 통계 ──────────────────────────────────
                _SectionHeader(
                  icon: Icons.fitness_center,
                  title: l10n.workoutStats,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),

                if (records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: EmptyStateWidget(
                      icon: Icons.fitness_center,
                      title: l10n.noWorkoutData,
                      subtitle: l10n.startWorkoutForStats,
                    ),
                  )
                else ...[
                  // 주간 운동 일수 바 차트
                  _ChartCard(
                    title: '${l10n.weeklyWorkoutDays} (최근 8주)',
                    child: _WeeklyWorkoutBarChart(data: workoutDays, l10n: l10n),
                  ),
                  const SizedBox(height: 12),

                  // 월간 총 볼륨 라인 차트
                  _ChartCard(
                    title: '${l10n.monthlyTotalVolume} (최근 6개월)',
                    child: _MonthlyVolumeLineChart(data: volumeData),
                  ),
                  const SizedBox(height: 12),

                  // 부위별 운동 비율 파이 차트
                  if (muscleGroups.isNotEmpty)
                    _ChartCard(
                      title: l10n.muscleGroupRatio,
                      child: _MuscleGroupPieChart(groups: muscleGroups),
                    ),
                  if (muscleGroups.isNotEmpty) const SizedBox(height: 12),

                  // Top 5 운동 + 평균 운동 시간
                  if (top5.isNotEmpty)
                    _WorkoutStatsInfoCard(
                      top5: top5,
                      avgMinutes: avgMinutes,
                      l10n: l10n,
                    ),
                ],
                const SizedBox(height: 20),

                // ── Section 2: 체성분 변화 ────────────────────────────────
                _SectionHeader(
                  icon: Icons.monitor_weight_outlined,
                  title: l10n.bodyComposition,
                  color: const Color(0xFF9C27B0),
                ),
                const SizedBox(height: 12),

                if (!hasWeightData)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: EmptyStateWidget(
                      icon: Icons.monitor_weight_outlined,
                      title: l10n.noWeightData,
                      subtitle: l10n.recordWeightForStats,
                      actionLabel: l10n.addWeightRecord,
                      onAction: () => _showAddWeightDialog(context, ref, l10n),
                    ),
                  )
                else ...[
                  // 체중 변화 라인 차트 (목표선 포함)
                  _ChartCard(
                    title: l10n.weightChange,
                    trailing: TextButton.icon(
                      onPressed: () => _showAddWeightDialog(context, ref, l10n),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addWeightRecord,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    child: _WeightLineChart(
                      entries: weightState.entries,
                      targetWeight: targetWeight,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 체성분 요약 카드 (simplified without body fat)
                  _BodyCompositionSummaryCard(
                    currentWeight: weightState.entries.last.weight,
                    startWeight: weightState.entries.first.weight,
                    currentBodyFat: 0,
                    startBodyFat: 0,
                    targetWeight: targetWeight,
                    l10n: l10n,
                  ),
                ],
                const SizedBox(height: 20),

                // ── Section 3: 영양 통계 ──────────────────────────────────
                _SectionHeader(
                  icon: Icons.restaurant_menu,
                  title: l10n.nutritionStats,
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),

                if (dietState.meals.isEmpty && hydrationState.totalMl == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: EmptyStateWidget(
                      icon: Icons.restaurant_menu,
                      title: l10n.noNutritionData,
                      subtitle: l10n.recordDietForStats,
                    ),
                  )
                else ...[
                  // 주간 칼로리 섭취 바 차트
                  _ChartCard(
                    title: '${l10n.weeklyCalorieIntake} (이번 주)',
                    child: _WeeklyCalorieBarChart(data: nutritionWeek, l10n: l10n),
                  ),
                  const SizedBox(height: 12),

                  // 매크로 비율 도넛 차트
                  if (proteinRatio > 0 || carbsRatio > 0 || fatRatio > 0)
                    _ChartCard(
                      title: l10n.todayMacroRatio,
                      child: _MacroDonutChart(
                        proteinRatio: proteinRatio,
                        carbsRatio: carbsRatio,
                        fatRatio: fatRatio,
                        l10n: l10n,
                      ),
                    ),
                  if (proteinRatio > 0 || carbsRatio > 0 || fatRatio > 0)
                    const SizedBox(height: 12),

                  // 수분 섭취 달성률
                  _HydrationWeekCard(
                      weekData: hydrationWeek,
                      goalMl: hydrationState.goalMl,
                      l10n: l10n),
                ],
                const SizedBox(height: 20),

                // ── Section 4: 스트릭 & 업적 ──────────────────────────────
                _SectionHeader(
                  icon: Icons.emoji_events,
                  title: l10n.streakAndAchievements,
                  color: const Color(0xFFFFB300),
                ),
                const SizedBox(height: 12),

                // 스트릭 카드
                _StreakCard(
                  currentStreak: currentStreak,
                  longestStreak: longestStreak,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),

                // 업적 달성률 진행바
                _AchievementProgressCard(
                  earned: earnedAchievements,
                  total: totalAchievements,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),

                // 최근 달성 업적 카드
                if (achievementCards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '아직 달성한 업적이 없습니다. 운동을 시작해보세요!',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...achievementCards.take(5).map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AchievementCard(achievement: a),
                    ),
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addWeightRecord),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.weightKg,
            hintText: '예: 75.3',
            suffixText: l10n.kg,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref
                    .read(_weightLogProvider.notifier)
                    .addEntry(value, l10n.today);
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable layout widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 Charts – 운동 통계
// ---------------------------------------------------------------------------

/// 주간 운동 일수 바 차트 (최근 8주)
class _WeeklyWorkoutBarChart extends StatelessWidget {
  final List<_WorkoutDayEntry> data;
  final AppLocalizations l10n;
  const _WeeklyWorkoutBarChart({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final groups = data.asMap().entries.map((e) {
      final isLatest = e.key == data.length - 1;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.days.toDouble(),
            color: isLatest
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.45),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: 8,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 24,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  // Show short labels to avoid overflow
                  final labels = [
                    '-8',
                    '-7',
                    '-6',
                    '-5',
                    '-4',
                    '-3',
                    '-2',
                    l10n.weeklyWorkoutDays,
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].weekLabel}\n${rod.toY.toInt()}${l10n.days}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 월간 총 볼륨 라인 차트 (최근 6개월)
class _MonthlyVolumeLineChart extends StatelessWidget {
  final List<_VolumeEntry> data;
  const _MonthlyVolumeLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final maxVolume = data.map((e) => e.volume).fold<double>(0, (a, b) => a > b ? a : b);
    final effectiveMax = maxVolume == 0 ? 1000.0 : maxVolume;
    final chartMaxY = (effectiveMax * 1.2).ceilToDouble();
    final chartMinY = 0.0;
    final interval = (chartMaxY / 4).ceilToDouble().clamp(1.0, double.infinity);

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.volume))
        .toList();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  }
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[index].monthLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.secondary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p1, p2, p3) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: colorScheme.secondary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.secondary.withValues(alpha: 0.12),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${data[s.x.toInt()].monthLabel}\n${(s.y / 1000).toStringAsFixed(1)}t',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 부위별 운동 비율 파이 차트
class _MuscleGroupPieChart extends StatefulWidget {
  final List<_MuscleGroupRatio> groups;
  const _MuscleGroupPieChart({required this.groups});

  @override
  State<_MuscleGroupPieChart> createState() => _MuscleGroupPieChartState();
}

class _MuscleGroupPieChartState extends State<_MuscleGroupPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: widget.groups.asMap().entries.map((e) {
                  final isTouched = e.key == _touchedIndex;
                  return PieChartSectionData(
                    value: e.value.ratio * 100,
                    color: e.value.color,
                    radius: isTouched ? 70 : 60,
                    title: '${(e.value.ratio * 100).toInt()}%',
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.groups
                  .map(
                    (g) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: g.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            g.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(g.ratio * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: g.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top 5 운동 리스트 + 평균 운동 시간 카드
class _WorkoutStatsInfoCard extends StatelessWidget {
  final List<_Top5Exercise> top5;
  final double avgMinutes;
  final AppLocalizations l10n;

  const _WorkoutStatsInfoCard({
    required this.top5,
    required this.avgMinutes,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = top5.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average workout time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.avgWorkoutTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${avgMinutes.toStringAsFixed(0)}${l10n.minutes}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l10n.topExercises,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...top5.asMap().entries.map((e) {
              final rank = e.key + 1;
              final ex = e.value;
              final barWidth = ex.count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: rank == 1
                              ? const Color(0xFFFFB300)
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${ex.count}${l10n.times}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ex.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: barWidth,
                              minHeight: 6,
                              backgroundColor:
                                  ex.color.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ex.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 Charts – 체성분
// ---------------------------------------------------------------------------

/// 체중 변화 라인 차트 (목표선 포함)
class _WeightLineChart extends StatelessWidget {
  final List<_WeightEntry> entries;
  final double targetWeight;
  final AppLocalizations l10n;

  const _WeightLineChart({
    required this.entries,
    required this.targetWeight,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    final weights = entries.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final minY = (minW - 2).clamp(targetWeight - 2, double.infinity);
    final maxY = maxW + 2;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  // Show only first, middle, and last labels
                  if (index == 0 ||
                      index == entries.length - 1 ||
                      index == (entries.length ~/ 2)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entries[index].weekLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: targetWeight,
                color: Colors.green.withValues(alpha: 0.7),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (_) =>
                      '${l10n.goal} ${targetWeight.toStringAsFixed(1)}${l10n.kg}',
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF9C27B0),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p1, p2, index) {
                  final isLast = index == entries.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 5 : 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF9C27B0),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 체성분 요약 카드
class _BodyCompositionSummaryCard extends StatelessWidget {
  final double currentWeight;
  final double startWeight;
  final double currentBodyFat;
  final double startBodyFat;
  final double targetWeight;
  final AppLocalizations l10n;

  const _BodyCompositionSummaryCard({
    required this.currentWeight,
    required this.startWeight,
    required this.currentBodyFat,
    required this.startBodyFat,
    required this.targetWeight,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final weightChange = startWeight - currentWeight;
    final fatReduced = startBodyFat - currentBodyFat;
    final denominator = startWeight - targetWeight;
    final progress = denominator == 0
        ? 0.0
        : ((startWeight - currentWeight) / denominator).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bodyCompSummary,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryStatItem(
                  label: l10n.currentWeight,
                  value: '${currentWeight.toStringAsFixed(1)} ${l10n.kg}',
                  color: const Color(0xFF9C27B0),
                ),
                _SummaryStatItem(
                  label: l10n.weightChange,
                  value: '${weightChange >= 0 ? "-" : "+"}${weightChange.abs().toStringAsFixed(1)} ${l10n.kg}',
                  color: Colors.green,
                ),
                if (currentBodyFat > 0)
                  _SummaryStatItem(
                    label: l10n.bodyFatPercent,
                    value: '-${fatReduced.toStringAsFixed(1)}%',
                    color: Colors.orange,
                  ),
                _SummaryStatItem(
                  label: l10n.goalAchievement,
                  value: '${(progress * 100).toInt()}%',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: progress,
              backgroundColor: Colors.grey.shade200,
              progressColor: const Color(0xFF9C27B0),
              barRadius: const Radius.circular(5),
              padding: EdgeInsets.zero,
              leading: const SizedBox.shrink(),
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.goal} ${targetWeight.toStringAsFixed(1)}${l10n.kg}까지 ${(currentWeight - targetWeight).abs().toStringAsFixed(1)}${l10n.kg} 남았어요',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3 Charts – 영양 통계
// ---------------------------------------------------------------------------

/// 주간 칼로리 바 차트
class _WeeklyCalorieBarChart extends StatelessWidget {
  final List<_NutritionDayEntry> data;
  final AppLocalizations l10n;
  const _WeeklyCalorieBarChart({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    const goalCalories = 2000.0;
    final maxCal = data.map((e) => e.calories).fold<int>(0, (a, b) => a > b ? a : b);
    final chartMaxY = maxCal > goalCalories ? (maxCal * 1.2).ceilToDouble() : 2600.0;

    final groups = data.asMap().entries.map((e) {
      final isOverGoal = e.value.calories > goalCalories;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.calories.toDouble(),
            color: isOverGoal
                ? Colors.orange
                : const Color(0xFF4CAF50),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: chartMaxY,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 500,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[index].dayLabel,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goalCalories,
                color: Colors.red.withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                  labelResolver: (_) => l10n.goal,
                ),
              ),
            ],
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].dayLabel}\n${rod.toY.toInt()} ${l10n.kcal}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 매크로 도넛 차트
class _MacroDonutChart extends StatefulWidget {
  final double proteinRatio;
  final double carbsRatio;
  final double fatRatio;
  final AppLocalizations l10n;

  const _MacroDonutChart({
    required this.proteinRatio,
    required this.carbsRatio,
    required this.fatRatio,
    required this.l10n,
  });

  @override
  State<_MacroDonutChart> createState() => _MacroDonutChartState();
}

class _MacroDonutChartState extends State<_MacroDonutChart> {
  int _touchedIndex = -1;

  static const _macroColors = [
    Color(0xFF1565C0), // 단백질
    Color(0xFFFF9800), // 탄수화물
    Color(0xFFE53935), // 지방
  ];

  @override
  Widget build(BuildContext context) {
    final ratios = [
      widget.proteinRatio,
      widget.carbsRatio,
      widget.fatRatio,
    ];
    final labels = [widget.l10n.protein, widget.l10n.carbs, widget.l10n.fat];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: ratios.asMap().entries.map((e) {
                  final isTouched = e.key == _touchedIndex;
                  return PieChartSectionData(
                    value: e.value * 100,
                    color: _macroColors[e.key],
                    radius: isTouched ? 55 : 45,
                    title: '${(e.value * 100).toInt()}%',
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 13 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ratios.asMap().entries.map((e) {
                // Approximate gram values assuming 2000 kcal/day
                final gramsMap = [
                  (widget.proteinRatio * 2000 / 4).round(),
                  (widget.carbsRatio * 2000 / 4).round(),
                  (widget.fatRatio * 2000 / 9).round(),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _macroColors[e.key],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labels[e.key],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${gramsMap[e.key]}g',
                            style: TextStyle(
                              fontSize: 11,
                              color: _macroColors[e.key],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${(e.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _macroColors[e.key],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 수분 섭취 달성률 (주간)
class _HydrationWeekCard extends StatelessWidget {
  final List<int> weekData; // ml per day
  final int goalMl;
  final AppLocalizations l10n;
  const _HydrationWeekCard(
      {required this.weekData, this.goalMl = AppDefaults.dailyWaterGoalMl, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final goal = goalMl;
    final achieved =
        weekData.where((ml) => ml >= goal).length;
    final totalMl = weekData.fold<int>(0, (a, b) => a + b);
    final nonZeroDays = weekData.where((ml) => ml > 0).length;
    final avgMl = nonZeroDays > 0 ? totalMl / nonZeroDays : 0.0;
    final dayLabels = [
      l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun,
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${l10n.hydrationAchievementRate} (이번 주)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$achieved/7${l10n.days} 달성',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekData.asMap().entries.map((e) {
                final percent = goal > 0 ? (e.value / goal).clamp(0.0, 1.0) : 0.0;
                final isAchieved = e.value >= goal;
                return Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 26,
                      lineWidth: 5,
                      percent: percent,
                      center: Text(
                        isAchieved ? '✓' : '${(percent * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: isAchieved ? 13 : 9,
                          fontWeight: FontWeight.bold,
                          color: isAchieved ? Colors.cyan : Colors.grey,
                        ),
                      ),
                      progressColor:
                          isAchieved ? Colors.cyan : Colors.cyan.withValues(alpha: 0.5),
                      backgroundColor: Colors.grey.shade200,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabels[e.key],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '일평균 ${avgMl.toStringAsFixed(0)}ml · ${l10n.goal} ${goal}ml',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
// Section 4 – 스트릭 & 업적
// ---------------------------------------------------------------------------

/// 스트릭 카드
class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final AppLocalizations l10n;

  const _StreakCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 현재 스트릭
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$currentStreak',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currentConsecutiveDays,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey.shade200,
            ),
            // 최장 스트릭
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFFB300),
                        size: 28,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$longestStreak',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFB300),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.longestStreak,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 업적 달성률 진행바 카드
class _AchievementProgressCard extends StatelessWidget {
  final int earned;
  final int total;
  final AppLocalizations l10n;

  const _AchievementProgressCard({
    required this.earned,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? earned / total : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFFFB300).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.military_tech,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.overallAchievementRate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$earned / $total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 12,
              percent: progress,
              backgroundColor: Colors.grey.shade200,
              linearGradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
              ),
              barRadius: const Radius.circular(6),
              padding: EdgeInsets.zero,
              leading: const SizedBox.shrink(),
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.achievementsRemaining(total - earned),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 개별 업적 카드
class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: achievement.color.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    achievement.color.withValues(alpha: 0.8),
                    achievement.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: achievement.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '달성',
                    style: TextStyle(
                      fontSize: 11,
                      color: achievement.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (achievement.earnedDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    achievement.earnedDate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
