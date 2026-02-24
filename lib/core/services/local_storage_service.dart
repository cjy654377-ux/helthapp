// 로컬 저장소 서비스 - SharedPreferences 래퍼
// 운동/식단/수분/캘린더/설정/체성분 데이터의 영속적 저장 및 로드를 담당합니다.
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// SharedPreferences 키 상수
// ---------------------------------------------------------------------------

/// 저장소 키 네임스페이스 상수 모음
abstract final class _StorageKeys {
  // 운동 기록
  static const String workoutRecords = 'workout_records';

  // 식단 기록
  static const String dietRecords = 'diet_records';

  // 수분 기록
  static const String hydrationRecords = 'hydration_records';

  // 캘린더 계획
  static const String calendarPlans = 'calendar_plans';

  // 사용자 설정
  static const String userSettings = 'user_settings';

  // 체중/체성분 기록
  static const String bodyRecords = 'body_records';
}

// ---------------------------------------------------------------------------
// LocalStorageService
// ---------------------------------------------------------------------------

/// SharedPreferences를 사용하는 로컬 저장소 서비스
///
/// 모든 데이터는 JSON 직렬화/역직렬화를 통해 저장/로드됩니다.
/// 비동기 초기화가 필요하므로 [init]을 먼저 호출해야 합니다.
class LocalStorageService {
  LocalStorageService._();

  /// Named constructor for test subclasses only.
  @visibleForTesting
  LocalStorageService.forTesting();

  static final LocalStorageService _instance = LocalStorageService._();
  factory LocalStorageService() => _instance;

  SharedPreferences? _prefs;

  /// 서비스 초기화 - 앱 시작 시 호출 필요
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 초기화 완료 여부
  bool get isInitialized => _prefs != null;

