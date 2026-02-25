# Decision Log - HealthApp

## D-001: Tech Stack Selection
- **결정**: Flutter + Riverpod + go_router + Firebase
- **대안**: React Native, Native (Swift/Kotlin)
- **이유**: 카메라앱 프로젝트와 동일한 스택으로 개발 효율 극대화, 크로스플랫폼 46% 시장 점유율

## D-002: Feature-First Directory Structure
- **결정**: lib/features/ 하위에 기능별 폴더 구조
- **대안**: Layer-first (presentation/domain/data)
- **이유**: 기능이 많은 헬스앱 특성상 기능별 분리가 유지보수에 유리

## D-003: Agent System
- **결정**: Opus(설계) -> Sonnet(구현) -> Haiku(반복 작업) 3단계 에이전트
- **대안**: 단일 에이전트
- **이유**: 카메라앱에서 검증된 효율적 토큰 관리 + 작업 병렬화

## D-004: Initial MVP Features
- **결정**: 운동 가이드, 운동 기록, 팀 커뮤니티, 식단, 수분, 캘린더 6개 핵심 기능
- **대안**: 운동 기록만 MVP
- **이유**: 시장 조사 결과 올인원 앱이 리텐션 높음, 차별화 포인트 확보

## D-005: Exercise Database Size
- **결정**: 50개+ 운동 데이터 (부위별 5-7개), 한국어 운동 설명/팁 포함
- **대안**: 외부 API 사용
- **이유**: 오프라인 사용 가능, 초기 MVP에서는 로컬 데이터로 충분

## D-006: AI Workout Recommendation
- **결정**: 로컬 알고리즘 기반 (최근 운동 부위 제외, 스플릿 기반, 진행적 과부하)
- **대안**: 외부 AI API (ChatGPT 등)
- **이유**: 초기 단계에서는 규칙 기반으로 충분, 추후 AI API 연동 가능

---

## Progress Log

### Checkpoint: Phase 1 Complete (2026-02-24)
**완료된 작업:**
- Flutter 프로젝트 생성 + 패키지 설치
- 에이전트 MD 3개 (CLAUDE.md, haiku-worker.md, sonnet-implementer.md)
- 토큰 한계 프로토콜 + 자가 리뷰 사이클 추가
- 테마 (라이트/다크), 라우터 (go_router + 바텀네비), 모델 3개
- 화면 8개: 홈, 운동가이드, 운동기록, 커뮤니티, 식단, 수분, 캘린더, 프로필
- Provider 6개: 운동기록, 운동DB(50+운동), 식단(30+음식), 수분, 캘린더, 커뮤니티
- 서비스 3개: 알림, 로컬저장, 업적(19개 업적)
- flutter analyze: 0 issues
- 총 코드: 14,515줄

**Phase 2 완료 (2026-02-24):**
- 챌린지 시스템 (Provider + UI, 7개 프리셋, 커스텀 생성)
- 통계 시각화 화면 (운동/체성분/영양/스트릭, fl_chart 차트 8개)
- 온보딩 플로우 (4페이지, 기본정보+목표 입력, SharedPreferences)
- 설정 화면 (프로필/운동/알림/앱/기타 5섹션)
- 라우터 업데이트 (온보딩 리다이렉트, 신규 4라우트)
- flutter analyze: 0 issues
- 총 코드: 29파일, 20,935줄

**Phase 3 완료 (2026-02-24):**
- Before/After 사진 비교 (갤러리/비교/타임라인 3탭)
- 휴식 타이머 (원형 CustomPainter + 진동 + 프리셋)
- 스플래시 화면 (그라디언트 + 애니메이션 + 초기화 플로우)
- 테스트 코드 208개 (모델/Provider/서비스/위젯)
- flutter analyze: 0 issues, flutter test: 208 passed
- 총: lib 32파일 24,228줄 + test 6파일 3,019줄 = 27,247줄

