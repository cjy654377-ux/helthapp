// 근육 회복 히트맵 화면
// CustomPainter 기반 신체 다이어그램 (앞면/뒷면)
// 회복 상태별 색상 코딩: 녹색(완전 회복) / 노랑(부분 회복) / 빨강(피로) / 회색(미자극)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/core/models/workout_model.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';

// ---------------------------------------------------------------------------
// 회복 상태 열거형
// ---------------------------------------------------------------------------

enum RecoveryStatus {
  recovered,   // 녹색: 72시간+ 경과 (완전 회복)
  partial,     // 노랑: 24-72시간 (부분 회복)
  fatigued,    // 빨강: 24시간 미만 (피로)
  untrained;   // 회색: 최근 자극 기록 없음

  Color get color {
    switch (this) {
      case RecoveryStatus.recovered:
        return const Color(0xFF4CAF50);
      case RecoveryStatus.partial:
        return const Color(0xFFFF9800);
      case RecoveryStatus.fatigued:
        return const Color(0xFFF44336);
      case RecoveryStatus.untrained:
        return const Color(0xFFBDBDBD);
    }
  }

  String get label {
    switch (this) {
      case RecoveryStatus.recovered:
        return 'Recovered'; // TODO: l10n
      case RecoveryStatus.partial:
        return 'Recovering'; // TODO: l10n
      case RecoveryStatus.fatigued:
        return 'Fatigued'; // TODO: l10n
      case RecoveryStatus.untrained:
        return 'Not Trained'; // TODO: l10n
    }
  }
}

// ---------------------------------------------------------------------------
// 근육 회복 데이터 모델
// ---------------------------------------------------------------------------

class MuscleRecoveryData {
  final BodyPart bodyPart;
  final RecoveryStatus status;
  final DateTime? lastWorkoutDate;
  final List<String> lastExercises; // 최근 운동 이름들
  final Duration? timeSinceWorkout;

  const MuscleRecoveryData({
    required this.bodyPart,
    required this.status,
    this.lastWorkoutDate,
    this.lastExercises = const [],
    this.timeSinceWorkout,
  });

  /// 권장 다음 운동 날짜
  DateTime? get recommendedNextWorkout {
    if (lastWorkoutDate == null) return null;
    // 72시간 후 완전 회복
    return lastWorkoutDate!.add(const Duration(hours: 72));
  }
}

// ---------------------------------------------------------------------------
// 회복 계산 Provider
// ---------------------------------------------------------------------------

final muscleRecoveryProvider =
    Provider<Map<BodyPart, MuscleRecoveryData>>((ref) {
  final history = ref.watch(workoutHistoryProvider);
  final now = DateTime.now();

  // 각 부위별 마지막 운동 날짜와 운동 이름을 추적
  final lastWorkout = <BodyPart, DateTime>{};
  final lastExercises = <BodyPart, List<String>>{};

  // 히스토리를 최신순으로 순회하여 마지막 운동 기록 찾기
  for (final record in history) {
    for (final exercise in record.exercises) {
      final part = exercise.bodyPart;
      if (!lastWorkout.containsKey(part)) {
        // 이 부위의 가장 최근 기록
        lastWorkout[part] = record.date;
        lastExercises[part] = [exercise.name];
      } else if (record.date == lastWorkout[part]) {
        // 같은 날 다른 운동도 수집
        lastExercises[part]!.add(exercise.name);
      }
    }
  }

  // 결과 맵 생성
  final result = <BodyPart, MuscleRecoveryData>{};
  // 히트맵에 표시할 부위 목록
  const displayParts = [
    BodyPart.chest,
    BodyPart.back,
    BodyPart.shoulders,
    BodyPart.biceps,
    BodyPart.triceps,
    BodyPart.abs,
    BodyPart.quadriceps,
    BodyPart.hamstrings,
    BodyPart.calves,
    BodyPart.glutes,
    BodyPart.forearms,
  ];

  for (final part in displayParts) {
    final lastDate = lastWorkout[part];
    if (lastDate == null) {
      result[part] = MuscleRecoveryData(
        bodyPart: part,
        status: RecoveryStatus.untrained,
      );
      continue;
    }

    final elapsed = now.difference(lastDate);
    RecoveryStatus status;
    if (elapsed.inHours < 24) {
      status = RecoveryStatus.fatigued;
    } else if (elapsed.inHours < 72) {
      status = RecoveryStatus.partial;
    } else {
      status = RecoveryStatus.recovered;
    }

    result[part] = MuscleRecoveryData(
      bodyPart: part,
      status: status,
      lastWorkoutDate: lastDate,
      lastExercises: lastExercises[part] ?? [],
      timeSinceWorkout: elapsed,
    );
  }

  return result;
});

