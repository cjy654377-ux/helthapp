// 커뮤니티 관련 데이터 모델
// Team, TeamPost, WorkoutShare 등의 불변 클래스 정의

/// 팀 멤버 역할 열거형
enum TeamRole {
  owner('팀장'),
  admin('관리자'),
  member('멤버');

  final String label;
  const TeamRole(this.label);
}

/// 게시글 타입 열거형
enum PostType {
  guestbook('방명록'),
  announcement('공지'),
  challenge('챌린지'),
  general('일반');

  final String label;
  const PostType(this.label);
}

// ---------------------------------------------------------------------------
// UserProfile - 간략한 사용자 프로필 (커뮤니티 내에서 사용)
// ---------------------------------------------------------------------------

/// 커뮤니티 내에서 표시되는 간략한 사용자 정보
class UserProfile {
  final String id;
  final String username; // 사용자명
  final String displayName; // 표시 이름
  final String? avatarUrl; // 프로필 사진 URL
  final String? bio; // 자기소개

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserProfile(id: $id, username: $username)';
}

// ---------------------------------------------------------------------------
// TeamMember - 팀 멤버
// ---------------------------------------------------------------------------

/// 팀의 개별 멤버 정보
class TeamMember {
  final UserProfile user;
  final TeamRole role; // 멤버 역할
  final DateTime joinedAt; // 가입 일시
  final bool isActive; // 활성 상태