**Phase 4 완료 (2026-02-24):**
- 7개 화면 ↔ Provider 직접 연결 완료 (로컬 더미 데이터 제거)
  - HomeScreen → workoutProviders, hydrationProvider, dietProvider, calendarProvider
  - WorkoutGuideScreen → exerciseDatabaseProvider
  - WorkoutLogScreen → workoutSessionProvider, workoutHistoryProvider
  - DietScreen → dietProvider, foodDatabaseProvider
  - HydrationScreen → hydrationProvider, waterTimelineProvider
  - CommunityScreen → communityProvider, myTeamsProvider, teamPostsProvider
  - CalendarScreen → calendarProvider, selectedDatePlansProvider
- flutter analyze: 0 issues, flutter test: 208 passed

**Phase 5 완료 (2026-02-24):**
- LocalStorageService 초기화 수정 (main.dart에서 앱 시작 전 init() 호출)
- 중복 라우트 제거 (standalone 라우트 3개 제거)
- 공통 Empty/Loading/Error 위젯 생성 (core/widgets/common_states.dart)
- 4개 화면에 Empty 상태 적용 (Calendar, Community, WorkoutLog, Diet)
- HomeScreen 하드코딩 사용자명 제거 → SharedPreferences 온보딩 닉네임 연동
- flutter analyze: 0 issues, flutter test: 208 passed
- 총: lib 33파일 24,544줄

**Phase 6 완료 (2026-02-24):**
- Stats 화면 실제 데이터 연결 (하드코딩 목 데이터 전체 제거)
  - workoutHistoryProvider → 주간 운동일수, 월간 볼륨, 부위별 비율, Top5 운동
  - dietProvider → 주간 칼로리, 매크로 비율
  - hydrationProvider → 주간 수분 달성률
  - achievementService → 업적 달성 현황
  - currentStreakProvider → 운동 스트릭
  - Empty 상태 처리 (데이터 없을 때)
- 챌린지-운동 데이터 자동 연동 (challenge_integration_service.dart)
  - 운동 완료 시 → workout/volume 챌린지 진행률 자동 업데이트
  - 식단 기록 시 → diet 챌린지 진행률 자동 업데이트
  - 수분 목표 달성 시 → water 챌린지 진행률 자동 업데이트
- flutter analyze: 0 issues, flutter test: 208 passed
- 총: lib 34파일 24,832줄

**Phase 7 완료 (2026-02-24):**
- flutter_local_notifications 실제 OS 알림 구현
  - flutter_local_notifications + timezone 패키지 설치
  - Android 권한 설정 (POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM 등)
  - Android 부트 리시버 등록 (재부팅 후 알림 유지)
  - NotificationService 전면 업그레이드 (Timer 기반 → OS 알림)
  - 수분/운동/식단/휴식 4종 리마인더 OS 알림 지원
  - 인앱 폴백 (포그라운드 Timer) 병행 지원
  - main.dart에서 앱 시작 시 NotificationService.init() 호출
- 위젯 테스트 27개 추가 (5개 핵심 화면)
  - WorkoutGuideScreen: 6개 (부위 선택, 운동 목록)
  - DietScreen: 5개 (칼로리, 매크로)
  - HydrationScreen: 6개 (수분 추가, 타임라인)
  - CalendarScreen: 5개 (캘린더 렌더링)
  - CommunityScreen: 5개 (팀, 피드)
- flutter analyze: 0 issues, flutter test: 235 passed
- 총: lib 34파일 24,947줄 + test 7파일 3,343줄 = 28,290줄

**Phase 8 완료 (2026-02-24):**
- Flutter l10n 인프라 구축
  - l10n.yaml 설정 (gen_l10n)
  - app_ko.arb: 한국어 80개 키 (기본 언어)
  - app_en.arb: 영어 80개 키
  - AppLocalizations 클래스 자동 생성
  - MaterialApp에 localizationsDelegates + supportedLocales 연결
  - intl + flutter_localizations 패키지 추가