/// 피로도 상위 3개 근육 (fatigued > partial 우선순위)
final top3FatiguedMusclesProvider =
    Provider<List<MuscleRecoveryData>>((ref) {
  final recoveryMap = ref.watch(muscleRecoveryProvider);
  final sorted = recoveryMap.values.toList()
    ..sort((a, b) {
      // fatigued > partial > recovered > untrained
      final order = {
        RecoveryStatus.fatigued: 0,
        RecoveryStatus.partial: 1,
        RecoveryStatus.recovered: 2,
        RecoveryStatus.untrained: 3,
      };
      final orderA = order[a.status] ?? 4;
      final orderB = order[b.status] ?? 4;
      if (orderA != orderB) return orderA.compareTo(orderB);
      // 같은 상태면 더 최근에 운동한 것 우선
      if (a.lastWorkoutDate != null && b.lastWorkoutDate != null) {
        return b.lastWorkoutDate!.compareTo(a.lastWorkoutDate!);
      }
      return 0;
    });
  return sorted.take(3).toList();
});

// ---------------------------------------------------------------------------
// RecoveryHeatmapScreen
// ---------------------------------------------------------------------------

class RecoveryHeatmapScreen extends ConsumerStatefulWidget {
  const RecoveryHeatmapScreen({super.key});

  @override
  ConsumerState<RecoveryHeatmapScreen> createState() =>
      _RecoveryHeatmapScreenState();
}

