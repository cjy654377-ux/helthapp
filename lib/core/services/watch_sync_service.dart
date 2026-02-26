// 스마트워치 데이터 동기화 서비스 (스캐폴드)
// Apple Watch (WCSession) 및 Wear OS (Wearable MessageClient) 통신 준비
//
// ─── 네이티브 구현 가이드 ───────────────────────────────────────────────
//
// [iOS - Swift]
// 1. WatchConnectivity 프레임워크 import
// 2. AppDelegate 또는 별도 WatchSessionManager 클래스에서 WCSession 설정
//
//   import WatchConnectivity
//
//   class WatchSessionManager: NSObject, WCSessionDelegate {
//     static let shared = WatchSessionManager()
//     private override init() {
//       super.init()
//       if WCSession.isSupported() {
//         WCSession.default.delegate = self
//         WCSession.default.activate()
//       }
//     }
//
//     // Flutter -> Watch: 현재 운동 세션 데이터 전송
//     func sendWorkoutData(_ data: [String: Any]) {
//       guard WCSession.default.isReachable else { return }
//       WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: nil)
//     }
//
//     // Watch -> Flutter: 세트 완료 이벤트 수신
//     func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//       // Flutter MethodChannel로 이벤트 전달
//       channel.invokeMethod("setCompleted", message)
//     }
//
//     func session(_ session: WCSession,
//                  activationDidCompleteWith activationState: WCSessionActivationState,
//                  error: Error?) { }
//     func sessionDidBecomeInactive(_ session: WCSession) { }
//     func sessionDidDeactivate(_ session: WCSession) { }
//   }
//
//   // MethodChannel 핸들러 (AppDelegate.swift 또는 FlutterViewController)
//   let channel = FlutterMethodChannel(name: "com.rhythmicaleskimo.healthApp/watch",
//                                      binaryMessenger: controller.binaryMessenger)
//   channel.setMethodCallHandler { call, result in
//     switch call.method {
//     case "isWatchConnected":
//       result(WCSession.default.isReachable)
//     case "sendWorkoutToWatch":
//       if let data = call.arguments as? [String: Any] {
//         WatchSessionManager.shared.sendWorkoutData(data)
//       }
//       result(nil)
//     case "sendRestTimerToWatch":
//       if let seconds = call.arguments as? Int {
//         WatchSessionManager.shared.sendWorkoutData(["restSeconds": seconds])
//       }
//       result(nil)
//     default:
//       result(FlutterMethodNotImplemented)
//     }
//   }
//
// [Android - Kotlin]
// 1. build.gradle에 `implementation "com.google.android.gms:play-services-wearable:18.1.0"` 추가
// 2. MainActivity.kt에서 MethodChannel 설정
//
//   import com.google.android.gms.wearable.Wearable
//
//   class MainActivity : FlutterActivity() {
//     private val CHANNEL = "com.rhythmicaleskimo.healthApp/watch"
//
//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//       super.configureFlutterEngine(flutterEngine)
//
//       MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
//         .setMethodCallHandler { call, result ->
//           when (call.method) {
//             "isWatchConnected" -> checkWearConnected(result)
//             "sendWorkoutToWatch" -> {
//               val data = call.arguments as? Map<*, *>
//               sendMessageToWear(data, result)
//             }
//             "sendRestTimerToWatch" -> {
//               val seconds = call.arguments as? Int ?: 0
//               sendMessageToWear(mapOf("restSeconds" to seconds), result)
//             }
//             else -> result.notImplemented()
//           }
//         }
//     }
//
//     private fun checkWearConnected(result: MethodChannel.Result) {
//       Wearable.getNodeClient(this).connectedNodes
//         .addOnSuccessListener { nodes -> result.success(nodes.isNotEmpty()) }
//         .addOnFailureListener { result.success(false) }
//     }
//
//     private fun sendMessageToWear(data: Map<*, *>?, result: MethodChannel.Result) {
//       Wearable.getNodeClient(this).connectedNodes
//         .addOnSuccessListener { nodes ->
//           nodes.forEach { node ->
//             val payload = data?.toString()?.toByteArray() ?: ByteArray(0)
//             Wearable.getMessageClient(this)
//               .sendMessage(node.id, "/workout", payload)
//           }
//           result.success(null)
//         }
//         .addOnFailureListener { result.error("SEND_FAILED", it.message, null) }
//     }
//   }
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// 데이터 전송 모델
// ---------------------------------------------------------------------------

/// 워치로 전송할 운동 세션 데이터
class WatchWorkoutData {
  final String exerciseName;
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;

  const WatchWorkoutData({
    required this.exerciseName,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'restSeconds': restSeconds,
      };
}

/// 워치에서 수신한 세트 완료 이벤트
class SetCompletionEvent {
  final int exerciseIndex;
  final int setIndex;
  final int actualReps;
  final double actualWeight;
  final DateTime timestamp;

