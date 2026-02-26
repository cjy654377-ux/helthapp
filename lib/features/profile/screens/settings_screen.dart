// 설정 화면 - 프로필/운동/알림/앱/기타 섹션 포함
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/services/health_sync_service.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// SharedPreferences 키
// ---------------------------------------------------------------------------

abstract final class _SettingsKeys {
  // 프로필
  static const String nickname = 'user_nickname';
  static const String height = 'user_height';
  static const String weight = 'user_weight';
  static const String gender = 'user_gender';
  static const String avatarPath = 'user_avatar_path';

  // 운동 설정
  static const String restSeconds = 'setting_rest_seconds';
  static const String weightUnit = 'setting_weight_unit';
  static const String workoutSplit = 'setting_workout_split';

  // 알림 설정
  static const String workoutNotif = 'notif_workout_enabled';
  static const String workoutNotifHour = 'notif_workout_hour';
  static const String workoutNotifMin = 'notif_workout_min';
  static const String hydrationNotif = 'notif_hydration_enabled';
  static const String hydrationInterval = 'notif_hydration_interval';
  static const String dietBreakfast = 'notif_diet_breakfast';
  static const String dietLunch = 'notif_diet_lunch';
  static const String dietDinner = 'notif_diet_dinner';

  // 앱 설정
  static const String themeMode = 'setting_theme_mode'; // 'system'|'light'|'dark'
  static const String language = 'setting_language'; // 'ko'|'en'
}

// ---------------------------------------------------------------------------
// 설정 상태 모델
// ---------------------------------------------------------------------------

class SettingsState {
  // 프로필
  final String nickname;
  final String height;
  final String weight;
  final String gender;
  final String? avatarPath;

  // 운동 설정
  final int restSeconds;
  final String weightUnit; // 'kg' | 'lbs'
  final String workoutSplit; // 'PPL' | '상하체' | '풀바디' | '4분할'

  // 알림 설정
  final bool workoutNotif;
  final int workoutNotifHour;
  final int workoutNotifMin;
  final bool hydrationNotif;
  final int hydrationInterval; // hours: 1|2|3
  final bool dietBreakfast;
  final bool dietLunch;
  final bool dietDinner;

  // 앱 설정
  final String themeMode; // 'system' | 'light' | 'dark'
  final String language; // 'ko' | 'en'

  const SettingsState({
    this.nickname = '',
    this.height = '',
    this.weight = '',
    this.gender = '남',
    this.avatarPath,
    this.restSeconds = 90,
    this.weightUnit = 'kg',
    this.workoutSplit = 'PPL',
    this.workoutNotif = false,
    this.workoutNotifHour = 7,
    this.workoutNotifMin = 0,
    this.hydrationNotif = false,
    this.hydrationInterval = 2,
    this.dietBreakfast = false,
    this.dietLunch = false,
    this.dietDinner = false,
    this.themeMode = 'system',
    this.language = 'ko',
  });