- flutter analyze: 0 issues, flutter test: 235 passed
- 총: lib 37파일 26,564줄 + test 7파일 3,343줄 = 29,907줄

**Phase 9 완료 (2026-02-24):**
- 6개 화면에 AppLocalizations 적용 (하드코딩 한국어 → l10n 키)
  - HomeScreen: ~20개 문자열 (greeting, healthyDay, headingToGoal, todayWorkout 등)
  - WorkoutGuideScreen: ~10개 문자열 + _localizedBodyPartName() 헬퍼
  - DietScreen: ~12개 문자열 (dietManagement, todayCalories, protein, carbs, fat 등)
  - HydrationScreen: ~12개 문자열 (hydration, quickAdd, customInput, weeklyHydration 등)
  - CalendarScreen: ~9개 문자열 (workoutCalendar, addPlan, exerciseName 등)
  - CommunityScreen: ~12개 문자열 (teamCommunity, myTeams, teamFeed, createTeam 등)
- 위젯 테스트 l10n 호환성 수정 (localizationsDelegates 추가)
- flutter analyze: 0 issues, flutter test: 235 passed
- 총: lib 37파일 26,629줄 + test 7파일 3,348줄 = 29,977줄

**Phase 10 완료 (2026-02-24):**
- 나머지 8개 화면에 AppLocalizations 적용 (하드코딩 한국어 → l10n 키)
  - StatsScreen: ~100개 문자열 (운동통계, 체성분, 영양, 스트릭, 요일/월 이름)
  - SettingsScreen: ~80개 문자열 (5섹션 전체, 다이얼로그)
  - OnboardingScreen: ~60개 문자열 (4페이지 전체)
  - SplashScreen: 3개 문자열
  - ChallengeScreen: ~50개 문자열 (3탭, 생성폼, 다이얼로그)
  - BodyProgressScreen: ~70개 문자열 (3탭, 사진 추가, 비교)
  - RestTimerScreen: ~15개 문자열
  - ProfileScreen: ~40개 문자열
- ARB 키 총 280+ 개 (app_ko.arb + app_en.arb)
- 불필요한 non-null assertion(!) 경고 수정
- flutter analyze: 0 issues, flutter test: 235 passed
- 총: lib 37파일 29,404줄 + test 7파일 3,348줄 = 32,752줄

**Phase 11 완료 (2026-02-24):**
- 남은 하드코딩 한국어 문자열 정리 (3개 화면 + 1 유틸)
  - WorkoutLogScreen: ~30개 문자열 (운동 추가/완료/검색/세트 관리)
  - HydrationScreen: ~10개 문자열 (알림 설정, 요일 이름, 목표)
  - CommunityScreen: _timeAgo 함수 l10n 적용 (방금 전/분 전/시간 전/일 전)
  - 헬퍼 함수 추가 (_localizedBodyPart, _dayLabel에 context 전달)
- ARB 키 총 310+ 개 (app_ko.arb + app_en.arb)
- flutter analyze: 0 issues, flutter test: 235 passed
- 총: lib 37파일 29,788줄 + test 7파일 3,348줄 = 33,136줄

**Phase 12 완료 (2026-02-24):**
- 위젯 테스트 34개 추가 (7개 화면 커버리지)
  - additional_screen_test.dart (20개): Profile(5), Settings(5), Stats(5), Challenge(5)
  - home_workout_test.dart (14개): Onboarding(5), WorkoutLog(5), Splash(4)
- 테스트 커버리지: 7/37 → 9/37 파일 (12개 화면 테스트 완료)
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 37파일 29,788줄 + test 9파일 3,828줄 = 33,616줄

