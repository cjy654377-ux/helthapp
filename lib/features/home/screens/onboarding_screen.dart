// 온보딩 화면 - 앱 최초 실행 시 표시되는 4단계 온보딩 플로우
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/core/router/app_router.dart';
import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// SharedPreferences 키
// ---------------------------------------------------------------------------

abstract final class _OnboardingKeys {
  static const String completed = 'onboarding_completed';
  static const String nickname = 'user_nickname';
  static const String gender = 'user_gender';
  static const String height = 'user_height';
  static const String weight = 'user_weight';
  static const String experience = 'user_experience';
  static const String goals = 'user_goals';
  static const String weeklyWorkoutGoal = 'weekly_workout_goal';
  static const String dailyCalorieGoal = 'daily_calorie_goal';
  static const String dailyWaterGoal = 'daily_water_goal';
}

// ---------------------------------------------------------------------------
// 온보딩 상태 모델
// ---------------------------------------------------------------------------

class OnboardingState {
  // 페이지 2: 기본 정보
  final String nickname;
  final String gender; // '남' | '여' | '기타'
  final String height;
  final String weight;
  final String experience; // '초보자' | '중급자' | '고급자'

  // 페이지 3: 목표
  final Set<String> selectedGoals;
  final int weeklyWorkoutGoal;
  final int dailyCalorieGoal;
  final int dailyWaterGoal;

  const OnboardingState({
    this.nickname = '',
    this.gender = '남',
    this.height = '',
    this.weight = '',
    this.experience = '초보자',
    this.selectedGoals = const {},
    this.weeklyWorkoutGoal = 3,
    this.dailyCalorieGoal = 2000,
    this.dailyWaterGoal = 2000,
  });

  OnboardingState copyWith({
    String? nickname,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    Set<String>? selectedGoals,
    int? weeklyWorkoutGoal,
    int? dailyCalorieGoal,
    int? dailyWaterGoal,
  }) {
    return OnboardingState(
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      experience: experience ?? this.experience,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      weeklyWorkoutGoal: weeklyWorkoutGoal ?? this.weeklyWorkoutGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
    );
  }
}

// ---------------------------------------------------------------------------
// 온보딩 StateNotifier
// ---------------------------------------------------------------------------

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void setNickname(String value) => state = state.copyWith(nickname: value);
  void setGender(String value) => state = state.copyWith(gender: value);
  void setHeight(String value) => state = state.copyWith(height: value);
  void setWeight(String value) => state = state.copyWith(weight: value);
  void setExperience(String value) => state = state.copyWith(experience: value);

  void toggleGoal(String goal) {
    final current = Set<String>.from(state.selectedGoals);
    if (current.contains(goal)) {
      current.remove(goal);
    } else {
      current.add(goal);
    }
    state = state.copyWith(selectedGoals: current);
  }

  void setWeeklyWorkoutGoal(int value) =>
      state = state.copyWith(weeklyWorkoutGoal: value);

  void setDailyCalorieGoal(int value) =>
      state = state.copyWith(dailyCalorieGoal: value);

  void setDailyWaterGoal(int value) =>
      state = state.copyWith(dailyWaterGoal: value);

  Future<void> saveAndComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_OnboardingKeys.completed, true);
    await prefs.setString(_OnboardingKeys.nickname, state.nickname);
    await prefs.setString(_OnboardingKeys.gender, state.gender);
    await prefs.setString(_OnboardingKeys.height, state.height);
    await prefs.setString(_OnboardingKeys.weight, state.weight);
    await prefs.setString(_OnboardingKeys.experience, state.experience);
    await prefs.setStringList(
        _OnboardingKeys.goals, state.selectedGoals.toList());
    await prefs.setInt(
        _OnboardingKeys.weeklyWorkoutGoal, state.weeklyWorkoutGoal);
    await prefs.setInt(
        _OnboardingKeys.dailyCalorieGoal, state.dailyCalorieGoal);
    await prefs.setInt(_OnboardingKeys.dailyWaterGoal, state.dailyWaterGoal);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);

/// 온보딩 완료 여부 확인 Provider
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_OnboardingKeys.completed) ?? false;
});

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    await ref.read(onboardingProvider.notifier).saveAndComplete();
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기 버튼 (마지막 페이지 제외)
            if (_currentPage < _totalPages - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(l10n.skip),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            // 페이지 뷰
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _BasicInfoPage(onNext: _nextPage, onBack: _previousPage),
                  _GoalSettingPage(onNext: _nextPage, onBack: _previousPage),
                  _CompletionPage(onComplete: _complete),
                ],
              ),
            ),

            // Dot indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1: 환영
