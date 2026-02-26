// 연결 상태 서비스 - 오프라인 감지 + 동기화 큐 관리
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// SyncOperation 모델
// ---------------------------------------------------------------------------

/// 오프라인 상태에서 대기 중인 동기화 작업 타입
enum SyncOperationType {
  workout,
  weight,
  water,
  diet,
  bodyMeasurement,
}

/// 오프라인 큐에 저장되는 동기화 작업
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  @override
  String toString() =>
      'SyncOperation(id: $id, type: ${type.name}, createdAt: $createdAt)';
}

// ---------------------------------------------------------------------------
// ConnectivityService
// ---------------------------------------------------------------------------

/// 인터넷 연결 상태를 모니터링하고 오프라인 동기화 큐를 관리하는 서비스
class ConnectivityService {
  // 내부 상태
  bool _isOnline = true;
  final List<SyncOperation> _syncQueue = [];

  // 스트림 컨트롤러
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  // 주기적 체크 타이머 (30초마다)
  Timer? _pollingTimer;

  // 외부에서 추가 작업 등록 콜백
  final List<Future<void> Function(List<SyncOperation>)> _processCallbacks =
      [];

  ConnectivityService() {
    _startPolling();
  }

  // ---------------------------------------------------------------------------
  // 공개 API
  // ---------------------------------------------------------------------------

  /// 현재 온라인 여부
  bool get isOnline => _isOnline;

  /// 온라인 상태 스트림
  Stream<bool> get onlineStream => _controller.stream;

  /// 대기 중인 동기화 작업 목록 (읽기 전용)
  List<SyncOperation> get pendingOperations =>
      List.unmodifiable(_syncQueue);

  /// 대기 중인 작업 수
  int get pendingCount => _syncQueue.length;

  /// 동기화 큐에 작업 추가
  void addToQueue(SyncOperation operation) {
    _syncQueue.add(operation);
  }

  /// 큐 처리 콜백 등록 (온라인 복귀 시 호출됨)
  void registerProcessCallback(
    Future<void> Function(List<SyncOperation>) callback,
  ) {
    _processCallbacks.add(callback);
  }

  /// 특정 작업 큐에서 제거
  void removeFromQueue(String operationId) {
    _syncQueue.removeWhere((op) => op.id == operationId);
  }

  /// 앱이 포그라운드로 돌아왔을 때 즉시 연결 확인
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  // ---------------------------------------------------------------------------
  // 내부 구현
  // ---------------------------------------------------------------------------

  void _startPolling() {
    // 즉시 첫 체크 수행
    _checkConnectivity();

    // 30초마다 주기적 체크
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      // DNS 조회로 실제 인터넷 연결 여부 확인
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final nowOnline = result.isNotEmpty && result.first.rawAddress.isNotEmpty;

      if (nowOnline != _isOnline) {
        _isOnline = nowOnline;
        _controller.add(_isOnline);

        // 온라인으로 복귀 시 큐 처리
        if (_isOnline && _syncQueue.isNotEmpty) {
          await _processQueue();
        }
      }
    } on SocketException {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    } on TimeoutException {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    } catch (_) {
      // 기타 오류 시 상태 변경 없음
    }
  }

  Future<void> _processQueue() async {
    if (_syncQueue.isEmpty || _processCallbacks.isEmpty) return;

    final operations = List<SyncOperation>.from(_syncQueue);
    for (final callback in _processCallbacks) {
      try {
        await callback(operations);
      } catch (_) {
        // 처리 콜백 실패 시 큐 유지
        return;
      }
    }

    // 처리 완료된 작업 제거
    _syncQueue.clear();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// ConnectivityService 싱글턴 Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// 온라인 여부 StreamProvider
/// true = 온라인, false = 오프라인
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // 현재 상태를 초기값으로 즉시 방출한 뒤 스트림 구독
  return Stream.value(service.isOnline)
      .asyncExpand((_) => service.onlineStream.startWith(service.isOnline));
});

/// 대기 중인 동기화 작업 수 Provider
final pendingOperationsCountProvider = Provider<int>((ref) {
  // connectivityProvider 변화 시 재계산
  ref.watch(connectivityProvider);
  final service = ref.read(connectivityServiceProvider);
  return service.pendingCount;
});

// Stream.startWith 확장 메서드
extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) {
    return Stream<T>.multi((controller) {
      controller.add(value);
      listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    });
  }
}
