// 팀 커뮤니티 상태 관리
// CommunityNotifier: 팀 생성/참가, 포스트 작성, 좋아요/댓글 관리
// FeedNotifier: 소셜 피드 로드/좋아요/댓글
// leaderboardProvider: 리더보드 순위 (family provider)

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
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── 초기화 ────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true);
    try {
      await _load();
      if (_disposed) return;
      // 샘플 데이터가 없으면 시드 데이터 로드
      if (state.myTeams.isEmpty) {
        await _loadSeedData();
      }
    } catch (_) {
      if (_disposed) return;
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

    if (_disposed) return;
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

      if (_disposed) return;
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
      if (_disposed) return;
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

// ---------------------------------------------------------------------------
// FeedState - 소셜 피드 상태
// ---------------------------------------------------------------------------

/// 소셜 활동 피드 상태
class FeedState {
  final List<ActivityFeedItem> items; // 피드 아이템 목록
  final bool isLoading;
  final bool hasMore; // 더 불러올 데이터 존재 여부
  final String? errorMessage;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  FeedState copyWith({
    List<ActivityFeedItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// 소셜 피드 목 데이터 생성
// ---------------------------------------------------------------------------

/// 목 피드 데이터 빌더 - 실제 서비스 연동 전 테스트용
List<ActivityFeedItem> _buildMockFeedItems() {
  final now = DateTime.now();

  // 목 사용자 프로필 목록
  const users = [
    UserProfile(
      id: 'user_local',
      username: 'fitness_user',
      displayName: '헬스 유저',
    ),
    UserProfile(
      id: 'user_002',
      username: 'gym_king',
      displayName: '운동왕',
    ),
    UserProfile(
      id: 'user_003',
      username: 'iron_lady',
      displayName: '아이언 레이디',
    ),
    UserProfile(
      id: 'user_004',
      username: 'cardio_hero',
      displayName: '유산소 영웅',
    ),
    UserProfile(
      id: 'user_005',
      username: 'powerlifter99',
      displayName: '파워리프터',
    ),
  ];

  return [
    ActivityFeedItem(
      id: 'feed_001',
      author: users[1],
      type: FeedItemType.workout,
      content: '오늘 가슴/삼두 루틴 완료! 벤치프레스 신기록 달성했어요 🔥',
      stats: {
        'duration': 75,
        'volume': 8450.0,
        'exercises': ['벤치프레스', '인클라인 덤벨', '케이블 크로스오버', '트라이셉 푸시다운'],
        'sets': 20,
      },
      likedByIds: const ['user_local', 'user_003', 'user_005'],
      comments: [
        PostComment(
          id: 'c_001',
          author: users[0],
          content: '대박이에요! 몇 kg 치셨어요?',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
        PostComment(
          id: 'c_002',
          author: users[2],
          content: '저도 오늘 가슴 했는데 같이 성장해요!',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    ActivityFeedItem(
      id: 'feed_002',
      author: users[2],
      type: FeedItemType.achievement,
      content: '스쿼트 100kg 첫 성공! 6개월 동안 목표했던 무게 드디어 달성!! 💪',
      stats: {
        'exercise': '스쿼트',
        'weight': 100.0,
        'previous_pr': 90.0,
        'improvement': 10.0,
      },
      likedByIds: const ['user_local', 'user_002', 'user_004', 'user_005'],
      comments: [
        PostComment(
          id: 'c_003',
          author: users[4],
          content: '축하해요!! 다음 목표는 120kg!!',
          createdAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 4)),
    ),
    ActivityFeedItem(
      id: 'feed_003',
      author: users[0], // 현재 사용자
      type: FeedItemType.workout,
      content: '등 운동 세션 완료. 데드리프트 위주로 했더니 허리가 살짝 뻐근하네요. 폼 체크 필요!',
      stats: {
        'duration': 60,
        'volume': 6200.0,
        'exercises': ['데드리프트', '바벨 로우', '풀업', '시티드 케이블 로우'],
        'sets': 16,
      },
      likedByIds: const ['user_002', 'user_003'],
      comments: [],
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
    ActivityFeedItem(
      id: 'feed_004',
      author: users[3],
      type: FeedItemType.challenge,
      content: '30일 플랭크 챌린지 Day 15 완료! 오늘 3분 버텼어요. 허리 코어 강화 중!',
      stats: {
        'challenge': '30일 플랭크',
        'day': 15,
        'duration_seconds': 180,
      },
      likedByIds: const ['user_local', 'user_002', 'user_005'],
      comments: [
        PostComment(
          id: 'c_004',
          author: users[0],
          content: '파이팅! 절반 넘었네요!',
          createdAt: now.subtract(const Duration(hours: 8, minutes: 10)),
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 9)),
    ),
    ActivityFeedItem(
      id: 'feed_005',
      author: users[4],
      type: FeedItemType.workout,
      content: '오늘 하체 데이. 스쿼트+레그프레스+런지 삼종세트로 다리가 후들후들',
      stats: {
        'duration': 90,
        'volume': 12800.0,
        'exercises': ['바벨 스쿼트', '레그 프레스', '불가리안 스플릿 스쿼트', '레그 컬'],
        'sets': 24,
      },
      likedByIds: const ['user_002', 'user_003', 'user_004'],
      comments: [],
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    ),
    ActivityFeedItem(
      id: 'feed_006',
      author: users[1],
      type: FeedItemType.photo,
      content: '3개월 비포 & 애프터! 꾸준함이 답입니다. 아직 갈 길이 멀지만 조금씩 변화가 보여요.',
      imageUrls: const [],
      stats: {
        'duration_weeks': 12,
        'workouts_completed': 68,
      },
      likedByIds: const [
        'user_local',
        'user_003',
        'user_004',
        'user_005',
      ],
      comments: [
        PostComment(
          id: 'c_005',
          author: users[2],
          content: '와 진짜 달라졌다! 대단해요!!',
          createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        ),
        PostComment(
          id: 'c_006',
          author: users[0],
          content: '동기부여 받고 갑니다 🙌',
          createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        ),
      ],
      createdAt: now.subtract(const Duration(days: 1, hours: 8)),
    ),
    ActivityFeedItem(
      id: 'feed_007',
      author: users[2],
      type: FeedItemType.workout,
      content: '어깨 운동 집중 루틴! 숄더프레스 무게 올렸어요',
      stats: {
        'duration': 55,
        'volume': 4300.0,
        'exercises': ['바벨 숄더프레스', '사이드 레터럴 레이즈', '페이스풀', '리버스 플라이'],
        'sets': 18,
      },
      likedByIds: const ['user_local', 'user_004'],
      comments: [],
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}

// ---------------------------------------------------------------------------
// FeedNotifier - 소셜 피드 상태 관리
// ---------------------------------------------------------------------------

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    loadFeed();
  }

  static const int _pageSize = 10;
  int _currentPage = 0;
  List<ActivityFeedItem> _allItems = [];

  /// 피드 초기 로드 (목 데이터)
  Future<void> loadFeed() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 목 데이터 로드 (나중에 Firestore 연동으로 교체)
      await Future.delayed(const Duration(milliseconds: 400));
      _allItems = _buildMockFeedItems();
      _currentPage = 0;

      final pageItems = _allItems.take(_pageSize).toList();
      state = state.copyWith(
        items: pageItems,
        isLoading: false,
        hasMore: _allItems.length > _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '피드를 불러오는데 실패했습니다.',
      );
    }
  }

  /// 피드 더 불러오기 (페이지네이션)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentPage++;
      final start = _currentPage * _pageSize;
      final newItems = _allItems.skip(start).take(_pageSize).toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: start + _pageSize < _allItems.length,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 피드 아이템 좋아요 토글
  void likeFeedItem(String itemId, String currentUserId) {
    final updatedItems = state.items.map((item) {
      if (item.id != itemId) return item;
      final likedBy = List<String>.from(item.likedByIds);
      if (likedBy.contains(currentUserId)) {
        likedBy.remove(currentUserId);
      } else {
        likedBy.add(currentUserId);
      }
      return item.copyWith(likedByIds: likedBy);
    }).toList();

    // _allItems 도 함께 업데이트하여 loadMore 시 유지
    _allItems = _allItems.map((item) {
      if (item.id != itemId) return item;
      return updatedItems.firstWhere((i) => i.id == itemId, orElse: () => item);
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// 피드 아이템에 댓글 추가
  void commentOnFeedItem(
    String itemId,
    String text,
    UserProfile currentUser,
  ) {
    if (text.trim().isEmpty) return;
    final comment = PostComment(
      id: const Uuid().v4(),
      author: currentUser,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    final updatedItems = state.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(comments: [...item.comments, comment]);
    }).toList();

    _allItems = _allItems.map((item) {
      if (item.id != itemId) return item;
      return updatedItems.firstWhere((i) => i.id == itemId, orElse: () => item);
    }).toList();

    state = state.copyWith(items: updatedItems);
  }
}

// ---------------------------------------------------------------------------
// 리더보드 목 데이터 생성
// ---------------------------------------------------------------------------

/// 리더보드 목 데이터 빌더 (타입별)
List<LeaderboardEntry> _buildMockLeaderboard(LeaderboardType type) {
  // 현재 사용자 포함 목 경쟁자 목록
  final entries = <Map<String, dynamic>>[
    {
      'userId': 'user_005',
      'name': '파워리프터',
      'weeklyVolume': 54320.0,
      'monthlyWorkouts': 24,
      'streak': 42,
      'totalPRs': 18,
    },
    {
      'userId': 'user_002',
      'name': '운동왕',
      'weeklyVolume': 48100.0,
      'monthlyWorkouts': 22,
      'streak': 35,
      'totalPRs': 15,
    },
    {
      'userId': 'user_003',
      'name': '아이언 레이디',
      'weeklyVolume': 41200.0,
      'monthlyWorkouts': 20,
      'streak': 28,
      'totalPRs': 12,
    },
    {
      'userId': 'user_local', // 현재 사용자
      'name': '헬스 유저',
      'weeklyVolume': 36800.0,
      'monthlyWorkouts': 18,
      'streak': 21,
      'totalPRs': 9,
    },
    {
      'userId': 'user_004',
      'name': '유산소 영웅',
      'weeklyVolume': 28500.0,
      'monthlyWorkouts': 25,
      'streak': 60,
      'totalPRs': 6,
    },
    {
      'userId': 'user_006',
      'name': '주말전사',
      'weeklyVolume': 22000.0,
      'monthlyWorkouts': 10,
      'streak': 8,
      'totalPRs': 4,
    },
    {
      'userId': 'user_007',
      'name': '바디빌더지망생',
      'weeklyVolume': 18900.0,
      'monthlyWorkouts': 17,
      'streak': 15,
      'totalPRs': 7,
    },
    {
      'userId': 'user_008',
      'name': '꾸준한 사람',
      'weeklyVolume': 15600.0,
      'monthlyWorkouts': 15,
      'streak': 12,
      'totalPRs': 3,
    },
  ];

  // 타입별 정렬 기준 선택
  String scoreKey;
  switch (type) {
    case LeaderboardType.weeklyVolume:
      scoreKey = 'weeklyVolume';
    case LeaderboardType.monthlyWorkouts:
      scoreKey = 'monthlyWorkouts';
    case LeaderboardType.streak:
      scoreKey = 'streak';
    case LeaderboardType.totalPRs:
      scoreKey = 'totalPRs';
  }

  // 점수 기준 내림차순 정렬
  entries.sort((a, b) => (b[scoreKey] as num).compareTo(a[scoreKey] as num));

  return entries.asMap().entries.map((entry) {
    final index = entry.key;
    final data = entry.value;
    return LeaderboardEntry(
      userId: data['userId'] as String,
      userName: data['name'] as String,
      score: (data[scoreKey] as num).toDouble(),
      rank: index + 1,
      isCurrentUser: data['userId'] == 'user_local',
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// 소셜 피드 Providers
// ---------------------------------------------------------------------------

/// 소셜 활동 피드 Provider
final feedProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});

/// 팔로잉 사용자 ID 목록 Provider (현재 사용자가 팔로우하는 사람들)
/// 나중에 Firestore 연동으로 교체 예정
final followingProvider = StateProvider<List<String>>((ref) {
  return const ['user_002', 'user_003', 'user_004'];
});

// ---------------------------------------------------------------------------
// 리더보드 Providers
// ---------------------------------------------------------------------------

/// 리더보드 Provider - LeaderboardType별 family provider
final leaderboardProvider =
    Provider.family<List<LeaderboardEntry>, LeaderboardType>((ref, type) {
  return _buildMockLeaderboard(type);
});
