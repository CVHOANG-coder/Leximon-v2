import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/onboarding_vocabulary_test.dart';

class AssessmentLevelScreen extends StatefulWidget {
  const AssessmentLevelScreen({super.key});

  @override
  State<AssessmentLevelScreen> createState() => _AssessmentLevelScreenState();
}

class _AssessmentLevelScreenState extends State<AssessmentLevelScreen> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061D4C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/bg_choose_language.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 254,
                    child: _AssessmentLevelPanel(
                      selectedOption: _selectedOption,
                      onSelected: (index) {
                        setState(() => _selectedOption = index);
                      },
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: _AssessmentLevelHeader(),
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

class _AssessmentLevelHeader extends StatelessWidget {
  const _AssessmentLevelHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 14,
            child: Semantics(
              label: 'Quay lại',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/onboarding/assessment-intro');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 38,
            top: 86,
            child: Text(
              'Đánh giá trình độ\n'
              'tiếng Anh hiện tại\n'
              'của bạn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 190,
            child: Text(
              'Chọn cấp độ phù hợp để chúng tôi\n'
              'xây dựng lộ trình học tốt nhất cho bạn.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: -3,
            top: 69,
            child: Image.asset(
              'assets/images/owls/owl_learn.png',
              width: 151,
              height: 192,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              cacheWidth: 700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentLevelPanel extends StatelessWidget {
  const _AssessmentLevelPanel({
    required this.selectedOption,
    required this.onSelected,
  });

  final int? selectedOption;
  final ValueChanged<int> onSelected;

  static const _options = [
    _AssessmentOptionData(
      text: 'Vừa mới bắt đầu học,\ntôi chưa biết gì cả',
      imageAsset: 'assets/images/onboarding/scooter.png',
      startingBand: VocabularyStartingBand.beginner,
    ),
    _AssessmentOptionData(
      text:
          'Tôi biết một chút ngữ pháp\n'
          'cơ bản và có thể nói được các\n'
          'từ cũng như cụm từ đơn giản',
      imageAsset: 'assets/images/onboarding/bike.png',
      startingBand: VocabularyStartingBand.beginner,
    ),
    _AssessmentOptionData(
      text:
          'Tôi có thể trò chuyện nhưng\n'
          'còn mắc lỗi và hay\n'
          'ngập ngừng',
      imageAsset: 'assets/images/onboarding/car.png',
      startingBand: VocabularyStartingBand.intermediate,
    ),
    _AssessmentOptionData(
      text:
          'Tôi nói trôi chảy, đọc sách\n'
          'và xem phim bằng\n'
          'tiếng Anh',
      imageAsset: 'assets/images/onboarding/rocket.png',
      startingBand: VocabularyStartingBand.advanced,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E031A55),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final horizontalPadding = compact ? 28.0 : 33.0;
          final cardHeight = compact ? 112.0 : 103.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              26,
              horizontalPadding,
              16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 42,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    for (var index = 0; index < _options.length; index++) ...[
                      _AssessmentOptionCard(
                        option: _options[index],
                        selected: selectedOption == index,
                        compact: compact,
                        height: cardHeight,
                        onTap: () => onSelected(index),
                      ),
                      if (index != _options.length - 1)
                        const SizedBox(height: 10),
                    ],
                    const Spacer(),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C4DE4), Color(0xFF147BFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40155CFF),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(19),
                          child: InkWell(
                            key: const ValueKey('assessment-level-start'),
                            onTap: selectedOption == null
                                ? null
                                : () => context.push(
                                    '/onboarding/assessment-intro/'
                                    'vocabulary-test?band='
                                    '${_options[selectedOption!].startingBand.queryValue}',
                                  ),
                            borderRadius: BorderRadius.circular(19),
                            child: const Center(
                              child: Text(
                                'Bắt đầu bài kiểm tra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssessmentOptionCard extends StatelessWidget {
  const _AssessmentOptionCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.height,
    required this.onTap,
  });

  final _AssessmentOptionData option;
  final bool selected;
  final bool compact;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: option.text.replaceAll('\n', ' '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('assessment-option-${option.imageAsset}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 11 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF2F7FF) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9FC4FF)
                    : const Color(0xFFEAF0F8),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14234381),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 74 : 84,
                  height: compact ? 86 : 83,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(compact ? 5 : 6),
                  child: Image.asset(
                    option.imageAsset,
                    fit: BoxFit.contain,
                    cacheWidth: 420,
                  ),
                ),
                SizedBox(width: compact ? 14 : 18),
                Expanded(
                  child: Text(
                    option.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF071944),
                      fontSize: compact ? 14.5 : 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 14),
                _AssessmentRadio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentRadio extends StatelessWidget {
  const _AssessmentRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF13BD2A) : const Color(0xFFD5DDEB),
          width: 2.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF13C42D) : Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AssessmentOptionData {
  const _AssessmentOptionData({
    required this.text,
    required this.imageAsset,
    required this.startingBand,
  });

  final String text;
  final String imageAsset;
  final VocabularyStartingBand startingBand;
}
