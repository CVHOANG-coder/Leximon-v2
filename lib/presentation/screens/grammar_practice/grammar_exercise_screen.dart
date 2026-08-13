import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/grammar_content.dart';
import '../../../data/services/grammar_progress_service.dart';
import '../../../data/services/grammar_question_engine.dart';
import '../../../shared/providers/app_providers.dart';
import 'grammar_practice_screen.dart';

class GrammarExerciseScreen extends ConsumerStatefulWidget {
  const GrammarExerciseScreen({
    required this.pack,
    required this.topic,
    this.initialQuestions,
    this.progressService,
    super.key,
  });

  final GrammarPack pack;
  final GrammarTopic topic;
  final List<GrammarQuestionContent>? initialQuestions;
  final GrammarProgressService? progressService;

  @override
  ConsumerState<GrammarExerciseScreen> createState() =>
      _GrammarExerciseScreenState();
}

class _GrammarExerciseScreenState extends ConsumerState<GrammarExerciseScreen> {
  final _engine = const GrammarQuestionEngine();
  late final GrammarProgressService _progressService;
  late final Future<List<GrammarQuestionContent>> _questionsFuture;
  List<GrammarQuestionViewData> _questions = const [];
  GrammarAnswerDraft? _draft;
  List<TextEditingController> _textControllers = const [];
  int _currentIndex = 0;
  bool _isResolved = false;
  bool _isCorrect = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _progressService =
        widget.progressService ?? ref.read(grammarProgressServiceProvider);
    _questionsFuture = widget.initialQuestions == null
        ? ref.read(grammarTopicQuestionsProvider(widget.topic.id).future)
        : Future.value(widget.initialQuestions!);
  }

  @override
  void dispose() {
    _disposeTextControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('grammar-exercise-screen'),
        backgroundColor: const Color(0xFFF7FAFF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _ExerciseBackdrop(),
            SafeArea(
              bottom: false,
              child: FutureBuilder<List<GrammarQuestionContent>>(
                future: _questionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ExerciseLoadError(
                      message: snapshot.error.toString(),
                    );
                  }
                  _initializeQuestions(snapshot.data ?? const []);
                  if (_questions.isEmpty) {
                    return const _ExerciseLoadError(
                      message: 'This lesson has no questions.',
                    );
                  }
                  final question = _questions[_currentIndex];
                  final draft = _draft!;
                  return Column(
                    children: [
                      _ExerciseHeader(
                        title: widget.topic.label,
                        current: _currentIndex + 1,
                        total: _questions.length,
                        onClose: _confirmExit,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('grammar-question-scroll'),
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _QuestionTypePill(question: question),
                              const SizedBox(height: 13),
                              _GrammarElementsText(
                                elements: question.rubric,
                                fallback: _fallbackInstruction(question),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 20,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _QuestionContentCard(question: question),
                              const SizedBox(height: 18),
                              KeyedSubtree(
                                key: ValueKey(
                                  'grammar-renderer-${question.source.id}',
                                ),
                                child: _buildRenderer(question, draft),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _ExerciseFooter(
                        isResolved: _isResolved,
                        isCorrect: _isCorrect,
                        feedbackDetail: _isResolved && !_isCorrect
                            ? _feedbackDetail(question, draft)
                            : null,
                        correctAnswers: _isResolved && !_isCorrect
                            ? _engine.correctAnswerLines(question)
                            : const [],
                        isSaving: _isSaving,
                        canCheck: _engine.isComplete(question, draft),
                        isLast: _currentIndex == _questions.length - 1,
                        onPrimary: _isResolved ? _next : _check,
                      ),
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

  void _initializeQuestions(List<GrammarQuestionContent> contents) {
    if (_initialized) return;
    _initialized = true;
    _questions = contents
        .map(GrammarQuestionViewData.fromContent)
        .toList(growable: false);
    if (_questions.isEmpty) return;
    final unfinished = contents.indexWhere(
      (question) => question.savedResponse == null,
    );
    _currentIndex = unfinished < 0 ? 0 : unfinished;
    _restoreDraft();
  }

  void _restoreDraft() {
    _disposeTextControllers();
    final question = _questions[_currentIndex];
    final saved = question.source.savedResponse;
    _draft = saved == null
        ? GrammarAnswerDraft.empty(question)
        : GrammarAnswerDraft.restore(question, saved.responseData);
    _isResolved = saved != null;
    _isCorrect = saved?.isCorrect ?? false;
    _textControllers = [
      for (final answer in _draft!.gapTexts)
        TextEditingController(text: answer),
    ];
  }

  void _disposeTextControllers() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    _textControllers = const [];
  }

  Widget _buildRenderer(
    GrammarQuestionViewData question,
    GrammarAnswerDraft draft,
  ) {
    if (question.type == 'MCQ') {
      return _ChoiceRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    if (question.type == 'FIB') {
      if (question.responseType == 'TEXT') {
        return _TextGapRenderer(
          question: question,
          draft: draft,
          controllers: _textControllers,
          locked: _isResolved,
          onChanged: () => setState(() {}),
        );
      }
      return _ChoiceGapRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    if (question.type == 'REORDERING') {
      return _ReorderRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    if (question.type == 'MATCHSORT') {
      return _MatchRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    if (question.type == 'LABELLING') {
      return _LabellingRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    if (question.type == 'GROUPING') {
      return _GroupingRenderer(
        question: question,
        draft: draft,
        locked: _isResolved,
        onChanged: () => setState(() {}),
      );
    }
    return _UnsupportedRenderer(type: question.type);
  }

  Future<void> _check() async {
    final question = _questions[_currentIndex];
    final draft = _draft!;
    if (!_engine.isComplete(question, draft) || _isSaving) return;
    setState(() => _isSaving = true);
    final correct = _engine.check(question, draft);
    try {
      await _progressService.saveResponse(
        questionId: question.source.id,
        topicId: question.source.topicId,
        responseData: _engine.serialize(question, draft),
        isCorrect: correct,
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isResolved = true;
        _isCorrect = correct;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa thể lưu đáp án. Hãy thử lại.')),
      );
    }
  }

  Future<void> _next() async {
    if (_currentIndex >= _questions.length - 1) {
      await _showResult();
      return;
    }
    setState(() {
      _currentIndex++;
      _restoreDraft();
    });
  }

  Future<void> _showResult() async {
    final repository = ref.read(grammarRepositoryProvider);
    final refreshed = await repository.loadTopicQuestions(widget.topic.id);
    if (!mounted) return;
    final answered = refreshed
        .where((item) => item.savedResponse != null)
        .length;
    final correct = refreshed
        .where((item) => item.savedResponse?.isCorrect == true)
        .length;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GrammarTopicResultScreen(
          packTitle: widget.pack.title,
          topicTitle: widget.topic.label,
          answered: answered,
          correct: correct,
          total: refreshed.length,
          questions: refreshed,
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời bài luyện?'),
        content: const Text(
          'Các câu đã kiểm tra đã được lưu. Bạn có thể tiếp tục từ câu đang dở sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rời bài'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) Navigator.of(context).pop();
  }

  String _fallbackInstruction(GrammarQuestionViewData question) =>
      switch (question.type) {
        'MCQ' => 'Choose the correct answer.',
        'FIB' => 'Complete the sentence.',
        'REORDERING' => 'Arrange the words in the correct order.',
        'MATCHSORT' => 'Match the two parts.',
        'LABELLING' => 'Select all the correct words.',
        'GROUPING' => 'Put each item into the correct group.',
        _ => 'Complete this exercise.',
      };

  String? _feedbackDetail(
    GrammarQuestionViewData question,
    GrammarAnswerDraft draft,
  ) {
    if (question.type != 'LABELLING' || question.answers is! List) return null;
    final correct = (question.answers as List)
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    final wrongCount = draft.selections.difference(correct).length;
    final missingCount = correct.difference(draft.selections).length;
    if (wrongCount > 0 && missingCount > 0) {
      return '$wrongCount từ chọn sai • thiếu $missingCount đáp án';
    }
    if (wrongCount > 0) return 'Bạn đã chọn sai $wrongCount từ';
    if (missingCount > 0) return 'Bạn chọn thiếu $missingCount đáp án';
    return null;
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.title,
    required this.current,
    required this.total,
    required this.onClose,
  });

  final String title;
  final int current;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('grammar-exercise-close'),
              onTap: onClose,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close_rounded, color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _GrammarExerciseProgressBar(value: current / total),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .15),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x122A70B8),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$current/$total',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarExerciseProgressBar extends StatelessWidget {
  const _GrammarExerciseProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('grammar-exercise-progress'),
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2A70B8),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: ColoredBox(
          color: const Color(0xFFD7E9FA),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                final visibleProgress = progress <= 0
                    ? 0.0
                    : (.07 + (progress * .93)).clamp(0.0, 1.0);
                return FractionallySizedBox(
                  key: const ValueKey('grammar-exercise-progress-fill'),
                  widthFactor: visibleProgress,
                  heightFactor: 1,
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF155CFF), Color(0xFF66CFF4)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionTypePill extends StatelessWidget {
  const _QuestionTypePill({required this.question});

  final GrammarQuestionViewData question;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (question.type) {
      'MCQ' => (Icons.touch_app_rounded, 'CHOOSE'),
      'FIB' => (Icons.edit_note_rounded, 'FILL THE GAP'),
      'REORDERING' => (Icons.swap_vert_rounded, 'REORDER'),
      'MATCHSORT' => (Icons.compare_arrows_rounded, 'MATCH'),
      'LABELLING' => (Icons.select_all_rounded, 'SELECT WORDS'),
      'GROUPING' => (Icons.dashboard_customize_rounded, 'GROUP'),
      _ => (Icons.school_rounded, question.type),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4FF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionContentCard extends StatelessWidget {
  const _QuestionContentCard({required this.question});

  final GrammarQuestionViewData question;

  @override
  Widget build(BuildContext context) {
    if (question.type == 'LABELLING' ||
        question.type == 'GROUPING' ||
        question.type == 'MATCHSORT') {
      return const SizedBox.shrink();
    }
    final answerBody = question.answerBody;
    final supportingElements = [
      ...question.leftColumn,
      ...answerBody.where(
        (element) =>
            element.type == GrammarElementType.image ||
            element.type == GrammarElementType.audio,
      ),
    ];
    final inlineElements = answerBody
        .where(
          (element) =>
              element.type == GrammarElementType.text ||
              element.type == GrammarElementType.gap,
        )
        .toList(growable: false);
    if (supportingElements.isEmpty && inlineElements.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142A70B8),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final element in supportingElements) ...[
            _QuestionElementView(element: element),
            if (element != supportingElements.last || inlineElements.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (inlineElements.isNotEmpty)
            if (question.requiredWord case final requiredWord?)
              _RewriteQuestionBody(
                elements: inlineElements,
                requiredWord: requiredWord,
              )
            else
              _InlineQuestionBody(elements: inlineElements),
        ],
      ),
    );
  }
}

class _RewriteQuestionBody extends StatelessWidget {
  const _RewriteQuestionBody({
    required this.elements,
    required this.requiredWord,
  });

  final List<GrammarQuestionElement> elements;
  final String requiredWord;

  @override
  Widget build(BuildContext context) {
    final gapIndex = elements.indexWhere(
      (element) => element.type == GrammarElementType.gap,
    );
    final beforeGap = (gapIndex < 0 ? elements : elements.take(gapIndex))
        .where((element) => element.type == GrammarElementType.text)
        .map((element) => element.data)
        .join(' ');
    final afterGap = gapIndex < 0
        ? ''
        : elements
              .skip(gapIndex + 1)
              .where((element) => element.type == GrammarElementType.text)
              .map((element) => element.data)
              .join(' ')
              .trim();
    final sentenceMatch = RegExp(
      r'^\s*A:\s*(.*?)\s*B:\s*(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(beforeGap);
    if (sentenceMatch == null) {
      return _InlineQuestionBody(elements: elements);
    }
    final sentenceA = _normalizeRewriteText(sentenceMatch.group(1) ?? '');
    final prefixB = _normalizeRewriteText(sentenceMatch.group(2) ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RewriteSectionLabel(label: 'CÂU GỐC'),
        const SizedBox(height: 8),
        _RewriteSentenceRow(marker: 'A', text: sentenceA),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE9F2FF), Color(0xFFF2F8FF)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCFE2FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Từ bắt buộc',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                key: const ValueKey('grammar-required-word'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .25),
                  ),
                ),
                child: Text(
                  requiredWord.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const _RewriteSectionLabel(label: 'VIẾT LẠI CÂU'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RewriteMarker(label: 'B'),
            const SizedBox(width: 9),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 7,
                children: [
                  if (prefixB.isNotEmpty) _RewriteText(text: prefixB),
                  const _RewriteGap(),
                  if (afterGap.isNotEmpty) _RewriteText(text: afterGap),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _normalizeRewriteText(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

class _RewriteSectionLabel extends StatelessWidget {
  const _RewriteSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class _RewriteSentenceRow extends StatelessWidget {
  const _RewriteSentenceRow({required this.marker, required this.text});

  final String marker;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _RewriteMarker(label: marker),
      const SizedBox(width: 9),
      Expanded(child: _RewriteText(text: text)),
    ],
  );
}

class _RewriteMarker extends StatelessWidget {
  const _RewriteMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFEBF3FF),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _RewriteText extends StatelessWidget {
  const _RewriteText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.primaryDark,
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _RewriteGap extends StatelessWidget {
  const _RewriteGap();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('grammar-rewrite-gap'),
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF5FF),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFF9DC8FF), width: 1.3),
    ),
    child: const Text(
      '__________',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    ),
  );
}

class _InlineQuestionBody extends StatelessWidget {
  const _InlineQuestionBody({required this.elements});

  final List<GrammarQuestionElement> elements;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 7,
      children: [
        for (final element in elements)
          if (element.type == GrammarElementType.gap)
            Container(
              width: 54,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF5FF),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFBED9FA)),
              ),
              child: const Text(
                '•••',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            )
          else
            _GrammarStyledText(
              element: element,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    );
  }
}

class _QuestionElementView extends StatelessWidget {
  const _QuestionElementView({required this.element});

  final GrammarQuestionElement element;

  @override
  Widget build(BuildContext context) {
    return switch (element.type) {
      GrammarElementType.image => _GrammarAssetImage(fileName: element.data),
      GrammarElementType.audio => _GrammarAssetAudioButton(
        key: ValueKey('grammar-audio-player-${element.data}'),
        fileName: element.data,
      ),
      GrammarElementType.text => _GrammarStyledText(
        element: element,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _GrammarElementsText extends StatelessWidget {
  const _GrammarElementsText({
    required this.elements,
    required this.fallback,
    required this.style,
  });

  final List<GrammarQuestionElement> elements;
  final String fallback;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final textElements = elements
        .where((element) => element.type == GrammarElementType.text)
        .toList(growable: false);
    if (textElements.isEmpty) return Text(fallback, style: style);
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < textElements.length; index++) ...[
            if (index > 0) const TextSpan(text: '\n'),
            ..._grammarTextSpans(textElements[index], style),
          ],
        ],
      ),
      style: style,
    );
  }
}

class _GrammarStyledText extends StatelessWidget {
  const _GrammarStyledText({
    required this.element,
    required this.style,
    this.textAlign,
  });

  final GrammarQuestionElement element;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(children: _grammarTextSpans(element, style)),
    style: style,
    textAlign: textAlign,
  );
}

List<InlineSpan> _grammarTextSpans(
  GrammarQuestionElement element,
  TextStyle baseStyle,
) {
  final segments = element.textSegments;
  if (segments.isEmpty) return [TextSpan(text: element.data)];
  return [
    for (final segment in segments)
      TextSpan(
        text: segment.text,
        style: segment.emphasized
            ? baseStyle.copyWith(fontStyle: FontStyle.italic)
            : null,
      ),
  ];
}

class _GrammarAssetImage extends StatelessWidget {
  const _GrammarAssetImage({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.asset(
      'assets/data/grammar/allpack/$fileName',
      key: ValueKey('grammar-image-$fileName'),
      fit: BoxFit.contain,
      height: 170,
      errorBuilder: (context, error, stack) => Container(
        height: 96,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
            SizedBox(height: 5),
            Text(
              'Không thể tải ảnh',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GrammarAssetAudioButton extends StatefulWidget {
  const _GrammarAssetAudioButton({required this.fileName, super.key});

  final String fileName;

  @override
  State<_GrammarAssetAudioButton> createState() =>
      _GrammarAssetAudioButtonState();
}

class _GrammarAssetAudioButtonState extends State<_GrammarAssetAudioButton> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final isPlaying =
          state.playing && state.processingState != ProcessingState.completed;
      if (_isPlaying != isPlaying) setState(() => _isPlaying = isPlaying);
    });
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isLoading || widget.fileName.isEmpty) return;
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _player.setAsset('assets/data/grammar/allpack/${widget.fileName}');
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát audio lúc này.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF6FF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('grammar-audio-${widget.fileName}'),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
              Text(
                _isPlaying ? 'Đang phát' : 'Nghe audio',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRenderer extends StatelessWidget {
  const _ChoiceRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final multi =
        question.answers is List && (question.answers as List).length > 1;
    final correctOptions = question.answers is List
        ? (question.answers as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .toSet()
        : const <int>{};
    return Column(
      children: [
        for (var index = 0; index < question.options.length; index++) ...[
          _AnswerOptionCard(
            key: ValueKey('grammar-option-${index + 1}'),
            number: index + 1,
            element: question.options[index],
            selected: draft.selections.contains(index + 1),
            locked: locked,
            correctChoice: correctOptions.contains(index + 1),
            onTap: () {
              if (locked) return;
              if (!multi) draft.selections.clear();
              if (!draft.selections.add(index + 1)) {
                draft.selections.remove(index + 1);
              }
              onChanged();
            },
          ),
          if (index < question.options.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  const _AnswerOptionCard({
    required this.number,
    required this.element,
    required this.selected,
    required this.locked,
    required this.correctChoice,
    required this.onTap,
    super.key,
  });

  final int number;
  final GrammarQuestionElement element;
  final bool selected;
  final bool locked;
  final bool correctChoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = locked && correctChoice;
    final showWrong = locked && selected && !correctChoice;
    final accent = showCorrect
        ? AppColors.green
        : showWrong
        ? const Color(0xFFFF6B6B)
        : AppColors.primary;
    return Material(
      color: (selected || showCorrect)
          ? accent.withValues(alpha: .1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: (selected || showCorrect) ? accent : const Color(0xFFE1EAF6),
          width: (selected || showCorrect) ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (selected || showCorrect)
                      ? accent
                      : const Color(0xFFF0F5FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: (selected || showCorrect)
                    ? Icon(
                        showWrong ? Icons.close_rounded : Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _QuestionElementView(element: element)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextGapRenderer extends StatelessWidget {
  const _TextGapRenderer({
    required this.question,
    required this.draft,
    required this.controllers,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final List<TextEditingController> controllers;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your answer',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        for (var index = 0; index < controllers.length; index++) ...[
          TextField(
            key: ValueKey('grammar-gap-text-$index'),
            controller: controllers[index],
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            readOnly: locked,
            textInputAction: index == controllers.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: controllers.length == 1
                  ? 'Type your answer'
                  : 'Gap ${index + 1}',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDDE8F6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDDE8F6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) {
              draft.gapTexts[index] = value;
              onChanged();
            },
          ),
          if (index < controllers.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _ChoiceGapRenderer extends StatefulWidget {
  const _ChoiceGapRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  State<_ChoiceGapRenderer> createState() => _ChoiceGapRendererState();
}

class _ChoiceGapRendererState extends State<_ChoiceGapRenderer> {
  int _activeGap = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < widget.draft.gapChoices.length; index++)
              ChoiceChip(
                label: Text(
                  widget.draft.gapChoices[index] == null
                      ? 'Gap ${index + 1}'
                      : widget
                            .question
                            .options[widget.draft.gapChoices[index]! - 1]
                            .data,
                ),
                selected: _activeGap == index,
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() => _activeGap = index),
              ),
          ],
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (var index = 0; index < widget.question.options.length; index++)
              ActionChip(
                key: ValueKey('grammar-gap-option-${index + 1}'),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFDDE8F6)),
                label: Text(widget.question.options[index].data),
                onPressed: widget.locked
                    ? null
                    : () {
                        widget.draft.gapChoices[_activeGap] = index + 1;
                        if (_activeGap < widget.draft.gapChoices.length - 1) {
                          setState(() => _activeGap++);
                        } else {
                          setState(() {});
                        }
                        widget.onChanged();
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _ReorderRenderer extends StatelessWidget {
  const _ReorderRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final shuffledOptions = _shuffledOptionIndices(question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF5FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final optionIndex in draft.order)
                InputChip(
                  label: Text(question.options[optionIndex - 1].data),
                  onDeleted: locked
                      ? null
                      : () {
                          draft.order.remove(optionIndex);
                          onChanged();
                        },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final optionIndex in shuffledOptions)
              if (!draft.order.contains(optionIndex))
                ActionChip(
                  key: ValueKey('grammar-reorder-option-$optionIndex'),
                  label: Text(question.options[optionIndex - 1].data),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFDDE8F6)),
                  onPressed: locked
                      ? null
                      : () {
                          draft.order.add(optionIndex);
                          onChanged();
                        },
                ),
          ],
        ),
      ],
    );
  }
}

class _MatchRenderer extends StatelessWidget {
  const _MatchRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final left = question.body;
    final shuffledOptions = _shuffledOptionIndices(question);
    return Column(
      children: [
        for (var index = 0; index < question.options.length; index++) ...[
          _MatchPairCard(
            key: ValueKey('grammar-match-card-$index'),
            number: index + 1,
            prompt: index < left.length ? left[index].data : '${index + 1}',
            selectedAnswer: _selectedMatchAnswer(index),
            correctAnswer: question.options[index].data,
            locked: locked,
            isCorrect: locked && _selectedMatchIndex(index) == index + 1,
            onTap: locked
                ? null
                : () => _chooseAnswer(
                    context,
                    rowIndex: index,
                    optionIndices: shuffledOptions,
                  ),
          ),
          if (index < question.options.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  int? _selectedMatchIndex(int rowIndex) {
    if (rowIndex >= draft.order.length || draft.order[rowIndex] <= 0) {
      return null;
    }
    return draft.order[rowIndex];
  }

  String? _selectedMatchAnswer(int rowIndex) {
    final optionIndex = _selectedMatchIndex(rowIndex);
    if (optionIndex == null || optionIndex > question.options.length) {
      return null;
    }
    return question.options[optionIndex - 1].data;
  }

  Future<void> _chooseAnswer(
    BuildContext context, {
    required int rowIndex,
    required List<int> optionIndices,
  }) async {
    final selected = await _showMatchOptionsSheet(
      context,
      prompt: rowIndex < question.body.length
          ? question.body[rowIndex].data
          : '${rowIndex + 1}',
      options: question.options,
      optionIndices: optionIndices,
      currentValue: _selectedMatchIndex(rowIndex),
      usedValues: draft.order,
    );
    if (selected == null || !context.mounted) return;
    while (draft.order.length < question.options.length) {
      draft.order.add(0);
    }
    for (var index = 0; index < draft.order.length; index++) {
      if (index != rowIndex && draft.order[index] == selected) {
        draft.order[index] = 0;
      }
    }
    draft.order[rowIndex] = selected;
    onChanged();
  }
}

class _MatchPairCard extends StatelessWidget {
  const _MatchPairCard({
    required this.number,
    required this.prompt,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.locked,
    required this.isCorrect,
    required this.onTap,
    super.key,
  });

  final int number;
  final String prompt;
  final String? selectedAnswer;
  final String correctAnswer;
  final bool locked;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAnswer = selectedAnswer != null;
    final stateColor = locked
        ? (isCorrect ? AppColors.green : const Color(0xFFFF6B6B))
        : AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: locked
              ? stateColor.withValues(alpha: .38)
              : const Color(0xFFE1EBF8),
          width: locked ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x102A70B8),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VẾ CẦN GHÉP',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .75,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: Divider(color: stateColor.withValues(alpha: .2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.link_rounded,
                  color: stateColor.withValues(alpha: .75),
                  size: 19,
                ),
              ),
              Expanded(child: Divider(color: stateColor.withValues(alpha: .2))),
            ],
          ),
          const SizedBox(height: 9),
          Material(
            color: hasAnswer
                ? stateColor.withValues(alpha: locked ? .09 : .06)
                : const Color(0xFFF7FAFE),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              key: ValueKey('grammar-match-answer-${number - 1}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasAnswer
                        ? stateColor.withValues(alpha: .32)
                        : const Color(0xFFDDE8F6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: hasAnswer
                            ? stateColor.withValues(alpha: .13)
                            : const Color(0xFFEAF1FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        locked
                            ? (isCorrect
                                  ? Icons.check_rounded
                                  : Icons.close_rounded)
                            : Icons.add_link_rounded,
                        color: hasAnswer ? stateColor : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedAnswer ?? 'Chọn nội dung phù hợp',
                        style: TextStyle(
                          color: hasAnswer
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: hasAnswer
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!locked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (locked && !isCorrect) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Đáp án đúng: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: correctAnswer,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<int?> _showMatchOptionsSheet(
  BuildContext context, {
  required String prompt,
  required List<GrammarQuestionElement> options,
  required List<int> optionIndices,
  required int? currentValue,
  required List<int> usedValues,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final height = math.min(MediaQuery.sizeOf(context).height * .72, 570.0);
      return Container(
        key: const ValueKey('grammar-match-options-sheet'),
        height: height,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3DFEE),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CHỌN VẾ PHÙ HỢP',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prompt,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: optionIndices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final optionIndex = optionIndices[index];
                  final selected = optionIndex == currentValue;
                  final usedAt = usedValues.indexOf(optionIndex);
                  return Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: .08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      key: ValueKey('grammar-match-option-$optionIndex'),
                      onTap: () => Navigator.of(context).pop(optionIndex),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 58),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(alpha: .5)
                                : const Color(0xFFE1EAF5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFEDF3FB),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.link_rounded,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                options[optionIndex - 1].data,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!selected && usedAt >= 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF3FB),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'Cặp ${usedAt + 1}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

List<int> _shuffledOptionIndices(GrammarQuestionViewData question) {
  final indices = List<int>.generate(
    question.options.length,
    (index) => index + 1,
  );
  indices.shuffle(math.Random(question.source.id));
  return indices;
}

class _LabellingRenderer extends StatelessWidget {
  const _LabellingRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = question.body
        .where((element) => element.type == GrammarElementType.text)
        .map((element) => element.data)
        .join(' ');
    final words = text.split(RegExp(r'\s+'));
    final correctPositions = question.answers is List
        ? (question.answers as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .toSet()
        : const <int>{};
    return Wrap(
      spacing: 8,
      runSpacing: 9,
      children: [
        for (var index = 0; index < words.length; index++)
          _LabellingWordChip(
            key: ValueKey('grammar-label-word-${index + 1}'),
            label: words[index],
            selected: draft.selections.contains(index + 1),
            correct: correctPositions.contains(index + 1),
            resolved: locked,
            onTap: locked
                ? null
                : () {
                    if (!draft.selections.add(index + 1)) {
                      draft.selections.remove(index + 1);
                    }
                    onChanged();
                  },
          ),
      ],
    );
  }
}

class _LabellingWordChip extends StatelessWidget {
  const _LabellingWordChip({
    required this.label,
    required this.selected,
    required this.correct,
    required this.resolved,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool resolved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = resolved && selected && correct;
    final showWrong = resolved && selected && !correct;
    final showMissing = resolved && !selected && correct;
    final showPendingSelection = !resolved && selected;
    final accent = showCorrect
        ? AppColors.green
        : showWrong
        ? const Color(0xFFFF5F66)
        : showMissing
        ? const Color(0xFFF59E0B)
        : AppColors.primary;
    final background = showCorrect
        ? accent.withValues(alpha: .18)
        : showWrong
        ? accent.withValues(alpha: .13)
        : showMissing
        ? accent.withValues(alpha: .1)
        : showPendingSelection
        ? accent.withValues(alpha: .12)
        : Colors.white.withValues(alpha: .83);
    final borderColor =
        showCorrect || showWrong || showMissing || showPendingSelection
        ? accent
        : const Color(0xFFD5DEEC);
    final showStatusIcon =
        showCorrect || showWrong || showMissing || showPendingSelection;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 43),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: borderColor,
              width: showCorrect || showWrong || showMissing ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x102A70B8),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStatusIcon) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showWrong
                        ? Icons.close_rounded
                        : showMissing
                        ? Icons.priority_high_rounded
                        : Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  color:
                      showCorrect ||
                          showWrong ||
                          showMissing ||
                          showPendingSelection
                      ? accent
                      : AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: showStatusIcon
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
              if (showMissing) ...[
                const SizedBox(width: 7),
                Container(
                  key: const ValueKey('grammar-label-missing-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Thiếu',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupingRenderer extends StatelessWidget {
  const _GroupingRenderer({
    required this.question,
    required this.draft,
    required this.locked,
    required this.onChanged,
  });

  final GrammarQuestionViewData question;
  final GrammarAnswerDraft draft;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < question.body.length; index++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0EAF6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question.body[index].data,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: draft.groups[index],
                  hint: const Text('Group'),
                  underline: const SizedBox.shrink(),
                  items: [
                    for (
                      var group = 0;
                      group < question.options.length;
                      group++
                    )
                      DropdownMenuItem(
                        value: group + 1,
                        child: Text(question.options[group].data),
                      ),
                  ],
                  onChanged: locked
                      ? null
                      : (value) {
                          draft.groups[index] = value;
                          onChanged();
                        },
                ),
              ],
            ),
          ),
          if (index < question.body.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _UnsupportedRenderer extends StatelessWidget {
  const _UnsupportedRenderer({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E9),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text('Unsupported question type: $type'),
  );
}

class _ExerciseFooter extends StatelessWidget {
  const _ExerciseFooter({
    required this.isResolved,
    required this.isCorrect,
    required this.feedbackDetail,
    required this.correctAnswers,
    required this.isSaving,
    required this.canCheck,
    required this.isLast,
    required this.onPrimary,
  });

  final bool isResolved;
  final bool isCorrect;
  final String? feedbackDetail;
  final List<String> correctAnswers;
  final bool isSaving;
  final bool canCheck;
  final bool isLast;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final feedbackColor = isCorrect ? AppColors.green : const Color(0xFFFF6B6B);
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        isResolved ? 12 : 16,
        18,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isResolved
            ? feedbackColor.withValues(alpha: .1)
            : Colors.white.withValues(alpha: .95),
        border: const Border(top: BorderSide(color: Color(0xFFE7EEF7))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isResolved) ...[
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: feedbackColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? 'Chính xác!' : 'Chưa chính xác',
                        style: TextStyle(
                          color: feedbackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (feedbackDetail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          feedbackDetail!,
                          key: const ValueKey('grammar-answer-feedback-detail'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isCorrect && correctAnswers.isNotEmpty) ...[
              _CorrectAnswerCard(lines: correctAnswers),
              const SizedBox(height: 10),
            ],
          ],
          FilledButton(
            key: const ValueKey('grammar-check-button'),
            onPressed: (isResolved || canCheck) && !isSaving ? onPrimary : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: isResolved ? feedbackColor : AppColors.primary,
              disabledBackgroundColor: const Color(0xFFD7E1EE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: isSaving
                ? const SizedBox.square(
                    dimension: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isResolved
                        ? isLast
                              ? 'Xem kết quả'
                              : 'Tiếp tục'
                        : 'Kiểm tra',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CorrectAnswerCard extends StatelessWidget {
  const _CorrectAnswerCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('grammar-correct-answer'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.green.withValues(alpha: .28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.green, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đáp án đúng',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 92),
                  child: SingleChildScrollView(
                    child: Text(
                      lines.join('\n'),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class GrammarTopicResultScreen extends ConsumerWidget {
  const GrammarTopicResultScreen({
    required this.packTitle,
    required this.topicTitle,
    required this.answered,
    required this.correct,
    required this.total,
    this.questions = const <GrammarQuestionContent>[],
    super.key,
  });

  final String packTitle;
  final String topicTitle;
  final int answered;
  final int correct;
  final int total;
  final List<GrammarQuestionContent> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracy = answered == 0 ? 0 : (correct * 100 / answered).floor();
    final progress = total == 0 ? 0 : (answered * 100 / total).ceil();
    final wrong = questions
        .where((question) => question.savedResponse?.isCorrect == false)
        .length;
    return Scaffold(
      key: const ValueKey('grammar-topic-result-screen'),
      backgroundColor: const Color(0xFFF1F8FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_word_study.png',
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    key: const ValueKey('grammar-result-scroll'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/grammar/cup_grammar.png',
                                key: const ValueKey('grammar-result-trophy'),
                                width: 138,
                                height: 104,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Hoàn thành bài luyện!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 26,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$packTitle • $topicTitle',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ResultMetric(
                                      key: const ValueKey(
                                        'grammar-result-progress-card',
                                      ),
                                      icon: Icons.trending_up_rounded,
                                      label: 'Tiến độ',
                                      value: '$progress%',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _ResultMetric(
                                      key: const ValueKey(
                                        'grammar-result-accuracy-card',
                                      ),
                                      icon: Icons.track_changes_rounded,
                                      label: 'Chính xác',
                                      value: '$accuracy%',
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              if (questions.isNotEmpty) ...[
                                _ResultQuestionMap(questions: questions),
                                const SizedBox(height: 22),
                              ],
                              _ResultReviewHeader(
                                correct: correct,
                                wrong: wrong,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: questions.length,
                          itemBuilder: (context, index) => _ResultQuestionCard(
                            key: ValueKey(
                              'grammar-result-question-${index + 1}',
                            ),
                            number: index + 1,
                            question: questions[index],
                          ),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    11,
                    20,
                    12 + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE1EAF5)),
                    ),
                  ),
                  child: _ResultBottomButton(
                    onPressed: () {
                      ref.invalidate(grammarPacksProvider);
                      Navigator.of(context).pop();
                    },
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

class _ResultQuestionMap extends StatelessWidget {
  const _ResultQuestionMap({required this.questions});

  final List<GrammarQuestionContent> questions;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('grammar-result-question-map'),
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .87),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122A70B8),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ResultHeaderIcon(icon: Icons.assignment_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan câu trả lời',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ResultMapLegend(color: AppColors.green, label: 'Đúng'),
              SizedBox(width: 8),
              _ResultMapLegend(color: Color(0xFFFF5F66), label: 'Sai'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (var index = 0; index < questions.length; index++)
                _ResultQuestionDot(
                  key: ValueKey('grammar-result-index-${index + 1}'),
                  number: index + 1,
                  response: questions[index].savedResponse,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultMapLegend extends StatelessWidget {
  const _ResultMapLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ResultHeaderIcon extends StatelessWidget {
  const _ResultHeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4BA7FF), Color(0xFF155CFF)],
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30155CFF),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 19),
  );
}

class _ResultQuestionDot extends StatelessWidget {
  const _ResultQuestionDot({
    required this.number,
    required this.response,
    super.key,
  });

  final int number;
  final GrammarSavedResponse? response;

  @override
  Widget build(BuildContext context) {
    final color = response == null
        ? const Color(0xFFB4C2D5)
        : response!.isCorrect
        ? AppColors.green
        : const Color(0xFFFF5F66);
    return Semantics(
      label: response == null
          ? 'Câu $number, chưa làm'
          : response!.isCorrect
          ? 'Câu $number, đúng'
          : 'Câu $number, sai',
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .25),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ResultReviewHeader extends StatelessWidget {
  const _ResultReviewHeader({required this.correct, required this.wrong});

  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ResultHeaderIcon(icon: Icons.format_list_bulleted_rounded),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết câu trả lời',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Xem lại câu đúng và câu cần ôn thêm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _ResultCountBadge(
          key: const ValueKey('grammar-result-correct-count'),
          icon: Icons.check_rounded,
          count: correct,
          color: AppColors.green,
        ),
        const SizedBox(width: 7),
        _ResultCountBadge(
          key: const ValueKey('grammar-result-wrong-count'),
          icon: Icons.close_rounded,
          count: wrong,
          color: Color(0xFFFF5F66),
        ),
      ],
    );
  }
}

class _ResultCountBadge extends StatelessWidget {
  const _ResultCountBadge({
    required this.icon,
    required this.count,
    required this.color,
    super.key,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .23)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ResultQuestionCard extends StatelessWidget {
  const _ResultQuestionCard({
    required this.number,
    required this.question,
    super.key,
  });

  final int number;
  final GrammarQuestionContent question;

  @override
  Widget build(BuildContext context) {
    const engine = GrammarQuestionEngine();
    final viewData = GrammarQuestionViewData.fromContent(question);
    final isAnswered = question.savedResponse != null;
    final isCorrect = question.savedResponse?.isCorrect == true;
    final color = !isAnswered
        ? AppColors.textSecondary
        : isCorrect
        ? AppColors.green
        : const Color(0xFFFF5F66);
    final correctAnswers = isCorrect
        ? const <String>[]
        : engine.correctAnswerLines(viewData);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: color.withValues(alpha: .26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x102A70B8),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              !isAnswered
                  ? Icons.remove_rounded
                  : isCorrect
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Câu $number',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      !isAnswered
                          ? 'Chưa làm'
                          : isCorrect
                          ? 'Đúng'
                          : 'Sai',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _resultQuestionSummary(viewData),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isCorrect && correctAnswers.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Đáp án đúng: ${correctAnswers.join(' • ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _resultQuestionSummary(GrammarQuestionViewData question) {
  final elements = question.answerBody;
  final content = elements
      .where(
        (element) =>
            element.type == GrammarElementType.text ||
            element.type == GrammarElementType.gap,
      )
      .map(
        (element) =>
            element.type == GrammarElementType.gap ? '___' : element.data,
      )
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (content.isNotEmpty) return content;
  if (question.type == 'REORDERING') {
    return question.options.map((option) => option.data).join(' ');
  }
  if (question.instruction.isNotEmpty) return question.instruction;
  return switch (question.type) {
    'MCQ' => 'Chọn đáp án đúng',
    'MATCHSORT' => 'Ghép các nội dung tương ứng',
    'GROUPING' => 'Phân loại các từ vào nhóm đúng',
    _ => 'Bài tập ${question.type}',
  };
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 122,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1C2A70B8),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, color.withValues(alpha: .025)],
              ),
              border: Border.all(color: Colors.white, width: 1.4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 35,
            child: CustomPaint(
              key: const ValueKey('grammar-result-metric-wave'),
              painter: _ResultMetricWavePainter(
                color: color.withValues(alpha: .11),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 31),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: color,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
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

class _ResultMetricWavePainter extends CustomPainter {
  const _ResultMetricWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .55)
      ..cubicTo(
        size.width * .18,
        size.height * .9,
        size.width * .34,
        size.height * .12,
        size.width * .57,
        size.height * .34,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .55,
        size.width * .87,
        size.height * .08,
        size.width,
        size.height * .18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ResultMetricWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ResultBottomButton extends StatelessWidget {
  const _ResultBottomButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF155CFF), Color(0xFF287AF7)],
      ),
      borderRadius: BorderRadius.circular(19),
      boxShadow: const [
        BoxShadow(
          color: Color(0x32155CFF),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('grammar-result-back-button'),
        onTap: onPressed,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_rounded, color: Colors.white, size: 23),
            SizedBox(width: 11),
            Text(
              'Về danh sách bài học',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExerciseBackdrop extends StatelessWidget {
  const _ExerciseBackdrop();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bg_word_study.png',
    key: const ValueKey('grammar-exercise-background'),
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.fill,
    alignment: Alignment.topCenter,
    filterQuality: FilterQuality.high,
  );
}

class _ExerciseLoadError extends StatelessWidget {
  const _ExerciseLoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
