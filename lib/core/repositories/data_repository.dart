// 데이터 레포지토리 인터페이스 정의
// Provider와 저장소 사이의 추상화 레이어

import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

/// 운동 기록 저장소
abstract class WorkoutRepository {
  /// 전체 운동 기록 로드
  Future<List<WorkoutRecord>> loadHistory();

  /// 단일 운동 기록 저장
  Future<void> saveRecord(WorkoutRecord record);

  /// 전체 운동 기록 일괄 저장
  Future<void> saveAllRecords(List<WorkoutRecord> records);

  /// ID로 운동 기록 삭제
  Future<void> deleteRecord(String id);

  /// 개인 기록(PR) 로드
  Future<List<PersonalRecord>> loadPersonalRecords();

  /// 개인 기록(PR) 저장
  Future<void> savePersonalRecords(List<PersonalRecord> records);
}

/// 식단 저장소
abstract class DietRepository {
  /// 특정 날짜의 식사 로드
  Future<List<Meal>> loadMeals(String dateKey);

  /// 특정 날짜의 식사 저장
  Future<void> saveMeals(String dateKey, List<Meal> meals);

  /// 영양 목표 로드
  Future<NutritionGoal> loadNutritionGoal();

  /// 영양 목표 저장
  Future<void> saveNutritionGoal(NutritionGoal goal);

  /// 최근 사용 식품 ID 로드
  Future<List<String>> loadRecentFoodIds();

  /// 최근 사용 식품 ID 저장
  Future<void> saveRecentFoodIds(List<String> ids);
}

/// 수분 섭취 저장소
abstract class HydrationRepository {
  /// 특정 날짜의 수분 데이터(entries + settings) 로드
  Future<Map<String, dynamic>> loadHydrationData(String dateKey);

  /// 특정 날짜의 수분 데이터 저장
  Future<void> saveHydrationData(String dateKey, Map<String, dynamic> data);

  /// 수분 섭취 설정(목표량 + 알림 시간) 로드
  Future<Map<String, dynamic>> loadHydrationSettings();

  /// 수분 섭취 설정 저장
  Future<void> saveHydrationSettings(Map<String, dynamic> settings);
}

/// 캘린더 운동 계획 저장소
abstract class CalendarRepository {
  /// 전체 운동 계획 맵 로드
  Future<Map<String, List<Map<String, dynamic>>>> loadAllPlans();

  /// 전체 운동 계획 맵 저장
  Future<void> saveAllPlans(Map<String, List<Map<String, dynamic>>> plans);
}

/// 커뮤니티 저장소
abstract class CommunityRepository {
  /// 현재 사용자 프로필 로드
  Future<UserProfile?> loadCurrentUser();

  /// 사용자 프로필 저장
  Future<void> saveCurrentUser(UserProfile profile);

  /// 팀 목록 로드
  Future<List<Team>> loadMyTeams();

  /// 팀 목록 저장
  Future<void> saveMyTeams(List<Team> teams);

  /// 특정 팀의 게시글 로드
  Future<List<TeamPost>> loadTeamPosts(String teamId);

  /// 특정 팀의 게시글 저장
  Future<void> saveTeamPosts(String teamId, List<TeamPost> posts);

  /// 특정 팀의 운동 공유 로드
  Future<List<WorkoutShare>> loadTeamShares(String teamId);

  /// 특정 팀의 운동 공유 저장
  Future<void> saveTeamShares(String teamId, List<WorkoutShare> shares);
}

/// 챌린지 저장소
abstract class ChallengeRepository {
  /// 활성 챌린지 로드
  Future<List<Map<String, dynamic>>> loadActiveChallenges();

  /// 활성 챌린지 저장
  Future<void> saveActiveChallenges(List<Map<String, dynamic>> challenges);

  /// 완료 챌린지 로드
  Future<List<Map<String, dynamic>>> loadCompletedChallenges();

  /// 완료 챌린지 저장
  Future<void> saveCompletedChallenges(List<Map<String, dynamic>> challenges);
}

/// 업적/배지 저장소
abstract class AchievementRepository {
  /// 달성된 업적 ID 목록 로드
  Future<List<String>> loadUnlockedIds();

  /// 달성된 업적 ID 목록 저장
  Future<void> saveUnlockedIds(List<String> ids);

  /// 업적 진행 카운트 맵 로드
  Future<Map<String, int>> loadProgressCounts();

  /// 업적 진행 카운트 맵 저장
  Future<void> saveProgressCounts(Map<String, int> counts);
}
