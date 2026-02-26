// 신체 측정 기록 화면 – 줄자 둘레 값 시계열 추적
// 자체 StateNotifier + SharedPreferences 영속성 포함
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Enums & Models
// ---------------------------------------------------------------------------

/// 측정 부위 열거형
enum MeasurementType {
  neck,
  shoulders,
  chest,
  leftBicep,
  rightBicep,
  waist,
  hips,
  leftThigh,
  rightThigh,
  leftCalf,
  rightCalf;

  String get label {
    switch (this) {
      case MeasurementType.neck:
        return '목 둘레'; // TODO: l10n
      case MeasurementType.shoulders:
        return '어깨 너비'; // TODO: l10n
      case MeasurementType.chest:
        return '가슴 둘레'; // TODO: l10n
      case MeasurementType.leftBicep:
        return '왼팔 둘레'; // TODO: l10n
      case MeasurementType.rightBicep:
        return '오른팔 둘레'; // TODO: l10n
      case MeasurementType.waist:
        return '허리 둘레'; // TODO: l10n
      case MeasurementType.hips:
        return '엉덩이 둘레'; // TODO: l10n
      case MeasurementType.leftThigh:
        return '왼쪽 허벅지'; // TODO: l10n
      case MeasurementType.rightThigh:
        return '오른쪽 허벅지'; // TODO: l10n
      case MeasurementType.leftCalf:
        return '왼쪽 종아리'; // TODO: l10n
      case MeasurementType.rightCalf:
        return '오른쪽 종아리'; // TODO: l10n
    }
  }

  String get unit => 'cm';
}

/// 기본으로 표시할 측정 부위 (Show More 전)
const _commonMeasurements = [
  MeasurementType.chest,
  MeasurementType.waist,
  MeasurementType.hips,
  MeasurementType.rightBicep,
  MeasurementType.rightThigh,
];

/// 단일 측정 기록
class BodyMeasurement {
  final String id;
  final DateTime date;
  final Map<MeasurementType, double> measurements;
  final String? notes;

  const BodyMeasurement({
    required this.id,
    required this.date,
    required this.measurements,
    this.notes,
  });

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    Map<MeasurementType, double>? measurements,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      measurements: measurements ?? this.measurements,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'measurements': measurements.map(
          (k, v) => MapEntry(k.name, v),
        ),
        'notes': notes,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    final rawMeasurements =
        (json['measurements'] as Map<String, dynamic>? ?? {});
    final measurements = <MeasurementType, double>{};
    for (final entry in rawMeasurements.entries) {
      try {
        final type = MeasurementType.values.firstWhere(
          (e) => e.name == entry.key,
        );
        measurements[type] = (entry.value as num).toDouble();
      } catch (_) {
        // 알 수 없는 타입 무시
      }
    }
    return BodyMeasurement(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      measurements: measurements,
      notes: json['notes'] as String?,
    );
  }
}

/// 전체 상태
class BodyMeasurementsState {
  final List<BodyMeasurement> records;

  const BodyMeasurementsState({this.records = const []});

  BodyMeasurementsState copyWith({List<BodyMeasurement>? records}) {
    return BodyMeasurementsState(records: records ?? this.records);
  }

  Map<String, dynamic> toJson() => {
        'records': records.map((r) => r.toJson()).toList(),
      };

