// 실제 OS 알림 서비스 - flutter_local_notifications 사용
// 수분/운동/식단/휴식 리마인더를 시스템 알림으로 전송
import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// 열거형 정의
// ---------------------------------------------------------------------------

/// 식사 시간 열거형
enum MealTime {
  breakfast('아침', 8, 0),
  lunch('점심', 12, 0),
  dinner('저녁', 18, 30),
  snack('간식', 15, 0);

  final String label;
  final int hour;
  final int minute;

  const MealTime(this.label, this.hour, this.minute);
}

/// 리마인더 타입 열거형
enum ReminderType {
  hydration('수분 섭취'),
  workout('운동'),
  meal('식단'),
  rest('휴식'),
  general('일반');

  final String label;
  const ReminderType(this.label);
}

// ---------------------------------------------------------------------------
// ReminderInfo 모델
// ---------------------------------------------------------------------------

class ReminderInfo {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final ReminderType type;
  final bool isRepeating;
  final Duration? interval;

  const ReminderInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
    this.isRepeating = false,
    this.interval,
  });

  ReminderInfo copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    ReminderType? type,
    bool? isRepeating,
    Duration? interval,
  }) {
    return ReminderInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      isRepeating: isRepeating ?? this.isRepeating,
      interval: interval ?? this.interval,
    );
  }

  @override
  String toString() =>
      'ReminderInfo(id: $id, title: $title, type: ${type.label})';
}

// ---------------------------------------------------------------------------
// 콜백 타입
// ---------------------------------------------------------------------------

typedef ReminderCallback = void Function(ReminderInfo reminder);

// ---------------------------------------------------------------------------
// 알림 채널 상수
// ---------------------------------------------------------------------------

abstract final class _Channels {
  static const String hydration = 'hydration_channel';
  static const String workout = 'workout_channel';
  static const String meal = 'meal_channel';
  static const String general = 'general_channel';
}

