import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// App title
  ///
  /// In ko, this message translates to:
  /// **'헬스 & 피트니스'**
  String get appTitle;

  /// Greeting with user name
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요, {name}님!'**
  String greeting(String name);

  /// Motivational subtitle on home screen
  ///
  /// In ko, this message translates to:
  /// **'오늘도 건강한 하루!'**
  String get healthyDay;

  /// Motivational greeting card message
  ///
  /// In ko, this message translates to:
  /// **'목표를 향해 나아가는 중!'**
  String get headingToGoal;

  /// Today's workout section label
  ///
  /// In ko, this message translates to:
  /// **'오늘의 운동'**
  String get todayWorkout;

  /// Completed exercises label
  ///
  /// In ko, this message translates to:
  /// **'완료한 운동'**
  String get completedExercises;

  /// Total volume label
  ///
  /// In ko, this message translates to:
  /// **'총 볼륨'**
  String get totalVolume;

  /// Hydration intake label on home card
  ///
  /// In ko, this message translates to:
  /// **'수분 섭취'**
  String get hydrationIntake;

  /// Calorie intake label on home card
  ///
  /// In ko, this message translates to:
  /// **'칼로리 섭취'**
  String get calorieIntake;

  /// Goal label
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get goal;

  /// Consumed / intake label
  ///
  /// In ko, this message translates to:
  /// **'섭취'**
  String get consumed;

  /// Remaining label
  ///
  /// In ko, this message translates to:
  /// **'남은'**
  String get remaining;

  /// Exceeded label
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get exceeded;

  /// Kilocalories unit
  ///
  /// In ko, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// Upcoming workout section label
  ///
  /// In ko, this message translates to:
  /// **'다음 예정 운동'**
  String get upcomingWorkout;

  /// Empty state when no workout plan exists
  ///
  /// In ko, this message translates to:
  /// **'운동 계획이 없습니다'**
  String get noWorkoutPlan;

  /// Quick actions section title
  ///
  /// In ko, this message translates to:
  /// **'빠른 실행'**
  String get quickStart;

  /// Quick action: start workout
  ///
  /// In ko, this message translates to:
  /// **'운동 시작'**
  String get startWorkout;

  /// Quick action: log diet
  ///
  /// In ko, this message translates to:
  /// **'식단 기록'**
  String get logDiet;

  /// Quick action: drink water
  ///
  /// In ko, this message translates to:
  /// **'물 마시기'**
  String get drinkWater;

  /// Workout guide screen title
  ///
  /// In ko, this message translates to:
  /// **'운동 가이드'**
  String get workoutGuide;

  /// Body part: chest
  ///
  /// In ko, this message translates to:
  /// **'가슴'**
  String get chest;

  /// Body part: back
  ///
  /// In ko, this message translates to:
  /// **'등'**
  String get back;

  /// Body part: shoulders
  ///
  /// In ko, this message translates to:
  /// **'어깨'**
  String get shoulders;

  /// Body part: arms
  ///
  /// In ko, this message translates to:
  /// **'팔'**
  String get arms;

  /// Body part: legs
  ///
  /// In ko, this message translates to:
  /// **'하체'**
  String get legs;

  /// Body part: core
  ///
  /// In ko, this message translates to:
  /// **'코어'**
  String get core;

  /// Number of exercises
  ///
  /// In ko, this message translates to:
  /// **'{count}개 운동'**
  String exerciseCount(int count);

  /// Exercises for a body part
  ///
  /// In ko, this message translates to:
  /// **'{bodyPart} 운동'**
  String bodyPartExercises(String bodyPart);

  /// Difficulty level: beginner
  ///
  /// In ko, this message translates to:
  /// **'초급'**
  String get beginner;

  /// Difficulty level: intermediate
  ///
  /// In ko, this message translates to:
  /// **'중급'**
  String get intermediate;

  /// Difficulty level: advanced
  ///
  /// In ko, this message translates to:
  /// **'고급'**
  String get advanced;

  /// Equipment label
  ///
  /// In ko, this message translates to:
  /// **'사용 기구'**
  String get equipment;

  /// Description label
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get description;

  /// Tips label
  ///
  /// In ko, this message translates to:
  /// **'팁'**
  String get tips;

  /// Workout log screen title
  ///
  /// In ko, this message translates to:
  /// **'운동 기록'**
  String get workoutLog;

  /// Add exercise button
  ///
  /// In ko, this message translates to:
  /// **'운동 추가'**
  String get addExercise;

  /// Set label for workout
  ///
  /// In ko, this message translates to:
  /// **'세트'**
  String get set;

  /// Kilogram unit
  ///
  /// In ko, this message translates to:
  /// **'kg'**
  String get kg;

  /// Reps unit
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get reps;

  /// Complete / done button
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get complete;

  /// Rest time label
  ///
  /// In ko, this message translates to:
  /// **'휴식 시간'**
  String get restTime;

  /// Diet screen title
  ///
  /// In ko, this message translates to:
  /// **'식단 관리'**
  String get dietManagement;

  /// Today's calorie section title
  ///
  /// In ko, this message translates to:
  /// **'오늘의 칼로리'**
  String get todayCalories;

  /// Protein nutrient
  ///
  /// In ko, this message translates to:
  /// **'단백질'**
  String get protein;

  /// Carbohydrate nutrient
  ///
  /// In ko, this message translates to:
  /// **'탄수화물'**
  String get carbs;

  /// Fat nutrient
  ///
  /// In ko, this message translates to:
  /// **'지방'**
  String get fat;

  /// Meal type: breakfast
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get breakfast;

  /// Meal type: lunch
  ///
  /// In ko, this message translates to:
  /// **'점심'**
  String get lunch;

  /// Meal type: dinner
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get dinner;

  /// Meal type: snack
  ///
  /// In ko, this message translates to:
  /// **'간식'**
  String get snack;

  /// Hydration screen title
  ///
  /// In ko, this message translates to:
  /// **'수분 보충'**
  String get hydration;

  /// Intake amount label
  ///
  /// In ko, this message translates to:
  /// **'섭취량'**
  String get intakeAmount;

  /// Today's intake log section title
  ///
  /// In ko, this message translates to:
  /// **'오늘 섭취 기록'**
  String get todayIntakeLog;

  /// Quick add section label
  ///
  /// In ko, this message translates to:
  /// **'빠른 추가'**
  String get quickAdd;

  /// Custom input button label
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get custom;

  /// Custom input dialog title
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get customInput;

  /// Intake amount in ml field label
  ///
  /// In ko, this message translates to:
  /// **'섭취량 (ml)'**
  String get intakeAmountMl;

  /// Add button
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// Empty state for no records
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없습니다.'**
  String get noRecordYet;

  /// Weekly hydration chart title
  ///
  /// In ko, this message translates to:
  /// **'주간 수분 섭취'**
  String get weeklyHydration;

  /// Achievement rate label
  ///
  /// In ko, this message translates to:
  /// **'달성률'**
  String get achievementRate;

  /// Calendar screen title
  ///
  /// In ko, this message translates to:
  /// **'운동 캘린더'**
  String get workoutCalendar;

  /// Add plan button
  ///
  /// In ko, this message translates to:
  /// **'계획 추가'**
  String get addPlan;

  /// Add workout plan for a specific date
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 운동 계획 추가'**
  String addPlanForDate(int month, int day);

  /// Exercise name field label
  ///
  /// In ko, this message translates to:
  /// **'운동 이름'**
  String get exerciseName;

  /// Exercise name hint text
  ///
  /// In ko, this message translates to:
  /// **'예: 가슴 & 삼두 운동'**
  String get exerciseNameHint;

  /// Body parts label
  ///
  /// In ko, this message translates to:
  /// **'신체 부위'**
  String get bodyParts;

  /// Split template label
  ///
  /// In ko, this message translates to:
  /// **'스플릿 템플릿'**
  String get splitTemplate;

  /// Add plan action button
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get addPlanAction;

  /// Empty state subtitle for calendar
  ///
  /// In ko, this message translates to:
  /// **'이 날짜에 운동 계획을 추가해보세요'**
  String get addWorkoutPlanSubtitle;

  /// Community screen title
  ///
  /// In ko, this message translates to:
  /// **'팀 커뮤니티'**
  String get teamCommunity;

  /// My teams section label
  ///
  /// In ko, this message translates to:
  /// **'내 팀'**
  String get myTeams;

  /// Team feed section label
  ///
  /// In ko, this message translates to:
  /// **'팀 피드'**
  String get teamFeed;

  /// Create team FAB label
  ///
  /// In ko, this message translates to:
  /// **'팀 만들기'**
  String get createTeam;

  /// Create new team dialog title
  ///
  /// In ko, this message translates to:
  /// **'새 팀 만들기'**
  String get createNewTeam;

  /// Team name input hint
  ///
  /// In ko, this message translates to:
  /// **'팀 이름을 입력하세요'**
  String get teamNameHint;

  /// Team description input hint
  ///
  /// In ko, this message translates to:
  /// **'팀 설명 (선택)'**
  String get teamDescHint;

  /// Create team button
  ///
  /// In ko, this message translates to:
  /// **'팀 생성'**
  String get createTeamAction;

  /// Join team button
  ///
  /// In ko, this message translates to:
  /// **'팀 가입'**
  String get joinTeam;

  /// Empty state for no posts
  ///
  /// In ko, this message translates to:
  /// **'아직 게시물이 없습니다'**
  String get noPostsYet;

  /// Empty state subtitle for no posts
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 게시물을 작성해보세요'**
  String get writeFirstPost;

  /// Empty state for no teams
  ///
  /// In ko, this message translates to:
  /// **'아직 팀이 없습니다'**
  String get noTeamsYet;

  /// Empty state subtitle for no teams
  ///
  /// In ko, this message translates to:
  /// **'팀에 참여하거나 새 팀을 만들어보세요'**
  String get joinOrCreateTeam;

  /// Stats screen title
  ///
  /// In ko, this message translates to:
  /// **'통계 & 진척도'**
  String get statsAndProgress;

  /// Workout stats section
  ///
  /// In ko, this message translates to:
  /// **'운동 통계'**
  String get workoutStats;

  /// Body composition section
  ///
  /// In ko, this message translates to:
  /// **'체성분 변화'**
  String get bodyComposition;

  /// Nutrition stats section
  ///
  /// In ko, this message translates to:
  /// **'영양 통계'**
  String get nutritionStats;

  /// Streak and achievements section
  ///
  /// In ko, this message translates to:
  /// **'스트릭 & 업적'**
  String get streakAndAchievements;

  /// Profile screen title
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// Settings label
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// My record section label
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get myRecord;

  /// Total workout days label
  ///
  /// In ko, this message translates to:
  /// **'총 운동일'**
  String get totalWorkoutDays;

  /// Consecutive streak label
  ///
  /// In ko, this message translates to:
  /// **'연속 스트릭'**
  String get consecutiveStreak;

  /// Weight change section title
  ///
  /// In ko, this message translates to:
  /// **'체중 변화'**
  String get weightChange;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// Confirm button
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// Close button
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// Retry button
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No data available message
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get noData;

  /// Notification settings dialog title
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// Hydration reminder instruction
  ///
  /// In ko, this message translates to:
  /// **'수분 섭취 알림을 설정하세요.'**
  String get setHydrationReminder;

  /// Reminder interval: every 1 hour
  ///
  /// In ko, this message translates to:
  /// **'1시간마다'**
  String get everyOneHour;

  /// Reminder interval: every 2 hours
  ///
  /// In ko, this message translates to:
  /// **'2시간마다'**
  String get everyTwoHours;

  /// Reminder interval: every 3 hours
  ///
  /// In ko, this message translates to:
  /// **'3시간마다'**
  String get everyThreeHours;

  /// Reminder set confirmation
  ///
  /// In ko, this message translates to:
  /// **'{interval} 알림이 설정되었습니다.'**
  String reminderSet(String interval);

  /// Challenge screen title
  ///
  /// In ko, this message translates to:
  /// **'챌린지'**
  String get challenge;

  /// Default user name
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get user;

  /// Today label
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// Edit personal info setting
  ///
  /// In ko, this message translates to:
  /// **'개인 정보 수정'**
  String get personalInfoEdit;

  /// Target weight setting
  ///
  /// In ko, this message translates to:
  /// **'목표 체중 설정'**
  String get targetWeightSetting;

  /// Share with friends setting
  ///
  /// In ko, this message translates to:
  /// **'친구에게 공유'**
  String get shareWithFriends;

  /// Privacy policy setting
  ///
  /// In ko, this message translates to:
  /// **'개인 정보 보호 정책'**
  String get privacyPolicy;

  /// Help and support setting
  ///
  /// In ko, this message translates to:
  /// **'도움말 및 지원'**
  String get helpAndSupport;

  /// Logout setting
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// Profile started date
  ///
  /// In ko, this message translates to:
  /// **'{date}부터 운동 시작'**
  String startedWorkoutOn(String date);

  /// Tap to add photo label
  ///
  /// In ko, this message translates to:
  /// **'탭하여 추가'**
  String get tapToAdd;

  /// Add photo button label
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get addPhoto;

  /// Empty state for workout stats
  ///
  /// In ko, this message translates to:
  /// **'운동 기록이 없습니다'**
  String get noWorkoutData;

  /// Empty state subtitle for workout stats
  ///
  /// In ko, this message translates to:
  /// **'운동을 시작하면 여기에 통계가 표시됩니다'**
  String get startWorkoutForStats;

  /// Weekly workout days chart title
  ///
  /// In ko, this message translates to:
  /// **'주간 운동 일수'**
  String get weeklyWorkoutDays;

  /// Days unit
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get days;

  /// Monthly total volume chart title
  ///
  /// In ko, this message translates to:
  /// **'월간 총 볼륨'**
  String get monthlyTotalVolume;

  /// Muscle group ratio chart title
  ///
  /// In ko, this message translates to:
  /// **'부위별 운동 비율'**
  String get muscleGroupRatio;

  /// Top 5 most performed exercises
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 한 운동 Top 5'**
  String get topExercises;

  /// Times/count unit
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get times;

  /// Empty state for weight data
  ///
  /// In ko, this message translates to:
  /// **'체중 기록이 없습니다'**
  String get noWeightData;

  /// Empty state subtitle for weight data
  ///
  /// In ko, this message translates to:
  /// **'체중을 기록하면 변화 추이를 확인할 수 있습니다'**
  String get recordWeightForStats;

  /// Add weight record button
  ///
  /// In ko, this message translates to:
  /// **'체중 기록 추가'**
  String get addWeightRecord;

  /// Weight in kg field label
  ///
  /// In ko, this message translates to:
  /// **'체중 (kg)'**
  String get weightKg;

  /// Body fat percentage field label
  ///
  /// In ko, this message translates to:
  /// **'체지방률 (%)'**
  String get bodyFatPercent;

  /// Skeletal muscle mass field label
  ///
  /// In ko, this message translates to:
  /// **'골격근량 (kg)'**
  String get muscleMassKg;

  /// Body composition summary title
  ///
  /// In ko, this message translates to:
  /// **'체성분 요약'**
  String get bodyCompSummary;

  /// Current weight label
  ///
  /// In ko, this message translates to:
  /// **'현재 체중'**
  String get currentWeight;

  /// Goal achievement rate label
  ///
  /// In ko, this message translates to:
  /// **'목표 달성률'**
  String get goalAchievement;

  /// Empty state for nutrition data
  ///
  /// In ko, this message translates to:
  /// **'영양 기록이 없습니다'**
  String get noNutritionData;

  /// Empty state subtitle for nutrition stats
  ///
  /// In ko, this message translates to:
  /// **'식단을 기록하면 영양 통계를 확인할 수 있습니다'**
  String get recordDietForStats;

  /// Weekly calorie intake chart title
  ///
  /// In ko, this message translates to:
  /// **'주간 칼로리 섭취'**
  String get weeklyCalorieIntake;

  /// Today macro ratio chart title
  ///
  /// In ko, this message translates to:
  /// **'오늘 매크로 비율'**
  String get todayMacroRatio;

  /// Hydration achievement rate chart title
  ///
  /// In ko, this message translates to:
  /// **'수분 섭취 달성률'**
  String get hydrationAchievementRate;

  /// Current consecutive workout days
  ///
  /// In ko, this message translates to:
  /// **'현재 연속 운동일'**
  String get currentConsecutiveDays;

  /// Longest streak record
  ///
  /// In ko, this message translates to:
  /// **'최장 스트릭 기록'**
  String get longestStreak;

  /// Overall achievement rate
  ///
  /// In ko, this message translates to:
  /// **'전체 업적 달성률'**
  String get overallAchievementRate;

  /// Average workout time
  ///
  /// In ko, this message translates to:
  /// **'평균 운동 시간'**
  String get avgWorkoutTime;

  /// Minutes unit
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get minutes;

  /// Monday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get mon;

  /// Tuesday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get tue;

  /// Wednesday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get wed;

  /// Thursday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get thu;

  /// Friday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get fri;

  /// Saturday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get sat;

  /// Sunday abbreviation
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get sun;

  /// January
  ///
  /// In ko, this message translates to:
  /// **'1월'**
  String get jan;

  /// February
  ///
  /// In ko, this message translates to:
  /// **'2월'**
  String get feb;

  /// March
  ///
  /// In ko, this message translates to:
  /// **'3월'**
  String get mar;

  /// April
  ///
  /// In ko, this message translates to:
  /// **'4월'**
  String get apr;

  /// May
  ///
  /// In ko, this message translates to:
  /// **'5월'**
  String get may;

  /// June
  ///
  /// In ko, this message translates to:
  /// **'6월'**
  String get jun;

  /// July
  ///
  /// In ko, this message translates to:
  /// **'7월'**
  String get jul;

  /// August
  ///
  /// In ko, this message translates to:
  /// **'8월'**
  String get aug;

  /// September
  ///
  /// In ko, this message translates to:
  /// **'9월'**
  String get sep;

  /// October
  ///
  /// In ko, this message translates to:
  /// **'10월'**
  String get oct;

  /// November
  ///
  /// In ko, this message translates to:
  /// **'11월'**
  String get nov;

  /// December
  ///
  /// In ko, this message translates to:
  /// **'12월'**
  String get dec;

  /// Profile photo label
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진'**
  String get profilePhoto;

  /// Tap to change label
  ///
  /// In ko, this message translates to:
  /// **'탭하여 변경'**
  String get tapToChange;

  /// Nickname label
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No nickname placeholder
  ///
  /// In ko, this message translates to:
  /// **'닉네임 없음'**
  String get noNickname;

  /// Gender label
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get gender;

  /// Male
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// Female
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// Other gender
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get other;

  /// Height label
  ///
  /// In ko, this message translates to:
  /// **'키'**
  String get height;

  /// Body weight label
  ///
  /// In ko, this message translates to:
  /// **'몸무게'**
  String get weight;

  /// Centimeters unit
  ///
  /// In ko, this message translates to:
  /// **'cm'**
  String get cm;

  /// Workout settings section
  ///
  /// In ko, this message translates to:
  /// **'운동 설정'**
  String get workoutSettings;

  /// Default rest time setting
  ///
  /// In ko, this message translates to:
  /// **'기본 휴식 시간'**
  String get defaultRestTime;

  /// Weight unit setting
  ///
  /// In ko, this message translates to:
  /// **'무게 단위'**
  String get weightUnit;

  /// Default workout split setting
  ///
  /// In ko, this message translates to:
  /// **'기본 운동 스플릿'**
  String get defaultSplit;

  /// Workout reminder setting
  ///
  /// In ko, this message translates to:
  /// **'운동 알림'**
  String get workoutReminder;

  /// Hydration reminder setting
  ///
  /// In ko, this message translates to:
  /// **'수분 알림'**
  String get hydrationReminder;

  /// Meal reminder setting
  ///
  /// In ko, this message translates to:
  /// **'식단 알림'**
  String get mealReminder;

  /// Breakfast/lunch/dinner reminder
  ///
  /// In ko, this message translates to:
  /// **'아침/점심/저녁 식단 알림'**
  String get breakfastLunchDinnerReminder;

  /// App settings section
  ///
  /// In ko, this message translates to:
  /// **'앱 설정'**
  String get appSettings;

  /// Dark mode setting
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkMode;

  /// System mode option
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get systemMode;

  /// Light mode option
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get lightMode;

  /// Dark mode option
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get darkModeOption;

  /// Language setting
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// Korean language
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// English language
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get english;

  /// Data management section
  ///
  /// In ko, this message translates to:
  /// **'데이터 관리'**
  String get dataManagement;

  /// Backup data button
  ///
  /// In ko, this message translates to:
  /// **'데이터 백업'**
  String get backupData;

  /// Restore data button
  ///
  /// In ko, this message translates to:
  /// **'데이터 복원'**
  String get restoreData;

  /// Delete all data button
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터 삭제'**
  String get deleteAllData;

  /// Misc settings section
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get misc;

  /// App version label
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get appVersion;

  /// Terms of service setting
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// Open source licenses setting
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get openSourceLicenses;

  /// Seconds unit
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get seconds;

  /// Seconds with count
  ///
  /// In ko, this message translates to:
  /// **'{count}초'**
  String secondsUnit(int count);

  /// Minutes with count
  ///
  /// In ko, this message translates to:
  /// **'{count}분'**
  String minutesUnit(int count);

  /// Skip button
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// Onboarding title
  ///
  /// In ko, this message translates to:
  /// **'당신만의 건강 파트너'**
  String get yourHealthPartner;

  /// Onboarding subtitle
  ///
  /// In ko, this message translates to:
  /// **'운동, 식단, 커뮤니티를 하나의 앱에서'**
  String get allInOneApp;

  /// Get started button
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get getStarted;

  /// Basic info input page title
  ///
  /// In ko, this message translates to:
  /// **'기본 정보 입력'**
  String get basicInfoInput;

  /// Basic info page subtitle
  ///
  /// In ko, this message translates to:
  /// **'건강 목표에 맞춤 서비스를 제공하기 위해 기본 정보를 알려주세요.'**
  String get tellUsAboutYou;

  /// Nickname input hint
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get nicknameHint;

  /// Select gender label
  ///
  /// In ko, this message translates to:
  /// **'성별 선택'**
  String get selectGender;

  /// Height in cm label
  ///
  /// In ko, this message translates to:
  /// **'키 (cm)'**
  String get heightCm;

  /// Weight in kg field label
  ///
  /// In ko, this message translates to:
  /// **'몸무게 (kg)'**
  String get weightKgField;

  /// Next button
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// Goal setting page title
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get goalSetting;

  /// Goal setting subtitle
  ///
  /// In ko, this message translates to:
  /// **'맞춤 추천을 위해 목표를 설정해주세요.'**
  String get setGoalsForYou;

  /// Fitness level label
  ///
  /// In ko, this message translates to:
  /// **'운동 수준'**
  String get fitnessLevel;

  /// Beginner fitness level
  ///
  /// In ko, this message translates to:
  /// **'초보자'**
  String get beginnerLevel;

  /// Intermediate fitness level
  ///
  /// In ko, this message translates to:
  /// **'중급자'**
  String get intermediateLevel;

  /// Advanced fitness level
  ///
  /// In ko, this message translates to:
  /// **'고급자'**
  String get advancedLevel;

  /// Main goal label
  ///
  /// In ko, this message translates to:
  /// **'주요 목표'**
  String get mainGoal;

  /// Strength gain goal
  ///
  /// In ko, this message translates to:
  /// **'근력 증가'**
  String get strengthGain;

  /// Weight loss goal
  ///
  /// In ko, this message translates to:
  /// **'체중 감량'**
  String get weightLoss;

  /// Endurance improvement goal
  ///
  /// In ko, this message translates to:
  /// **'체력 향상'**
  String get enduranceImprove;

  /// Flexibility improvement goal
  ///
  /// In ko, this message translates to:
  /// **'유연성 향상'**
  String get flexibilityImprove;

  /// Health maintenance goal
  ///
  /// In ko, this message translates to:
  /// **'건강 유지'**
  String get healthMaintain;

  /// Weekly workout count goal
  ///
  /// In ko, this message translates to:
  /// **'주간 운동 횟수 목표'**
  String get weeklyWorkoutGoal;

  /// Times per week unit
  ///
  /// In ko, this message translates to:
  /// **'회/주'**
  String get timesPerWeek;

  /// Daily calorie goal
  ///
  /// In ko, this message translates to:
  /// **'일일 칼로리 목표'**
  String get dailyCalorieGoal;

  /// Daily water goal
  ///
  /// In ko, this message translates to:
  /// **'일일 수분 목표'**
  String get dailyWaterGoal;

  /// Milliliters unit
  ///
  /// In ko, this message translates to:
  /// **'ml'**
  String get ml;

  /// Onboarding completion title
  ///
  /// In ko, this message translates to:
  /// **'준비 완료!'**
  String get allReady;

  /// Onboarding completion message
  ///
  /// In ko, this message translates to:
  /// **'모든 설정이 완료되었습니다.\n지금 바로 건강한 라이프스타일을 시작하세요!'**
  String get allSetMessage;

  /// Start now button
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get startNow;

  /// Splash screen subtitle
  ///
  /// In ko, this message translates to:
  /// **'건강한 라이프스타일의 시작'**
  String get healthyLifestyleStart;

  /// Loading indicator text
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// Active challenges tab
  ///
  /// In ko, this message translates to:
  /// **'참여중'**
  String get participating;

  /// Completed tab
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get completed;

  /// Discover tab
  ///
  /// In ko, this message translates to:
  /// **'찾기'**
  String get discover;

  /// Create challenge button
  ///
  /// In ko, this message translates to:
  /// **'챌린지 만들기'**
  String get createChallenge;

  /// Empty state for no active challenges
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 챌린지가 없어요'**
  String get noChallengesYet;

  /// Empty state subtitle for challenges
  ///
  /// In ko, this message translates to:
  /// **'새로운 챌린지를 찾아 참여해보세요!'**
  String get findChallengeToJoin;

  /// Empty state for no completed challenges
  ///
  /// In ko, this message translates to:
  /// **'완료한 챌린지가 없습니다'**
  String get noCompletedChallenges;

  /// Empty state subtitle for completed challenges
  ///
  /// In ko, this message translates to:
  /// **'챌린지를 완료하고 뱃지를 모아보세요!'**
  String get completeChallengesForBadges;

  /// Personal challenge type
  ///
  /// In ko, this message translates to:
  /// **'개인 챌린지'**
  String get personalChallenge;

  /// Team challenge type
  ///
  /// In ko, this message translates to:
  /// **'팀 챌린지'**
  String get teamChallenge;

  /// Add progress button
  ///
  /// In ko, this message translates to:
  /// **'진행상황 추가'**
  String get addProgress;

  /// Leave challenge button
  ///
  /// In ko, this message translates to:
  /// **'챌린지 탈퇴'**
  String get leaveChallenge;

  /// Due today label
  ///
  /// In ko, this message translates to:
  /// **'오늘 마감'**
  String get dueToday;

  /// Days left label
  ///
  /// In ko, this message translates to:
  /// **'{count}일 남음'**
  String daysLeft(int count);

  /// Participants count
  ///
  /// In ko, this message translates to:
  /// **'{count}명 참가'**
  String participants(int count);

  /// Challenge name field
  ///
  /// In ko, this message translates to:
  /// **'챌린지 이름'**
  String get challengeName;

  /// Challenge name hint
  ///
  /// In ko, this message translates to:
  /// **'예: 30일 스쿼트 챌린지'**
  String get challengeNameHint;

  /// Challenge description field
  ///
  /// In ko, this message translates to:
  /// **'챌린지 설명'**
  String get challengeDescription;

  /// Challenge description hint
  ///
  /// In ko, this message translates to:
  /// **'챌린지에 대한 설명을 입력하세요'**
  String get challengeDescHint;

  /// Challenge type field
  ///
  /// In ko, this message translates to:
  /// **'챌린지 유형'**
  String get challengeType;

  /// Target value field
  ///
  /// In ko, this message translates to:
  /// **'목표값'**
  String get targetValue;

  /// Duration field
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get duration;

  /// 1 week duration
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get oneWeek;

  /// 2 weeks duration
  ///
  /// In ko, this message translates to:
  /// **'2주'**
  String get twoWeeks;

  /// 1 month duration
  ///
  /// In ko, this message translates to:
  /// **'1개월'**
  String get oneMonth;

  /// Challenge scope
  ///
  /// In ko, this message translates to:
  /// **'범위'**
  String get scope;

  /// Start challenge button
  ///
  /// In ko, this message translates to:
  /// **'챌린지 시작하기'**
  String get startChallenge;

  /// Join challenge button
  ///
  /// In ko, this message translates to:
  /// **'참여하기'**
  String get joinChallenge;

  /// Body progress screen title
  ///
  /// In ko, this message translates to:
  /// **'바디 프로그레스'**
  String get bodyProgress;

  /// Photo gallery tab
  ///
  /// In ko, this message translates to:
  /// **'사진 갤러리'**
  String get photoGallery;

  /// Before/after comparison tab
  ///
  /// In ko, this message translates to:
  /// **'Before/After'**
  String get beforeAfter;

  /// Timeline tab
  ///
  /// In ko, this message translates to:
  /// **'타임라인'**
  String get timeline;

  /// Front pose
  ///
  /// In ko, this message translates to:
  /// **'앞모습'**
  String get front;

  /// Side pose
  ///
  /// In ko, this message translates to:
  /// **'옆모습'**
  String get side;

  /// Back pose
  ///
  /// In ko, this message translates to:
  /// **'뒷모습'**
  String get backPose;

  /// Delete photo button
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get deletePhoto;

  /// Delete photo confirmation
  ///
  /// In ko, this message translates to:
  /// **'이 사진을 삭제하시겠습니까?'**
  String get deletePhotoConfirm;

  /// Overlay comparison button
  ///
  /// In ko, this message translates to:
  /// **'오버레이 비교'**
  String get overlayCompare;

  /// Change summary title
  ///
  /// In ko, this message translates to:
  /// **'변화 요약'**
  String get changeSummary;

  /// Add progress photo button
  ///
  /// In ko, this message translates to:
  /// **'진행 사진 추가'**
  String get addProgressPhoto;

  /// Select pose label
  ///
  /// In ko, this message translates to:
  /// **'포즈 선택'**
  String get selectPose;

  /// Optional weight field
  ///
  /// In ko, this message translates to:
  /// **'체중 (선택)'**
  String get weightOptional;

  /// Optional body fat field
  ///
  /// In ko, this message translates to:
  /// **'체지방률 (선택)'**
  String get bodyFatOptional;

  /// Optional memo field
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get memoOptional;

  /// Please add photo message
  ///
  /// In ko, this message translates to:
  /// **'사진을 추가해주세요'**
  String get pleaseAddPhoto;

  /// Select from gallery button
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get selectFromGallery;

  /// Take photo button
  ///
  /// In ko, this message translates to:
  /// **'사진 촬영'**
  String get takePhoto;

  /// Empty state for no photos
  ///
  /// In ko, this message translates to:
  /// **'사진이 없습니다'**
  String get noPhotosYet;

  /// Empty state subtitle for no photos
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 진행 사진을 추가해보세요'**
  String get addFirstPhoto;

  /// Need at least 2 photos for comparison
  ///
  /// In ko, this message translates to:
  /// **'비교하려면 2장 이상의 사진이 필요합니다'**
  String get needTwoPhotos;

  /// Rest timer screen title
  ///
  /// In ko, this message translates to:
  /// **'휴식 타이머'**
  String get restTimer;

  /// Timer done label
  ///
  /// In ko, this message translates to:
  /// **'완료!'**
  String get timerDone;

  /// In progress label
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get inProgress;

  /// Paused label
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get paused;

  /// Subtract 15 seconds
  ///
  /// In ko, this message translates to:
  /// **'-15초'**
  String get minus15sec;

  /// Add 15 seconds
  ///
  /// In ko, this message translates to:
  /// **'+15초'**
  String get plus15sec;

  /// Reset button
  ///
  /// In ko, this message translates to:
  /// **'리셋'**
  String get reset;

  /// Start button
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get start;

  /// Skip timer button
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skipTimer;

  /// Next set label
  ///
  /// In ko, this message translates to:
  /// **'다음 세트:'**
  String get nextSet;

  /// Previous set label
  ///
  /// In ko, this message translates to:
  /// **'이전 세트:'**
  String get previousSet;

  /// Preset times label
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get presetTimes;

  /// Total volume in profile
  ///
  /// In ko, this message translates to:
  /// **'총 볼륨'**
  String get totalVolumeKg;

  /// Before/after photo section in profile
  ///
  /// In ko, this message translates to:
  /// **'Before / After'**
  String get beforeAfterPhoto;

  /// Workout stats menu item in profile
  ///
  /// In ko, this message translates to:
  /// **'운동 통계'**
  String get workoutStatsMenu;

  /// No weight records message
  ///
  /// In ko, this message translates to:
  /// **'체중 기록이 없습니다'**
  String get noWeightRecords;

  /// Edit nickname dialog title
  ///
  /// In ko, this message translates to:
  /// **'닉네임 수정'**
  String get editNickname;

  /// Nickname input hint in dialog
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get enterNickname;

  /// Solo challenge subtitle
  ///
  /// In ko, this message translates to:
  /// **'나 혼자 도전하는 챌린지'**
  String get soloChallenge;

  /// Team challenge subtitle
  ///
  /// In ko, this message translates to:
  /// **'팀원과 함께 도전하는 챌린지'**
  String get teamChallengeSubtitle;

  /// All challenges joined
  ///
  /// In ko, this message translates to:
  /// **'모든 챌린지에 참여 중입니다!'**
  String get allChallengesJoined;

  /// Create custom challenge hint
  ///
  /// In ko, this message translates to:
  /// **'위 버튼으로 커스텀 챌린지를 만들어 보세요.'**
  String get createCustomChallenge;

  /// Leave challenge confirmation
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\'에서 탈퇴하시겠습니까?'**
  String leaveConfirmMessage(String title);

  /// Add value input label
  ///
  /// In ko, this message translates to:
  /// **'추가할 값'**
  String get addValueLabel;

  /// Achievement status
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get achieved;

  /// Period ended status
  ///
  /// In ko, this message translates to:
  /// **'기간 종료'**
  String get periodEnded;

  /// Percent achieved and end date
  ///
  /// In ko, this message translates to:
  /// **'% 달성 · {date} 종료'**
  String percentAchievedEnd(String date);

  /// Days with count
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String daysCount(int count);

  /// Goal with value and unit
  ///
  /// In ko, this message translates to:
  /// **'목표: {value} {unit}'**
  String goalWithValue(String value, String unit);

  /// Challenge joined snackbar
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 챌린지에 참가했습니다!'**
  String challengeJoinedMessage(String title);

  /// Name validation error
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력하세요'**
  String get enterNameValidation;

  /// Target validation error
  ///
  /// In ko, this message translates to:
  /// **'목표값을 입력하세요'**
  String get enterTargetValidation;

  /// Valid number validation error
  ///
  /// In ko, this message translates to:
  /// **'유효한 숫자를 입력하세요'**
  String get enterValidNumber;

  /// Start date label
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get startDateLabel;

  /// End date label
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get endDateLabel;

  /// End date validation error
  ///
  /// In ko, this message translates to:
  /// **'종료일은 시작일 이후여야 합니다.'**
  String get endDateMustBeAfterStart;

  /// Challenge created snackbar
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 챌린지가 생성되었습니다!'**
  String challengeCreatedMessage(String title);

  /// Select date label
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get selectDate;

  /// Slide to compare hint
  ///
  /// In ko, this message translates to:
  /// **'슬라이더를 움직여 비교'**
  String get slideToCompare;

  /// Select above hint
  ///
  /// In ko, this message translates to:
  /// **'위에서 선택하세요'**
  String get selectAbove;

  /// Body fat change label
  ///
  /// In ko, this message translates to:
  /// **'체지방 변화'**
  String get bodyFatChange;

  /// Pose label
  ///
  /// In ko, this message translates to:
  /// **'포즈'**
  String get poseLabel;

  /// Body weight label
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get bodyWeightLabel;

  /// Body fat label
  ///
  /// In ko, this message translates to:
  /// **'체지방'**
  String get bodyFatLabel;

  /// Memo label
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoLabel;

  /// Saving indicator
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get saving;

  /// Condition memo hint
  ///
  /// In ko, this message translates to:
  /// **'오늘의 컨디션, 식단 등을 기록해보세요'**
  String get conditionHint;

  /// Steps unit
  ///
  /// In ko, this message translates to:
  /// **'걸음'**
  String get steps;

  /// Today's workout title in workout log
  ///
  /// In ko, this message translates to:
  /// **'오늘의 운동'**
  String get todayWorkoutTitle;

  /// Empty state title for workout log
  ///
  /// In ko, this message translates to:
  /// **'운동을 추가해 보세요!'**
  String get addExercisePrompt;

  /// Empty state subtitle for workout log
  ///
  /// In ko, this message translates to:
  /// **'아래 버튼을 눌러 오늘의 운동을 기록하세요.'**
  String get addExerciseSubtitle;

  /// Workout complete dialog title
  ///
  /// In ko, this message translates to:
  /// **'운동 완료'**
  String get workoutComplete;

  /// Workout complete confirmation
  ///
  /// In ko, this message translates to:
  /// **'오늘의 운동을 완료하시겠습니까?'**
  String get completeWorkoutConfirm;

  /// Exercise search hint
  ///
  /// In ko, this message translates to:
  /// **'운동 검색'**
  String get searchExercise;

  /// All filter label
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// Compound exercise type
  ///
  /// In ko, this message translates to:
  /// **'복합'**
  String get compound;

  /// No search results message
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get noSearchResults;

  /// Total volume label with colon
  ///
  /// In ko, this message translates to:
  /// **'총 볼륨: '**
  String get totalVolumeLabel;

  /// Rest timer label with colon
  ///
  /// In ko, this message translates to:
  /// **'휴식 타이머: '**
  String get restTimerLabel;

  /// Volume label
  ///
  /// In ko, this message translates to:
  /// **'볼륨'**
  String get volumeLabel;

  /// Delete exercise button
  ///
  /// In ko, this message translates to:
  /// **'운동 삭제'**
  String get deleteExercise;

  /// Set column header
  ///
  /// In ko, this message translates to:
  /// **'세트'**
  String get setHeader;

  /// Weight column header
  ///
  /// In ko, this message translates to:
  /// **'무게 (kg)'**
  String get weightKgHeader;

  /// Reps column header
  ///
  /// In ko, this message translates to:
  /// **'횟수'**
  String get repsHeader;

  /// Completed column header
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get completedHeader;

  /// Add set button
  ///
  /// In ko, this message translates to:
  /// **'세트 추가'**
  String get addSet;

  /// Rest label
  ///
  /// In ko, this message translates to:
  /// **'휴식'**
  String get rest;

  /// Workout done celebration title
  ///
  /// In ko, this message translates to:
  /// **'운동 완료!'**
  String get workoutDone;

  /// Great job message
  ///
  /// In ko, this message translates to:
  /// **'오늘도 수고하셨습니다!'**
  String get greatJobToday;

  /// Time ago: just now
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNow;

  /// Minutes ago
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String minutesAgo(int count);

  /// Hours ago
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String hoursAgo(int count);

  /// Days ago
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String daysAgo(int count);

  /// Cannot load data error
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다.'**
  String get cannotLoadData;

  /// Goal with ml amount
  ///
  /// In ko, this message translates to:
  /// **'목표 {amount}ml'**
  String goalWithMl(int amount);

  /// Volume info text
  ///
  /// In ko, this message translates to:
  /// **'볼륨: {value} kg'**
  String volumeInfo(String value);

  /// Login screen title
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// Login screen subtitle
  ///
  /// In ko, this message translates to:
  /// **'건강한 라이프스타일을 시작하세요'**
  String get loginSubtitle;

  /// Email field label
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get emailLabel;

  /// Password field label
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordLabel;

  /// Email field hint
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력하세요'**
  String get emailHint;

  /// Password field hint
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력하세요'**
  String get passwordHint;

  /// Sign in button
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get signIn;

  /// Sign up button
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUp;

  /// Google sign in button
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get signInWithGoogle;

  /// Apple sign in button
  ///
  /// In ko, this message translates to:
  /// **'Apple로 로그인'**
  String get signInWithApple;

  /// Forgot password link
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get forgotPassword;

  /// No account prompt
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get noAccount;

  /// Have account prompt
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요?'**
  String get haveAccount;

  /// Or divider text
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDivider;

  /// Password reset email sent title
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 메일 전송'**
  String get passwordResetSent;

  /// Password reset description
  ///
  /// In ko, this message translates to:
  /// **'입력하신 이메일로 비밀번호 재설정 링크를 보냈습니다.'**
  String get passwordResetDesc;

  /// Auth error: email already in use
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일입니다.'**
  String get authErrorEmailInUse;

  /// Auth error: invalid email
  ///
  /// In ko, this message translates to:
  /// **'유효하지 않은 이메일 형식입니다.'**
  String get authErrorInvalidEmail;

  /// Auth error: weak password
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 너무 약합니다. 6자 이상 입력하세요.'**
  String get authErrorWeakPassword;

  /// Auth error: user not found
  ///
  /// In ko, this message translates to:
  /// **'등록되지 않은 이메일입니다.'**
  String get authErrorUserNotFound;

  /// Auth error: wrong password
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 올바르지 않습니다.'**
  String get authErrorWrongPassword;

  /// Auth error: too many requests
  ///
  /// In ko, this message translates to:
  /// **'너무 많은 요청이 발생했습니다. 잠시 후 다시 시도하세요.'**
  String get authErrorTooManyRequests;

  /// Auth error: user disabled
  ///
  /// In ko, this message translates to:
  /// **'비활성화된 계정입니다.'**
  String get authErrorUserDisabled;

  /// Auth error: cancelled
  ///
  /// In ko, this message translates to:
  /// **'로그인이 취소되었습니다.'**
  String get authErrorCancelled;

  /// Auth error: unknown
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다.'**
  String get authErrorUnknown;

  /// Send reset link button
  ///
  /// In ko, this message translates to:
  /// **'재설정 링크 보내기'**
  String get sendResetLink;

  /// Reset password dialog title
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get resetPasswordTitle;

  /// Reset password dialog description
  ///
  /// In ko, this message translates to:
  /// **'가입한 이메일을 입력하면 비밀번호 재설정 링크를 보내드립니다.'**
  String get resetPasswordDesc;

  /// Not entered status
  ///
  /// In ko, this message translates to:
  /// **'입력 안 됨'**
  String get notEntered;

  /// Take photo with camera button
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get takePhotoCamera;

  /// Select from gallery option
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get selectFromGalleryOption;

  /// Backup feature coming soon message
  ///
  /// In ko, this message translates to:
  /// **'백업 기능은 준비 중입니다.'**
  String get backupComingSoon;

  /// Restore feature coming soon message
  ///
  /// In ko, this message translates to:
  /// **'복원 기능은 준비 중입니다.'**
  String get restoreComingSoon;

  /// All data deleted confirmation message
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터가 삭제되었습니다.'**
  String get allDataDeleted;

  /// Delete all data confirmation dialog
  ///
  /// In ko, this message translates to:
  /// **'모든 운동 기록, 식단 기록, 설정이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?'**
  String get deleteAllDataConfirm;

  /// App name
  ///
  /// In ko, this message translates to:
  /// **'헬스 & 피트니스'**
  String get appName;

  /// Notification time label
  ///
  /// In ko, this message translates to:
  /// **'알림 시간: '**
  String get notificationTimeLabel;

  /// Previous button
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get previous;

  /// Default user name
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get defaultUser;

  /// Date format with month, day, and day of week
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 ({dayOfWeek})'**
  String dateFormatMonthDay(int month, int day, String dayOfWeek);

  /// Monday full name
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// Tuesday full name
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// Wednesday full name
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// Thursday full name
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// Friday full name
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// Saturday full name
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// Sunday full name
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// Bottom nav home tab
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// Bottom nav workout tab
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get navWorkout;

  /// Bottom nav community tab
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get navCommunity;

  /// Bottom nav diet tab
  ///
  /// In ko, this message translates to:
  /// **'식단'**
  String get navDiet;

  /// Bottom nav calendar tab
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navCalendar;

  /// 404 error page title
  ///
  /// In ko, this message translates to:
  /// **'페이지를 찾을 수 없음'**
  String get pageNotFound;

  /// 404 error page message
  ///
  /// In ko, this message translates to:
  /// **'요청한 페이지를 찾을 수 없습니다.'**
  String get requestedPageNotFound;

  /// Go home button on error page
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get goHome;

  /// Height input hint
  ///
  /// In ko, this message translates to:
  /// **'예: 175'**
  String get hintHeight;

  /// Weight input hint
  ///
  /// In ko, this message translates to:
  /// **'예: 70'**
  String get hintWeight;

  /// Year-month format
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String dateFormatYearMonth(String year, String month);

  /// Full date format
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String dateFormatFull(String year, String month, String day);

  /// Privacy policy content placeholder
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침 내용은 준비 중입니다.'**
  String get privacyPolicyContent;

  /// Terms of service content placeholder
  ///
  /// In ko, this message translates to:
  /// **'이용약관 내용은 준비 중입니다.'**
  String get termsOfServiceContent;

  /// Split label: PPL
  ///
  /// In ko, this message translates to:
  /// **'PPL'**
  String get splitLabelPpl;

  /// Split label: upper/lower
  ///
  /// In ko, this message translates to:
  /// **'상하체 분할'**
  String get splitLabelUpperLower;

  /// Split label: full body
  ///
  /// In ko, this message translates to:
  /// **'풀바디'**
  String get splitLabelFullBody;

  /// Split label: custom
  ///
  /// In ko, this message translates to:
  /// **'사용자 정의'**
  String get splitLabelCustom;

  /// PPL template applied snackbar
  ///
  /// In ko, this message translates to:
  /// **'PPL 템플릿이 적용되었습니다.'**
  String get templateAppliedPpl;

  /// Upper/lower template applied snackbar
  ///
  /// In ko, this message translates to:
  /// **'상하체 분할 템플릿이 적용되었습니다.'**
  String get templateAppliedUpperLower;

  /// Full body template applied snackbar
  ///
  /// In ko, this message translates to:
  /// **'풀바디 템플릿이 적용되었습니다.'**
  String get templateAppliedFullBody;

  /// Custom template applied snackbar
  ///
  /// In ko, this message translates to:
  /// **'사용자 정의 템플릿: 직접 계획을 추가해 주세요.'**
  String get templateAppliedCustom;

  /// Plan completed badge
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get planCompleted;

  /// Rest preset: 1 minute
  ///
  /// In ko, this message translates to:
  /// **'1분'**
  String get restOneMinute;

  /// Rest preset: 1 minute 30 seconds
  ///
  /// In ko, this message translates to:
  /// **'1분 30초'**
  String get restOneMinuteHalf;

  /// Rest preset: 2 minutes
  ///
  /// In ko, this message translates to:
  /// **'2분'**
  String get restTwoMinutes;

  /// Rest preset: 3 minutes
  ///
  /// In ko, this message translates to:
  /// **'3분'**
  String get restThreeMinutes;

  /// Empty state: no meals recorded today
  ///
  /// In ko, this message translates to:
  /// **'오늘 기록된 식사가 없습니다'**
  String get noMealsRecorded;

  /// Empty state subtitle: add meal to start tracking
  ///
  /// In ko, this message translates to:
  /// **'식사를 추가하여 영양 관리를 시작하세요'**
  String get addMealToStart;

  /// Macro nutrients section title
  ///
  /// In ko, this message translates to:
  /// **'매크로 영양소'**
  String get macroNutrients;

  /// No meal record label
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get noMealRecord;

  /// Food count and calories summary
  ///
  /// In ko, this message translates to:
  /// **'{count}개 음식 · {calories} kcal'**
  String foodCountCalories(int count, String calories);

  /// Add meal of type label
  ///
  /// In ko, this message translates to:
  /// **'{mealType} 추가'**
  String addMealTypeLabel(String mealType);

  /// No record for meal type
  ///
  /// In ko, this message translates to:
  /// **'{mealType} 기록이 없습니다'**
  String noMealTypeRecord(String mealType);

  /// Meal food count and calories
  ///
  /// In ko, this message translates to:
  /// **'{count}개 음식 · {calories} kcal'**
  String mealFoodCountCalories(int count, String calories);

  /// Prompt to add food to meal
  ///
  /// In ko, this message translates to:
  /// **'음식을 추가해 주세요'**
  String get addFoodPrompt;

  /// Add food sheet title
  ///
  /// In ko, this message translates to:
  /// **'음식 추가'**
  String get addFood;

  /// Search food hint text
  ///
  /// In ko, this message translates to:
  /// **'음식 이름 검색'**
  String get searchFoodHint;

  /// Serving reference info
  ///
  /// In ko, this message translates to:
  /// **'기준 1회 {size}{unit} · {calories} kcal'**
  String servingReference(String size, String unit, String calories);

  /// Recent foods section label
  ///
  /// In ko, this message translates to:
  /// **'최근 음식'**
  String get recentFoods;

  /// Frequent foods section label
  ///
  /// In ko, this message translates to:
  /// **'자주 먹는 음식'**
  String get frequentFoods;

  /// Search result count label
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 ({count})'**
  String searchResultCount(int count);

  /// No food search results
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get noSearchResultsFood;

  /// Confirm add button
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get confirmAdd;

  /// Tooltip for search icon button
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get tooltipSearch;

  /// Tooltip for notifications icon button
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get tooltipNotifications;

  /// Tooltip for calendar icon button
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get tooltipCalendar;

  /// Tooltip for more options icon button
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get tooltipMoreOptions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
