// 운동 중 음악 미니 플레이어 위젯
// MethodChannel을 통해 플랫폼 미디어 컨트롤과 연동
// 현재 재생 중인 곡 정보 표시 및 이전/재생·정지/다음 제어 기능 제공

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// MethodChannel 상수
// ---------------------------------------------------------------------------

const MethodChannel _mediaChannel =
    MethodChannel('com.rhythmicaleskimo.healthApp/media');

// ---------------------------------------------------------------------------
// 미디어 정보 모델
// ---------------------------------------------------------------------------

/// 현재 재생 중인 미디어 정보
class _MediaInfo {
  final String title;
  final String artist;
  final bool isPlaying;

  const _MediaInfo({
    required this.title,
    required this.artist,
    required this.isPlaying,
  });

  static const _MediaInfo empty = _MediaInfo(
    title: '',
    artist: '',
    isPlaying: false,
  );

  bool get hasContent => title.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// 현재 미디어 정보 및 재생 상태
///
/// 플랫폼 미디어 컨트롤에서 정보를 가져옵니다.
/// 네이티브 구현 전까지 빈 상태를 반환합니다.
final _mediaInfoProvider = StateNotifierProvider<_MediaInfoNotifier, _MediaInfo>(
  (ref) => _MediaInfoNotifier(),
);

class _MediaInfoNotifier extends StateNotifier<_MediaInfo> {
  _MediaInfoNotifier() : super(_MediaInfo.empty) {
    _fetchMediaInfo();
  }

  /// 네이티브에서 현재 재생 중인 미디어 정보 가져오기
  Future<void> _fetchMediaInfo() async {
    try {
      final result =
          await _mediaChannel.invokeMethod<Map>('getMediaInfo');
      if (result == null) return;
      state = _MediaInfo(
        title: result['title'] as String? ?? '',
        artist: result['artist'] as String? ?? '',
        isPlaying: result['isPlaying'] as bool? ?? false,
      );
    } on PlatformException {
      // 네이티브 미구현 시 빈 상태 유지
    } catch (_) {
      // 기타 오류 무시
    }
  }

  /// 재생/정지 토글
  Future<void> togglePlayPause() async {
    try {
      await _mediaChannel.invokeMethod<void>('togglePlayPause');
      // 로컬 상태 즉시 업데이트 (낙관적 UI)
      state = _MediaInfo(
        title: state.title,
        artist: state.artist,
        isPlaying: !state.isPlaying,
      );
    } on PlatformException {
      // 무시
    } catch (_) {
      // 무시
    }
  }

  /// 다음 곡으로
  Future<void> skipNext() async {
    try {
      await _mediaChannel.invokeMethod<void>('skipNext');
      await Future.delayed(const Duration(milliseconds: 300));
      await _fetchMediaInfo();
    } on PlatformException {
      // 무시
    } catch (_) {
      // 무시
    }
  }

  /// 이전 곡으로
  Future<void> skipPrevious() async {
    try {
      await _mediaChannel.invokeMethod<void>('skipPrevious');
      await Future.delayed(const Duration(milliseconds: 300));
      await _fetchMediaInfo();
    } on PlatformException {
      // 무시
    } catch (_) {
      // 무시
    }
  }

  /// 기본 음악 앱 실행
  Future<void> openMusicApp() async {
    try {
      await _mediaChannel.invokeMethod<void>('openMusicApp');
    } on PlatformException {
      // 무시
    } catch (_) {
      // 무시
    }
  }
}

// ---------------------------------------------------------------------------
// MusicMiniPlayer 위젯
// ---------------------------------------------------------------------------

/// 운동 세션 중 표시되는 음악 미니 플레이어 위젯
///
/// 높이: ~56px, 반투명 다크 배경
/// - 음악이 재생 중인 경우: 곡 제목, 이전/재생·정지/다음 버튼 표시
/// - 음악이 없는 경우: "음악 재생" 버튼 표시
class MusicMiniPlayer extends ConsumerWidget {
  const MusicMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaInfo = ref.watch(_mediaInfoProvider);
    final notifier = ref.read(_mediaInfoProvider.notifier);

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: mediaInfo.hasContent
          ? _PlayerControls(
              mediaInfo: mediaInfo,
              onTogglePlay: notifier.togglePlayPause,
              onSkipNext: notifier.skipNext,
              onSkipPrevious: notifier.skipPrevious,
            )
          : _OpenMusicButton(onTap: notifier.openMusicApp),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 플레이어 컨트롤 바
// ---------------------------------------------------------------------------

class _PlayerControls extends StatelessWidget {
  final _MediaInfo mediaInfo;
  final VoidCallback onTogglePlay;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;

  const _PlayerControls({
    required this.mediaInfo,
    required this.onTogglePlay,
    required this.onSkipNext,
    required this.onSkipPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 음악 노트 아이콘
          const Icon(
            Icons.music_note,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),

          // 곡 제목 + 아티스트 (스크롤 텍스트)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScrollingText(
                  text: mediaInfo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (mediaInfo.artist.isNotEmpty)
                  Text(
                    mediaInfo.artist,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // 이전 곡 버튼
          _ControlButton(
            icon: Icons.skip_previous,
            onTap: onSkipPrevious,
          ),

          // 재생 / 정지 버튼
          _ControlButton(
            icon: mediaInfo.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
            onTap: onTogglePlay,
          ),

          // 다음 곡 버튼
          _ControlButton(
            icon: Icons.skip_next,
            onTap: onSkipNext,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 음악 앱 열기 버튼 (미디어 없을 때)
// ---------------------------------------------------------------------------

class _OpenMusicButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenMusicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.music_note, color: Colors.white54, size: 20),
            SizedBox(width: 10),
            Text(
              '음악 재생', // TODO: l10n
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 컨트롤 버튼
// ---------------------------------------------------------------------------

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: size),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 18,
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 스크롤 텍스트 (긴 제목 처리)
// ---------------------------------------------------------------------------

class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({required this.text, required this.style});

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    // 텍스트가 충분히 길 때만 스크롤 애니메이션 실행
    if (widget.text.length > 20) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