  SettingsState copyWith({
    String? nickname,
    String? height,
    String? weight,
    String? gender,
    String? avatarPath,
    bool clearAvatar = false,
    int? restSeconds,
    String? weightUnit,
    String? workoutSplit,
    bool? workoutNotif,
    int? workoutNotifHour,
    int? workoutNotifMin,
    bool? hydrationNotif,
    int? hydrationInterval,
    bool? dietBreakfast,
    bool? dietLunch,
    bool? dietDinner,
    String? themeMode,
    String? language,
  }) {
    return SettingsState(
      nickname: nickname ?? this.nickname,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      restSeconds: restSeconds ?? this.restSeconds,
      weightUnit: weightUnit ?? this.weightUnit,
      workoutSplit: workoutSplit ?? this.workoutSplit,
      workoutNotif: workoutNotif ?? this.workoutNotif,
      workoutNotifHour: workoutNotifHour ?? this.workoutNotifHour,
      workoutNotifMin: workoutNotifMin ?? this.workoutNotifMin,
      hydrationNotif: hydrationNotif ?? this.hydrationNotif,
      hydrationInterval: hydrationInterval ?? this.hydrationInterval,
      dietBreakfast: dietBreakfast ?? this.dietBreakfast,
      dietLunch: dietLunch ?? this.dietLunch,
      dietDinner: dietDinner ?? this.dietDinner,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsNotifier
// ---------------------------------------------------------------------------

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Timer? _debounce;
  bool _disposed = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        nickname: prefs.getString(_SettingsKeys.nickname) ?? '',
        height: prefs.getString(_SettingsKeys.height) ?? '',
        weight: prefs.getString(_SettingsKeys.weight) ?? '',
        gender: prefs.getString(_SettingsKeys.gender) ?? '남',
        avatarPath: prefs.getString(_SettingsKeys.avatarPath),
        restSeconds: prefs.getInt(_SettingsKeys.restSeconds) ?? 90,
        weightUnit: prefs.getString(_SettingsKeys.weightUnit) ?? 'kg',
        workoutSplit: prefs.getString(_SettingsKeys.workoutSplit) ?? 'PPL',
        workoutNotif: prefs.getBool(_SettingsKeys.workoutNotif) ?? false,
        workoutNotifHour: prefs.getInt(_SettingsKeys.workoutNotifHour) ?? 7,
        workoutNotifMin: prefs.getInt(_SettingsKeys.workoutNotifMin) ?? 0,
        hydrationNotif: prefs.getBool(_SettingsKeys.hydrationNotif) ?? false,
        hydrationInterval: prefs.getInt(_SettingsKeys.hydrationInterval) ?? 2,
        dietBreakfast: prefs.getBool(_SettingsKeys.dietBreakfast) ?? false,
        dietLunch: prefs.getBool(_SettingsKeys.dietLunch) ?? false,
        dietDinner: prefs.getBool(_SettingsKeys.dietDinner) ?? false,
        themeMode: prefs.getString(_SettingsKeys.themeMode) ?? 'system',
        language: prefs.getString(_SettingsKeys.language) ?? 'ko',
      );
    } catch (_) {
      // 로드 실패 시 기본값 유지
    }
  }

  Future<void> _save() async {
    if (_disposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = state;
      await prefs.setString(_SettingsKeys.nickname, s.nickname);
      await prefs.setString(_SettingsKeys.height, s.height);
      await prefs.setString(_SettingsKeys.weight, s.weight);
      await prefs.setString(_SettingsKeys.gender, s.gender);
      if (s.avatarPath != null) {
        await prefs.setString(_SettingsKeys.avatarPath, s.avatarPath!);
      } else {
        await prefs.remove(_SettingsKeys.avatarPath);
      }
      await prefs.setInt(_SettingsKeys.restSeconds, s.restSeconds);
      await prefs.setString(_SettingsKeys.weightUnit, s.weightUnit);
      await prefs.setString(_SettingsKeys.workoutSplit, s.workoutSplit);
      await prefs.setBool(_SettingsKeys.workoutNotif, s.workoutNotif);
      await prefs.setInt(_SettingsKeys.workoutNotifHour, s.workoutNotifHour);
      await prefs.setInt(_SettingsKeys.workoutNotifMin, s.workoutNotifMin);
      await prefs.setBool(_SettingsKeys.hydrationNotif, s.hydrationNotif);
      await prefs.setInt(_SettingsKeys.hydrationInterval, s.hydrationInterval);
      await prefs.setBool(_SettingsKeys.dietBreakfast, s.dietBreakfast);
      await prefs.setBool(_SettingsKeys.dietLunch, s.dietLunch);
      await prefs.setBool(_SettingsKeys.dietDinner, s.dietDinner);
      await prefs.setString(_SettingsKeys.themeMode, s.themeMode);
      await prefs.setString(_SettingsKeys.language, s.language);
    } catch (_) {
      // 저장 실패 시 무시 — UI 상태는 이미 갱신됨
    }
  }

  void _update(SettingsState updated) {
    if (_disposed) return;
    state = updated;
    // 디바운스: 연속 입력 시 500ms 후 1회만 저장
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  void setNickname(String v) => _update(state.copyWith(nickname: v));
  void setHeight(String v) => _update(state.copyWith(height: v));
  void setWeight(String v) => _update(state.copyWith(weight: v));
  void setGender(String v) => _update(state.copyWith(gender: v));
  void setAvatarPath(String? v) {
    if (v == null) {
      _update(state.copyWith(clearAvatar: true));
    } else {
      _update(state.copyWith(avatarPath: v));
    }
  }

  void setRestSeconds(int v) => _update(state.copyWith(restSeconds: v));
  void setWeightUnit(String v) => _update(state.copyWith(weightUnit: v));
  void setWorkoutSplit(String v) => _update(state.copyWith(workoutSplit: v));

  void setWorkoutNotif(bool v) => _update(state.copyWith(workoutNotif: v));
  void setWorkoutNotifTime(int hour, int min) =>
      _update(state.copyWith(workoutNotifHour: hour, workoutNotifMin: min));
  void setHydrationNotif(bool v) => _update(state.copyWith(hydrationNotif: v));
  void setHydrationInterval(int v) =>
      _update(state.copyWith(hydrationInterval: v));
  void setDietBreakfast(bool v) => _update(state.copyWith(dietBreakfast: v));
  void setDietLunch(bool v) => _update(state.copyWith(dietLunch: v));
  void setDietDinner(bool v) => _update(state.copyWith(dietDinner: v));

  void setThemeMode(String v) => _update(state.copyWith(themeMode: v));
  void setLanguage(String v) => _update(state.copyWith(language: v));

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      state = const SettingsState();
    } catch (_) {
      // 삭제 실패 시 상태 유지
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ProfileSection(),
          SizedBox(height: 16),
          _WorkoutSettingsSection(),
          SizedBox(height: 16),
          _NotificationSection(),
          SizedBox(height: 16),
          _AppSettingsSection(),
          SizedBox(height: 16),
          _MiscSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 헤더
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 1: 프로필
// ---------------------------------------------------------------------------

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.profile,
          icon: Icons.person_outline,
          color: colorScheme.primary,
        ),
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
              // 프로필 사진 변경
              ListTile(
                leading: _AvatarWidget(avatarPath: state.avatarPath),
                title: Text(l10n.profilePhoto),
                subtitle: Text(l10n.tapToChange),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickImage(context, notifier),
              ),
              const Divider(height: 1, indent: 72),

              // 닉네임 변경
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.badge_outlined,
                      color: colorScheme.primary, size: 20),
                ),
                title: Text(l10n.nickname),
                subtitle: Text(
                  state.nickname.isEmpty ? l10n.noNickname : state.nickname,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog(
                  context: context,
                  title: l10n.editNickname,
                  initialValue: state.nickname,
                  hintText: l10n.enterNickname,
                  onSave: notifier.setNickname,
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 기본 정보: 성별
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wc, color: Colors.purple, size: 20),
                ),
                title: Text(l10n.gender),
                trailing: _GenderDropdown(
                  value: state.gender,
                  onChanged: notifier.setGender,
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 기본 정보: 키
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.height, color: Colors.teal, size: 20),
                ),
                title: Text(l10n.height),
                subtitle: Text(
                  state.height.isEmpty ? l10n.notEntered : '${state.height} ${l10n.cm}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog(
                  context: context,
                  title: l10n.height,
                  initialValue: state.height,
                  hintText: '예: 175',
                  suffix: l10n.cm,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onSave: notifier.setHeight,
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 기본 정보: 몸무게
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined,
                      color: Colors.orange, size: 20),
                ),
                title: Text(l10n.weight),
                subtitle: Text(
                  state.weight.isEmpty ? l10n.notEntered : '${state.weight} ${l10n.kg}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog(
                  context: context,
                  title: l10n.weight,
                  initialValue: state.weight,
                  hintText: '예: 70',
                  suffix: l10n.kg,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onSave: notifier.setWeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(
      BuildContext context, SettingsNotifier notifier) async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhotoCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.selectFromGalleryOption),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        notifier.setAvatarPath(picked.path);
      }
    }
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required String hintText,
    required void Function(String) onSave,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            suffixText: suffix,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 2: 운동 설정