  factory BodyMeasurementsState.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementsState(
        records: (json['records'] as List<dynamic>? ?? [])
            .map((r) => BodyMeasurement.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// StateNotifier
// ---------------------------------------------------------------------------

const _kBodyMeasurementsKey = 'body_measurements';
const _uuid = Uuid();

class BodyMeasurementsNotifier
    extends StateNotifier<BodyMeasurementsState> {
  BodyMeasurementsNotifier() : super(const BodyMeasurementsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBodyMeasurementsKey);
      if (raw != null) {
        state = BodyMeasurementsState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kBodyMeasurementsKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void addMeasurement({
    required Map<MeasurementType, double> measurements,
    String? notes,
    DateTime? date,
  }) {
    final record = BodyMeasurement(
      id: _uuid.v4(),
      date: date ?? DateTime.now(),
      measurements: measurements,
      notes: notes,
    );
    // 날짜 내림차순 정렬
    final updated = [...state.records, record]
      ..sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(records: updated);
    _save();
  }

  void deleteMeasurement(String id) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
    _save();
  }

  /// 특정 부위의 측정 이력 반환 (날짜 오름차순)
  List<MapEntry<DateTime, double>> getHistory(MeasurementType type) {
    return state.records
        .where((r) => r.measurements.containsKey(type))
        .map((r) => MapEntry(r.date, r.measurements[type]!))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  /// 최신 vs 이전 변화량 반환 (null이면 데이터 부족)
  double? getLatestChange(MeasurementType type) {
    final history = getHistory(type);
    if (history.length < 2) return null;
    return history.last.value - history[history.length - 2].value;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bodyMeasurementsProvider =
    StateNotifierProvider<BodyMeasurementsNotifier, BodyMeasurementsState>(
  (ref) => BodyMeasurementsNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신체 측정'), // TODO: l10n
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기록'), // TODO: l10n
            Tab(text: '히스토리'), // TODO: l10n
            Tab(text: '차트'), // TODO: l10n
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RecordTab(),
          _HistoryTab(),
          _ChartsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Record
// ---------------------------------------------------------------------------

class _RecordTab extends ConsumerStatefulWidget {
  const _RecordTab();

  @override
  ConsumerState<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends ConsumerState<_RecordTab> {
  final Map<MeasurementType, TextEditingController> _controllers = {};
  final _notesController = TextEditingController();
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    for (final type in MeasurementType.values) {
      _controllers[type] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  List<MeasurementType> get _visibleTypes =>
      _showAll ? MeasurementType.values.toList() : _commonMeasurements;

  void _submit() {
    final measurements = <MeasurementType, double>{};
    for (final type in MeasurementType.values) {
      final text = _controllers[type]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null && value > 0) {
          measurements[type] = value;
        }
      }
    }

    if (measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 하나의 측정값을 입력하세요')), // TODO: l10n
      );
      return;
    }

    ref.read(bodyMeasurementsProvider.notifier).addMeasurement(
          measurements: measurements,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    // 입력 초기화
    for (final c in _controllers.values) {
      c.clear();
    }
    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('측정값이 저장되었습니다')), // TODO: l10n
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 표시
          Text(
            DateFormat('yyyy년 M월 d일').format(DateTime.now()), // TODO: l10n
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // 측정 필드
          ..._visibleTypes.map((type) {
            final change = ref
                .read(bodyMeasurementsProvider.notifier)
                .getLatestChange(type);
            return _MeasurementField(
              type: type,
              controller: _controllers[type]!,
              lastChange: change,
            );
          }),
          // Show All 토글
          TextButton.icon(
            onPressed: () => setState(() => _showAll = !_showAll),
            icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
            label: Text(_showAll ? '접기' : '모두 보기'), // TODO: l10n
          ),
          const SizedBox(height: 8),
          // 메모
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: '메모 (선택)', // TODO: l10n
              border: OutlineInputBorder(),
              hintText: '오늘의 컨디션, 특이사항 등', // TODO: l10n
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('저장'), // TODO: l10n
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 측정 필드 위젯
class _MeasurementField extends StatelessWidget {
  final MeasurementType type;
  final TextEditingController controller;
  final double? lastChange;

  const _MeasurementField({
    required this.type,
    required this.controller,
    this.lastChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: type.label,
                suffixText: type.unit,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (lastChange != null) ...[
            const SizedBox(width: 8),
            _ChangeIndicator(change: lastChange!),
          ],
        ],
      ),
    );
  }
}

/// 변화량 색상 표시 위젯
class _ChangeIndicator extends StatelessWidget {
  final double change;

  const _ChangeIndicator({required this.change});

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final arrow = isPositive ? '↑' : '↓';
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$sign${change.toStringAsFixed(1)}cm $arrow',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: History
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bodyMeasurementsProvider);
    final notifier = ref.read(bodyMeasurementsProvider.notifier);

    if (state.records.isEmpty) {
      return const Center(
        child: Text('기록이 없습니다. 측정값을 입력해보세요'), // TODO: l10n
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.records.length,
      itemBuilder: (context, index) {
        final record = state.records[index];
        return _HistoryCard(
          record: record,
          onDelete: () => notifier.deleteMeasurement(record.id),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BodyMeasurement record;
  final VoidCallback onDelete;

  const _HistoryCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(record.date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: record.measurements.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key.label}: ${entry.value.toStringAsFixed(1)}cm',
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: const EdgeInsets.all(0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Charts
// ---------------------------------------------------------------------------

class _ChartsTab extends ConsumerStatefulWidget {
  const _ChartsTab();

  @override
  ConsumerState<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends ConsumerState<_ChartsTab> {
  MeasurementType _selectedType = MeasurementType.waist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(bodyMeasurementsProvider.notifier);
    ref.watch(bodyMeasurementsProvider); // 상태 변화 감지

    final history = notifier.getHistory(_selectedType);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 측정 부위 선택 드롭다운
          DropdownButtonFormField<MeasurementType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: '측정 부위', // TODO: l10n
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: MeasurementType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: (type) {
              if (type != null) setState(() => _selectedType = type);
            },
          ),
          const SizedBox(height: 24),
          // 차트
          if (history.length < 2)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '데이터가 2개 이상 있어야 차트를 볼 수 있습니다', // TODO: l10n
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // 최신 변화량 표시
            _buildSummaryRow(theme, notifier, history),
            const SizedBox(height: 16),
            // fl_chart 라인 차트
            Expanded(
              child: _MeasurementLineChart(
                history: history,
                type: _selectedType,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    BodyMeasurementsNotifier notifier,
    List<MapEntry<DateTime, double>> history,
  ) {
    final change = notifier.getLatestChange(_selectedType);
    final latest = history.last.value;

    return Row(
      children: [
        // 최신 값
        Expanded(
          child: _StatChip(
            label: '현재', // TODO: l10n
            value: '${latest.toStringAsFixed(1)}cm',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        // 변화량
        if (change != null)
          Expanded(
            child: _StatChip(
              label: '변화', // TODO: l10n
              value: '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}cm',
              color: change > 0 ? Colors.green : Colors.red,
            ),
          ),
        const SizedBox(width: 8),
        // 측정 횟수
        Expanded(
          child: _StatChip(
            label: '기록 수', // TODO: l10n
            value: '${history.length}회',
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// fl_chart Line Chart
// ---------------------------------------------------------------------------

class _MeasurementLineChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> history;
  final MeasurementType type;

  const _MeasurementLineChart({
    required this.history,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    // x축: 날짜 인덱스, y축: 측정값(cm)
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = history.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxY = history.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) < 2 ? 2.0 : (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: history.length > 6
                  ? (history.length / 4).floorToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                final date = history[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor),
            left: BorderSide(color: theme.dividerColor),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final index = s.x.toInt();
                final date = index < history.length
                    ? history[index].key
                    : DateTime.now();
                return LineTooltipItem(
                  '${DateFormat('MM/dd').format(date)}\n${s.y.toStringAsFixed(1)}cm',
                  TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
