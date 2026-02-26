// Apple Health / Google Fit 양방향 동기화 서비스
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 상수
// ---------------------------------------------------------------------------

abstract final class _HealthKeys {
  static const String lastSyncTime = 'health_last_sync_time';
  static const String stepsEnabled = 'health_sync_steps';
  static const String workoutsEnabled = 'health_sync_workouts';
  static const String weightEnabled = 'health_sync_weight';
  static const String waterEnabled = 'health_sync_water';
  static const String sleepEnabled = 'health_sync_sleep';
  static const String heartRateEnabled = 'health_sync_heart_rate';
}

// ---------------------------------------------------------------------------
// HealthSyncConfig - 동기화 설정 모델
// ---------------------------------------------------------------------------

class HealthSyncConfig {
  final bool stepsEnabled;
  final bool workoutsEnabled;
  final bool weightEnabled;
  final bool waterEnabled;
  final bool sleepEnabled;
  final bool heartRateEnabled;

  const HealthSyncConfig({
    this.stepsEnabled = true,
    this.workoutsEnabled = true,
    this.weightEnabled = true,
    this.waterEnabled = true,
    this.sleepEnabled = true,
    this.heartRateEnabled = true,
  });

  HealthSyncConfig copyWith({
    bool? stepsEnabled,
    bool? workoutsEnabled,
    bool? weightEnabled,
    bool? waterEnabled,
    bool? sleepEnabled,
    bool? heartRateEnabled,
  }) {
    return HealthSyncConfig(
      stepsEnabled: stepsEnabled ?? this.stepsEnabled,
      workoutsEnabled: workoutsEnabled ?? this.workoutsEnabled,
      weightEnabled: weightEnabled ?? this.weightEnabled,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      sleepEnabled: sleepEnabled ?? this.sleepEnabled,
      heartRateEnabled: heartRateEnabled ?? this.heartRateEnabled,
    );
  }
}

// ---------------------------------------------------------------------------
// HealthSyncService
// ---------------------------------------------------------------------------

/// Apple Health (iOS) / Google Fit (Android) 양방향 동기화 서비스
class HealthSyncService {
  final Health _health = Health();

  // 요청할 데이터 타입
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WEIGHT,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  static const List<HealthDataType> _writeTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  // ---------------------------------------------------------------------------
  // 기본 확인
  // ---------------------------------------------------------------------------

  /// 현재 플랫폼에서 Health 데이터 사용 가능 여부
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // 권한 요청
  // ---------------------------------------------------------------------------