// ---------------------------------------------------------------------------

class _WorkoutSettingsSection extends ConsumerWidget {
  const _WorkoutSettingsSection();

  static const List<int> _restOptions = [60, 90, 120, 180];
  static const List<String> _weightUnits = ['kg', 'lbs'];
  static const List<String> _splitOptions = ['PPL', '상하체', '풀바디', '4분할'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.workoutSettings,
          icon: Icons.fitness_center,
          color: Colors.deepOrange,
        ),
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
              // 기본 휴식 시간
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: Colors.deepOrange, size: 20),
                ),
                title: Text(l10n.defaultRestTime),
                trailing: DropdownButton<int>(
                  value: state.restSeconds,
                  underline: const SizedBox.shrink(),
                  items: _restOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(l10n.secondsUnit(s)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setRestSeconds(v);
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 무게 단위
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.scale_outlined,
                      color: Colors.indigo, size: 20),
                ),
                title: Text(l10n.weightUnit),
                trailing: DropdownButton<String>(
                  value: state.weightUnit,
                  underline: const SizedBox.shrink(),
                  items: _weightUnits
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setWeightUnit(v);
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 기본 운동 스플릿
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.splitscreen,
                      color: Colors.green, size: 20),
                ),
                title: Text(l10n.defaultSplit),
                trailing: DropdownButton<String>(
                  value: state.workoutSplit,
                  underline: const SizedBox.shrink(),
                  items: _splitOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setWorkoutSplit(v);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 3: 알림 설정
// ---------------------------------------------------------------------------

class _NotificationSection extends ConsumerWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    String hydrationIntervalLabel(int hours) {
      if (hours == 1) return l10n.everyOneHour;
      if (hours == 2) return l10n.everyTwoHours;
      return l10n.everyThreeHours;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.notificationSettings,
          icon: Icons.notifications_outlined,
          color: Colors.amber.shade700,
        ),
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
              // 운동 알림 토글
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center,
                      color: Colors.amber.shade700, size: 20),
                ),
                title: Text(l10n.workoutReminder),
                subtitle: state.workoutNotif
                    ? Text(
                        '${state.workoutNotifHour.toString().padLeft(2, '0')}:${state.workoutNotifMin.toString().padLeft(2, '0')}',
                      )
                    : null,
                trailing: Switch(
                  value: state.workoutNotif,
                  onChanged: notifier.setWorkoutNotif,
                ),
              ),

              // 운동 시간 선택 (토글 On 시 표시)
              if (state.workoutNotif) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                  child: _TimePickerRow(
                    hour: state.workoutNotifHour,
                    minute: state.workoutNotifMin,
                    onChanged: (h, m) => notifier.setWorkoutNotifTime(h, m),
                  ),
                ),
              ],
              const Divider(height: 1, indent: 72),

              // 수분 알림 토글
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      color: Colors.cyan, size: 20),
                ),
                title: Text(l10n.hydrationReminder),
                subtitle: state.hydrationNotif
                    ? Text(hydrationIntervalLabel(state.hydrationInterval))
                    : null,
                trailing: Switch(
                  value: state.hydrationNotif,
                  onChanged: notifier.setHydrationNotif,
                ),
              ),

              // 수분 간격 선택 (토글 On 시 표시)
              if (state.hydrationNotif) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                  child: Row(
                    children: [1, 2, 3].map((h) {
                      final isSelected = state.hydrationInterval == h;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(hydrationIntervalLabel(h)),
                          selected: isSelected,
                          onSelected: (_) =>
                              notifier.setHydrationInterval(h),
                          selectedColor:
                              Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const Divider(height: 1, indent: 72),

              // 식단 알림: 아침
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wb_sunny_outlined,
                      color: Colors.orange, size: 20),
                ),
                title: Text('${l10n.breakfast} ${l10n.mealReminder}'),
                value: state.dietBreakfast,
                onChanged: notifier.setDietBreakfast,
              ),
              const Divider(height: 1, indent: 72),

              // 식단 알림: 점심
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.light_mode_outlined,
                      color: Colors.yellow.shade700, size: 20),
                ),
                title: Text('${l10n.lunch} ${l10n.mealReminder}'),
                value: state.dietLunch,
                onChanged: notifier.setDietLunch,
              ),
              const Divider(height: 1, indent: 72),

              // 식단 알림: 저녁
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bedtime_outlined,
                      color: Colors.deepPurple, size: 20),
                ),
                title: Text('${l10n.dinner} ${l10n.mealReminder}'),
                value: state.dietDinner,
                onChanged: notifier.setDietDinner,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 4: 앱 설정
