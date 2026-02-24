// 팀 커뮤니티 상태 관리
// CommunityNotifier: 팀 생성/참가, 포스트 작성, 좋아요/댓글 관리

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/core/repositories/repository_providers.dart';

// ---------------------------------------------------------------------------
// CommunityState - 커뮤니티 전체 상태
// ---------------------------------------------------------------------------

/// 커뮤니티 전체 상태
class CommunityState {
  final List<Team> myTeams; // 내가 속한 팀 목록
  final List<Team> allPublicTeams; // 공개 팀 전체 목록
  final Map<String, List<TeamPost>> teamPosts; // teamId -> 게시글 목록
  final Map<String, List<WorkoutShare>> workoutShares; // teamId -> 운동 공유
  final String? currentUserId; // 현재 로그인한 사용자 ID
  final UserProfile? currentUser; // 현재 사용자 프로필
  final bool isLoading;
  final String? errorMessage;

  const CommunityState({
    this.myTeams = const [],
    this.allPublicTeams = const [],
    this.teamPosts = const {},
    this.workoutShares = const {},
    this.currentUserId,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 특정 팀의 게시글 조회 (고정 포스트 우선)
  List<TeamPost> getPostsForTeam(String teamId) {
    final posts = teamPosts[teamId] ?? [];
    final sorted = List<TeamPost>.from(posts)
      ..sort((a, b) {
        // 공지 먼저
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted;
  }

  /// 특정 팀의 운동 공유 조회
  List<WorkoutShare> getWorkoutSharesForTeam(String teamId) {
    final shares = workoutShares[teamId] ?? [];
    return [...shares]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CommunityState copyWith({
    List<Team>? myTeams,
    List<Team>? allPublicTeams,
    Map<String, List<TeamPost>>? teamPosts,
    Map<String, List<WorkoutShare>>? workoutShares,
    String? currentUserId,
    UserProfile? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityState(
      myTeams: myTeams ?? this.myTeams,
      allPublicTeams: allPublicTeams ?? this.allPublicTeams,
      teamPosts: teamPosts ?? this.teamPosts,
      workoutShares: workoutShares ?? this.workoutShares,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// 샘플/시드 데이터 (즉시 테스트용)
// ---------------------------------------------------------------------------

/// 샘플 사용자 프로필
final _sampleUser = UserProfile(
  id: 'user_local',
  username: 'fitness_user',
  displayName: '헬스 유저',
  bio: '열심히 운동 중입니다 💪',
);

/// 샘플 팀 목록
List<Team> _buildSampleTeams() {
  final now = DateTime.now();
  return [
    Team(
      id: 'team_001',
      name: '새벽반 헬스팀',
      description: '매일 새벽 5시 운동하는 팀입니다. 함께 성장해요!',
      members: [
        TeamMember(
          user: _sampleUser,
          role: TeamRole.owner,
          joinedAt: now.subtract(const Duration(days: 30)),
        ),
        TeamMember(
          user: const UserProfile(
            id: 'user_002',
            username: 'gym_king',
            displayName: '운동왕',
          ),
          role: TeamRole.member,
          joinedAt: now.subtract(const Duration(days: 20)),
        ),
      ],
      isPublic: true,
      createdAt: now.subtract(const Duration(days: 30)),
    ),
    Team(
      id: 'team_002',
      name: '다이어트 챌린지 팀',
      description: '12주 감량 챌린지! 같이 해봐요',
      members: [
        TeamMember(
          user: const UserProfile(
            id: 'user_003',
            username: 'diet_master',
            displayName: '다이어트 마스터',
          ),
          role: TeamRole.owner,
          joinedAt: now.subtract(const Duration(days: 14)),
        ),
      ],
      isPublic: true,
      createdAt: now.subtract(const Duration(days: 14)),
    ),
  ];
}

/// 샘플 팀 게시글
List<TeamPost> _buildSamplePosts(String teamId) {
  final now = DateTime.now();
  return [
    TeamPost(
      id: 'post_001',
      teamId: teamId,
      author: const UserProfile(
        id: 'user_002',
        username: 'gym_king',
        displayName: '운동왕',
      ),
      type: PostType.announcement,
      content: '이번 주 챌린지: 매일 운동 인증 필수! 빠지지 말고 함께해요 💪',
      likedByIds: const ['user_local', 'user_003'],
      createdAt: now.subtract(const Duration(hours: 2)),
      isPinned: true,
    ),
    TeamPost(
      id: 'post_002',
      teamId: teamId,
      author: _sampleUser,
      type: PostType.guestbook,
      content: '오늘 가슴 운동 완료! 벤치프레스 100kg 달성했어요 🎉',
      likedByIds: const ['user_002'],
      comments: [
        PostComment(
          id: 'comment_001',
          author: const UserProfile(
            id: 'user_002',
            username: 'gym_king',
            displayName: '운동왕',
          ),
          content: '와 대박이에요! 축하드립니다!',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}

// ---------------------------------------------------------------------------
// CommunityNotifier
// ---------------------------------------------------------------------------

class CommunityNotifier extends StateNotifier<CommunityState> {
  CommunityNotifier(this._repo) : super(const CommunityState()) {
    _initialize();
  }

  final CommunityRepository _repo;

  // ── 초기화 ────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _load();
      // 샘플 데이터가 없으면 시드 데이터 로드
      if (state.myTeams.isEmpty) {
        await _loadSeedData();
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadSeedData() async {
    final sampleTeams = _buildSampleTeams();
    final samplePosts = <String, List<TeamPost>>{};
    final sampleShares = <String, List<WorkoutShare>>{};

    for (final team in sampleTeams) {
      samplePosts[team.id] = _buildSamplePosts(team.id);
      sampleShares[team.id] = [];
    }

    state = state.copyWith(
      myTeams: sampleTeams,
      allPublicTeams: sampleTeams,
      teamPosts: samplePosts,
      workoutShares: sampleShares,
      currentUser: _sampleUser,
      currentUserId: _sampleUser.id,
      isLoading: false,
    );
    await _save();
  }

  // ── 영속성 ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      // 사용자 정보 로드
      final user = await _repo.loadCurrentUser();

      // 팀 목록 로드
      final teams = await _repo.loadMyTeams();

      // 각 팀의 게시글 및 운동 공유 로드
      final teamPosts = <String, List<TeamPost>>{};
      final workoutShares = <String, List<WorkoutShare>>{};

      for (final team in teams) {
        teamPosts[team.id] = await _repo.loadTeamPosts(team.id);
        workoutShares[team.id] = await _repo.loadTeamShares(team.id);
      }

      if (teams.isNotEmpty) {
        state = CommunityState(
          myTeams: teams,
          allPublicTeams: teams,
          teamPosts: teamPosts,
          workoutShares: workoutShares,
          currentUser: user ?? _sampleUser,
          currentUserId: user?.id ?? _sampleUser.id,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _save() async {
    try {
      // 사용자 정보 저장
      if (state.currentUser != null) {
        await _repo.saveCurrentUser(state.currentUser!);
      }

      // 팀 목록 저장
      await _repo.saveMyTeams(state.myTeams);

      // 각 팀의 게시글 저장
      for (final entry in state.teamPosts.entries) {
        await _repo.saveTeamPosts(entry.key, entry.value);
      }

      // 운동 공유 저장
      for (final entry in state.workoutShares.entries) {
        await _repo.saveTeamShares(entry.key, entry.value);
      }
    } catch (_) {}
  }

  // ── 팀 관리 ───────────────────────────────────────────────────────────────

  /// 팀 생성
  Future<void> createTeam({
    required String name,
    String? description,
    bool isPublic = true,
    int maxMembers = 20,
  }) async {
    final user = state.currentUser ?? _sampleUser;

    final team = Team(
      id: const Uuid().v4(),
      name: name,
      description: description,
      members: [
        TeamMember(
          user: user,
          role: TeamRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
      isPublic: isPublic,
      maxMembers: maxMembers,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      myTeams: [...state.myTeams, team],
      allPublicTeams: isPublic
          ? [...state.allPublicTeams, team]
          : state.allPublicTeams,
      teamPosts: {...state.teamPosts, team.id: []},
      workoutShares: {...state.workoutShares, team.id: []},
    );
    await _save();
  }

  /// 팀 참가
  Future<void> joinTeam(String teamId) async {
    final user = state.currentUser ?? _sampleUser;

    final updatedPublicTeams = state.allPublicTeams.map((team) {
      if (team.id != teamId) return team;
      if (team.isFull) return team;
      if (team.hasMember(user.id)) return team;

      return team.copyWith(
        members: [
          ...team.members,
          TeamMember(
            user: user,
            role: TeamRole.member,
            joinedAt: DateTime.now(),
          ),
        ],
      );
    }).toList();

    // 내 팀 목록에 추가
    Team? joinedTeam;
    try {
      joinedTeam =
          updatedPublicTeams.firstWhere((t) => t.id == teamId);
    } catch (_) {}

    final alreadyInMyTeams =
        state.myTeams.any((t) => t.id == teamId);

    state = state.copyWith(
      allPublicTeams: updatedPublicTeams,
      myTeams: (joinedTeam != null && !alreadyInMyTeams)
          ? [...state.myTeams, joinedTeam]
          : state.myTeams,
      teamPosts: {
        ...state.teamPosts,
        if (!state.teamPosts.containsKey(teamId)) teamId: [],
      },
    );
    await _save();
  }

  /// 팀 탈퇴
  Future<void> leaveTeam(String teamId) async {
    final userId = state.currentUserId ?? _sampleUser.id;

    final updatedMyTeams =
        state.myTeams.where((t) => t.id != teamId).toList();

    final updatedPublicTeams = state.allPublicTeams.map((team) {
      if (team.id != teamId) return team;
      return team.copyWith(
        members: team.members
            .map((m) {
              if (m.user.id != userId) return m;
              return m.copyWith(isActive: false);
            })
            .toList(),
      );
    }).toList();

    state = state.copyWith(
      myTeams: updatedMyTeams,
      allPublicTeams: updatedPublicTeams,
    );
    await _save();
  }

  // ── 게시글 관리 ───────────────────────────────────────────────────────────

  /// 게시글 작성
  Future<void> createPost({
    required String teamId,
    required String content,
    PostType type = PostType.guestbook,
    List<String> imageUrls = const [],
  }) async {
    final user = state.currentUser ?? _sampleUser;

    final post = TeamPost(
      id: const Uuid().v4(),
      teamId: teamId,
      author: user,
      type: type,
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    final existingPosts =
        List<TeamPost>.from(state.teamPosts[teamId] ?? []);
    existingPosts.insert(0, post);

    state = state.copyWith(
      teamPosts: {...state.teamPosts, teamId: existingPosts},
    );
    await _save();
  }

  /// 게시글 좋아요 토글
  Future<void> toggleLikePost(String teamId, String postId) async {
    final userId = state.currentUserId ?? _sampleUser.id;

    final updatedPosts =
        (state.teamPosts[teamId] ?? []).map((post) {
      if (post.id != postId) return post;

      final likedBy = List<String>.from(post.likedByIds);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      return post.copyWith(likedByIds: likedBy);
    }).toList();

    state = state.copyWith(
      teamPosts: {...state.teamPosts, teamId: updatedPosts},
    );
    await _save();
  }

  /// 댓글 작성
  Future<void> addComment({
    required String teamId,
    required String postId,
    required String content,
  }) async {
    final user = state.currentUser ?? _sampleUser;

    final comment = PostComment(
      id: const Uuid().v4(),
      author: user,
      content: content,
      createdAt: DateTime.now(),
    );

    final updatedPosts =
        (state.teamPosts[teamId] ?? []).map((post) {
      if (post.id != postId) return post;
      return post.copyWith(
          comments: [...post.comments, comment]);
    }).toList();

    state = state.copyWith(
      teamPosts: {...state.teamPosts, teamId: updatedPosts},
    );
    await _save();
  }

  /// 게시글 삭제
  Future<void> deletePost(String teamId, String postId) async {
    final userId = state.currentUserId ?? _sampleUser.id;

    final updatedPosts = (state.teamPosts[teamId] ?? [])
        .where((post) {
      // 본인 게시글만 삭제 가능
      return !(post.id == postId && post.author.id == userId);
    }).toList();

    state = state.copyWith(
      teamPosts: {...state.teamPosts, teamId: updatedPosts},
    );
    await _save();
  }

  // ── 운동 공유 ─────────────────────────────────────────────────────────────

  /// 운동 기록 공유
  Future<void> shareWorkout({
    required String teamId,
    required String workoutTitle,
    required DateTime workoutDate,
    required int durationMinutes,
    required List<WorkoutShareEntry> exercises,
    required double totalVolume,
    List<String> photoUrls = const [],
    String? caption,
  }) async {
    final user = state.currentUser ?? _sampleUser;

    final share = WorkoutShare(
      id: const Uuid().v4(),
      author: user,
      teamId: teamId,
      workoutTitle: workoutTitle,
      workoutDate: workoutDate,
      durationMinutes: durationMinutes,
      exercises: exercises,
      totalVolume: totalVolume,
      photoUrls: photoUrls,
      caption: caption,
      createdAt: DateTime.now(),
    );

    final existingShares =
        List<WorkoutShare>.from(state.workoutShares[teamId] ?? []);
    existingShares.insert(0, share);

    state = state.copyWith(
      workoutShares: {
        ...state.workoutShares,
        teamId: existingShares,
      },
    );
    await _save();
  }

  /// 운동 공유 좋아요 토글
  Future<void> toggleLikeWorkoutShare(
      String teamId, String shareId) async {
    final userId = state.currentUserId ?? _sampleUser.id;

    final updatedShares =
        (state.workoutShares[teamId] ?? []).map((share) {
      if (share.id != shareId) return share;

      final likedBy = List<String>.from(share.likedByIds);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      return share.copyWith(likedByIds: likedBy);
    }).toList();

    state = state.copyWith(
      workoutShares: {
        ...state.workoutShares,
        teamId: updatedShares,
      },
    );
    await _save();
  }

  // ── 사용자 프로필 ─────────────────────────────────────────────────────────

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final current = state.currentUser ?? _sampleUser;
    final updated = current.copyWith(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    state = state.copyWith(currentUser: updated);
    await _save();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 커뮤니티 전체 상태 Provider
final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommunityNotifier(repo);
});

/// 내 팀 목록 Provider
final myTeamsProvider = Provider<List<Team>>((ref) {
  return ref.watch(communityProvider).myTeams;
});

/// 공개 팀 전체 목록 Provider
final allPublicTeamsProvider = Provider<List<Team>>((ref) {
  return ref.watch(communityProvider).allPublicTeams;
});

/// 특정 팀 게시글 Provider (파라미터화)
final teamPostsProvider =
    Provider.family<List<TeamPost>, String>((ref, teamId) {
  final communityState = ref.watch(communityProvider);
  return communityState.getPostsForTeam(teamId);
});

/// 특정 팀 운동 공유 Provider (파라미터화)
final teamWorkoutSharesProvider =
    Provider.family<List<WorkoutShare>, String>((ref, teamId) {
  final communityState = ref.watch(communityProvider);
  return communityState.getWorkoutSharesForTeam(teamId);
});

/// 커뮤니티 현재 사용자 Provider
final communityCurrentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(communityProvider).currentUser;
});

/// 특정 팀 정보 Provider (파라미터화)
final teamByIdProvider =
    Provider.family<Team?, String>((ref, teamId) {
  final teams = ref.watch(allPublicTeamsProvider);
  try {
    return teams.firstWhere((t) => t.id == teamId);
  } catch (_) {
    return null;
  }
});

/// 특정 팀 멤버 목록 Provider (파라미터화)
final teamMembersProvider =
    Provider.family<List<TeamMember>, String>((ref, teamId) {
  final team = ref.watch(teamByIdProvider(teamId));
  return team?.members.where((m) => m.isActive).toList() ?? [];
});

/// 커뮤니티 로딩 상태 Provider
final communityLoadingProvider = Provider<bool>((ref) {
  return ref.watch(communityProvider).isLoading;
});