  const TeamMember({
    required this.user,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  TeamMember copyWith({
    UserProfile? user,
    TeamRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return TeamMember(
      user: user ?? this.user,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      role: TeamRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => TeamRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

// ---------------------------------------------------------------------------
// Team 모델
// ---------------------------------------------------------------------------

/// 팀(그룹) 정보를 표현하는 불변 클래스
class Team {
  final String id;
  final String name; // 팀 이름
  final String? description; // 팀 설명
  final String? imageUrl; // 팀 대표 이미지 URL
  final List<TeamMember> members; // 팀 멤버 목록
  final bool isPublic; // 공개 팀 여부
  final int maxMembers; // 최대 멤버 수
  final DateTime createdAt; // 팀 생성일

  const Team({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.members,
    this.isPublic = true,
    this.maxMembers = 20,
    required this.createdAt,
  });

  /// 팀원 수
  int get memberCount => members.where((m) => m.isActive).length;

  /// 팀장 정보
  TeamMember? get owner {
    try {
      return members.firstWhere((m) => m.role == TeamRole.owner);
    } catch (_) {
      return null;
    }
  }

  /// 팀이 꽉 찼는지 여부
  bool get isFull => memberCount >= maxMembers;

  /// 특정 사용자가 팀 멤버인지 확인
  bool hasMember(String userId) =>
      members.any((m) => m.user.id == userId && m.isActive);

  /// 특정 사용자의 역할 반환
  TeamRole? getMemberRole(String userId) {
    try {
      return members.firstWhere((m) => m.user.id == userId).role;
    } catch (_) {
      return null;
    }
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<TeamMember>? members,
    bool? isPublic,
    int? maxMembers,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      members: (json['members'] as List<dynamic>)
          .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPublic: json['is_public'] as bool? ?? true,
      maxMembers: json['max_members'] as int? ?? 20,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'members': members.map((e) => e.toJson()).toList(),
      'is_public': isPublic,
      'max_members': maxMembers,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, members: $memberCount)';
}

// ---------------------------------------------------------------------------
// PostComment 모델 - 게시글 댓글
// ---------------------------------------------------------------------------

/// 게시글에 달린 댓글
class PostComment {
  final String id;
  final UserProfile author;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likedByIds; // 좋아요 누른 사용자 ID 목록

  const PostComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likedByIds = const [],
  });

  int get likeCount => likedByIds.length;

  bool isLikedBy(String userId) => likedByIds.contains(userId);

  PostComment copyWith({
    String? id,
    UserProfile? author,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likedByIds,
  }) {
    return PostComment(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedByIds: likedByIds ?? this.likedByIds,
    );
  }

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      author: UserProfile.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      likedByIds: List<String>.from(json['liked_by_ids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'liked_by_ids': likedByIds,
    };
  }
}

// ---------------------------------------------------------------------------
// TeamPost 모델 - 팀 방명록/피드 게시글
// ---------------------------------------------------------------------------

/// 팀 내 방명록 또는 피드에 작성된 게시글
class TeamPost {
  final String id;
  final String teamId; // 소속 팀 ID
  final UserProfile author; // 작성자
  final PostType type; // 게시글 타입
  final String content; // 게시글 내용
  final List<String> imageUrls; // 첨부 이미지 URL 목록
  final List<PostComment> comments; // 댓글 목록
  final List<String> likedByIds; // 좋아요 누른 사용자 ID 목록
  final DateTime createdAt; // 작성 일시
  final DateTime? updatedAt; // 수정 일시
  final bool isPinned; // 공지 고정 여부

  const TeamPost({
    required this.id,
    required this.teamId,
    required this.author,
    required this.type,
    required this.content,
    this.imageUrls = const [],
    this.comments = const [],
    this.likedByIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
  });

  int get likeCount => likedByIds.length;
  int get commentCount => comments.length;

  bool isLikedBy(String userId) => likedByIds.contains(userId);

  TeamPost copyWith({
    String? id,
    String? teamId,
    UserProfile? author,
    PostType? type,
    String? content,
    List<String>? imageUrls,
    List<PostComment>? comments,
    List<String>? likedByIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return TeamPost(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      author: author ?? this.author,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      comments: comments ?? this.comments,
      likedByIds: likedByIds ?? this.likedByIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory TeamPost.fromJson(Map<String, dynamic> json) {
    return TeamPost(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      author: UserProfile.fromJson(json['author'] as Map<String, dynamic>),
      type: PostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PostType.general,
      ),
      content: json['content'] as String,
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      likedByIds: List<String>.from(json['liked_by_ids'] as List? ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'author': author.toJson(),
      'type': type.name,
      'content': content,
      'image_urls': imageUrls,
      'comments': comments.map((e) => e.toJson()).toList(),
      'liked_by_ids': likedByIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_pinned': isPinned,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamPost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TeamPost(id: $id, author: ${author.username}, likes: $likeCount)';
}

// ---------------------------------------------------------------------------
// WorkoutShareEntry - 공유된 운동 세트 정보
// ---------------------------------------------------------------------------

/// 운동 공유 시 포함되는 개별 운동 데이터
class WorkoutShareEntry {
  final String exerciseName;
  final int sets; // 세트 수
  final int reps; // 반복 횟수
  final double weight; // 최대 무게 (kg)

  const WorkoutShareEntry({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  WorkoutShareEntry copyWith({
    String? exerciseName,
    int? sets,
    int? reps,
    double? weight,
  }) {
    return WorkoutShareEntry(
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }

  factory WorkoutShareEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutShareEntry(
      exerciseName: json['exercise_name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  @override
  String toString() =>
      'WorkoutShareEntry($exerciseName: ${sets}x$reps @ ${weight}kg)';
}

// ---------------------------------------------------------------------------
// WorkoutShare 모델 - 운동 기록 공유
// ---------------------------------------------------------------------------

/// 커뮤니티에 공유된 운동 기록 (사진 포함 가능)
class WorkoutShare {
  final String id;
  final UserProfile author; // 공유한 사용자
  final String? teamId; // 공유 대상 팀 ID (null이면 전체 공개)
  final String workoutTitle; // 운동 세션 제목 (예: "오늘의 가슴 운동")
  final DateTime workoutDate; // 운동 날짜
  final int durationMinutes; // 운동 시간 (분)
  final List<WorkoutShareEntry> exercises; // 수행한 운동 목록
  final double totalVolume; // 총 볼륨 (kg)
  final List<String> photoUrls; // 인증 사진 URL 목록
  final String? caption; // 게시글 캡션 (소감 등)
  final List<String> likedByIds; // 좋아요 누른 사용자 ID 목록
  final List<PostComment> comments; // 댓글 목록
  final DateTime createdAt; // 게시 일시

  const WorkoutShare({
    required this.id,
    required this.author,
    this.teamId,
    required this.workoutTitle,
    required this.workoutDate,
    required this.durationMinutes,
    required this.exercises,
    required this.totalVolume,
    this.photoUrls = const [],
    this.caption,
    this.likedByIds = const [],
    this.comments = const [],
    required this.createdAt,
  });

  int get likeCount => likedByIds.length;
  int get commentCount => comments.length;

  bool isLikedBy(String userId) => likedByIds.contains(userId);

  WorkoutShare copyWith({
    String? id,
    UserProfile? author,
    String? teamId,
    String? workoutTitle,
    DateTime? workoutDate,
    int? durationMinutes,
    List<WorkoutShareEntry>? exercises,
    double? totalVolume,
    List<String>? photoUrls,
    String? caption,
    List<String>? likedByIds,
    List<PostComment>? comments,
    DateTime? createdAt,
  }) {
    return WorkoutShare(
      id: id ?? this.id,
      author: author ?? this.author,
      teamId: teamId ?? this.teamId,
      workoutTitle: workoutTitle ?? this.workoutTitle,
      workoutDate: workoutDate ?? this.workoutDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      totalVolume: totalVolume ?? this.totalVolume,
      photoUrls: photoUrls ?? this.photoUrls,
      caption: caption ?? this.caption,
      likedByIds: likedByIds ?? this.likedByIds,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WorkoutShare.fromJson(Map<String, dynamic> json) {
    return WorkoutShare(
      id: json['id'] as String,
      author: UserProfile.fromJson(json['author'] as Map<String, dynamic>),
      teamId: json['team_id'] as String?,
      workoutTitle: json['workout_title'] as String,
      workoutDate: DateTime.parse(json['workout_date'] as String),
      durationMinutes: json['duration_minutes'] as int,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => WorkoutShareEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVolume: (json['total_volume'] as num).toDouble(),
      photoUrls: List<String>.from(json['photo_urls'] as List? ?? []),
      caption: json['caption'] as String?,
      likedByIds: List<String>.from(json['liked_by_ids'] as List? ?? []),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'team_id': teamId,
      'workout_title': workoutTitle,
      'workout_date': workoutDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'total_volume': totalVolume,
      'photo_urls': photoUrls,
      'caption': caption,
      'liked_by_ids': likedByIds,
      'comments': comments.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutShare &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutShare(id: $id, author: ${author.username}, title: $workoutTitle)';
}
