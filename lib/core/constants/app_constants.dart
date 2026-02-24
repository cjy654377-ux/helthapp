// 앱 전역 상수 정의
// 하드코딩된 목표값과 기본값을 중앙 관리

/// 앱 기본 목표값 상수
class AppDefaults {
  // 수분 섭취
  static const int dailyWaterGoalMl = 2000;
  static const List<int> defaultReminderHours = [9, 12, 15, 18, 21];

  // 식단
  static const int dailyCalorieGoal = 2000;
  static const double proteinRatio = 0.30;
  static const double carbsRatio = 0.50;
  static const double fatRatio = 0.20;

  // 운동
  static const int defaultRestTimerSeconds = 90;
  static const int weeklyWorkoutGoal = 3;

  // 온보딩 기본값
  static const double defaultHeight = 170.0;
  static const double defaultWeight = 70.0;

  AppDefaults._();
}
