import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// HydrationScreen
// ---------------------------------------------------------------------------

class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  Future<Map<DateTime, int>>? _weeklyStatsFuture;

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  void _loadWeeklyStats() {
    setState(() {
      _weeklyStatsFuture =
          ref.read(hydrationProvider.notifier).getWeeklyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hydrationProvider);
    final timelineEntries = ref.watch(waterTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.hydration,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        // 수분 데이터 새로고침: provider 재생성 + 주간 통계 재로드
        onRefresh: () async {
          ref.invalidate(hydrationProvider);
          _loadWeeklyStats();
        },
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HydrationRing(
            totalMl: state.totalMl,
            goalMl: state.goalMl,
            progress: state.progress,
            remainingMl: state.remainingMl,
          ),
          const SizedBox(height: 20),
          _QuickAddSection(
            onAdd: (ml) =>
                ref.read(hydrationProvider.notifier).addWater(ml),
          ),
          const SizedBox(height: 20),
          _TimelineSection(
            entries: timelineEntries,
            onRemove: (entryId) =>
                ref.read(hydrationProvider.notifier).removeEntry(entryId),
          ),
          const SizedBox(height: 20),
          _WeeklyChartSection(
            weeklyStatsFuture: _weeklyStatsFuture,
            goalMl: state.goalMl,
            onRefresh: _loadWeeklyStats,
          ),
          const SizedBox(height: 80),
        ],
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
        title: Text(l10n.notificationSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.setHydrationReminder),
            const SizedBox(height: 16),
            ...{
              l10n.everyOneHour: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
              l10n.everyTwoHours: [9, 11, 13, 15, 17, 19, 21],
              l10n.everyThreeHours: [9, 12, 15, 18, 21],
            }.entries.map(
              (e) => ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(e.key),
                onTap: () {
                  ref
                      .read(hydrationProvider.notifier)
                      .setReminderHours(e.value);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.reminderSet(e.key))),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration Ring
// ---------------------------------------------------------------------------

class _HydrationRing extends StatelessWidget {
  final int totalMl;
  final int goalMl;
  final double progress;
  final int remainingMl;

  const _HydrationRing({
    required this.totalMl,
    required this.goalMl,
    required this.progress,
    required this.remainingMl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOver = totalMl > goalMl;
    final displayRemaining = isOver ? totalMl - goalMl : remainingMl;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.cyan.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 100,
              lineWidth: 16,
              percent: progress,
              animation: true,
              animateFromLastPercent: true,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, color: Colors.cyan, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '$totalMl',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                  const Text(
                    'ml',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.cyan,
                    ),
                  ),
                ],
              ),
              progressColor: Colors.cyan,
              backgroundColor: Colors.cyan.withValues(alpha: 0.2),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HydrationStat(
                  label: l10n.goal,
                  value: '${goalMl}ml',
                  color: Colors.grey,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.cyan.shade100,
                ),
                _HydrationStat(
                  label: l10n.achievementRate,
                  value: '${(progress * 100).toInt()}%',
                  color: Colors.cyan,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.cyan.shade100,
                ),
                _HydrationStat(
                  label: isOver ? l10n.exceeded : l10n.remaining,
                  value: '${displayRemaining}ml',
                  color: isOver ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HydrationStat({
    required this.label,
    required this.value,
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Add Section
// ---------------------------------------------------------------------------

class _QuickAddSection extends StatelessWidget {
  final ValueChanged<int> onAdd;
  const _QuickAddSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).quickAdd,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AddButton(
                ml: 150,
                label: '150ml',
                icon: Icons.local_cafe,
                color: Colors.brown.shade300,
                onTap: () => onAdd(150),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AddButton(
                ml: 250,
                label: '250ml',
                icon: Icons.local_drink,
                color: Colors.cyan,
                onTap: () => onAdd(250),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AddButton(
                ml: 500,
                label: '500ml',
                icon: Icons.water_drop,
                color: Colors.blue,
                onTap: () => onAdd(500),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CustomAddButton(onAdd: onAdd),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final int ml;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AddButton({
    required this.ml,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomAddButton extends StatelessWidget {
  final ValueChanged<int> onAdd;
  const _CustomAddButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomDialog(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.edit, color: Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).custom,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.customInput),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.intakeAmountMl,
            suffixText: 'ml',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                onAdd(ml);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Section
// ---------------------------------------------------------------------------

class _TimelineSection extends StatelessWidget {
  final List<WaterIntakeEntry> entries;
  final ValueChanged<String> onRemove;

  const _TimelineSection({
    required this.entries,
    required this.onRemove,
  });

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.todayIntakeLog,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${entries.length}회',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.noRecordYet, style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final entry = mapEntry.value;
            final isLast = i == entries.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot & line
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.cyan.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 16,
                        left: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.amountMl} ml',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  _formatTime(entry.time),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () => onRemove(entry.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly Chart Section
// ---------------------------------------------------------------------------

class _WeeklyChartSection extends StatelessWidget {
  final Future<Map<DateTime, int>>? weeklyStatsFuture;
  final int goalMl;
  final VoidCallback onRefresh;

  const _WeeklyChartSection({
    required this.weeklyStatsFuture,
    required this.goalMl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyHydration,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<DateTime, int>>(
          future: weeklyStatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Card(
                child: SizedBox(
                  height: 240,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.cannotLoadData),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onRefresh,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final statsMap = snapshot.data!;
            // Sort dates ascending (oldest first, today last)
            final sortedDates = statsMap.keys.toList()
              ..sort((a, b) => a.compareTo(b));
            final weeklyData =
                sortedDates.map((d) => statsMap[d] ?? 0).toList();

            return _WeeklyBarChart(
              weeklyData: weeklyData,
              goalMl: goalMl,
              sortedDates: sortedDates,
            );
          },
        ),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> weeklyData;
  final int goalMl;
  final List<DateTime> sortedDates;

  const _WeeklyBarChart({
    required this.weeklyData,
    required this.goalMl,
    required this.sortedDates,
  });

  String _dayLabel(int index, BuildContext context) {
    if (index < 0 || index >= sortedDates.length) return '';
    final date = sortedDates[index];
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final l10n = AppLocalizations.of(context);
    if (isToday) return l10n.today;
    final weekdays = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    // weekday: 1=Mon, 7=Sun
    return weekdays[(date.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = weeklyData.length - 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (goalMl * 1.3).toDouble(),
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      final label = _dayLabel(i, context);
                      if (label.isEmpty) return const SizedBox.shrink();
                      final isToday = i == todayIndex;
                      return Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.cyan : Colors.grey,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goalMl.toDouble(),
                    color: Colors.cyan.withValues(alpha: 0.5),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 10,
                      ),
                      labelResolver: (_) => AppLocalizations.of(context).goalWithMl(goalMl),
                    ),
                  ),
                ],
              ),
              barGroups: weeklyData.asMap().entries.map((entry) {
                final i = entry.key;
                final ml = entry.value.toDouble();
                final isToday = i == todayIndex;
                final reachedGoal = ml >= goalMl;

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: ml,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      color: isToday
                          ? Colors.cyan
                          : reachedGoal
                              ? Colors.cyan.withValues(alpha: 0.6)
                              : Colors.cyan.withValues(alpha: 0.25),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
