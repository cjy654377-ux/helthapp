// AI 음식 사진 인식 화면
// ML Kit Image Labeling으로 음식 감지 → 데이터베이스 매칭 → 식단 추가

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';

// ---------------------------------------------------------------------------
// 음식 감지 결과 모델
// ---------------------------------------------------------------------------

/// AI가 감지한 음식 아이템 + 매칭된 데이터베이스 항목
class _DetectedFoodItem {
  final FoodItem foodItem;
  final double confidence; // ML Kit 신뢰도 (0~1)
  double portionMultiplier; // 1.0 = 1회 제공량 (사용자가 +/- 버튼으로 수정)
  bool isSelected; // 식단 추가 체크박스 상태

  _DetectedFoodItem({
    required this.foodItem,
    required this.confidence,
  })  : portionMultiplier = 1.0,
        isSelected = true;

  double get estimatedCalories =>
      foodItem.calories * portionMultiplier;
}

// ---------------------------------------------------------------------------
// 로컬 State 클래스
// ---------------------------------------------------------------------------

enum _PhotoScreenState { idle, processing, results }

// ---------------------------------------------------------------------------
// ML Kit 음식 키워드 매핑
// ---------------------------------------------------------------------------

/// ML Kit 라벨 -> 음식 데이터베이스 키워드 매핑
/// 감지된 라벨로부터 관련 음식 항목을 찾기 위한 매핑
const Map<String, List<String>> _labelToFoodKeywords = {
  // 밥/곡물
  'rice': ['쌀밥', '현미밥', 'rice'],
  'food': [''],
  'dish': [''],
  'meal': [''],
  'cuisine': [''],
  'ingredient': [''],
  // 육류
  'meat': ['닭가슴살', '소고기', '돼지고기', '불고기', 'chicken', 'beef', 'pork'],
  'chicken': ['닭가슴살', 'chicken'],
  'beef': ['소고기', '불고기', 'beef'],
  'pork': ['돼지고기', '삼겹살', 'pork'],
  'fish': ['연어', '참치', 'salmon', 'tuna'],
  'salmon': ['연어', 'salmon'],
  'seafood': ['연어', '참치', 'seafood'],
  // 채소
  'vegetable': ['브로콜리', '시금치', 'vegetable'],
  'broccoli': ['브로콜리', 'broccoli'],
  'spinach': ['시금치', 'spinach'],
  'salad': ['시금치 나물', 'salad'],
  // 과일
  'fruit': ['바나나', '사과', '블루베리', 'fruit'],
  'banana': ['바나나', 'banana'],
  'apple': ['사과', 'apple'],
  'berry': ['블루베리', 'berry'],
  // 달걀/유제품
  'egg': ['달걀', 'egg'],
  'dairy': ['우유', '그릭 요거트', '코티지 치즈', 'dairy'],
  'milk': ['우유', 'milk'],
  'yogurt': ['그릭 요거트', 'yogurt'],
  'cheese': ['코티지 치즈', 'cheese'],
  // 한식
  'kimchi': ['김치', '김치찌개', '김치볶음밥', 'kimchi'],
  'soup': ['김치찌개', '된장찌개', '순두부찌개', 'soup'],
  'stew': ['김치찌개', '된장찌개', 'stew'],
  // 탄수화물
  'bread': ['오트밀', 'bread'],
  'pasta': ['오트밀', 'pasta'],
  'potato': ['감자', '고구마', 'potato'],
  'sweet potato': ['고구마', 'sweet potato'],
  // 견과류
  'nut': ['아몬드', '땅콩버터', 'nut'],
  'almond': ['아몬드', 'almond'],
  // 아보카도
  'avocado': ['아보카도', 'avocado'],
};

// ---------------------------------------------------------------------------
// MealPhotoScreen
// ---------------------------------------------------------------------------

class MealPhotoScreen extends ConsumerStatefulWidget {
  const MealPhotoScreen({super.key});

  @override
  ConsumerState<MealPhotoScreen> createState() => _MealPhotoScreenState();
}

