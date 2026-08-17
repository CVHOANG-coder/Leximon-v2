import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/services/listening_progress_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../speaking_practice/speaking_exercise_screen.dart';
import 'skill_pack_purchase_screen.dart';
import 'listening_preload_screen.dart';

class ListeningCourseDetailScreen extends ConsumerStatefulWidget {
  const ListeningCourseDetailScreen({
    required this.courseId,
    required this.courseName,
    required this.courseIndexAsset,
    required this.lessonCount,
    required this.levelName,
    this.speakingMode = false,
    super.key,
  });

  final int courseId;
  final String courseName;
  final String courseIndexAsset;
  final int lessonCount;
  final String levelName;
  final bool speakingMode;

  @override
  ConsumerState<ListeningCourseDetailScreen> createState() =>
      _ListeningCourseDetailScreenState();
}

class _ListeningCourseDetailScreenState
    extends ConsumerState<ListeningCourseDetailScreen> {
  late final Future<_CourseDetailData> _detailFuture;
  final _searchController = TextEditingController();
  final Set<int> _expandedGroupIds = {};
  Map<int, _LessonProgress> _progressByLessonId = const {};
  String _query = '';
  String? _selectedLevel;
  late _PracticeMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.speakingMode
        ? _PracticeMode.speaking
        : _PracticeMode.listenAndType;
    _detailFuture = _loadCourseDetail(widget.courseIndexAsset);
    _loadProgress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillPack = _mode == _PracticeMode.speaking
        ? SkillPackType.speaking
        : SkillPackType.listening;
    final ownsSkillPack =
        ref
            .watch(remoteUserProfileProvider)
            .valueOrNull
            ?.ownedProductIds
            .contains(skillPack.productId) ==
        true;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('listening-course-detail-screen'),
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/practice_listen/bg_course_detail.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            FutureBuilder<_CourseDetailData>(
              future: _detailFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final groups = data == null
                    ? const <_LessonGroup>[]
                    : _visibleGroups(data);

                return CustomScrollView(
                  key: const ValueKey('listening-course-detail-scroll'),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _CourseDetailHeader(
                        courseName: widget.courseName,
                        lessonCount: widget.lessonCount,
                        levelName: widget.levelName,
                        onBack: () => Navigator.of(context).maybePop(),
                        onFilter: data == null
                            ? null
                            : () => _showLevelFilter(context, data.levels),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ModeSwitcher(
                          selected: _mode,
                          onSelected: _selectMode,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _DetailSearchField(
                          controller: _searchController,
                          onChanged: (value) => setState(
                            () => _query = value.trim().toLowerCase(),
                          ),
                          onFilter: data == null
                              ? null
                              : () => _showLevelFilter(context, data.levels),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ActiveFilters(
                        selectedLevel: _selectedLevel,
                        onClearLevel: () =>
                            setState(() => _selectedLevel = null),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _DetailEmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: context.l10n.text('listeningLessonsLoadError'),
                        ),
                      )
                    else if (groups.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _DetailEmptyState(
                          icon: Icons.search_off_rounded,
                          title: context.l10n.text('listeningLessonsEmpty'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final group = groups[index];
                            final expanded =
                                _query.isNotEmpty ||
                                _selectedLevel != null ||
                                _expandedGroupIds.contains(group.id);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == groups.length - 1 ? 0 : 12,
                              ),
                              child: _LessonGroupCard(
                                group: group,
                                sectionIndex: index,
                                expanded: expanded,
                                onToggle: () => _toggleGroup(group.id),
                                onLessonTap: _openLesson,
                                onLockedLessonTap: _openSkillPackPurchase,
                                progressByLessonId: _progressByLessonId,
                                ownsSkillPack: ownsSkillPack,
                              ),
                            );
                          }, childCount: groups.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_LessonGroup> _visibleGroups(_CourseDetailData data) {
    final visible = <_LessonGroup>[];
    for (final group in data.groups) {
      final lessons = group.lessons.where((lesson) {
        final matchesQuery =
            _query.isEmpty ||
            lesson.name.toLowerCase().contains(_query) ||
            lesson.subtitle.toLowerCase().contains(_query);
        final matchesLevel =
            _selectedLevel == null || lesson.levelName == _selectedLevel;
        return matchesQuery && matchesLevel;
      }).toList();
      if (lessons.isNotEmpty) {
        visible.add(group.copyWith(lessons: lessons));
      }
    }
    return visible;
  }

  void _toggleGroup(int id) {
    setState(() {
      if (!_expandedGroupIds.add(id)) _expandedGroupIds.remove(id);
    });
  }

  Future<void> _openLesson(_ListeningLesson lesson) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _mode == _PracticeMode.speaking
            ? SpeakingExerciseScreen(
                courseId: widget.courseId,
                courseIndexAsset: widget.courseIndexAsset,
                lessonId: lesson.id,
              )
            : ListeningPreloadScreen(
                courseId: widget.courseId,
                courseIndexAsset: widget.courseIndexAsset,
                lessonId: lesson.id,
                lessonName: lesson.name,
              ),
      ),
    );
    await _loadProgress();
  }

  Future<void> _openSkillPackPurchase() async {
    final skill = _mode == _PracticeMode.speaking
        ? SkillPackType.speaking
        : SkillPackType.listening;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SkillPackPurchaseScreen(skill: skill),
      ),
    );
    if (mounted) ref.invalidate(remoteUserProfileProvider);
  }

  void _selectMode(_PracticeMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _progressByLessonId = const {};
    });
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = <int, _LessonProgress>{};
    if (_mode == _PracticeMode.speaking) {
      final rows = await ref
          .read(speakingProgressServiceProvider)
          .loadCourseLessons(widget.courseId);
      for (final entry in rows.entries) {
        progress[entry.key] = _LessonProgress(
          completed: entry.value.completedSentences,
          status: entry.value.status,
        );
      }
    } else {
      final rows = await ref
          .read(listeningProgressServiceProvider)
          .loadCourseLessons(widget.courseId);
      for (final entry in rows.entries) {
        progress[entry.key] = _LessonProgress(
          completed: entry.value.completedChallenges,
          status: entry.value.status,
        );
      }
    }
    if (mounted) setState(() => _progressByLessonId = progress);
  }

  Future<void> _showLevelFilter(
    BuildContext context,
    List<String> levels,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _LevelFilterSheet(levels: levels, selected: _selectedLevel),
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedLevel = selected == '__all__' ? null : selected);
  }
}

