// 사전 제작 운동 프로그램 라이브러리 화면
// 프로그램 그리드, 상세 보기, 시작/포기 기능 포함

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_guide/providers/programs_provider.dart';
import 'package:health_app/features/workout_guide/providers/exercise_database_provider.dart';

// ---------------------------------------------------------------------------
// 헬퍼 함수
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

String _difficultyLabel(DifficultyLevel level) {
  switch (level) {
    case DifficultyLevel.beginner:
      return '초급'; // TODO: l10n
    case DifficultyLevel.intermediate:
      return '중급'; // TODO: l10n
    case DifficultyLevel.advanced:
      return '고급'; // TODO: l10n
  }
}

IconData _splitIcon(String splitType) {
  switch (splitType.toLowerCase()) {
    case 'ppl':
      return Icons.sync;
    case 'upper/lower':
      return Icons.swap_vert;
    case 'full body':
      return Icons.accessibility_new;
    case 'bro split':
      return Icons.sports_gymnastics;
    default:
      return Icons.fitness_center;
  }
}

// ---------------------------------------------------------------------------
// ProgramsScreen
// ---------------------------------------------------------------------------

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final active = ref.watch(activeProgramProvider);
    final activeProgram = ref.watch(activeProgramDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Programs', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // 활성 프로그램 배너
          if (active != null && activeProgram != null)
            SliverToBoxAdapter(
              child: _ActiveProgramBanner(
                active: active,
                program: activeProgram,
              ),
            ),

          // 프로그램 라이브러리 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                active != null
                    ? 'All Programs' // TODO: l10n
                    : 'Choose a Program', // TODO: l10n
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 프로그램 그리드
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final program = programs[index];
                  final isActive = active?.programId == program.id;
                  return _ProgramCard(
                    program: program,
                    isActive: isActive,
                    onTap: () => _showProgramDetail(context, ref, program),
                  );
                },
                childCount: programs.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showProgramDetail(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProgramDetailSheet(program: program),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Program Banner
// ---------------------------------------------------------------------------

class _ActiveProgramBanner extends ConsumerWidget {
  final ActiveProgram active;
  final WorkoutProgram program;

  const _ActiveProgramBanner({
    required this.active,
    required this.program,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDay = ref.watch(currentProgramDayProvider);
    final progress = active.progressPercent(program);
    final color = _difficultyColor(program.difficulty);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Program', // TODO: l10n
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Abandon Program?'), // TODO: l10n
                      content: const Text(
                        'Your progress will be lost.', // TODO: l10n
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'), // TODO: l10n
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Abandon',
                            style: TextStyle(color: Colors.red),
                          ), // TODO: l10n
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(activeProgramProvider.notifier)
                        .abandonProgram();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Quit', style: TextStyle(fontSize: 12)), // TODO: l10n
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            program.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentDay != null && !currentDay.restDay
                ? 'Week ${active.currentWeek} · Day ${active.currentDay}: ${currentDay.name}' // TODO: l10n
                : 'Week ${active.currentWeek} · Rest Day', // TODO: l10n
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% complete · '
                '${active.completedDayKeys.length} days done', // TODO: l10n
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Program Card (Grid Item)
// ---------------------------------------------------------------------------

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final bool isActive;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(program.difficulty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 + 활성 뱃지
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _splitIcon(program.splitType),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Active', // TODO: l10n
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 프로그램 이름
              Text(
                program.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 난이도 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _difficultyLabel(program.difficulty),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              // 기간 / 요일 수
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${program.durationWeeks}주', // TODO: l10n
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.fitness_center, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '주 ${program.daysPerWeek}일', // TODO: l10n
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Program Detail Bottom Sheet
// ---------------------------------------------------------------------------

class _ProgramDetailSheet extends ConsumerStatefulWidget {
  final WorkoutProgram program;

  const _ProgramDetailSheet({required this.program});

  @override
  ConsumerState<_ProgramDetailSheet> createState() =>
      _ProgramDetailSheetState();
}

class _ProgramDetailSheetState extends ConsumerState<_ProgramDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 처음 4주만 탭으로 표시 (탭이 너무 많아지는 것 방지)
    final tabCount = widget.program.durationWeeks.clamp(1, 4);
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final active = ref.watch(activeProgramProvider);
    final isActive = active?.programId == program.id;
    final color = _difficultyColor(program.difficulty);
    final tabCount = program.durationWeeks.clamp(1, 4);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 프로그램 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _splitIcon(program.splitType),
                            color: color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                program.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                program.splitType,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 메타 정보 행
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.calendar_today,
                          label: '${program.durationWeeks}주', // TODO: l10n
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.fitness_center,
                          label: '주 ${program.daysPerWeek}일', // TODO: l10n
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.signal_cellular_alt,
                          label: _difficultyLabel(program.difficulty),
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 설명
                    Text(
                      program.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                    // 태그
                    if (program.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: program.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // 주차 탭
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: color,
                unselectedLabelColor: Colors.grey,
                indicatorColor: color,
                tabs: List.generate(
                  tabCount,
                  (i) => Tab(text: 'Week ${i + 1}'), // TODO: l10n
                ),
              ),

              // 주차별 운동 스케줄
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(tabCount, (weekIdx) {
                    final week = program.weeks[weekIdx];
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: week.days.length,
                      itemBuilder: (context, dayIdx) {
                        final day = week.days[dayIdx];
                        return _DayScheduleCard(
                          day: day,
                          color: color,
                        );
                      },
                    );
                  }),
                ),
              ),

              // 시작/포기 버튼
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: isActive
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Abandon Program?'), // TODO: l10n
                                  content: const Text(
                                    'Your progress will be lost.', // TODO: l10n
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'), // TODO: l10n
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Abandon',
                                        style: TextStyle(color: Colors.red),
                                      ), // TODO: l10n
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await ref
                                    .read(activeProgramProvider.notifier)
                                    .abandonProgram();
                              }
                            },
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Abandon Program'), // TODO: l10n
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () async {
                              // 이미 다른 프로그램 진행 중인 경우 확인
                              if (active != null) {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Switch Program?'), // TODO: l10n
                                    content: const Text(
                                      'Current program progress will be lost.', // TODO: l10n
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'), // TODO: l10n
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Switch'), // TODO: l10n
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                              }
                              await ref
                                  .read(activeProgramProvider.notifier)
                                  .startProgram(program.id);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Program'), // TODO: l10n
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Day Schedule Card
// ---------------------------------------------------------------------------

class _DayScheduleCard extends ConsumerWidget {
  final ProgramDay day;
  final Color color;

  const _DayScheduleCard({required this.day, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.read(exerciseDatabaseProvider);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: day.restDay
                  ? Colors.grey.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              day.restDay ? Icons.hotel : Icons.fitness_center,
              size: 18,
              color: day.restDay ? Colors.grey : color,
            ),
          ),
          title: Text(
            'Day ${day.dayNumber}: ${day.name}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: day.restDay ? Colors.grey : null,
            ),
          ),
          subtitle: day.restDay
              ? const Text(
                  'Rest & Recovery', // TODO: l10n
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              : Text(
                  '${day.exercises.length} exercises', // TODO: l10n
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
          children: day.restDay
              ? [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Focus on recovery and rest.', // TODO: l10n
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ]
              : day.exercises.map((ex) {
                  // 운동 이름 조회
                  final exercise = dbState.allExercises
                      .where((e) => e.id == ex.exerciseId)
                      .firstOrNull;
                  final name = exercise?.name ?? ex.exerciseId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ex.sets}세트 × ${ex.reps}', // TODO: l10n
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 작은 메타 정보 칩
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