// ---------------------------------------------------------------------------

class _AppSettingsSection extends ConsumerWidget {
  const _AppSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final Map<String, String> themeModes = {
      'system': l10n.systemMode,
      'light': l10n.lightMode,
      'dark': l10n.darkModeOption,
    };

    final Map<String, String> languages = {
      'ko': l10n.korean,
      'en': l10n.english,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.appSettings,
          icon: Icons.settings_outlined,
          color: Colors.blueGrey,
        ),
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
              // 다크 모드
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: Colors.blueGrey, size: 20),
                ),
                title: Text(l10n.darkMode),
                trailing: DropdownButton<String>(
                  value: state.themeMode,
                  underline: const SizedBox.shrink(),
                  items: themeModes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setThemeMode(v);
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 언어 설정
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.language,
                      color: Colors.blue, size: 20),
                ),
                title: Text(l10n.language),
                trailing: DropdownButton<String>(
                  value: state.language,
                  underline: const SizedBox.shrink(),
                  items: languages.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setLanguage(v);
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),

              // Apple Health / Google Fit 연동
              _HealthSyncTile(),
              const Divider(height: 1, indent: 72),

              // 데이터 백업
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.backup_outlined,
                      color: Colors.green, size: 20),
                ),
                title: Text(l10n.backupData),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.backupComingSoon),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 데이터 복원
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restore,
                      color: Colors.teal, size: 20),
                ),
                title: Text(l10n.restoreData),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.restoreComingSoon),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 데이터 전체 삭제
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever_outlined,
                      color: Colors.red, size: 20),
                ),
                title: Text(
                  l10n.deleteAllData,
                  style: const TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () =>
                    _confirmDeleteAll(context, ref.read(settingsProvider.notifier)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAll(BuildContext context, SettingsNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.allDataDeleted),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 섹션 5: 기타
// ---------------------------------------------------------------------------

class _MiscSection extends StatelessWidget {
  const _MiscSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.misc,
          icon: Icons.info_outline,
          color: Colors.grey.shade600,
        ),
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
              // 앱 버전
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: Colors.grey, size: 20),
                ),
                title: Text(l10n.appVersion),
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 개인정보 처리방침
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined,
                      color: Colors.grey, size: 20),
                ),
                title: Text(l10n.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPolicyDialog(
                  context,
                  title: l10n.privacyPolicy,
                  content: l10n.privacyPolicyContent,
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 이용약관
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: Colors.grey, size: 20),
                ),
                title: Text(l10n.termsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPolicyDialog(
                  context,
                  title: l10n.termsOfService,
                  content: l10n.termsOfServiceContent,
                ),
              ),
              const Divider(height: 1, indent: 72),

              // 오픈소스 라이선스
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code,
                      color: Colors.grey, size: 20),
                ),
                title: Text(l10n.openSourceLicenses),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPolicyDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 공통 위젯
