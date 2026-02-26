import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/workout_log/widgets/music_mini_player.dart';
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
          // 총 볼륨 + 경과 시간 바
          _TotalVolumeBar(
            totalVolume: session.totalVolume,
            elapsedSeconds: session.elapsedSeconds,
            isActive: session.isActive,
          ),

          // 음악 미니 플레이어 (세션 활성 시에만 표시)
          if (session.isActive) const MusicMiniPlayer(),

          // 휴식 타이머 배너
          if (session.isRestTimerRunning && session.restTimerSeconds > 0)
            _RestTimerBanner(
              seconds: session.restTimerSeconds,
              onStop: () =>
                  ref.read(workoutSessionProvider.notifier).stopRestTimer(),
            ),

          // 운동 목록
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
                    onRefresh: () async {
                      ref.invalidate(workoutHistoryProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: session.exercises.asMap().entries.map((entry) {
                        final exerciseIndex = entry.key;
                        final exercise = entry.value;
                        final supersetGroupId =
                            ref.read(workoutSessionProvider.notifier)
                                .isSupersetted(exerciseIndex);
                        return _ExerciseCard(
                          exercise: exercise,
                          exerciseIndex: exerciseIndex,
                          supersetGroupId: supersetGroupId,
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
                          onUpdateSetRpe: (i, rpe) => ref
                              .read(workoutSessionProvider.notifier)
                              .updateSet(exercise.exerciseId, i, rpe: rpe),
                          onUpdateSetType: (i, type) => ref
                              .read(workoutSessionProvider.notifier)
                              .updateSet(exercise.exerciseId, i, setType: type),
                          onToggleSetComplete: (i) => ref
                              .read(workoutSessionProvider.notifier)
                              .toggleSetComplete(exercise.exerciseId, i),
                          onRemoveExercise: () => ref
                              .read(workoutSessionProvider.notifier)
                              .removeExercise(exercise.exerciseId),
                          onStartRest: (s) => ref
                              .read(workoutSessionProvider.notifier)
                              .startRestTimer(s),
                          onAddWarmup: () =>
                              _showWarmupDialog(context, exercise.exerciseId),
                          onSwapExercise: () =>
                              _showSwapExerciseSheet(context, exercise),
                          onLinkSuperset: () =>
                              _showSupersetDialog(context, exerciseIndex),
                          onRemoveSuperset: supersetGroupId != null
                              ? () => ref
                                  .read(workoutSessionProvider.notifier)
                                  .removeSupersetGroup(supersetGroupId)
                              : null,
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
  // 운동 추가 다이얼로그
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
  // 워밍업 세트 생성 다이얼로그
  // ---------------------------------------------------------------------------

  void _showWarmupDialog(BuildContext context, String exerciseId) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.generateWarmup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.workingWeight),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                suffixText: 'kg',
                hintText: '60',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                ref
                    .read(workoutSessionProvider.notifier)
                    .insertWarmupSets(exerciseId, weight);
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.addWarmup),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 운동 교체 바텀시트
  // ---------------------------------------------------------------------------

  void _showSwapExerciseSheet(BuildContext context, ExerciseEntry exercise) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // 같은 부위의 다른 운동 목록
        final alternatives = kAllExercises
            .where((e) =>
                e.bodyPart == exercise.bodyPart &&
                e.id != exercise.exerciseId)
            .toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
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
                l10n.selectAlternative,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.name,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: alternatives.isEmpty
                    ? Center(child: Text(l10n.noSearchResults))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: alternatives.length,
                        itemBuilder: (_, i) {
                          final alt = alternatives[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.fitness_center, size: 16),
                            ),
                            title: Text(alt.name),
                            subtitle: Text(
                              '${alt.equipment.label} · ${alt.difficulty.label}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              ref
                                  .read(workoutSessionProvider.notifier)
                                  .replaceExercise(exercise.exerciseId, alt);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 슈퍼셋 연결 다이얼로그
  // ---------------------------------------------------------------------------

  void _showSupersetDialog(BuildContext context, int exerciseIndex) {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(workoutSessionProvider);
    final selectedIndices = <int>{exerciseIndex};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.linkAsSuperset),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: session.exercises.asMap().entries.map((entry) {
                final idx = entry.key;
                final ex = entry.value;
                return CheckboxListTile(
                  title: Text(ex.name, style: const TextStyle(fontSize: 14)),
                  value: selectedIndices.contains(idx),
                  onChanged: idx == exerciseIndex
                      ? null // 현재 운동은 항상 선택
                      : (v) {
                          setDialogState(() {
                            if (v == true) {
                              selectedIndices.add(idx);
                            } else {
                              selectedIndices.remove(idx);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: selectedIndices.length >= 2
                  ? () {
                      ref
                          .read(workoutSessionProvider.notifier)
                          .createSuperset(selectedIndices.toList()..sort());
                      Navigator.pop(ctx);
                    }
                  : null,
              child: Text(l10n.superset),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 운동 완료 다이얼로그
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
// 운동 추가 바텀시트
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
// 총 볼륨 + 경과 시간 바
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
// 휴식 타이머 배너
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
// 운동 카드
// ---------------------------------------------------------------------------

class _ExerciseCard extends ConsumerStatefulWidget {
  final ExerciseEntry exercise;
  final int exerciseIndex;
  final int? supersetGroupId;
  final bool isNewPr;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final Function(int, double?, int?) onUpdateSet;
  final Function(int, int?) onUpdateSetRpe;
  final Function(int, SetType) onUpdateSetType;
  final ValueChanged<int> onToggleSetComplete;
  final VoidCallback onRemoveExercise;
  final ValueChanged<int> onStartRest;
  final VoidCallback onAddWarmup;
  final VoidCallback onSwapExercise;
  final VoidCallback onLinkSuperset;
  final VoidCallback? onRemoveSuperset;

  const _ExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    this.supersetGroupId,
    required this.isNewPr,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateSetRpe,
    required this.onUpdateSetType,
    required this.onToggleSetComplete,
    required this.onRemoveExercise,
    required this.onStartRest,
    required this.onAddWarmup,
    required this.onSwapExercise,
    required this.onLinkSuperset,
    this.onRemoveSuperset,
  });

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  bool _isExpanded = true;

  // 슈퍼셋 그룹에 사용할 색상 목록
  static const List<Color> _supersetColors = [
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
  ];

  Color? get _supersetColor {
    if (widget.supersetGroupId == null) return null;
    return _supersetColors[widget.supersetGroupId! % _supersetColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = widget.exercise;
    final supersetColor = _supersetColor;

    // e1RM 표시
    final e1rm = ref.watch(estimated1RMProvider(exercise.exerciseId));

    Widget card = Card(
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
          // 슈퍼셋 배지
          if (supersetColor != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: supersetColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: supersetColor),
                  const SizedBox(width: 4),
                  Text(
                    l10n.superset,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: supersetColor,
                    ),
                  ),
                ],
              ),
            ),

          // 헤더
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // e1RM 표시
                      if (e1rm != null)
                        Text(
                          '${l10n.estimated1RM}: ${e1rm.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
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
                // 운동 교체 버튼
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  tooltip: l10n.swapExercise,
                  onPressed: widget.onSwapExercise,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
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
                    if (v == 'superset') widget.onLinkSuperset();
                    if (v == 'removeSuperset' &&
                        widget.onRemoveSuperset != null) {
                      widget.onRemoveSuperset!();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'superset',
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.linkAsSuperset),
                        ],
                      ),
                    ),
                    if (widget.onRemoveSuperset != null)
                      PopupMenuItem(
                        value: 'removeSuperset',
                        child: Row(
                          children: [
                            const Icon(Icons.link_off, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.removeSuperset),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              color: Colors.red),
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

            // 세트 컬럼 헤더
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      l10n.setHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.weightKgHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.repsHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // RPE 헤더
                  SizedBox(
                    width: 44,
                    child: Text(
                      l10n.rpe,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 28,
                    child: Text(
                      l10n.completedHeader,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            // 세트 행들
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
                onRpeChanged: (rpe) => widget.onUpdateSetRpe(i, rpe),
                onSetTypeChanged: (type) =>
                    widget.onUpdateSetType(i, type),
              );
            }),

            // 액션 행
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
                  const SizedBox(width: 6),
                  // 워밍업 추가 버튼
                  OutlinedButton.icon(
                    onPressed: widget.onAddWarmup,
                    icon: const Icon(Icons.bolt, size: 16,
                        color: Colors.orange),
                    label: Text(
                      l10n.addWarmup,
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      side: const BorderSide(
                          color: Colors.orange, width: 0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<int>(
                    onSelected: widget.onStartRest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
                                color: Colors.blue, fontSize: 12),
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

    // 슈퍼셋 표시: 왼쪽 컬러 바
    if (supersetColor != null) {
      card = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: supersetColor,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4)),
            ),
          ),
          Expanded(child: card),
        ],
      );
    }

    return card;
  }
}

// ---------------------------------------------------------------------------
// 세트 행
// ---------------------------------------------------------------------------

class _SetRow extends StatelessWidget {
  final SetEntry set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleComplete;
  final VoidCallback onRemove;
  final ValueChanged<int?> onRpeChanged;
  final ValueChanged<SetType> onSetTypeChanged;

  const _SetRow({
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleComplete,
    required this.onRemove,
    required this.onRpeChanged,
    required this.onSetTypeChanged,
  });

  /// 세트 타입에 따른 색상/레이블
  (Color, Color, String) _setTypeBadge(BuildContext context) {
    return switch (set.setType) {
      SetType.warmup => (
          Colors.grey.withValues(alpha: 0.18),
          Colors.grey.shade600,
          'W',
        ),
      SetType.dropSet => (
          Colors.orange.withValues(alpha: 0.18),
          Colors.orange,
          'D',
        ),
      SetType.failure => (
          Colors.red.withValues(alpha: 0.18),
          Colors.red,
          'F',
        ),
      SetType.working => (
          Colors.blue.withValues(alpha: 0.1),
          Colors.blue,
          '${set.setNumber}',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = set.isCompleted;
    final (bgColor, textColor, badgeLabel) = _setTypeBadge(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isCompleted
          ? Colors.green.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // 세트 번호 / 타입 배지 (롱프레스로 타입 변경)
          SizedBox(
            width: 44,
            child: GestureDetector(
              onLongPress: () => _showSetTypeMenu(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: bgColor,
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 무게 입력
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
          const SizedBox(width: 6),
          // 반복수 입력
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
          const SizedBox(width: 6),
          // RPE 선택 (팝업 메뉴)
          SizedBox(
            width: 44,
            child: _RpeSelector(
              rpe: set.rpe,
              onChanged: onRpeChanged,
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 4),
          // 완료 체크박스
          SizedBox(
            width: 28,
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
          // 세트 삭제 버튼
          SizedBox(
            width: 28,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 16),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  /// 세트 타입 변경 팝업
  void _showSetTypeMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<SetType>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem(
          value: SetType.working,
          child: Text(l10n.setTypeWorking),
        ),
        PopupMenuItem(
          value: SetType.warmup,
          child: Text(l10n.setTypeWarmup),
        ),
        PopupMenuItem(
          value: SetType.dropSet,
          child: Text(l10n.setTypeDropSet),
        ),
        PopupMenuItem(
          value: SetType.failure,
          child: Text(l10n.setTypeFailure),
        ),
      ],
    ).then((type) {
      if (type != null) onSetTypeChanged(type);
    });
  }
}

// ---------------------------------------------------------------------------
// RPE 선택기
// ---------------------------------------------------------------------------

class _RpeSelector extends StatelessWidget {
  final int? rpe;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const _RpeSelector({
    required this.rpe,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasRpe = rpe != null;
    return PopupMenuButton<int?>(
      enabled: enabled,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: hasRpe
              ? Colors.purple.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasRpe
                ? Colors.purple.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          hasRpe ? '$rpe' : '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasRpe ? Colors.purple : Colors.grey,
          ),
        ),
      ),
      itemBuilder: (_) => [
        // RPE 없음 선택지
        const PopupMenuItem<int?>(
          value: null,
          child: Text('-'),
        ),
        // RPE 6~10
        ...List.generate(5, (i) => i + 6).map(
          (v) => PopupMenuItem<int?>(
            value: v,
            child: Text('RPE $v'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 숫자 입력
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
            const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
// 완료 화면
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