class _RecoveryHeatmapScreenState
    extends ConsumerState<RecoveryHeatmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BodyPart? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recoveryMap = ref.watch(muscleRecoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recovery Heatmap', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Front'), // TODO: l10n
            Tab(text: 'Back'),  // TODO: l10n
          ],
        ),
      ),
      body: Column(
        children: [
          // 범례
          _buildLegend(),

          // 신체 다이어그램
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BodyDiagramView(
                  isFront: true,
                  recoveryMap: recoveryMap,
                  selectedMuscle: _selectedMuscle,
                  onMuscleSelected: _onMuscleSelected,
                ),
                _BodyDiagramView(
                  isFront: false,
                  recoveryMap: recoveryMap,
                  selectedMuscle: _selectedMuscle,
                  onMuscleSelected: _onMuscleSelected,
                ),
              ],
            ),
          ),

          // 선택된 근육 상세 정보
          if (_selectedMuscle != null && recoveryMap[_selectedMuscle] != null)
            _MuscleDetailPanel(
              data: recoveryMap[_selectedMuscle]!,
              onDismiss: () => setState(() => _selectedMuscle = null),
            ),
        ],
      ),
    );
  }

  void _onMuscleSelected(BodyPart part) {
    setState(() {
      _selectedMuscle = _selectedMuscle == part ? null : part;
    });
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: RecoveryStatus.values.map((status) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                status.label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body Diagram View (앞면/뒷면 전환 가능)
// ---------------------------------------------------------------------------

class _BodyDiagramView extends StatelessWidget {
  final bool isFront;
  final Map<BodyPart, MuscleRecoveryData> recoveryMap;
  final BodyPart? selectedMuscle;
  final ValueChanged<BodyPart> onMuscleSelected;

  const _BodyDiagramView({
    required this.isFront,
    required this.recoveryMap,
    required this.selectedMuscle,
    required this.onMuscleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _BodyDiagramPainter(
              isFront: isFront,
              recoveryMap: recoveryMap,
              selectedMuscle: selectedMuscle,
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset position, Size size) {
    final bodyPart = _BodyDiagramPainter.hitTestMuscle(position, size, isFront);
    if (bodyPart != null) {
      onMuscleSelected(bodyPart);
    }
  }
}

// ---------------------------------------------------------------------------
// Body Diagram CustomPainter
// ---------------------------------------------------------------------------

class _BodyDiagramPainter extends CustomPainter {
  final bool isFront;
  final Map<BodyPart, MuscleRecoveryData> recoveryMap;
  final BodyPart? selectedMuscle;

  const _BodyDiagramPainter({
    required this.isFront,
    required this.recoveryMap,
    required this.selectedMuscle,
  });

  // 신체 부위별 상대 좌표 (0-1 범위, 400x700 기준 캔버스)
  // 앞면/뒷면 구분하여 위치 정의
  static Map<BodyPart, List<Offset>> _frontMusclePoints(Size size) {
    final w = size.width;
    final h = size.height;
    return {
      BodyPart.chest:      [Offset(w * 0.50, h * 0.27)],
      BodyPart.shoulders:  [Offset(w * 0.35, h * 0.23), Offset(w * 0.65, h * 0.23)],
      BodyPart.biceps:     [Offset(w * 0.28, h * 0.32), Offset(w * 0.72, h * 0.32)],
      BodyPart.triceps:    [Offset(w * 0.25, h * 0.36), Offset(w * 0.75, h * 0.36)],
      BodyPart.forearms:   [Offset(w * 0.23, h * 0.43), Offset(w * 0.77, h * 0.43)],
      BodyPart.abs:        [Offset(w * 0.50, h * 0.37)],
      BodyPart.quadriceps: [Offset(w * 0.42, h * 0.60), Offset(w * 0.58, h * 0.60)],
      BodyPart.calves:     [Offset(w * 0.43, h * 0.78), Offset(w * 0.57, h * 0.78)],
    };
  }

  static Map<BodyPart, List<Offset>> _backMusclePoints(Size size) {
    final w = size.width;
    final h = size.height;
    return {
      BodyPart.back:       [Offset(w * 0.50, h * 0.30)],
      BodyPart.shoulders:  [Offset(w * 0.35, h * 0.23), Offset(w * 0.65, h * 0.23)],
      BodyPart.triceps:    [Offset(w * 0.28, h * 0.32), Offset(w * 0.72, h * 0.32)],
      BodyPart.forearms:   [Offset(w * 0.24, h * 0.40), Offset(w * 0.76, h * 0.40)],
      BodyPart.glutes:     [Offset(w * 0.42, h * 0.50), Offset(w * 0.58, h * 0.50)],
      BodyPart.hamstrings: [Offset(w * 0.42, h * 0.62), Offset(w * 0.58, h * 0.62)],
      BodyPart.calves:     [Offset(w * 0.43, h * 0.78), Offset(w * 0.57, h * 0.78)],
    };
  }

  /// 터치 히트 테스트 - 터치 좌표가 어느 근육 영역에 속하는지 반환
  static BodyPart? hitTestMuscle(Offset position, Size size, bool isFront) {
    final points = isFront
        ? _frontMusclePoints(size)
        : _backMusclePoints(size);
    const hitRadius = 36.0;

    for (final entry in points.entries) {
      for (final point in entry.value) {
        if ((position - point).distance <= hitRadius) {
          return entry.key;
        }
      }
    }
    return null;
  }

  Color _getColor(BodyPart part) {
    return recoveryMap[part]?.status.color ?? RecoveryStatus.untrained.color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black12;

    // ── 몸통 실루엣 그리기 ────────────────────────────────────────────────
    _drawBodySilhouette(canvas, size, outlinePaint);

    // ── 근육 그룹 원형 표시 ───────────────────────────────────────────────
    final musclePoints =
        isFront ? _frontMusclePoints(size) : _backMusclePoints(size);

    for (final entry in musclePoints.entries) {
      final part = entry.key;
      final color = _getColor(part);
      final isSelected = part == selectedMuscle;

      for (final center in entry.value) {
        // 선택된 근육은 더 크게 + 테두리 강조
        final radius = isSelected ? 28.0 : 22.0;

        // 그림자 효과
        final shadowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(center, radius + 4, shadowPaint);

        // 근육 원형
        paint.color = color.withValues(alpha: 0.85);
        canvas.drawCircle(center, radius, paint);

        // 테두리
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1.5
          ..color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6);
        canvas.drawCircle(center, radius, borderPaint);
      }
    }

    // ── 근육 이름 레이블 그리기 ───────────────────────────────────────────
    for (final entry in musclePoints.entries) {
      final part = entry.key;
      final isSelected = part == selectedMuscle;

      // 여러 포인트의 중심을 레이블 위치로 사용
      final avgX = entry.value.map((o) => o.dx).reduce((a, b) => a + b) /
          entry.value.length;
      final avgY = entry.value.map((o) => o.dy).reduce((a, b) => a + b) /
          entry.value.length;

      // 레이블 위치 (원 아래쪽)
      final labelPos = Offset(avgX, avgY + 30);

      _drawLabel(canvas, part.label, labelPos, isSelected);
    }
  }

  void _drawBodySilhouette(Canvas canvas, Size size, Paint outline) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    if (isFront) {
      // 앞면 실루엣: 머리, 목, 몸통, 팔, 다리
      _drawFrontSilhouette(canvas, w, h, bodyPaint, outline);
    } else {
      // 뒷면 실루엣
      _drawBackSilhouette(canvas, w, h, bodyPaint, outline);
    }
  }

  void _drawFrontSilhouette(
      Canvas canvas, double w, double h, Paint fill, Paint outline) {
    // 머리
    final headCenter = Offset(w * 0.5, h * 0.09);
    canvas.drawCircle(headCenter, w * 0.08, fill);
    canvas.drawCircle(headCenter, w * 0.08, outline);

    // 목
    final neckRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.145),
      width: w * 0.07,
      height: h * 0.035,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, const Radius.circular(4)),
      fill,
    );

    // 몸통
    final torsoPath = Path()
      ..moveTo(w * 0.32, h * 0.16)
      ..lineTo(w * 0.68, h * 0.16)
      ..lineTo(w * 0.66, h * 0.47)
      ..lineTo(w * 0.58, h * 0.47)
      ..lineTo(w * 0.56, h * 0.50)
      ..lineTo(w * 0.44, h * 0.50)
      ..lineTo(w * 0.42, h * 0.47)
      ..lineTo(w * 0.34, h * 0.47)
      ..close();
    canvas.drawPath(torsoPath, fill);
    canvas.drawPath(torsoPath, outline);

    // 왼팔 (화면 기준 왼쪽)
    final leftArmPath = Path()
      ..moveTo(w * 0.32, h * 0.17)
      ..lineTo(w * 0.20, h * 0.22)
      ..lineTo(w * 0.17, h * 0.48)
      ..lineTo(w * 0.24, h * 0.48)
      ..lineTo(w * 0.27, h * 0.22)
      ..lineTo(w * 0.36, h * 0.18)
      ..close();
    canvas.drawPath(leftArmPath, fill);
    canvas.drawPath(leftArmPath, outline);

    // 오른팔
    final rightArmPath = Path()
      ..moveTo(w * 0.68, h * 0.17)
      ..lineTo(w * 0.80, h * 0.22)
      ..lineTo(w * 0.83, h * 0.48)
      ..lineTo(w * 0.76, h * 0.48)
      ..lineTo(w * 0.73, h * 0.22)
      ..lineTo(w * 0.64, h * 0.18)
      ..close();
    canvas.drawPath(rightArmPath, fill);
    canvas.drawPath(rightArmPath, outline);

    // 왼다리
    final leftLegPath = Path()
      ..moveTo(w * 0.36, h * 0.50)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.46, h * 0.88)
      ..lineTo(w * 0.38, h * 0.88)
      ..lineTo(w * 0.34, h * 0.68)
      ..close();
    canvas.drawPath(leftLegPath, fill);
    canvas.drawPath(leftLegPath, outline);

    // 오른다리
    final rightLegPath = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.64, h * 0.50)
      ..lineTo(w * 0.66, h * 0.68)
      ..lineTo(w * 0.62, h * 0.88)
      ..lineTo(w * 0.54, h * 0.88)
      ..lineTo(w * 0.50, h * 0.68)
      ..close();
    canvas.drawPath(rightLegPath, fill);
    canvas.drawPath(rightLegPath, outline);
  }

  void _drawBackSilhouette(
      Canvas canvas, double w, double h, Paint fill, Paint outline) {
    // 뒷면은 앞면과 동일한 구조로 그림 (간략화)
    _drawFrontSilhouette(canvas, w, h, fill, outline);
  }

  void _drawLabel(
      Canvas canvas, String text, Offset position, bool isSelected) {
    final textStyle = TextStyle(
      color: isSelected ? Colors.black87 : Colors.grey.shade600,
      fontSize: isSelected ? 12 : 10,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 70);

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BodyDiagramPainter oldDelegate) {
    return oldDelegate.recoveryMap != recoveryMap ||
        oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.isFront != isFront;
  }
}

