// 습관 추적 화면 – 비운동 일일 습관(수면, 비타민, 스트레칭 등) 기록
// 자체 StateNotifier + SharedPreferences 영속성 포함
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// 개별 습관 정의
class Habit {
  final String id;
  final String name;
  final int iconCodePoint; // IconData는 JSON 직렬화 불가 → codePoint 저장
  final int colorValue; // Color.value
  final int targetDays; // 주당 목표 일수
  final bool isActive;

  const Habit({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.targetDays,
    this.isActive = true,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Habit copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    int? targetDays,
    bool? isActive,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      targetDays: targetDays ?? this.targetDays,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'targetDays': targetDays,
        'isActive': isActive,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCodePoint: json['iconCodePoint'] as int,
        colorValue: json['colorValue'] as int,
        targetDays: json['targetDays'] as int,
        isActive: json['isActive'] as bool? ?? true,
      );
}

/// 특정 날짜에 습관 완료 여부 기록
class HabitEntry {
  final String habitId;
  final String dateKey; // 'yyyy-MM-dd' 형식
  final bool completed;

  const HabitEntry({
    required this.habitId,
    required this.dateKey,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'dateKey': dateKey,
        'completed': completed,
      };

  factory HabitEntry.fromJson(Map<String, dynamic> json) => HabitEntry(
        habitId: json['habitId'] as String,
        dateKey: json['dateKey'] as String,
        completed: json['completed'] as bool,
      );
}

/// 습관 추적기 전체 상태
class HabitTrackerState {
  final List<Habit> habits;
  final List<HabitEntry> entries;
  final DateTime selectedDate;

  const HabitTrackerState({
    this.habits = const [],
    this.entries = const [],
    required this.selectedDate,
  });

  HabitTrackerState copyWith({
    List<Habit>? habits,
    List<HabitEntry>? entries,
    DateTime? selectedDate,
  }) {
    return HabitTrackerState(
      habits: habits ?? this.habits,
      entries: entries ?? this.entries,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory HabitTrackerState.fromJson(
    Map<String, dynamic> json,
    DateTime selectedDate,
  ) =>
      HabitTrackerState(
        habits: (json['habits'] as List<dynamic>? ?? [])
            .map((h) => Habit.fromJson(h as Map<String, dynamic>))
            .toList(),
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => HabitEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        selectedDate: selectedDate,
      );
}

// ---------------------------------------------------------------------------
// StateNotifier
// ---------------------------------------------------------------------------

const _kHabitTrackerKey = 'habit_tracker';
const _uuid = Uuid();

/// 날짜 키 형식: 'yyyy-MM-dd'
String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class HabitTrackerNotifier extends StateNotifier<HabitTrackerState> {
  HabitTrackerNotifier()
      : super(HabitTrackerState(selectedDate: DateTime.now())) {
    _load();
  }

  // ---- 영속성 ----

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHabitTrackerKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = HabitTrackerState.fromJson(json, state.selectedDate);
      }
    } catch (_) {
      // 로드 실패 시 기본값 유지
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHabitTrackerKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  // ---- 날짜 선택 ----

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // ---- 습관 CRUD ----

  void addHabit({
    required String name,
    required int iconCodePoint,
    required int colorValue,
    int targetDays = 7,
  }) {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      targetDays: targetDays,
    );
    state = state.copyWith(habits: [...state.habits, habit]);
    _save();
  }

  void removeHabit(String habitId) {
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != habitId).toList(),
      entries: state.entries.where((e) => e.habitId != habitId).toList(),
    );
    _save();
  }

  void toggleEntry(DateTime date, String habitId) {
    final key = _dateKey(date);
    final existing = state.entries.indexWhere(
      (e) => e.habitId == habitId && e.dateKey == key,
    );

    List<HabitEntry> updated;
    if (existing >= 0) {
      // 토글: 완료 <-> 미완료
      final prev = state.entries[existing];
      updated = [...state.entries];
      updated[existing] = HabitEntry(
        habitId: habitId,
        dateKey: key,
        completed: !prev.completed,
      );
    } else {
      // 새 항목 추가 (완료)
      updated = [
        ...state.entries,
        HabitEntry(habitId: habitId, dateKey: key, completed: true),
      ];
    }
    state = state.copyWith(entries: updated);
    _save();
  }

