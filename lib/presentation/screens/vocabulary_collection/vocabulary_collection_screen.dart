import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/practice_exercise.dart';
import '../../../data/models/vocabulary_collection.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/services/learning_progress_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../difficult_words_training/difficult_words_result_screen.dart';
import '../repetition_practice/repetition_practice_screen.dart';
import '../review_practice/review_practice_screen.dart';

class VocabularyCollectionScreen extends ConsumerStatefulWidget {
  const VocabularyCollectionScreen({required this.status, super.key});

  final VocabularyCollectionStatus status;

  @override
  ConsumerState<VocabularyCollectionScreen> createState() =>
      _VocabularyCollectionScreenState();
}

class _VocabularyCollectionScreenState
    extends ConsumerState<VocabularyCollectionScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(vocabularyCollectionProvider).valueOrNull;
    final allEntries = snapshot?.entriesFor(widget.status) ?? const [];
    final entries = allEntries.where(_matchesSearch).toList(growable: false);
    final totalWords = snapshot?.totalWordCount ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      body: Stack(
        children: [
          const Positioned.fill(child: _CollectionBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _CollectionTopBar(
                    title: _statusTitle(widget.status),
                    kicker:
                        widget.status ==
                            VocabularyCollectionStatus.needsPractice
                        ? 'DIFFICULT WORDS'
                        : 'VOCABULARY COLLECTION',
                    searchOpen: _searchOpen,
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: () => _searchOpen
                        ? _closeSearch()
                        : setState(() => _searchOpen = true),
                  ),
                ),
                Expanded(
                  child: snapshot == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _CollectionBody(
                          status: widget.status,
                          entries: entries,
                          totalWords: totalWords,
                          searchOpen: _searchOpen,
                          controller: _searchController,
                          onSearchChanged: (value) => setState(
                            () => _search = value.trim().toLowerCase(),
                          ),
                          onOpenSearch: () =>
                              setState(() => _searchOpen = true),
                          onCloseSearch: _closeSearch,
                          onWordTap: (entry) => _showWordDetails(entry),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _CollectionCta(
                    label:
                        widget.status ==
                            VocabularyCollectionStatus.needsPractice
                        ? 'Luyện từ'
                        : 'Ôn luyện',
                    onPressed: allEntries.isEmpty ? null : _startReview,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(VocabularyCollectionEntry entry) {
    if (_search.isEmpty) return true;
    return entry.word.writing.toLowerCase().contains(_search) ||
        entry.word.translation.toLowerCase().contains(_search);
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _search = '';
      _searchOpen = false;
    });
  }

  Future<void> _showWordDetails(VocabularyCollectionEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordDetailSheet(entry: entry),
    );
  }

  Future<void> _startReview() async {
    final snapshot = ref.read(vocabularyCollectionProvider).valueOrNull;
    final collectionEntries = snapshot?.entriesFor(widget.status) ?? const [];
    if (collectionEntries.isEmpty || !mounted) return;

    if (widget.status == VocabularyCollectionStatus.needsPractice) {
      await _startDifficultWordsTraining();
      return;
    }

    if (widget.status == VocabularyCollectionStatus.mastered ||
        widget.status == VocabularyCollectionStatus.reviewing) {
      final database = ref.read(appDatabaseProvider);
      final enabledWords = await database.enabledWords();
      if (!mounted) return;

      final words = collectionEntries
          .map(_toExerciseWord)
          .toList(growable: false);
      final distractorWords = enabledWords
          .map(_databaseWordToExerciseWord)
          .toList(growable: false);
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => RepetitionPracticeScreen(
            title: widget.status == VocabularyCollectionStatus.mastered
                ? 'Ôn từ đã biết'
                : 'Ôn từ đang học',
            words: words,
            distractorWords: distractorWords,
            database: database,
          ),
        ),
      );
      if (mounted) {
        ref.invalidate(vocabularyCollectionProvider);
        ref.invalidate(topicProgressProvider);
        ref.invalidate(dailyCardProvider);
        ref.invalidate(progressDashboardProvider);
      }
      return;
    }
  }

  Future<void> _startDifficultWordsTraining() async {
    var healedWordCount = 0;
    var trainedWordCount = 0;

    while (mounted) {
      final service = ref.read(difficultWordsTrainingServiceProvider);
      final batch = await service.prepareBatch();
      if (!mounted) return;
      if (batch.isEmpty) {
        _refreshProgress();
        Navigator.of(context).pop();
        return;
      }

      SessionCompletionResult? completion;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReviewPracticeScreen(
            title: 'Các từ khó',
            kicker: 'DIFFICULT WORDS',
            words: batch.words
                .map(_databaseWordToExerciseMap)
                .toList(growable: false),
            distractorWords: batch.distractorWords
                .map(_databaseWordToExerciseMap)
                .toList(growable: false),
            dailyTaskType: DailyTaskType.difficult,
            similarWordIds: batch.similarWordIds,
            exerciseMasksByWordId: batch.exerciseMasksByWordId,
            database: ref.read(appDatabaseProvider),
            onSessionCompleted: (result) => completion = result,
          ),
        ),
      );
      if (!mounted) return;
      if (completed != true || completion == null) {
        _refreshProgress();
        return;
      }

      healedWordCount += completion!.successfulWordCount;
      trainedWordCount += completion!.completedWordCount;
      final nextBatch = await service.prepareBatch();
      if (!mounted) return;
      _refreshProgress();

      final action = await Navigator.of(context)
          .push<DifficultWordsResultAction>(
            MaterialPageRoute<DifficultWordsResultAction>(
              builder: (_) => DifficultWordsResultScreen(
                healedWordCount: healedWordCount,
                trainedWordCount: trainedWordCount,
                remainingWordCount: nextBatch.remainingWordCount,
              ),
            ),
          );
      if (!mounted) return;
      if (action != DifficultWordsResultAction.continueTraining) {
        _refreshProgress();
        if (nextBatch.isEmpty) Navigator.of(context).pop();
        return;
      }
    }
  }

  void _refreshProgress() {
    ref.invalidate(vocabularyCollectionProvider);
    ref.invalidate(topicProgressProvider);
    ref.invalidate(dailyCardProvider);
    ref.invalidate(wordProgressProvider);
    ref.invalidate(progressDashboardProvider);
  }

  ExerciseWord _toExerciseWord(VocabularyCollectionEntry entry) {
    return ExerciseWord(
      id: entry.word.id,
      topicId: entry.word.topicId,
      writing: entry.word.writing,
      translation: entry.word.translation,
      transliteration:
          entry.word.transliteration ?? entry.word.transcription ?? '',
    );
  }

  ExerciseWord _databaseWordToExerciseWord(WordRow word) {
    return ExerciseWord(
      id: word.id,
      topicId: word.topicId,
      writing: word.writing,
      translation: word.translation,
      transliteration: word.transliteration ?? word.transcription ?? '',
    );
  }

  Map<String, dynamic> _databaseWordToExerciseMap(WordRow word) {
    return {
      'id': word.id,
      'topicId': word.topicId,
      'writing': word.writing,
      'translation': word.translation,
      'transliteration': word.transliteration ?? word.transcription ?? '',
    };
  }
}