// ---------------------------------------------------------------------------

class _AvatarWidget extends StatelessWidget {
  final String? avatarPath;

  const _AvatarWidget({this.avatarPath});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (avatarPath != null && File(avatarPath!).existsSync()) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: FileImage(File(avatarPath!)),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(Icons.person, color: colorScheme.primary),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: '남', child: Text(l10n.male)),
        DropdownMenuItem(value: '여', child: Text(l10n.female)),
        DropdownMenuItem(value: '기타', child: Text(l10n.other)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _TimePickerRow({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(l10n.notificationTimeLabel),
        TextButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: hour, minute: minute),
            );
            if (picked != null) {
              onChanged(picked.hour, picked.minute);
            }
          },
          child: Text(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Apple Health / Google Fit 연동 타일
// ---------------------------------------------------------------------------

/// 설정 화면의 앱 섹션에 표시되는 Health 연동 ListTile
class _HealthSyncTile extends ConsumerWidget {
  const _HealthSyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 플랫폼 이름
    final platformName = Platform.isIOS ? 'Apple Health' : 'Google Fit';

    // 권한 상태를 비동기로 조회
    final permissionAsync = ref.watch(healthPermissionGrantedProvider);

    final isConnected = permissionAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.favorite_outline,
            color: Colors.pink, size: 20),
      ),
      title: Text('$platformName 연동'),
      subtitle: Text(isConnected ? '연동됨' : '연동되지 않음'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 연결 상태 인디케이터 점
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push('/health-sync'),
    );
  }
}
