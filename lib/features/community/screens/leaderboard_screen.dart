// 리더보드 화면 - 주간 볼륨, 월간 운동 횟수, 연속 운동, PR 수 기준 순위
// Tab bar + 순위 리스트 (1-3위 금/은/동 하이라이트, 현재 사용자 강조)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/features/community/providers/community_providers.dart';

// ---------------------------------------------------------------------------
// 리더보드 탭 설정
// ---------------------------------------------------------------------------

const _leaderboardTabs = [
  (LeaderboardType.weeklyVolume, 'Weekly Volume', Icons.bar_chart), // TODO: l10n
  (LeaderboardType.monthlyWorkouts, 'Monthly Workouts', Icons.calendar_month), // TODO: l10n
  (LeaderboardType.streak, 'Streak', Icons.local_fire_department), // TODO: l10n
  (LeaderboardType.totalPRs, 'Total PRs', Icons.emoji_events), // TODO: l10n
];

// ---------------------------------------------------------------------------
// LeaderboardScreen
// ---------------------------------------------------------------------------

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _leaderboardTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _leaderboardTabs.map((tab) {
            final (_, label, icon) = tab;
            return Tab(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            );
          }).toList(),
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2.5,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _leaderboardTabs.map((tab) {
          return _LeaderboardTabView(type: tab.$1);
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LeaderboardTabView - 탭별 리더보드 뷰
// ---------------------------------------------------------------------------

class _LeaderboardTabView extends ConsumerWidget {
  final LeaderboardType type;

  const _LeaderboardTabView({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(leaderboardProvider(type));
    final currentUserId =
        ref.watch(communityProvider.select((s) => s.currentUserId)) ??
            'user_local';

    // 현재 사용자 항목 찾기 (하단 고정용)
    LeaderboardEntry? currentUserEntry;
    try {
      currentUserEntry =
          entries.firstWhere((e) => e.userId == currentUserId);
    } catch (_) {}

    // 현재 사용자가 상위 10위 내에 있는지 여부
    final currentUserInTop = currentUserEntry != null && currentUserEntry.rank <= 10;

    return Column(
      children: [
        // ── 상위 3위 포디움 ─────────────────────────────────────────────────
        if (entries.length >= 3)
          _PodiumSection(entries: entries.take(3).toList(), type: type),

        const Divider(height: 1),

        // ── 순위 목록 ──────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: currentUserInTop ? 16 : 80,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _LeaderboardTile(
                entry: entry,
                type: type,
                isCurrentUser: entry.userId == currentUserId,
              );
            },
          ),
        ),

        // ── 현재 사용자가 10위 밖이면 하단 고정 표시 ────────────────────────
        if (!currentUserInTop && currentUserEntry != null)
          _CurrentUserFixedBar(entry: currentUserEntry, type: type),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PodiumSection - 1~3위 포디움
// ---------------------------------------------------------------------------

class _PodiumSection extends StatelessWidget {
  final List<LeaderboardEntry> entries; // 반드시 3개
  final LeaderboardType type;

  const _PodiumSection({required this.entries, required this.type});

  @override
  Widget build(BuildContext context) {
    // 포디움 순서: 2위(좌) - 1위(중) - 3위(우)
    final order = [entries[1], entries[0], entries[2]];
    final heights = [80.0, 100.0, 60.0];
    final colors = [Colors.grey.shade400, Colors.amber, Colors.brown.shade300];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final entry = order[i];
          final rankIndex = i == 0 ? 1 : (i == 1 ? 0 : 2); // 실제 순위 인덱스
          final medal = ['', '1st', '2nd', '3rd'][entry.rank];

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아바타
                _RankAvatar(
                  entry: entry,
                  size: rankIndex == 0 ? 52 : 44,
                  medalColor: colors[i],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatScore(entry.score, type),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // 포디움 블록
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    border: Border(
                      top: BorderSide(color: colors[i], width: 2),
                      left: BorderSide(
                          color: colors[i].withValues(alpha: 0.4), width: 1),
                      right: BorderSide(
                          color: colors[i].withValues(alpha: 0.4), width: 1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    medal,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors[i],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LeaderboardTile - 개별 순위 행
// ---------------------------------------------------------------------------

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardType type;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.entry,
    required this.type,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1~3위 메달 색상
    final rankColor = switch (entry.rank) {
      1 => Colors.amber,
      2 => Colors.grey.shade400,
      3 => Colors.brown.shade300,
      _ => Colors.transparent,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              )
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 순위 번호
            SizedBox(
              width: 28,
              child: entry.rank <= 3
                  ? Icon(Icons.circle, color: rankColor, size: 10)
                  : Text(
                      '${entry.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),
            // 아바타
            _RankAvatar(entry: entry, size: 40, medalColor: rankColor),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                entry.userName,
                style: TextStyle(
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'You', // TODO: l10n
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatScore(entry.score, type),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isCurrentUser
                    ? theme.colorScheme.primary
                    : Colors.grey.shade700,
              ),
            ),
            Text(
              _scoreUnit(type),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CurrentUserFixedBar - 현재 사용자 하단 고정 바 (10위 밖일 때)
// ---------------------------------------------------------------------------

class _CurrentUserFixedBar extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardType type;

  const _CurrentUserFixedBar({
    required this.entry,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 순위 번호
            SizedBox(
              width: 28,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RankAvatar(entry: entry, size: 36, medalColor: Colors.transparent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Your rank', // TODO: l10n
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatScore(entry.score, type),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _scoreUnit(type),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
// _RankAvatar - 순위 아바타 (이니셜 기반)
// ---------------------------------------------------------------------------

class _RankAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;
  final Color medalColor;

  const _RankAvatar({
    required this.entry,
    required this.size,
    required this.medalColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHash(entry.userId);
    final initial =
        entry.userName.isNotEmpty ? entry.userName[0] : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            initial,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.36,
            ),
          ),
        ),
        // 1~3위 메달 오버레이
        if (entry.rank <= 3)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 헬퍼 함수
// ---------------------------------------------------------------------------

/// 문자열 해시로 결정적 색상 반환
Color _colorFromHash(String value) {
  const colors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
  ];
  return colors[value.hashCode.abs() % colors.length];
}

/// 점수를 리더보드 타입에 맞는 포맷으로 변환
String _formatScore(double score, LeaderboardType type) {
  switch (type) {
    case LeaderboardType.weeklyVolume:
      return '${(score / 1000).toStringAsFixed(1)}t'; // 톤 단위
    case LeaderboardType.monthlyWorkouts:
      return score.toInt().toString();
    case LeaderboardType.streak:
      return score.toInt().toString();
    case LeaderboardType.totalPRs:
      return score.toInt().toString();
  }
}

/// 점수 단위 레이블 반환
String _scoreUnit(LeaderboardType type) {
  switch (type) {
    case LeaderboardType.weeklyVolume:
      return 'volume'; // TODO: l10n
    case LeaderboardType.monthlyWorkouts:
      return 'workouts'; // TODO: l10n
    case LeaderboardType.streak:
      return 'day streak'; // TODO: l10n
    case LeaderboardType.totalPRs:
      return 'personal records'; // TODO: l10n
  }
}
