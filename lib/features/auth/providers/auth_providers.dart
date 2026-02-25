// Firebase 인증 상태 관리 Provider
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/app_user.dart';
import 'package:health_app/core/services/auth_service.dart';

// ---------------------------------------------------------------------------
// AuthService Provider
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ---------------------------------------------------------------------------
// Auth 상태 열거형
// ---------------------------------------------------------------------------

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

// ---------------------------------------------------------------------------
// AuthState - 인증 상태 모델
// ---------------------------------------------------------------------------

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
  );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// ---------------------------------------------------------------------------
// AuthNotifier - 인증 상태 관리
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Firebase Auth 상태 변화 감시
    _authSub = _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: AppUser.fromFirebaseUser(firebaseUser),
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// 이메일 회원가입
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'auth_error_unknown',
      );
    }
  }

  /// 이메일 로그인
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'auth_error_unknown',
      );
    }
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.signInWithGoogle();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'cancelled') {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'auth_error_unknown',
      );
    }
  }

  /// Apple 로그인
  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.signInWithApple();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'auth_error_unknown',
      );
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 비밀번호 재설정
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Firebase 에러 코드 → 사용자 메시지 매핑
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'auth_error_email_in_use';
      case 'invalid-email':
        return 'auth_error_invalid_email';
      case 'weak-password':
        return 'auth_error_weak_password';
      case 'user-not-found':
        return 'auth_error_user_not_found';
      case 'wrong-password':
        return 'auth_error_wrong_password';
      case 'too-many-requests':
        return 'auth_error_too_many_requests';
      case 'user-disabled':
        return 'auth_error_user_disabled';
      case 'cancelled':
        return 'auth_error_cancelled';
      default:
        return 'auth_error_unknown';
    }
  }
}

// ---------------------------------------------------------------------------
// Provider 정의
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// 현재 인증된 사용자 편의 Provider
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});
