// Firestore 기반 데이터 저장소 구현
// 5개의 레포지토리 인터페이스를 Firestore로 구현

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_app/core/models/community_model.dart';
import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/core/repositories/data_repository.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// FirestoreWorkoutRepository
// ---------------------------------------------------------------------------

/// Firestore 기반 운동 기록 저장소
class FirestoreWorkoutRepository implements WorkoutRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreWorkoutRepository({required String uid, FirebaseFirestore? db})
      : _uid = uid,
        _db = db ?? FirebaseFirestore.instance;

  /// 운동 기록 서브컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _workoutsRef =>
      _db.collection('users').doc(_uid).collection('workouts');

  /// 개인 기록(PR) 서브컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _prRef =>
      _db.collection('users').doc(_uid).collection('personalRecords');

  @override
  Future<List<WorkoutRecord>> loadHistory() async {
    try {
      final snapshot =
          await _workoutsRef.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutRecord.fromJson(data);
      }).toList();
    } catch (_) {
      // 로드 실패 시 빈 목록 반환
      return [];
    }
  }

  @override
  Future<void> saveRecord(WorkoutRecord record) async {
    try {
      await _workoutsRef.doc(record.id).set(record.toJson());
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<void> saveAllRecords(List<WorkoutRecord> records) async {
    try {
      // Firestore batch: 최대 500개 제한 고려
      const batchLimit = 500;
      for (var i = 0; i < records.length; i += batchLimit) {
        final chunk = records.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final record in chunk) {
          batch.set(_workoutsRef.doc(record.id), record.toJson());
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      await _workoutsRef.doc(id).delete();
    } catch (_) {
      // 삭제 실패 무시
    }
  }

  @override
  Future<List<PersonalRecord>> loadPersonalRecords() async {
    try {
      final snapshot = await _prRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PersonalRecord.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> savePersonalRecords(List<PersonalRecord> records) async {
    try {
      // 기존 PR 전부 삭제 후 재작성 (batch 사용)
      final existing = await _prRef.get();
      const batchLimit = 500;

      // 삭제 배치
      for (var i = 0; i < existing.docs.length; i += batchLimit) {
        final chunk = existing.docs.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 쓰기 배치
      for (var i = 0; i < records.length; i += batchLimit) {
        final chunk = records.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final record in chunk) {
          // exerciseId를 문서 ID로 사용
          batch.set(_prRef.doc(record.exerciseId), record.toJson());
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// FirestoreDietRepository
// ---------------------------------------------------------------------------

/// Firestore 기반 식단 저장소
class FirestoreDietRepository implements DietRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreDietRepository({required String uid, FirebaseFirestore? db})
      : _uid = uid,
        _db = db ?? FirebaseFirestore.instance;

  /// 사용자 문서 참조
  DocumentReference<Map<String, dynamic>> get _userDocRef => _db.collection('users').doc(_uid);

  /// 날짜별 식사 서브컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _mealsRef =>
      _userDocRef.collection('meals');

  @override
  Future<List<Meal>> loadMeals(String dateKey) async {
    try {
      final doc = await _mealsRef.doc(dateKey).get();
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final mealsList = data['meals'] as List<dynamic>?;
      if (mealsList == null) return [];

      return mealsList
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMeals(String dateKey, List<Meal> meals) async {
    try {
      await _mealsRef.doc(dateKey).set({
        'meals': meals.map((m) => m.toJson()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<NutritionGoal> loadNutritionGoal() async {
    try {
      final doc =
          await _userDocRef.collection('settings').doc('nutritionGoal').get();
      if (!doc.exists) return NutritionGoal.standard;

      final data = doc.data();
      if (data == null) return NutritionGoal.standard;

      return NutritionGoal.fromJson(data);
    } catch (_) {
      return NutritionGoal.standard;
    }
  }

  @override
  Future<void> saveNutritionGoal(NutritionGoal goal) async {
    try {
      await _userDocRef
          .collection('settings')
          .doc('nutritionGoal')
          .set(goal.toJson());
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<List<String>> loadRecentFoodIds() async {
    try {
      final doc =
          await _userDocRef.collection('settings').doc('recentFoods').get();
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final ids = data['ids'] as List<dynamic>?;
      if (ids == null) return [];

      return ids.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveRecentFoodIds(List<String> ids) async {
    try {
      await _userDocRef.collection('settings').doc('recentFoods').set({
        'ids': ids,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// FirestoreHydrationRepository
// ---------------------------------------------------------------------------

/// Firestore 기반 수분 섭취 저장소
class FirestoreHydrationRepository implements HydrationRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreHydrationRepository({required String uid, FirebaseFirestore? db})
      : _uid = uid,
        _db = db ?? FirebaseFirestore.instance;

  /// 사용자 문서 참조
  DocumentReference<Map<String, dynamic>> get _userDocRef => _db.collection('users').doc(_uid);

  /// 날짜별 수분 데이터 서브컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _hydrationRef =>
      _userDocRef.collection('hydration');

  @override
  Future<Map<String, dynamic>> loadHydrationData(String dateKey) async {
    try {
      final doc = await _hydrationRef.doc(dateKey).get();
      if (!doc.exists) return {};

      final data = doc.data();
      return data ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveHydrationData(
      String dateKey, Map<String, dynamic> data) async {
    try {
      await _hydrationRef.doc(dateKey).set({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 저장 실패 무시
    }
  }

  @override
  Future<Map<String, dynamic>> loadHydrationSettings() async {
    try {
      final doc = await _userDocRef
          .collection('settings')
          .doc('hydrationSettings')
          .get();
      if (!doc.exists) return {};

      final data = doc.data();
      return data ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveHydrationSettings(Map<String, dynamic> settings) async {
    try {
      await _userDocRef
          .collection('settings')
          .doc('hydrationSettings')
          .set({
        ...settings,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// FirestoreCalendarRepository
// ---------------------------------------------------------------------------

/// Firestore 기반 캘린더 운동 계획 저장소
class FirestoreCalendarRepository implements CalendarRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreCalendarRepository({required String uid, FirebaseFirestore? db})
      : _uid = uid,
        _db = db ?? FirebaseFirestore.instance;

  /// 운동 계획 서브컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _db.collection('users').doc(_uid).collection('calendarPlans');

  @override
  Future<Map<String, List<Map<String, dynamic>>>> loadAllPlans() async {
    try {
      final snapshot = await _plansRef.get();
      final result = <String, List<Map<String, dynamic>>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final plansList = data['plans'] as List<dynamic>?;
        if (plansList == null) continue;

        result[doc.id] =
            plansList.map((e) => e as Map<String, dynamic>).toList();
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveAllPlans(
      Map<String, List<Map<String, dynamic>>> plans) async {
    try {
      // 기존 계획 전부 삭제 후 재작성
      final existing = await _plansRef.get();
      const batchLimit = 500;

      // 삭제 배치
      for (var i = 0; i < existing.docs.length; i += batchLimit) {
        final chunk = existing.docs.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 쓰기 배치 (dateKey를 문서 ID로 사용)
      final entries = plans.entries.toList();
      for (var i = 0; i < entries.length; i += batchLimit) {
        final chunk = entries.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final entry in chunk) {
          batch.set(_plansRef.doc(entry.key), {
            'plans': entry.value,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }
}

// ---------------------------------------------------------------------------
// FirestoreCommunityRepository
// ---------------------------------------------------------------------------

/// Firestore 기반 커뮤니티 저장소
/// 팀은 최상위 컬렉션(teams/{teamId})에 저장
class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreCommunityRepository({
    required String uid,
    FirebaseFirestore? db,
  })  : _uid = uid,
        _db = db ?? FirebaseFirestore.instance;

  /// 사용자 문서 참조
  DocumentReference<Map<String, dynamic>> get _userDocRef => _db.collection('users').doc(_uid);

  /// 최상위 팀 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _teamsRef => _db.collection('teams');

  // ── 사용자 프로필 ──────────────────────────────────────────────────────────

  @override
  Future<UserProfile?> loadCurrentUser() async {
    try {
      final doc =
          await _userDocRef.collection('settings').doc('communityProfile').get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCurrentUser(UserProfile profile) async {
    try {
      await _userDocRef
          .collection('settings')
          .doc('communityProfile')
          .set(profile.toJson());
    } catch (_) {
      // 저장 실패 무시
    }
  }

  // ── 팀 목록 ───────────────────────────────────────────────────────────────

  @override
  Future<List<Team>> loadMyTeams() async {
    try {
      // 사용자가 속한 팀 ID 목록을 settings에서 먼저 조회
      final doc =
          await _userDocRef.collection('settings').doc('myTeams').get();
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final teamIds = (data['team_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();
      if (teamIds == null || teamIds.isEmpty) return [];

      // 팀 ID로 각 팀 문서 로드
      final teams = <Team>[];
      for (final teamId in teamIds) {
        try {
          final teamDoc = await _teamsRef.doc(teamId).get();
          if (!teamDoc.exists) continue;

          final teamData = teamDoc.data();
          if (teamData == null) continue;

          teams.add(Team.fromJson(teamData));
        } catch (_) {
          // 개별 팀 로드 실패 시 건너뜀
          continue;
        }
      }
      return teams;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMyTeams(List<Team> teams) async {
    try {
      // 팀 ID 목록을 사용자 settings에 저장
      final teamIds = teams.map((t) => t.id).toList();
      await _userDocRef.collection('settings').doc('myTeams').set({
        'team_ids': teamIds,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 각 팀 문서를 최상위 teams 컬렉션에 저장
      const batchLimit = 500;
      for (var i = 0; i < teams.length; i += batchLimit) {
        final chunk = teams.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final team in chunk) {
          batch.set(_teamsRef.doc(team.id), team.toJson());
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }

  // ── 팀 게시글 ─────────────────────────────────────────────────────────────

  @override
  Future<List<TeamPost>> loadTeamPosts(String teamId) async {
    try {
      final snapshot = await _teamsRef
          .doc(teamId)
          .collection('posts')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TeamPost.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTeamPosts(String teamId, List<TeamPost> posts) async {
    try {
      final postsRef = _teamsRef.doc(teamId).collection('posts');

      // 기존 게시글 삭제 후 재작성
      final existing = await postsRef.get();
      const batchLimit = 500;

      // 삭제 배치
      for (var i = 0; i < existing.docs.length; i += batchLimit) {
        final chunk = existing.docs.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 쓰기 배치 (postId를 문서 ID로 사용)
      for (var i = 0; i < posts.length; i += batchLimit) {
        final chunk = posts.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final post in chunk) {
          batch.set(postsRef.doc(post.id), post.toJson());
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }

  // ── 운동 공유 ─────────────────────────────────────────────────────────────

  @override
  Future<List<WorkoutShare>> loadTeamShares(String teamId) async {
    try {
      final snapshot = await _teamsRef
          .doc(teamId)
          .collection('shares')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutShare.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTeamShares(
      String teamId, List<WorkoutShare> shares) async {
    try {
      final sharesRef = _teamsRef.doc(teamId).collection('shares');

      // 기존 공유 삭제 후 재작성
      final existing = await sharesRef.get();
      const batchLimit = 500;

      // 삭제 배치
      for (var i = 0; i < existing.docs.length; i += batchLimit) {
        final chunk = existing.docs.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 쓰기 배치 (shareId를 문서 ID로 사용)
      for (var i = 0; i < shares.length; i += batchLimit) {
        final chunk = shares.skip(i).take(batchLimit).toList();
        final batch = _db.batch();
        for (final share in chunk) {
          batch.set(sharesRef.doc(share.id), share.toJson());
        }
        await batch.commit();
      }
    } catch (_) {
      // 저장 실패 무시
    }
  }
}
