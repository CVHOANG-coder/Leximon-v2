import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/just_audio_asset_path.dart';
import '../../../data/datasources/ipa_asset_data_source.dart';
import '../../../data/models/ipa_sound.dart';
import '../../../data/services/ipa_progress_service.dart';
import '../../../shared/providers/app_providers.dart';
import 'ipa_sound_detail_screen.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key, this.sounds});

  final List<IpaSound>? sounds;

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final AudioPlayer _player = AudioPlayer();
  late Future<List<IpaSound>> _soundsFuture;
  StreamSubscription<void>? _completionSubscription;
  String? _playingSymbol;
  IpaProgressService? _progressService;
  ProviderContainer? _providerContainer;
  Set<String> _viewedSymbols = const {};
  Set<String> _completedSymbols = const {};
  bool _didConnectProgress = false;

  @override
  void initState() {
    super.initState();
    _soundsFuture = _loadSounds();
    _completionSubscription = _player.processingStateStream
        .where((state) => state == ProcessingState.completed)
        .map((_) {})
        .listen((_) {
          if (mounted) setState(() => _playingSymbol = null);
        });
  }

  @override
  void dispose() {
    unawaited(_completionSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didConnectProgress) return;
    _didConnectProgress = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      _providerContainer = container;
      _progressService = container.read(ipaProgressServiceProvider);
      unawaited(_refreshProgress());
    } on Object {
      // Standalone previews/tests can render without a ProviderScope.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FBFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('pronunciation-screen'),
        backgroundColor: const Color(0xFFF7FBFF),
        body: Stack(
          children: [
            const Positioned.fill(child: _SoundsBackdrop()),
            FutureBuilder<List<IpaSound>>(
              future: _soundsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    onRetry: () =>
                        setState(() => _soundsFuture = _loadSounds()),
                  );
                }

                final sounds = snapshot.data ?? const <IpaSound>[];
                return CustomScrollView(
                  key: const ValueKey('pronunciation-scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: _SoundsHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      sliver: SliverToBoxAdapter(
                        child: _SoundSection(
                          title: 'Vowel Sounds',
                          icon: Icons.volume_up_rounded,
                          accent: const Color(0xFF1673F9),
                          soft: const Color(0xFFDCEEFF),
                          sparkle: const Color(0xFF75B2FF),
                          columns: 4,
                          childAspectRatio: 1.2,
                          sounds: _ofGroup(sounds, IpaSoundGroup.vowel),
                          viewedSymbols: _viewedSymbols,
                          completedSymbols: _completedSymbols,
                          playingSymbol: _playingSymbol,
                          onSoundTap: _play,
                          onSoundOpen: _openDetail,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      sliver: SliverToBoxAdapter(
                        child: _SoundSection(
                          title: 'R-controlled vowels',
                          icon: Icons.volume_up_rounded,
                          accent: const Color(0xFFEF7800),
                          soft: const Color(0xFFFFECD0),
                          sparkle: const Color(0xFFFFC76F),
                          columns: 4,
                          childAspectRatio: 1.42,
                          sounds: _ofGroup(
                            sounds,
                            IpaSoundGroup.rControlledVowel,
                          ),
                          viewedSymbols: _viewedSymbols,
                          completedSymbols: _completedSymbols,
                          playingSymbol: _playingSymbol,
                          onSoundTap: _play,
                          onSoundOpen: _openDetail,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _SoundSection(
                          title: 'Consonant Sounds',
                          icon: Icons.volume_up_rounded,
                          accent: const Color(0xFF08A954),
                          soft: const Color(0xFFDDF8E5),
                          sparkle: const Color(0xFF7FDEAC),
                          columns: 4,
                          childAspectRatio: 1.15,
                          compact: true,
                          sounds: _ofGroup(sounds, IpaSoundGroup.consonant),
                          viewedSymbols: _viewedSymbols,
                          completedSymbols: _completedSymbols,
                          playingSymbol: _playingSymbol,
                          onSoundTap: _play,
                          onSoundOpen: _openDetail,
                        ),
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

  List<IpaSound> _ofGroup(List<IpaSound> sounds, IpaSoundGroup group) =>
      sounds.where((sound) => sound.group == group).toList(growable: false);

  Future<List<IpaSound>> _loadSounds() => widget.sounds == null
      ? IpaAssetDataSource.load()
      : Future.value(widget.sounds);

  Future<void> _play(IpaSound sound) async {
    setState(() => _playingSymbol = sound.symbol);
    try {
      await _player.stop();
      await _player.setAsset(justAudioAssetPath(sound.audioAsset));
      await _player.play();
      await _progressService?.recordPracticed(sound.symbol);
      await _refreshProgress();
      _providerContainer?.invalidate(challengeDashboardProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingSymbol = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('audioPlaybackError'))),
      );
    }
  }

  Future<void> _openDetail(IpaSound sound) async {
    await _player.stop();
    if (mounted) setState(() => _playingSymbol = null);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => IpaSoundDetailScreen(sound: sound)),
    );
    await _progressService?.recordOpened(sound.symbol);
    await _refreshProgress();
    _providerContainer?.invalidate(challengeDashboardProvider);
  }

  Future<void> _refreshProgress() async {
    final service = _progressService;
    if (service == null) return;
    final progress = await service.loadAll();
    if (!mounted) return;
    setState(() {
      _viewedSymbols = progress.keys.toSet();
      _completedSymbols = {
        for (final entry in progress.entries)
          if (entry.value.completedAt != null) entry.key,
      };
    });
  }
}

class _SoundsHeader extends StatelessWidget {
  const _SoundsHeader();

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: safeTop + 98,
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 9,
            left: 14,
            child: _HeaderButton(onTap: () => Navigator.of(context).maybePop()),
          ),
          Positioned(
            top: safeTop + 7,
            left: 64,
            right: 18,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCFE8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFF176EE8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sounds',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 31,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        context.l10n.text('pronunciationGroupTitle'),
                        style: TextStyle(
                          color: Color(0xFF435D91),
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 10,
            right: 116,
            child: _Sparkle(color: Colors.white, size: 16),
          ),
          const Positioned(
            top: 48,
            right: 38,
            child: _Sparkle(color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .76),
    shape: const CircleBorder(),
    child: InkWell(
      key: const ValueKey('pronunciation-back-button'),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_rounded,
          color: AppColors.primaryDark,
          size: 21,
        ),
      ),
    ),
  );
}