class _CollectionBackdrop extends StatelessWidget {
  const _CollectionBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFCDEBFF),
                Color(0xFFE6F5FF),
                Color(0xFFF7FCFF),
                Color(0xFFEAF7FF),
              ],
              stops: [0, .28, .62, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -50,
          left: -65,
          child: _BackdropOrb(
            size: 180,
            color: Colors.white.withValues(alpha: .72),
          ),
        ),
        Positioned(
          top: 180,
          right: -90,
          child: _BackdropOrb(
            size: 230,
            color: Colors.white.withValues(alpha: .58),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -90,
          child: _BackdropOrb(
            size: 220,
            color: Colors.white.withValues(alpha: .7),
          ),
        ),
        Positioned(top: 110, right: 70, child: _Spark(size: 8)),
        Positioned(top: 205, left: 80, child: _Spark(size: 6)),
        const Positioned(
          left: -12,
          bottom: 230,
          child: Icon(Icons.spa_rounded, color: Color(0x6646CBEA), size: 92),
        ),
        const Positioned(
          right: -14,
          bottom: 120,
          child: Icon(Icons.spa_rounded, color: Color(0x5546CBEA), size: 108),
        ),
      ],
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .5),
        boxShadow: const [BoxShadow(color: Colors.white, blurRadius: 9)],
      ),
    );
  }
}

