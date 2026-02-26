// Apple Health / Google Fit 동기화 설정 화면
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/services/health_sync_service.dart';

// ---------------------------------------------------------------------------
// HealthSyncScreen
// ---------------------------------------------------------------------------

class HealthSyncScreen extends ConsumerStatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  ConsumerState<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends ConsumerState<HealthSyncScreen> {
  bool _isSyncing = false;
  String? _syncError;
  int? _stepsToday;
  List<int> _heartRates = [];
  Duration? _sleepLast;
  bool _dataLoaded = false;

  // 플랫폼 이름
  String get _platformName => Platform.isIOS ? 'Apple Health' : 'Google Fit';
  IconData get _platformIcon =>
      Platform.isIOS ? Icons.favorite : Icons.directions_run;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final service = ref.read(healthSyncServiceProvider);
    final hasPermission = await service.hasPermissions();
    if (!hasPermission) {
      setState(() => _dataLoaded = true);
      return;
    }

    try {
      final steps = await service.readStepsToday();
      final heartRates = await service.readHeartRateToday();
      final sleep = await service.readSleepLastNight();

      if (mounted) {
        setState(() {
          _stepsToday = steps;
          _heartRates = heartRates;
          _sleepLast = sleep;
          _dataLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dataLoaded = true);
      }
    }
  }