class _SoundSection extends StatelessWidget {
  const _SoundSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.soft,
    required this.sparkle,
    required this.columns,
    required this.childAspectRatio,
    required this.sounds,
    required this.viewedSymbols,
    required this.completedSymbols,
    required this.playingSymbol,
    required this.onSoundTap,
    required this.onSoundOpen,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color soft;
  final Color sparkle;
  final int columns;
  final double childAspectRatio;
  final List<IpaSound> sounds;
  final Set<String> viewedSymbols;
  final Set<String> completedSymbols;
  final String? playingSymbol;
  final ValueChanged<IpaSound> onSoundTap;
  final ValueChanged<IpaSound> onSoundOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .94)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14235C93),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
                    decoration: BoxDecoration(
                      color: soft.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            color: soft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 14, color: accent),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          title,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _Sparkle(color: sparkle, size: 14),
              const SizedBox(width: 5),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns.clamp(1, 4),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return _SoundTile(
                key: ValueKey('ipa-sound-${sound.symbol}'),
                sound: sound,
                accent: accent,
                soft: soft,
                compact: compact,
                viewed: viewedSymbols.contains(sound.symbol),
                completed: completedSymbols.contains(sound.symbol),
                playing: playingSymbol == sound.symbol,
                onTap: () => onSoundTap(sound),
                onOpen: () => onSoundOpen(sound),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.sound,
    required this.accent,
    required this.soft,
    required this.compact,
    required this.viewed,
    required this.completed,
    required this.playing,
    required this.onTap,
    required this.onOpen,
    super.key,
  });

  final IpaSound sound;
  final Color accent;
  final Color soft;
  final bool compact;
  final bool viewed;
  final bool completed;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(compact ? 13 : 15),
      side: BorderSide(
        color: accent.withValues(
          alpha: completed
              ? .30
              : viewed
              ? .16
              : .06,
        ),
      ),
    );
    final tile = Material(
      color: playing
          ? soft.withValues(alpha: .68)
          : completed
          ? soft.withValues(alpha: .38)
          : viewed
          ? soft.withValues(alpha: .16)
          : Colors.white,
      elevation: 0,
      shadowColor: const Color(0x24255D8D),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        onLongPress: onTap,
        customBorder: shape,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 2 : 4, 8, compact ? 2 : 4, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = compact ? 3.0 : 4.0;
              final defaultCircleSize = compact ? 27.0 : 32.0;
              final labelSpace = compact ? 8.0 : 10.0;
              // Keep a small fractional-pixel safety margin. Grid cell heights
              // are often non-integral on real devices (for example 35.66px).
              final circleSize = (constraints.maxHeight - gap - labelSpace - 1)
                  .clamp(0.0, defaultCircleSize);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: playing || completed ? accent : soft,
                      shape: BoxShape.circle,
                      boxShadow: playing
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: .25),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          sound.symbol,
                          maxLines: 1,
                          style: TextStyle(
                            color: playing || completed ? Colors.white : accent,
                            fontSize: compact ? 15 : 18,
                            height: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          sound.example,
                          maxLines: 1,
                          style: TextStyle(
                            color: const Color(0xFF334E83),
                            fontSize: compact ? 9 : 11,
                            height: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    return Semantics(
      label: completed
          ? context.l10n.text(
              'pronunciationCompletedSemantics',
              values: {'symbol': sound.symbol},
            )
          : viewed
          ? context.l10n.text(
              'pronunciationViewedSemantics',
              values: {'symbol': sound.symbol},
            )
          : sound.symbol,
      button: true,
      child: Stack(
        children: [
          Positioned.fill(child: tile),
          if (viewed)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                key: ValueKey(
                  completed
                      ? 'ipa-sound-completed-${sound.symbol}'
                      : 'ipa-sound-viewed-${sound.symbol}',
                ),
                width: compact ? 15 : 17,
                height: compact ? 15 : 17,
                decoration: BoxDecoration(
                  color: completed ? const Color(0xFF19B96E) : accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F0B315E), blurRadius: 4),
                  ],
                ),
                child: Icon(
                  completed ? Icons.check_rounded : Icons.visibility_rounded,
                  color: Colors.white,
                  size: compact ? 9 : 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.auto_awesome_rounded, color: color, size: size);
}

class _SoundsBackdrop extends StatelessWidget {
  const _SoundsBackdrop();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bg_word_study.png',
    key: const ValueKey('pronunciation-background'),
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.volume_off_rounded,
              color: AppColors.textMuted,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.text('pronunciationLoadError'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    ),
  );
}
