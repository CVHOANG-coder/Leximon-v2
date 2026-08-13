import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/just_audio_asset_path.dart';
import '../../../data/models/ipa_sound.dart';
import '../../../data/services/ipa_progress_service.dart';
import '../../../shared/providers/app_providers.dart';

class IpaSoundDetailScreen extends StatefulWidget {
  const IpaSoundDetailScreen({required this.sound, super.key});

  final IpaSound sound;

  @override
  State<IpaSoundDetailScreen> createState() => _IpaSoundDetailScreenState();
}

class _IpaSoundDetailScreenState extends State<IpaSoundDetailScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  YoutubePlayerController? _youtubeController;
  StreamSubscription<ProcessingState>? _audioSubscription;
  String? _playingAsset;
  IpaProgressService? _progressService;
  ProviderContainer? _providerContainer;
  Future<void>? _openProgressFuture;
  bool _didRecordOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final videoId = widget.sound.youtubeVideoId;
    if (videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        startSeconds: widget.sound.youtubeStartSeconds,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          playsInline: true,
          strictRelatedVideos: true,
        ),
      );
    }
    _audioSubscription = _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        setState(() => _playingAsset = null);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_youtubeController?.pauseVideo());
      unawaited(_audioPlayer.pause());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRecordOpen) return;
    _didRecordOpen = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      _providerContainer = container;
      _progressService = container.read(ipaProgressServiceProvider);
      _openProgressFuture = _progressService!.recordOpened(widget.sound.symbol);
      unawaited(_openProgressFuture);
    } on Object {
      // Standalone previews/tests can render without a ProviderScope.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audioSubscription?.cancel());
    unawaited(_audioPlayer.dispose());
    unawaited(_youtubeController?.close());
    super.dispose();
  }

  Future<void> _play(String asset) async {
    if (asset.isEmpty) return;
    if (_playingAsset == asset && _audioPlayer.playing) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingAsset = null);
      return;
    }

    if (mounted) setState(() => _playingAsset = asset);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(justAudioAssetPath(asset));
      await _audioPlayer.play();
      unawaited(_recordPractice());
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingAsset = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát âm thanh lúc này.')),
      );
    }
  }

  Future<void> _recordPractice() async {
    await _openProgressFuture;
    await _progressService?.recordPracticed(widget.sound.symbol);
    _providerContainer?.invalidate(challengeDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final sound = widget.sound;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FBFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('ipa-sound-detail-screen'),
        backgroundColor: const Color(0xFFF7FBFF),
        body: Stack(
          children: [
            const Positioned.fill(child: _DetailBackdrop()),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                key: const ValueKey('ipa-detail-scroll'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _DetailHeader(sound: sound)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ArticulationSection(
                        sound: sound,
                        isPlaying: _playingAsset == sound.audioAsset,
                        onPlay: () => _play(sound.audioAsset),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _VideoSection(controller: _youtubeController),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      28 + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _WordSection(
                          sectionKey: const ValueKey('ipa-spelling-section'),
                          title: 'Spelling',
                          iconAsset: 'assets/svgs/ipa/spell.svg',
                          decorationAsset: 'assets/images/ipa/spell_bottom.png',
                          accent: const Color(0xFF39B98A),
                          words: sound.spellingWords,
                          playingAsset: _playingAsset,
                          onPlay: _play,
                          showTranscription: true,
                        ),
                        const SizedBox(height: 14),
                        _WordSection(
                          sectionKey: const ValueKey('ipa-beginning-section'),
                          title: 'Beginning sound',
                          iconAsset: 'assets/svgs/ipa/begin_sound.svg',
                          decorationAsset:
                              'assets/images/ipa/beginning_sound_bottom.png',
                          accent: const Color(0xFFFFB629),
                          words: sound.beginningWords,
                          playingAsset: _playingAsset,
                          onPlay: _play,
                        ),
                        const SizedBox(height: 14),
                        _WordSection(
                          sectionKey: const ValueKey('ipa-middle-section'),
                          title: 'Middle sound',
                          iconAsset: 'assets/svgs/ipa/middle_sound.svg',
                          decorationAsset:
                              'assets/images/ipa/middle_sound_bottom.png',
                          accent: const Color(0xFF8569ED),
                          words: sound.middleWords,
                          playingAsset: _playingAsset,
                          onPlay: _play,
                        ),
                        const SizedBox(height: 14),
                        _WordSection(
                          sectionKey: const ValueKey('ipa-end-section'),
                          title: 'End sound',
                          iconAsset: 'assets/svgs/ipa/end_sound.svg',
                          decorationAsset:
                              'assets/images/ipa/end_sound_bottom.png',
                          accent: const Color(0xFFEF7899),
                          words: sound.endWords,
                          playingAsset: _playingAsset,
                          onPlay: _play,
                        ),
                      ],
                    ),
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.sound});

  final IpaSound sound;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 82,
    child: Row(
      children: [
        const SizedBox(width: 16),
        Material(
          color: Colors.white.withValues(alpha: .88),
          elevation: 0,
          shadowColor: const Color(0x33285B8E),
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('ipa-detail-back-button'),
            onTap: () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF237EDB),
                size: 27,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '${sound.name.trim()} [${sound.symbol}]',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 27,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    ),
  );
}

class _ArticulationSection extends StatelessWidget {
  const _ArticulationSection({
    required this.sound,
    required this.isPlaying,
    required this.onPlay,
  });

  final IpaSound sound;
  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AspectRatio(
        aspectRatio: 1.1,
        child: _MouthCard(
          photoAsset: sound.photoAsset,
          isPlaying: isPlaying,
          onPlay: onPlay,
        ),
      ),
      const SizedBox(height: 12),
      _SoundDescriptionCard(sound: sound),
    ],
  );
}

