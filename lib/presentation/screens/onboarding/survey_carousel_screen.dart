import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/daily_notification_service.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

class SurveyCarouselScreen extends ConsumerStatefulWidget {
  const SurveyCarouselScreen({super.key});

  @override
  ConsumerState<SurveyCarouselScreen> createState() =>
      _SurveyCarouselScreenState();
}

class _SurveyCarouselScreenState extends ConsumerState<SurveyCarouselScreen> {
  static const _pageCount = 16;

  final PageController _pageController = PageController();
  final Set<int> _selectedGoals = {};
  final Set<int> _selectedLearningMethods = {};
  final Set<int> _selectedChallenges = {};
  final Set<int> _selectedBarriers = {};
  final Set<int> _selectedTopics = {};

  int _currentPage = 0;
  int? _selectedAge;
  int? _selectedFrequency;
  int? _selectedResultTimeline;
  int? _selectedDailyStudyTime;
  double _preferredStudyMinutes = 19 * 60 + 50;
  bool _preferredStudyTimeSelected = false;
  bool _isFinishing = false;
  Offset? _swipeStartPosition;
  bool _notificationPermissionRequested = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return switch (_currentPage) {
      0 => _selectedAge != null,
      1 => _selectedGoals.isNotEmpty,
      3 => _selectedFrequency != null,
      4 => _selectedLearningMethods.isNotEmpty,
      6 => _selectedResultTimeline != null,
      7 => _selectedDailyStudyTime != null,
      9 => _preferredStudyTimeSelected,
      11 => _selectedChallenges.isNotEmpty,
      12 => _selectedBarriers.isNotEmpty,
      13 => _selectedTopics.isNotEmpty,
      _ => true,
    };
  }

  Future<void> _continue() async {
    if (!_canContinue) return;

    if (_currentPage == 13) {
      final selectedOrders = {..._selectedTopics};
      ref.read(selectedTopicOrdersProvider.notifier).state = selectedOrders;
      unawaited(_persistSelectedTopics(selectedOrders));
    }

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
      await ref.read(appLanguageServiceProvider).completeCarousel();
      if (!mounted) return;
      context.go('/onboarding/assessment-intro/survey/free-trial');
    } on Object {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('surveySaveProgressError'))),
      );
    }
  }

  Future<void> _persistSelectedTopics(Set<int> selectedOrders) async {
    try {
      await ref.read(localDataInitializationProvider.future);
      await ref
          .read(topicRepositoryProvider)
          .saveSelectedTopicOrders(selectedOrders);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('surveySaveTopicsError'))),
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

  void _handlePointerDown(PointerDownEvent event) {
    _swipeStartPosition = event.position;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final startPosition = _swipeStartPosition;
    _swipeStartPosition = null;
    if (startPosition == null || _currentPage == _pageCount - 1) return;

    // The preferred-time slider is a horizontal gesture itself. Only the
    // Continue button may leave this page after the user adjusts the time.
    if (_currentPage == 9) return;

    final delta = event.position - startPosition;
    final isHorizontalSwipe =
        delta.dx.abs() >= 48 && delta.dx.abs() > delta.dy.abs() * 1.2;
    if (!isHorizontalSwipe) return;

    if (delta.dx < 0) {
      unawaited(_continue());
    } else {
      unawaited(_goToPreviousPage());
    }
  }

  void _handlePageChanged(int page) {
    setState(() => _currentPage = page);
    if (page == 10 && !_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_requestNotificationPermission());
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final localizations = context.l10n;
      final permissionResult = await DailyNotificationService.instance
          .requestPermission();
      if (permissionResult != DailyNotificationPermissionResult.granted) {
        return;
      }

      final totalMinutes = _preferredStudyMinutes.round() % (24 * 60);
      await DailyNotificationService.instance.scheduleDaily(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
        localizations: localizations,
      );
    } on Object {
      // Permission is optional during onboarding. A native/plugin failure
      // must not interrupt the survey flow or prevent the user from
      // continuing through onboarding.
    }
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
                  'assets/images/onboarding/bg_open_knowleage.png',
                  // _currentPage == 5 || _currentPage >= 8
                  //     ? 'assets/images/onboarding/bg_open_knowleage.png'
                  //     : 'assets/images/onboarding/intro_form_bg.png',
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
                    child: Listener(
                      onPointerDown: _handlePointerDown,
                      onPointerUp: _handlePointerUp,
                      onPointerCancel: (_) => _swipeStartPosition = null,
                      child: PageView(
                        key: const ValueKey('survey-carousel'),
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        scrollBehavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        onPageChanged: _handlePageChanged,
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
                          const _SurveySummaryPage(),
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
                          _KnowledgeJourneyPage(isActive: _currentPage == 5),
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
                          _StudyHabitPage(isActive: _currentPage == 8),
                          _PreferredStudyTimePage(
                            isActive: _currentPage == 9,
                            selectedMinutes: _preferredStudyMinutes,
                            onChanged: (minutes) {
                              setState(() {
                                _preferredStudyMinutes = minutes;
                                _preferredStudyTimeSelected = true;
                              });
                            },
                          ),
                          _StudyReminderPage(isActive: _currentPage == 10),
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
                          _TopicSelectionPage(
                            selectedTopics: _selectedTopics,
                            onToggle: (index) {
                              setState(() {
                                if (!_selectedTopics.add(index)) {
                                  _selectedTopics.remove(index);
                                }
                              });
                            },
                            onToggleAll: (topics) {
                              setState(() {
                                final topicOrders = topics
                                    .map((topic) => topic.order)
                                    .toSet();
                                if (_selectedTopics.length ==
                                    topicOrders.length) {
                                  _selectedTopics.clear();
                                } else {
                                  _selectedTopics
                                    ..clear()
                                    ..addAll(topicOrders);
                                }
                              });
                            },
                          ),
                          const _SocialProofPage(),
                          _AnalysisLoadingPage(
                            isActive: _currentPage == 15,
                            onCompleted: _continue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_currentPage != 15)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                      child: _SurveyContinueButton(
                        label: switch (_currentPage) {
                          2 => context.l10n.text('surveyContinueWithLeximon'),
                          5 => context.l10n.text('surveyContinueJourney'),
                          8 => context.l10n.continueLabel,
                          10 => context.l10n.text('surveyGreat'),
                          14 => context.l10n.text('surveyStartLearning'),
                          _ => context.l10n.continueLabel,
                        },
                        showArrow: _currentPage == 5,
                        useBlueGradient: _currentPage == 14,
                        enabled: _canContinue,
                        isLoading: _isFinishing,
                        onTap: _continue,
                      ),
                    ),
                ],
              ),
            ),
            if (_currentPage == 8 || _currentPage == 9)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 39),
                    child: IconButton(
                      key: ValueKey(
                        _currentPage == 8
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
    final usesDarkBackground = currentPage == 5 || currentPage >= 8;

    return SizedBox(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < 15; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? const Color(0xFF77D4FF)
                    : const Color(0xFF326DD1),
                // ? usesDarkBackground
                //       ? const Color(0xFF77D4FF)
                //       : const Color(0xFF073FC8)
                // : usesDarkBackground
                // ? const Color(0xFF326DD1)
                // : Colors.white.withValues(alpha: 0.42),
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
            const SizedBox(width: 5),
          ],
          AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: currentPage == 15 ? 1.08 : 1,
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
    'surveyAgeUnder16',
    '16–25',
    '26–35',
    '36–50',
    'surveyAgeOver50',
  ];

  final int? selectedAge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyAgeQuestion'),
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
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: _SurveyStyles.cardDecoration(selected: selected),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.text(label),
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
    (label: 'surveyGoalCareer', asset: 'assets/images/onboarding/job.png'),
    (label: 'surveyGoalTravel', asset: 'assets/images/onboarding/travel.png'),
    (label: 'surveyGoalEducation', asset: 'assets/images/onboarding/study.png'),
    (
      label: 'surveyGoalEntertainment',
      asset: 'assets/images/onboarding/entertainment.png',
    ),
    (
      label: 'surveyGoalAbroad',
      asset: 'assets/images/onboarding/go_aboard.png',
    ),
    (
      label: 'surveyGoalPersonal',
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
          Text(
            context.l10n.text('surveyGoalQuestion'),
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
                  context.l10n.text(label),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF061B62),
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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
      label: 'surveyFrequencyRarely',
      asset: 'assets/images/onboarding/rarely.png',
    ),
    (
      label: 'surveyFrequencySometimes',
      asset: 'assets/images/onboarding/sometimes.png',
    ),
    (
      label: 'surveyFrequencyOccasionally',
      asset: 'assets/images/onboarding/occasionally.png',
    ),
    (
      label: 'surveyFrequencyOften',
      asset: 'assets/images/onboarding/usually.png',
    ),
    (
      label: 'surveyFrequencyNever',
      asset: 'assets/images/onboarding/never.png',
    ),
  ];

  final int? selectedFrequency;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyFrequencyQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
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
    (label: 'surveyMethodTutor', asset: 'assets/images/onboarding/tutor.png'),
    (
      label: 'surveyMethodApp',
      asset: 'assets/images/onboarding/english_app.png',
    ),
    (
      label: 'surveyMethodSelfStudy',
      asset: 'assets/images/onboarding/learn_throught_video.png',
    ),
    (label: 'surveyMethodSchool', asset: 'assets/images/onboarding/school.png'),
    (
      label: 'surveyMethodNativeSpeakers',
      asset: 'assets/images/onboarding/usually.png',
    ),
    (label: 'surveyMethodNever', asset: 'assets/images/onboarding/never.png'),
  ];

  final Set<int> selectedMethods;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyHistoryQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
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
    (label: 'surveyTimelineFast', asset: 'assets/images/onboarding/fire.png'),
    (
      label: 'surveyTimelineMonths',
      asset: 'assets/images/onboarding/calendar.png',
    ),
    (
      label: 'surveyTimelineLongTerm',
      asset: 'assets/images/onboarding/clock.png',
    ),
  ];

  final int? selectedTimeline;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyTimelineQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
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
      label: 'surveyStudyUnder10',
      asset: 'assets/images/onboarding/under_10_minutes.png',
    ),
    (
      label: 'surveyStudy10To20',
      asset: 'assets/images/onboarding/20_minutes.png',
    ),
    (
      label: 'surveyStudy20To60',
      asset: 'assets/images/onboarding/60_minutes.png',
    ),
    (
      label: 'surveyStudyOverHour',
      asset: 'assets/images/onboarding/many_hours.png',
    ),
  ];

  final int? selectedStudyTime;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyStudyTimeQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
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

