// 음성 식단 기록 화면
// speech_to_text로 음성 인식 → 텍스트 파싱 → 음식 항목 추출 → 식단 추가

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:health_app/core/models/diet_model.dart';
import 'package:health_app/features/diet/providers/diet_providers.dart';

// ---------------------------------------------------------------------------
// 음성 파싱 결과 모델
// ---------------------------------------------------------------------------

/// 음성 텍스트에서 파싱된 음식 항목
class _ParsedFoodItem {
  final FoodItem foodItem;
  double amount; // 실제 섭취량 (g/ml) - 사용자가 텍스트 필드로 수정 가능하므로 mutable
  bool isSelected; // 식단 추가 체크박스 상태

  _ParsedFoodItem({
    required this.foodItem,
    required this.amount,
  }) : isSelected = true;

  double get estimatedCalories => foodItem.caloriesFor(amount);
  double get estimatedProtein => foodItem.proteinFor(amount);
}

// ---------------------------------------------------------------------------
// 화면 상태 열거형
// ---------------------------------------------------------------------------

enum _VoiceState {
  idle, // 초기 상태 - 마이크 버튼 표시
  listening, // 듣는 중 - 애니메이션
  transcribed, // 변환 완료 - 텍스트 표시 + 파싱 결과
  confirmed, // 확정 - 식단 추가 완료
}

// ---------------------------------------------------------------------------
// 음성 파싱 유틸리티
// ---------------------------------------------------------------------------

/// 분량 패턴 (한국어/영어)
/// 예: "200g", "한 그릇", "two cups", "1개", "반 개"
const Map<String, double> _koreanQuantityMap = {
  '한': 1.0,
  '두': 2.0,
  '세': 3.0,
  '네': 4.0,
  '다섯': 5.0,
  '반': 0.5,
  '하나': 1.0,
  '둘': 2.0,
  '셋': 3.0,
  '넷': 4.0,
};

const Map<String, double> _englishQuantityMap = {
  'one': 1.0,
  'two': 2.0,
  'three': 3.0,
  'four': 4.0,
  'five': 5.0,
  'half': 0.5,
  'a': 1.0,
  'an': 1.0,
};

/// 단위 -> 그램 환산 (근사치)
const Map<String, double> _unitToGrams = {
  'g': 1.0,
  'gram': 1.0,
  'grams': 1.0,
  '그램': 1.0,
  'kg': 1000.0,
  'ml': 1.0,
  '밀리리터': 1.0,
  'l': 1000.0,
  '리터': 1000.0,
  '그릇': 1.0, // 1그릇 = 1회 제공량으로 처리
  '공기': 1.0, // 밥 한 공기
  '개': 1.0,
  '조각': 1.0,
  '쪽': 1.0,
  '컵': 240.0,
  'cup': 240.0,
  'cups': 240.0,
  'bowl': 1.0, // 1회 제공량
  'piece': 1.0,
  'pieces': 1.0,
  'slice': 1.0,
  'slices': 1.0,
};

