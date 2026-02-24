// Firebase 인증 서비스 래퍼
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:health_app/core/models/app_user.dart';

/// Firebase Auth 래퍼 서비스
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 현재 AppUser
  AppUser? get currentAppUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebaseUser(user);
  }

  // --- 이메일 로그인 ---

  /// 이메일 회원가입
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppUser.fromFirebaseUser(credential.user!);
  }

  /// 이메일 로그인
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppUser.fromFirebaseUser(credential.user!);
  }

  // --- Google 로그인 ---

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Google 로그인이 취소되었습니다.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return AppUser.fromFirebaseUser(userCredential.user!);
  }

  // --- Apple 로그인 ---

  Future<AppUser> signInWithApple() async {
    // nonce 생성
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple은 첫 로그인 시에만 이름 제공 → displayName 업데이트
    if (appleCredential.givenName != null) {
      await userCredential.user?.updateDisplayName(
        '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim(),
      );
    }

    return AppUser.fromFirebaseUser(userCredential.user!);
  }

  // --- 로그아웃 ---

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // --- 비밀번호 재설정 ---

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- 계정 삭제 ---

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  // --- 유틸 ---

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