  /// 특정 날짜에 습관 완료 여부
  bool isCompleted(String habitId, DateTime date) {
    final key = _dateKey(date);
    final entry = state.entries.where(
      (e) => e.habitId == habitId && e.dateKey == key,
    );
    return entry.isNotEmpty && entry.first.completed;
  }

  /// 현재 연속 스트릭 계산 (오늘부터 역순으로 연속 완료일 수)
  int getCurrentStreak(String habitId) {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      if (isCompleted(habitId, date)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 이번 주 완료율 계산 (0.0 ~ 1.0)
  double getWeeklyCompletionRate(DateTime weekStart) {
    if (state.habits.isEmpty) return 0.0;
    int total = 0;
    int completed = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      for (final habit in state.habits.where((h) => h.isActive)) {
        total++;
        if (isCompleted(habit.id, date)) completed++;
      }
    }
    return total == 0 ? 0.0 : completed / total;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final habitTrackerProvider =
    StateNotifierProvider<HabitTrackerNotifier, HabitTrackerState>(
  (ref) => HabitTrackerNotifier(),
);

// ---------------------------------------------------------------------------
// 기본 습관 제안 목록
// ---------------------------------------------------------------------------

const _defaultHabitSuggestions = [
  (name: '물 마시기', icon: Icons.water_drop, color: Color(0xFF2196F3)),
  (name: '스트레칭', icon: Icons.self_improvement, color: Color(0xFF4CAF50)),
  (name: '비타민', icon: Icons.medication, color: Color(0xFFFF9800)),
  (name: '7시간 수면', icon: Icons.bedtime, color: Color(0xFF9C27B0)),
  (name: '명상', icon: Icons.spa, color: Color(0xFF00BCD4)),
];

// 아이콘 피커용 12개 아이콘
const _iconOptions = [
  Icons.water_drop,
  Icons.self_improvement,
  Icons.medication,
  Icons.bedtime,
  Icons.spa,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.book,
  Icons.music_note,
  Icons.restaurant,
  Icons.favorite,
  Icons.lightbulb,
];

// 컬러 피커용 8가지 색상
const _colorOptions = [
  Color(0xFF2196F3), // 파랑
  Color(0xFF4CAF50), // 초록
  Color(0xFFFF9800), // 주황
  Color(0xFF9C27B0), // 보라
  Color(0xFF00BCD4), // 청록
  Color(0xFFF44336), // 빨강
  Color(0xFFFFEB3B), // 노랑
  Color(0xFF795548), // 갈색
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HabitTrackerScreen extends ConsumerWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitTrackerProvider);
    final notifier = ref.read(habitTrackerProvider.notifier);

    // 이번 주 시작일 (월요일 기준)
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('습관 추적기'), // TODO: l10n
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, ref),
        tooltip: '습관 추가', // TODO: l10n
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 주간 뷰
          _WeekView(
            weekStart: weekStart,
            selectedDate: state.selectedDate,
            onDateSelected: notifier.selectDate,
          ),
          const SizedBox(height: 8),
          // 습관 목록
          Expanded(
            child: state.habits.isEmpty
                ? _EmptyHabitsView(onAddSuggestion: (name, icon, color) {
                    notifier.addHabit(
                      name: name,
                      iconCodePoint: icon.codePoint,
                      colorValue: color.toARGB32(),
                    );
                  })
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: state.habits.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.habits.length) {
                        // 마지막 항목: 주간 완료율 카드
                        return _WeeklyCompletionCard(
                          rate: notifier.getWeeklyCompletionRate(weekStart),
                        );
                      }
                      final habit = state.habits[index];
                      final completed =
                          notifier.isCompleted(habit.id, state.selectedDate);
                      final streak = notifier.getCurrentStreak(habit.id);
                      return _HabitTile(
                        habit: habit,
                        completed: completed,
                        streak: streak,
                        onToggle: () =>
                            notifier.toggleEntry(state.selectedDate, habit.id),
                        onDelete: () => notifier.removeHabit(habit.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddHabitDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddHabitDialog(
        onAdd: (name, iconCodePoint, colorValue, targetDays) {
          ref.read(habitTrackerProvider.notifier).addHabit(
                name: name,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                targetDays: targetDays,
              );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week View Widget
// ---------------------------------------------------------------------------

class _WeekView extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekView({
    required this.weekStart,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final theme = Theme.of(context);

    // 요일 레이블
    const dayLabels = ['월', '화', '수', '목', '금', '토', '일']; // TODO: l10n

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabels[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit Tile
// ---------------------------------------------------------------------------

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool completed;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitTile({
    required this.habit,
    required this.completed,
    required this.streak,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('습관 삭제'), // TODO: l10n
            content: Text('${habit.name}을(를) 삭제하시겠습니까?'), // TODO: l10n
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'), // TODO: l10n
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    const Text('삭제', style: TextStyle(color: Colors.red)), // TODO: l10n
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: habit.color.withValues(alpha: 0.15),
            child: Icon(habit.icon, color: habit.color, size: 22),
          ),
          title: Text(
            habit.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: completed ? TextDecoration.lineThrough : null,
              color: completed
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
            ),
          ),
          subtitle: streak > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      '$streak일 연속', // TODO: l10n
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.orange),
                    ),
                  ],
                )
              : null,
          trailing: Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: completed,
              onChanged: (_) => onToggle(),
              activeColor: habit.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyHabitsView extends StatelessWidget {
  final void Function(String name, IconData icon, Color color)
      onAddSuggestion;

  const _EmptyHabitsView({required this.onAddSuggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rtl,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 습관이 없습니다', // TODO: l10n
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '추천 습관을 추가해보세요', // TODO: l10n
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ..._defaultHabitSuggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                icon: Icon(s.icon, color: s.color),
                label: Text(s.name),
                onPressed: () => onAddSuggestion(s.name, s.icon, s.color),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: s.color.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly Completion Rate Card
// ---------------------------------------------------------------------------

class _WeeklyCompletionCard extends StatelessWidget {
  final double rate;

  const _WeeklyCompletionCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (rate * 100).round();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 원형 진행률 표시
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 6,
                    backgroundColor:
                        theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 주 달성률', // TODO: l10n
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rateMessage(rate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rateMessage(double rate) {
    if (rate >= 0.9) return '훌륭해요! 이번 주 거의 완벽합니다 🎉'; // TODO: l10n
    if (rate >= 0.7) return '잘하고 있어요! 조금만 더 힘내세요'; // TODO: l10n
    if (rate >= 0.5) return '절반 이상 달성! 꾸준히 유지해보세요'; // TODO: l10n
    return '조금씩 시작해봐요. 작은 습관이 큰 변화를 만듭니다'; // TODO: l10n
  }
}

// ---------------------------------------------------------------------------
// Add Habit Dialog
// ---------------------------------------------------------------------------

class _AddHabitDialog extends StatefulWidget {
  final void Function(
      String name, int iconCodePoint, int colorValue, int targetDays) onAdd;

  const _AddHabitDialog({required this.onAdd});

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.favorite;
  Color _selectedColor = _colorOptions.first;
  int _targetDays = 7;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('새 습관 추가'), // TODO: l10n
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 입력
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '습관 이름', // TODO: l10n
                border: OutlineInputBorder(),
                hintText: '예: 물 마시기', // TODO: l10n
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // 아이콘 선택
            Text('아이콘', style: theme.textTheme.labelLarge), // TODO: l10n
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((icon) {
                final selected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? _selectedColor.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? _selectedColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 색상 선택
            Text('색상', style: theme.textTheme.labelLarge), // TODO: l10n
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((color) {
                final selected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 2)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 주당 목표 일수
            Text('주당 목표', style: theme.textTheme.labelLarge), // TODO: l10n
            Slider(
              value: _targetDays.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_targetDays일', // TODO: l10n
              onChanged: (v) => setState(() => _targetDays = v.round()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'), // TODO: l10n
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            widget.onAdd(
              name,
              _selectedIcon.codePoint,
              _selectedColor.toARGB32(),
              _targetDays,
            );
            Navigator.pop(context);
          },
          child: const Text('추가'), // TODO: l10n
        ),
      ],
    );
  }
}