/// 텍스트에서 음식 항목 + 분량 파싱
List<_ParsedFoodItem> _parseVoiceText(
    String text, List<FoodItem> allFoods) {
  final result = <_ParsedFoodItem>[];
  final lowerText = text.toLowerCase();

  for (final food in allFoods) {
    final foodNameLower = food.name.toLowerCase();
    final foodNameEnLower = food.nameEn?.toLowerCase() ?? '';

    // 음식 이름이 텍스트에 포함되어 있는지 확인
    bool found = lowerText.contains(foodNameLower);
    if (!found && foodNameEnLower.isNotEmpty) {
      found = lowerText.contains(foodNameEnLower);
    }

    // 짧은 이름 (2자 이하)은 노이즈 방지를 위해 정확 매칭
    if (food.name.length <= 2) {
      found = lowerText.split(' ').contains(foodNameLower) ||
          lowerText.contains(' $foodNameLower ') ||
          lowerText.startsWith('$foodNameLower ') ||
          lowerText.endsWith(' $foodNameLower');
    }

    if (!found) continue;

    // 분량 파싱 시도
    double amount = food.servingSize; // 기본값: 1회 제공량

    // 숫자 + 단위 패턴 검색 (예: "200g", "300ml")
    final numericPattern =
        RegExp(r'(\d+\.?\d*)\s*(g|kg|ml|l|gram|grams|그램|밀리리터|리터)');
    final numericMatch = numericPattern.firstMatch(lowerText);
    if (numericMatch != null) {
      final numStr = numericMatch.group(1) ?? '';
      final unit = numericMatch.group(2) ?? '';
      final num = double.tryParse(numStr) ?? 1.0;
      final multiplier = _unitToGrams[unit] ?? 1.0;

      // 단위가 그램/ml이면 직접 사용, 아니면 1회 제공량 배수로 처리
      if (multiplier > 1.0) {
        amount = num * multiplier;
      } else {
        amount = num;
      }
    } else {
      // 한국어 수량 검색 (예: "한 그릇", "두 개")
      double multiplier = 1.0;
      for (final entry in _koreanQuantityMap.entries) {
        if (lowerText.contains(entry.key)) {
          multiplier = entry.value;
          break;
        }
      }
      // 영어 수량
      for (final entry in _englishQuantityMap.entries) {
        if (lowerText.split(' ').contains(entry.key)) {
          multiplier = entry.value;
          break;
        }
      }

      // 단위 키워드에 따른 분량 결정
      bool foundUnit = false;
      for (final entry in _unitToGrams.entries) {
        if (lowerText.contains(entry.key)) {
          if (entry.value == 1.0) {
            // 그릇/개 등 = 제공량 배수
            amount = food.servingSize * multiplier;
          } else {
            // 컵 등 고정 그램 단위
            amount = entry.value * multiplier;
          }
          foundUnit = true;
          break;
        }
      }

      if (!foundUnit) {
        amount = food.servingSize * multiplier;
      }
    }

    result.add(_ParsedFoodItem(foodItem: food, amount: amount));
  }

  return result;
}

// ---------------------------------------------------------------------------
// VoiceLoggingScreen
// ---------------------------------------------------------------------------

class VoiceLoggingScreen extends ConsumerStatefulWidget {
  const VoiceLoggingScreen({super.key});

  @override
  ConsumerState<VoiceLoggingScreen> createState() => _VoiceLoggingScreenState();
}

