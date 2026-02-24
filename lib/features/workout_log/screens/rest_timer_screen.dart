import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;
  final String? exerciseName;
  final int? nextSetNumber;
  final String? previousSetInfo;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 90,
    this.isRunning = false,
    this.isCompleted = false,
    this.exerciseName,
    this.nextSetNumber,
    this.previousSetInfo,
  });

  double get progress {
    if (totalSeconds == 0) return 0;
    return remainingSeconds / totalSeconds;
  }

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    String? exerciseName,
    int? nextSetNumber,
    String? previousSetInfo,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      exerciseName: exerciseName ?? this.exerciseName,
      nextSetNumber: nextSetNumber ?? this.nextSetNumber,
      previousSetInfo: previousSetInfo ?? this.previousSetInfo,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier({
    int initialSeconds = 90,
    String? exerciseName,
    int? nextSetNumber,
    String? previousSetInfo,
  }) : super(RestTimerState(
          totalSeconds: initialSeconds,
          remainingSeconds: initialSeconds,
          isRunning: false,
          isCompleted: false,
          exerciseName: exerciseName,
          nextSetNumber: nextSetNumber,
          previousSetInfo: previousSetInfo,
        )) {
    // Auto-start on creation
    start();
  }

  void start() {
    if (state.isCompleted || state.remainingSeconds == 0) return;
    _startTick();
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.isCompleted || state.remainingSeconds == 0) return;
    _startTick();
    state = state.copyWith(isRunning: true);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
      isCompleted: false,
    );
  }

  void skip() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      isCompleted: true,
    );
    HapticFeedback.lightImpact();
  }

  void setDuration(int seconds) {
    final wasRunning = state.isRunning;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
      isCompleted: false,
    );
    if (wasRunning) start();
  }

  void addTime(int seconds) {
    if (state.isCompleted) return;
    final newRemaining = state.remainingSeconds + seconds;
    final newTotal =
        newRemaining > state.totalSeconds ? newRemaining : state.totalSeconds;
    state = state.copyWith(
      totalSeconds: newTotal,
      remainingSeconds: newRemaining,
      isCompleted: false,
    );
  }

  void subtractTime(int seconds) {
    if (state.isCompleted) return;
    final newRemaining = (state.remainingSeconds - seconds).clamp(0, state.totalSeconds);
    if (newRemaining == 0) {
      _timer?.cancel();
      _timer = null;
      state = state.copyWith(
        remainingSeconds: 0,
        isRunning: false,
        isCompleted: true,
      );
      _onCompleted();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.remainingSeconds <= 1) {
        t.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          isCompleted: true,
        );
        _onCompleted();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _onCompleted() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider factory
// ---------------------------------------------------------------------------

// Family provider so callers can inject context (exercise info, duration)
final restTimerScreenProvider = StateNotifierProvider.autoDispose
    .family<RestTimerNotifier, RestTimerState, RestTimerArgs>(
  (ref, args) => RestTimerNotifier(
    initialSeconds: args.initialSeconds,
    exerciseName: args.exerciseName,
    nextSetNumber: args.nextSetNumber,
    previousSetInfo: args.previousSetInfo,
  ),
);

class RestTimerArgs {
  final int initialSeconds;
  final String? exerciseName;
  final int? nextSetNumber;
  final String? previousSetInfo;

  const RestTimerArgs({
    this.initialSeconds = 90,
    this.exerciseName,
    this.nextSetNumber,
    this.previousSetInfo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestTimerArgs &&
          other.initialSeconds == initialSeconds &&
          other.exerciseName == exerciseName &&
          other.nextSetNumber == nextSetNumber &&
          other.previousSetInfo == previousSetInfo;

  @override
  int get hashCode => Object.hash(
        initialSeconds,
        exerciseName,
        nextSetNumber,
        previousSetInfo,
      );
}

// ---------------------------------------------------------------------------
// Public entry point: show the overlay
// ---------------------------------------------------------------------------

/// Show a full-screen rest timer dialog on top of the current route.
Future<void> showRestTimerScreen(
  BuildContext context, {
  int initialSeconds = 90,
  String? exerciseName,
  int? nextSetNumber,
  String? previousSetInfo,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (_) => RestTimerScreen(
      args: RestTimerArgs(
        initialSeconds: initialSeconds,
        exerciseName: exerciseName,
        nextSetNumber: nextSetNumber,
        previousSetInfo: previousSetInfo,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Screen Widget
// ---------------------------------------------------------------------------

class RestTimerScreen extends ConsumerStatefulWidget {
  final RestTimerArgs args;

  const RestTimerScreen({super.key, required this.args});

  @override
  ConsumerState<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends ConsumerState<RestTimerScreen>
    with SingleTickerProviderStateMixin {
  static const List<int> _presets = [30, 60, 90, 120, 180, 300];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  RestTimerNotifier get _notifier =>
      ref.read(restTimerScreenProvider(widget.args).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restTimerScreenProvider(widget.args));
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = state.isCompleted;

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar
                _TopBar(
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),

                // Context info
                _ContextInfo(state: state),
                const SizedBox(height: 24),

                // Circular timer
                Expanded(
                  child: Center(
                    child: _CircularTimer(
                      state: state,
                      pulseAnimation: _pulseAnimation,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // +/- 15s adjust buttons
                _TimeAdjustRow(
                  onAdd: () => _notifier.addTime(15),
                  onSubtract: () => _notifier.subtractTime(15),
                  enabled: !isCompleted,
                ),
                const SizedBox(height: 20),

                // Preset chips
                _PresetChips(
                  presets: _presets,
                  selectedSeconds: state.totalSeconds,
                  onSelect: (s) => _notifier.setDuration(s),
                ),
                const SizedBox(height: 24),

                // Control buttons
                _ControlRow(
                  state: state,
                  onPlayPause: () {
                    if (state.isRunning) {
                      _notifier.pause();
                    } else {
                      _notifier.resume();
                    }
                  },
                  onReset: () => _notifier.reset(),
                  onSkip: () {
                    _notifier.skip();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 22),
        const SizedBox(width: 8),
        Text(
          l10n.restTimer,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          tooltip: l10n.close,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Context info (exercise name, next set, previous set)
// ---------------------------------------------------------------------------

class _ContextInfo extends StatelessWidget {
  final RestTimerState state;
  const _ContextInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasInfo = state.exerciseName != null ||
        state.nextSetNumber != null ||
        state.previousSetInfo != null;
    if (!hasInfo) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          if (state.exerciseName != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  state.exerciseName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (state.nextSetNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.nextSet} ${state.nextSetNumber}${l10n.set}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
          if (state.previousSetInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.previousSet} ${state.previousSetInfo}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular Timer
// ---------------------------------------------------------------------------

class _CircularTimer extends StatelessWidget {
  final RestTimerState state;
  final Animation<double> pulseAnimation;
  final ColorScheme colorScheme;

  const _CircularTimer({
    required this.state,
    required this.pulseAnimation,
    required this.colorScheme,
  });

  String get _formattedTime {
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompleted = state.isCompleted;
    final arcColor = isCompleted ? const Color(0xFF4CAF50) : colorScheme.primary;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isCompleted ? pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(
          painter: _CircularTimerPainter(
            progress: state.progress,
            arcColor: arcColor,
            trackColor: Colors.white.withValues(alpha: 0.12),
            strokeWidth: 14,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Time text
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    height: 1,
                  ),
                  child: Text(_formattedTime),
                ),
                const SizedBox(height: 8),
                // Status label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isCompleted
                      ? Text(
                          l10n.timerDone,
                          key: const ValueKey('completed'),
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        )
                      : Text(
                          state.isRunning ? l10n.inProgress : l10n.paused,
                          key: ValueKey(state.isRunning),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter – circular arc countdown
// ---------------------------------------------------------------------------

class _CircularTimerPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty
  final Color arcColor;
  final Color trackColor;
  final double strokeWidth;

  const _CircularTimerPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc (foreground – clockwise, shrinking)
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2; // top of circle
      final sweepAngle = 2 * math.pi * progress; // shrinks as progress → 0

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.trackColor != trackColor;
  }
}

// ---------------------------------------------------------------------------
// +/- 15s adjustment row
// ---------------------------------------------------------------------------

class _TimeAdjustRow extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onSubtract;
  final bool enabled;

  const _TimeAdjustRow({
    required this.onAdd,
    required this.onSubtract,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AdjustButton(
          label: l10n.minus15sec,
          icon: Icons.remove_circle_outline,
          onPressed: enabled ? onSubtract : null,
        ),
        const SizedBox(width: 24),
        _AdjustButton(
          label: l10n.plus15sec,
          icon: Icons.add_circle_outline,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _AdjustButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
            isEnabled ? Colors.white70 : Colors.white.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset Chips
// ---------------------------------------------------------------------------

class _PresetChips extends StatelessWidget {
  final List<int> presets;
  final int selectedSeconds;
  final ValueChanged<int> onSelect;

  const _PresetChips({
    required this.presets,
    required this.selectedSeconds,
    required this.onSelect,
  });

  String _label(int s, AppLocalizations l10n) {
    final m = s ~/ 60;
    final rem = s % 60;
    if (m == 0) return l10n.secondsUnit(s);
    if (rem == 0) return l10n.minutesUnit(m);
    return '${l10n.minutesUnit(m)} ${l10n.secondsUnit(rem)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: presets.map((s) {
        final isSelected = s == selectedSeconds;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ChoiceChip(
            label: Text(_label(s, l10n)),
            selected: isSelected,
            onSelected: (_) => onSelect(s),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Control Row (play/pause, reset, skip)
// ---------------------------------------------------------------------------

class _ControlRow extends StatelessWidget {
  final RestTimerState state;
  final VoidCallback onPlayPause;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  const _ControlRow({
    required this.state,
    required this.onPlayPause,
    required this.onReset,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompleted = state.isCompleted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _CircleIconButton(
          icon: Icons.replay_rounded,
          label: l10n.reset,
          onPressed: onReset,
          color: Colors.white60,
          size: 52,
        ),
        const SizedBox(width: 20),

        // Play/Pause – primary action
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isCompleted
              ? _CircleIconButton(
                  key: const ValueKey('completed_check'),
                  icon: Icons.check_rounded,
                  label: l10n.complete,
                  onPressed: () => Navigator.of(context).pop(),
                  color: const Color(0xFF4CAF50),
                  size: 72,
                  isPrimary: true,
                )
              : _CircleIconButton(
                  key: ValueKey(state.isRunning),
                  icon: state.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: state.isRunning ? l10n.paused : l10n.start,
                  onPressed: onPlayPause,
                  color: Theme.of(context).colorScheme.primary,
                  size: 72,
                  isPrimary: true,
                ),
        ),
        const SizedBox(width: 20),

        // Skip button
        _CircleIconButton(
          icon: Icons.skip_next_rounded,
          label: l10n.skipTimer,
          onPressed: onSkip,
          color: Colors.white60,
          size: 52,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final bool isPrimary;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isPrimary ? color : Colors.white.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
