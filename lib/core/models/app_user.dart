// Firebase 인증 사용자 모델
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// 앱 내에서 사용하는 통합 사용자 모델
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? provider; // 'email', 'google', 'apple'
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.provider,
    required this.createdAt,
  });

  /// Firebase User로부터 AppUser 생성
  factory AppUser.fromFirebaseUser(fb.User user) {
    String? provider;
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId == 'google.com') {
        provider = 'google';
      } else if (providerId == 'apple.com') {
        provider = 'apple';
      } else {
        provider = 'email';
      }
    }

    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: provider,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'provider': provider,
    'createdAt': createdAt.toIso8601String(),
  };

  /// JSON 역직렬화
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    email: json['email'] as String?,
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
    provider: json['provider'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
  }) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    provider: provider,
    createdAt: createdAt,
  );
}