class _MouthCard extends StatelessWidget {
  const _MouthCard({
    required this.photoAsset,
    required this.isPlaying,
    required this.onPlay,
  });

  final String photoAsset;
  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('ipa-mouth-card'),
    constraints: const BoxConstraints(minHeight: 225),
    padding: const EdgeInsets.all(10),
    decoration: _cardDecoration(radius: 26),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: photoAsset.isEmpty
              ? const ColoredBox(
                  color: Color(0xFFFFF1F1),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: Color(0xFFF29A9A),
                    size: 58,
                  ),
                )
              : Image.asset(photoAsset, fit: BoxFit.contain),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: _RoundAudioButton(
            isPlaying: isPlaying,
            onPressed: onPlay,
            size: 54,
          ),
        ),
      ],
    ),
  );
}

class _SoundDescriptionCard extends StatelessWidget {
  const _SoundDescriptionCard({required this.sound});

  final IpaSound sound;

  @override
  Widget build(BuildContext context) {
    final description = sound.description.isNotEmpty
        ? sound.description
        : "The '${sound.name.trim()}' /${sound.symbol}/ is a ${sound.typeLabel}. "
              'Watch the mouth movement, listen, and repeat the sound slowly.';
    return Container(
      key: const ValueKey('ipa-description-card'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 225),
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 17),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 28,
                color: Color(0xFFFFC548),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sound.typeLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF43618D),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Example: ${sound.example}',
              style: const TextStyle(
                color: Color(0xFF267C72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.controller});

  final YoutubePlayerController? controller;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: _cardDecoration(radius: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(7, 5, 7, 11),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF268BE9),
                size: 24,
              ),
              SizedBox(width: 9),
              Text(
                'Pronunciation video',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: const Color(0xFFEAF3FC),
            child: controller == null
                ? const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: Text(
                        'Video is unavailable',
                        style: TextStyle(color: Color(0xFF63799B)),
                      ),
                    ),
                  )
                : YoutubePlayer(
                    key: const ValueKey('ipa-youtube-player'),
                    controller: controller!,
                    aspectRatio: 16 / 9,
                    backgroundColor: const Color(0xFFEAF3FC),
                    keepAlive: true,
                  ),
          ),
        ),
      ],
    ),
  );
}

class _WordSection extends StatelessWidget {
  const _WordSection({
    required this.sectionKey,
    required this.title,
    required this.iconAsset,
    required this.decorationAsset,
    required this.accent,
    required this.words,
    required this.playingAsset,
    required this.onPlay,
    this.showTranscription = false,
  });

  final Key sectionKey;
  final String title;
  final String iconAsset;
  final String decorationAsset;
  final Color accent;
  final List<IpaWord> words;
  final String? playingAsset;
  final ValueChanged<String> onPlay;
  final bool showTranscription;

  @override
  Widget build(BuildContext context) => Container(
    key: sectionKey,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: _cardDecoration(radius: 26),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Image.asset(
              decorationAsset,
              height: 112,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 55),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 29,
                    height: 29,
                    child: SvgPicture.asset(iconAsset),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: accent.withValues(alpha: .18), height: 1),
              if (words.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No examples available for this sound.',
                    style: TextStyle(color: Color(0xFF71819F)),
                  ),
                )
              else
                for (var index = 0; index < words.length; index++) ...[
                  _WordRow(
                    word: words[index],
                    isPlaying: playingAsset == words[index].audioAsset,
                    onPlay: () => onPlay(words[index].audioAsset),
                    showTranscription: showTranscription,
                  ),
                  if (index != words.length - 1)
                    Divider(color: accent.withValues(alpha: .15), height: 1),
                ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.word,
    required this.isPlaying,
    required this.onPlay,
    required this.showTranscription,
  });

  final IpaWord word;
  final bool isPlaying;
  final VoidCallback onPlay;
  final bool showTranscription;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            showTranscription && word.transcription.isNotEmpty
                ? '${word.name}  ${word.transcription}'
                : word.name,
            style: const TextStyle(
              color: Color(0xFF264475),
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundAudioButton(isPlaying: isPlaying, onPressed: onPlay, size: 38),
      ],
    ),
  );
}

class _RoundAudioButton extends StatelessWidget {
  const _RoundAudioButton({
    required this.isPlaying,
    required this.onPressed,
    required this.size,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
    color: isPlaying ? const Color(0xFF278DEB) : Colors.white,
    elevation: 3,
    shadowColor: const Color(0x33234E7C),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
          color: isPlaying ? Colors.white : const Color(0xFF278DEB),
          size: size * .48,
        ),
      ),
    ),
  );
}

BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
  color: Colors.white.withValues(alpha: .94),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white, width: 1.2),
  boxShadow: const [
    BoxShadow(color: Color(0x18275585), blurRadius: 22, offset: Offset(0, 9)),
  ],
);

class _DetailBackdrop extends StatelessWidget {
  const _DetailBackdrop();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bg_word_study.png',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  );
}
