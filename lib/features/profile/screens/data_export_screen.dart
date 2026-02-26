// 데이터 내보내기 화면 – 운동/식단/수분/신체 데이터 CSV 파일 내보내기
// dart:io File 저장 + 시스템 공유 시트
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:health_app/features/diet/providers/diet_providers.dart';
import 'package:health_app/features/hydration/providers/hydration_providers.dart';
import 'package:health_app/features/workout_log/providers/workout_providers.dart';
import 'package:health_app/features/profile/screens/body_measurements_screen.dart'
    show bodyMeasurementsProvider, MeasurementType;
import 'package:health_app/features/profile/screens/habit_tracker_screen.dart'
    show habitTrackerProvider;

// ---------------------------------------------------------------------------
// Enums & Models
// ---------------------------------------------------------------------------

/// 내보내기 데이터 카테고리
enum ExportCategory {
  workouts,
  diet,
  hydration,
  bodyProgress,
  measurements,
  habits;

  String get label {
    switch (this) {
      case ExportCategory.workouts:
        return '운동 기록'; // TODO: l10n
      case ExportCategory.diet:
        return '식단 기록'; // TODO: l10n
      case ExportCategory.hydration:
        return '수분 섭취'; // TODO: l10n
      case ExportCategory.bodyProgress:
        return '바디 프로그레스'; // TODO: l10n
      case ExportCategory.measurements:
        return '신체 측정'; // TODO: l10n
      case ExportCategory.habits:
        return '습관 기록'; // TODO: l10n
    }
  }

  IconData get icon {
    switch (this) {
      case ExportCategory.workouts:
        return Icons.fitness_center;
      case ExportCategory.diet:
        return Icons.restaurant;
      case ExportCategory.hydration:
        return Icons.water_drop;
      case ExportCategory.bodyProgress:
        return Icons.photo_camera;
      case ExportCategory.measurements:
        return Icons.straighten;
      case ExportCategory.habits:
        return Icons.checklist;
    }
  }
}

/// 날짜 범위 선택
enum DateRangeOption {
  lastWeek,
  lastMonth,
  allTime;