int _idFromString(String id) => id.hashCode.abs() % 100000;

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final Map<String, Timer> _timers = {};
  final Map<String, ReminderInfo> _reminders = {};
  ReminderCallback? _onReminderTriggered;

  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // 초기화
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // 추후 라우팅 연동 가능
  }

  void setOnReminderTriggered(ReminderCallback callback) {
    _onReminderTriggered = callback;
  }

  void removeOnReminderTriggered() {
    _onReminderTriggered = null;
  }

  // ---------------------------------------------------------------------------
  // 수분 섭취 리마인더
  // ---------------------------------------------------------------------------

  Future<void> scheduleHydrationReminder({required Duration interval}) async {
    const id = 'hydration_reminder';
    await cancelReminder(id);

    final now = DateTime.now();
    final info = ReminderInfo(
      id: id,
      title: '물 마실 시간이에요!',
      body: '수분 섭취 목표를 달성하기 위해 지금 물을 마셔보세요.',
      scheduledTime: now.add(interval),
      type: ReminderType.hydration,
      isRepeating: true,
      interval: interval,
    );
    _reminders[id] = info;

    if (_isInitialized) {
      await _plugin.periodicallyShow(
        id: _idFromString(id),
        title: info.title,
        body: info.body,
        repeatInterval: _durationToRepeatInterval(interval),
        notificationDetails: _details(
          channelId: _Channels.hydration,
          channelName: '수분 섭취 알림',
          channelDesc: '수분 섭취 리마인더',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    _timers[id] = Timer.periodic(interval, (_) {
      _onReminderTriggered?.call(info);
    });
  }

  // ---------------------------------------------------------------------------
  // 운동 리마인더
  // ---------------------------------------------------------------------------

  Future<void> scheduleWorkoutReminder({
    required DateTime time,
    required String workoutName,
  }) async {
    final id = 'workout_${time.millisecondsSinceEpoch}';
    final now = DateTime.now();
    if (time.isBefore(now)) return;

    final info = ReminderInfo(
      id: id,
      title: '운동 시간이에요!',
      body: '오늘의 $workoutName 운동을 시작할 시간입니다.',
      scheduledTime: time,
      type: ReminderType.workout,
    );
    _reminders[id] = info;

    if (_isInitialized) {
      await _plugin.zonedSchedule(
        id: _idFromString(id),
        title: info.title,
        body: info.body,
        scheduledDate: _toTZ(time),
        notificationDetails: _details(
          channelId: _Channels.workout,
          channelName: '운동 알림',
          channelDesc: '운동 리마인더',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final delay = time.difference(now);
    _timers[id] = Timer(delay, () {
      _onReminderTriggered?.call(info);
      _timers.remove(id);
      _reminders.remove(id);
    });
  }

  // ---------------------------------------------------------------------------
  // 식단 리마인더
  // ---------------------------------------------------------------------------

  Future<void> scheduleMealReminder({required MealTime mealTime}) async {
    final id = 'meal_${mealTime.name}';
    await cancelReminder(id);

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year, now.month, now.day, mealTime.hour, mealTime.minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final info = ReminderInfo(
      id: id,
      title: '${mealTime.label} 기록 시간이에요!',
      body: '${mealTime.label} 식단을 기록하고 영양 목표를 확인하세요.',
      scheduledTime: scheduledTime,
      type: ReminderType.meal,
      isRepeating: true,
      interval: const Duration(days: 1),
    );
    _reminders[id] = info;

    if (_isInitialized) {
      await _plugin.zonedSchedule(
        id: _idFromString(id),
        title: info.title,
        body: info.body,
        scheduledDate: _toTZ(scheduledTime),
        notificationDetails: _details(
          channelId: _Channels.meal,
          channelName: '식단 알림',
          channelDesc: '식단 기록 리마인더',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    final delay = scheduledTime.difference(now);
    _timers[id] = Timer(delay, () {
      _onReminderTriggered?.call(info);
      _timers[id]?.cancel();
      _timers[id] = Timer.periodic(const Duration(days: 1), (_) {
        _onReminderTriggered?.call(info);
      });
    });
  }

  // ---------------------------------------------------------------------------
  // 휴식 리마인더
  // ---------------------------------------------------------------------------

  Future<void> scheduleRestReminder({required Duration interval}) async {
    const id = 'rest_reminder';
    await cancelReminder(id);

    final now = DateTime.now();
    final info = ReminderInfo(
      id: id,
      title: '잠깐 휴식을 취하세요!',
      body: '오랫동안 앉아 계셨네요. 잠깐 스트레칭을 해보세요.',
      scheduledTime: now.add(interval),
      type: ReminderType.rest,
      isRepeating: true,
      interval: interval,
    );
    _reminders[id] = info;

    if (_isInitialized) {
      await _plugin.periodicallyShow(
        id: _idFromString(id),
        title: info.title,
        body: info.body,
        repeatInterval: _durationToRepeatInterval(interval),
        notificationDetails: _details(
          channelId: _Channels.general,
          channelName: '일반 알림',
          channelDesc: '휴식 및 일반 리마인더',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    _timers[id] = Timer.periodic(interval, (_) {
      _onReminderTriggered?.call(info);
    });
  }

  // ---------------------------------------------------------------------------
  // 일반 리마인더
  // ---------------------------------------------------------------------------

  Future<void> scheduleGeneralReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeating = false,
    Duration? interval,
  }) async {
    await cancelReminder(id);

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    final info = ReminderInfo(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      type: ReminderType.general,
      isRepeating: repeating,
      interval: interval,
    );
    _reminders[id] = info;

    if (_isInitialized) {
      await _plugin.zonedSchedule(
        id: _idFromString(id),
        title: title,
        body: body,
        scheduledDate: _toTZ(scheduledTime),
        notificationDetails: _details(
          channelId: _Channels.general,
          channelName: '일반 알림',
          channelDesc: '일반 리마인더',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeating ? DateTimeComponents.time : null,
      );
    }

    final delay = scheduledTime.difference(now);
    if (repeating && interval != null) {
      _timers[id] = Timer(delay, () {
        _onReminderTriggered?.call(info);
        _timers[id]?.cancel();
        _timers[id] = Timer.periodic(interval, (_) {
          _onReminderTriggered?.call(info);
        });
      });
    } else {
      _timers[id] = Timer(delay, () {
        _onReminderTriggered?.call(info);
        _timers.remove(id);
        _reminders.remove(id);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 즉시 알림
  // ---------------------------------------------------------------------------

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: _details(
        channelId: _Channels.general,
        channelName: '일반 알림',
        channelDesc: '일반 알림',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 리마인더 관리
  // ---------------------------------------------------------------------------

  Future<void> cancelReminder(String id) async {
    _timers[id]?.cancel();
    _timers.remove(id);
    _reminders.remove(id);
    if (_isInitialized) {
      await _plugin.cancel(id: _idFromString(id));
    }
  }

  Future<void> cancelAll() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _reminders.clear();
    if (_isInitialized) {
      await _plugin.cancelAll();
    }
  }

  Future<void> cancelHydrationReminder() async {
    await cancelReminder('hydration_reminder');
  }

  Future<void> cancelMealReminder(MealTime mealTime) async {
    await cancelReminder('meal_${mealTime.name}');
  }

  Future<void> cancelAllMealReminders() async {
    for (final mealTime in MealTime.values) {
      await cancelMealReminder(mealTime);
    }
  }

  List<ReminderInfo> get activeReminders =>
      List.unmodifiable(_reminders.values.toList());

  List<ReminderInfo> remindersByType(ReminderType type) {
    return _reminders.values.where((r) => r.type == type).toList();
  }

  ReminderInfo? getReminderById(String id) => _reminders[id];
  int get activeReminderCount => _reminders.length;
  bool isReminderActive(String id) => _reminders.containsKey(id);

  // ---------------------------------------------------------------------------
  // 내부 헬퍼
  // ---------------------------------------------------------------------------

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _toTZ(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

  RepeatInterval _durationToRepeatInterval(Duration d) {
    if (d.inHours >= 24) return RepeatInterval.daily;
    if (d.inHours >= 1) return RepeatInterval.hourly;
    return RepeatInterval.everyMinute;
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _reminders.clear();
    _onReminderTriggered = null;
  }
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});
