import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/features/community/providers/community_providers.dart';
import 'package:health_app/core/widgets/common_states.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Local UI-only provider
// ---------------------------------------------------------------------------

final selectedTeamProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a deterministic color from an index for team avatars.
Color _teamColor(int index) {
  const colors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];
  return colors[index % colors.length];
}

/// Returns a deterministic color derived from a string's hashCode.
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
  final hash = value.hashCode.abs();
  return colors[hash % colors.length];
}

/// Formats a [DateTime] as a human-readable relative time string.
String _timeAgo(DateTime createdAt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inSeconds < 60) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  return '${(diff.inDays / 7).floor()}주 전';
}

// ---------------------------------------------------------------------------
// CommunityScreen
// ---------------------------------------------------------------------------

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider);
    final selectedTeamId = ref.watch(selectedTeamProvider);
    final isLoading = ref.watch(communityLoadingProvider);
    final currentUserId =
        ref.watch(communityProvider.select((s) => s.currentUserId));

    // Collect posts: all teams combined, or filtered to selected team.
    final List<TeamPost> posts;
    if (selectedTeamId != null) {
      posts = ref.watch(teamPostsProvider(selectedTeamId));
    } else {
      posts = teams
          .expand((team) => ref.watch(teamPostsProvider(team.id)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Build a teamId -> team name lookup map for post display.
    final teamNameMap = {for (final t in teams) t.id: t.name};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.teamCommunity,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTeamDialog(context, ref),
        icon: const Icon(Icons.group_add),
        label: Text(l10n.createTeam),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Team list header
                _TeamListSection(
                  teams: teams,
                  selectedTeamId: selectedTeamId,
                  onSelectTeam: (id) {
                    ref.read(selectedTeamProvider.notifier).state =
                        id == selectedTeamId ? null : id;
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    l10n.teamFeed,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateWidget(
                      icon: Icons.article_outlined,
                      title: l10n.noPostsYet,
                      subtitle: l10n.writeFirstPost,
                    ),
                  )
                else
                  ...posts.map(
                    (post) => _FeedPostCard(
                      post: post,
                      teamName:
                          teamNameMap[post.teamId] ?? '알 수 없는 팀',
                      currentUserId: currentUserId ?? '',
                      onLike: () => ref
                          .read(communityProvider.notifier)
                          .toggleLikePost(post.teamId, post.id),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.createNewTeam,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.teamNameHint,
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                hintText: l10n.teamDescHint,
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(communityProvider.notifier).createTeam(
                          name: name,
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          isPublic: true,
                        );
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.createTeamAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team List Section
// ---------------------------------------------------------------------------

class _TeamListSection extends StatelessWidget {
  final List<Team> teams;
  final String? selectedTeamId;
  final ValueChanged<String> onSelectTeam;

  const _TeamListSection({
    required this.teams,
    required this.selectedTeamId,
    required this.onSelectTeam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(
            l10n.myTeams,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (teams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: EmptyStateWidget(
              icon: Icons.group_outlined,
              title: l10n.noTeamsYet,
              subtitle: l10n.joinOrCreateTeam,
            ),
          )
        else
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: teams.length + 1, // +1 for join button
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              if (i == teams.length) {
                // Join / discover teams button
                return GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.joinTeam,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final team = teams[i];
              final teamColor = _teamColor(i);
              final initial = team.name.isNotEmpty
                  ? team.name.characters.first
                  : '?';
              final isSelected = team.id == selectedTeamId;

              return GestureDetector(
                onTap: () => onSelectTeam(team.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? teamColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? teamColor
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? teamColor : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${team.memberCount}명',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feed Post Card
// ---------------------------------------------------------------------------

class _FeedPostCard extends StatelessWidget {
  final TeamPost post;
  final String teamName;
  final String currentUserId;
  final VoidCallback onLike;

  const _FeedPostCard({
    required this.post,
    required this.teamName,
    required this.currentUserId,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authorColor = _colorFromHash(post.author.id);
    final authorInitial = post.author.displayName.isNotEmpty
        ? post.author.displayName.characters.first
        : '?';
    final isLiked = post.isLikedBy(currentUserId);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: authorColor.withValues(alpha: 0.2),
                  child: Text(
                    authorInitial,
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
                        post.author.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  authorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              teamName,
                              style: TextStyle(
                                fontSize: 11,
                                color: authorColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timeAgo(post.createdAt, l10n),
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

            const SizedBox(height: 12),

            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: isLiked ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 20, color: Colors.grey),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