class _CourseDetailHeader extends StatelessWidget {
  const _CourseDetailHeader({
    required this.courseName,
    required this.lessonCount,
    required this.levelName,
    required this.onBack,
    required this.onFilter,
  });

  final String courseName;
  final int lessonCount;
  final String levelName;
  final VoidCallback onBack;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, safeTop + 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: context.l10n.back,
                onTap: onBack,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  courseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 26,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.9,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _HeaderButton(
                icon: Icons.filter_alt_outlined,
                label: context.l10n.text('filter'),
                onTap: onFilter,
                showLabel: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HeaderMetaPill(
                icon: Icons.menu_book_rounded,
                label: context.l10n.text(
                  'lessonCount',
                  values: {'count': lessonCount},
                ),
              ),
              _HeaderMetaPill(
                icon: Icons.star_border_rounded,
                label: context.l10n.text(
                  'levelValue',
                  values: {'level': levelName},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showLabel = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .86),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x162A70B8),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 21),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _HeaderMetaPill extends StatelessWidget {
  const _HeaderMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFD8E6F8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF315B98),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.selected, required this.onSelected});

  final _PracticeMode selected;
  final ValueChanged<_PracticeMode> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: .9),
          const Color(0xFFEAF4FF).withValues(alpha: .88),
        ],
      ),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A2A70B8),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        for (final mode in _PracticeMode.values)
          Expanded(
            child: SizedBox.expand(
              child: _ModeOption(
                mode: mode,
                selected: selected == mode,
                onTap: () => onSelected(mode),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _PracticeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF65A0FF), Color(0xFF2168F4)],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x4D2875F5),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode.icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.text(mode.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailSearchField extends StatelessWidget {
  const _DetailSearchField({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .86),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white),
            boxShadow: const [
              BoxShadow(
                color: Color(0x172A70B8),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            key: const ValueKey('course-detail-search'),
            controller: controller,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: context.l10n.text('searchStories'),
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryDark,
                size: 19,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 39),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _SearchFilterButton(onTap: onFilter),
    ],
  );
}