  const SetCompletionEvent({
    required this.exerciseIndex,
    required this.setIndex,
    required this.actualReps,
    required this.actualWeight,
    required this.timestamp,
  });

  factory SetCompletionEvent.fromJson(Map<String, dynamic> json) =>
      SetCompletionEvent(
        exerciseIndex: json['exerciseIndex'] as int? ?? 0,
        setIndex: json['setIndex'] as int? ?? 0,
        actualReps: json['actualReps'] as int? ?? 0,
        actualWeight: (json['actualWeight'] as num?)?.toDouble() ?? 0.0,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// WatchSyncService
// ---------------------------------------------------------------------------

/// Apple Watch / Wear OS 통신 서비스 (Flutter 측 스캐폴드)
///
/// 현재 네이티브 구현이 없으므로 모든 호출은 안전하게 no-op 처리됩니다.
/// 네이티브 구현 완료 후 MethodChannel이 자동으로 연결됩니다.
class WatchSyncService {
  static const MethodChannel _channel =
      MethodChannel('com.rhythmicaleskimo.healthApp/watch');

  // 워치 → 앱 이벤트를 위한 StreamController
  final _setCompletionController =
      StreamController<SetCompletionEvent>.broadcast();

  WatchSyncService() {
    // 네이티브에서 보내는 세트 완료 이벤트를 수신
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// 네이티브 콜백 처리
  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'setCompleted':
        try {
          final raw = call.arguments;
          final Map<String, dynamic> data;
          if (raw is Map) {
            data = Map<String, dynamic>.from(raw);
          } else if (raw is String) {
            data = json.decode(raw) as Map<String, dynamic>;
          } else {
            return;
          }
          _setCompletionController.add(SetCompletionEvent.fromJson(data));
        } catch (_) {
          // 파싱 오류 무시
        }
    }
  }

  // ── 워치로 데이터 전송 ────────────────────────────────────────────────────

  /// 현재 운동 세션 데이터를 워치로 전송
  ///
  /// [session] 현재 진행 중인 운동 세션 상태
  /// 네이티브 구현 전까지는 PlatformException을 무시합니다.
  Future<void> sendWorkoutToWatch(WorkoutSessionState session) async {
    try {
      if (session.exercises.isEmpty) return;

      // 가장 마지막에 추가된 운동과 미완료 세트 찾기
      final lastExercise = session.exercises.last;
      final pendingSet = lastExercise.sets
          .where((s) => !s.isCompleted)
          .toList()
          .firstOrNull;

      if (pendingSet == null) return;

      final data = WatchWorkoutData(
        exerciseName: lastExercise.name,
        setNumber: pendingSet.setNumber,
        targetReps: pendingSet.reps,
        targetWeight: pendingSet.weight,
        restSeconds: session.restTimerSeconds,
      );

      await _channel.invokeMethod<void>(
        'sendWorkoutToWatch',
        data.toJson(),
      );
    } on PlatformException {
      // 네이티브 미구현 시 무시
    } catch (_) {
      // 기타 오류 무시
    }
  }

  /// 워치에서 수신한 세트 완료 이벤트 스트림
  ///
  /// 워치에서 세트를 완료하면 이 스트림으로 이벤트가 전달됩니다.
  /// UI에서 ref.listen 또는 StreamProvider로 구독하세요.
  Stream<SetCompletionEvent> receiveSetCompletion() =>
      _setCompletionController.stream;

  /// 휴식 타이머 남은 시간을 워치로 동기화
  ///
  /// [seconds] 남은 휴식 시간 (초)
  Future<void> sendRestTimerToWatch(int seconds) async {
    try {
      await _channel.invokeMethod<void>('sendRestTimerToWatch', seconds);
    } on PlatformException {
      // 네이티브 미구현 시 무시
    } catch (_) {
      // 기타 오류 무시
    }
  }

  /// 워치 연결 여부 확인
  ///
  /// 네이티브 구현 완료 전까지 항상 false를 반환합니다.
  Future<bool> isWatchConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWatchConnected');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _setCompletionController.close();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// WatchSyncService 싱글톤 Provider
final watchSyncServiceProvider = Provider<WatchSyncService>((ref) {
  final service = WatchSyncService();
  ref.onDispose(service.dispose);
  return service;
});

/// 워치 연결 상태 Provider
///
/// 네이티브 구현 전까지 항상 false를 반환합니다.
/// 네이티브 구현 완료 후 자동으로 실제 값을 반환합니다.
final watchConnectedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(watchSyncServiceProvider);
  return service.isWatchConnected();
});

/// 워치로부터 받은 세트 완료 이벤트 스트림 Provider
final watchSetCompletionProvider = StreamProvider<SetCompletionEvent>((ref) {
  final service = ref.watch(watchSyncServiceProvider);
  return service.receiveSetCompletion();
});
