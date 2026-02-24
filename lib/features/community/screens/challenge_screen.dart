// 챌린지 화면 - 게이미피케이션 시스템 UI
// 탭바: 참여중 / 완료 / 찾기

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:health_app/features/community/providers/challenge_providers.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// ChallengeScreen (루트 화면)
// ---------------------------------------------------------------------------

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 앱 첫 실행 시 샘플 데이터 주입
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengeProvider.notifier).injectSampleChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.challenge),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.participating),
            Tab(text: l10n.completed),
            Tab(text: l10n.discover),
          ],
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor:
              colorScheme.onPrimary.withValues(alpha: 0.6),
          indicatorColor: colorScheme.onPrimary,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActiveChallengesTab(),
          _CompletedChallengesTab(),
          _DiscoverChallengesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChallengeSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.createChallenge),
      ),
    );
  }

  void _showCreateChallengeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CreateChallengeSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// 탭 1: 참여중 챌린지
// ---------------------------------------------------------------------------

class _ActiveChallengesTab extends ConsumerWidget {
  const _ActiveChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final challenges = ref.watch(activeChallengesProvider);
    final isLoading = ref.watch(challengeLoadingProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (challenges.isEmpty) {
      return _EmptyState(
        icon: Icons.emoji_events_outlined,
        title: l10n.noChallengesYet,
        subtitle: l10n.findChallengeToJoin,
        actionLabel: l10n.discover,
        onAction: () {},
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        return _ActiveChallengeCard(challenge: challenges[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 탭 2: 완료된 챌린지
// ---------------------------------------------------------------------------

class _CompletedChallengesTab extends ConsumerWidget {
  const _CompletedChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final challenges = ref.watch(completedChallengesProvider);

    if (challenges.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline,
        title: l10n.noCompletedChallenges,
        subtitle: l10n.completeChallengesForBadges,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        return _CompletedChallengeCard(challenge: challenges[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 탭 3: 챌린지 찾기
// ---------------------------------------------------------------------------

class _DiscoverChallengesTab extends ConsumerWidget {
  const _DiscoverChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(availableChallengesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // 섹션: 개인 챌린지
        _SectionHeader(
          title: l10n.personalChallenge,
          subtitle: l10n.soloChallenge,
          icon: Icons.person_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        ...available
            .where((c) => c.scope == ChallengeScope.personal)
            .map((c) => _AvailableChallengeCard(challenge: c)),

        const SizedBox(height: 20),

        // 섹션: 팀 챌린지
        _SectionHeader(
          title: l10n.teamChallenge,
          subtitle: l10n.teamChallengeSubtitle,
          icon: Icons.group_outlined,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        ...available
            .where((c) => c.scope == ChallengeScope.team)
            .map((c) => _AvailableChallengeCard(challenge: c)),

        if (available.isEmpty)
          _EmptyState(
            icon: Icons.check_circle,
            title: l10n.allChallengesJoined,
            subtitle: l10n.createCustomChallenge,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 활성 챌린지 카드
// ---------------------------------------------------------------------------

class _ActiveChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const userId = 'user_local';
    final progress = challenge.progressRatioFor(userId);
    final progressValue = challenge.progressValueFor(userId);
    final colorScheme = Theme.of(context).colorScheme;
    final typeInfo = _challengeTypeInfo(challenge.type, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: typeInfo.color.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 행: 아이콘 + 이름 + 배지
            Row(
              children: [
                // 타입 아이콘 배지
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeInfo.icon,
                    color: typeInfo.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _ChipBadge(
                            label: challenge.type.label,
                            color: typeInfo.color,
                          ),
                          const SizedBox(width: 6),
                          _ChipBadge(
                            label: challenge.scope.label,
                            color: challenge.scope == ChallengeScope.team
                                ? colorScheme.secondary
                                : colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 더보기 메뉴
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _confirmLeave(context, ref);
                    } else if (value == 'add_progress') {
                      _showAddProgressDialog(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'add_progress',
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.addProgress),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          const Icon(Icons.exit_to_app,
                              size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.leaveChallenge,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 진행률 바
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 10,
              percent: progress,
              backgroundColor: typeInfo.color.withValues(alpha: 0.12),
              progressColor: typeInfo.color,
              barRadius: const Radius.circular(8),
              animation: true,
              animationDuration: 800,
            ),

            const SizedBox(height: 10),

            // 진행률 수치 + 남은 일수
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progressValue.toStringAsFixed(progressValue.truncateToDouble() == progressValue ? 0 : 1)}'
                  ' / ${challenge.targetValue.toStringAsFixed(challenge.targetValue.truncateToDouble() == challenge.targetValue ? 0 : 1)}'
                  ' ${_unitLabel(l10n, challenge.type)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: typeInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      challenge.remainingDays == 0
                          ? l10n.dueToday
                          : l10n.daysLeft(challenge.remainingDays),
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: challenge.remainingDays <= 1
                                    ? Colors.red
                                    : colorScheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 참가자 수 + 보상
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.participants(challenge.participantIds.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (challenge.reward != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.card_giftcard,
                    size: 14,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      challenge.reward!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.tertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveChallenge),
        content: Text(l10n.leaveConfirmMessage(challenge.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(challengeProvider.notifier)
                  .leaveChallenge(challenge.id);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddProgressDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addProgress),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.addValueLabel,
            suffixText: _unitLabel(l10n, challenge.type),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(challengeProvider.notifier).addProgress(
                      challengeId: challenge.id,
                      delta: value,
                    );
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 완료 챌린지 카드
// ---------------------------------------------------------------------------

class _CompletedChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _CompletedChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const userId = 'user_local';
    final progressRatio = challenge.progressRatioFor(userId);
    final isGoalMet = progressRatio >= 1.0;
    final colorScheme = Theme.of(context).colorScheme;
    final typeInfo = _challengeTypeInfo(challenge.type, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 타입 아이콘 (흐리게)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGoalMet
                    ? typeInfo.color.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGoalMet ? Icons.emoji_events : typeInfo.icon,
                color: isGoalMet ? typeInfo.color : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isGoalMet
                                    ? null
                                    : colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isGoalMet
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isGoalMet ? l10n.achieved : l10n.periodEnded,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isGoalMet ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 6,
                    percent: progressRatio > 1.0 ? 1.0 : progressRatio,
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    progressColor:
                        isGoalMet ? Colors.green : Colors.grey.shade400,
                    barRadius: const Radius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progressRatio * 100).toInt()}${l10n.percentAchievedEnd(_formatDate(challenge.endDate))}',
                    style: Theme.of(context).textTheme.bodySmall,
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

// ---------------------------------------------------------------------------
// 참여 가능한 챌린지 카드
// ---------------------------------------------------------------------------

class _AvailableChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _AvailableChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final typeInfo = _challengeTypeInfo(challenge.type, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 타입 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeInfo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    challenge.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        l10n.daysCount(challenge.totalDays),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.flag_outlined,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        l10n.goalWithValue(
                          challenge.targetValue.toStringAsFixed(challenge.targetValue.truncateToDouble() == challenge.targetValue ? 0 : 1),
                          _unitLabel(l10n, challenge.type),
                        ),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 참가 버튼
            FilledButton(
              onPressed: () {
                ref
                    .read(challengeProvider.notifier)
                    .joinPresetChallenge(challenge.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.challengeJoinedMessage(challenge.title)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: typeInfo.color,
              ),
              child: Text(
                l10n.joinChallenge,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 챌린지 만들기 BottomSheet
// ---------------------------------------------------------------------------

class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet();

  @override
  ConsumerState<_CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState
    extends ConsumerState<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();

  ChallengeType _selectedType = ChallengeType.workout;
  ChallengeScope _selectedScope = ChallengeScope.personal;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.createChallenge,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 폼
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      // 챌린지 이름
                      _FormLabel(l10n.challengeName),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: l10n.challengeNameHint,
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.enterNameValidation : null,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // 설명
                      _FormLabel(l10n.challengeDescription),
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          hintText: l10n.challengeDescHint,
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // 챌린지 유형 선택
                      _FormLabel(l10n.challengeType),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ChallengeType.values.map((type) {
                          final isSelected = _selectedType == type;
                          final typeInfo = _challengeTypeInfo(
                              type, colorScheme);
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  typeInfo.icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : typeInfo.color,
                                ),
                                const SizedBox(width: 4),
                                Text(type.label),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedType = type),
                            selectedColor: typeInfo.color,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // 목표값
                      _FormLabel('${l10n.targetValue} (${_unitLabel(l10n, _selectedType)})'),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: _targetHint(_selectedType),
                          prefixIcon: const Icon(Icons.flag_outlined),
                          suffixText: _unitLabel(l10n, _selectedType),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.enterTargetValidation;
                          }
                          final d = double.tryParse(v.trim());
                          if (d == null || d <= 0) {
                            return l10n.enterValidNumber;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 기간 선택
                      _FormLabel(l10n.duration),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: l10n.startDateLabel,
                              date: _startDate,
                              onDateSelected: (d) =>
                                  setState(() => _startDate = d),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '~',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Expanded(
                            child: _DatePickerField(
                              label: l10n.endDateLabel,
                              date: _endDate,
                              onDateSelected: (d) =>
                                  setState(() => _endDate = d),
                              firstDate: _startDate
                                  .add(const Duration(days: 1)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 범위 선택 (개인 / 팀)
                      _FormLabel(l10n.scope),
                      Row(
                        children: ChallengeScope.values.map((scope) {
                          final isSelected = _selectedScope == scope;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: _ScopeSelectCard(
                                scope: scope,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selectedScope = scope),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // 생성 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.rocket_launch_outlined),
                          label: Text(l10n.startChallenge),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);

    if (_endDate.isBefore(_startDate) ||
        _endDate.isAtSameMomentAs(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.endDateMustBeAfterStart),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetValue = double.parse(_targetController.text.trim());

    ref.read(challengeProvider.notifier).createChallenge(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? '${_titleController.text.trim()} ${l10n.challenge}'
              : _descController.text.trim(),
          type: _selectedType,
          targetValue: targetValue,
          startDate: _startDate,
          endDate: _endDate,
          scope: _selectedScope,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            l10n.challengeCreatedMessage(_titleController.text.trim())),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 날짜 선택 필드
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onDateSelected,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onDateSelected(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(
          _formatDate(date),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 범위 선택 카드
// ---------------------------------------------------------------------------

class _ScopeSelectCard extends StatelessWidget {
  final ChallengeScope scope;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeSelectCard({
    required this.scope,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              scope == ChallengeScope.personal
                  ? Icons.person_outline
                  : Icons.group_outlined,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              scope.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 공통 유틸 위젯
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 헬퍼 함수들
// ---------------------------------------------------------------------------

/// 챌린지 타입별 아이콘 및 색상 정보
({IconData icon, Color color}) _challengeTypeInfo(
    ChallengeType type, ColorScheme scheme) {
  return switch (type) {
    ChallengeType.workout => (
        icon: Icons.fitness_center,
        color: scheme.primary,
      ),
    ChallengeType.volume => (
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFFE53935),
      ),
    ChallengeType.steps => (
        icon: Icons.directions_walk,
        color: const Color(0xFF43A047),
      ),
    ChallengeType.water => (
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF039BE5),
      ),
    ChallengeType.diet => (
        icon: Icons.restaurant_menu,
        color: const Color(0xFFFF8F00),
      ),
    ChallengeType.custom => (
        icon: Icons.star_outline,
        color: const Color(0xFF8E24AA),
      ),
  };
}

/// 챌린지 타입별 단위 레이블
String _unitLabel(AppLocalizations l10n, ChallengeType type) {
  return switch (type) {
    ChallengeType.workout => l10n.days,
    ChallengeType.volume => l10n.kg,
    ChallengeType.steps => l10n.steps,
    ChallengeType.water => l10n.days,
    ChallengeType.diet => l10n.days,
    ChallengeType.custom => l10n.times,
  };
}

/// 챌린지 타입별 목표값 힌트
String _targetHint(ChallengeType type) {
  return switch (type) {
    ChallengeType.workout => '예: 7 (7일 연속)',
    ChallengeType.volume => '예: 50000 (50,000kg)',
    ChallengeType.steps => '예: 10000 (10,000걸음/일)',
    ChallengeType.water => '예: 14 (14일 연속)',
    ChallengeType.diet => '예: 30 (30일 연속)',
    ChallengeType.custom => '예: 10',
  };
}

/// 날짜 포맷 (M월 D일)
String _formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일';
}
