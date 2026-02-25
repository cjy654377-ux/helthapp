import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/workout_guide/providers/exercise_database_provider.dart';
import 'package:health_app/core/widgets/common_states.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// WorkoutLogScreen
// ---------------------------------------------------------------------------

class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  // Tracks whether the completion screen should be shown
  bool _showCompletion = false;
  double _completedVolume = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(workoutSessionProvider);

    if (_showCompletion) {
      return _CompletionScreen(totalVolume: _completedVolume);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.todayWorkoutTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (session.exercises.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showCompleteDialog(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.complete),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
        ],
      ),
      body: Column(
        children: [
          // Total volume + elapsed time bar
          _TotalVolumeBar(
            totalVolume: session.totalVolume,
            elapsedSeconds: session.elapsedSeconds,
            isActive: session.isActive,
          ),

          // Rest timer banner
          if (session.isRestTimerRunning && session.restTimerSeconds > 0)
            _RestTimerBanner(
              seconds: session.restTimerSeconds,
              onStop: () =>
                  ref.read(workoutSessionProvider.notifier).stopRestTimer(),
            ),

          // Exercise list
          Expanded(
            child: session.exercises.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.fitness_center,
                    title: l10n.addExercisePrompt,
                    subtitle: l10n.addExerciseSubtitle,
                    actionLabel: l10n.addExercise,
                    onAction: () => _showAddExerciseDialog(context),
                  )
                : RefreshIndicator(
                    // 운동 기록 새로고침: provider 재생성으로 최신 데이터 로드
                    onRefresh: () async {
                      ref.invalidate(workoutHistoryProvider);
                    },
                    child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: session.exercises.map((exercise) {
                      return _ExerciseCard(
                        exercise: exercise,
                        isNewPr: session.newPrExerciseIds
                            .contains(exercise.exerciseId),
                        onAddSet: () => ref
                            .read(workoutSessionProvider.notifier)
                            .addSet(exercise.exerciseId),
                        onRemoveSet: (i) => ref
                            .read(workoutSessionProvider.notifier)
                            .removeSet(exercise.exerciseId, i),
                        onUpdateSet: (i, w, r) => ref
                            .read(workoutSessionProvider.notifier)
                            .updateSet(exercise.exerciseId, i,
                                weight: w, reps: r),
                        onToggleSetComplete: (i) => ref
                            .read(workoutSessionProvider.notifier)
                            .toggleSetComplete(exercise.exerciseId, i),
                        onRemoveExercise: () => ref
                            .read(workoutSessionProvider.notifier)
                            .removeExercise(exercise.exerciseId),
                        onStartRest: (s) => ref
                            .read(workoutSessionProvider.notifier)
                            .startRestTimer(s),
                      );
                    }).toList(),
                  ),
                    ),
          ),
        ],
      ),
      floatingActionButton: session.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addExercise),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Add Exercise Dialog
  // ---------------------------------------------------------------------------

  void _showAddExerciseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddExerciseSheet(
        onExerciseSelected: (exercise) {
          final notifier = ref.read(workoutSessionProvider.notifier);
          final session = ref.read(workoutSessionProvider);
          // Start the session on the first exercise add
          if (!session.hasStarted) {
            notifier.startSession();
          }
          notifier.addExercise(exercise);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Complete Workout Dialog
  // ---------------------------------------------------------------------------

  void _showCompleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutComplete),
        content: Text(l10n.completeWorkoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              _completeWorkout();
            },
            child: Text(l10n.complete),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWorkout() async {
    final notifier = ref.read(workoutSessionProvider.notifier);
    final record = notifier.completeSession();
    if (record != null) {
      await ref
          .read(workoutHistoryProvider.notifier)
          .saveRecord(record);
      if (mounted) {
        setState(() {
          _completedVolume = record.totalVolume;
          _showCompletion = true;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Add Exercise Bottom Sheet
// ---------------------------------------------------------------------------

String _localizedBodyPart(AppLocalizations l10n, String part) {
  return switch (part) {
    '가슴' => l10n.chest,
    '등' => l10n.back,
    '어깨' => l10n.shoulders,
    '팔' => l10n.arms,
    '하체' => l10n.legs,
    '코어' => l10n.core,
    _ => part,
  };
}

class _AddExerciseSheet extends ConsumerStatefulWidget {
  final ValueChanged<Exercise> onExerciseSelected;

  const _AddExerciseSheet({required this.onExerciseSelected});

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  BodyPart? _selectedBodyPart;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> get _filteredExercises {
    return kAllExercises.where((e) {
      final matchesBodyPart =
          _selectedBodyPart == null || e.bodyPart == _selectedBodyPart;
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.nameEn.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesBodyPart && matchesSearch;
    }).toList();
  }

  /// Groups exercises by BodyPart, preserving body-part order from BodyPart enum.
  Map<BodyPart, List<Exercise>> get _groupedExercises {
    final grouped = <BodyPart, List<Exercise>>{};
    for (final e in _filteredExercises) {
      grouped.putIfAbsent(e.bodyPart, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grouped = _groupedExercises;
    // Build a flat list: section header + exercise tiles
    final List<Widget> items = [];
    grouped.forEach((bodyPart, exercises) {
      items.add(_BodyPartHeader(
          label: _localizedBodyPart(l10n, bodyPart.label)));
      for (final exercise in exercises) {
        items.add(_ExerciseTile(
          exercise: exercise,
          onTap: () => widget.onExerciseSelected(exercise),
        ));
      }
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.addExercise,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: l10n.searchExercise,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Body part filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: l10n.all,
                  selected: _selectedBodyPart == null,
                  onTap: () => setState(() => _selectedBodyPart = null),
                ),
                ...BodyPart.values
                    .where((bp) =>
                        bp != BodyPart.fullBody && bp != BodyPart.cardio)
                    .map((bp) => _FilterChip(
                          label: _localizedBodyPart(l10n, bp.label),
                          selected: _selectedBodyPart == bp,
                          onTap: () => setState(() =>
                              _selectedBodyPart =
                                  _selectedBodyPart == bp ? null : bp),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Exercise list grouped by body part
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(l10n.noSearchResults))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (_, i) => items[i],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BodyPartHeader extends StatelessWidget {
  final String label;
  const _BodyPartHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.8),
        child: Icon(
          Icons.fitness_center,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        '${exercise.equipment.label} · ${exercise.difficulty.label}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: exercise.isCompound
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.compound,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Volume + Elapsed Time Bar
// ---------------------------------------------------------------------------

class _TotalVolumeBar extends StatelessWidget {
  final double totalVolume;
  final int elapsedSeconds;
  final bool isActive;

  const _TotalVolumeBar({
    required this.totalVolume,
    required this.elapsedSeconds,
    required this.isActive,
  });

  String get _elapsed {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, size: 18),
          const SizedBox(width: 6),
          Text(l10n.totalVolumeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            '${totalVolume.toStringAsFixed(0)} kg',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (isActive) ...[
            const Icon(Icons.timer_outlined, size: 16),
            const SizedBox(width: 4),
            Text(
              _elapsed,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rest Timer Banner
// ---------------------------------------------------------------------------

class _RestTimerBanner extends StatelessWidget {
  final int seconds;
  final VoidCallback onStop;

  const _RestTimerBanner({required this.seconds, required this.onStop});

  String get _formatted {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            l10n.restTimerLabel,
            style:
                const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blue, size: 20),
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------



// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatefulWidget {
  final ExerciseEntry exercise;
  final bool isNewPr;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final Function(int, double?, int?) onUpdateSet;
  final ValueChanged<int> onToggleSetComplete;
  final VoidCallback onRemoveExercise;
  final ValueChanged<int> onStartRest;

  const _ExerciseCard({
    required this.exercise,
    required this.isNewPr,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onToggleSetComplete,
    required this.onRemoveExercise,
    required this.onStartRest,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = widget.exercise;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isNewPr
              ? Colors.amber.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.2),
          width: widget.isNewPr ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.fitness_center,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.isNewPr)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${l10n.volumeInfo(exercise.totalVolume.toStringAsFixed(0))}  '
              '· ${l10n.complete}: ${exercise.completedSets}/${exercise.sets.length}${l10n.set}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onPressed: () =>
                      setState(() => _isExpanded = !_isExpanded),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') widget.onRemoveExercise();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.deleteExercise,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Set column header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      l10n.setHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.weightKgHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.repsHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.volumeLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: Text(
                      l10n.completedHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // Set rows
            ...exercise.sets.asMap().entries.map((entry) {
              final i = entry.key;
              final set = entry.value;
              return _SetRow(
                set: set,
                onWeightChanged: (w) =>
                    widget.onUpdateSet(i, w, null),
                onRepsChanged: (r) =>
                    widget.onUpdateSet(i, null, r),
                onToggleComplete: () => widget.onToggleSetComplete(i),
                onRemove: () => widget.onRemoveSet(i),
              );
            }),

            // Actions row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onAddSet();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addSet),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<int>(
                    onSelected: widget.onStartRest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            l10n.rest,
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) {
                      final restL10n = AppLocalizations.of(ctx);
                      return [
                        PopupMenuItem(
                            value: 60,
                            child: Text(restL10n.restOneMinute)),
                        PopupMenuItem(
                            value: 90,
                            child: Text(restL10n.restOneMinuteHalf)),
                        PopupMenuItem(
                            value: 120,
                            child: Text(restL10n.restTwoMinutes)),
                        PopupMenuItem(
                            value: 180,
                            child: Text(restL10n.restThreeMinutes)),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Set Row
// ---------------------------------------------------------------------------

class _SetRow extends StatelessWidget {
  final SetEntry set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleComplete;
  final VoidCallback onRemove;

  const _SetRow({
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleComplete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isWarmup = set.isWarmup;
    final isCompleted = set.isCompleted;

    final badgeColor = isWarmup
        ? Colors.orange.withValues(alpha: 0.15)
        : Colors.blue.withValues(alpha: 0.1);
    final badgeTextColor = isWarmup ? Colors.orange : Colors.blue;
    final badgeLabel = isWarmup ? 'W' : '${set.setNumber}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isCompleted
          ? Colors.green.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Set number / warmup badge
          SizedBox(
            width: 36,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: badgeColor,
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Weight input
          Expanded(
            child: _NumberInput(
              initialValue:
                  set.weight == 0 ? '' : set.weight.toString(),
              hint: '0',
              enabled: !isCompleted,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) onWeightChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Reps input
          Expanded(
            child: _NumberInput(
              initialValue:
                  set.reps == 0 ? '' : set.reps.toString(),
              hint: '0',
              enabled: !isCompleted,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) onRepsChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Volume display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                isCompleted
                    ? '${set.volume.toStringAsFixed(0)} kg'
                    : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Complete checkbox
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isCompleted,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                onToggleComplete();
              },
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Remove set button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 18),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Number Input
// ---------------------------------------------------------------------------

class _NumberInput extends StatelessWidget {
  final String initialValue;
  final String hint;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _NumberInput({
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: enabled ? null : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2)),
        ),
        filled: !enabled,
        fillColor: enabled
            ? null
            : Colors.grey.withValues(alpha: 0.06),
      ),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Completion Screen
// ---------------------------------------------------------------------------

class _CompletionScreen extends StatelessWidget {
  final double totalVolume;
  const _CompletionScreen({required this.totalVolume});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.workoutDone,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.greatJobToday,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.totalVolume,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '${totalVolume.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
