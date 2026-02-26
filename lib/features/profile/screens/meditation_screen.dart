// 명상/호흡 운동 화면
// 운동 전후 집중, 회복, 스트레스 해소를 위한 가이드 호흡 세션
// AnimationController로 숨쉬기 원 애니메이션, SharedPreferences로 세션 수 저장

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 호흡 패턴 정의
// ---------------------------------------------------------------------------

/// 호흡 페이즈 종류
enum BreathPhase {
  inhale('들숨', Colors.teal),
  holdAfterInhale('참기', Colors.indigo),
  exhale('날숨', Colors.blueGrey),
  holdAfterExhale('참기', Colors.indigo);

  final String label;
  final Color color;
  const BreathPhase(this.label, this.color);
}

/// 호흡 패턴 (각 페이즈의 초 수)
class BreathPattern {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdAfterInhaleSeconds;
  final int exhaleSeconds;
  final int holdAfterExhaleSeconds;
  final Color primaryColor;

  const BreathPattern({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdAfterInhaleSeconds,
    required this.exhaleSeconds,
    required this.holdAfterExhaleSeconds,
    required this.primaryColor,
  });

  /// 한 사이클의 총 초 수
  int get cycleDuration =>
      inhaleSeconds +
      holdAfterInhaleSeconds +
      exhaleSeconds +
      holdAfterExhaleSeconds;

  /// 페이즈 목록 (초 단위)
  List<(BreathPhase, int)> get phases => [
        (BreathPhase.inhale, inhaleSeconds),
        if (holdAfterInhaleSeconds > 0) (BreathPhase.holdAfterInhale, holdAfterInhaleSeconds),
        (BreathPhase.exhale, exhaleSeconds),
        if (holdAfterExhaleSeconds > 0) (BreathPhase.holdAfterExhale, holdAfterExhaleSeconds),
      ];
}

/// 사전 정의된 호흡 패턴
class BreathPatterns {
  static const boxBreathing = BreathPattern(
    name: '박스 호흡',
    description: '4-4-4-4 패턴으로 집중력과 안정감 향상',
    inhaleSeconds: 4,
    holdAfterInhaleSeconds: 4,
    exhaleSeconds: 4,
    holdAfterExhaleSeconds: 4,
    primaryColor: Color(0xFF2196F3),
  );

  static const relaxation478 = BreathPattern(
    name: '4-7-8 이완',
    description: '불안 해소와 빠른 수면 유도에 효과적',
    inhaleSeconds: 4,
    holdAfterInhaleSeconds: 7,
    exhaleSeconds: 8,
    holdAfterExhaleSeconds: 0,
    primaryColor: Color(0xFF9C27B0),
  );

  static const deepBreathing = BreathPattern(
    name: '복식 호흡',
    description: '스트레스 해소와 부교감신경 활성화',
    inhaleSeconds: 5,
    holdAfterInhaleSeconds: 0,
    exhaleSeconds: 5,
    holdAfterExhaleSeconds: 0,
    primaryColor: Color(0xFF4CAF50),
  );
}

/// 세션 타입 (사전 설정)
class MeditationSessionType {
  final String name;
  final String subtitle;
  final IconData icon;
  final BreathPattern pattern;
  final int durationMinutes;
  final Color color;

  const MeditationSessionType({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.pattern,
    required this.durationMinutes,
    required this.color,
  });
}

const List<MeditationSessionType> kSessionTypes = [
  MeditationSessionType(
    name: '운동 전 집중',
    subtitle: '박스 호흡 · 3분',
    icon: Icons.sports_gymnastics,
    pattern: BreathPatterns.boxBreathing,
    durationMinutes: 3,
    color: Color(0xFF2196F3),
  ),
  MeditationSessionType(
    name: '운동 후 회복',
    subtitle: '4-7-8 이완 · 5분',
    icon: Icons.self_improvement,
    pattern: BreathPatterns.relaxation478,
    durationMinutes: 5,
    color: Color(0xFF9C27B0),
  ),
  MeditationSessionType(
    name: '스트레스 해소',
    subtitle: '복식 호흡 · 5분',
    icon: Icons.spa,
    pattern: BreathPatterns.deepBreathing,
    durationMinutes: 5,
    color: Color(0xFF4CAF50),
  ),
];

