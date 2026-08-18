import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/listening_asset_data_source.dart';
import '../../../data/models/listening_catalog.dart';
import '../../../shared/providers/app_providers.dart';
import 'listening_course_detail_screen.dart';

class ListeningPracticeScreen extends ConsumerStatefulWidget {
  const ListeningPracticeScreen({this.speakingMode = false, super.key});

  final bool speakingMode;

  @override
  ConsumerState<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState
    extends ConsumerState<ListeningPracticeScreen> {
  final _searchController = TextEditingController();
  late final Future<List<_ListeningCourse>> _coursesFuture;
  _ListeningFilter _selectedFilter = _ListeningFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses(ref.read(listeningAssetDataSourceProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: ValueKey(
          widget.speakingMode
              ? 'speaking-practice-screen'
              : 'listening-practice-screen',
        ),
        backgroundColor: AppColors.background,
        body: FutureBuilder<List<_ListeningCourse>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            final courses = snapshot.data ?? const <_ListeningCourse>[];
            final visibleCourses = courses.where(_matchesFilters).toList();
            final featured = visibleCourses.where((course) => course.id == 2);
            final regularCourses = visibleCourses
                .where((course) => course.id != 2)
                .toList();

            return CustomScrollView(
              key: const ValueKey('listening-practice-scroll'),
              slivers: [
                SliverToBoxAdapter(
                  child: _ListeningHeader(
                    controller: _searchController,
                    speakingMode: widget.speakingMode,
                    onQueryChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterBar(
                    selected: _selectedFilter,
                    onSelected: (filter) =>
                        setState(() => _selectedFilter = filter),
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
                    child: _ListeningEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: context.l10n.text('listeningTopicsLoadError'),
                      body: context.l10n.text('tryAgainLater'),
                    ),
                  )
                else if (visibleCourses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ListeningEmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.text('listeningTopicsEmpty'),
                      body: context.l10n.text('tryDifferentSearchFilter'),
                    ),
                  )
                else ...[
                  if (featured.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                      sliver: SliverToBoxAdapter(
                        child: _FeaturedCourseCard(
                          course: featured.first,
                          onTap: () => _openCourse(featured.first),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      featured.isNotEmpty ? 14 : 20,
                      8,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == regularCourses.length - 1 ? 0 : 12,
                          ),
                          child: _CourseCard(
                            course: regularCourses[index],
                            onTap: () => _openCourse(regularCourses[index]),
                          ),
                        );
                      }, childCount: regularCourses.length),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilters(_ListeningCourse course) {
    final matchesQuery =
        _query.isEmpty || course.name.toLowerCase().contains(_query);
    if (!matchesQuery) return false;
    return switch (_selectedFilter) {
      _ListeningFilter.all => true,
      _ListeningFilter.stories => const {2, 13}.contains(course.id),
      _ListeningFilter.videos => course.type == 'youtube',
      _ListeningFilter.exams => const {1, 7, 10, 18}.contains(course.id),
      _ListeningFilter.basics => const {3, 4, 6, 9}.contains(course.id),
    };
  }

  void _openCourse(_ListeningCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListeningCourseDetailScreen(
          courseId: course.id,
          courseName: course.name,
          courseIndexAsset: course.indexAsset,
          lessonCount: course.lessonCount,
          levelName: course.levelName,
          speakingMode: widget.speakingMode,
        ),
      ),
    );
  }
}

class _ListeningHeader extends StatelessWidget {
  const _ListeningHeader({
    required this.controller,
    required this.onQueryChanged,
    required this.speakingMode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final bool speakingMode;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: safeTop + 210,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 28,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD9F3FF), Color(0xFFEDF5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(34),
                ),
              ),
              child: Opacity(
                opacity: .38,
                child: Image.asset(
                  'assets/images/practice_listen/banner_header_all_course.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: safeTop + 10,
            left: 18,
            child: _RoundIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: context.l10n.back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: safeTop + 62,
            left: 10,
            right: 155,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text(
                    speakingMode
                        ? 'speakingPracticeTitle'
                        : 'listeningPracticeTitle',
                  ),
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  speakingMode
                      ? context.l10n.text('speakingPracticeSubtitle')
                      : context.l10n.text('listeningPracticeSubtitle'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF52739A),
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: safeTop + 36,
            right: 16,
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/practice_listen/owl_listener.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: _SearchField(
              controller: controller,
              onChanged: onQueryChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E5F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2A70B8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const ValueKey('listening-search-field'),
              controller: controller,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: context.l10n.text('searchTopics'),
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFCFE0FA)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _ListeningFilter selected;
  final ValueChanged<_ListeningFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _ListeningFilter.values) ...[
            _FilterChip(
              filter: filter,
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
            if (filter != _ListeningFilter.values.last)
              const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _ListeningFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? Colors.transparent : const Color(0xFFD5E2F4),
      ),
    );
    return Material(
      color: selected ? AppColors.primary : Colors.white.withValues(alpha: .8),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                filter.icon,
                size: 18,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                context.l10n.text(filter.label),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCourseCard extends StatelessWidget {
  const _FeaturedCourseCard({required this.course, required this.onTap});

  final _ListeningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const ValueKey('featured-listening-course'),
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FCFF), Color(0xFFE9F2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x242A70B8),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * .5,
                  child: const DecoratedBox(
                    key: ValueKey('featured-course-artwork-gradient'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(26),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF9FE3FF),
                          Color(0xFFC8F1FF),
                          Color(0xFFF8FCFF),
                        ],
                        stops: [0, .62, 1],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 7,
                  bottom: 2,
                  width: constraints.maxWidth * .35,
                  child: Image.asset(course.imageAsset, fit: BoxFit.contain),
                ),
                Positioned(
                  left: constraints.maxWidth * .44,
                  right: 48,
                  top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          context.l10n.text('featured'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 21,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CourseMetadata(course: course),
                    ],
                  ),
                ),
                const Positioned(
                  right: 13,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _CourseArrow(size: 40)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final _ListeningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        key: ValueKey('listening-course-${course.id}'),
        height: 124,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5ECF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x182A70B8),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 4,
                bottom: 4,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(course.imageAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: 112,
                top: 0,
                right: 48,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CourseLevelBadge(levelName: course.levelName),
                    const SizedBox(height: 7),
                    _CourseLessonCount(lessonCount: course.lessonCount),
                  ],
                ),
              ),
              if (course.isVideo)
                const Positioned(right: 2, top: 2, child: _VideoBadge()),
              const Positioned(right: 3, bottom: 3, child: _CourseListArrow()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseMetadata extends StatelessWidget {
  const _CourseMetadata({required this.course});

  final _ListeningCourse course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CourseLevelBadge(levelName: course.levelName),
        const SizedBox(height: 8),
        _CourseLessonCount(lessonCount: course.lessonCount),
      ],
    );
  }
}