// ---------------------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 피트니스 아이콘
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // 타이틀
          Text(
            l10n.yourHealthPartner,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 서브타이틀
          Text(
            l10n.allInOneApp,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),

          // 시작 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.getStarted,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2: 기본 정보 입력
// ---------------------------------------------------------------------------

class _BasicInfoPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BasicInfoPage({required this.onNext, required this.onBack});

  @override
  ConsumerState<_BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends ConsumerState<_BasicInfoPage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  // stored values used in logic (do not translate)
  static const List<String> _genderValues = ['남', '여', '기타'];
  static const List<String> _experienceValues = ['초보자', '중급자', '고급자'];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _nicknameController = TextEditingController(text: state.nickname);
    _heightController = TextEditingController(text: state.height);
    _weightController = TextEditingController(text: state.weight);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<String> genderLabels = [l10n.male, l10n.female, l10n.other];
    final List<String> experienceLabels = [
      l10n.beginnerLevel,
      l10n.intermediateLevel,
      l10n.advancedLevel,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // 헤더
          Text(
            l10n.basicInfoInput,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tellUsAboutYou,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // 닉네임
          _InputLabel(l10n.nickname),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: l10n.nicknameHint,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: notifier.setNickname,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),

          // 성별
          _InputLabel(l10n.selectGender),
          Wrap(
            spacing: 10,
            children: List.generate(_genderValues.length, (i) {
              final value = _genderValues[i];
              final label = genderLabels[i];
              final isSelected = state.gender == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => notifier.setGender(value),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // 키 / 몸무게
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputLabel(l10n.heightCm),
                    TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        hintText: '예: 175',
                        suffixText: 'cm',
                      ),
                      onChanged: notifier.setHeight,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputLabel(l10n.weightKgField),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        hintText: '예: 70',
                        suffixText: 'kg',
                      ),
                      onChanged: notifier.setWeight,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 운동 경력
          _InputLabel(l10n.fitnessLevel),
          Wrap(
            spacing: 10,
            children: List.generate(_experienceValues.length, (i) {
              final value = _experienceValues[i];
              final label = experienceLabels[i];
              final isSelected = state.experience == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => notifier.setExperience(value),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 36),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.next,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3: 목표 설정
// ---------------------------------------------------------------------------

class _GoalSettingPage extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _GoalSettingPage({required this.onNext, required this.onBack});

  // stored values used as keys in logic (do not translate)
  static const List<String> _availableGoalValues = [
    '근력 증가',
    '체중 감량',
    '체력 향상',
    '유연성 향상',
    '건강 유지',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<String> goalLabels = [
      l10n.strengthGain,
      l10n.weightLoss,
      l10n.enduranceImprove,
      l10n.flexibilityImprove,
      l10n.healthMaintain,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // 헤더
          Text(
            l10n.goalSetting,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.setGoalsForYou,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // 목표 선택 멀티 셀렉트
          _InputLabel(l10n.mainGoal),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_availableGoalValues.length, (i) {
              final goalValue = _availableGoalValues[i];
              final goalLabel = goalLabels[i];
              final isSelected = state.selectedGoals.contains(goalValue);
              return FilterChip(
                label: Text(goalLabel),
                selected: isSelected,
                onSelected: (_) => notifier.toggleGoal(goalValue),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // 주간 운동 횟수 슬라이더
          _InputLabel(l10n.weeklyWorkoutGoal),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: state.weeklyWorkoutGoal.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '${state.weeklyWorkoutGoal}${l10n.reps}',
                  onChanged: (v) => notifier.setWeeklyWorkoutGoal(v.round()),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${state.weeklyWorkoutGoal}${l10n.timesPerWeek}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 일일 칼로리 목표 슬라이더
          _InputLabel(l10n.dailyCalorieGoal),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: state.dailyCalorieGoal.toDouble(),
                  min: 1200,
                  max: 3500,
                  divisions: 46,
                  label: '${state.dailyCalorieGoal}${l10n.kcal}',
                  onChanged: (v) =>
                      notifier.setDailyCalorieGoal(v.round()),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  '${state.dailyCalorieGoal}\n${l10n.kcal}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 일일 수분 목표 슬라이더
          _InputLabel(l10n.dailyWaterGoal),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: state.dailyWaterGoal.toDouble(),
                  min: 1000,
                  max: 3000,
                  divisions: 20,
                  label: '${state.dailyWaterGoal}${l10n.ml}',
                  onChanged: (v) => notifier.setDailyWaterGoal(v.round()),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  '${state.dailyWaterGoal}\n${l10n.ml}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.next,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4: 완료
// ---------------------------------------------------------------------------

class _CompletionPage extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _CompletionPage({required this.onComplete});

  @override
  State<_CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<_CompletionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 체크마크 애니메이션
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade700,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // "준비 완료!" 메시지
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  l10n.allReady,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.allSetMessage,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),

          // 시작하기 버튼
          FadeTransition(
            opacity: _fadeAnim,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.startNow,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
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
// 공통 위젯
// ---------------------------------------------------------------------------

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