class _StudyHabitPage extends StatefulWidget {
  const _StudyHabitPage({required this.isActive});

  final bool isActive;

  @override
  State<_StudyHabitPage> createState() => _StudyHabitPageState();
}

class _StudyHabitPageState extends State<_StudyHabitPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _descriptionOpacity;
  late final Animation<Offset> _descriptionSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.42, curve: Curves.easeOutCubic),
          ),
        );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.58, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _iconSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.14, 0.68, curve: Curves.easeOutCubic),
          ),
        );
    _descriptionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1, curve: Curves.easeOut),
    );
    _descriptionSlide =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
          ),
        );

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StudyHabitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0);
    } else if (oldWidget.isActive && !widget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          FadeTransition(
            opacity: _titleOpacity,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                context.l10n.text('surveyHabitTitle'),
                key: const ValueKey('study-habit-title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
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
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _iconOpacity,
            child: SlideTransition(
              position: _iconSlide,
              child: ScaleTransition(
                scale: _iconScale,
                child: Image.asset(
                  'assets/images/onboarding/time_learn.png',
                  key: const ValueKey('study-habit-icon'),
                  width: 340,
                  fit: BoxFit.contain,
                  cacheWidth: 1000,
                ),
              ),
            ),
          ),
          const SizedBox(height: 27),
          FadeTransition(
            opacity: _descriptionOpacity,
            child: SlideTransition(
              position: _descriptionSlide,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: context.l10n.text('surveyHabitDescription')),
                    TextSpan(
                      text: context.l10n.text('surveyHabitHighlight'),
                      style: const TextStyle(
                        color: Color(0xFF55A8FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                key: const ValueKey('study-habit-description'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferredStudyTimePage extends StatefulWidget {
  const _PreferredStudyTimePage({
    required this.isActive,
    required this.selectedMinutes,
    required this.onChanged,
  });

  final bool isActive;
  final double selectedMinutes;
  final ValueChanged<double> onChanged;

  static const _timeLabelStyle = TextStyle(
    color: Color(0xFFA8C8FF),
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(color: Color(0x8000165B), blurRadius: 6, offset: Offset(0, 2)),
    ],
  );

  @override
  State<_PreferredStudyTimePage> createState() =>
      _PreferredStudyTimePageState();
}

class _PreferredStudyTimePageState extends State<_PreferredStudyTimePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _questionOpacity;
  late final Animation<Offset> _questionSlide;
  late final Animation<double> _timeOpacity;
  late final Animation<double> _timeScale;
  late final Animation<double> _sliderOpacity;
  late final Animation<Offset> _sliderSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _iconSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
          ),
        );
    _questionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.65, curve: Curves.easeOut),
    );
    _questionSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.68, curve: Curves.easeOutCubic),
          ),
        );
    _timeOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.82, curve: Curves.easeOut),
    );
    _timeScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.85, curve: Curves.easeOutBack),
      ),
    );
    _sliderOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 1, curve: Curves.easeOut),
    );
    _sliderSlide = Tween<Offset>(begin: const Offset(0, 0.32), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
          ),
        );

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _PreferredStudyTimePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0);
    } else if (oldWidget.isActive && !widget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          FadeTransition(
            opacity: _iconOpacity,
            child: SlideTransition(
              position: _iconSlide,
              child: ScaleTransition(
                scale: _iconScale,
                child: Image.asset(
                  'assets/images/onboarding/chose_time_learn.png',
                  key: const ValueKey('preferred-study-time-icon'),
                  width: 310,
                  height: 238,
                  fit: BoxFit.contain,
                  cacheWidth: 1000,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeTransition(
            opacity: _questionOpacity,
            child: SlideTransition(
              position: _questionSlide,
              child: Text(
                context.l10n.text('surveyPreferredTimeQuestion'),
                key: const ValueKey('preferred-study-time-question'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _timeOpacity,
            child: ScaleTransition(
              scale: _timeScale,
              child: Text(
                _formatTime(widget.selectedMinutes),
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
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _sliderOpacity,
            child: SlideTransition(
              position: _sliderSlide,
              child: Column(
                key: const ValueKey('preferred-study-time-slider-section'),
                children: [
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
                          value: widget.selectedMinutes,
                          min: 360,
                          max: 1440,
                          divisions: 108,
                          onChanged: widget.onChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '06:00',
                        style: _PreferredStudyTimePage._timeLabelStyle,
                      ),
                      Text(
                        '12:00',
                        style: _PreferredStudyTimePage._timeLabelStyle,
                      ),
                      Text(
                        '18:00',
                        style: _PreferredStudyTimePage._timeLabelStyle,
                      ),
                      Text(
                        '00:00',
                        style: _PreferredStudyTimePage._timeLabelStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyReminderPage extends StatefulWidget {
  const _StudyReminderPage({required this.isActive});

  final bool isActive;

  @override
  State<_StudyReminderPage> createState() => _StudyReminderPageState();
}

class _StudyReminderPageState extends State<_StudyReminderPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _primaryTextOpacity;
  late final Animation<Offset> _primaryTextSlide;
  late final Animation<double> _secondaryTextOpacity;
  late final Animation<Offset> _secondaryTextSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.38, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _iconSlide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.56, curve: Curves.easeOutCubic),
          ),
        );
    _primaryTextOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.72, curve: Curves.easeOut),
    );
    _primaryTextSlide =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.32, 0.76, curve: Curves.easeOutCubic),
          ),
        );
    _secondaryTextOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 1, curve: Curves.easeOut),
    );
    _secondaryTextSlide =
        Tween<Offset>(begin: const Offset(0, 0.24), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
          ),
        );

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StudyReminderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0);
    } else if (oldWidget.isActive && !widget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 10),
          FadeTransition(
            opacity: _iconOpacity,
            child: SlideTransition(
              position: _iconSlide,
              child: ScaleTransition(
                scale: _iconScale,
                child: Image.asset(
                  'assets/images/onboarding/reminder_notification.png',
                  key: const ValueKey('study-reminder-icon'),
                  width: 330,
                  height: 330,
                  fit: BoxFit.contain,
                  cacheWidth: 1000,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _primaryTextOpacity,
            child: SlideTransition(
              position: _primaryTextSlide,
              child: Text(
                context.l10n.text('surveyReminderPrimary'),
                key: const ValueKey('study-reminder-primary-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: _secondaryTextOpacity,
            child: SlideTransition(
              position: _secondaryTextSlide,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: context.l10n.text('surveyReminderSecondary'),
                    ),
                    TextSpan(
                      text: context.l10n.text('surveyReminderHighlight'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                key: const ValueKey('study-reminder-secondary-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
      label: 'surveyChallengeVocabulary',
      asset: 'assets/images/onboarding/learn_and_remember.png',
    ),
    (
      label: 'surveyChallengeGrammar',
      asset: 'assets/images/onboarding/grammar.png',
    ),
    (
      label: 'surveyChallengeSpeaking',
      asset: 'assets/images/onboarding/speak_english.png',
    ),
    (
      label: 'surveyChallengeListening',
      asset: 'assets/images/onboarding/listen_english.png',
    ),
    (
      label: 'surveyChallengeReading',
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
          Text(
            context.l10n.text('surveyChallengeQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071B65),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
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
      label: 'surveyBarrierTime',
      asset: 'assets/images/onboarding/thieu_thoi_gian.png',
    ),
    (
      label: 'surveyBarrierMaterials',
      asset: 'assets/images/onboarding/thieu_tai_lieu.png',
    ),
    (
      label: 'surveyBarrierMethod',
      asset: 'assets/images/onboarding/thieu_lo_trinh.png',
    ),
    (
      label: 'surveyBarrierDifficulty',
      asset: 'assets/images/onboarding/hoc_dieu_moi_kho.png',
    ),
    (
      label: 'surveyBarrierPractice',
      asset: 'assets/images/onboarding/thieu_thuc_hanh.png',
    ),
    (
      label: 'surveyBarrierNone',
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
          Text(
            context.l10n.text('surveyBarrierQuestion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w700,
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
                  context.l10n.text(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071B65),
                    fontSize: 16,
                    height: 1.22,
                    fontWeight: FontWeight.w600,
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
      title: 'surveyReviewOneTitle',
      text: 'surveyReviewOneBody',
    ),
    (author: 'Oki', title: 'surveyReviewTwoTitle', text: 'surveyReviewTwoBody'),
    (
      author: 'Minh Anh',
      title: 'surveyReviewThreeTitle',
      text: 'surveyReviewThreeBody',
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
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Bright',
                  style: TextStyle(
                    color: Color(0xFF39A9FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: context.l10n.text('surveySocialProofPrefix')),
                const TextSpan(
                  text: '2.000.000',
                  style: TextStyle(
                    color: Color(0xFF42D7F4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: context.l10n.text('surveySocialProofSuffix')),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            context.l10n.text(title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              context.l10n.text(text),
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

class _TopicSelectionPage extends ConsumerWidget {
  const _TopicSelectionPage({
    required this.selectedTopics,
    required this.onToggle,
    required this.onToggleAll,
  });

  final Set<int> selectedTopics;
  final ValueChanged<int> onToggle;
  final ValueChanged<List<Topic>> onToggleAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(onboardingTopicsProvider);

    return topicsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          context.l10n.topicsLoadError,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      data: (topics) => _buildTopicList(context, topics),
    );
  }

  Widget _buildTopicList(BuildContext context, List<Topic> topics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            context.l10n.text('surveyTopicTitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.75,
              shadows: [
                Shadow(
                  color: Color(0xFF2379FF),
                  blurRadius: 13,
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
          _TopicSelectAllCard(
            key: const ValueKey('survey-topic-select-all'),
            selectedCount: topics
                .where((topic) => selectedTopics.contains(topic.order))
                .length,
            totalCount: topics.length,
            onTap: () => onToggleAll(topics),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < topics.length; index++) ...[
            _TopicOptionCard(
              key: ValueKey('survey-topic-${topics[index].order}'),
              label: topics[index].translated.isNotEmpty
                  ? topics[index].translated
                  : topics[index].original,
              imageAsset: topicIconAsset(topics[index]),
              selected: selectedTopics.contains(topics[index].order),
              onTap: () => onToggle(topics[index].order),
            ),
            if (index != topics.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _TopicSelectAllCard extends StatelessWidget {
  const _TopicSelectAllCard({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onTap,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: _TopicSelectionStyles.cardDecoration,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.text('surveySelectAll'),
                  style: _TopicSelectionStyles.labelStyle,
                ),
              ),
              _TopicSelectionIndicator(
                selectedCount: selectedCount,
                totalCount: totalCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicOptionCard extends StatelessWidget {
  const _TopicOptionCard({
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
        child: Container(
          height: 58,
          decoration: _TopicSelectionStyles.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 70,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEEFF),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
                child: SvgPicture.asset(imageAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _TopicSelectionStyles.labelStyle,
                ),
              ),
              _SurveyCheckbox(selected: selected),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicSelectionIndicator extends StatelessWidget {
  const _TopicSelectionIndicator({
    required this.selectedCount,
    required this.totalCount,
  });

  final int selectedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final allSelected = selectedCount == totalCount;

    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        gradient: hasSelection
            ? const LinearGradient(
                colors: [Color(0xFF10CF55), Color(0xFF06A92E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasSelection ? null : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: hasSelection
              ? const Color(0xFF2CDD67)
              : const Color(0xFF6898F6),
          width: 1.5,
        ),
        boxShadow: hasSelection
            ? const [
                BoxShadow(
                  color: Color(0x6611C448),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: hasSelection
          ? Icon(
              allSelected ? Icons.check_rounded : Icons.remove_rounded,
              color: Colors.white,
              size: 22,
            )
          : null,
    );
  }
}

abstract final class _TopicSelectionStyles {
  static const labelStyle = TextStyle(
    color: Color(0xFF071B65),
    fontSize: 16.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.95),
    borderRadius: BorderRadius.circular(17),
    border: Border.all(color: const Color(0xFF73C5FF), width: 1.1),
    boxShadow: const [
      BoxShadow(color: Color(0xA02286F5), blurRadius: 14, offset: Offset(0, 5)),
    ],
  );
}

class _AnalysisLoadingPage extends StatefulWidget {
  const _AnalysisLoadingPage({
    required this.isActive,
    required this.onCompleted,
  });

  final bool isActive;
  final VoidCallback onCompleted;

  @override
  State<_AnalysisLoadingPage> createState() => _AnalysisLoadingPageState();
}

class _AnalysisLoadingPageState extends State<_AnalysisLoadingPage> {
  static const _steps = [
    'surveyAnalysisTopic',
    'surveyAnalysisDictionary',
    'surveyAnalysisExercises',
    'surveyAnalysisPace',
  ];

  Timer? _stepTimer;
  Timer? _completionTimer;
  int _completedSteps = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startAnalysis();
  }

  @override
  void didUpdateWidget(covariant _AnalysisLoadingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _startAnalysis();
    } else if (oldWidget.isActive && !widget.isActive) {
      _cancelTimers();
    }
  }

  void _startAnalysis() {
    _cancelTimers();
    _completedSteps = 0;
    _isComplete = false;
    _stepTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted || !widget.isActive) {
        timer.cancel();
        return;
      }

      final nextStep = _completedSteps + 1;
      setState(() => _completedSteps = nextStep);
      if (nextStep < _steps.length) return;

      timer.cancel();
      setState(() => _isComplete = true);
      _completionTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted && widget.isActive) widget.onCompleted();
      });
    });
  }

  void _cancelTimers() {
    _stepTimer?.cancel();
    _completionTimer?.cancel();
    _stepTimer = null;
    _completionTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 86),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1677FF).withValues(alpha: 0.22),
                      const Color(0xFF004AE8).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99145DFF),
                      blurRadius: 70,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              Lottie.asset(
                'assets/lotties/Loading_wave.json',
                key: const ValueKey('survey-analysis-lottie'),
                width: 325,
                height: 325,
                fit: BoxFit.contain,
                repeat: !_isComplete,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _isComplete
                    ? const _AnalysisCompleteMark(
                        key: ValueKey('analysis-complete'),
                      )
                    : Text(
                        context.l10n.text('surveyAnalysisProcessing'),
                        key: const ValueKey('analysis-processing'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Color(0xFF2E8DFF), blurRadius: 13),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 250,
            height: 180,
            child: Column(
              children: [
                for (var index = 0; index < _steps.length; index++)
                  _AnalysisStep(
                    label: _steps[index],
                    visible: index < _completedSteps,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCompleteMark extends StatelessWidget {
  const _AnalysisCompleteMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 146,
      height: 146,
      child: CustomPaint(painter: _AnalysisCheckPainter()),
    );
  }
}

class _AnalysisCheckPainter extends CustomPainter {
  const _AnalysisCheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.83, size.height * 0.27);

    canvas.save();
    canvas.translate(4, 12);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xB000123F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 29
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF008656)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB5FFD2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCCFFE0), Color(0xFF56FFA0), Color(0xFF10C975)],
          stops: [0, 0.48, 1],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalysisCheckPainter oldDelegate) => false;
}

class _AnalysisStep extends StatelessWidget {
  const _AnalysisStep({required this.label, required this.visible});

  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        scale: visible ? 1 : 0.72,
        child: SizedBox(
          height: 43,
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D8F53).withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF79FF43),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xCC52FF46),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  context.l10n.text(label),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Color(0xFF125FFF), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeJourneyPage extends StatefulWidget {
  const _KnowledgeJourneyPage({required this.isActive});

  final bool isActive;

  @override
  State<_KnowledgeJourneyPage> createState() => _KnowledgeJourneyPageState();
}

class _KnowledgeJourneyPageState extends State<_KnowledgeJourneyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.62, curve: Curves.easeOutBack),
      ),
    );
    _iconSlide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
          ),
        );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.24), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
          ),
        );

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _KnowledgeJourneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0);
    } else if (oldWidget.isActive && !widget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 34),
          FadeTransition(
            opacity: _iconOpacity,
            child: SlideTransition(
              position: _iconSlide,
              child: ScaleTransition(
                scale: _iconScale,
                child: Image.asset(
                  'assets/images/onboarding/open_know.png',
                  key: const ValueKey('knowledge-journey-icon'),
                  width: 340,
                  fit: BoxFit.contain,
                  cacheWidth: 1000,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeTransition(
            opacity: _textOpacity,
            child: SlideTransition(
              position: _textSlide,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: context.l10n.text('surveyKnowledgeLead')),
                    TextSpan(
                      text: context.l10n.text('surveyKnowledgeOpen'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: context.l10n.text('surveyKnowledgeConnect')),
                    TextSpan(
                      text: context.l10n.text('surveyKnowledgeMore'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                key: const ValueKey('knowledge-journey-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
      text: 'surveySummaryQuoteOne',
      source: 'Source: BBC Worklife\ncareer growth and global work',
    ),
    (
      text: 'surveySummaryQuoteTwo',
      source: 'Source: World Economic Forum\nfuture of jobs and skills',
    ),
    (
      text: 'surveySummaryQuoteThree',
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
          Text(
            context.l10n.text('surveySummaryTitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w700,
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
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: context.l10n.text('surveySummaryWith')),
                const TextSpan(
                  text: 'Leximon',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: context.l10n.text('surveySummaryDaily')),
                TextSpan(
                  text: context.l10n.text('surveySummaryOpportunities'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: context.l10n.text('surveySummaryGoals')),
                TextSpan(
                  text: context.l10n.text('surveySummaryCareer'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
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
                  context.l10n.text(text),
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
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool showArrow;
  final bool useBlueGradient;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: !isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFFD9E2EC), Color(0xFFEEF3F8)],
                )
              : useBlueGradient
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
          border: Border.all(
            color: isEnabled ? Colors.white : const Color(0xFFC9D5E1),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? const [
                  BoxShadow(
                    color: Color(0x701B8CFF),
                    blurRadius: 26,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(34),
          child: InkWell(
            key: const ValueKey('survey-carousel-continue'),
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      color: useBlueGradient
                          ? (isEnabled ? Colors.white : const Color(0xFF8393A5))
                          : (isEnabled
                                ? const Color(0xFF1263F4)
                                : const Color(0xFF8393A5)),
                      strokeWidth: 2.5,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: useBlueGradient
                          ? (isEnabled ? Colors.white : const Color(0xFF8393A5))
                          : (isEnabled
                                ? const Color(0xFF1263F4)
                                : const Color(0xFF8393A5)),
                      fontSize: label.length > 10 ? 18 : 19,
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
    color: Color(0xFFFFFFFF),
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w700,
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
