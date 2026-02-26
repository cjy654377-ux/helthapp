// 트레이너 주도 영상 운동 라이브러리 화면
// 추천 영상 히어로 카드, 카테고리 탭, 영상 그리드, 상세 화면 포함

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/features/workout_guide/providers/video_workout_provider.dart';

// ---------------------------------------------------------------------------
// 카테고리 탭 필터 Provider
// ---------------------------------------------------------------------------

final _selectedCategoryProvider = StateProvider<VideoCategory?>((ref) => null);

// ---------------------------------------------------------------------------
// VideoWorkoutScreen
// ---------------------------------------------------------------------------

/// 트레이너 주도 영상 운동 라이브러리 화면
class VideoWorkoutScreen extends ConsumerWidget {
  const VideoWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredVideoProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final videos = ref.watch(videosByCategory(selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '영상 운동', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // 추천 영상 히어로 카드
          if (featured != null)
            SliverToBoxAdapter(
              child: _FeaturedVideoCard(video: featured),
            ),

          // 카테고리 탭
          SliverToBoxAdapter(
            child: _CategoryTabBar(
              selected: selectedCategory,
              onSelect: (cat) =>
                  ref.read(_selectedCategoryProvider.notifier).state = cat,
            ),
          ),

          // 영상 그리드
          videos.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '해당 카테고리에 영상이 없습니다.', // TODO: l10n
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _VideoCard(video: videos[index]),
                      childCount: videos.length,
                    ),
                  ),
                ),

          // 하단 여백
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 추천 영상 히어로 카드
// ---------------------------------------------------------------------------

class _FeaturedVideoCard extends StatelessWidget {
  final VideoWorkout video;

  const _FeaturedVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, video),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 썸네일 이미지
              _VideoThumbnail(url: video.thumbnailUrl, height: 200),

              // 그라디언트 오버레이
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),

              // 추천 뱃지
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '오늘의 추천', // TODO: l10n
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 프리미엄 뱃지
              if (video.isPremium)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PremiumBadge(),
                ),

              // 재생 버튼
              const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 56,
                ),
              ),

              // 영상 정보 (하단)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video.trainerName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.durationMinutes}분', // TODO: l10n
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 카테고리 탭 바
// ---------------------------------------------------------------------------

class _CategoryTabBar extends StatelessWidget {
  final VideoCategory? selected;
  final ValueChanged<VideoCategory?> onSelect;

  const _CategoryTabBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final categories = [null, ...VideoCategory.values];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          final label = cat?.label ?? '전체'; // TODO: l10n

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: Theme.of(context).colorScheme.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 영상 카드 (그리드 아이템)
// ---------------------------------------------------------------------------

class _VideoCard extends StatelessWidget {
  final VideoWorkout video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, video),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            Stack(
              children: [
                _VideoThumbnail(url: video.thumbnailUrl, height: 110),
                // 재생 버튼 오버레이
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // 프리미엄 뱃지
                if (video.isPremium)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _PremiumBadge(),
                  ),
                // 카테고리 칩
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      video.category.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 영상 정보
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.trainerName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // 시간
                      const Icon(Icons.timer, size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${video.durationMinutes}분', // TODO: l10n
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 난이도 뱃지
                      _DifficultyBadge(difficulty: video.difficulty),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 영상 상세 화면 (플레이어 플레이스홀더 + 정보)
// ---------------------------------------------------------------------------

class VideoWorkoutDetailScreen extends StatelessWidget {
  final VideoWorkout video;

  const VideoWorkoutDetailScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 플레이어 영역 (슬리버 앱바 스타일)
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _VideoPlayerPlaceholder(video: video),
            ),
          ),

          // 하얀 카드 영역 (영상 정보)
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _VideoDetailContent(video: video),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 영상 플레이어 플레이스홀더
// ---------------------------------------------------------------------------

class _VideoPlayerPlaceholder extends StatelessWidget {
  final VideoWorkout video;

  const _VideoPlayerPlaceholder({required this.video});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 썸네일 배경
        _VideoThumbnail(url: video.thumbnailUrl, height: 220),

        // 어두운 오버레이
        Container(color: Colors.black.withValues(alpha: 0.4)),

        // 중앙 재생 아이콘 + "영상 준비 중" 텍스트
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              '영상 준비 중', // TODO: l10n - "Video coming soon"
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Video coming soon',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 영상 상세 정보 콘텐츠
// ---------------------------------------------------------------------------

class _VideoDetailContent extends StatelessWidget {
  final VideoWorkout video;

  const _VideoDetailContent({required this.video});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 + 난이도
          Row(
            children: [
              Chip(
                label: Text(
                  video.category.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                backgroundColor: colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              _DifficultyBadge(difficulty: video.difficulty),
              if (video.isPremium) ...[
                const SizedBox(width: 8),
                _PremiumBadge(),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // 제목
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 트레이너 + 시간 + 조회수
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                video.trainerName,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${video.durationMinutes}분', // TODO: l10n
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.visibility_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${_formatViewCount(video.viewCount)}명', // TODO: l10n
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 설명
          const Text(
            '운동 설명', // TODO: l10n
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.description,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),

          // 대상 신체 부위
          if (video.bodyParts.isNotEmpty) ...[
            const Text(
              '대상 부위', // TODO: l10n
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: video.bodyParts
                  .map(
                    (bp) => Chip(
                      label: Text(
                        bp,
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}만';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}천';
    }
    return count.toString();
  }
}

// ---------------------------------------------------------------------------
// 공용 내부 위젯들
// ---------------------------------------------------------------------------

/// 영상 썸네일 이미지
class _VideoThumbnail extends StatelessWidget {
  final String url;
  final double height;

  const _VideoThumbnail({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white38,
            size: 40,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 난이도 뱃지
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case '초급':
        return Colors.green;
      case '중급':
        return Colors.orange;
      case '고급':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 프리미엄 뱃지
class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 내비게이션 헬퍼
// ---------------------------------------------------------------------------

void _navigateToDetail(BuildContext context, VideoWorkout video) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VideoWorkoutDetailScreen(video: video),
    ),
  );
}