class _SearchFilterButton extends StatelessWidget {
  const _SearchFilterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F2A70B8),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: AppColors.primaryDark,
          size: 19,
        ),
      ),
    ),
  );
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.selectedLevel,
    required this.onClearLevel,
  });

  final String? selectedLevel;
  final VoidCallback onClearLevel;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Row(
      children: [
        _StatusChip(
          label: selectedLevel ?? context.l10n.text('allLevels'),
          selected: selectedLevel != null,
          onTap: selectedLevel == null ? null : onClearLevel,
        ),
        const SizedBox(width: 8),
        _StatusChip(label: context.l10n.text('notStarted')),
        const SizedBox(width: 8),
        _StatusChip(label: context.l10n.text('inProgress')),
        const SizedBox(width: 8),
        _StatusChip(label: context.l10n.text('completed')),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppColors.surfaceBlue
        : Colors.white.withValues(alpha: .72),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFD8E4F4),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: selected ? AppColors.primary : AppColors.primaryDark,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LessonGroupCard extends StatelessWidget {
  const _LessonGroupCard({
    required this.group,
    required this.sectionIndex,
    required this.expanded,
    required this.onToggle,
    required this.onLessonTap,
    required this.onLockedLessonTap,
    required this.progressByLessonId,
    required this.ownsSkillPack,
  });

  final _LessonGroup group;
  final int sectionIndex;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<_ListeningLesson> onLessonTap;
  final VoidCallback onLockedLessonTap;
  final Map<int, _LessonProgress> progressByLessonId;
  final bool ownsSkillPack;

  static const _sectionColors = [
    [Color(0xFF87C8FF), Color(0xFF286AFF)],
    [Color(0xFF8CE8C2), Color(0xFF20B979)],
    [Color(0xFFC5B1FF), Color(0xFF7755E8)],
    [Color(0xFFFFD171), Color(0xFFFFA51F)],
  ];
  static const _sectionIcons = [
    Icons.auto_stories_rounded,
    Icons.landscape_rounded,
    Icons.air_rounded,
    Icons.home_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _sectionColors[sectionIndex % _sectionColors.length];
    final icon = _sectionIcons[sectionIndex % _sectionIcons.length];
    final totalChallenges = group.lessons.fold<int>(
      0,
      (total, lesson) => total + lesson.totalChallenges,
    );
    final completedChallenges = group.lessons.fold<int>(
      0,
      (total, lesson) =>
          total + (progressByLessonId[lesson.id]?.completed ?? 0),
    );
    final completionPercent = totalChallenges == 0
        ? 0
        : (completedChallenges * 100 / totalChallenges).round();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: expanded
              ? AppColors.primary.withValues(alpha: .3)
              : Colors.white,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1B2A70B8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _SectionIcon(colors: colors, icon: icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.text(group.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.yellow,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.text(
                                  'lessonCount',
                                  values: {'count': group.lessons.length},
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (expanded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: .28),
                          ),
                        ),
                        child: Text(
                          context.l10n.text(
                            'percentComplete',
                            values: {'percent': completionPercent},
                          ),
                          style: const TextStyle(
                            color: Color(0xFF159769),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 7),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < group.lessons.length;
                    index++
                  ) ...[
                    _LessonCard(
                      lesson: group.lessons[index],
                      displayIndex: index + 1,
                      onTap: ownsSkillPack
                          ? () => onLessonTap(group.lessons[index])
                          : onLockedLessonTap,
                      progress: progressByLessonId[group.lessons[index].id],
                      isLocked: !ownsSkillPack,
                    ),
                    if (index != group.lessons.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.colors, required this.icon});

  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: .28),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 27),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.displayIndex,
    required this.onTap,
    required this.progress,
    required this.isLocked,
  });

  final _ListeningLesson lesson;
  final int displayIndex;
  final VoidCallback onTap;
  final _LessonProgress? progress;
  final bool isLocked;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    // Locked lessons intentionally keep a tap handler so they can open the
    // skill-pack purchase screen. The caller supplies either the lesson
    // action or the unlock flow based on the ownership state.
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isLocked ? .45 : 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EBF6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x122A70B8),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$displayIndex',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanLessonName(lesson.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _LessonMeta(
                        icon: Icons.extension_rounded,
                        label: context.l10n.text(
                          'challengeCount',
                          values: {'count': lesson.totalChallenges},
                        ),
                        color: AppColors.purple,
                      ),
                      _LessonMeta(
                        icon: Icons.bar_chart_rounded,
                        label: context.l10n.text(
                          'levelValue',
                          values: {'level': lesson.levelName},
                        ),
                        color: AppColors.primary,
                      ),
                      _LessonMeta(
                        icon: Icons.adjust_rounded,
                        label:
                            progress?.status ==
                                ListeningLessonStatus.completed.index
                            ? context.l10n.text('completed')
                            : context.l10n.text(
                                'challengeCount',
                                values: {
                                  'count':
                                      '${progress?.completed ?? 0}/${lesson.totalChallenges}',
                                },
                              ),
                        color: AppColors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.chevron_right_rounded,
              color: isLocked ? AppColors.textMuted : const Color(0xFF5F79A6),
              size: isLocked ? 22 : 25,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .13)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LevelFilterSheet extends StatelessWidget {
  const _LevelFilterSheet({required this.levels, required this.selected});

  final List<String> levels;
  final String? selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.text('listeningFilterByLevel'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _LevelChoice(
                label: context.l10n.text('listeningCategoryAll'),
                selected: selected == null,
                onTap: () => Navigator.pop(context, '__all__'),
              ),
              for (final level in levels)
                _LevelChoice(
                  label: level,
                  selected: selected == level,
                  onTap: () => Navigator.pop(context, level),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LevelChoice extends StatelessWidget {
  const _LevelChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.surfaceBlue,
    side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
    labelStyle: TextStyle(
      color: selected ? AppColors.primary : AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 44),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CourseDetailData {
  const _CourseDetailData({required this.groups, required this.levels});

  final List<_LessonGroup> groups;
  final List<String> levels;
}

class _LessonGroup {
  const _LessonGroup({
    required this.id,
    required this.name,
    required this.lessons,
  });

  final int id;
  final String name;
  final List<_ListeningLesson> lessons;

  _LessonGroup copyWith({List<_ListeningLesson>? lessons}) =>
      _LessonGroup(id: id, name: name, lessons: lessons ?? this.lessons);
}

class _ListeningLesson {
  const _ListeningLesson({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.levelName,
    required this.totalChallenges,
    required this.groupId,
  });

  factory _ListeningLesson.fromJson(
    Map<String, dynamic> json,
    String fallbackLevel,
  ) => _ListeningLesson(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    subtitle: json['subTitle'] as String? ?? '',
    levelName: (json['levelName'] as String?)?.isNotEmpty == true
        ? json['levelName'] as String
        : fallbackLevel,
    totalChallenges: json['totalChallenges'] as int? ?? 0,
    groupId: json['groupId'] as int?,
  );

  final int id;
  final String name;
  final String subtitle;
  final String levelName;
  final int totalChallenges;
  final int? groupId;
}

enum _PracticeMode {
  listenAndType('listeningModeType', Icons.headphones_rounded),
  speaking('speakingMode', Icons.mic_rounded);

  const _PracticeMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _LessonProgress {
  const _LessonProgress({required this.completed, required this.status});

  final int completed;
  final int status;
}

Future<_CourseDetailData> _loadCourseDetail(String assetPath) async {
  final encoded = await rootBundle.loadString(assetPath);
  final json = jsonDecode(encoded) as Map<String, dynamic>;
  final courseLevel = json['levelName'] as String? ?? 'A1';
  final fallbackLevel = courseLevel.split('-').first;
  final lessons = (json['lessons'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((lesson) => _ListeningLesson.fromJson(lesson, fallbackLevel))
      .toList();
  final rawGroups = (json['lessonGroups'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();

  final groups = <_LessonGroup>[];
  if (rawGroups.isEmpty) {
    groups.add(_LessonGroup(id: -1, name: 'lessons', lessons: lessons));
  } else {
    final groupedIds = <int>{};
    for (final rawGroup in rawGroups) {
      final id = rawGroup['id'] as int;
      groupedIds.add(id);
      final groupLessons = lessons
          .where((lesson) => lesson.groupId == id)
          .toList();
      if (groupLessons.isNotEmpty) {
        groups.add(
          _LessonGroup(
            id: id,
            name: rawGroup['name'] as String? ?? 'Section ${groups.length + 1}',
            lessons: groupLessons,
          ),
        );
      }
    }
    final remainingLessons = lessons
        .where((lesson) => !groupedIds.contains(lesson.groupId))
        .toList();
    if (remainingLessons.isNotEmpty) {
      groups.add(
        _LessonGroup(id: -1, name: 'otherLessons', lessons: remainingLessons),
      );
    }
  }

  final levels =
      lessons
          .map((lesson) => lesson.levelName)
          .where((level) => level.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return _CourseDetailData(groups: groups, levels: levels);
}

String _cleanLessonName(String value) =>
    value.replaceFirst(RegExp(r'^\d+\.\s*'), '');
