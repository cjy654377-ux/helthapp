// 앱 진입점 - 헬스 & 피트니스 앱
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_app/l10n/app_localizations.dart';

import 'package:health_app/core/theme/app_theme.dart';
import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/core/services/challenge_integration_service.dart';
import 'package:health_app/core/services/notification_service.dart';
import 'package:health_app/firebase_options.dart';

void main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore 오프라인 퍼시스턴스 활성화
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // OS 알림 서비스 초기화
  await NotificationService().init();

  runApp(
    // Riverpod의 ProviderScope로 앱 전체를 감싸 상태 관리 활성화
    const ProviderScope(
      child: HealthApp(),
    ),
  );
}

/// 앱 루트 위젯
class HealthApp extends ConsumerWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // appRouterProvider를 통해 GoRouter 인스턴스 가져오기
    final router = ref.watch(appRouterProvider);

    // 챌린지 통합 서비스 활성화 - 운동/식단/수분 데이터 변경 시 챌린지 자동 업데이트
    ref.watch(challengeIntegrationProvider);

    return MaterialApp.router(
      // 앱 기본 정보
      title: '헬스 & 피트니스',
      debugShowCheckedModeBanner: false,

      // 라우터 설정
      routerConfig: router,

      // 라이트 테마
      theme: AppTheme.lightTheme,

      // 다크 테마
      darkTheme: AppTheme.darkTheme,

      // 시스템 설정에 따라 자동으로 테마 전환
      themeMode: ThemeMode.system,

      // 다국어 지원 (l10n)
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko', 'KR'),
    );
  }
}