**Phase 13 완료 (2026-02-24):**
- 자가 리뷰 사이클: 코드 품질/UX 개선
  - app_constants.dart 생성 (하드코딩된 목표값 중앙 상수화)
    - dailyWaterGoalMl, defaultReminderHours, dailyCalorieGoal, defaultRestTimerSeconds 등
  - 3개 파일에서 하드코딩 2000ml/[9,12,15,18,21] → AppDefaults 상수 참조로 변경
    - hydration_providers.dart, stats_screen.dart, diet_model.dart
  - 홈 화면 Quick Action 버튼 실제 네비게이션 연결 (기존 빈 onTap)
    - "운동 시작" → /workout-log, "식단 기록" → /diet, "물 마시기" → /hydration
  - 미사용 import 정리 (home_screen.dart: common_states.dart 제거)
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 38파일 29,817줄 + test 9파일 3,828줄 = 33,645줄

## D-007: Firebase 연동 아키텍처 설계
- **결정**: 5단계 점진적 Firebase 연동 (Phase 0~4)
- **대안**: 전면 Firestore 전환 (Big-bang)
- **이유**: 기존 269 테스트 보존, 오프라인 우선 전략, 점진적 안정성 확보

### Firebase 연동 계획 (설계 완료, 구현 대기):
- **Phase 0**: Firebase 패키지 + 플랫폼 설정 (pubspec, gradle, Info.plist)
- **Phase 1**: Repository 추상화 (Provider↔저장소 사이 인터페이스 삽입)
  - 생성: data_repository.dart, local_data_repository.dart, repository_providers.dart
  - 수정: 5개 feature provider (workout, diet, hydration, calendar, community)
- **Phase 2**: Firebase Auth + 로그인 UI (이메일/Google/Apple)
  - 생성: auth_service.dart, app_user.dart, auth_providers.dart, login_screen.dart
  - 수정: main.dart, app_router.dart, splash_screen.dart
- **Phase 3**: Firestore 클라우드 동기화 (오프라인 우선 + write-through cache)
  - Firestore 스키마: users/{uid}/workouts|meals|hydration|calendar + teams/{id}/posts
  - 생성: firestore_data_repository.dart, sync_service.dart, firestore.rules
- **Phase 4**: Firebase Storage (바디 프로그레스/팀 사진 업로드)
  - 생성: storage_service.dart

### Firestore 컬렉션 구조:
```
users/{uid}/ → profile, workouts/, meals/, hydration/, calendarPlans/, bodyProgress/, achievements/
teams/{teamId}/ → members/, posts/, workoutShares/
challenges/{id}/ → participants/
```

**Firebase Phase 0 완료 (2026-02-25):**
- pubspec.yaml: firebase_core, firebase_auth, cloud_firestore, firebase_storage, google_sign_in, sign_in_with_apple, crypto 추가
- main.dart: Firebase.initializeApp() + Firestore 오프라인 퍼시스턴스 설정
- firebase_options.dart 생성 (kofilter-f28d8 프로젝트, TODO: flutterfire configure로 실제 앱 ID 교체)
- Android: google-services.json 플레이스홀더, minSdk=23, google-services 플러그인
- iOS: Info.plist에 Google Sign-In URL scheme 추가
- flutter analyze: 0 issues, flutter test: 269 passed

**Firebase Phase 1 완료 (2026-02-25) - Repository 추상화:**
- core/repositories/data_repository.dart: 5개 추상 인터페이스 (Workout, Diet, Hydration, Calendar, Community)
- core/repositories/local_data_repository.dart: SharedPreferences 구현체 5개
- core/repositories/repository_providers.dart: Riverpod Provider 정의 (기본값: Local)
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 42파일 + test 9파일

**Firebase Phase 2 완료 (2026-02-25) - Auth + 로그인 UI:**
- core/models/app_user.dart: Firebase User 래핑 모델 (fromFirebaseUser, toJson, fromJson, copyWith)
- core/services/auth_service.dart: Firebase Auth 래퍼 (이메일/Google/Apple 로그인, 로그아웃, 비밀번호 재설정)
- features/auth/providers/auth_providers.dart: AuthState + AuthNotifier (StateNotifier), authProvider, currentUserProvider
- features/auth/screens/login_screen.dart: 로그인/회원가입 UI (그라디언트 배경, 이메일/Google/Apple, 모드 토글)
- core/router/app_router.dart: /login 라우트 추가
- features/home/screens/splash_screen.dart: Firebase Auth 체크 → 미인증→로그인, 인증+미온보딩→온보딩, 인증+완료→홈
- ARB 키 35개 추가 (로그인/회원가입/에러 메시지, ko+en)
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 46파일 + test 9파일