class _CollectionTopBar extends StatelessWidget {
  const _CollectionTopBar({
    required this.title,
    required this.kicker,
    required this.searchOpen,
    required this.onBack,
    required this.onSearch,
  });

  final String title;
  final String kicker;
  final bool searchOpen;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GlassIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GlassIconButton(
            icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
            onTap: onSearch,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white.withValues(alpha: .78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 1.2),
        ),
        elevation: 0,
        shadowColor: const Color(0x263D8DD6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),
        ),
      ),
    );
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({
    required this.status,
    required this.entries,
    required this.totalWords,
    required this.searchOpen,
    required this.controller,
    required this.onSearchChanged,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onWordTap,
  });

  final VocabularyCollectionStatus status;
  final List<VocabularyCollectionEntry> entries;
  final int totalWords;
  final bool searchOpen;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<VocabularyCollectionEntry> onWordTap;

  @override
  Widget build(BuildContext context) {
    final progress = totalWords == 0 ? 0.0 : entries.length / totalWords;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      children: [
        _CollectionSummary(
          status: status,
          count: entries.length,
          totalWords: totalWords,
          progress: progress,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24072762),
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              _SearchShell(
                open: searchOpen,
                controller: controller,
                onChanged: onSearchChanged,
                onOpen: onOpenSearch,
                onClose: onCloseSearch,
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                const _EmptyCollection()
              else
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WordItem(entry: entry, onTap: onWordTap),
                  ),
                ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 2),
                const Text(
                  'Chạm vào từng từ để xem thông tin chi tiết và nghe phát âm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({
    required this.status,
    required this.count,
    required this.totalWords,
    required this.progress,
  });

  final VocabularyCollectionStatus status;
  final int count;
  final int totalWords;
  final double progress;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x243B9DE8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BỘ TỪ ĐANG HỌC',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Thư viện Leximon',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: accent,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusUnit(status),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2EEFC),
              valueColor: const AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusDescription(status),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              Text(
                '$count / $totalWords',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchShell extends StatelessWidget {
  const _SearchShell({
    required this.open,
    required this.controller,
    required this.onChanged,
    required this.onOpen,
    required this.onClose,
  });

  final bool open;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: open ? null : onOpen,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: open ? Colors.white : const Color(0xFFF3F8FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: open ? const Color(0x3355A8EF) : const Color(0x0F0E3F91),
          ),
          boxShadow: open
              ? const [
                  BoxShadow(
                    color: Color(0x1C37A2FF),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF8AA7D0),
              size: 21,
            ),
            const SizedBox(width: 12),
            if (open)
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tìm từ trong danh sách',
                    hintStyle: TextStyle(
                      color: Color(0xFFA6B5C8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              )
            else
              const Expanded(
                child: Text(
                  'Tìm từ trong danh sách',
                  style: TextStyle(color: Color(0xFF7D90AC), fontSize: 14),
                ),
              ),
            if (open)
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF8AA7D0),
                  size: 20,
                ),
                splashRadius: 18,
                tooltip: 'Đóng tìm kiếm',
              ),
          ],
        ),
      ),
    );
  }
}

class _WordItem extends StatelessWidget {
  const _WordItem({required this.entry, required this.onTap});