class _CourseLevelBadge extends StatelessWidget {
  const _CourseLevelBadge({required this.levelName});

  final String levelName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      context.l10n.text('levelValue', values: {'level': levelName}),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 9,
        height: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CourseLessonCount extends StatelessWidget {
  const _CourseLessonCount({required this.lessonCount});

  final int lessonCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.menu_book_rounded, color: Color(0xFF52739A), size: 15),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          context.l10n.text('lessonCount', values: {'count': lessonCount}),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF52739A),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1DF),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_fill_rounded, color: AppColors.orange, size: 12),
        SizedBox(width: 3),
        Text(
          'Video',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CourseArrow extends StatelessWidget {
  const _CourseArrow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A155CFF),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Icon(
      Icons.arrow_forward_rounded,
      color: AppColors.primary,
      size: size * .52,
    ),
  );
}

class _CourseListArrow extends StatelessWidget {
  const _CourseListArrow();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE3ECFA)),
    ),
    child: const Icon(
      Icons.arrow_forward_rounded,
      color: AppColors.primary,
      size: 16,
    ),
  );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .92)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A2E72B8),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: IconButton(
      tooltip: semanticLabel,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: AppColors.primary, size: 21),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(42),
        maximumSize: const Size.square(42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}

class _ListeningEmptyState extends StatelessWidget {
  const _ListeningEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: AppColors.textMuted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

class _ListeningCourse {
  const _ListeningCourse({
    required this.id,
    required this.name,
    required this.type,
    required this.lessonCount,
    required this.levelName,
    required this.indexAsset,
  });

  factory _ListeningCourse.fromSummary(ListeningCourseSummary summary) {
    return _ListeningCourse(
      id: summary.id,
      name: summary.name,
      type: summary.type,
      lessonCount: summary.totalLessons > 0
          ? summary.totalLessons
          : summary.lessons.length,
      levelName: summary.levelName,
      indexAsset: summary.indexAsset,
    );
  }

  final int id;
  final String name;
  final String type;
  final int lessonCount;
  final String levelName;
  final String indexAsset;

  bool get isVideo => type == 'youtube';

  String get imageAsset =>
      'assets/images/practice_listen/${_imageFileByCourseId[id] ?? 'short_stories.png'}';
}

enum _ListeningFilter {
  all('listeningCategoryAll', Icons.grid_view_rounded),
  stories('listeningCategoryStories', Icons.auto_stories_rounded),
  videos('Video', Icons.smart_display_rounded),
  exams('listeningCategoryExams', Icons.school_rounded),
  basics('listeningCategoryBasics', Icons.abc_rounded);

  const _ListeningFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

Future<List<_ListeningCourse>> _loadCourses(
  ListeningAssetDataSource dataSource,
) async {
  final summaries = await dataSource.loadCatalog();
  final courses = summaries.map(_ListeningCourse.fromSummary).toList();
  courses.sort(
    (a, b) =>
        _displayOrder.indexOf(a.id).compareTo(_displayOrder.indexOf(b.id)),
  );
  return courses;
}

const _displayOrder = [2, 6, 13, 10, 1, 8, 14, 12, 7, 18, 9, 4, 3];

const _imageFileByCourseId = <int, String>{
  1: 'IELTS_listening.png',
  2: 'short_stories.png',
  3: 'spelling_names.png',
  4: 'numbers.png',
  6: 'conversations.png',
  7: 'TOEFL_listening.png',
  8: 'random_videos.png',
  9: 'IPA.png',
  10: 'TOEIC_listening.png',
  12: 'TED.png',
  13: 'stories_for_kids.png',
  14: 'news.png',
  18: 'medical_english_oet.png',
};