// ---------------------------------------------------------------------------
// MeditationScreen
// ---------------------------------------------------------------------------

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  // 세션 상태
  bool _sessionActive = false;
  bool _sessionComplete = false;
  int _completedSessions = 0;

  // 선택된 세션 타입 (null = 커스텀)
  MeditationSessionType? _selectedType;
  BreathPattern _pattern = BreathPatterns.boxBreathing;
  int _durationMinutes = 3;

  // 호흡 애니메이션
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // 세션 타이머
  int _totalRemainingSeconds = 0;
  int _phaseRemainingSeconds = 0;
  int _currentPhaseIndex = 0;
  Timer? _sessionTimer;

  // 현재 페이즈
  BreathPhase get _currentPhase =>
      _pattern.phases[_currentPhaseIndex].$1;

  int get _currentPhaseDuration =>
      _pattern.phases[_currentPhaseIndex].$2;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _loadCompletedSessions();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _completedSessions = prefs.getInt('meditation_completed_sessions') ?? 0;
      });
    }
  }

  Future<void> _saveCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('meditation_completed_sessions', _completedSessions);
  }

  // ── 세션 제어 ─────────────────────────────────────────────────────────────

  void _startSession() {
    setState(() {
      _sessionActive = true;
      _sessionComplete = false;
      _totalRemainingSeconds = _durationMinutes * 60;
      _currentPhaseIndex = 0;
      _phaseRemainingSeconds = _currentPhaseDuration;
    });

    _startPhaseAnimation();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      _totalRemainingSeconds--;
      _phaseRemainingSeconds--;

      // 세션 완료
      if (_totalRemainingSeconds <= 0) {
        timer.cancel();
        _onSessionComplete();
        return;
      }

      // 페이즈 전환
      if (_phaseRemainingSeconds <= 0) {
        _currentPhaseIndex =
            (_currentPhaseIndex + 1) % _pattern.phases.length;
        _phaseRemainingSeconds = _currentPhaseDuration;
        _onPhaseTransition();
      }
    });
  }

  void _onPhaseTransition() {
    // 햅틱 피드백
    HapticFeedback.lightImpact();
    // 새 페이즈 애니메이션 시작
    _startPhaseAnimation();
  }

  void _startPhaseAnimation() {
    _breathController.stop();
    _breathController.duration = Duration(seconds: _currentPhaseDuration);

    switch (_currentPhase) {
      case BreathPhase.inhale:
        // 들숨: 원이 커짐
        _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _breathController, curve: Curves.easeIn),
        );
        _breathController.forward(from: 0.0);

      case BreathPhase.holdAfterInhale:
        // 들숨 후 참기: 최대 크기 유지
        _breathAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
          CurvedAnimation(parent: _breathController, curve: Curves.linear),
        );
        _breathController.forward(from: 0.0);

      case BreathPhase.exhale:
        // 날숨: 원이 작아짐
        _breathAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
          CurvedAnimation(parent: _breathController, curve: Curves.easeOut),
        );
        _breathController.forward(from: 0.0);

      case BreathPhase.holdAfterExhale:
        // 날숨 후 참기: 최소 크기 유지
        _breathAnimation = Tween<double>(begin: 0.6, end: 0.6).animate(
          CurvedAnimation(parent: _breathController, curve: Curves.linear),
        );
        _breathController.forward(from: 0.0);
    }
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _breathController.stop();
    setState(() {
      _sessionActive = false;
      _sessionComplete = false;
    });
  }

  void _onSessionComplete() {
    _breathController.stop();
    _completedSessions++;
    _saveCompletedSessions();
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionActive = false;
      _sessionComplete = true;
    });
  }

  // ── UI 빌더 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '명상 & 호흡',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.self_improvement, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_completedSessions회 완료',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _sessionComplete
          ? _buildCompletionScreen()
          : _sessionActive
              ? _buildActiveSession()
              : _buildSessionSelector(),
    );
  }

  // ── 세션 선택 화면 ─────────────────────────────────────────────────────────

  Widget _buildSessionSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 설명
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 마음 준비',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '규칙적인 호흡은 운동 퍼포먼스와 회복에 직접적인 영향을 줍니다. 세션을 선택하세요.',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            '세션 선택',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 사전 설정 세션 카드
          ...kSessionTypes.map((type) => _SessionTypeCard(
                sessionType: type,
                isSelected: _selectedType == type,
                onTap: () {
                  setState(() {
                    _selectedType = type;
                    _pattern = type.pattern;
                    _durationMinutes = type.durationMinutes;
                  });
                },
              )),

          const SizedBox(height: 16),
          // 커스텀 세션
          _buildCustomSection(),

          const SizedBox(height: 32),
          // 시작 버튼
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pattern.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                '세션 시작 ($_durationMinutes분)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCustomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedType == null
              ? Colors.white38
              : Colors.white.withValues(alpha: 0.1),
          width: _selectedType == null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('커스텀',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('패턴과 시간을 직접 설정',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedType = null;
                }),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedType == null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: _selectedType == null
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ),
            ],
          ),
          if (_selectedType == null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            // 패턴 선택
            const Text('호흡 패턴',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _PatternChip(
                  label: '박스 4-4-4-4',
                  isSelected: _pattern == BreathPatterns.boxBreathing,
                  color: BreathPatterns.boxBreathing.primaryColor,
                  onTap: () => setState(
                      () => _pattern = BreathPatterns.boxBreathing),
                ),
                const SizedBox(width: 8),
                _PatternChip(
                  label: '4-7-8',
                  isSelected: _pattern == BreathPatterns.relaxation478,
                  color: BreathPatterns.relaxation478.primaryColor,
                  onTap: () => setState(
                      () => _pattern = BreathPatterns.relaxation478),
                ),
                const SizedBox(width: 8),
                _PatternChip(
                  label: '복식',
                  isSelected: _pattern == BreathPatterns.deepBreathing,
                  color: BreathPatterns.deepBreathing.primaryColor,
                  onTap: () => setState(
                      () => _pattern = BreathPatterns.deepBreathing),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 시간 선택
            const Text('세션 시간',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [1, 3, 5, 10]
                  .map(
                    (min) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _DurationChip(
                        minutes: min,
                        isSelected: _durationMinutes == min,
                        onTap: () =>
                            setState(() => _durationMinutes = min),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── 활성 세션 화면 ─────────────────────────────────────────────────────────

  Widget _buildActiveSession() {
    final totalSeconds = _durationMinutes * 60;
    final progress = 1.0 - (_totalRemainingSeconds / totalSeconds);
    final minutes = _totalRemainingSeconds ~/ 60;
    final seconds = _totalRemainingSeconds % 60;
    final phaseColor = _currentPhase.color;

    return Column(
      children: [
        // 전체 진행 바
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(_pattern.primaryColor),
          minHeight: 3,
        ),

        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 호흡 원 애니메이션
                AnimatedBuilder(
                  animation: _breathAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 240 * _breathAnimation.value,
                      height: 240 * _breathAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            phaseColor.withValues(alpha: 0.3),
                            phaseColor.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: phaseColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPhase.label,
                              style: TextStyle(
                                color: phaseColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_phaseRemainingSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 패턴 안내
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _pattern.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 남은 시간
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} 남음',
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                ),

                const SizedBox(height: 48),

                // 페이즈 인디케이터
                _buildPhaseIndicator(),

                const SizedBox(height: 48),

                // 정지 버튼
                TextButton.icon(
                  onPressed: _stopSession,
                  icon: const Icon(Icons.stop_circle_outlined,
                      color: Colors.white54),
                  label: const Text(
                    '세션 종료',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _pattern.phases.asMap().entries.map((entry) {
        final isActive = entry.key == _currentPhaseIndex;
        final phase = entry.value.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? phase.color : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 세션 완료 화면 ─────────────────────────────────────────────────────────

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 완료 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _pattern.primaryColor.withValues(alpha: 0.3),
                    _pattern.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: _pattern.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: _pattern.primaryColor,
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              '세션 완료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_durationMinutes분 $_pattern.name 완료',
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),

            const SizedBox(height: 32),

            // 누적 기록
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.self_improvement,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '총 $_completedSessions번 세션 완료',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 다시 하기
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sessionComplete = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pattern.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '다시 하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '홈으로',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 하위 위젯들
// ---------------------------------------------------------------------------

class _SessionTypeCard extends StatelessWidget {
  final MeditationSessionType sessionType;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionTypeCard({
    required this.sessionType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? sessionType.color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? sessionType.color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sessionType.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sessionType.icon,
                    color: sessionType.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionType.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sessionType.subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: sessionType.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PatternChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white54,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white54 : Colors.transparent,
          ),
        ),
        child: Text(
          '$minutes분',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