  String get label {
    switch (this) {
      case DateRangeOption.lastWeek:
        return '최근 1주'; // TODO: l10n
      case DateRangeOption.lastMonth:
        return '최근 1개월'; // TODO: l10n
      case DateRangeOption.allTime:
        return '전체 기간'; // TODO: l10n
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRangeOption.lastWeek:
        return now.subtract(const Duration(days: 7));
      case DateRangeOption.lastMonth:
        return now.subtract(const Duration(days: 30));
      case DateRangeOption.allTime:
        return DateTime(2000);
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  final Set<ExportCategory> _selectedCategories = {
    ExportCategory.workouts,
    ExportCategory.diet,
    ExportCategory.measurements,
    ExportCategory.habits,
  };
  DateRangeOption _dateRange = DateRangeOption.lastMonth;
  bool _isExporting = false;
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 내보내기'), // TODO: l10n
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 텍스트
            _InfoCard(),
            const SizedBox(height: 20),
            // 데이터 카테고리 선택
            Text(
              '내보낼 데이터', // TODO: l10n
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...ExportCategory.values.map((cat) {
              return CheckboxListTile(
                value: _selectedCategories.contains(cat),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedCategories.add(cat);
                    } else {
                      _selectedCategories.remove(cat);
                    }
                  });
                },
                secondary: Icon(cat.icon, color: theme.colorScheme.primary),
                title: Text(cat.label),
                controlAffinity: ListTileControlAffinity.trailing,
                dense: true,
              );
            }),
            const SizedBox(height: 20),
            // 날짜 범위 선택
            Text(
              '기간', // TODO: l10n
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: DateRangeOption.values.map((option) {
                final selected = _dateRange == option;
                return ChoiceChip(
                  label: Text(option.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _dateRange = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 포맷 표시
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_chart,
                      size: 16,
                      color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'CSV 형식으로 내보내기', // TODO: l10n
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 내보내기 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedCategories.isEmpty || _isExporting
                    ? null
                    : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isExporting ? '생성 중...' : '내보내기', // TODO: l10n
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
            // 마지막 내보내기 경로 표시
            if (_lastExportPath != null) ...[
              const SizedBox(height: 12),
              _ExportResultCard(path: _lastExportPath!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() {
      _isExporting = true;
      _lastExportPath = null;
    });

    try {
      final csvContent = await _generateCsv();
      final path = await _saveToFile(csvContent);
      setState(() => _lastExportPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('내보내기 완료: $path'), // TODO: l10n
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('내보내기 실패: $e'), // TODO: l10n
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _generateCsv() async {
    final buffer = StringBuffer();
    final startDate = _dateRange.startDate;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // ---- Workouts ----
    if (_selectedCategories.contains(ExportCategory.workouts)) {
      // workoutHistoryProvider 반환 타입: List<WorkoutRecord>
      final records = ref.read(workoutHistoryProvider)
          .where((r) => r.date.isAfter(startDate))
          .toList();

      buffer.writeln('=== 운동 기록 ==='); // TODO: l10n
      buffer.writeln('날짜,운동명,세트번호,반복,무게(kg),볼륨(kg),메모');
      for (final record in records) {
        for (final exercise in record.exercises) {
          for (final set in exercise.sets) {
            buffer.writeln(
              '"${dateFormat.format(record.date)}",'
              '"${exercise.name}",'
              '${set.setNumber},'
              '${set.reps},'
              '${set.weight.toStringAsFixed(1)},'
              '${set.volume.toStringAsFixed(1)},'
              '"${record.notes?.replaceAll('"', "'") ?? ""}"',
            );
          }
        }
      }
      buffer.writeln();
    }

    // ---- Diet ----
    if (_selectedCategories.contains(ExportCategory.diet)) {
      // dietProvider 반환 타입: DailyDietState, meals: List<Meal>
      // Meal: id, type, dateTime, foods(List<MealFoodEntry>)
      final meals = ref.read(dietProvider).meals
          .where((m) => m.dateTime.isAfter(startDate))
          .toList();

      buffer.writeln('=== 식단 기록 ==='); // TODO: l10n
      buffer.writeln('날짜,식사 유형,총 칼로리,단백질(g),탄수화물(g),지방(g),메모');
      for (final meal in meals) {
        buffer.writeln(
          '"${timeFormat.format(meal.dateTime)}",'
          '"${meal.type.name}",'
          '${meal.totalCalories.toStringAsFixed(0)},'
          '${meal.totalProtein.toStringAsFixed(1)},'
          '${meal.totalCarbs.toStringAsFixed(1)},'
          '${meal.totalFat.toStringAsFixed(1)},'
          '"${meal.note?.replaceAll('"', "'") ?? ""}"',
        );
      }
      buffer.writeln();
    }

    // ---- Hydration ----
    if (_selectedCategories.contains(ExportCategory.hydration)) {
      // hydrationProvider 반환 타입: DailyHydrationState, entries: List<WaterIntakeEntry>
      final entries = ref.read(hydrationProvider).entries
          .where((e) => e.time.isAfter(startDate))
          .toList();

      buffer.writeln('=== 수분 섭취 ==='); // TODO: l10n
      buffer.writeln('날짜,섭취량(ml),메모');
      for (final entry in entries) {
        buffer.writeln(
          '"${timeFormat.format(entry.time)}",'
          '${entry.amountMl},'
          '"${entry.note?.replaceAll('"', "'") ?? ""}"',
        );
      }
      buffer.writeln();
    }

    // ---- Body Measurements ----
    if (_selectedCategories.contains(ExportCategory.measurements)) {
      final measurementsState = ref.read(bodyMeasurementsProvider);
      final records = measurementsState.records
          .where((r) => r.date.isAfter(startDate))
          .toList();

      buffer.writeln('=== 신체 측정 ==='); // TODO: l10n
      final typeHeaders =
          MeasurementType.values.map((t) => t.label).join(',');
      buffer.writeln('날짜,$typeHeaders,메모');
      for (final record in records) {
        final values = MeasurementType.values.map((t) {
          final v = record.measurements[t];
          return v != null ? v.toStringAsFixed(1) : '';
        }).join(',');
        buffer.writeln(
          '"${dateFormat.format(record.date)}",'
          '$values,'
          '"${record.notes?.replaceAll('"', "'") ?? ""}"',
        );
      }
      buffer.writeln();
    }

    // ---- Habits ----
    if (_selectedCategories.contains(ExportCategory.habits)) {
      final habitState = ref.read(habitTrackerProvider);
      final habitEntries = habitState.entries.where((e) {
        try {
          final date = DateTime.parse(e.dateKey);
          return date.isAfter(startDate);
        } catch (_) {
          return false;
        }
      }).toList();

      buffer.writeln('=== 습관 기록 ==='); // TODO: l10n
      buffer.writeln('날짜,습관명,완료여부');
      for (final entry in habitEntries) {
        final habit = habitState.habits
            .where((h) => h.id == entry.habitId)
            .firstOrNull;
        if (habit != null) {
          buffer.writeln(
            '"${entry.dateKey}",'
            '"${habit.name}",'
            '${entry.completed ? "완료" : "미완료"}',
          );
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> _saveToFile(String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'healthapp_export_$timestamp.csv';
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);
    return filePath;
  }
}

// ---------------------------------------------------------------------------
// Info Card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '선택한 데이터를 CSV 파일로 내보냅니다. '
              '파일은 앱 문서 폴더에 저장됩니다.', // TODO: l10n
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export Result Card
// ---------------------------------------------------------------------------

class _ExportResultCard extends StatelessWidget {
  final String path;

  const _ExportResultCard({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = path.split('/').last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내보내기 완료', // TODO: l10n
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