  Future<void> _requestPermissions() async {
    final service = ref.read(healthSyncServiceProvider);
    final granted = await service.requestPermissions();

    if (!mounted) return;

    if (granted) {
      // 권한 획득 후 Provider 갱신
      ref.invalidate(healthPermissionGrantedProvider);
      await _loadHealthData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연동 권한이 허용되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('권한이 거부되었습니다. 설정 앱에서 직접 허용해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      final service = ref.read(healthSyncServiceProvider);
      await service.setLastSyncTime(DateTime.now());
      await _loadHealthData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('동기화가 완료되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncError = '동기화 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permissionAsync = ref.watch(healthPermissionGrantedProvider);
    final availableAsync = ref.watch(healthAvailableProvider);
    final config = ref.watch(healthSyncConfigProvider);
    final configNotifier = ref.read(healthSyncConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_platformName 연동'),
        elevation: 0,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: '지금 동기화',
              onPressed: _syncNow,
            ),
        ],
      ),
      body: availableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('오류가 발생했습니다')),
        data: (available) {
          if (!available) {
            return const _UnavailableView();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 연결 상태 헤더 카드
              permissionAsync.when(
                loading: () => const _StatusCardSkeleton(),
                error: (e, s) => _StatusCard(
                  granted: false,
                  platformName: _platformName,
                  platformIcon: _platformIcon,
                  onConnect: _requestPermissions,
                ),
                data: (granted) => _StatusCard(
                  granted: granted,
                  platformName: _platformName,
                  platformIcon: _platformIcon,
                  onConnect: _requestPermissions,
                ),
              ),

              const SizedBox(height: 16),

              // 에러 표시
              if (_syncError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ErrorBanner(message: _syncError!),
                ),

              // 오늘의 데이터 카드
              permissionAsync.maybeWhen(
                data: (granted) => granted && _dataLoaded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: '오늘의 건강 데이터',
                            icon: Icons.monitor_heart_outlined,
                            color: Colors.pink,
                          ),
                          const SizedBox(height: 8),
                          _HealthDataGrid(
                            stepsToday: _stepsToday,
                            heartRates: _heartRates,
                            sleepDuration: _sleepLast,
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // 동기화 항목 설정
              _SectionHeader(
                title: '동기화 항목',
                icon: Icons.tune_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _SyncToggleTile(
                      icon: Icons.directions_walk,
                      iconColor: Colors.green,
                      title: '걸음 수',
                      subtitle: '오늘의 걸음 수를 읽어옵니다',
                      value: config.stepsEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(stepsEnabled: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SyncToggleTile(
                      icon: Icons.fitness_center,
                      iconColor: Colors.deepOrange,
                      title: '운동 기록',
                      subtitle: '운동 세션을 자동으로 기록합니다',
                      value: config.workoutsEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(workoutsEnabled: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SyncToggleTile(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: Colors.indigo,
                      title: '체중',
                      subtitle: '체중 기록을 동기화합니다',
                      value: config.weightEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(weightEnabled: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SyncToggleTile(
                      icon: Icons.water_drop_outlined,
                      iconColor: Colors.cyan,
                      title: '수분 섭취',
                      subtitle: '물 섭취량을 동기화합니다',
                      value: config.waterEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(waterEnabled: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SyncToggleTile(
                      icon: Icons.bedtime_outlined,
                      iconColor: Colors.deepPurple,
                      title: '수면',
                      subtitle: '수면 데이터를 읽어옵니다',
                      value: config.sleepEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(sleepEnabled: v),
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SyncToggleTile(
                      icon: Icons.favorite_outline,
                      iconColor: Colors.red,
                      title: '심박수',
                      subtitle: '심박수 데이터를 읽어옵니다',
                      value: config.heartRateEnabled,
                      onChanged: (v) => configNotifier.update(
                        config.copyWith(heartRateEnabled: v),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 마지막 동기화 시간
              _LastSyncWidget(service: ref.read(healthSyncServiceProvider)),

              const SizedBox(height: 16),

              // 지금 동기화 버튼
              FilledButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? '동기화 중...' : '지금 동기화'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 서브 위젯들
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  final bool granted;
  final String platformName;
  final IconData platformIcon;
  final VoidCallback onConnect;

  const _StatusCard({
    required this.granted,
    required this.platformName,
    required this.platformIcon,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = granted ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      color: statusColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(platformIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        granted ? Icons.check_circle : Icons.warning_amber,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        granted ? '연동됨' : '권한 필요',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!granted)
              TextButton(
                onPressed: onConnect,
                child: const Text('연동하기'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(height: 80),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HealthDataGrid extends StatelessWidget {
  final int? stepsToday;
  final List<int> heartRates;
  final Duration? sleepDuration;

  const _HealthDataGrid({
    this.stepsToday,
    required this.heartRates,
    this.sleepDuration,
  });

  @override
  Widget build(BuildContext context) {
    final avgHr = heartRates.isEmpty
        ? null
        : heartRates.reduce((a, b) => a + b) ~/ heartRates.length;

    return Row(
      children: [
        Expanded(
          child: _DataTile(
            icon: Icons.directions_walk,
            iconColor: Colors.green,
            label: '걸음 수',
            value: stepsToday != null
                ? '${_formatNumber(stepsToday!)} 걸음'
                : '데이터 없음',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DataTile(
            icon: Icons.favorite,
            iconColor: Colors.red,
            label: '평균 심박수',
            value: avgHr != null ? '$avgHr bpm' : '데이터 없음',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DataTile(
            icon: Icons.bedtime,
            iconColor: Colors.deepPurple,
            label: '수면 시간',
            value: sleepDuration != null
                ? '${sleepDuration!.inHours}시간 ${sleepDuration!.inMinutes % 60}분'
                : '데이터 없음',
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(1)}만';
    }
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final hundreds = n % 1000;
      return '$thousands,${hundreds.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DataTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _SyncToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SyncToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _LastSyncWidget extends StatefulWidget {
  final HealthSyncService service;

  const _LastSyncWidget({required this.service});

  @override
  State<_LastSyncWidget> createState() => _LastSyncWidgetState();
}

class _LastSyncWidgetState extends State<_LastSyncWidget> {
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await widget.service.getLastSyncTime();
    if (mounted) {
      setState(() => _lastSync = t);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _lastSync == null
            ? '아직 동기화하지 않았습니다'
            : '마지막 동기화: ${_formatTime(_lastSync!)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '이 기기에서 건강 데이터 연동을 지원하지 않습니다',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'iOS(Apple Health) 또는 Android(Google Fit) 기기에서 이용 가능합니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
