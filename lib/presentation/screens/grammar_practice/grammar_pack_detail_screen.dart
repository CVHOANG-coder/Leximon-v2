import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import 'grammar_exercise_screen.dart';
import 'grammar_practice_screen.dart';
import '../listening_practice/skill_pack_purchase_screen.dart';

const grammarPackProductId = 'com.wordisland.learnenglish.ios.pack.grammar';

class GrammarPackDetailScreen extends StatefulWidget {
  const GrammarPackDetailScreen({required this.pack, super.key});

  final GrammarPack pack;

  @override
  State<GrammarPackDetailScreen> createState() =>
      _GrammarPackDetailScreenState();
}

class _GrammarPackDetailScreenState extends State<GrammarPackDetailScreen> {
  late GrammarPack _visiblePack;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _visiblePack = widget.pack;
  }

  @override
  Widget build(BuildContext context) {
    // The detail route is normally rendered below the app's ProviderScope.
    // Keep the standalone widget usable as well (for previews/tests), while
    // still reacting to the profile once a Riverpod scope is available.
    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return _buildContent(context, ownsGrammarPack: true);
    }

    return Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(remoteUserProfileProvider).valueOrNull;
        // Splash loads the profile before entering the app. Treat an unknown
        // profile as pending; an explicitly loaded non-owner is locked.
        final ownsGrammarPack =
            profile == null ||
            profile.ownedProductIds.contains(grammarPackProductId);
        return _buildContent(context, ownsGrammarPack: ownsGrammarPack);
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool ownsGrammarPack}) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FAFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('grammar-pack-detail-screen'),
        backgroundColor: const Color(0xFFF7FAFF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _DetailBackdrop(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                key: const ValueKey('grammar-pack-detail-scroll'),
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                    sliver: SliverToBoxAdapter(
                      child: _DetailHeader(
                        pack: _visiblePack,
                        isEditing: _isEditing,
                        onEdit: () => setState(() => _isEditing = !_isEditing),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PackSummary(pack: _visiblePack),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 19, 20, 11),
                    sliver: SliverToBoxAdapter(
                      child: _LessonsHeading(count: _visiblePack.topics.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.separated(
                      itemCount: _visiblePack.topics.length,
                      itemBuilder: (context, index) => _LessonCard(
                        topic: _visiblePack.topics[index],
                        index: index,
                        level: _visiblePack.level,
                        isEditing: _isEditing,
                        isLocked: !ownsGrammarPack,
                        onTap: _isEditing
                            ? null
                            : ownsGrammarPack
                            ? () => _openExercise(_visiblePack.topics[index])
                            : _openGrammarPackPurchase,
                        onReset: () => _resetTopic(_visiblePack.topics[index]),
                      ),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 9),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExercise(GrammarTopic topic) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GrammarExerciseScreen(pack: _visiblePack, topic: topic),
      ),
    );
    if (!mounted) return;
    ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return;
    }
    final packs = await container.read(grammarRepositoryProvider).loadPacks();
    if (!mounted) return;
    final refreshed = packs
        .map(GrammarPack.fromContent)
        .where((item) => item.guid == widget.pack.guid);
    if (refreshed.isNotEmpty) setState(() => _visiblePack = refreshed.first);

    // Notify the catalog after the detail screen has already consumed the
    // latest SQLite snapshot. Both screens will therefore render the same
    // stored progress when this route is popped.
    container.invalidate(grammarTopicQuestionsProvider(topic.id));
    container.invalidate(grammarPacksProvider);
  }

  Future<void> _openGrammarPackPurchase() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const SkillPackPurchaseScreen(skill: SkillPackType.grammar),
      ),
    );
    if (!mounted) return;
    try {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(remoteUserProfileProvider);
    } on StateError {
      // Standalone previews do not have a Riverpod scope.
    }
  }

  Future<void> _resetTopic(GrammarTopic topic) async {
    if (topic.id <= 0 || topic.progress <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.restart_alt_rounded,
          color: Color(0xFFFF6B6B),
          size: 34,
        ),
        title: Text(context.l10n.text('grammarResetLessonTitle')),
        content: Text(
          context.l10n.text(
            'grammarResetLessonBody',
            values: {'topic': topic.label},
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('grammar-reset-topic-cancel-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('grammar-reset-topic-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.text('reset')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final container = ProviderScope.containerOf(context);
    await container.read(grammarProgressServiceProvider).resetTopic(topic.id);
    if (!mounted) return;
    container.invalidate(grammarTopicQuestionsProvider(topic.id));
    container.invalidate(grammarPacksProvider);
    final packs = await container.read(grammarRepositoryProvider).loadPacks();
    if (!mounted) return;
    final refreshed = packs
        .map(GrammarPack.fromContent)
        .where((pack) => pack.guid == widget.pack.guid);
    if (refreshed.isNotEmpty) {
      setState(() => _visiblePack = refreshed.first);
    }
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.pack,
    required this.isEditing,
    required this.onEdit,
  });

  final GrammarPack pack;
  final bool isEditing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderButton(
          key: const ValueKey('grammar-pack-back-button'),
          width: 48,
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryDark,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            pack.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          key: const ValueKey('grammar-pack-edit-button'),
          width: 74,
          onTap: onEdit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEditing ? Icons.check_rounded : Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                isEditing ? 'Done' : 'Edit',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.width,
    required this.onTap,
    required this.child,
    super.key,
  });

  final double width;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Colors.white),
    );
    return Material(
      color: Colors.white.withValues(alpha: .9),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: SizedBox(
          width: width,
          height: 46,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PackSummary extends StatelessWidget {
  const _PackSummary({required this.pack});

  final GrammarPack pack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(14, 16, 13, 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x162A70B8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 91,
            height: 91,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD5E9FF)),
            ),
            child: Image.asset(pack.iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grammar Practice',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pack.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 17,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Master essential grammar topics step by step.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryProgressRing(progress: pack.progress),
                const SizedBox(height: 7),
                const Text(
                  'Overall progress',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryProgressRing extends StatelessWidget {
  const _SummaryProgressRing({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 68,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CircularProgressIndicator(
            value: 1,
            strokeWidth: 8,
            color: Color(0xFFE8F0FC),
          ),
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            color: AppColors.primary,
          ),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$progress',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const TextSpan(text: '%', style: TextStyle(fontSize: 11)),
                ],
              ),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsHeading extends StatelessWidget {
  const _LessonsHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lessons',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count topics in this pack',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.topic,
    required this.index,
    required this.level,
    required this.isEditing,
    required this.isLocked,
    required this.onTap,
    required this.onReset,
  });

  final GrammarTopic topic;
  final int index;
  final String level;
  final bool isEditing;
  final bool isLocked;
  final VoidCallback? onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? .45 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: .91),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('grammar-topic-$index'),
          onTap: onTap,
          child: SizedBox(
            height: 83,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDCEBFF)),
                  ),
                  child: Center(
                    child: Container(
                      width: 29,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF53B6FF), Color(0xFF345BEF)],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x28345BEF),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.format_align_left_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${topic.progress}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const _LessonBadge(
                            label: 'Grammar',
                            color: AppColors.primary,
                            background: Color(0xFFEDF4FF),
                          ),
                          const SizedBox(width: 7),
                          _LessonBadge(
                            label: _difficulty.label,
                            color: _difficulty.color,
                            background: _difficulty.background,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(99),
                        ),
                        child: LinearProgressIndicator(
                          value: topic.progress / 100,
                          minHeight: 5,
                          backgroundColor: Color(0xFFEAF1FA),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isEditing && !isLocked)
                  IconButton(
                    key: ValueKey('grammar-reset-topic-$index'),
                    tooltip: context.l10n.text('grammarResetProgressTooltip'),
                    onPressed: topic.progress > 0 ? onReset : null,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEEEE),
                      disabledBackgroundColor: const Color(0xFFF3F6FB),
                    ),
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      color: topic.progress > 0
                          ? const Color(0xFFFF5F67)
                          : AppColors.textMuted,
                      size: 22,
                    ),
                  )
                else
                  Icon(
                    isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.chevron_right_rounded,
                    color: isLocked
                        ? AppColors.textMuted
                        : const Color(0xFF91ADD2),
                    size: isLocked ? 22 : 28,
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({String label, Color color, Color background}) get _difficulty =>
      switch (level) {
        'Intermediate' => (
          label: 'Medium',
          color: const Color(0xFFE77C10),
          background: const Color(0xFFFFF6E9),
        ),
        'Advanced' => (
          label: 'Hard',
          color: const Color(0xFFD83786),
          background: const Color(0xFFFFEEF6),
        ),
        _ => (
          label: 'Easy',
          color: const Color(0xFF0AA75B),
          background: const Color(0xFFEDFBF3),
        ),
      };
}

class _LessonBadge extends StatelessWidget {
  const _LessonBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailBackdrop extends StatelessWidget {
  const _DetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F7FF), Color(0xFFF9FCFF), Color(0xFFEDF7FF)],
          stops: [0, .5, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -95,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x553DD4FF), Color(0x003DD4FF)],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 96,
            left: 74,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 19),
          ),
        ],
      ),
    );
  }
}
