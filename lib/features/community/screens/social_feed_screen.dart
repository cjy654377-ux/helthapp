// 소셜 활동 피드 화면 - 인스타그램 스타일 글로벌 피드
// ActivityFeedItem 카드, 좋아요 애니메이션, 댓글 섹션, 무한 스크롤

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/features/community/providers/community_providers.dart';
import 'package:health_app/core/widgets/common_states.dart';

// ---------------------------------------------------------------------------
// 헬퍼: 상대 시간 문자열 반환
// ---------------------------------------------------------------------------

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now'; // TODO: l10n
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago'; // TODO: l10n
  if (diff.inHours < 24) return '${diff.inHours}h ago'; // TODO: l10n
  if (diff.inDays < 7) return '${diff.inDays}d ago'; // TODO: l10n
  return '${(diff.inDays / 7).floor()}w ago'; // TODO: l10n
}

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

// ---------------------------------------------------------------------------
// SocialFeedScreen
// ---------------------------------------------------------------------------

class SocialFeedScreen extends ConsumerWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final currentUserId =
        ref.watch(communityProvider.select((s) => s.currentUserId)) ??
            'user_local';
    final currentUser = ref.watch(communityCurrentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Social Feed', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search', // TODO: l10n
            onPressed: () {},
          ),
        ],
      ),
      body: feedState.isLoading && feedState.items.isEmpty
          ? const LoadingStateWidget(message: 'Loading feed...') // TODO: l10n
          : feedState.errorMessage != null && feedState.items.isEmpty
              ? ErrorStateWidget(
                  message: feedState.errorMessage!,
                  onRetry: () =>
                      ref.read(feedProvider.notifier).loadFeed(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(feedProvider.notifier).loadFeed(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount:
                        feedState.items.length + (feedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 마지막 항목: 더 불러오기 트리거
                      if (index == feedState.items.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(feedProvider.notifier).loadMore();
                        });
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = feedState.items[index];
                      return _FeedItemCard(
                        item: item,
                        currentUserId: currentUserId,
                        currentUser: currentUser,
                        onLike: () => ref
                            .read(feedProvider.notifier)
                            .likeFeedItem(item.id, currentUserId),
                        onComment: (text) {
                          if (currentUser != null) {
                            ref
                                .read(feedProvider.notifier)
                                .commentOnFeedItem(item.id, text, currentUser);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeedItemCard - 피드 아이템 카드
// ---------------------------------------------------------------------------

class _FeedItemCard extends StatefulWidget {
  final ActivityFeedItem item;
  final String currentUserId;
  final UserProfile? currentUser;
  final VoidCallback onLike;
  final ValueChanged<String> onComment;

  const _FeedItemCard({
    required this.item,
    required this.currentUserId,
    required this.currentUser,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<_FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<_FeedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeController.forward().then((_) => _likeController.reverse());
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final isLiked = item.isLikedBy(widget.currentUserId);
    final authorColor = _colorFromHash(item.author.id);
    final initial = item.author.displayName.isNotEmpty
        ? item.author.displayName[0]
        : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더: 아바타 + 이름 + 타입 배지 + 시간 ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                // 아바타
                CircleAvatar(
                  radius: 22,
                  backgroundColor: authorColor.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: authorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.author.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          _FeedTypeBadge(type: item.type),
                          const SizedBox(width: 6),
                          Text(
                            _timeAgo(item.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ── 콘텐츠 텍스트 ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              item.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),

          // ── 운동 통계 칩 (workout/achievement 타입) ───────────────────────
          if (item.stats.isNotEmpty &&
              (item.type == FeedItemType.workout ||
                  item.type == FeedItemType.achievement))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _WorkoutStatsCard(stats: item.stats, type: item.type),
            ),

          // ── 액션 버튼: 좋아요, 댓글, 공유 ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                // 좋아요 버튼 (애니메이션)
                ScaleTransition(
                  scale: _likeScale,
                  child: InkWell(
                    onTap: _handleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 22,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${item.likeCount}',
                            style: TextStyle(
                              color: isLiked ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 댓글 버튼
                InkWell(
                  onTap: () => setState(() => _showComments = !_showComments),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _showComments
                              ? Icons.chat_bubble
                              : Icons.chat_bubble_outline,
                          size: 22,
                          color: _showComments
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${item.commentCount}',
                          style: TextStyle(
                            color: _showComments
                                ? theme.colorScheme.primary
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 공유 버튼
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 20, color: Colors.grey),
                  onPressed: () => _showShareOptions(context, item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

          // ── 댓글 섹션 (토글) ──────────────────────────────────────────────
          if (_showComments) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _CommentSection(
              comments: item.comments,
              onSubmit: (text) => widget.onComment(text),
              commentController: _commentController,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // 공유 옵션 바텀시트
  void _showShareOptions(BuildContext context, ActivityFeedItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareOptionsSheet(item: item),
    );
  }
}

// ---------------------------------------------------------------------------
// _FeedTypeBadge - 피드 타입 배지
// ---------------------------------------------------------------------------

class _FeedTypeBadge extends StatelessWidget {
  final FeedItemType type;

  const _FeedTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (type) {
      FeedItemType.workout => ('Workout', Colors.blue, Icons.fitness_center), // TODO: l10n
      FeedItemType.achievement => ('PR!', Colors.amber, Icons.emoji_events), // TODO: l10n
      FeedItemType.challenge => ('Challenge', Colors.green, Icons.flag), // TODO: l10n
      FeedItemType.photo => ('Photo', Colors.pink, Icons.photo), // TODO: l10n
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WorkoutStatsCard - 운동 통계 요약 카드
// ---------------------------------------------------------------------------

class _WorkoutStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final FeedItemType type;

  const _WorkoutStatsCard({required this.stats, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (type == FeedItemType.achievement) {
      // PR 달성 카드
      final exercise = stats['exercise'] as String? ?? '';
      final weight = stats['weight'] as double? ?? 0;
      final previous = stats['previous_pr'] as double? ?? 0;
      final improvement = stats['improvement'] as double? ?? 0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New PR: $exercise', // TODO: l10n
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${weight.toStringAsFixed(0)}kg  (+${improvement.toStringAsFixed(0)}kg from ${previous.toStringAsFixed(0)}kg)', // TODO: l10n
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 운동 통계 카드
    final duration = stats['duration'] as int? ?? 0;
    final volume = stats['volume'] as double? ?? 0;
    final sets = stats['sets'] as int? ?? 0;
    final exercises = stats['exercises'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 통계 행
          Row(
            children: [
              _StatChip(
                icon: Icons.timer_outlined,
                label: '${duration}min', // TODO: l10n
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.fitness_center,
                label: '${(volume / 1000).toStringAsFixed(1)}t', // 총 볼륨 (톤 단위)
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.repeat,
                label: '${sets}sets', // TODO: l10n
              ),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            // 운동 이름 태그 목록
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: exercises.take(4).map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CommentSection - 댓글 섹션
// ---------------------------------------------------------------------------

class _CommentSection extends StatelessWidget {
  final List<PostComment> comments;
  final ValueChanged<String> onSubmit;
  final TextEditingController commentController;

  const _CommentSection({
    required this.comments,
    required this.onSubmit,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기존 댓글 목록
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No comments yet. Be the first!', // TODO: l10n
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...comments.map((c) => _CommentTile(comment: c)),

          const SizedBox(height: 8),

          // 댓글 입력창
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...', // TODO: l10n
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (text) {
                    onSubmit(text);
                    commentController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  onSubmit(commentController.text);
                  commentController.clear();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final authorColor = _colorFromHash(comment.author.id);
    final initial = comment.author.displayName.isNotEmpty
        ? comment.author.displayName[0]
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: authorColor.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: TextStyle(
                color: authorColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${comment.author.displayName}  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: comment.content,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(comment.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShareOptionsSheet - 공유 옵션 바텀시트
// ---------------------------------------------------------------------------

class _ShareOptionsSheet extends StatelessWidget {
  final ActivityFeedItem item;

  const _ShareOptionsSheet({required this.item});

  String _buildTextSummary() {
    final buf = StringBuffer();
    buf.writeln('${item.author.displayName}\'s workout:');
    buf.writeln(item.content);
    if (item.stats['duration'] != null) {
      buf.writeln('Duration: ${item.stats['duration']}min');
    }
    if (item.stats['volume'] != null) {
      buf.writeln(
          'Volume: ${(item.stats['volume'] as double).toStringAsFixed(0)}kg');
    }
    buf.writeln('\nShared via HealthApp');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Workout', // TODO: l10n
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 텍스트로 공유
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Share as Text'), // TODO: l10n
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                // share_plus 미포함 → 클립보드 복사 + SnackBar 안내
                _copyToClipboard(context, _buildTextSummary());
              },
            ),
            // 링크 공유
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'), // TODO: l10n
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(
                  context,
                  'https://healthapp.example.com/feed/${item.id}',
                );
              },
            ),
            // 클립보드 복사
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy to Clipboard'), // TODO: l10n
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context, _buildTextSummary());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Flutter 기본 클립보드 서비스 사용
    // share_plus 패키지가 추가되면 Share.share(text) 로 교체 가능
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'), // TODO: l10n
        duration: Duration(seconds: 2),
      ),
    );
  }
}
