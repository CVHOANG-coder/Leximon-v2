import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/app_providers.dart';

class SurveyCarouselScreen extends ConsumerStatefulWidget {
  const SurveyCarouselScreen({super.key});

  @override
  ConsumerState<SurveyCarouselScreen> createState() =>
      _SurveyCarouselScreenState();
}

class _SurveyCarouselScreenState extends ConsumerState<SurveyCarouselScreen> {
  static const _pageCount = 14;

  final PageController _pageController = PageController();
  final Set<int> _selectedGoals = {0};
  final Set<int> _selectedLearningMethods = {1, 2, 3};
  final Set<int> _selectedChallenges = {0, 2, 3};
  final Set<int> _selectedBarriers = {};

  int _currentPage = 0;
  int? _selectedAge;
  int _selectedFrequency = 2;
  int _selectedResultTimeline = 0;
  int _selectedDailyStudyTime = 1;
  double _preferredStudyMinutes = 19 * 60 + 50;
  bool _isFinishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_currentPage < _pageCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await ref.read(appLanguageServiceProvider).completeOnboarding();
      if (!mounted) return;
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hoàn tất thiết lập. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage == 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0870F9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0870F9),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [...previousChildren, ?currentChild],
                );
              },
              child: SizedBox.expand(
                key: ValueKey('survey-background-$_currentPage'),
                child: Image.asset(
                  _currentPage >= 6 && _currentPage <= 12
                      ? 'assets/images/onboarding/bg_open_knowleage.png'
                      : 'assets/images/onboarding/intro_form_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 38),
                  _SurveyProgressIndicator(currentPage: _currentPage),
                  const SizedBox(height: 25),
                  Expanded(
                    child: PageView(
                      key: const ValueKey('survey-carousel'),
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      children: [
                        _AgeSurveyPage(
                          selectedAge: _selectedAge,
                          onSelected: (index) {
                            setState(() => _selectedAge = index);
                          },
                        ),
                        _GoalSurveyPage(
                          selectedGoals: _selectedGoals,
                          onToggle: (index) {
                            setState(() {
                              if (!_selectedGoals.add(index)) {
                                _selectedGoals.remove(index);
                              }
                            });
                          },
                        ),
                        _FrequencySurveyPage(
                          selectedFrequency: _selectedFrequency,
                          onSelected: (index) {
                            setState(() => _selectedFrequency = index);
                          },
                        ),
                        _LearningHistorySurveyPage(
                          selectedMethods: _selectedLearningMethods,
                          onToggle: (index) {
                            setState(() {
                              if (!_selectedLearningMethods.add(index)) {
                                _selectedLearningMethods.remove(index);
                              }
                            });
                          },
                        ),
                        _ResultTimelineSurveyPage(
                          selectedTimeline: _selectedResultTimeline,
                          onSelected: (index) {
                            setState(() => _selectedResultTimeline = index);
                          },
                        ),
                        _DailyStudyTimeSurveyPage(
                          selectedStudyTime: _selectedDailyStudyTime,
                          onSelected: (index) {
                            setState(() => _selectedDailyStudyTime = index);
                          },
                        ),
                        const _StudyHabitPage(),
                        _PreferredStudyTimePage(
                          selectedMinutes: _preferredStudyMinutes,
                          onChanged: (minutes) {
                            setState(() => _preferredStudyMinutes = minutes);
                          },
                        ),
                        const _StudyReminderPage(),
                        _EnglishChallengePage(
                          selectedChallenges: _selectedChallenges,
                          onToggle: (index) {
                            setState(() {
                              if (!_selectedChallenges.add(index)) {
                                _selectedChallenges.remove(index);
                              }
                            });
                          },
                        ),
                        _LearningBarrierPage(
                          selectedBarriers: _selectedBarriers,
                          onToggle: (index) {
                            setState(() {
                              const noBarrierIndex = 5;
                              if (index == noBarrierIndex) {
                                if (!_selectedBarriers.remove(index)) {
                                  _selectedBarriers
                                    ..clear()
                                    ..add(index);
                                }
                                return;
                              }

                              _selectedBarriers.remove(noBarrierIndex);
                              if (!_selectedBarriers.add(index)) {
                                _selectedBarriers.remove(index);
                              }
                            });
                          },
                        ),
                        const _SocialProofPage(),
                        const _KnowledgeJourneyPage(),
                        const _SurveySummaryPage(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 10, 36, 18),
                    child: _SurveyContinueButton(
                      label: switch (_currentPage) {
                        6 => 'Tiếp tục',
                        8 => 'Tuyệt vời!',
                        11 => 'Bắt đầu học nào!',
                        12 => 'Tiếp tục hành trình',
                        13 => 'Tiếp tục cùng Leximon',
                        _ => 'Tiếp',
                      },
                      showArrow: _currentPage == 12,
                      useBlueGradient: _currentPage == 11,
                      isLoading: _isFinishing,
                      onTap: _continue,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentPage == 6 || _currentPage == 7)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 39),
                    child: IconButton(
                      key: ValueKey(
                        _currentPage == 6
                            ? 'survey-habit-back'
                            : 'survey-preferred-time-back',
                      ),
                      onPressed: _goToPreviousPage,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SurveyProgressIndicator extends StatelessWidget {
  const _SurveyProgressIndicator({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final usesDarkBackground = currentPage >= 6 && currentPage <= 12;

    return SizedBox(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < 11; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? usesDarkBackground
                          ? const Color(0xFF77D4FF)
                          : const Color(0xFF073FC8)
                    : usesDarkBackground
                    ? const Color(0xFF326DD1)
                    : Colors.white.withValues(alpha: 0.42),
                shape: BoxShape.circle,
                boxShadow: currentPage == index && usesDarkBackground
                    ? const [
                        BoxShadow(
                          color: Color(0xFF2A8EFF),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: currentPage == 13 ? 1.08 : 1,
            child: Image.asset(
              'assets/images/onboarding/final.png',
              width: 38,
              height: 38,
              cacheWidth: 180,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeSurveyPage extends StatelessWidget {
  const _AgeSurveyPage({required this.selectedAge, required this.onSelected});

  static const _ages = [
    'Dưới 16 tuổi',
    '16–25',
    '26–35',
    '36–50',
    'Trên 50 tuổi',
  ];

  final int? selectedAge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          const Text(
            'Bạn bao nhiêu tuổi?',
            textAlign: TextAlign.center,
            style: _SurveyStyles.questionTitle,
          ),
          const SizedBox(height: 28),
          for (var index = 0; index < _ages.length; index++) ...[
            _AgeOptionCard(
              key: ValueKey('survey-age-$index'),
              label: _ages[index],
              selected: selectedAge == index,
              onTap: () => onSelected(index),
            ),
            if (index != _ages.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AgeOptionCard extends StatelessWidget {
  const _AgeOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: _SurveyStyles.cardDecoration(selected: selected),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SurveyRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSurveyPage extends StatelessWidget {
  const _GoalSurveyPage({required this.selectedGoals, required this.onToggle});

  static const _goals = [
    (
      label: 'Để tìm việc mới và phát triển\nnghề nghiệp',
      asset: 'assets/images/onboarding/job.png',
    ),
    (
      label: 'Để giao tiếp khi đi du lịch nước ngoài',
      asset: 'assets/images/onboarding/travel.png',
    ),
    (
      label: 'Để nâng cao kết quả học tập hoặc vào\nđại học',
      asset: 'assets/images/onboarding/study.png',
    ),
    (
      label: 'Để xem phim, đọc sách báo,\nnghe nhạc',
      asset: 'assets/images/onboarding/entertainment.png',
    ),
    (
      label: 'Tôi sống ở nước ngoài hoặc dự định\nchuyển ra nước ngoài',
      asset: 'assets/images/onboarding/go_aboard.png',
    ),
    (
      label: 'Phát triển cá nhân',
      asset: 'assets/images/onboarding/develop_self.png',
    ),
  ];

  final Set<int> selectedGoals;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const Text(
            'Tại sao bạn lại học tiếng Anh?',
            textAlign: TextAlign.center,
            style: _SurveyStyles.questionTitle,
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _goals.length; index++) ...[
            _GoalOptionCard(
              key: ValueKey('survey-goal-$index'),
              label: _goals[index].label,
              imageAsset: _goals[index].asset,
              selected: selectedGoals.contains(index),
              onTap: () => onToggle(index),
            ),
            if (index != _goals.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 77,
          decoration: _SurveyStyles.cardDecoration(selected: selected),
          child: Row(
            children: [
              Container(
                width: 72,
                height: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFCFE7FF)
                      : const Color(0xFFE7F2FF),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 320,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 15.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SurveyCheckbox(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencySurveyPage extends StatelessWidget {
  const _FrequencySurveyPage({
    required this.selectedFrequency,
    required this.onSelected,
  });

  static const _frequencies = [
    (
      label: 'Hiếm khi, ví dụ như để dịch một từ',
      asset: 'assets/images/onboarding/rarely.png',
    ),
    (
      label: 'Đôi khi, ví dụ như khi xem phim hoặc\nđọc sách báo',
      asset: 'assets/images/onboarding/sometimes.png',
    ),
    (
      label: 'Thỉnh thoảng, ví dụ như tại nơi làm\nviệc hoặc khi đi du lịch',
      asset: 'assets/images/onboarding/occasionally.png',
    ),
    (
      label:
          'Thường xuyên, vì tôi giao tiếp bằng\ntiếng Anh trong cuộc sống hằng ngày',
      asset: 'assets/images/onboarding/usually.png',
    ),
    (label: 'Không bao giờ dùng', asset: 'assets/images/onboarding/never.png'),
  ];

  final int selectedFrequency;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Bạn dùng tiếng Anh thường xuyên\nnhư thế nào?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              shadows: [
                Shadow(
                  color: Color(0x80001D70),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (var index = 0; index < _frequencies.length; index++) ...[
            _FrequencyOptionCard(
              key: ValueKey('survey-frequency-$index'),
              label: _frequencies[index].label,
              imageAsset: _frequencies[index].asset,
              selected: selectedFrequency == index,
              onTap: () => onSelected(index),
            ),
            if (index != _frequencies.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FrequencyOptionCard extends StatelessWidget {
  const _FrequencyOptionCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 84,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F9FF)
                : Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1FD7FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x8015C9FF)
                    : const Color(0x54135FBE),
                blurRadius: selected ? 19 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6FE9), Color(0xFF073CCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  border: selected
                      ? Border.all(color: const Color(0xFF31E4FF), width: 1.5)
                      : null,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 340,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 14.5,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              _SurveyRadio(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningHistorySurveyPage extends StatelessWidget {
  const _LearningHistorySurveyPage({
    required this.selectedMethods,
    required this.onToggle,
  });

  static const _methods = [
    (
      label: 'Học với gia sư hoặc tham gia khóa\nhọc ngôn ngữ',
      asset: 'assets/images/onboarding/tutor.png',
    ),
    (
      label: 'Học bằng các ứng dụng học tiếng Anh',
      asset: 'assets/images/onboarding/english_app.png',
    ),
    (
      label: 'Tự học qua video hoặc sách',
      asset: 'assets/images/onboarding/learn_throught_video.png',
    ),
    (
      label: 'Tại trường phổ thông hoặc đại học',
      asset: 'assets/images/onboarding/school.png',
    ),
    (
      label: 'Khi nói chuyện với người bản ngữ',
      asset: 'assets/images/onboarding/usually.png',
    ),
    (label: 'Chưa từng học', asset: 'assets/images/onboarding/never.png'),
  ];

  final Set<int> selectedMethods;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Bạn đã từng học tiếng Anh\nbao giờ chưa?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              shadows: [
                Shadow(
                  color: Color(0x80001D70),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _methods.length; index++) ...[
            _LearningMethodCard(
              key: ValueKey('survey-learning-method-$index'),
              label: _methods[index].label,
              imageAsset: _methods[index].asset,
              selected: selectedMethods.contains(index),
              onTap: () => onToggle(index),
            ),
            if (index != _methods.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LearningMethodCard extends StatelessWidget {
  const _LearningMethodCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 74,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F9FF)
                : Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1FD7FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x8015C9FF)
                    : const Color(0x54135FBE),
                blurRadius: selected ? 19 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6FE9), Color(0xFF073CCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  border: selected
                      ? Border.all(color: const Color(0xFF31E4FF), width: 1.5)
                      : null,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 320,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 14.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              _SurveyCheckbox(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTimelineSurveyPage extends StatelessWidget {
  const _ResultTimelineSurveyPage({
    required this.selectedTimeline,
    required this.onSelected,
  });

  static const _timelines = [
    (
      label: 'Càng nhanh càng tốt. Tôi muốn sớm\nnâng cao hiểu biết',
      asset: 'assets/images/onboarding/fire.png',
    ),
    (
      label: 'Tôi cần nâng cao trình độ trong\nvài tháng',
      asset: 'assets/images/onboarding/calendar.png',
    ),
    (
      label: 'Không cần vội. Tôi dự định học\nngôn ngữ lâu dài',
      asset: 'assets/images/onboarding/clock.png',
    ),
  ];

  final int selectedTimeline;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Bạn cần bao lâu\nđể có kết quả?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              shadows: [
                Shadow(
                  color: Color(0x80001D70),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          for (var index = 0; index < _timelines.length; index++) ...[
            _ResultTimelineCard(
              key: ValueKey('survey-result-timeline-$index'),
              label: _timelines[index].label,
              imageAsset: _timelines[index].asset,
              selected: selectedTimeline == index,
              onTap: () => onSelected(index),
            ),
            if (index != _timelines.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ResultTimelineCard extends StatelessWidget {
  const _ResultTimelineCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 100,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F9FF)
                : Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1FD7FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x8015C9FF)
                    : const Color(0x54135FBE),
                blurRadius: selected ? 19 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 88,
                height: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E85F9), Color(0xFF0B50DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  border: selected
                      ? Border.all(color: const Color(0xFF31E4FF), width: 1.5)
                      : null,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 380,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              _SurveyRadio(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyStudyTimeSurveyPage extends StatelessWidget {
  const _DailyStudyTimeSurveyPage({
    required this.selectedStudyTime,
    required this.onSelected,
  });

  static const _studyTimes = [
    (
      label: 'Dưới 10 phút',
      asset: 'assets/images/onboarding/under_10_minutes.png',
    ),
    (label: '10 – 20 phút', asset: 'assets/images/onboarding/20_minutes.png'),
    (label: '20 – 60 phút', asset: 'assets/images/onboarding/60_minutes.png'),
    (label: 'Hơn 1 giờ', asset: 'assets/images/onboarding/many_hours.png'),
  ];

  final int selectedStudyTime;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Bạn sẵn sàng dành bao nhiêu\n'
            'thời gian mỗi ngày để\n'
            'học tiếng Anh?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.65,
              shadows: [
                Shadow(
                  color: Color(0x80001D70),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < _studyTimes.length; index++) ...[
            _DailyStudyTimeCard(
              key: ValueKey('survey-daily-study-time-$index'),
              label: _studyTimes[index].label,
              imageAsset: _studyTimes[index].asset,
              selected: selectedStudyTime == index,
              onTap: () => onSelected(index),
            ),
            if (index != _studyTimes.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DailyStudyTimeCard extends StatelessWidget {
  const _DailyStudyTimeCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 90,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F9FF)
                : Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1FD7FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x8015C9FF)
                    : const Color(0x54135FBE),
                blurRadius: selected ? 19 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E85F9), Color(0xFF0B50DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  border: selected
                      ? Border.all(color: const Color(0xFF31E4FF), width: 1.5)
                      : null,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 360,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              _SurveyRadio(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyHabitPage extends StatelessWidget {
  const _StudyHabitPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Text(
            'Bạn đã sẵn sàng dành bao\n'
            'nhiêu thời gian mỗi ngày để\n'
            'học tiếng Anh?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.65,
              shadows: [
                Shadow(
                  color: Color(0x90001A63),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Image.asset(
            'assets/images/onboarding/time_learn.png',
            width: 340,
            fit: BoxFit.contain,
            cacheWidth: 1000,
          ),
          const SizedBox(height: 27),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Dành ra khoảng thời gian cố định mỗi ngày\n'
                      'để học sẽ giúp bạn hình thành thói quen\n'
                      'và ',
                ),
                TextSpan(
                  text: 'tiến bộ nhanh hơn.',
                  style: TextStyle(
                    color: Color(0xFF55A8FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
              shadows: [
                Shadow(
                  color: Color(0x80001452),
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferredStudyTimePage extends StatelessWidget {
  const _PreferredStudyTimePage({
    required this.selectedMinutes,
    required this.onChanged,
  });

  final double selectedMinutes;
  final ValueChanged<double> onChanged;

  String _formatTime(double value) {
    final totalMinutes = value.round().clamp(360, 1440).toInt();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final displayHours = hours == 24 ? 0 : hours;

    return '${displayHours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Image.asset(
            'assets/images/onboarding/chose_time_learn.png',
            width: 310,
            height: 238,
            fit: BoxFit.contain,
            cacheWidth: 1000,
          ),
          const SizedBox(height: 18),
          const Text(
            'Với bạn, giờ nào là thuận tiện\nđể học tiếng Anh?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.65,
              shadows: [
                Shadow(
                  color: Color(0xB0001A63),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            _formatTime(selectedMinutes),
            key: const ValueKey('survey-preferred-time-value'),
            style: const TextStyle(
              color: Color(0xFF8AC5FF),
              fontSize: 43,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Color(0xFF1B75FF), blurRadius: 16),
                Shadow(
                  color: Color(0x80001162),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7738FF),
                      Color(0xFF3C6EFF),
                      Color(0xFF3AA7FF),
                      Color(0xFF477BFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(color: Color(0xCC267FFF), blurRadius: 16),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  disabledActiveTrackColor: Colors.transparent,
                  disabledInactiveTrackColor: Colors.transparent,
                  thumbColor: const Color(0xFFF7FBFF),
                  overlayColor: const Color(0x332B8CFF),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 20,
                    elevation: 8,
                    pressedElevation: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 27,
                  ),
                ),
                child: Slider(
                  key: const ValueKey('survey-preferred-time-slider'),
                  value: selectedMinutes,
                  min: 360,
                  max: 1440,
                  divisions: 108,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('06:00', style: _PreferredStudyTimePage._timeLabelStyle),
              Text('12:00', style: _PreferredStudyTimePage._timeLabelStyle),
              Text('18:00', style: _PreferredStudyTimePage._timeLabelStyle),
              Text('00:00', style: _PreferredStudyTimePage._timeLabelStyle),
            ],
          ),
        ],
      ),
    );
  }

  static const _timeLabelStyle = TextStyle(
    color: Color(0xFFA8C8FF),
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(color: Color(0x8000165B), blurRadius: 6, offset: Offset(0, 2)),
    ],
  );
}

class _StudyReminderPage extends StatelessWidget {
  const _StudyReminderPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/onboarding/reminder_notification.png',
            width: 330,
            height: 330,
            fit: BoxFit.contain,
            cacheWidth: 1000,
          ),
          const SizedBox(height: 24),
          const Text(
            'Leximon sẽ nhắc nhở bạn về các buổi học\n'
            'để bạn không bỏ lỡ ngày nào.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              shadows: [
                Shadow(
                  color: Color(0xA000104E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Chúng tôi nhận thấy rằng việc thực hành\n'
                      'thường xuyên có thể giúp tăng tốc độ học\n'
                      'tiếng Anh lên gần ',
                ),
                TextSpan(
                  text: '4,6 lần!',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              shadows: [
                Shadow(
                  color: Color(0xA000104E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnglishChallengePage extends StatelessWidget {
  const _EnglishChallengePage({
    required this.selectedChallenges,
    required this.onToggle,
  });

  static const _challenges = [
    (
      label: 'Học và ghi nhớ từ mới',
      asset: 'assets/images/onboarding/learn_and_remember.png',
    ),
    (
      label: 'Học và hiểu ngữ pháp',
      asset: 'assets/images/onboarding/grammar.png',
    ),
    (
      label: 'Nói bằng tiếng Anh',
      asset: 'assets/images/onboarding/speak_english.png',
    ),
    (
      label: 'Nghe hiểu tiếng Anh',
      asset: 'assets/images/onboarding/listen_english.png',
    ),
    (
      label: 'Hiểu và dịch các văn bản',
      asset: 'assets/images/onboarding/translate_english.png',
    ),
  ];

  final Set<int> selectedChallenges;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Đối với bạn, khó khăn lớn nhất\ntrong tiếng Anh là gì?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.65,
              shadows: [
                Shadow(
                  color: Color(0xFF2379FF),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
                Shadow(
                  color: Color(0xA000104E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          for (var index = 0; index < _challenges.length; index++) ...[
            _EnglishChallengeCard(
              key: ValueKey('survey-challenge-$index'),
              label: _challenges[index].label,
              imageAsset: _challenges[index].asset,
              selected: selectedChallenges.contains(index),
              onTap: () => onToggle(index),
            ),
            if (index != _challenges.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _EnglishChallengeCard extends StatelessWidget {
  const _EnglishChallengeCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF66C9FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0xB02E9CFF)
                    : const Color(0x801A70E8),
                blurRadius: selected ? 19 : 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2681F7), Color(0xFF073CCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                  border: Border.all(
                    color: const Color(0xFF6BE0FF),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 340,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071B65),
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SurveyCheckbox(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningBarrierPage extends StatelessWidget {
  const _LearningBarrierPage({
    required this.selectedBarriers,
    required this.onToggle,
  });

  static const _barriers = [
    (
      label: 'Thiếu thời gian',
      asset: 'assets/images/onboarding/thieu_thoi_gian.png',
    ),
    (
      label: 'Thiếu học liệu tốt',
      asset: 'assets/images/onboarding/thieu_tai_lieu.png',
    ),
    (
      label: 'Tôi không biết cách học\ntiếng Anh đúng đắn',
      asset: 'assets/images/onboarding/thieu_lo_trinh.png',
    ),
    (
      label: 'Học điều mới thật là khó',
      asset: 'assets/images/onboarding/hoc_dieu_moi_kho.png',
    ),
    (
      label: 'Thiếu thực hành và giao tiếp',
      asset: 'assets/images/onboarding/thieu_thuc_hanh.png',
    ),
    (
      label: 'Không có điều gì',
      asset: 'assets/images/onboarding/khong_thieu_gi.png',
    ),
  ];

  final Set<int> selectedBarriers;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Điều gì khiến bạn không thể\n'
            'học tiếng Anh một cách\n'
            'nhanh chóng?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              shadows: [
                Shadow(
                  color: Color(0xFF2379FF),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
                Shadow(
                  color: Color(0xA000104E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _barriers.length; index++) ...[
            _LearningBarrierCard(
              key: ValueKey('survey-barrier-$index'),
              label: _barriers[index].label,
              imageAsset: _barriers[index].asset,
              selected: selectedBarriers.contains(index),
              onTap: () => onToggle(index),
            ),
            if (index != _barriers.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LearningBarrierCard extends StatelessWidget {
  const _LearningBarrierCard({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? const Color(0xFF66C9FF)
                  : Colors.white.withValues(alpha: 0.92),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0xB02E9CFF)
                    : const Color(0x801A70E8),
                blurRadius: selected ? 19 : 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: double.infinity,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2681F7), Color(0xFF073CCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: const Color(0xFF6BE0FF),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 340,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071B65),
                    fontSize: 16.5,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SurveyCheckbox(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialProofPage extends StatelessWidget {
  const _SocialProofPage();

  static const _reviews = [
    (
      author: 'Ruavip753',
      title: 'Good',
      text:
          'App ngày càng hoàn thiện, bỏ tiền mua vĩnh viễn coi bộ không '
          'uổng phí. Thấy cũng tội cho app khi 1 đồng tháng ngu không biết '
          'sử dụng thế. Thêm 1 đồng tháng ngu thì xài hàng free nữa chứ.',
    ),
    (
      author: 'Oki',
      title: 'Ứng dụng rất hay',
      text:
          'Rất hay và dễ học. Bài học ngắn gọn, hình ảnh đẹp và giúp tôi '
          'duy trì thói quen luyện tiếng Anh mỗi ngày.',
    ),
    (
      author: 'Minh Anh',
      title: 'Hữu ích',
      text:
          'Nội dung phù hợp với trình độ, cách học dễ hiểu và phần nhắc '
          'lịch giúp tôi không bỏ lỡ buổi học.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.asset(
            'assets/images/onboarding/giup_moi_nguoi.png',
            width: 285,
            height: 245,
            fit: BoxFit.contain,
            cacheWidth: 1000,
          ),
          const SizedBox(height: 10),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Bright',
                  style: TextStyle(
                    color: Color(0xFF39A9FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ' đã giúp '),
                TextSpan(
                  text: '2.000.000',
                  style: TextStyle(
                    color: Color(0xFF42D7F4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ' người dùng\ncải thiện năng lực tiếng Anh'),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              height: 1.42,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: Color(0xA000104E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SocialRating(),
          const SizedBox(height: 15),
          SizedBox(
            height: 175,
            child: ListView.separated(
              key: const ValueKey('survey-social-reviews'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _SocialReviewCard(
                  author: review.author,
                  title: review.title,
                  text: review.text,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialRating extends StatelessWidget {
  const _SocialRating();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.energy_savings_leaf_rounded,
          color: Color(0xFF5A9BFF),
          size: 31,
        ),
        const SizedBox(width: 8),
        const Text(
          '4.5',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
            height: 1,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Color(0xFF2C8CFF), blurRadius: 14)],
          ),
        ),
        const SizedBox(width: 12),
        for (var index = 0; index < 4; index++)
          const Icon(Icons.star_rounded, color: Color(0xFFFFB733), size: 29),
        const Icon(Icons.star_half_rounded, color: Color(0xFFFFB733), size: 29),
        const SizedBox(width: 8),
        const Icon(
          Icons.energy_savings_leaf_rounded,
          color: Color(0xFF5A9BFF),
          size: 31,
        ),
      ],
    );
  }
}

class _SocialReviewCard extends StatelessWidget {
  const _SocialReviewCard({
    required this.author,
    required this.title,
    required this.text,
  });

  final String author;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF083795).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF2769ED), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x660052D5),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '★★★★★',
                  style: TextStyle(
                    color: Color(0xFFFFB733),
                    fontSize: 17,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                author,
                style: const TextStyle(
                  color: Color(0xFF54A1FF),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeJourneyPage extends StatelessWidget {
  const _KnowledgeJourneyPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 34),
          Image.asset(
            'assets/images/onboarding/open_know.png',
            width: 340,
            fit: BoxFit.contain,
            cacheWidth: 1000,
          ),
          const SizedBox(height: 22),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Tiếng Anh là chìa khóa giúp bạn\n'),
                TextSpan(
                  text: 'mở cánh cửa tri thức,',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: '\nkết nối thế giới và\nnắm bắt '),
                TextSpan(
                  text: 'nhiều cơ hội hơn.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.42,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.25,
              shadows: [
                Shadow(
                  color: Color(0x80001452),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveySummaryPage extends StatelessWidget {
  const _SurveySummaryPage();

  static const _quotes = [
    (
      text:
          'Tiếng Anh mở ra cánh cửa đến\n'
          'những cơ hội nghề nghiệp quốc tế\n'
          'và mức thu nhập hấp dẫn hơn.',
      source: 'Source: BBC Worklife\ncareer growth and global work',
    ),
    (
      text:
          'Kỹ năng ngôn ngữ giúp bạn nổi bật\n'
          'trong tuyển dụng, làm việc hiệu quả\n'
          'với đội nhóm đa quốc gia và phát triển\n'
          'sự nghiệp bền vững.',
      source: 'Source: World Economic Forum\nfuture of jobs and skills',
    ),
    (
      text:
          'Khả năng giao tiếp và sử dụng tiếng Anh\n'
          'tự tin là chìa khóa để dẫn dắt, thăng tiến\n'
          'và đạt được thành công lâu dài.',
      source:
          'Source: Harvard Business Review\n'
          'leadership and career advancement',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Text(
            'Tiếng Anh giúp bạn tiến xa hơn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Color(0x5A001F78),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _quotes.length; index++) ...[
            _QuoteCard(
              text: _quotes[index].text,
              source: _quotes[index].source,
            ),
            if (index != _quotes.length - 1) const SizedBox(height: 6),
          ],
          const SizedBox(height: 16),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Với '),
                TextSpan(
                  text: 'Leximon',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ', học tiếng Anh mỗi ngày giúp bạn\n'),
                TextSpan(
                  text: 'mở rộng cơ hội, nâng cao sự tự tin',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' và tiến gần hơn\nđến mục tiêu '),
                TextSpan(
                  text: 'sự nghiệp và thu nhập.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text, required this.source});

  final String text;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 18, 12),
      decoration: _SurveyStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 15.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Positioned(
                right: 0,
                top: -8,
                child: Text(
                  '”',
                  style: TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 52,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            source,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF174697),
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyRadio extends StatelessWidget {
  const _SurveyRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 27,
      height: 27,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF13BD2A) : const Color(0xFF8DB5F5),
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

class _SurveyCheckbox extends StatelessWidget {
  const _SurveyCheckbox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF10CF55), Color(0xFF06A92E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? const Color(0xFF2CDD67) : const Color(0xFF6898F6),
          width: 1.5,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x5511C448),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
          : null,
    );
  }
}

class _SurveyContinueButton extends StatelessWidget {
  const _SurveyContinueButton({
    required this.label,
    required this.showArrow,
    required this.useBlueGradient,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool showArrow;
  final bool useBlueGradient;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: useBlueGradient
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1846F5),
                    Color(0xFF3266FF),
                    Color(0xFF244AF3),
                  ],
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFF9FCFF),
                    Color(0xFFEAF6FF),
                    Color(0xFFF9FCFF),
                  ],
                ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x701B8CFF),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(34),
          child: InkWell(
            key: const ValueKey('survey-carousel-continue'),
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      color: useBlueGradient
                          ? Colors.white
                          : const Color(0xFF1263F4),
                      strokeWidth: 2.5,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: useBlueGradient
                          ? Colors.white
                          : const Color(0xFF1263F4),
                      fontSize: label.length > 10 ? 21 : 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showArrow)
                    const Positioned(
                      right: 29,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0B4DEB),
                        size: 30,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _SurveyStyles {
  static const questionTitle = TextStyle(
    color: Color(0xFF031B65),
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  static BoxDecoration cardDecoration({bool selected = false}) {
    return BoxDecoration(
      color: selected
          ? const Color(0xFFF0F7FF)
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: selected
            ? const Color(0xFFA9C9FF)
            : Colors.white.withValues(alpha: 0.92),
        width: selected ? 1.5 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x54135FBE),
          blurRadius: 17,
          offset: Offset(0, 7),
        ),
        BoxShadow(
          color: Color(0x70FFFFFF),
          blurRadius: 9,
          offset: Offset(0, -2),
        ),
      ],
    );
  }
}