**Firebase Phase 3 완료 (2026-02-25) - Firestore 클라우드 동기화:**
- core/repositories/firestore_data_repository.dart: 5개 Firestore 구현체
  - FirestoreWorkoutRepository: users/{uid}/workouts/*, personalRecords/*
  - FirestoreDietRepository: users/{uid}/meals/{dateKey}, settings/nutritionGoal, settings/recentFoods
  - FirestoreHydrationRepository: users/{uid}/hydration/{dateKey}, settings/hydrationSettings
  - FirestoreCalendarRepository: users/{uid}/calendarPlans/{dateKey}
  - FirestoreCommunityRepository: users/{uid}/settings/communityProfile, teams/{teamId}/posts/*, shares/*
- core/services/sync_service.dart: 로컬→Firestore 마이그레이션 (synced_{uid} 키로 중복 방지)
- core/repositories/repository_providers.dart: 인증 시 Firestore 구현체로 자동 전환
- firestore.rules: 사용자 데이터 본인만 접근, 팀 인증 사용자 읽기/쓰기
- 배치 쓰기 500개 단위 청크, 오프라인 퍼시스턴스 활성화
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 48파일 + test 9파일

**Firebase Phase 4 완료 (2026-02-25) - Firebase Storage:**
- core/services/storage_service.dart: 사진 업로드/삭제 서비스
  - uploadBodyProgressPhoto: users/{uid}/body_progress/{timestamp}_{pose}.jpg
  - uploadProfilePhoto: users/{uid}/profile/avatar.jpg
  - uploadTeamPostImage: teams/{teamId}/posts/{postId}/{uuid}.jpg
  - deleteByUrl, deleteByPath, deleteFolder (재귀 삭제)
  - storageServiceProvider (Riverpod)
- flutter analyze: 0 issues, flutter test: 269 passed
- 총: lib 49파일 + test 9파일

**Firebase 연동 전체 완료 (Phase 0~4)**

**Provider-Repository 배선 완료 (2026-02-25):**
- 6개 feature provider 모두 Repository 주입으로 전환 완료
  - workout, diet, hydration, calendar, community, challenge
- 인증 상태에 따라 Local/Firestore 자동 전환
- test/helpers/test_overrides.dart: 테스트에서 Local repo 강제 사용
- flutter analyze: 0 issues, flutter test: 269 passed

**자가 리뷰 사이클 1차 완료 (2026-02-25):**
- currentUserProvider 이름 충돌 해결 (community → communityCurrentUserProvider)
- body_progress_screen 커스텀 regex JSON 파서 → dart:convert 교체
- 6개 provider 레거시 메서드명 정리 (_loadFromPrefs → _load)
- flutter analyze: 0 issues, flutter test: 269 passed

**하드코딩 문자열 i18n 처리 완료 (2026-02-25):**
- settings_screen, home_screen, onboarding_screen 총 23개 ARB 키 추가
- 날짜 포맷, 요일, 기본 사용자명, 백업/복원/삭제 메시지 등

**AchievementService Repository 전환 완료 (2026-02-25):**
- AchievementRepository 인터페이스 + Local/Firestore 구현체
- AchievementService: LocalStorageService → AchievementRepository 주입
- local_storage_service.dart 완전 삭제 (중복 레이어 제거)
- main.dart에서 LocalStorageService().init() 제거
- flutter analyze: 0 issues, flutter test: 269 passed

**자가 리뷰 2차 완료 (2026-02-25):**
- body fat TextField controller 누락 버그 수정 (const 제거)
- 비밀번호 리셋 결과 미확인 → success/fail 분기 처리
- SyncService: Challenge + Achievement 마이그레이션 추가 + splash 배선
- flutter analyze: 0 issues, flutter test: 269 passed

**자가 리뷰 3차 완료 (2026-02-25):**
- LocalAchievementRepository: load에서 잘못된 키('user_settings') → 올바른 키로 수정 (데이터 유실 방지)
- AppRoutes: workoutLog('/workout-log' → '/workout-guide/log'), hydration('/hydration' → '/diet/hydration') 경로 수정
- SyncService try-catch + firebaseUser 변수 재사용 (null 안전성)
- 바텀 네비게이션 5개 탭 + 404 에러 페이지 + 공통 재시도 버튼 i18n 전환 (8 ARB 키)
- 에러 페이지: 릴리즈 모드에서 에러 상세 숨김 (kDebugMode)
- home_screen: userNicknameProvider 제거 → settingsProvider 직접 참조
- splash_screen: SharedPreferences 직접 접근 → onboardingCompletedProvider 재사용
- settings_screen: _load/_save/clearAllData 에러 핸들링 + _save 500ms 디바운스 + dispose
- flutter analyze: 0 issues, flutter test: 269 passed

**자가 리뷰 4차 완료 (2026-02-26) - 코드 품질 + 메모리 안정성:**
- AuthNotifier 스트림 구독 누수 수정 (StreamSubscription 저장 + dispose cancel)
- DietNotifier/Hydration/Calendar/Community/WorkoutHistory: disposed 가드 추가 (async state 접근 크래시 방지)
- SettingsNotifier 디바운스 레이스 컨디션 수정 (_disposed 플래그)
- Google/Apple 로그인 크래시 핸들링 (PlatformException → FirebaseAuthException 래핑)
- SplashScreen Firebase 직접 접근 → authServiceProvider 전환
- Firestore 레포 silent catch → debugPrint 로깅 24개 추가
- 알림 서비스 중첩 타이머 레이스 컨디션 수정
- 중복 날짜 포맷 → AppDefaults.dateKey() 유틸 추출
- 하드코딩 한국어 2건 → i18n 전환 (privacyPolicy/termsOfService)
- flutter analyze: 0 issues, flutter test: 269 passed

**자가 리뷰 5차 완료 (2026-02-26) - UI/UX + i18n 완성:**
- 하드코딩 한국어 30개 → l10n 전환 (calendar/diet/workout_log)
  - 캘린더: 스플릿 템플릿 라벨, 부위명, 날짜 포맷, 완료 배지
  - 식단: 빈 상태, 매크로, 음식 추가 시트, 검색 UI 전체
  - 운동기록: 휴식 타이머 시간 라벨
- 접근성: IconButton tooltip 추가 (검색/알림/캘린더/더보기)
- 키보드: 식단 음식 검색 스크롤 시 자동 dismiss (onDrag)
- 햅틱: 운동 세트 체크/추가/완료 시 진동 피드백
- 팀명 텍스트 ellipsis 일관성 적용
- _QuickActionButton static const 필드 추출 (성능)
- flutter analyze: 0 issues, flutter test: 269 passed

**다음 작업:**
- 자가 리뷰 6차 (notification_service i18n, achievement_service i18n 등)

**기타 대기:**
- notification_service.dart 푸시 알림 텍스트 i18n
- achievement_service.dart 업적 제목/설명 i18n
- body_progress_screen BodyProgressRepository 추출
- onboarding_screen SharedPreferences → settingsProvider 통합
- iOS GoogleService-Info.plist CLIENT_ID 추가 (Firebase Console에서 Google Sign-In 활성화 필요)
- Info.plist REVERSED_CLIENT_ID 실제 값 교체
- 홈화면 위젯 (iOS/Android)
- 앱 아이콘 + Fastlane 빌드
- 캘린더 landscape 대응
- pull-to-refresh 패턴 추가
- 스크롤-투-탑 (바텀 네비 탭 재탭)
