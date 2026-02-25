import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/features/calendar/providers/calendar_providers.dart';
import 'package:health_app/core/widgets/common_states.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Split template helpers (pure UI helpers, no local state)
// ---------------------------------------------------------------------------

Color _splitColor(String? splitType) {
  switch (splitType) {
    case 'ppl':
      return Colors.blue;
    case 'upper_lower':
      return Colors.purple;
    case 'full_body':
      return Colors.green;
    default:
      return Colors.orange;
  }
}

String _splitLabel(AppLocalizations l10n, String? splitType) {
  switch (splitType) {
    case 'ppl':
      return l10n.splitLabelPpl;
    case 'upper_lower':
      return l10n.splitLabelUpperLower;
    case 'full_body':
      return l10n.splitLabelFullBody;
    default:
      return l10n.splitLabelCustom;
  }
}

// ---------------------------------------------------------------------------
// CalendarScreen
// ---------------------------------------------------------------------------

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final calendarState = ref.watch(calendarProvider);
    final selectedDay = ref.watch(selectedDateProvider);
    final selectedPlans = ref.watch(selectedDatePlansProvider);
    final focusedDay = calendarState.focusedMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.workoutCalendar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_week_outlined),
            tooltip: l10n.splitTemplate,
            onSelected: (template) =>
                _applyTemplate(context, template, ref),
            itemBuilder: (_) => [
              _buildTemplateMenuItem(l10n, 'ppl'),
              _buildTemplateMenuItem(l10n, 'upper_lower'),
              _buildTemplateMenuItem(l10n, 'full_body'),
              _buildTemplateMenuItem(l10n, 'custom'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar<WorkoutPlanEntry>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            eventLoader: (day) => calendarState.getPlansForDate(day),
            onDaySelected: (selected, focused) {
              ref.read(calendarProvider.notifier).selectDate(selected);
              ref.read(calendarProvider.notifier).changeFocusedMonth(focused);
            },
            onPageChanged: (focused) {
              ref.read(calendarProvider.notifier).changeFocusedMonth(focused);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),

          const Divider(height: 1),

          // Selected day plans
          Expanded(
            child: _DayPlanList(
              selectedDay: selectedDay,
              plans: selectedPlans,
              onRemove: (planId) => ref
                  .read(calendarProvider.notifier)
                  .removePlan(selectedDay, planId),
              onToggleComplete: (planId) => ref
                  .read(calendarProvider.notifier)
                  .togglePlanComplete(selectedDay, planId),
              onAdd: () => _showAddPlanDialog(context, selectedDay, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context, selectedDay, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  PopupMenuItem<String> _buildTemplateMenuItem(
      AppLocalizations l10n, String value) {
    final splitType = value == 'custom' ? null : value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _splitColor(splitType),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(_splitLabel(l10n, splitType)),
        ],
      ),
    );
  }

  void _applyTemplate(
      BuildContext context, String template, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    switch (template) {
      case 'ppl':
        ref.read(calendarProvider.notifier).applyPPLSplit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.templateAppliedPpl),
            backgroundColor: _splitColor('ppl'),
          ),
        );
        break;
      case 'upper_lower':
        ref.read(calendarProvider.notifier).applyUpperLowerSplit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.templateAppliedUpperLower),
            backgroundColor: _splitColor('upper_lower'),
          ),
        );
        break;
      case 'full_body':
        ref.read(calendarProvider.notifier).applyFullBodySplit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.templateAppliedFullBody),
            backgroundColor: _splitColor('full_body'),
          ),
        );
        break;
      case 'custom':
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.templateAppliedCustom),
            backgroundColor: _splitColor(null),
          ),
        );
        break;
    }
  }

  void _showAddPlanDialog(
      BuildContext context, DateTime date, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String selectedTitle = '';
    List<String> selectedBodyParts = [];
    String? selectedSplitType; // null = custom/orange

    final bodyPartOptions = [
      l10n.chest,
      l10n.back,
      l10n.shoulders,
      l10n.arms,
      l10n.legs,
      l10n.core,
    ];
    const splitOptions = <String?>['ppl', 'upper_lower', 'full_body', null];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addPlanForDate(date.month, date.day),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.exerciseName,
                    hintText: l10n.exerciseNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => selectedTitle = v,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.bodyParts,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bodyPartOptions.map((part) {
                    final isSelected = selectedBodyParts.contains(part);
                    return FilterChip(
                      label: Text(part),
                      selected: isSelected,
                      onSelected: (v) {
                        setModalState(() {
                          if (v) {
                            selectedBodyParts.add(part);
                          } else {
                            selectedBodyParts.remove(part);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.splitTemplate,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: splitOptions.map((type) {
                    return ChoiceChip(
                      label: Text(_splitLabel(l10n, type)),
                      selected: selectedSplitType == type,
                      selectedColor:
                          _splitColor(type).withValues(alpha: 0.2),
                      onSelected: (_) =>
                          setModalState(() => selectedSplitType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedTitle.isNotEmpty) {
                        final plan = WorkoutPlanEntry(
                          id: const Uuid().v4(),
                          title: selectedTitle,
                          targetBodyParts: List<String>.from(selectedBodyParts),
                          splitType: selectedSplitType,
                        );
                        ref
                            .read(calendarProvider.notifier)
                            .addPlan(date, plan);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.addPlanAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day Plan List
// ---------------------------------------------------------------------------

class _DayPlanList extends StatelessWidget {
  final DateTime selectedDay;
  final List<WorkoutPlanEntry> plans;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onToggleComplete;
  final VoidCallback onAdd;

  const _DayPlanList({
    required this.selectedDay,
    required this.plans,
    required this.onRemove,
    required this.onToggleComplete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekdayLabels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final dayLabel = weekdayLabels[selectedDay.weekday - 1];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                l10n.dateFormatMonthDay(
                    selectedDay.month, selectedDay.day, dayLabel),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: plans.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.event_note,
                  title: l10n.noWorkoutPlan,
                  subtitle: l10n.addWorkoutPlanSubtitle,
                  actionLabel: l10n.addPlan,
                  onAction: onAdd,
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: plans.length,
                  itemBuilder: (_, i) => _PlanCard(
                    plan: plans[i],
                    onRemove: () => onRemove(plans[i].id),
                    onToggleComplete: () => onToggleComplete(plans[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan Card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final WorkoutPlanEntry plan;
  final VoidCallback onRemove;
  final VoidCallback onToggleComplete;

  const _PlanCard({
    required this.plan,
    required this.onRemove,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _splitColor(plan.splitType);
    final label = _splitLabel(l10n, plan.splitType);
    final isCompleted = plan.isCompleted;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggleComplete,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Split type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Completed badge
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 11, color: Colors.green),
                          const SizedBox(width: 3),
                          Text(
                            l10n.planCompleted,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.grey),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Title with strikethrough when completed
              Text(
                plan.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
              if (plan.targetBodyParts.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: plan.targetBodyParts
                      .map(
                        (part) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            part,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Text(
                  plan.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