  /// SharedPreferences 인스턴스 (초기화 안 되었으면 예외)
  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'LocalStorageService가 초기화되지 않았습니다. init()을 먼저 호출하세요.',
      );
    }
    return prefs;
  }

  // ---------------------------------------------------------------------------
  // 운동 기록 저장/로드
  // ---------------------------------------------------------------------------

  /// 운동 기록 목록 저장
  ///
  /// [records]: 저장할 운동 기록 목록 (Map 형태로 직렬화된 WorkoutLog 리스트)
  Future<void> saveWorkoutRecords(List<Map<String, dynamic>> records) async {
    await _saveJsonList(_StorageKeys.workoutRecords, records);
  }

  /// 운동 기록 목록 로드
  ///
  /// 저장된 데이터가 없으면 빈 리스트 반환
  Future<List<Map<String, dynamic>>> loadWorkoutRecords() async {
    return _loadJsonList(_StorageKeys.workoutRecords);
  }

  /// 운동 기록 전체 삭제
  Future<void> clearWorkoutRecords() async {
    await _requirePrefs.remove(_StorageKeys.workoutRecords);
  }

  // ---------------------------------------------------------------------------
  // 식단 기록 저장/로드
  // ---------------------------------------------------------------------------

  /// 식단 기록 목록 저장
  ///
  /// [records]: 저장할 식단 기록 목록 (Map 형태로 직렬화된 Meal 리스트)
  Future<void> saveDietRecords(List<Map<String, dynamic>> records) async {
    await _saveJsonList(_StorageKeys.dietRecords, records);
  }

  /// 식단 기록 목록 로드
  ///
  /// 저장된 데이터가 없으면 빈 리스트 반환
  Future<List<Map<String, dynamic>>> loadDietRecords() async {
    return _loadJsonList(_StorageKeys.dietRecords);
  }

  /// 식단 기록 전체 삭제
  Future<void> clearDietRecords() async {
    await _requirePrefs.remove(_StorageKeys.dietRecords);
  }

  // ---------------------------------------------------------------------------
  // 수분 기록 저장/로드
  // ---------------------------------------------------------------------------

  /// 수분 섭취 기록 목록 저장
  ///
  /// [records]: 저장할 수분 기록 목록 (Map 형태로 직렬화된 WaterIntakeEntry 리스트)
  Future<void> saveHydrationRecords(List<Map<String, dynamic>> records) async {
    await _saveJsonList(_StorageKeys.hydrationRecords, records);
  }

  /// 수분 섭취 기록 목록 로드
  ///
  /// 저장된 데이터가 없으면 빈 리스트 반환
  Future<List<Map<String, dynamic>>> loadHydrationRecords() async {
    return _loadJsonList(_StorageKeys.hydrationRecords);
  }

  /// 수분 기록 전체 삭제
  Future<void> clearHydrationRecords() async {
    await _requirePrefs.remove(_StorageKeys.hydrationRecords);
  }

  // ---------------------------------------------------------------------------
  // 캘린더 계획 저장/로드
  // ---------------------------------------------------------------------------

  /// 캘린더 운동 계획 저장
  ///
  /// [plans]: 저장할 캘린더 계획 (날짜 문자열 -> 계획 데이터 Map)
  Future<void> saveCalendarPlans(Map<String, dynamic> plans) async {
    await _saveJsonMap(_StorageKeys.calendarPlans, plans);
  }

  /// 캘린더 운동 계획 로드
  ///
  /// 저장된 데이터가 없으면 빈 Map 반환
  Future<Map<String, dynamic>> loadCalendarPlans() async {
    return _loadJsonMap(_StorageKeys.calendarPlans);
  }

  /// 캘린더 계획 전체 삭제
  Future<void> clearCalendarPlans() async {
    await _requirePrefs.remove(_StorageKeys.calendarPlans);
  }

  // ---------------------------------------------------------------------------
  // 사용자 설정 저장/로드
  // ---------------------------------------------------------------------------

  /// 사용자 설정 저장
  ///
  /// [settings]: 저장할 설정 Map (알림 설정, 목표 설정, UI 설정 등)
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    await _saveJsonMap(_StorageKeys.userSettings, settings);
  }

  /// 사용자 설정 로드
  ///
  /// 저장된 데이터가 없으면 빈 Map 반환
  Future<Map<String, dynamic>> loadUserSettings() async {
    return _loadJsonMap(_StorageKeys.userSettings);
  }

  /// 특정 설정 값 저장 (단일 키-값)
  ///
  /// [key]: 설정 키
  /// [value]: 저장할 값 (String, int, double, bool 지원)
  Future<void> saveSettingValue(String key, dynamic value) async {
    final settings = await loadUserSettings();
    settings[key] = value;
    await saveUserSettings(settings);
  }

  /// 특정 설정 값 로드 (단일 키)
  ///
  /// [key]: 설정 키
  /// [defaultValue]: 키가 없을 때 반환할 기본값
  Future<T?> loadSettingValue<T>(String key, {T? defaultValue}) async {
    final settings = await loadUserSettings();
    final value = settings[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// 사용자 설정 전체 삭제
  Future<void> clearUserSettings() async {
    await _requirePrefs.remove(_StorageKeys.userSettings);
  }

  // ---------------------------------------------------------------------------
  // 체중/체성분 기록 저장/로드
  // ---------------------------------------------------------------------------

  /// 체중/체성분 기록 목록 저장
  ///
  /// [records]: 저장할 체성분 기록 목록 (날짜, 체중, 체지방률, 근육량 등 포함)
  Future<void> saveBodyRecords(List<Map<String, dynamic>> records) async {
    await _saveJsonList(_StorageKeys.bodyRecords, records);
  }

  /// 체중/체성분 기록 목록 로드
  ///
  /// 저장된 데이터가 없으면 빈 리스트 반환
  Future<List<Map<String, dynamic>>> loadBodyRecords() async {
    return _loadJsonList(_StorageKeys.bodyRecords);
  }

  /// 체성분 기록 전체 삭제
  Future<void> clearBodyRecords() async {
    await _requirePrefs.remove(_StorageKeys.bodyRecords);
  }

  // ---------------------------------------------------------------------------
  // 전체 데이터 관리
  // ---------------------------------------------------------------------------

  /// 모든 앱 데이터 삭제 (초기화/탈퇴 시 사용)
  Future<void> clearAll() async {
    await Future.wait([
      clearWorkoutRecords(),
      clearDietRecords(),
      clearHydrationRecords(),
      clearCalendarPlans(),
      clearUserSettings(),
      clearBodyRecords(),
    ]);
  }

  /// 저장된 전체 데이터 크기 추정 (바이트 단위)
  Future<int> estimateDataSize() async {
    final keys = [
      _StorageKeys.workoutRecords,
      _StorageKeys.dietRecords,
      _StorageKeys.hydrationRecords,
      _StorageKeys.calendarPlans,
      _StorageKeys.userSettings,
      _StorageKeys.bodyRecords,
    ];

    int total = 0;
    for (final key in keys) {
      final value = _requirePrefs.getString(key);
      if (value != null) {
        total += value.length;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // 내부 헬퍼 메서드
  // ---------------------------------------------------------------------------

  /// JSON 리스트를 SharedPreferences에 저장
  Future<void> _saveJsonList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    try {
      final jsonString = jsonEncode(list);
      await _requirePrefs.setString(key, jsonString);
    } catch (e) {
      // 직렬화 오류 시 저장 실패 (데이터 손상 방지)
      throw StorageException('데이터 저장 실패 (key: $key): $e');
    }
  }

  /// SharedPreferences에서 JSON 리스트 로드
  Future<List<Map<String, dynamic>>> _loadJsonList(String key) async {
    try {
      final jsonString = _requirePrefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      // 역직렬화 오류 시 빈 리스트 반환 (앱 크래시 방지)
      return [];
    }
  }

  /// JSON Map을 SharedPreferences에 저장
  Future<void> _saveJsonMap(
    String key,
    Map<String, dynamic> map,
  ) async {
    try {
      final jsonString = jsonEncode(map);
      await _requirePrefs.setString(key, jsonString);
    } catch (e) {
      throw StorageException('데이터 저장 실패 (key: $key): $e');
    }
  }

  /// SharedPreferences에서 JSON Map 로드
  Future<Map<String, dynamic>> _loadJsonMap(String key) async {
    try {
      final jsonString = _requirePrefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return {};

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return {};

      return decoded;
    } catch (e) {
      // 역직렬화 오류 시 빈 Map 반환
      return {};
    }
  }
}

// ---------------------------------------------------------------------------
// 예외 클래스
// ---------------------------------------------------------------------------

/// 저장소 작업 실패 예외
class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

/// SharedPreferences 인스턴스 Provider (비동기 초기화)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// LocalStorageService Provider
///
/// 앱 시작 시 [sharedPreferencesProvider]가 완료된 후 생성됩니다.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// 초기화된 LocalStorageService Provider (비동기)
///
/// 초기화가 완료되어야 사용 가능합니다.
final localStorageServiceInitProvider =
    FutureProvider<LocalStorageService>((ref) async {
  final service = ref.watch(localStorageServiceProvider);
  await service.init();
  return service;
});