  /// 읽기/쓰기 권한 요청
  /// 반환값: true = 권한 부여됨, false = 거부됨
  Future<bool> requestPermissions() async {
    if (!await isAvailable()) return false;

    try {
      // iOS: 읽기 + 쓰기 모두 요청
      // Android: Google Fit에서 필요한 권한만 요청
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _writeTypes
            .map((_) => HealthDataAccess.READ_WRITE)
            .toList()
          ..addAll(
            List.filled(
              _readTypes.length - _writeTypes.length,
              HealthDataAccess.READ,
            ),
          ),
      );
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// 현재 권한 부여 여부 확인
  Future<bool> hasPermissions() async {
    if (!await isAvailable()) return false;
    try {
      final result = await _health.hasPermissions(_readTypes);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 읽기 기능
  // ---------------------------------------------------------------------------

  /// 오늘의 걸음 수 읽기
  Future<int> readStepsToday() async {
    if (!await isAvailable()) return 0;
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 오늘의 심박수 샘플 읽기 (bpm 목록)
  Future<List<int>> readHeartRateToday() async {
    if (!await isAvailable()) return [];
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: midnight,
        endTime: now,
      );

      return data
          .map((point) {
            final value = point.value;
            if (value is NumericHealthValue) {
              return value.numericValue.round();
            }
            return 0;
          })
          .where((bpm) => bpm > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 어젯밤 수면 데이터 읽기
  Future<Duration?> readSleepLastNight() async {
    if (!await isAvailable()) return null;
    try {
      final now = DateTime.now();
      // 어제 오후 6시 ~ 오늘 오전 11시 범위
      final from = DateTime(now.year, now.month, now.day - 1, 18, 0);
      final to = DateTime(now.year, now.month, now.day, 11, 0);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: from,
        endTime: to,
      );

      if (data.isEmpty) return null;

      // 총 수면 시간 계산
      int totalMinutes = 0;
      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        totalMinutes += duration;
      }

      return Duration(minutes: totalMinutes);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 쓰기 기능
  // ---------------------------------------------------------------------------

  /// 운동 기록을 Health로 동기화
  /// [durationMinutes]: 운동 시간(분)
  /// [caloriesBurned]: 소모 칼로리
  /// [workoutType]: HealthWorkoutActivityType (기본: 일반 운동)
  Future<bool> syncWorkoutToHealth({
    required DateTime startTime,
    required int durationMinutes,
    required double caloriesBurned,
    HealthWorkoutActivityType workoutType =
        HealthWorkoutActivityType.STRENGTH_TRAINING,
  }) async {
    if (!await isAvailable()) return false;
    try {
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final success = await _health.writeWorkoutData(
        activityType: workoutType,
        start: startTime,
        end: endTime,
        totalEnergyBurned: caloriesBurned.round(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 체중 데이터를 Health로 동기화 (kg 단위)
  Future<bool> syncWeightToHealth(double weightKg) async {
    if (!await isAvailable()) return false;
    try {
      final success = await _health.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: DateTime.now(),
        unit: HealthDataUnit.KILOGRAM,
      );
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 수분 섭취량을 Health로 동기화 (ml 단위)
  Future<bool> syncWaterToHealth(double ml) async {
    if (!await isAvailable()) return false;
    try {
      // Health 패키지는 리터 단위 사용
      final success = await _health.writeHealthData(
        value: ml / 1000.0,
        type: HealthDataType.WATER,
        startTime: DateTime.now(),
        unit: HealthDataUnit.LITER,
      );
      return success;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 동기화 시간 관리 (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// 마지막 동기화 시간 조회
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_HealthKeys.lastSyncTime);
      if (ms == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  /// 마지막 동기화 시간 저장
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _HealthKeys.lastSyncTime, time.millisecondsSinceEpoch);
    } catch (_) {
      // 저장 실패 시 무시
    }
  }

  // ---------------------------------------------------------------------------
  // 동기화 설정 관리 (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// 저장된 동기화 설정 로드
  Future<HealthSyncConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return HealthSyncConfig(
        stepsEnabled: prefs.getBool(_HealthKeys.stepsEnabled) ?? true,
        workoutsEnabled: prefs.getBool(_HealthKeys.workoutsEnabled) ?? true,
        weightEnabled: prefs.getBool(_HealthKeys.weightEnabled) ?? true,
        waterEnabled: prefs.getBool(_HealthKeys.waterEnabled) ?? true,
        sleepEnabled: prefs.getBool(_HealthKeys.sleepEnabled) ?? true,
        heartRateEnabled: prefs.getBool(_HealthKeys.heartRateEnabled) ?? true,
      );
    } catch (_) {
      return const HealthSyncConfig();
    }
  }

  /// 동기화 설정 저장
  Future<void> saveConfig(HealthSyncConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_HealthKeys.stepsEnabled, config.stepsEnabled);
      await prefs.setBool(_HealthKeys.workoutsEnabled, config.workoutsEnabled);
      await prefs.setBool(_HealthKeys.weightEnabled, config.weightEnabled);
      await prefs.setBool(_HealthKeys.waterEnabled, config.waterEnabled);
      await prefs.setBool(_HealthKeys.sleepEnabled, config.sleepEnabled);
      await prefs.setBool(
          _HealthKeys.heartRateEnabled, config.heartRateEnabled);
    } catch (_) {
      // 저장 실패 시 무시
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// HealthSyncService 싱글턴 Provider
final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

/// 오늘의 걸음 수 FutureProvider
final todayStepsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(healthSyncServiceProvider);
  return service.readStepsToday();
});

/// Health 권한 부여 여부 FutureProvider
final healthPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(healthSyncServiceProvider);
  return service.hasPermissions();
});

/// Health 플랫폼 사용 가능 여부 FutureProvider
final healthAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(healthSyncServiceProvider);
  return service.isAvailable();
});

/// 동기화 설정 상태 Provider
final healthSyncConfigProvider =
    StateNotifierProvider<_HealthSyncConfigNotifier, HealthSyncConfig>(
  (ref) => _HealthSyncConfigNotifier(ref.read(healthSyncServiceProvider)),
);

class _HealthSyncConfigNotifier extends StateNotifier<HealthSyncConfig> {
  final HealthSyncService _service;

  _HealthSyncConfigNotifier(this._service) : super(const HealthSyncConfig()) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.loadConfig();
  }

  Future<void> update(HealthSyncConfig config) async {
    state = config;
    await _service.saveConfig(config);
  }
}
