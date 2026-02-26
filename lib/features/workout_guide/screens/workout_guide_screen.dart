import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/features/workout_guide/providers/exercise_database_provider.dart';
import 'package:health_app/features/workout_guide/providers/programs_provider.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Body part group definition
// ---------------------------------------------------------------------------

class _BodyPartGroup {
  final String name;
  final IconData icon;
  final Color color;
  final List<BodyPart> bodyParts;

  const _BodyPartGroup({
    required this.name,
    required this.icon,
    required this.color,
    required this.bodyParts,
  });
}

const List<_BodyPartGroup> _bodyPartGroups = [
  _BodyPartGroup(
    name: '가슴',
    icon: Icons.accessibility_new,
    color: Colors.red,
    bodyParts: [BodyPart.chest],
  ),
  _BodyPartGroup(
    name: '등',
    icon: Icons.back_hand,
    color: Colors.blue,
    bodyParts: [BodyPart.back],
  ),
  _BodyPartGroup(
    name: '어깨',
    icon: Icons.sports_handball,
    color: Colors.purple,
    bodyParts: [BodyPart.shoulders],
  ),
  _BodyPartGroup(
    name: '팔',
    icon: Icons.sports_mma,
    color: Colors.orange,
    bodyParts: [BodyPart.biceps, BodyPart.triceps],
  ),
  _BodyPartGroup(
    name: '하체',
    icon: Icons.directions_run,
    color: Colors.green,
    bodyParts: [
      BodyPart.quadriceps,
      BodyPart.hamstrings,
      BodyPart.calves,
      BodyPart.glutes,
    ],
  ),
  _BodyPartGroup(
    name: '코어',
    icon: Icons.sports_gymnastics,
    color: Colors.teal,
    bodyParts: [BodyPart.abs],
  ),
];

// ---------------------------------------------------------------------------
// Localized body part name helper
// ---------------------------------------------------------------------------

String _localizedBodyPartName(BuildContext context, int index) {
  final l10n = AppLocalizations.of(context);
  const keys = ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'];
  switch (keys[index]) {
    case 'chest':
      return l10n.chest;
    case 'back':
      return l10n.back;
    case 'shoulders':
      return l10n.shoulders;
    case 'arms':
      return l10n.arms;
    case 'legs':
      return l10n.legs;
    case 'core':
      return l10n.core;
    default:
      return '';
  }
}

// ---------------------------------------------------------------------------
// Difficulty color helper
// ---------------------------------------------------------------------------

Color _difficultyColor(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.beginner:
      return Colors.green;
    case DifficultyLevel.intermediate:
      return Colors.orange;
    case DifficultyLevel.advanced:
      return Colors.red;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _selectedBodyPartProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// WorkoutGuideScreen
// ---------------------------------------------------------------------------

class WorkoutGuideScreen extends ConsumerWidget {
  const WorkoutGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = ref.watch(_selectedBodyPartProvider);
    final selectedGroup = _bodyPartGroups[selectedIndex];

    // 활성 프로그램 상태 감시
    final activeProgram = ref.watch(activeProgramProvider);
    final activeProgramDetail = ref.watch(activeProgramDetailProvider);
    final currentDay = ref.watch(currentProgramDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.workoutGuide,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Programs + Video Workouts 버튼 (상단 액션 바)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                // Programs 버튼
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.programs),
                    icon: const Icon(Icons.view_list, size: 18),
                    label: const Text(
                      'Programs', // TODO: l10n
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Video Workouts 버튼
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.videoWorkouts),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text(
                      '영상 운동', // TODO: l10n
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 활성 프로그램 배너 (있을 경우 표시)
          if (activeProgram != null && activeProgramDetail != null)
            _ActiveProgramBanner(
              active: activeProgram,
              program: activeProgramDetail,
              currentDay: currentDay,
              onTap: () => context.push(AppRoutes.programs),
            ),

          _BodyPartSelector(
            selectedIndex: selectedIndex,
            onSelect: (i) =>
                ref.read(_selectedBodyPartProvider.notifier).state = i,
          ),
          const Divider(height: 1),
          Expanded(
            child: _ExerciseList(
              group: selectedGroup,
              groupIndex: selectedIndex,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body Part Selector (icon grid row)
// ---------------------------------------------------------------------------

class _BodyPartSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _BodyPartSelector({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_bodyPartGroups.length, (i) {
          final group = _bodyPartGroups[i];
          final isSelected = i == selectedIndex;
          final localizedName = _localizedBodyPartName(context, i);
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? group.color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? group.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    group.icon,
                    color: isSelected ? group.color : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? group.color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise List
// ---------------------------------------------------------------------------

class _ExerciseList extends ConsumerWidget {
  final _BodyPartGroup group;
  final int groupIndex;

  const _ExerciseList({required this.group, required this.groupIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localizedName = _localizedBodyPartName(context, groupIndex);
    final exercises = group.bodyParts
        .expand((bp) => ref.watch(exercisesByBodyPartProvider(bp)))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(group.icon, color: group.color, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.bodyPartExercises(localizedName),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: group.color,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: group.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.exerciseCount(exercises.length),
                style: TextStyle(
                  fontSize: 12,
                  color: group.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...exercises.map(
          (e) => _ExerciseCard(exercise: e, accentColor: group.color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Card (expandable)
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final Color accentColor;

  const _ExerciseCard({required this.exercise, required this.accentColor});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  String _buildTargetMuscle(Exercise ex) {
    final parts = [
      ex.bodyPart.label,
      ...ex.secondaryBodyParts.map((bp) => bp.label),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final color = widget.accentColor;
    final diffColor = _difficultyColor(ex.difficulty);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _buildTargetMuscle(ex),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex.difficulty.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: diffColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.sports_handball,
                  label: l10n.equipment,
                  value: ex.equipment.label,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: l10n.description,
                  value: ex.instructions.join('\n'),
                ),
                if (ex.tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.lightbulb_outline,
                    label: l10n.tips,
                    value: ex.tips.join('\n'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active Program Banner (workout guide 상단 표시용)
// ---------------------------------------------------------------------------

class _ActiveProgramBanner extends StatelessWidget {
  final ActiveProgram active;
  final WorkoutProgram program;
  final ProgramDay? currentDay;
  final VoidCallback onTap;

  const _ActiveProgramBanner({
    required this.active,
    required this.program,
    required this.currentDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayText = currentDay != null && !currentDay!.restDay
        ? 'Week ${active.currentWeek} Day ${active.currentDay}: ${currentDay!.name}' // TODO: l10n
        : 'Week ${active.currentWeek} - Rest Day'; // TODO: l10n

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    dayText,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
