// 스플래시/로딩 화면 - 앱 초기화 중 표시되는 애니메이션 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// 초기화 상태 열거형
// ---------------------------------------------------------------------------

enum SplashStatus { initializing, done }

// ---------------------------------------------------------------------------
// 초기화 Provider
// ---------------------------------------------------------------------------

/// 앱 초기화를 담당하는 FutureProvider.
/// SharedPreferences를 초기화하고 온보딩 완료 여부를 반환합니다.
final splashInitProvider = FutureProvider<bool>((ref) async {
  // 2초 딜레이 (스플래시 애니메이션 재생 시간 확보)
  await Future.wait([
    Future<void>.delayed(const Duration(seconds: 2)),
    _checkOnboardingCompleted(),
  ]).then((results) => results);

  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

Future<bool> _checkOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
}

// ---------------------------------------------------------------------------
// SplashScreen
// ---------------------------------------------------------------------------

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // 아이콘 FadeIn + ScaleUp 애니메이션 컨트롤러
  late final AnimationController _iconController;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;

  // 텍스트 SlideUp + FadeIn 애니메이션 컨트롤러
  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();

    // 아이콘 애니메이션 설정 (0ms ~ 700ms)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconFade = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeIn,
    );
    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );

    // 텍스트 애니메이션 설정 (300ms 딜레이 후 시작)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 순차적으로 애니메이션 시작
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _iconController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await _textController.forward();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _navigateWhenReady(bool onboardingCompleted) {
    if (_navigationTriggered || !mounted) return;
    _navigationTriggered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (onboardingCompleted) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Provider 감시 - 초기화 완료 시 자동 이동
    ref.listen<AsyncValue<bool>>(splashInitProvider, (_, next) {
      next.whenData(_navigateWhenReady);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0), // 파란색
              Color(0xFF00897B), // 녹색
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 중앙 콘텐츠 (아이콘 + 앱 이름)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 앱 아이콘 - FadeIn + ScaleUp 애니메이션
                      FadeTransition(
                        opacity: _iconFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 앱 이름 텍스트 - SlideUp + FadeIn 애니메이션
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              Text(
                                l10n.appTitle,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.healthyLifestyleStart,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 로딩 인디케이터
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loading,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
