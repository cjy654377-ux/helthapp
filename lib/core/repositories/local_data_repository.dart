import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// LocalWorkoutRepository - SharedPreferences 기반 운동 기록 저장소
// ---------------------------------------------------------------------------

class LocalWorkoutRepository implements WorkoutRepository {
  static const String _historyKey = 'workout_history';
  static const String _personalRecordsKey = 'personal_records';

  @override
  Future<List<WorkoutRecord>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final records = decoded
          .map((e) => WorkoutRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveRecord(WorkoutRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allRecords = await loadHistory();

      // id가 같은 기존 기록이 있으면 교체, 없으면 추가
      final index = allRecords.indexWhere((r) => r.id == record.id);
      if (index >= 0) {
        allRecords[index] = record;
      } else {
        allRecords.add(record);
      }

      final jsonString =
          jsonEncode(allRecords.map((r) => r.toJson()).toList());
      await prefs.setString(_historyKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<void> saveAllRecords(List<WorkoutRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_historyKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allRecords = await loadHistory();
      allRecords.removeWhere((r) => r.id == id);

      final jsonString =
          jsonEncode(allRecords.map((r) => r.toJson()).toList());
      await prefs.setString(_historyKey, jsonString);
    } catch (_) {
      // 삭제 실패 무시
    }
  }

  @override
  Future<List<PersonalRecord>> loadPersonalRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_personalRecordsKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> savePersonalRecords(List<PersonalRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_personalRecordsKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// LocalDietRepository - SharedPreferences 기반 식단 저장소
// ---------------------------------------------------------------------------

class LocalDietRepository implements DietRepository {
  static const String _nutritionGoalKey = 'nutrition_goal';
  static const String _recentFoodsKey = 'recent_foods';

  /// 날짜별 키 생성
  String _dietDateKey(String dateKey) => 'diet_$dateKey';

  @override
  Future<List<Meal>> loadMeals(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_dietDateKey(dateKey));
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMeals(String dateKey, List<Meal> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(meals.map((m) => m.toJson()).toList());
      await prefs.setString(_dietDateKey(dateKey), jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<NutritionGoal> loadNutritionGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_nutritionGoalKey);
      if (jsonString == null) return NutritionGoal.standard;

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return NutritionGoal.fromJson(decoded);
    } catch (_) {
      return NutritionGoal.standard;
    }
  }

  @override
  Future<void> saveNutritionGoal(NutritionGoal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(goal.toJson());
      await prefs.setString(_nutritionGoalKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<List<String>> loadRecentFoodIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentFoodsKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveRecentFoodIds(List<String> foodIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(foodIds);
      await prefs.setString(_recentFoodsKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// LocalHydrationRepository - SharedPreferences 기반 수분 섭취 저장소
// ---------------------------------------------------------------------------

class LocalHydrationRepository implements HydrationRepository {
  static const String _settingsKey = 'hydration_settings';

  /// 날짜별 키 생성
  String _hydrationDateKey(String dateKey) => 'hydration_$dateKey';

  @override
  Future<Map<String, dynamic>> loadHydrationData(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_hydrationDateKey(dateKey));
      if (jsonString == null) return {};

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveHydrationData(
      String dateKey, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(_hydrationDateKey(dateKey), jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<Map<String, dynamic>> loadHydrationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null) return {};

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveHydrationSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);
      await prefs.setString(_settingsKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// LocalCalendarRepository - SharedPreferences 기반 캘린더 저장소
// ---------------------------------------------------------------------------

class LocalCalendarRepository implements CalendarRepository {
  static const String _plansKey = 'calendar_plans';

  @override
  Future<Map<String, List<Map<String, dynamic>>>> loadAllPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_plansKey);
      if (jsonString == null) return {};

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final entries = (value as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return MapEntry(key, entries);
      });
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveAllPlans(
      Map<String, List<Map<String, dynamic>>> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(plans);
      await prefs.setString(_plansKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// LocalCommunityRepository - SharedPreferences 기반 커뮤니티 저장소
// ---------------------------------------------------------------------------

class LocalCommunityRepository implements CommunityRepository {
  static const String _currentUserKey = 'current_user';
  static const String _myTeamsKey = 'my_teams';

  /// 팀 게시글 키 생성
  String _teamPostsKey(String teamId) => 'team_posts_$teamId';

  /// 팀 운동 공유 키 생성
  String _teamSharesKey(String teamId) => 'team_shares_$teamId';

  @override
  Future<UserProfile?> loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_currentUserKey);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCurrentUser(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toJson());
      await prefs.setString(_currentUserKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<List<Team>> loadMyTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_myTeamsKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMyTeams(List<Team> teams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(teams.map((t) => t.toJson()).toList());
      await prefs.setString(_myTeamsKey, jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<List<TeamPost>> loadTeamPosts(String teamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_teamPostsKey(teamId));
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => TeamPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTeamPosts(String teamId, List<TeamPost> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(posts.map((p) => p.toJson()).toList());
      await prefs.setString(_teamPostsKey(teamId), jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<List<WorkoutShare>> loadTeamShares(String teamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_teamSharesKey(teamId));
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => WorkoutShare.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTeamShares(
      String teamId, List<WorkoutShare> shares) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(shares.map((s) => s.toJson()).toList());
      await prefs.setString(_teamSharesKey(teamId), jsonString);
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

class LocalChallengeRepository implements ChallengeRepository {
  static const _activeChallengesKey = 'active_challenges';
  static const _completedChallengesKey = 'completed_challenges';

  @override
  Future<List<Map<String, dynamic>>> loadActiveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_activeChallengesKey);
      if (json == null) return [];
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveActiveChallenges(List<Map<String, dynamic>> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeChallengesKey, jsonEncode(challenges));
    } catch (_) {}
  }

  @override
  Future<List<Map<String, dynamic>>> loadCompletedChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_completedChallengesKey);
      if (json == null) return [];
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveCompletedChallenges(List<Map<String, dynamic>> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_completedChallengesKey, jsonEncode(challenges));
    } catch (_) {}
  }
}