class _VoiceLoggingScreenState extends ConsumerState<VoiceLoggingScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _speechInitializing = false;

  _VoiceState _voiceState = _VoiceState.idle;
  String _transcribedText = '';
  List<_ParsedFoodItem> _parsedItems = [];

  // 애니메이션 컨트롤러 (마이크 펄스)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 수동 검색 폴백
  bool _showManualSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 음성 인식 초기화
  // ---------------------------------------------------------------------------

  Future<void> _initSpeech() async {
    setState(() => _speechInitializing = true);
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() {
              _voiceState = _VoiceState.idle;
            });
            _pulseController.stop();
          }
        },
      );
    } catch (e) {
      _speechAvailable = false;
    } finally {
      if (mounted) setState(() => _speechInitializing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 음성 인식 시작/중지
  // ---------------------------------------------------------------------------

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해 주세요.'); // TODO: l10n
      return;
    }

    setState(() {
      _voiceState = _VoiceState.listening;
      _transcribedText = '';
      _parsedItems = [];
      _showManualSearch = false;
    });

    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko-KR', // 한국어 우선; 영어는 'en-US'
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _pulseController.stop();
    _pulseController.reset();

    if (_transcribedText.trim().isEmpty) {
      setState(() => _voiceState = _VoiceState.idle);
      return;
    }

    // 파싱 실행
    _parseTranscription();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _transcribedText = result.recognizedWords;
    });

    // 최종 결과면 자동 중지
    if (result.finalResult) {
      _stopListening();
    }
  }

  // ---------------------------------------------------------------------------
  // 텍스트 파싱
  // ---------------------------------------------------------------------------

  void _parseTranscription() {
    final allFoods = kAllFoodItems;
    final parsed = _parseVoiceText(_transcribedText, allFoods);

    setState(() {
      _parsedItems = parsed;
      _voiceState = _VoiceState.transcribed;
      _showManualSearch = parsed.isEmpty;
    });
  }

  // ---------------------------------------------------------------------------
  // 재녹음
  // ---------------------------------------------------------------------------

  void _reRecord() {
    setState(() {
      _voiceState = _VoiceState.idle;
      _transcribedText = '';
      _parsedItems = [];
      _showManualSearch = false;
    });
  }

  // ---------------------------------------------------------------------------
  // 식단에 추가
  // ---------------------------------------------------------------------------

  Future<void> _addToMeal() async {
    final selectedItems =
        _parsedItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      _showError('추가할 음식을 선택해 주세요.'); // TODO: l10n
      return;
    }

    try {
      final dietNotifier = ref.read(dietProvider.notifier);

      await dietNotifier.addMeal(MealType.snack);

      final dietState = ref.read(dietProvider);
      if (dietState.meals.isEmpty) return;
      final mealId = dietState.meals.last.id;

      for (final item in selectedItems) {
        await dietNotifier.addFoodToMeal(
            mealId, item.foodItem, item.amount);
        await ref
            .read(foodDatabaseProvider.notifier)
            .addToRecent(item.foodItem);
      }

      setState(() => _voiceState = _VoiceState.confirmed);

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
  // 수동 검색 음식 추가
  // ---------------------------------------------------------------------------

  void _addManualFood(FoodItem food) {
    setState(() {
      if (_parsedItems.any((item) => item.foodItem.id == food.id)) return;
      _parsedItems.add(
        _ParsedFoodItem(foodItem: food, amount: food.servingSize),
      );
      _voiceState = _VoiceState.transcribed;
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
          '음성으로 식단 기록', // TODO: l10n
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // 마이크 버튼
                  _MicButton(
                    voiceState: _voiceState,
                    isInitializing: _speechInitializing,
                    pulseAnimation: _pulseAnimation,
                    onTap: () {
                      if (_voiceState == _VoiceState.listening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 상태 안내 텍스트
                  _StatusText(voiceState: _voiceState),
                  const SizedBox(height: 24),

                  // 변환된 텍스트 박스
                  if (_transcribedText.isNotEmpty ||
                      _voiceState == _VoiceState.listening)
                    _TranscribedTextBox(
                      text: _transcribedText,
                      isListening: _voiceState == _VoiceState.listening,
                    ),

                  const SizedBox(height: 20),

                  // 파싱된 음식 목록
                  if (_voiceState == _VoiceState.transcribed) ...[
                    if (_parsedItems.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_outlined,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 6),
                            const Text(
                              '인식된 음식', // TODO: l10n
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() =>
                                  _showManualSearch = !_showManualSearch),
                              child: const Text('직접 추가'), // TODO: l10n
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._parsedItems.asMap().entries.map(
                            (entry) => _ParsedFoodCard(
                              item: entry.value,
                              onToggle: (selected) => setState(
                                () => _parsedItems[entry.key].isSelected =
                                    selected,
                              ),
                              onAmountChanged: (amount) => setState(
                                () =>
                                    _parsedItems[entry.key].amount = amount,
                              ),
                            ),
                          ),
                    ] else ...[
                      // 파싱 실패
                      Column(
                        children: [
                          const Icon(Icons.help_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            '음식을 인식하지 못했어요.\n아래에서 직접 검색해 보세요.', // TODO: l10n
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],

                    // 수동 검색
                    if (_showManualSearch) ...[
                      const SizedBox(height: 16),
                      _ManualSearchSection(
                        controller: _searchController,
                        onFoodSelected: _addManualFood,
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),

          // 하단 버튼 영역
          if (_voiceState == _VoiceState.transcribed)
            _BottomActionBar(
              hasSelectedItems:
                  _parsedItems.any((item) => item.isSelected),
              totalCalories: _parsedItems
                  .where((item) => item.isSelected)
                  .fold(0.0, (sum, item) => sum + item.estimatedCalories),
              selectedCount: _parsedItems
                  .where((item) => item.isSelected)
                  .length,
              onReRecord: _reRecord,
              onAdd: _addToMeal,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 마이크 버튼 (펄스 애니메이션)
// ---------------------------------------------------------------------------

class _MicButton extends StatelessWidget {
  final _VoiceState voiceState;
  final bool isInitializing;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _MicButton({
    required this.voiceState,
    required this.isInitializing,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = voiceState == _VoiceState.listening;
    final color = isListening ? Colors.red : Colors.orange;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: isInitializing ? null : onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 외부 펄스 원 (듣는 중에만)
              if (isListening) ...[
                Container(
                  width: 130 * pulseAnimation.value,
                  height: 130 * pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 110 * pulseAnimation.value,
                  height: 110 * pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
              // 메인 버튼
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInitializing
                      ? Colors.grey.withValues(alpha: 0.2)
                      : color.withValues(alpha: isListening ? 1.0 : 0.15),
                  border: Border.all(
                    color: isInitializing ? Colors.grey : color,
                    width: 2,
                  ),
                ),
                child: isInitializing
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop : Icons.mic,
                        size: 36,
                        color: isListening ? Colors.white : color,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 상태 안내 텍스트
// ---------------------------------------------------------------------------

class _StatusText extends StatelessWidget {
  final _VoiceState voiceState;
  const _StatusText({required this.voiceState});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (voiceState) {
      _VoiceState.idle => (
          '마이크를 눌러 말씀해 주세요\n"닭가슴살 200g, 현미밥 한 공기"', // TODO: l10n
          Colors.grey
        ),
      _VoiceState.listening => ('듣는 중...', Colors.red), // TODO: l10n
      _VoiceState.transcribed => ('인식 완료', Colors.green), // TODO: l10n
      _VoiceState.confirmed => ('추가 완료', Colors.green), // TODO: l10n
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: color,
        height: 1.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 변환된 텍스트 박스
// ---------------------------------------------------------------------------

class _TranscribedTextBox extends StatelessWidget {
  final String text;
  final bool isListening;

  const _TranscribedTextBox({
    required this.text,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isListening
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                '음성 내용', // TODO: l10n
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isListening) ...[
                const Spacer(),
                const _BlinkingDot(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.isEmpty ? '...' : text,
            style: TextStyle(
              fontSize: 15,
              color: text.isEmpty ? Colors.grey : null,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 녹음 중 깜빡이는 점 표시
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: _controller.value),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 파싱된 음식 카드
// ---------------------------------------------------------------------------

class _ParsedFoodCard extends StatelessWidget {
  final _ParsedFoodItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onAmountChanged;

  const _ParsedFoodCard({
    required this.item,
    required this.onToggle,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final food = item.foodItem;

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
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.estimatedCalories.toStringAsFixed(0)} kcal · '
                    '단백질 ${item.estimatedProtein.toStringAsFixed(0)}g',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 분량 수정 텍스트 필드
            SizedBox(
              width: 72,
              child: _AmountField(
                amount: item.amount,
                unit: food.servingUnit,
                onChanged: onAmountChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 분량 입력 필드
// ---------------------------------------------------------------------------

class _AmountField extends StatefulWidget {
  final double amount;
  final String unit;
  final ValueChanged<double> onChanged;

  const _AmountField({
    required this.amount,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.amount.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _ctrl.text = widget.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        suffixText: widget.unit,
        suffixStyle: const TextStyle(fontSize: 10),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      onChanged: (val) {
        final parsed = double.tryParse(val);
        if (parsed != null && parsed > 0) {
          widget.onChanged(parsed);
        }
      },
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
        const Divider(),
        const SizedBox(height: 8),
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
// 하단 액션 버튼 바
// ---------------------------------------------------------------------------

class _BottomActionBar extends StatelessWidget {
  final bool hasSelectedItems;
  final double totalCalories;
  final int selectedCount;
  final VoidCallback onReRecord;
  final VoidCallback onAdd;

  const _BottomActionBar({
    required this.hasSelectedItems,
    required this.totalCalories,
    required this.selectedCount,
    required this.onReRecord,
    required this.onAdd,
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
      child: Row(
        children: [
          // 재녹음 버튼
          OutlinedButton.icon(
            onPressed: onReRecord,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('재녹음'), // TODO: l10n
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 식단 추가 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: hasSelectedItems ? onAdd : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                hasSelectedItems
                    ? '$selectedCount개 추가 · ${totalCalories.toStringAsFixed(0)} kcal' // TODO: l10n
                    : '음식을 선택해 주세요', // TODO: l10n
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
