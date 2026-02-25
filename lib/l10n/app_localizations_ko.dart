// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '헬스 & 피트니스';

  @override
  String greeting(String name) {
    return '안녕하세요, $name님!';
  }

  @override
  String get healthyDay => '오늘도 건강한 하루!';

  @override
  String get headingToGoal => '목표를 향해 나아가는 중!';

  @override
  String get todayWorkout => '오늘의 운동';

  @override
  String get completedExercises => '완료한 운동';

  @override
  String get totalVolume => '총 볼륨';

  @override
  String get hydrationIntake => '수분 섭취';

  @override
  String get calorieIntake => '칼로리 섭취';

  @override
  String get goal => '목표';

  @override
  String get consumed => '섭취';

  @override
  String get remaining => '남은';

  @override
  String get exceeded => '초과';

  @override
  String get kcal => 'kcal';

  @override
  String get upcomingWorkout => '다음 예정 운동';

  @override
  String get noWorkoutPlan => '운동 계획이 없습니다';

  @override
  String get quickStart => '빠른 실행';

  @override
  String get startWorkout => '운동 시작';

  @override
  String get logDiet => '식단 기록';

  @override
  String get drinkWater => '물 마시기';

  @override
  String get workoutGuide => '운동 가이드';

  @override
  String get chest => '가슴';

  @override
  String get back => '등';

  @override
  String get shoulders => '어깨';

  @override
  String get arms => '팔';

  @override
  String get legs => '하체';

  @override
  String get core => '코어';

  @override
  String exerciseCount(int count) {
    return '$count개 운동';
  }

  @override
  String bodyPartExercises(String bodyPart) {
    return '$bodyPart 운동';
  }

  @override
  String get beginner => '초급';

  @override
  String get intermediate => '중급';

  @override
  String get advanced => '고급';

  @override
  String get equipment => '사용 기구';

  @override
  String get description => '설명';

  @override
  String get tips => '팁';

  @override
  String get workoutLog => '운동 기록';

  @override
  String get addExercise => '운동 추가';

  @override
  String get set => '세트';

  @override
  String get kg => 'kg';

  @override
  String get reps => '회';

  @override
  String get complete => '완료';

  @override
  String get restTime => '휴식 시간';

  @override
  String get dietManagement => '식단 관리';

  @override
  String get todayCalories => '오늘의 칼로리';

  @override
  String get protein => '단백질';

  @override
  String get carbs => '탄수화물';

  @override
  String get fat => '지방';

  @override
  String get breakfast => '아침';

  @override
  String get lunch => '점심';

  @override
  String get dinner => '저녁';

  @override
  String get snack => '간식';

  @override
  String get hydration => '수분 보충';

  @override
  String get intakeAmount => '섭취량';

  @override
  String get todayIntakeLog => '오늘 섭취 기록';

  @override
  String get quickAdd => '빠른 추가';

  @override
  String get custom => '직접';

  @override
  String get customInput => '직접 입력';

  @override
  String get intakeAmountMl => '섭취량 (ml)';

  @override
  String get add => '추가';

  @override
  String get noRecordYet => '아직 기록이 없습니다.';

  @override
  String get weeklyHydration => '주간 수분 섭취';

  @override
  String get achievementRate => '달성률';

  @override
  String get workoutCalendar => '운동 캘린더';

  @override
  String get addPlan => '계획 추가';

  @override
  String addPlanForDate(int month, int day) {
    return '$month월 $day일 운동 계획 추가';
  }

  @override
  String get exerciseName => '운동 이름';

  @override
  String get exerciseNameHint => '예: 가슴 & 삼두 운동';

  @override
  String get bodyParts => '신체 부위';

  @override
  String get splitTemplate => '스플릿 템플릿';

  @override
  String get addPlanAction => '추가하기';

  @override
  String get addWorkoutPlanSubtitle => '이 날짜에 운동 계획을 추가해보세요';

  @override
  String get teamCommunity => '팀 커뮤니티';

  @override
  String get myTeams => '내 팀';

  @override
  String get teamFeed => '팀 피드';

  @override
  String get createTeam => '팀 만들기';

  @override
  String get createNewTeam => '새 팀 만들기';

  @override
  String get teamNameHint => '팀 이름을 입력하세요';

  @override
  String get teamDescHint => '팀 설명 (선택)';

  @override
  String get createTeamAction => '팀 생성';

  @override
  String get joinTeam => '팀 가입';

  @override
  String get noPostsYet => '아직 게시물이 없습니다';

  @override
  String get writeFirstPost => '첫 번째 게시물을 작성해보세요';

  @override
  String get noTeamsYet => '아직 팀이 없습니다';

  @override
  String get joinOrCreateTeam => '팀에 참여하거나 새 팀을 만들어보세요';

  @override
  String get statsAndProgress => '통계 & 진척도';

  @override
  String get workoutStats => '운동 통계';

  @override
  String get bodyComposition => '체성분 변화';

  @override
  String get nutritionStats => '영양 통계';

  @override
  String get streakAndAchievements => '스트릭 & 업적';

  @override
  String get profile => '프로필';

  @override
  String get settings => '설정';

  @override
  String get myRecord => '내 기록';

  @override
  String get totalWorkoutDays => '총 운동일';

  @override
  String get consecutiveStreak => '연속 스트릭';

  @override
  String get weightChange => '체중 변화';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get confirm => '확인';

  @override
  String get delete => '삭제';

  @override
  String get close => '닫기';

  @override
  String get retry => '다시 시도';

  @override
  String get noData => '데이터가 없습니다';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get setHydrationReminder => '수분 섭취 알림을 설정하세요.';

  @override
  String get everyOneHour => '1시간마다';

  @override
  String get everyTwoHours => '2시간마다';

  @override
  String get everyThreeHours => '3시간마다';

  @override
  String reminderSet(String interval) {
    return '$interval 알림이 설정되었습니다.';
  }

  @override
  String get challenge => '챌린지';

  @override
  String get user => '사용자';

  @override
  String get today => '오늘';

  @override
  String get personalInfoEdit => '개인 정보 수정';

  @override
  String get targetWeightSetting => '목표 체중 설정';

  @override
  String get shareWithFriends => '친구에게 공유';

  @override
  String get privacyPolicy => '개인 정보 보호 정책';

  @override
  String get helpAndSupport => '도움말 및 지원';

  @override
  String get logout => '로그아웃';

  @override
  String startedWorkoutOn(String date) {
    return '$date부터 운동 시작';
  }

  @override
  String get tapToAdd => '탭하여 추가';

  @override
  String get addPhoto => '사진 추가';

  @override
  String get noWorkoutData => '운동 기록이 없습니다';

  @override
  String get startWorkoutForStats => '운동을 시작하면 여기에 통계가 표시됩니다';

  @override
  String get weeklyWorkoutDays => '주간 운동 일수';

  @override
  String get days => '일';

  @override
  String get monthlyTotalVolume => '월간 총 볼륨';

  @override
  String get muscleGroupRatio => '부위별 운동 비율';

  @override
  String get topExercises => '가장 많이 한 운동 Top 5';

  @override
  String get times => '회';

  @override
  String get noWeightData => '체중 기록이 없습니다';

  @override
  String get recordWeightForStats => '체중을 기록하면 변화 추이를 확인할 수 있습니다';

  @override
  String get addWeightRecord => '체중 기록 추가';

  @override
  String get weightKg => '체중 (kg)';

  @override
  String get bodyFatPercent => '체지방률 (%)';

  @override
  String get muscleMassKg => '골격근량 (kg)';

  @override
  String get bodyCompSummary => '체성분 요약';

  @override
  String get currentWeight => '현재 체중';

  @override
  String get goalAchievement => '목표 달성률';

  @override
  String get noNutritionData => '영양 기록이 없습니다';

  @override
  String get recordDietForStats => '식단을 기록하면 영양 통계를 확인할 수 있습니다';

  @override
  String get weeklyCalorieIntake => '주간 칼로리 섭취';

  @override
  String get todayMacroRatio => '오늘 매크로 비율';

  @override
  String get hydrationAchievementRate => '수분 섭취 달성률';

  @override
  String get currentConsecutiveDays => '현재 연속 운동일';

  @override
  String get longestStreak => '최장 스트릭 기록';

  @override
  String get overallAchievementRate => '전체 업적 달성률';

  @override
  String get avgWorkoutTime => '평균 운동 시간';

  @override
  String get minutes => '분';

  @override
  String get mon => '월';

  @override
  String get tue => '화';

  @override
  String get wed => '수';

  @override
  String get thu => '목';

  @override
  String get fri => '금';

  @override
  String get sat => '토';

  @override
  String get sun => '일';

  @override
  String get jan => '1월';

  @override
  String get feb => '2월';

  @override
  String get mar => '3월';

  @override
  String get apr => '4월';

  @override
  String get may => '5월';

  @override
  String get jun => '6월';

  @override
  String get jul => '7월';

  @override
  String get aug => '8월';

  @override
  String get sep => '9월';

  @override
  String get oct => '10월';

  @override
  String get nov => '11월';

  @override
  String get dec => '12월';

  @override
  String get profilePhoto => '프로필 사진';

  @override
  String get tapToChange => '탭하여 변경';

  @override
  String get nickname => '닉네임';

  @override
  String get noNickname => '닉네임 없음';

  @override
  String get gender => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get other => '기타';

  @override
  String get height => '키';

  @override
  String get weight => '몸무게';

  @override
  String get cm => 'cm';

  @override
  String get workoutSettings => '운동 설정';

  @override
  String get defaultRestTime => '기본 휴식 시간';

  @override
  String get weightUnit => '무게 단위';

  @override
  String get defaultSplit => '기본 운동 스플릿';

  @override
  String get workoutReminder => '운동 알림';

  @override
  String get hydrationReminder => '수분 알림';

  @override
  String get mealReminder => '식단 알림';

  @override
  String get breakfastLunchDinnerReminder => '아침/점심/저녁 식단 알림';

  @override
  String get appSettings => '앱 설정';

  @override
  String get darkMode => '다크 모드';

  @override
  String get systemMode => '시스템';

  @override
  String get lightMode => '라이트';

  @override
  String get darkModeOption => '다크';

  @override
  String get language => '언어';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get dataManagement => '데이터 관리';

  @override
  String get backupData => '데이터 백업';

  @override
  String get restoreData => '데이터 복원';

  @override
  String get deleteAllData => '모든 데이터 삭제';

  @override
  String get misc => '기타';

  @override
  String get appVersion => '앱 버전';

  @override
  String get termsOfService => '이용약관';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get seconds => '초';

  @override
  String secondsUnit(int count) {
    return '$count초';
  }

  @override
  String minutesUnit(int count) {
    return '$count분';
  }

  @override
  String get skip => '건너뛰기';

  @override
  String get yourHealthPartner => '당신만의 건강 파트너';

  @override
  String get allInOneApp => '운동, 식단, 커뮤니티를 하나의 앱에서';

  @override
  String get getStarted => '시작하기';

  @override
  String get basicInfoInput => '기본 정보 입력';

  @override
  String get tellUsAboutYou => '건강 목표에 맞춤 서비스를 제공하기 위해 기본 정보를 알려주세요.';

  @override
  String get nicknameHint => '닉네임을 입력하세요';

  @override
  String get selectGender => '성별 선택';

  @override
  String get heightCm => '키 (cm)';

  @override
  String get weightKgField => '몸무게 (kg)';

  @override
  String get next => '다음';

  @override
  String get goalSetting => '목표 설정';

  @override
  String get setGoalsForYou => '맞춤 추천을 위해 목표를 설정해주세요.';

  @override
  String get fitnessLevel => '운동 수준';

  @override
  String get beginnerLevel => '초보자';

  @override
  String get intermediateLevel => '중급자';

  @override
  String get advancedLevel => '고급자';

  @override
  String get mainGoal => '주요 목표';

  @override
  String get strengthGain => '근력 증가';

  @override
  String get weightLoss => '체중 감량';

  @override
  String get enduranceImprove => '체력 향상';

  @override
  String get flexibilityImprove => '유연성 향상';

  @override
  String get healthMaintain => '건강 유지';

  @override
  String get weeklyWorkoutGoal => '주간 운동 횟수 목표';

  @override
  String get timesPerWeek => '회/주';

  @override
  String get dailyCalorieGoal => '일일 칼로리 목표';

  @override
  String get dailyWaterGoal => '일일 수분 목표';

  @override
  String get ml => 'ml';

  @override
  String get allReady => '준비 완료!';

  @override
  String get allSetMessage => '모든 설정이 완료되었습니다.\n지금 바로 건강한 라이프스타일을 시작하세요!';

  @override
  String get startNow => '시작하기';

  @override
  String get healthyLifestyleStart => '건강한 라이프스타일의 시작';

  @override
  String get loading => '로딩 중...';

  @override
  String get participating => '참여중';

  @override
  String get completed => '완료';

  @override
  String get discover => '찾기';

  @override
  String get createChallenge => '챌린지 만들기';

  @override
  String get noChallengesYet => '참여 중인 챌린지가 없어요';

  @override
  String get findChallengeToJoin => '새로운 챌린지를 찾아 참여해보세요!';

  @override
  String get noCompletedChallenges => '완료한 챌린지가 없습니다';

  @override
  String get completeChallengesForBadges => '챌린지를 완료하고 뱃지를 모아보세요!';

  @override
  String get personalChallenge => '개인 챌린지';

  @override
  String get teamChallenge => '팀 챌린지';

  @override
  String get addProgress => '진행상황 추가';

  @override
  String get leaveChallenge => '챌린지 탈퇴';

  @override
  String get dueToday => '오늘 마감';

  @override
  String daysLeft(int count) {
    return '$count일 남음';
  }

  @override
  String participants(int count) {
    return '$count명 참가';
  }

  @override
  String get challengeName => '챌린지 이름';

  @override
  String get challengeNameHint => '예: 30일 스쿼트 챌린지';

  @override
  String get challengeDescription => '챌린지 설명';

  @override
  String get challengeDescHint => '챌린지에 대한 설명을 입력하세요';

  @override
  String get challengeType => '챌린지 유형';

  @override
  String get targetValue => '목표값';

  @override
  String get duration => '기간';

  @override
  String get oneWeek => '1주';

  @override
  String get twoWeeks => '2주';

  @override
  String get oneMonth => '1개월';

  @override
  String get scope => '범위';

  @override
  String get startChallenge => '챌린지 시작하기';

  @override
  String get joinChallenge => '참여하기';

  @override
  String get bodyProgress => '바디 프로그레스';

  @override
  String get photoGallery => '사진 갤러리';

  @override
  String get beforeAfter => 'Before/After';

  @override
  String get timeline => '타임라인';

  @override
  String get front => '앞모습';

  @override
  String get side => '옆모습';

  @override
  String get backPose => '뒷모습';

  @override
  String get deletePhoto => '사진 삭제';

  @override
  String get deletePhotoConfirm => '이 사진을 삭제하시겠습니까?';

  @override
  String get overlayCompare => '오버레이 비교';

  @override
  String get changeSummary => '변화 요약';

  @override
  String get addProgressPhoto => '진행 사진 추가';

  @override
  String get selectPose => '포즈 선택';

  @override
  String get weightOptional => '체중 (선택)';

  @override
  String get bodyFatOptional => '체지방률 (선택)';

  @override
  String get memoOptional => '메모 (선택)';

  @override
  String get pleaseAddPhoto => '사진을 추가해주세요';

  @override
  String get selectFromGallery => '갤러리에서 선택';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get noPhotosYet => '사진이 없습니다';

  @override
  String get addFirstPhoto => '첫 번째 진행 사진을 추가해보세요';

  @override
  String get needTwoPhotos => '비교하려면 2장 이상의 사진이 필요합니다';

  @override
  String get restTimer => '휴식 타이머';

  @override
  String get timerDone => '완료!';

  @override
  String get inProgress => '진행 중';

  @override
  String get paused => '일시정지';

  @override
  String get minus15sec => '-15초';

  @override
  String get plus15sec => '+15초';

  @override
  String get reset => '리셋';

  @override
  String get start => '시작';

  @override
  String get skipTimer => '건너뛰기';

  @override
  String get nextSet => '다음 세트:';

  @override
  String get previousSet => '이전 세트:';

  @override
  String get presetTimes => '프리셋';

  @override
  String get totalVolumeKg => '총 볼륨';

  @override
  String get beforeAfterPhoto => 'Before / After';

  @override
  String get workoutStatsMenu => '운동 통계';

  @override
  String get noWeightRecords => '체중 기록이 없습니다';

  @override
  String get editNickname => '닉네임 수정';

  @override
  String get enterNickname => '닉네임을 입력하세요';

  @override
  String get soloChallenge => '나 혼자 도전하는 챌린지';

  @override
  String get teamChallengeSubtitle => '팀원과 함께 도전하는 챌린지';

  @override
  String get allChallengesJoined => '모든 챌린지에 참여 중입니다!';

  @override
  String get createCustomChallenge => '위 버튼으로 커스텀 챌린지를 만들어 보세요.';

  @override
  String leaveConfirmMessage(String title) {
    return '\'$title\'에서 탈퇴하시겠습니까?';
  }

  @override
  String get addValueLabel => '추가할 값';

  @override
  String get achieved => '달성';

  @override
  String get periodEnded => '기간 종료';

  @override
  String percentAchievedEnd(String date) {
    return '% 달성 · $date 종료';
  }

  @override
  String daysCount(int count) {
    return '$count일';
  }

  @override
  String goalWithValue(String value, String unit) {
    return '목표: $value $unit';
  }

  @override
  String challengeJoinedMessage(String title) {
    return '\'$title\' 챌린지에 참가했습니다!';
  }

  @override
  String get enterNameValidation => '이름을 입력하세요';

  @override
  String get enterTargetValidation => '목표값을 입력하세요';

  @override
  String get enterValidNumber => '유효한 숫자를 입력하세요';

  @override
  String get startDateLabel => '시작일';

  @override
  String get endDateLabel => '종료일';

  @override
  String get endDateMustBeAfterStart => '종료일은 시작일 이후여야 합니다.';

  @override
  String challengeCreatedMessage(String title) {
    return '\'$title\' 챌린지가 생성되었습니다!';
  }

  @override
  String get selectDate => '날짜 선택';

  @override
  String get slideToCompare => '슬라이더를 움직여 비교';

  @override
  String get selectAbove => '위에서 선택하세요';

  @override
  String get bodyFatChange => '체지방 변화';

  @override
  String get poseLabel => '포즈';

  @override
  String get bodyWeightLabel => '체중';

  @override
  String get bodyFatLabel => '체지방';

  @override
  String get memoLabel => '메모';

  @override
  String get saving => '저장 중...';

  @override
  String get conditionHint => '오늘의 컨디션, 식단 등을 기록해보세요';

  @override
  String get steps => '걸음';

  @override
  String get todayWorkoutTitle => '오늘의 운동';

  @override
  String get addExercisePrompt => '운동을 추가해 보세요!';

  @override
  String get addExerciseSubtitle => '아래 버튼을 눌러 오늘의 운동을 기록하세요.';

  @override
  String get workoutComplete => '운동 완료';

  @override
  String get completeWorkoutConfirm => '오늘의 운동을 완료하시겠습니까?';

  @override
  String get searchExercise => '운동 검색';

  @override
  String get all => '전체';

  @override
  String get compound => '복합';

  @override
  String get noSearchResults => '검색 결과가 없습니다.';

  @override
  String get totalVolumeLabel => '총 볼륨: ';

  @override
  String get restTimerLabel => '휴식 타이머: ';

  @override
  String get volumeLabel => '볼륨';

  @override
  String get deleteExercise => '운동 삭제';

  @override
  String get setHeader => '세트';

  @override
  String get weightKgHeader => '무게 (kg)';

  @override
  String get repsHeader => '횟수';

  @override
  String get completedHeader => '완료';

  @override
  String get addSet => '세트 추가';

  @override
  String get rest => '휴식';

  @override
  String get workoutDone => '운동 완료!';

  @override
  String get greatJobToday => '오늘도 수고하셨습니다!';

  @override
  String get justNow => '방금 전';

  @override
  String minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get cannotLoadData => '데이터를 불러올 수 없습니다.';

  @override
  String goalWithMl(int amount) {
    return '목표 ${amount}ml';
  }

  @override
  String volumeInfo(String value) {
    return '볼륨: $value kg';
  }

  @override
  String get loginTitle => '로그인';

  @override
  String get loginSubtitle => '건강한 라이프스타일을 시작하세요';

  @override
  String get emailLabel => '이메일';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get emailHint => '이메일을 입력하세요';

  @override
  String get passwordHint => '비밀번호를 입력하세요';

  @override
  String get signIn => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get signInWithApple => 'Apple로 로그인';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get haveAccount => '이미 계정이 있으신가요?';

  @override
  String get orDivider => '또는';

  @override
  String get passwordResetSent => '비밀번호 재설정 메일 전송';

  @override
  String get passwordResetDesc => '입력하신 이메일로 비밀번호 재설정 링크를 보냈습니다.';

  @override
  String get authErrorEmailInUse => '이미 사용 중인 이메일입니다.';

  @override
  String get authErrorInvalidEmail => '유효하지 않은 이메일 형식입니다.';

  @override
  String get authErrorWeakPassword => '비밀번호가 너무 약합니다. 6자 이상 입력하세요.';

  @override
  String get authErrorUserNotFound => '등록되지 않은 이메일입니다.';

  @override
  String get authErrorWrongPassword => '비밀번호가 올바르지 않습니다.';

  @override
  String get authErrorTooManyRequests => '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get authErrorUserDisabled => '비활성화된 계정입니다.';

  @override
  String get authErrorCancelled => '로그인이 취소되었습니다.';

  @override
  String get authErrorUnknown => '알 수 없는 오류가 발생했습니다.';

  @override
  String get sendResetLink => '재설정 링크 보내기';

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get resetPasswordDesc => '가입한 이메일을 입력하면 비밀번호 재설정 링크를 보내드립니다.';

  @override
  String get notEntered => '입력 안 됨';

  @override
  String get takePhotoCamera => '카메라로 촬영';

  @override
  String get selectFromGalleryOption => '갤러리에서 선택';

  @override
  String get backupComingSoon => '백업 기능은 준비 중입니다.';

  @override
  String get restoreComingSoon => '복원 기능은 준비 중입니다.';

  @override
  String get allDataDeleted => '모든 데이터가 삭제되었습니다.';

  @override
  String get deleteAllDataConfirm =>
      '모든 운동 기록, 식단 기록, 설정이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?';

  @override
  String get appName => '헬스 & 피트니스';

  @override
  String get notificationTimeLabel => '알림 시간: ';

  @override
  String get previous => '이전';

  @override
  String get defaultUser => '사용자';

  @override
  String dateFormatMonthDay(int month, int day, String dayOfWeek) {
    return '$month월 $day일 ($dayOfWeek)';
  }

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get navHome => '홈';

  @override
  String get navWorkout => '운동';

  @override
  String get navCommunity => '커뮤니티';

  @override
  String get navDiet => '식단';

  @override
  String get navCalendar => '캘린더';

  @override
  String get pageNotFound => '페이지를 찾을 수 없음';

  @override
  String get requestedPageNotFound => '요청한 페이지를 찾을 수 없습니다.';

  @override
  String get goHome => '홈으로 돌아가기';

  @override
  String get hintHeight => '예: 175';

  @override
  String get hintWeight => '예: 70';

  @override
  String dateFormatYearMonth(String year, String month) {
    return '$year년 $month월';
  }

  @override
  String dateFormatFull(String year, String month, String day) {
    return '$year년 $month월 $day일';
  }

  @override
  String get privacyPolicyContent => '개인정보 처리방침 내용은 준비 중입니다.';

  @override
  String get termsOfServiceContent => '이용약관 내용은 준비 중입니다.';

  @override
  String get splitLabelPpl => 'PPL';

  @override
  String get splitLabelUpperLower => '상하체 분할';

  @override
  String get splitLabelFullBody => '풀바디';

  @override
  String get splitLabelCustom => '사용자 정의';

  @override
  String get templateAppliedPpl => 'PPL 템플릿이 적용되었습니다.';

  @override
  String get templateAppliedUpperLower => '상하체 분할 템플릿이 적용되었습니다.';

  @override
  String get templateAppliedFullBody => '풀바디 템플릿이 적용되었습니다.';

  @override
  String get templateAppliedCustom => '사용자 정의 템플릿: 직접 계획을 추가해 주세요.';

  @override
  String get planCompleted => '완료';

  @override
  String get restOneMinute => '1분';

  @override
  String get restOneMinuteHalf => '1분 30초';

  @override
  String get restTwoMinutes => '2분';

  @override
  String get restThreeMinutes => '3분';

  @override
  String get noMealsRecorded => '오늘 기록된 식사가 없습니다';

  @override
  String get addMealToStart => '식사를 추가하여 영양 관리를 시작하세요';

  @override
  String get macroNutrients => '매크로 영양소';

  @override
  String get noMealRecord => '기록 없음';

  @override
  String foodCountCalories(int count, String calories) {
    return '$count개 음식 · $calories kcal';
  }

  @override
  String addMealTypeLabel(String mealType) {
    return '$mealType 추가';
  }

  @override
  String noMealTypeRecord(String mealType) {
    return '$mealType 기록이 없습니다';
  }

  @override
  String mealFoodCountCalories(int count, String calories) {
    return '$count개 음식 · $calories kcal';
  }

  @override
  String get addFoodPrompt => '음식을 추가해 주세요';

  @override
  String get addFood => '음식 추가';

  @override
  String get searchFoodHint => '음식 이름 검색';

  @override
  String servingReference(String size, String unit, String calories) {
    return '기준 1회 $size$unit · $calories kcal';
  }

  @override
  String get recentFoods => '최근 음식';

  @override
  String get frequentFoods => '자주 먹는 음식';

  @override
  String searchResultCount(int count) {
    return '검색 결과 ($count)';
  }

  @override
  String get noSearchResultsFood => '검색 결과가 없습니다';

  @override
  String get confirmAdd => '추가하기';

  @override
  String get tooltipSearch => '검색';

  @override
  String get tooltipNotifications => '알림';

  @override
  String get tooltipCalendar => '캘린더';

  @override
  String get tooltipMoreOptions => '더보기';

  @override
  String achievementsRemaining(int count) {
    return '앞으로 $count개의 업적을 달성해보세요!';
  }

  @override
  String get achievementFirstWorkoutTitle => '첫 운동';

  @override
  String get achievementFirstWorkoutDesc => '첫 번째 운동 기록을 완료했습니다';

  @override
  String get achievementWorkout10Title => '운동 마니아';

  @override
  String get achievementWorkout10Desc => '운동 기록을 10회 완료했습니다';

  @override
  String get achievementWorkout50Title => '헬스 중독자';

  @override
  String get achievementWorkout50Desc => '운동 기록을 50회 완료했습니다';

  @override
  String get achievementWorkout100Title => '운동의 신';

  @override
  String get achievementWorkout100Desc => '운동 기록을 100회 완료했습니다';

  @override
  String get achievementVolume1000Title => '1톤 클럽';

  @override
  String get achievementVolume1000Desc => '한 세션에 총 볼륨 1,000kg을 달성했습니다';

  @override
  String get achievementPrFirstTitle => '새 기록!';

  @override
  String get achievementPrFirstDesc => '첫 개인 최고 기록(PR)을 달성했습니다';

  @override
  String get achievementMorningWarriorTitle => '새벽 전사';

  @override
  String get achievementMorningWarriorDesc => '오전 운동을 10회 완료했습니다';

  @override
  String get achievementVariety10Title => '만능 운동인';

  @override
  String get achievementVariety10Desc => '10가지 이상의 다양한 운동을 수행했습니다';

  @override
  String get achievementStreak3Title => '3일 연속';

  @override
  String get achievementStreak3Desc => '3일 연속으로 운동했습니다';

  @override
  String get achievementStreak7Title => '일주일 연속';

  @override
  String get achievementStreak7Desc => '7일 연속으로 운동했습니다';

  @override
  String get achievementStreak30Title => '한 달 연속';

  @override
  String get achievementStreak30Desc => '30일 연속으로 운동했습니다';

  @override
  String get achievementWaterFirstGoalTitle => '수분 첫 목표!';

  @override
  String get achievementWaterFirstGoalDesc => '처음으로 하루 수분 섭취 목표를 달성했습니다';

  @override
  String get achievementWaterMasterTitle => '수분 마스터';

  @override
  String get achievementWaterMasterDesc => '수분 섭취 목표를 7일 달성했습니다';

  @override
  String get achievementWaterStreak30Title => '수분 왕';

  @override
  String get achievementWaterStreak30Desc => '30일 연속 수분 섭취 목표를 달성했습니다';

  @override
  String get achievementDietFirstLogTitle => '식단 시작';

  @override
  String get achievementDietFirstLogDesc => '첫 번째 식단을 기록했습니다';

  @override
  String get achievementDietStreak7Title => '식단 기록왕';

  @override
  String get achievementDietStreak7Desc => '7일 연속 식단을 기록했습니다';

  @override
  String get achievementTeamJoinTitle => '팀 플레이어';

  @override
  String get achievementTeamJoinDesc => '팀에 가입했습니다';

  @override
  String get achievementSocialButterflyTitle => '소셜 버터플라이';

  @override
  String get achievementSocialButterflyDesc => '팀 활동(게시글/댓글)을 10회 이상 했습니다';

  @override
  String get achievementBodyTransformationTitle => '변신 성공';

  @override
  String get achievementBodyTransformationDesc => '체중 변화 목표를 달성했습니다';

  @override
  String get notifHydrationTitle => '물 마실 시간이에요!';

  @override
  String get notifHydrationBody => '수분 섭취 목표를 달성하기 위해 지금 물을 마셔보세요.';

  @override
  String get notifHydrationChannelName => '수분 섭취 알림';

  @override
  String get notifHydrationChannelDesc => '수분 섭취 리마인더';

  @override
  String get notifWorkoutTitle => '운동 시간이에요!';

  @override
  String notifWorkoutBody(String workoutName) {
    return '오늘의 $workoutName 운동을 시작할 시간입니다.';
  }

  @override
  String get notifWorkoutChannelName => '운동 알림';

  @override
  String get notifWorkoutChannelDesc => '운동 리마인더';

  @override
  String notifMealTitle(String mealLabel) {
    return '$mealLabel 기록 시간이에요!';
  }

  @override
  String notifMealBody(String mealLabel) {
    return '$mealLabel 식단을 기록하고 영양 목표를 확인하세요.';
  }

  @override
  String get notifMealChannelName => '식단 알림';

  @override
  String get notifMealChannelDesc => '식단 기록 리마인더';

  @override
  String get notifRestTitle => '잠깐 휴식을 취하세요!';

  @override
  String get notifRestBody => '오랫동안 앉아 계셨네요. 잠깐 스트레칭을 해보세요.';

  @override
  String get notifGeneralChannelName => '일반 알림';

  @override
  String get notifGeneralChannelDesc => '휴식 및 일반 리마인더';

  @override
  String get mealLabelBreakfast => '아침';

  @override
  String get mealLabelLunch => '점심';

  @override
  String get mealLabelDinner => '저녁';

  @override
  String get mealLabelSnack => '간식';
}
