import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/grammar_asset_data_source.dart';
import '../../../data/models/grammar_content.dart';
import '../../../shared/providers/app_providers.dart';
import 'grammar_pack_detail_screen.dart';

class GrammarPracticeScreen extends ConsumerStatefulWidget {
  const GrammarPracticeScreen({this.packs, super.key});

  final List<GrammarPack>? packs;

  @override
  ConsumerState<GrammarPracticeScreen> createState() =>
      _GrammarPracticeScreenState();
}

class _GrammarPracticeScreenState extends ConsumerState<GrammarPracticeScreen> {
  late Future<List<GrammarPack>> _packsFuture;
  final Set<String> _collapsedLevels = <String>{};
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _packsFuture = widget.packs == null
        ? _loadLocalPacks()
        : SynchronousFuture(widget.packs!);
  }

  Future<List<GrammarPack>> _loadLocalPacks() async {
    final packs = await ref.read(grammarPacksProvider.future);
    return packs.map(GrammarPack.fromContent).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FAFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _GrammarBackdrop(),
            SafeArea(
              bottom: false,
              child: FutureBuilder<List<GrammarPack>>(
                future: _packsFuture,
                builder: (context, snapshot) {
                  return CustomScrollView(
                    key: const ValueKey('grammar-practice-scroll'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        sliver: SliverToBoxAdapter(
                          child: _GrammarHeader(
                            onBack: () => Navigator.of(context).pop(),
                            isEditing: _isEditing,
                            onEdit: () =>
                                setState(() => _isEditing = !_isEditing),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                        sliver: SliverToBoxAdapter(
                          child: _GrammarHero(
                            progress: _averageProgress(
                              snapshot.data ?? const [],
                            ),
                          ),
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _LoadError(message: snapshot.error.toString()),
                        )
                      else
                        ..._buildLevelSlivers(snapshot.data ?? const []),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _averageProgress(List<GrammarPack> packs) {
    if (packs.isEmpty) return 0;
    return (packs.fold<int>(0, (sum, pack) => sum + pack.progress) /
            packs.length)
        .ceil();
  }

  List<Widget> _buildLevelSlivers(List<GrammarPack> packs) {
    final grouped = <String, List<GrammarPack>>{};
    for (final level in GrammarLevelStyle.levelOrder) {
      grouped[level] = packs.where((pack) => pack.level == level).toList();
    }

    return [
      for (final level in GrammarLevelStyle.levelOrder)
        if (grouped[level]!.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _GrammarLevelSection(
                level: level,
                packs: grouped[level]!,
                collapsed: _collapsedLevels.contains(level),
                isEditing: _isEditing,
                onPackReturned: _refreshPacks,
                onResetPack: _resetPack,
                onToggle: () => setState(() {
                  if (!_collapsedLevels.add(level)) {
                    _collapsedLevels.remove(level);
                  }
                }),
              ),
            ),
          ),
    ];
  }

  void _refreshPacks() {
    if (widget.packs != null || !mounted) return;
    _reloadPacksFromDatabase();
  }

  Future<void> _reloadPacksFromDatabase() async {
    final contents = await ref.read(grammarRepositoryProvider).loadPacks();
    if (!mounted) return;
    final packs = contents.map(GrammarPack.fromContent).toList(growable: false);
    ref.invalidate(grammarPacksProvider);
    setState(() {
      _packsFuture = SynchronousFuture(packs);
    });
  }

  Future<void> _resetPack(GrammarPack pack) async {
    if (pack.id <= 0 || pack.progress <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.restart_alt_rounded,
          color: Color(0xFFFF6B6B),
          size: 34,
        ),
        title: Text(context.l10n.text('grammarResetPackTitle')),
        content: Text(
          context.l10n.text(
            'grammarResetPackBody',
            values: {'pack': pack.title},
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('grammar-reset-cancel-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('grammar-reset-confirm-button'),
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
    await ref.read(grammarProgressServiceProvider).resetPack(pack.id);
    if (!mounted) return;
    for (final topic in pack.topics) {
      ref.invalidate(grammarTopicQuestionsProvider(topic.id));
    }
    await _reloadPacksFromDatabase();
  }
}

class _GrammarHeader extends StatelessWidget {
  const _GrammarHeader({
    required this.onBack,
    required this.isEditing,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final bool isEditing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassButton(
          key: const ValueKey('grammar-back-button'),
          width: 48,
          onTap: onBack,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GRAMMAR PRACTICE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: 5),
              Text(
                context.l10n.text('grammarTitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _GlassButton(
          key: const ValueKey('grammar-edit-button'),
          width: 100,
          onTap: onEdit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEditing ? Icons.check_rounded : Icons.tune_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isEditing
                      ? context.l10n.text('done')
                      : context.l10n.text('edit'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
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
      side: BorderSide(color: Colors.white.withValues(alpha: .95)),
    );
    return Material(
      color: Colors.white.withValues(alpha: .88),
      shape: shape,
      elevation: 0,
      shadowColor: const Color(0x262A70B8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: SizedBox(
          width: width,
          height: 40,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GrammarHero extends StatelessWidget {
  const _GrammarHero({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/bg_word_study.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1D2A70B8),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final owlWidth = constraints.maxWidth * .34;
            const contentRight = 88.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 2,
                  bottom: -1,
                  width: owlWidth,
                  height: constraints.maxHeight * .96,
                  child: Image.asset(
                    'assets/images/grammar/owl_grammar.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .37,
                  top: 17,
                  right: contentRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key: ValueKey('grammar-hero-title'),
                        context.l10n.text('grammarByLevelTitle'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.25,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        key: ValueKey('grammar-hero-subtitle'),
                        context.l10n.text('grammarMotivation'),
                        maxLines: 2,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 13,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ProgressRing(
                      key: const ValueKey('grammar-hero-ring'),
                      progress: progress / 100,
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .37,
                  right: contentRight,
                  bottom: 12,
                  child: Container(
                    key: const ValueKey('grammar-hero-progress'),
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            context.l10n.text('overallProgress'),
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 65,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 7,
            color: Colors.white.withValues(alpha: .88),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            color: AppColors.primary,
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarLevelSection extends StatelessWidget {
  const _GrammarLevelSection({
    required this.level,
    required this.packs,
    required this.collapsed,
    required this.isEditing,
    required this.onToggle,
    required this.onPackReturned,
    required this.onResetPack,
  });

  final String level;
  final List<GrammarPack> packs;
  final bool collapsed;
  final bool isEditing;
  final VoidCallback onToggle;
  final VoidCallback onPackReturned;
  final ValueChanged<GrammarPack> onResetPack;

  @override
  Widget build(BuildContext context) {
    final style = GrammarLevelStyle.forLevel(level);
    final levelProgress = packs.isEmpty
        ? 0
        : (packs.fold<int>(0, (sum, pack) => sum + pack.progress) /
                  packs.length)
              .ceil();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x112A70B8),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            key: ValueKey('grammar-level-$level'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 1, 2, 8),
              child: Row(
                children: [
                  Container(
                    width: 116,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          style.color.withValues(alpha: .16),
                          style.color.withValues(alpha: .05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            level.toUpperCase(),
                            style: TextStyle(
                              color: style.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${packs.length} packs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 88,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        context.l10n.text(
                          'percentComplete',
                          values: {'percent': levelProgress},
                        ),
                        style: TextStyle(
                          color: style.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  AnimatedRotation(
                    turns: collapsed ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: style.color,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 230),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: collapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              children: [
                for (var index = 0; index < packs.length; index++) ...[
                  if (index > 0) const SizedBox(height: 4),
                  _GrammarPackTile(
                    pack: packs[index],
                    style: style,
                    isEditing: isEditing,
                    onReturn: onPackReturned,
                    onReset: () => onResetPack(packs[index]),
                  ),
                ],
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _GrammarPackTile extends StatelessWidget {
  const _GrammarPackTile({
    required this.pack,
    required this.style,
    required this.isEditing,
    required this.onReturn,
    required this.onReset,
  });

  final GrammarPack pack;
  final GrammarLevelStyle style;
  final bool isEditing;
  final VoidCallback onReturn;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.text(
        'grammarPackSemantics',
        values: {'title': pack.title, 'count': pack.lessonCount},
      ),
      child: Material(
        color: Colors.white.withValues(alpha: .9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFFE7EFFA)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('grammar-pack-${pack.guid}'),
          onTap: isEditing
              ? null
              : () async {
                  var selectedPack = pack;
                  if (selectedPack.topics.isEmpty) {
                    final reloadedPacks = await GrammarPackCatalog.load();
                    selectedPack = reloadedPacks.firstWhere(
                      (item) => item.guid == pack.guid,
                      orElse: () => pack,
                    );
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          GrammarPackDetailScreen(pack: selectedPack),
                    ),
                  );
                  onReturn();
                },
          child: SizedBox(
            height: 61,
            child: Row(
              children: [
                const SizedBox(width: 9),
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Image.asset(pack.iconAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.text(
                          'lessonCount',
                          values: {'count': pack.lessonCount},
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pack.progress / 100,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFEAF1FA),
                          color: style.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Container(
                  width: 45,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${pack.progress}%',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                if (isEditing)
                  IconButton(
                    key: ValueKey('grammar-reset-pack-${pack.guid}'),
                    tooltip: context.l10n.text('grammarResetProgressTooltip'),
                    onPressed: pack.progress > 0 ? onReset : null,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEEEE),
                      disabledBackgroundColor: const Color(0xFFF3F6FB),
                    ),
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      color: pack.progress > 0
                          ? const Color(0xFFFF5F67)
                          : AppColors.textMuted,
                      size: 21,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                const SizedBox(width: 7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.orange),
          const SizedBox(height: 10),
          Text(
            context.l10n.text('grammarLoadError'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _GrammarBackdrop extends StatelessWidget {
  const _GrammarBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F6FF), Color(0xFFF8FBFF), Color(0xFFEEF7FF)],
          stops: [0, .48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -75,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x553BD0FF), Color(0x003BD0FF)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 210,
            left: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GrammarPack {
  const GrammarPack({
    this.id = 0,
    required this.guid,
    required this.level,
    required this.title,
    required this.lessonCount,
    required this.iconAsset,
    this.progress = 0,
    this.topicData,
  });

  final int id;
  final String guid;
  final String level;
  final String title;
  final int lessonCount;
  final String iconAsset;
  final int progress;
  final List<GrammarTopic>? topicData;

  // Nullable storage keeps objects created before a hot reload compatible
  // after the topics field is introduced. Missing data is rehydrated on tap.
  List<GrammarTopic> get topics => topicData ?? const <GrammarTopic>[];

  factory GrammarPack.fromContent(GrammarPackContent pack) {
    return GrammarPack(
      id: pack.id,
      guid: pack.guid,
      level: pack.level,
      title: pack.title,
      lessonCount: pack.lessonCount,
      iconAsset: pack.iconAsset,
      progress: pack.progress,
      topicData: pack.topics
          .map(GrammarTopic.fromContent)
          .toList(growable: false),
    );
  }

  factory GrammarPack.fromAsset(GrammarAssetPack pack) {
    return GrammarPack(
      guid: pack.guid,
      level: pack.level,
      title: pack.title,
      lessonCount: pack.topics.length,
      iconAsset: pack.iconAsset,
      topicData: pack.topics
          .map(
            (topic) => GrammarTopic(
              label: topic.title,
              questionCount: topic.questions.length,
            ),
          )
          .toList(growable: false),
    );
  }
}

class GrammarTopic {
  const GrammarTopic({
    this.id = 0,
    required this.label,
    required this.questionCount,
    this.progress = 0,
    this.isComplete = false,
  });

  final int id;
  final String label;
  final int questionCount;
  final int progress;
  final bool isComplete;

  factory GrammarTopic.fromContent(GrammarTopicContent topic) {
    return GrammarTopic(
      id: topic.id,
      label: topic.label,
      questionCount: topic.questionCount,
      progress: topic.progress,
      isComplete: topic.isComplete,
    );
  }
}

abstract final class GrammarPackCatalog {
  static Future<List<GrammarPack>> load({AssetBundle? bundle}) async {
    final packs = await GrammarAssetDataSource(bundle: bundle).loadAll();
    return packs.map(GrammarPack.fromAsset).toList(growable: false);
  }
}

class GrammarLevelStyle {
  const GrammarLevelStyle({required this.color, required this.icon});

  static const levelOrder = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Advanced',
  ];

  final Color color;
  final IconData icon;

  static GrammarLevelStyle forLevel(String level) => switch (level) {
    'Beginner' => const GrammarLevelStyle(
      color: AppColors.green,
      icon: Icons.eco_rounded,
    ),
    'Elementary' => const GrammarLevelStyle(
      color: Color(0xFFF49A14),
      icon: Icons.star_rounded,
    ),
    'Intermediate' => const GrammarLevelStyle(
      color: AppColors.purple,
      icon: Icons.stacked_bar_chart_rounded,
    ),
    'Advanced' => const GrammarLevelStyle(
      color: Color(0xFFE63198),
      icon: Icons.workspace_premium_rounded,
    ),
    _ => const GrammarLevelStyle(
      color: AppColors.primary,
      icon: Icons.school_rounded,
    ),
  };
}