  final VocabularyCollectionEntry entry;
  final ValueChanged<VocabularyCollectionEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FBFF),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => onTap(entry),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Material(
                color: const Color(0xFFEEF6FF),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () =>
                      TextToSpeechService.instance.speak(entry.word.writing),
                  borderRadius: BorderRadius.circular(18),
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF3CA0FF),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.word.writing,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.word.translation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AB0CD),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDEBFC), width: 1.2),
      ),
      child: Column(
        children: [
          Image(
            image: AssetImage(
              'assets/images/empty_word_vocabulary_collection.png',
            ),
            width: 250,
            height: 150,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 10),
          Text(
            'Chưa có từ nào trong nhóm này',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Các từ thuộc nhóm này sẽ xuất hiện\nsau khi bạn học và ôn tập.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCta extends StatelessWidget {
  const _CollectionCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: onPressed == null
                ? const LinearGradient(
                    colors: [Color(0xFFDCE7F5), Color(0xFFEAF0F8)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1658D3), Color(0xFF2481FA)],
                  ),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: onPressed == null
                    ? const Color(0x1A7B97BA)
                    : const Color(0x333A8EF2),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: onPressed == null
                      ? const Color(0xFF8EA2C0)
                      : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed == null
                        ? const Color(0xFF8EA2C0)
                        : Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordDetailSheet extends StatelessWidget {
  const _WordDetailSheet({required this.entry});

  final VocabularyCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final transcription = entry.word.transcription;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E2F1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ĐANG XEM TỪ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF55A8EF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F8FD),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.word.writing,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.7,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.word.translation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AudioButton(
                      icon: Icons.slow_motion_video_rounded,
                      label: 'Nghe chậm',
                      onTap: () => TextToSpeechService.instance.speak(
                        entry.word.writing,
                        speechRate: TextToSpeechService.slowSpeechRate,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _AudioButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Nghe phát âm',
                      large: true,
                      onTap: () => TextToSpeechService.instance.speak(
                        entry.word.writing,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _statusColor(entry.status).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusTitle(entry.status),
                    style: TextStyle(
                      color: _statusColor(entry.status),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _DetailLine(
                  label: 'American English',
                  value: transcription == null || transcription.isEmpty
                      ? 'Chưa cập nhật'
                      : '/$transcription/',
                ),
                _DetailLine(
                  label: 'Cấp độ từ',
                  value: _levelLabel(entry.word.level),
                ),
                _DetailLine(label: 'Chủ đề', value: entry.topic.translated),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 82.0 : 68.0;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0xFFF6FBFF),
        shape: CircleBorder(
          side: const BorderSide(color: Color(0xFFBFE0FB), width: 3),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: const Color(0xFF55A8EF), size: 28),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusTitle(VocabularyCollectionStatus status) {
  switch (status) {
    case VocabularyCollectionStatus.mastered:
      return 'Đã nắm chắc';
    case VocabularyCollectionStatus.reviewing:
      return 'Đang ôn';
    case VocabularyCollectionStatus.needsPractice:
      return 'Các từ khó';
  }
}

String _statusUnit(VocabularyCollectionStatus status) {
  switch (status) {
    case VocabularyCollectionStatus.mastered:
      return 'từ chắc';
    case VocabularyCollectionStatus.reviewing:
      return 'từ đang ôn';
    case VocabularyCollectionStatus.needsPractice:
      return 'từ cần luyện';
  }
}

String _statusDescription(VocabularyCollectionStatus status) {
  switch (status) {
    case VocabularyCollectionStatus.mastered:
      return 'Danh sách từ đã nắm vững để bạn nghe lại và xem chi tiết.';
    case VocabularyCollectionStatus.reviewing:
      return 'Những từ đang đi qua lịch lặp lại để ghi nhớ lâu hơn.';
    case VocabularyCollectionStatus.needsPractice:
      return 'Những từ bạn thường nhầm hoặc cần thêm thời gian luyện tập.';
  }
}

Color _statusColor(VocabularyCollectionStatus status) {
  switch (status) {
    case VocabularyCollectionStatus.mastered:
      return AppColors.green;
    case VocabularyCollectionStatus.reviewing:
      return AppColors.primary;
    case VocabularyCollectionStatus.needsPractice:
      return AppColors.orange;
  }
}

String _levelLabel(int level) {
  if (level <= 1) return 'sơ cấp';
  if (level == 2) return 'trung cấp';
  return 'nâng cao';
}
