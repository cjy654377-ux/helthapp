import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/features/auth/providers/auth_providers.dart';
import 'package:health_app/l10n/app_localizations.dart';

// 에러 키를 로컬라이즈된 문자열로 변환
String _getErrorMessage(AppLocalizations l10n, String errorKey) {
  switch (errorKey) {
    case 'auth_error_email_in_use':
      return l10n.authErrorEmailInUse;
    case 'auth_error_invalid_email':
      return l10n.authErrorInvalidEmail;
    case 'auth_error_weak_password':
      return l10n.authErrorWeakPassword;
    case 'auth_error_user_not_found':
      return l10n.authErrorUserNotFound;
    case 'auth_error_wrong_password':
      return l10n.authErrorWrongPassword;
    case 'auth_error_too_many_requests':
      return l10n.authErrorTooManyRequests;
    case 'auth_error_user_disabled':
      return l10n.authErrorUserDisabled;
    case 'auth_error_cancelled':
      return l10n.authErrorCancelled;
    default:
      return l10n.authErrorUnknown;
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpMode = false;   // 로그인/회원가입 모드 토글
  bool _obscurePassword = true; // 비밀번호 가시성 토글

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 비밀번호 재설정 다이얼로그
  Future<void> _showPasswordResetDialog() async {
    final l10n = AppLocalizations.of(context);
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.forgotPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.passwordResetDesc),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.forgotPassword),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(authProvider.notifier)
          .sendPasswordReset(resetEmailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.passwordResetSent : l10n.authErrorUnknown),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }

    resetEmailController.dispose();
  }

  // 로그인 또는 회원가입 실행
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(authProvider.notifier);

    if (_isSignUpMode) {
      await notifier.signUpWithEmail(email: email, password: password);
    } else {
      await notifier.signInWithEmail(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 인증 상태 변화 감지: 에러 스낵바, 인증 완료 시 네비게이션
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        final message = _getErrorMessage(l10n, next.errorMessage!);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
            ),
          );
      }

      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        // 스플래시와 동일한 그라디언트 배경
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0), // 파란색
              Color(0xFF00897B), // 틸색
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 앱 아이콘 + 타이틀 영역 (스플래시와 유사)
                    _buildHeader(l10n),

                    const SizedBox(height: 40),

                    // 이메일 입력 필드
                    _buildEmailField(l10n, isLoading),

                    const SizedBox(height: 12),

                    // 비밀번호 입력 필드
                    _buildPasswordField(l10n, isLoading),

                    const SizedBox(height: 8),

                    // 비밀번호 찾기 링크 (로그인 모드에서만 표시)
                    if (!_isSignUpMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _showPasswordResetDialog,
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 로그인 / 회원가입 버튼
                    _buildSubmitButton(l10n, isLoading),

                    const SizedBox(height: 24),

                    // 구분선 "또는"
                    _buildDivider(l10n),

                    const SizedBox(height: 20),

                    // Google 로그인 버튼
                    _buildGoogleSignInButton(l10n, isLoading),

                    // Apple 로그인 버튼 (iOS 전용)
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      _buildAppleSignInButton(l10n, isLoading),
                    ],

                    const SizedBox(height: 32),

                    // 모드 전환 링크 (계정 없음/있음)
                    _buildToggleModeButton(l10n, isLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 앱 아이콘 + 타이틀 + 서브타이틀
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        // 앱 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha:0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // 앱 타이틀
        Text(
          l10n.loginTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // 서브타이틀
        Text(
          l10n.loginSubtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha:0.8),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 이메일 입력 필드
  Widget _buildEmailField(AppLocalizations l10n, bool isLoading) {
    return TextFormField(
      controller: _emailController,
      enabled: !isLoading,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(color: Color(0xFF1A1A2E)),
      decoration: _buildInputDecoration(
        label: l10n.emailLabel,
        hint: l10n.emailHint,
        prefixIcon: Icons.email_outlined,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.authErrorInvalidEmail;
        }
        // 간단한 이메일 형식 검증
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value.trim())) {
          return l10n.authErrorInvalidEmail;
        }
        return null;
      },
    );
  }

  // 비밀번호 입력 필드
  Widget _buildPasswordField(AppLocalizations l10n, bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      enabled: !isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      style: const TextStyle(color: Color(0xFF1A1A2E)),
      decoration: _buildInputDecoration(
        label: l10n.passwordLabel,
        hint: l10n.passwordHint,
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF1565C0),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.authErrorWeakPassword;
        }
        if (_isSignUpMode && value.length < 6) {
          return l10n.authErrorWeakPassword;
        }
        return null;
      },
    );
  }

  // 공통 InputDecoration (흰색 둥근 컨테이너)
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF1565C0)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF607D8B)),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      errorStyle: const TextStyle(color: Color(0xFFFF5252)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
      ),
    );
  }

  // 로그인 / 회원가입 메인 버튼
  Widget _buildSubmitButton(AppLocalizations l10n, bool isLoading) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          disabledBackgroundColor: Colors.white.withValues(alpha:0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1565C0),
                ),
              )
            : Text(_isSignUpMode ? l10n.signUp : l10n.signIn),
      ),
    );
  }

  // "또는" 구분선
  Widget _buildDivider(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha:0.4),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.orDivider,
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.7),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha:0.4),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // Google 로그인 버튼
  Widget _buildGoogleSignInButton(AppLocalizations l10n, bool isLoading) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => ref.read(authProvider.notifier).signInWithGoogle(),
        icon: _GoogleLogo(),
        label: Text(l10n.signInWithGoogle),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF444444),
          disabledBackgroundColor: Colors.white.withValues(alpha:0.6),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Apple 로그인 버튼 (iOS 전용)
  Widget _buildAppleSignInButton(AppLocalizations l10n, bool isLoading) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => ref.read(authProvider.notifier).signInWithApple(),
        icon: const Icon(Icons.apple, size: 22, color: Colors.white),
        label: Text(l10n.signInWithApple),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha:0.6),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 모드 전환 링크 (회원가입 <-> 로그인)
  Widget _buildToggleModeButton(AppLocalizations l10n, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUpMode ? l10n.haveAccount : l10n.noAccount,
          style: TextStyle(
            color: Colors.white.withValues(alpha:0.8),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode;
                    _formKey.currentState?.reset();
                  });
                },
          child: Text(
            _isSignUpMode ? l10n.signIn : l10n.signUp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Google 로고 위젯 (SVG 없이 텍스트 + 컬러로 표현)
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

// Google 로고 커스텀 페인터
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // 배경 원 (흰색 배경 위에 그려지므로 생략)

    // G 문자를 4가지 색상 호로 표현
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r * 0.62,
    );

    // 빨간색 (상단)
    canvas.drawArc(rect, -2.36, 1.57, false, paintRed);
    // 노란색 (좌측 하단)
    canvas.drawArc(rect, -0.79, 1.57, false, paintYellow);
    // 초록색 (하단)
    canvas.drawArc(rect, 0.78, 1.57, false, paintGreen);
    // 파란색 (우측)
    canvas.drawArc(rect, 2.36, 1.57, false, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