class _MealPhotoScreenState extends ConsumerState<MealPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  _PhotoScreenState _screenState = _PhotoScreenState.idle;
  List<_DetectedFoodItem> _detectedItems = [];
  String _processingMessage = '';

  // 검색 폴백 상태
  bool _showManualSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 이미지 선택
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (xFile == null) return;

      setState(() {
        _selectedImage = File(xFile.path);
        _screenState = _PhotoScreenState.processing;
        _processingMessage = 'AI가 음식을 분석 중...'; // TODO: l10n
        _detectedItems = [];
        _showManualSearch = false;
      });

      await _analyzeImage(File(xFile.path));
    } catch (e) {
      if (mounted) {
        _showError('이미지를 불러오는 중 오류가 발생했습니다.'); // TODO: l10n
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ML Kit 이미지 분석
  // ---------------------------------------------------------------------------

  Future<void> _analyzeImage(File imageFile) async {
    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.5);
    final ImageLabeler labeler = ImageLabeler(options: options);

    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final List<ImageLabel> labels = await labeler.processImage(inputImage);

      // 감지된 라벨로부터 음식 매칭
      final allFoods = kAllFoodItems;
      final Map<String, _DetectedFoodItem> matchedItems = {};

      for (final label in labels) {
        final labelLower = label.label.toLowerCase();

        // 라벨 키워드 매핑 검색
        for (final entry in _labelToFoodKeywords.entries) {
          if (labelLower.contains(entry.key) ||
              entry.key.contains(labelLower)) {
            // 키워드와 일치하는 음식 데이터베이스 항목 검색
            for (final keyword in entry.value) {
              if (keyword.isEmpty) continue;
              for (final food in allFoods) {
                final nameMatch =
                    food.name.toLowerCase().contains(keyword.toLowerCase());
                final nameEnMatch = food.nameEn
                        ?.toLowerCase()
                        .contains(keyword.toLowerCase()) ??
                    false;

                if (nameMatch || nameEnMatch) {
                  // 이미 추가된 항목이면 신뢰도가 더 높은 것으로 교체
                  if (!matchedItems.containsKey(food.id) ||
                      label.confidence >
                          matchedItems[food.id]!.confidence) {
                    matchedItems[food.id] = _DetectedFoodItem(
                      foodItem: food,
                      confidence: label.confidence,
                    );
                  }
                }
              }
            }
          }
        }
      }

      // 신뢰도 내림차순 정렬, 최대 6개
      final sortedItems = matchedItems.values.toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final topItems = sortedItems.take(6).toList();

      if (mounted) {
        setState(() {
          _detectedItems = topItems;
          _screenState = _PhotoScreenState.results;
          // 매칭 결과 없으면 수동 검색 자동 표시
          _showManualSearch = topItems.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _screenState = _PhotoScreenState.results;
          _showManualSearch = true;
        });
        _showError('AI 분석 중 오류가 발생했습니다. 직접 검색해 주세요.'); // TODO: l10n
      }
    } finally {
      labeler.close();
    }
  }

  // ---------------------------------------------------------------------------
  // 식단에 추가
  // ---------------------------------------------------------------------------

  Future<void> _addToMeal() async {
    final selectedItems =
        _detectedItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      _showError('추가할 음식을 선택해 주세요.'); // TODO: l10n
      return;
    }

    try {
      final dietNotifier = ref.read(dietProvider.notifier);

      // 오늘 날짜에 식사 추가
      await dietNotifier.addMeal(MealType.snack);

      // 방금 추가한 식사 ID 가져오기
      final dietState = ref.read(dietProvider);
      if (dietState.meals.isEmpty) return;
      final mealId = dietState.meals.last.id;

      // 선택된 음식 항목 추가
      for (final item in selectedItems) {
        final amount = item.foodItem.servingSize * item.portionMultiplier;
        await dietNotifier.addFoodToMeal(mealId, item.foodItem, amount);
        await ref
            .read(foodDatabaseProvider.notifier)
            .addToRecent(item.foodItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedItems.length}개 음식이 오늘 식단에 추가되었습니다.', // TODO: l10n
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('식단 추가 중 오류가 발생했습니다.'); // TODO: l10n
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------------------------------------------------------------------------
  // 수동 검색 추가
  // ---------------------------------------------------------------------------

  void _addManualFood(FoodItem food) {
    setState(() {
      // 이미 목록에 있으면 무시
      if (_detectedItems.any((item) => item.foodItem.id == food.id)) return;
      _detectedItems.add(_DetectedFoodItem(
        foodItem: food,
        confidence: 1.0,
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // UI 빌드
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 음식 인식', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사진 영역
                  _PhotoArea(
                    selectedImage: _selectedImage,
                    onCamera: () => _pickImage(ImageSource.camera),
                    onGallery: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: 20),

                  // 처리 중 shimmer
                  if (_screenState == _PhotoScreenState.processing)
                    _ProcessingShimmer(message: _processingMessage),

                  // 결과 영역
                  if (_screenState == _PhotoScreenState.results) ...[
                    if (_detectedItems.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 6),
                          const Text(
                            'AI가 인식한 음식', // TODO: l10n
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(
                                () => _showManualSearch = !_showManualSearch),
                            child: const Text('직접 추가'), // TODO: l10n
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._detectedItems.asMap().entries.map(
                            (entry) => _DetectedFoodCard(
                              item: entry.value,
                              onToggle: (selected) => setState(() =>
                                  _detectedItems[entry.key].isSelected =
                                      selected),
                              onPortionChanged: (multiplier) => setState(() =>
                                  _detectedItems[entry.key].portionMultiplier =
                                      multiplier),
                            ),
                          ),
                    ] else ...[
                      // 결과 없음 - 수동 검색 유도
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'AI가 음식을 인식하지 못했어요.\n직접 검색해서 추가해 보세요.', // TODO: l10n
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 수동 검색 영역
                    if (_showManualSearch) ...[
                      const SizedBox(height: 16),
                      _ManualSearchSection(
                        controller: _searchController,
                        onFoodSelected: _addManualFood,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // 하단 버튼
          if (_screenState == _PhotoScreenState.results &&
              _detectedItems.any((item) => item.isSelected))
            _AddToMealButton(
              selectedCount:
                  _detectedItems.where((item) => item.isSelected).length,
              totalCalories: _detectedItems
                  .where((item) => item.isSelected)
                  .fold(0.0, (sum, item) => sum + item.estimatedCalories),
              onPressed: _addToMeal,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 사진 영역 위젯
// ---------------------------------------------------------------------------

class _PhotoArea extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoArea({
    required this.selectedImage,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              selectedImage!,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  '음식 사진을 촬영하거나 선택하세요', // TODO: l10n
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('카메라'), // TODO: l10n
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('갤러리'), // TODO: l10n
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 처리 중 Shimmer (패키지 없이 직접 구현)
// ---------------------------------------------------------------------------

class _ProcessingShimmer extends StatefulWidget {
  final String message;
  const _ProcessingShimmer({required this.message});

  @override
  State<_ProcessingShimmer> createState() => _ProcessingShimmerState();
}

class _ProcessingShimmerState extends State<_ProcessingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(widget.message,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        // Shimmer 카드들
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [
                        (_animation.value - 0.3).clamp(0.0, 1.0),
                        _animation.value.clamp(0.0, 1.0),
                        (_animation.value + 0.3).clamp(0.0, 1.0),
                      ],
                      colors: [
                        Colors.grey.withValues(alpha: 0.1),
                        Colors.grey.withValues(alpha: 0.2),
                        Colors.grey.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 감지된 음식 카드
// ---------------------------------------------------------------------------

class _DetectedFoodCard extends StatelessWidget {
  final _DetectedFoodItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onPortionChanged;

  const _DetectedFoodCard({
    required this.item,
    required this.onToggle,
    required this.onPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final food = item.foodItem;
    final confidencePct = (item.confidence * 100).toInt();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isSelected
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 체크박스
            Checkbox(
              value: item.isSelected,
              onChanged: (val) => onToggle(val ?? false),
              activeColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // 음식 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // 신뢰도 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _confidenceColor(item.confidence)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$confidencePct%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _confidenceColor(item.confidence),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.estimatedCalories.toStringAsFixed(0)} kcal · '
                    '${(food.servingSize * item.portionMultiplier).toStringAsFixed(0)}${food.servingUnit}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // +/- 버튼
            _PortionControls(
              multiplier: item.portionMultiplier,
              onChanged: onPortionChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.grey;
  }
}

// ---------------------------------------------------------------------------
// 분량 조절 버튼
// ---------------------------------------------------------------------------

class _PortionControls extends StatelessWidget {
  final double multiplier;
  final ValueChanged<double> onChanged;

  const _PortionControls({
    required this.multiplier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
          icon: Icons.remove,
          onPressed: multiplier > 0.5
              ? () => onChanged((multiplier - 0.5).clamp(0.5, 5.0))
              : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${multiplier.toStringAsFixed(1)}x',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        _IconBtn(
          icon: Icons.add,
          onPressed: multiplier < 5.0
              ? () => onChanged((multiplier + 0.5).clamp(0.5, 5.0))
              : null,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onPressed != null
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null ? Colors.orange : Colors.grey,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 수동 검색 섹션
// ---------------------------------------------------------------------------

class _ManualSearchSection extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<FoodItem> onFoodSelected;

  const _ManualSearchSection({
    required this.controller,
    required this.onFoodSelected,
  });

  @override
  ConsumerState<_ManualSearchSection> createState() =>
      _ManualSearchSectionState();
}

class _ManualSearchSectionState extends ConsumerState<_ManualSearchSection> {
  @override
  Widget build(BuildContext context) {
    final filteredFoods = ref.watch(filteredFoodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '직접 검색', // TODO: l10n
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          onChanged: (query) =>
              ref.read(foodDatabaseProvider.notifier).search(query),
          decoration: InputDecoration(
            hintText: '음식 이름으로 검색', // TODO: l10n
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.controller.text.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: filteredFoods.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '검색 결과가 없습니다.', // TODO: l10n
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredFoods.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final food = filteredFoods[i];
                      return ListTile(
                        dense: true,
                        title: Text(food.name,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${food.calories.toStringAsFixed(0)} kcal / ${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: Colors.orange, size: 20),
                        onTap: () {
                          widget.onFoodSelected(food);
                          widget.controller.clear();
                          ref.read(foodDatabaseProvider.notifier).search('');
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 하단 식단 추가 버튼
// ---------------------------------------------------------------------------

class _AddToMealButton extends StatelessWidget {
  final int selectedCount;
  final double totalCalories;
  final VoidCallback onPressed;

  const _AddToMealButton({
    required this.selectedCount,
    required this.totalCalories,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '$selectedCount개 음식 추가 · ${totalCalories.toStringAsFixed(0)} kcal', // TODO: l10n
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
