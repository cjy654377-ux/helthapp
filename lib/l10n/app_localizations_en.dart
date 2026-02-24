// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Health & Fitness';

  @override
  String greeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get healthyDay => 'Have a healthy day!';

  @override
  String get headingToGoal => 'Heading towards your goal!';

  @override
  String get todayWorkout => 'Today\'s Workout';

  @override
  String get completedExercises => 'Completed exercises';

  @override
  String get totalVolume => 'Total volume';

  @override
  String get hydrationIntake => 'Hydration';

  @override
  String get calorieIntake => 'Calorie intake';

  @override
  String get goal => 'Goal';

  @override
  String get consumed => 'Consumed';

  @override
  String get remaining => 'Remaining';

  @override
  String get exceeded => 'Exceeded';

  @override
  String get kcal => 'kcal';

  @override
  String get upcomingWorkout => 'Upcoming Workout';

  @override
  String get noWorkoutPlan => 'No workout plan';

  @override
  String get quickStart => 'Quick Start';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get logDiet => 'Log Diet';

  @override
  String get drinkWater => 'Drink Water';

  @override
  String get workoutGuide => 'Workout Guide';

  @override
  String get chest => 'Chest';

  @override
  String get back => 'Back';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get arms => 'Arms';

  @override
  String get legs => 'Legs';

  @override
  String get core => 'Core';

  @override
  String exerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String bodyPartExercises(String bodyPart) {
    return '$bodyPart Exercises';
  }

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get equipment => 'Equipment';

  @override
  String get description => 'Description';

  @override
  String get tips => 'Tips';

  @override
  String get workoutLog => 'Workout Log';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get set => 'Set';

  @override
  String get kg => 'kg';

  @override
  String get reps => 'reps';

  @override
  String get complete => 'Complete';

  @override
  String get restTime => 'Rest Time';

  @override
  String get dietManagement => 'Diet Management';

  @override
  String get todayCalories => 'Today\'s Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snack => 'Snack';

  @override
  String get hydration => 'Hydration';

  @override
  String get intakeAmount => 'Intake';

  @override
  String get todayIntakeLog => 'Today\'s Intake Log';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get custom => 'Custom';

  @override
  String get customInput => 'Custom Input';

  @override
  String get intakeAmountMl => 'Amount (ml)';

  @override
  String get add => 'Add';

  @override
  String get noRecordYet => 'No records yet.';

  @override
  String get weeklyHydration => 'Weekly Hydration';

  @override
  String get achievementRate => 'Achievement';

  @override
  String get workoutCalendar => 'Workout Calendar';

  @override
  String get addPlan => 'Add Plan';

  @override
  String addPlanForDate(int month, int day) {
    return 'Add workout plan for $month/$day';
  }

  @override
  String get exerciseName => 'Exercise Name';

  @override
  String get exerciseNameHint => 'e.g. Chest & Tricep workout';

  @override
  String get bodyParts => 'Body Parts';

  @override
  String get splitTemplate => 'Split Template';

  @override
  String get addPlanAction => 'Add';

  @override
  String get addWorkoutPlanSubtitle => 'Add a workout plan for this date';

  @override
  String get teamCommunity => 'Team Community';

  @override
  String get myTeams => 'My Teams';

  @override
  String get teamFeed => 'Team Feed';

  @override
  String get createTeam => 'Create Team';

  @override
  String get createNewTeam => 'Create New Team';

  @override
  String get teamNameHint => 'Enter team name';

  @override
  String get teamDescHint => 'Team description (optional)';

  @override
  String get createTeamAction => 'Create Team';

  @override
  String get joinTeam => 'Join Team';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get writeFirstPost => 'Write the first post';

  @override
  String get noTeamsYet => 'No teams yet';

  @override
  String get joinOrCreateTeam => 'Join a team or create a new one';

  @override
  String get statsAndProgress => 'Stats & Progress';

  @override
  String get workoutStats => 'Workout Stats';

  @override
  String get bodyComposition => 'Body Composition';

  @override
  String get nutritionStats => 'Nutrition Stats';

  @override
  String get streakAndAchievements => 'Streaks & Achievements';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get myRecord => 'My Record';

  @override
  String get totalWorkoutDays => 'Total workout days';

  @override
  String get consecutiveStreak => 'Consecutive streak';

  @override
  String get weightChange => 'Weight Change';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data available';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get setHydrationReminder => 'Set hydration reminders.';

  @override
  String get everyOneHour => 'Every hour';

  @override
  String get everyTwoHours => 'Every 2 hours';

  @override
  String get everyThreeHours => 'Every 3 hours';

  @override
  String reminderSet(String interval) {
    return '$interval reminder has been set.';
  }

  @override
  String get challenge => 'Challenge';

  @override
  String get user => 'User';

  @override
  String get today => 'Today';

  @override
  String get personalInfoEdit => 'Edit Personal Info';

  @override
  String get targetWeightSetting => 'Target Weight';

  @override
  String get shareWithFriends => 'Share with Friends';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get logout => 'Log Out';

  @override
  String startedWorkoutOn(String date) {
    return 'Working out since $date';
  }

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get noWorkoutData => 'No workout data';

  @override
  String get startWorkoutForStats => 'Start a workout to see stats here';

  @override
  String get weeklyWorkoutDays => 'Weekly Workout Days';

  @override
  String get days => 'days';

  @override
  String get monthlyTotalVolume => 'Monthly Total Volume';

  @override
  String get muscleGroupRatio => 'Muscle Group Ratio';

  @override
  String get topExercises => 'Top 5 Exercises';

  @override
  String get times => 'times';

  @override
  String get noWeightData => 'No weight data';

  @override
  String get recordWeightForStats => 'Record your weight to track changes';

  @override
  String get addWeightRecord => 'Add Weight Record';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get bodyFatPercent => 'Body fat (%)';

  @override
  String get muscleMassKg => 'Muscle mass (kg)';

  @override
  String get bodyCompSummary => 'Body Composition Summary';

  @override
  String get currentWeight => 'Current Weight';

  @override
  String get goalAchievement => 'Goal Achievement';

  @override
  String get noNutritionData => 'No nutrition data';

  @override
  String get recordDietForStats => 'Log your diet to see nutrition stats';

  @override
  String get weeklyCalorieIntake => 'Weekly Calorie Intake';

  @override
  String get todayMacroRatio => 'Today\'s Macro Ratio';

  @override
  String get hydrationAchievementRate => 'Hydration Achievement Rate';

  @override
  String get currentConsecutiveDays => 'Current Streak';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String get overallAchievementRate => 'Overall Achievement Rate';

  @override
  String get avgWorkoutTime => 'Avg Workout Time';

  @override
  String get minutes => 'min';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get nickname => 'Nickname';

  @override
  String get noNickname => 'No nickname';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get cm => 'cm';

  @override
  String get workoutSettings => 'Workout Settings';

  @override
  String get defaultRestTime => 'Default Rest Time';

  @override
  String get weightUnit => 'Weight Unit';

  @override
  String get defaultSplit => 'Default Split';

  @override
  String get workoutReminder => 'Workout Reminder';

  @override
  String get hydrationReminder => 'Hydration Reminder';

  @override
  String get mealReminder => 'Meal Reminder';

  @override
  String get breakfastLunchDinnerReminder => 'Breakfast/Lunch/Dinner reminder';

  @override
  String get appSettings => 'App Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemMode => 'System';

  @override
  String get lightMode => 'Light';

  @override
  String get darkModeOption => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get backupData => 'Backup Data';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get misc => 'Misc';

  @override
  String get appVersion => 'App Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get seconds => 'sec';

  @override
  String secondsUnit(int count) {
    return '${count}s';
  }

  @override
  String minutesUnit(int count) {
    return '${count}min';
  }

  @override
  String get skip => 'Skip';

  @override
  String get yourHealthPartner => 'Your Health Partner';

  @override
  String get allInOneApp => 'Workout, diet, and community all in one app';

  @override
  String get getStarted => 'Get Started';

  @override
  String get basicInfoInput => 'Basic Info';

  @override
  String get tellUsAboutYou =>
      'Tell us about yourself for personalized health recommendations.';

  @override
  String get nicknameHint => 'Enter your nickname';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get weightKgField => 'Weight (kg)';

  @override
  String get next => 'Next';

  @override
  String get goalSetting => 'Goal Setting';

  @override
  String get setGoalsForYou =>
      'Set your goals for personalized recommendations.';

  @override
  String get fitnessLevel => 'Fitness Level';

  @override
  String get beginnerLevel => 'Beginner';

  @override
  String get intermediateLevel => 'Intermediate';

  @override
  String get advancedLevel => 'Advanced';

  @override
  String get mainGoal => 'Main Goal';

  @override
  String get strengthGain => 'Strength Gain';

  @override
  String get weightLoss => 'Weight Loss';

  @override
  String get enduranceImprove => 'Endurance';

  @override
  String get flexibilityImprove => 'Flexibility';

  @override
  String get healthMaintain => 'Health Maintenance';

  @override
  String get weeklyWorkoutGoal => 'Weekly Workout Goal';

  @override
  String get timesPerWeek => 'times/week';

  @override
  String get dailyCalorieGoal => 'Daily Calorie Goal';

  @override
  String get dailyWaterGoal => 'Daily Water Goal';

  @override
  String get ml => 'ml';

  @override
  String get allReady => 'All Set!';

  @override
  String get allSetMessage =>
      'Setup complete.\nStart your healthy lifestyle now!';

  @override
  String get startNow => 'Start Now';

  @override
  String get healthyLifestyleStart => 'Start your healthy lifestyle';

  @override
  String get loading => 'Loading...';

  @override
  String get participating => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get discover => 'Discover';

  @override
  String get createChallenge => 'Create Challenge';

  @override
  String get noChallengesYet => 'No active challenges';

  @override
  String get findChallengeToJoin => 'Find a new challenge to join!';

  @override
  String get noCompletedChallenges => 'No completed challenges';

  @override
  String get completeChallengesForBadges =>
      'Complete challenges to earn badges!';

  @override
  String get personalChallenge => 'Personal';

  @override
  String get teamChallenge => 'Team';

  @override
  String get addProgress => 'Add Progress';

  @override
  String get leaveChallenge => 'Leave Challenge';

  @override
  String get dueToday => 'Due today';

  @override
  String daysLeft(int count) {
    return '$count days left';
  }

  @override
  String participants(int count) {
    return '$count participants';
  }

  @override
  String get challengeName => 'Challenge Name';

  @override
  String get challengeNameHint => 'e.g. 30-day Squat Challenge';

  @override
  String get challengeDescription => 'Description';

  @override
  String get challengeDescHint => 'Describe your challenge';

  @override
  String get challengeType => 'Challenge Type';

  @override
  String get targetValue => 'Target Value';

  @override
  String get duration => 'Duration';

  @override
  String get oneWeek => '1 week';

  @override
  String get twoWeeks => '2 weeks';

  @override
  String get oneMonth => '1 month';

  @override
  String get scope => 'Scope';

  @override
  String get startChallenge => 'Start Challenge';

  @override
  String get joinChallenge => 'Join';

  @override
  String get bodyProgress => 'Body Progress';

  @override
  String get photoGallery => 'Gallery';

  @override
  String get beforeAfter => 'Before/After';

  @override
  String get timeline => 'Timeline';

  @override
  String get front => 'Front';

  @override
  String get side => 'Side';

  @override
  String get backPose => 'Back';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get deletePhotoConfirm => 'Delete this photo?';

  @override
  String get overlayCompare => 'Overlay Compare';

  @override
  String get changeSummary => 'Change Summary';

  @override
  String get addProgressPhoto => 'Add Progress Photo';

  @override
  String get selectPose => 'Select Pose';

  @override
  String get weightOptional => 'Weight (optional)';

  @override
  String get bodyFatOptional => 'Body fat % (optional)';

  @override
  String get memoOptional => 'Memo (optional)';

  @override
  String get pleaseAddPhoto => 'Please add a photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get addFirstPhoto => 'Add your first progress photo';

  @override
  String get needTwoPhotos => 'Need at least 2 photos to compare';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get timerDone => 'Done!';

  @override
  String get inProgress => 'In Progress';

  @override
  String get paused => 'Paused';

  @override
  String get minus15sec => '-15s';

  @override
  String get plus15sec => '+15s';

  @override
  String get reset => 'Reset';

  @override
  String get start => 'Start';

  @override
  String get skipTimer => 'Skip';

  @override
  String get nextSet => 'Next set:';

  @override
  String get previousSet => 'Previous set:';

  @override
  String get presetTimes => 'Presets';

  @override
  String get totalVolumeKg => 'Total Volume';

  @override
  String get beforeAfterPhoto => 'Before / After';

  @override
  String get workoutStatsMenu => 'Workout Stats';

  @override
  String get noWeightRecords => 'No weight records';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get soloChallenge => 'Challenge yourself solo';

  @override
  String get teamChallengeSubtitle => 'Challenge with your team';

  @override
  String get allChallengesJoined => 'You\'ve joined all challenges!';

  @override
  String get createCustomChallenge =>
      'Create a custom challenge using the button above.';

  @override
  String leaveConfirmMessage(String title) {
    return 'Leave \'$title\'?';
  }

  @override
  String get addValueLabel => 'Value to add';

  @override
  String get achieved => 'Achieved';

  @override
  String get periodEnded => 'Period ended';

  @override
  String percentAchievedEnd(String date) {
    return '% achieved · Ended $date';
  }

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String goalWithValue(String value, String unit) {
    return 'Goal: $value $unit';
  }

  @override
  String challengeJoinedMessage(String title) {
    return 'Joined \'$title\' challenge!';
  }

  @override
  String get enterNameValidation => 'Please enter a name';

  @override
  String get enterTargetValidation => 'Please enter a target value';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get endDateLabel => 'End date';

  @override
  String get endDateMustBeAfterStart => 'End date must be after start date.';

  @override
  String challengeCreatedMessage(String title) {
    return '\'$title\' challenge created!';
  }

  @override
  String get selectDate => 'Select date';

  @override
  String get slideToCompare => 'Slide to compare';

  @override
  String get selectAbove => 'Select above';

  @override
  String get bodyFatChange => 'Body fat change';

  @override
  String get poseLabel => 'Pose';

  @override
  String get bodyWeightLabel => 'Weight';

  @override
  String get bodyFatLabel => 'Body fat';

  @override
  String get memoLabel => 'Memo';

  @override
  String get saving => 'Saving...';

  @override
  String get conditionHint => 'Record your condition, diet, etc.';

  @override
  String get steps => 'steps';

  @override
  String get todayWorkoutTitle => 'Today\'s Workout';

  @override
  String get addExercisePrompt => 'Add an exercise!';

  @override
  String get addExerciseSubtitle =>
      'Press the button below to log today\'s workout.';

  @override
  String get workoutComplete => 'Workout Complete';

  @override
  String get completeWorkoutConfirm => 'Complete today\'s workout?';

  @override
  String get searchExercise => 'Search exercise';

  @override
  String get all => 'All';

  @override
  String get compound => 'Compound';

  @override
  String get noSearchResults => 'No search results.';

  @override
  String get totalVolumeLabel => 'Total volume: ';

  @override
  String get restTimerLabel => 'Rest timer: ';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get deleteExercise => 'Delete Exercise';

  @override
  String get setHeader => 'Set';

  @override
  String get weightKgHeader => 'Weight (kg)';

  @override
  String get repsHeader => 'Reps';

  @override
  String get completedHeader => 'Done';

  @override
  String get addSet => 'Add Set';

  @override
  String get rest => 'Rest';

  @override
  String get workoutDone => 'Workout Complete!';

  @override
  String get greatJobToday => 'Great job today!';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get cannotLoadData => 'Cannot load data.';

  @override
  String goalWithMl(int amount) {
    return 'Goal ${amount}ml';
  }

  @override
  String volumeInfo(String value) {
    return 'Volume: $value kg';
  }

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Start your healthy lifestyle';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get orDivider => 'or';

  @override
  String get passwordResetSent => 'Password Reset Email Sent';

  @override
  String get passwordResetDesc =>
      'We\'ve sent a password reset link to the email you provided.';

  @override
  String get authErrorEmailInUse => 'This email is already in use.';

  @override
  String get authErrorInvalidEmail => 'Invalid email format.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorTooManyRequests =>
      'Too many requests. Please try again later.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorCancelled => 'Sign in was cancelled.';

  @override
  String get authErrorUnknown => 'An unknown error occurred.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordDesc =>
      'Enter your email and we\'ll send you a password reset link.';
}