// ---------------------------------------------------------------------------
// Muscle Detail Panel (선택된 근육 상세 정보)
// ---------------------------------------------------------------------------

class _MuscleDetailPanel extends StatelessWidget {
  final MuscleRecoveryData data;
  final VoidCallback onDismiss;

  const _MuscleDetailPanel({
    required this.data,
    required this.onDismiss,
  });

  String _formatDuration(Duration? duration) {
    if (duration == null) return '-';
    if (duration.inDays >= 1) {
      return '${duration.inDays}일 전'; // TODO: l10n
    } else if (duration.inHours >= 1) {
      return '${duration.inHours}시간 전'; // TODO: l10n
    } else {
      return '${duration.inMinutes}분 전'; // TODO: l10n
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = data.status;
    final color = status.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.bodyPart.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.grey,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 정보 그리드
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time,
                  label: 'Last Workout', // TODO: l10n
                  value: data.lastWorkoutDate != null
                      ? _formatDate(data.lastWorkoutDate)
                      : 'No record', // TODO: l10n
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer_outlined,
                  label: 'Time Since', // TODO: l10n
                  value: _formatDuration(data.timeSinceWorkout),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 최근 운동 목록
          if (data.lastExercises.isNotEmpty) ...[
            const Text(
              'Last Exercises', // TODO: l10n
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.lastExercises.take(4).map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // 다음 운동 권장 날짜
          if (data.recommendedNextWorkout != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Recommended next: ${_formatDate(data.recommendedNextWorkout)}', // TODO: l10n
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info Item Widget
// ---------------------------------------------------------------------------

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
