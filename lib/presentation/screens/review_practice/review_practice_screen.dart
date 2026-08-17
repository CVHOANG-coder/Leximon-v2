import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/practice_exercise.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/services/practice_lesson_generator.dart';
import '../../../data/services/learning_progress_service.dart';
import '../../../presentation/widgets/app_dialog.dart';
import '../../../presentation/widgets/app_bottom_sheet.dart';

class ReviewPracticeScreen extends StatefulWidget {
  const ReviewPracticeScreen({
    required this.words,
    required this.distractorWords,
    this.dailyTaskType = DailyTaskType.learn,
    this.similarWordIds = const {},
    this.listeningEnabled = true,
    this.pronouncingEnabled = true,
    this.initialQuestionIndex = 0,
    this.showIntroOnStart = true,
    this.title,
    this.kicker = 'SELECTED REVIEW',
    this.exerciseMasksByWordId = const {},
    this.database,
    this.onSessionCompleted,
    super.key,
  });

  final List<Map<String, dynamic>> words;
  final List<Map<String, dynamic>> distractorWords;
  final DailyTaskType dailyTaskType;
  final Map<int, List<int>> similarWordIds;
  final bool listeningEnabled;
  final bool pronouncingEnabled;
  final int initialQuestionIndex;
  final bool showIntroOnStart;
  final String? title;
  final String kicker;
  final Map<int, int> exerciseMasksByWordId;
  final AppDatabase? database;
  final ValueChanged<SessionCompletionResult>? onSessionCompleted;

  @override
  State<ReviewPracticeScreen> createState() => _ReviewPracticeScreenState();
}

class _ReviewPracticeScreenState extends State<ReviewPracticeScreen> {
  static const _wrongAnswerSheetDelay = Duration(milliseconds: 800);
  late final List<ExerciseWord> _introWords;
  late final List<PracticeExercise> _questions;
  late final List<ExerciseAnswerState> _answers;
  late final List<bool> _isRetry;
  late final List<int> _sessionOrderIndexes;
  late bool _showIntro;
  int _questionIndex = 0;
  ExerciseWord? _selectedAnswer;
  List<String> _typingInput = const [];
  bool _isAnswerSubmitted = false;
  bool _isFeedbackSheetVisible = false;
  bool _isSpeakingRecording = false;
  bool _isSpeakingResultCorrect = false;
  bool _isSpeakingDecisionVisible = false;
  int _questionTransitionDirection = 1;
  bool _speechAvailable = false;
  String _recognizedSpeakingText = '';
  String? _speakingError;
  LearningProgressService? _progressService;
  String? _sessionId;
  Future<void> _sessionReady = Future<void>.value();
  Future<void> _persistenceChain = Future<void>.value();
  final SpeechToText _speechToText = SpeechToText();

  PracticeExercise get _question => _questions[_questionIndex];
  bool get _hasSelection => _selectedAnswer != null;
  bool get _answered => _isAnswerSubmitted;
  bool get _isCorrect {
    if (!_answered) return false;
    if (_isTypingChoice) {
      return _typingInput.join() == _typingTarget;
    }
    if (_isSpeakingChoice) return _isSpeakingResultCorrect;
    return _selectedAnswer?.id == _question.word.id;
  }

  bool get _isListeningChoice =>
      _question.trainingExercise == TrainingExerciseType.choiceOfThreeListening;
  bool get _isFourListeningChoice =>
      _question.trainingExercise == TrainingExerciseType.choiceOfFourListening;
  bool get _isSpeakingChoice =>
      _question.trainingExercise == TrainingExerciseType.speaking;
  bool get _isTypingChoice =>
      _question.trainingExercise == TrainingExerciseType.constructor;
  String get _typingTarget => _normalizeTypingWord(_question.word.writing);

  String get _progressLabel {
    if (_showIntro) return context.l10n.text('reviewWarmupStep');
    if (_isListeningChoice) {
      return context.l10n.text('reviewListeningSoundStep');
    }
    if (_isFourListeningChoice) {
      return context.l10n.text('reviewListeningQuestionStep');
    }
    if (_isTypingChoice) return context.l10n.text('reviewTypingStep');
    if (_isSpeakingChoice) return context.l10n.text('reviewSpeakingStep');
    return context.l10n.text('reviewTranslationStep');
  }

  @override
  void initState() {
    super.initState();
    _introWords = widget.words
        .map(ExerciseWord.fromMap)
        .where((word) => word.writing.isNotEmpty && word.translation.isNotEmpty)
        .toList(growable: false);
    final enabledWords = widget.distractorWords
        .map(ExerciseWord.fromMap)
        .where((word) => word.writing.isNotEmpty && word.translation.isNotEmpty)
        .toList(growable: false);
    final generatedQuestions = PracticeLessonGenerator().buildLesson(
      words: _introWords,
      enabledWords: enabledWords,
      similarWordIds: widget.similarWordIds,
      listeningEnabled: widget.listeningEnabled,
      pronouncingEnabled: widget.pronouncingEnabled,
    );
    _questions = List<PracticeExercise>.of(
      widget.exerciseMasksByWordId.isEmpty
          ? generatedQuestions
          : generatedQuestions.where((question) {
              final mask = widget.exerciseMasksByWordId[question.word.id] ?? 0;
              final typeBit = LearningProgressService.bitForType(
                question.trainingExercise,
              );
              return (mask & typeBit) != 0;
            }),
    );
    _answers = List<ExerciseAnswerState>.filled(
      _questions.length,
      ExerciseAnswerState.notAnswered,
      growable: true,
    );
    _isRetry = List<bool>.filled(_questions.length, false, growable: true);
    _sessionOrderIndexes = List<int>.generate(
      _questions.length,
      (index) => index,
      growable: true,
    );
    _showIntro = widget.showIntroOnStart;
    _questionIndex = widget.initialQuestionIndex
        .clamp(0, _questions.length - 1)
        .toInt();

    if (widget.database != null && _questions.isNotEmpty) {
      _progressService = LearningProgressService(widget.database!);
      _sessionReady = _createLearningSession();
    }
  }

  Future<void> _createLearningSession() async {
    final service = _progressService;
    if (service == null) return;
    _sessionId = await service.startSession(
      exercises: _questions,
      requiredMask: LearningProgressService.maskForTypes(
        _questions.map((question) => question.trainingExercise),
      ),
      topicId: _introWords.first.topicId,
    );
  }

  void _startPractice() {
    setState(() {
      _questionTransitionDirection = 1;
      _showIntro = false;
    });
  }

  void _selectAnswer(ExerciseWord answer) {
    if (_answered || (!_isListeningChoice && _hasSelection)) return;
    setState(() {
      _selectedAnswer = answer;
      if (!_isListeningChoice) _isAnswerSubmitted = true;
    });
    if (!_isListeningChoice) {
      _recordCurrentAnswer(
        answer.id == _question.word.id
            ? ExerciseAnswerState.correct
            : ExerciseAnswerState.wrong,
      );
    }
    final isWrongAnswer = answer.id != _question.word.id;
    if (isWrongAnswer && !_isListeningChoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWrongAnswerSheet();
      });
    }
  }

  void _submitAnswer() {
    if (!_isListeningChoice || !_hasSelection || _answered) return;
    final isWrongAnswer = _selectedAnswer!.id != _question.word.id;
    setState(() => _isAnswerSubmitted = true);
    _recordCurrentAnswer(
      isWrongAnswer ? ExerciseAnswerState.wrong : ExerciseAnswerState.correct,
    );
    if (isWrongAnswer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showListeningWrongAnswerSheet();
      });
    }
  }

  void _selectTypingCharacter(String character) {
    if (!_isTypingChoice || _answered) return;
    final answerWord = _question.word;
    final targetCharacters = _typingTarget.split('');
    final usedCount = _typingInput.where((item) => item == character).length;
    final availableCount = targetCharacters
        .where((item) => item == character)
        .length;
    if (usedCount >= availableCount) return;

    final nextInput = [..._typingInput, character];
    final completed = nextInput.length == targetCharacters.length;
    setState(() {
      _typingInput = nextInput;
      if (completed) _isAnswerSubmitted = true;
    });
    if (completed) {
      _recordCurrentAnswer(
        _isCorrect ? ExerciseAnswerState.correct : ExerciseAnswerState.wrong,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_playWord(answerWord));
      });
    }
    if (completed && !_isCorrect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTypingWrongAnswerSheet();
      });
    }
  }

  void _removeLastTypingCharacter() {
    if (!_isTypingChoice || _answered || _typingInput.isEmpty) return;
    setState(() {
      _typingInput = List<String>.of(_typingInput)..removeLast();
    });
  }

  Future<void> _showWrongAnswerSheet() async {
    if (!mounted || !_answered || _isCorrect || _isListeningChoice) return;
    final selectedAnswer = _selectedAnswer!;
    final question = _question;
    setState(() => _isFeedbackSheetVisible = true);
    await Future<void>.delayed(_wrongAnswerSheetDelay);
    if (!mounted || !_answered || _isCorrect || _isListeningChoice) {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6604193A),
        builder: (sheetContext) => _WrongAnswerSheet(
          selectedAnswer: selectedAnswer,
          correctAnswer: question.word,
          onPlay: _playWord,
          onContinue: () {
            Navigator.of(sheetContext).pop();
            unawaited(_continue());
          },
          isLast: _questionIndex == _questions.length - 1,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
    }
  }

  Future<void> _showListeningWrongAnswerSheet() async {
    if (!mounted || !_answered || _isCorrect || !_isListeningChoice) return;
    final selectedAnswer = _selectedAnswer!;
    final question = _question;
    setState(() => _isFeedbackSheetVisible = true);
    await Future<void>.delayed(_wrongAnswerSheetDelay);
    if (!mounted || !_answered || _isCorrect || !_isListeningChoice) {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6604193A),
        builder: (sheetContext) => _ListeningWrongAnswerSheet(
          question: question,
          selectedAnswer: selectedAnswer,
          onPlay: _playWord,
          onContinue: () {
            Navigator.of(sheetContext).pop();
            unawaited(_continue());
          },
          isLast: _questionIndex == _questions.length - 1,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
    }
  }

  Future<void> _showTypingWrongAnswerSheet() async {
    if (!mounted || !_answered || _isCorrect || !_isTypingChoice) return;
    final question = _question;
    setState(() => _isFeedbackSheetVisible = true);
    await Future<void>.delayed(_wrongAnswerSheetDelay);
    if (!mounted || !_answered || _isCorrect || !_isTypingChoice) {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6604193A),
        builder: (sheetContext) => _TypingWrongAnswerSheet(
          question: question,
          onPlay: _playWord,
          onContinue: () {
            Navigator.of(sheetContext).pop();
            unawaited(_continue());
          },
          isLast: _questionIndex == _questions.length - 1,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFeedbackSheetVisible = false);
    }
  }

  Future<void> _continue() async {
    if (!_answered) return;
    if (_questionIndex == _questions.length - 1) {
      await _finishSession();
      return;
    }
    setState(() {
      _questionTransitionDirection = 1;
      _questionIndex += 1;
      _selectedAnswer = null;
      _typingInput = const [];
      _isAnswerSubmitted = false;
      _isSpeakingRecording = false;
      _recognizedSpeakingText = '';
      _speakingError = null;
      _isSpeakingResultCorrect = false;
    });
  }

  void _recordCurrentAnswer(ExerciseAnswerState answer) {
    _recordAnswerAt(_questionIndex, answer);
  }

  void _recordAnswerAt(int index, ExerciseAnswerState answer) {
    if (_answers[index] != ExerciseAnswerState.notAnswered) return;
    _answers[index] = answer;

    final question = _questions[index];
    if (answer == ExerciseAnswerState.wrong &&
        !_isRetry[index] &&
        widget.dailyTaskType != DailyTaskType.difficult) {
      _appendRetry(question);
    }

    final service = _progressService;
    if (service == null) return;
    _persistenceChain = _persistenceChain.then((_) async {
      await _sessionReady;
      final sessionId = _sessionId;
      if (sessionId == null) return;
      await service.submitAnswer(
        sessionId: sessionId,
        orderIndex: _sessionOrderIndexes[index],
        answer: answer,
        createRetryOnWrong: widget.dailyTaskType != DailyTaskType.difficult,
      );
    });
  }

  void _appendRetry(PracticeExercise question) {
    for (var index = 0; index < _questions.length; index++) {
      if (_isRetry[index] &&
          _questions[index].word.id == question.word.id &&
          _questions[index].trainingExercise == question.trainingExercise) {
        return;
      }
    }
    setState(() {
      _questions.add(
        PracticeExercise(
          word: question.word,
          variants: question.variants,
          trainingExercise: question.trainingExercise,
        ),
      );
      _answers.add(ExerciseAnswerState.notAnswered);
      _isRetry.add(true);
      _sessionOrderIndexes.add(_sessionOrderIndexes.length);
    });
  }

  Future<void> _finishSession() async {
    await _persistenceChain;
    final service = _progressService;
    final sessionId = _sessionId;
    if (service != null && sessionId != null) {
      try {
        final result = await service.completeSession(
          sessionId,
          dailyTaskType: widget.dailyTaskType,
        );
        widget.onSessionCompleted?.call(result);
      } on StateError {
        // Keep the completed UI flow available when a non-persistent test
        // session is intentionally interrupted.
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _playWord(ExerciseWord word) {
    return TextToSpeechService.instance.speak(word.writing);
  }

  Future<void> _playWordSlow(ExerciseWord word) {
    return TextToSpeechService.instance.speak(
      word.writing,
      speechRate: TextToSpeechService.slowSpeechRate,
    );
  }

  Future<void> _toggleSpeakingRecording() async {
    if (!_isSpeakingChoice || _answered) return;
    if (_isSpeakingRecording) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isSpeakingRecording = false);
        _maybeShowNoSpeech();
      }
      return;
    }

    final available = await _ensureSpeechRecognition();
    if (!available) {
      if (mounted) {
        setState(() {
          _speakingError = context.l10n.text('reviewSpeechAccessError');
        });
        // Permission/device failure makes the remaining speaking block
        // unavailable for this session. It must not become a knowledge error.
        _skipSpeakingQuestions();
      }
      return;
    }

    if (!mounted || !_isSpeakingChoice || _answered) return;
    setState(() {
      _isSpeakingRecording = true;
      _recognizedSpeakingText = '';
      _speakingError = null;
    });
    try {
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          partialResults: true,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          listenMode: ListenMode.confirmation,
        ),
        onResult: (result) {
          if (!mounted) return;
          setState(() => _recognizedSpeakingText = result.recognizedWords);
        },
      );
    } on Object {
      if (mounted) {
        setState(() {
          _isSpeakingRecording = false;
          _speakingError = context.l10n.text('reviewRecordingStartError');
        });
      }
    }
  }

  Future<bool> _ensureSpeechRecognition() async {
    if (_speechAvailable) return true;
    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted || !_isSpeakingRecording) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isSpeakingRecording = false);
            _maybeShowNoSpeech();
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isSpeakingRecording = false;
            _speakingError = error.errorMsg;
          });
          if (_isNoSpeechError(error.errorMsg)) _maybeShowNoSpeech();
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
      return available;
    } on Object {
      return false;
    }
  }

  void _checkSpeakingResult() {
    if (!_isSpeakingChoice || _isSpeakingRecording || _answered) return;
    final recognized = _normalizeSpeech(_recognizedSpeakingText);
    if (recognized.isEmpty) {
      unawaited(_showSpeakingDecision(noSound: true));
      return;
    }
    final isCorrect = recognized == _normalizeSpeech(_question.word.writing);
    if (isCorrect) {
      setState(() {
        _isSpeakingResultCorrect = true;
        _isAnswerSubmitted = true;
      });
      _recordCurrentAnswer(ExerciseAnswerState.correct);
      return;
    }

    setState(() => _isSpeakingResultCorrect = false);
    unawaited(_showSpeakingDecision(noSound: false));
  }

  void _maybeShowNoSpeech() {
    if (!mounted || !_isSpeakingChoice || _answered || _isSpeakingRecording) {
      return;
    }
    if (_recognizedSpeakingText.trim().isNotEmpty) return;
    unawaited(_showSpeakingDecision(noSound: true));
  }

  bool _isNoSpeechError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('no_match') ||
        normalized.contains('no match') ||
        normalized.contains('no speech');
  }

  Future<void> _showSpeakingDecision({required bool noSound}) async {
    if (!mounted || !_isSpeakingChoice || _answered) return;
    if (_isSpeakingDecisionVisible) return;
    _isSpeakingDecisionVisible = true;
    try {
      final decision = await showDialog<_SpeakingDecision>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x7504193A),
        builder: (dialogContext) => _SpeakingDecisionDialog(
          noSound: noSound,
          onRetry: () =>
              Navigator.of(dialogContext).pop(_SpeakingDecision.retry),
          onSkip: () => Navigator.of(dialogContext).pop(_SpeakingDecision.skip),
        ),
      );
      if (!mounted) return;
      if (decision == _SpeakingDecision.retry) {
        setState(() {
          _recognizedSpeakingText = '';
          _speakingError = null;
          _isSpeakingResultCorrect = false;
        });
      } else if (decision == _SpeakingDecision.skip) {
        _skipCurrentSpeakingQuestion();
      }
    } finally {
      _isSpeakingDecisionVisible = false;
    }
  }

  void _skipCurrentSpeakingQuestion() {
    unawaited(_speechToText.cancel());
    _recordCurrentAnswer(ExerciseAnswerState.skipped);
    if (_questionIndex == _questions.length - 1) {
      unawaited(_finishSession());
      return;
    }
    setState(() {
      _questionTransitionDirection = 1;
      _questionIndex += 1;
      _selectedAnswer = null;
      _typingInput = const [];
      _isAnswerSubmitted = false;
      _isSpeakingRecording = false;
      _recognizedSpeakingText = '';
      _speakingError = null;
      _isSpeakingResultCorrect = false;
    });
  }

  Future<void> _confirmSkipSpeaking() async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x7504193A),
      builder: (dialogContext) => _SkipListeningDialog(
        title: context.l10n.text('reviewSkipSpeakingTitle'),
        description: context.l10n.text('reviewSkipSpeakingBody'),
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onSkip: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldSkip == true && mounted) _skipSpeakingQuestions();
  }

  void _skipSpeakingQuestions() {
    unawaited(_speechToText.cancel());
    final skippedFrom = _questionIndex;
    var nextIndex = _questionIndex + 1;
    while (nextIndex < _questions.length &&
        _questions[nextIndex].trainingExercise ==
            TrainingExerciseType.speaking) {
      nextIndex += 1;
    }
    for (var index = skippedFrom; index < nextIndex; index++) {
      _recordAnswerAt(index, ExerciseAnswerState.skipped);
    }
    if (nextIndex >= _questions.length) {
      unawaited(_finishSession());
      return;
    }
    setState(() {
      _questionTransitionDirection = 1;
      _questionIndex = nextIndex;
      _selectedAnswer = null;
      _typingInput = const [];
      _isAnswerSubmitted = false;
      _isSpeakingRecording = false;
      _recognizedSpeakingText = '';
      _speakingError = null;
      _isSpeakingResultCorrect = false;
    });
  }

  String _normalizeSpeech(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  Future<void> _confirmSkipListening() async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x7504193A),
      builder: (dialogContext) => _SkipListeningDialog(
        title: context.l10n.text('reviewSkipListeningTitle'),
        description: context.l10n.text('reviewSkipListeningBody'),
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onSkip: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldSkip == true && mounted) _skipListeningQuestions();
  }

  void _skipListeningQuestions() {
    final skippedFrom = _questionIndex;
    var nextIndex = _questionIndex + 1;
    while (nextIndex < _questions.length && _isListeningExerciseAt(nextIndex)) {
      nextIndex += 1;
    }
    for (var index = skippedFrom; index < nextIndex; index++) {
      _recordAnswerAt(index, ExerciseAnswerState.skipped);
    }
    if (nextIndex >= _questions.length) {
      unawaited(_finishSession());
      return;
    }
    setState(() {
      _questionTransitionDirection = 1;
      _questionIndex = nextIndex;
      _selectedAnswer = null;
      _typingInput = const [];
      _isAnswerSubmitted = false;
    });
  }

  bool _isListeningExerciseAt(int index) {
    final type = _questions[index].trainingExercise;
    return type == TrainingExerciseType.choiceOfThreeListening ||
        type == TrainingExerciseType.choiceOfFourListening;
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x7504193A),
      builder: (dialogContext) => _ExitPracticeDialog(
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onExit: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldExit == true && mounted) {
      unawaited(_speechToText.cancel());
      await _persistenceChain;
      final service = _progressService;
      final sessionId = _sessionId;
      if (service != null && sessionId != null) {
        await service.abandonSession(sessionId);
      }
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    unawaited(_speechToText.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _showIntro
        ? 0.0
        : (_questionIndex + 1) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _PracticeBackdrop()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(
                  children: [
                    _PracticeTopBar(
                      kicker: widget.kicker,
                      title:
                          widget.title ??
                          context.l10n.text('reviewDefaultTitle'),
                      onClose: _confirmExit,
                    ),
                    const SizedBox(height: 14),
                    _PracticeProgress(
                      label: _progressLabel,
                      progress: progress,
                      current: _showIntro ? 0 : _questionIndex + 1,
                      total: _questions.length,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: max(
                            24,
                            MediaQuery.paddingOf(context).bottom + 18,
                          ),
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            reverseDuration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (currentChild, previousChildren) {
                              return ClipRect(
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                ),
                              );
                            },
                            transitionBuilder: (child, animation) {
                              final isIncoming =
                                  animation.status != AnimationStatus.reverse;
                              final direction = _questionTransitionDirection
                                  .toDouble();
                              final slide =
                                  Tween<Offset>(
                                    begin: Offset(
                                      (isIncoming ? direction : -direction) *
                                          .22,
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                      reverseCurve: Curves.easeInCubic,
                                    ),
                                  );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: _showIntro
                                ? _PracticeIntroCard(
                                    key: const ValueKey('practice-intro'),
                                    words: _introWords,
                                    onStart: _startPractice,
                                  )
                                : Column(
                                    key: ValueKey(
                                      'practice-question-$_questionIndex',
                                    ),
                                    children: [
                                      if (_isListeningChoice)
                                        _ListeningChoiceCard(
                                          question: _question,
                                          selectedAnswer: _selectedAnswer,
                                          isSubmitted: _answered,
                                          onSelected: _selectAnswer,
                                          onSubmit: _submitAnswer,
                                          onPlay: _playWord,
                                          onSkip: _confirmSkipListening,
                                        )
                                      else if (_isFourListeningChoice)
                                        _ChoiceOfFourListeningCard(
                                          question: _question,
                                          selectedAnswer: _selectedAnswer,
                                          onSelected: _selectAnswer,
                                          onPlay: _playWord,
                                          onPlaySlow: _playWordSlow,
                                          onSkip: _confirmSkipListening,
                                        )
                                      else if (_isTypingChoice)
                                        _TypingChallengeCard(
                                          question: _question,
                                          input: _typingInput,
                                          isSubmitted: _answered,
                                          isCorrect: _isCorrect,
                                          onCharacterSelected:
                                              _selectTypingCharacter,
                                          onRemoveCharacter:
                                              _removeLastTypingCharacter,
                                          onPlay: _playWord,
                                        )
                                      else if (_isSpeakingChoice)
                                        _SpeakingCard(
                                          question: _question,
                                          isRecording: _isSpeakingRecording,
                                          isSubmitted: _answered,
                                          recognizedText:
                                              _recognizedSpeakingText,
                                          isCorrect: _isSpeakingResultCorrect,
                                          errorMessage: _speakingError,
                                          onRecord: _toggleSpeakingRecording,
                                          onCheck: _checkSpeakingResult,
                                          onPlay: _playWord,
                                          onPlaySlow: _playWordSlow,
                                          onSkip: _confirmSkipSpeaking,
                                        )
                                      else
                                        _ChoiceOfFourCard(
                                          question: _question,
                                          selectedAnswer: _selectedAnswer,
                                          onSelected: _selectAnswer,
                                          onPlay: _playWord,
                                        ),
                                      if (_answered &&
                                          !_isFeedbackSheetVisible) ...[
                                        const SizedBox(height: 14),
                                        _ContinueButton(
                                          onPressed: () =>
                                              unawaited(_continue()),
                                          isLast:
                                              _questionIndex ==
                                              _questions.length - 1,
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _audioLabel(BuildContext context, int index) {
  return context.l10n.text(
    'reviewAudioOption',
    values: {'letter': String.fromCharCode(65 + index)},
  );
}

String _audioLabelFor(
  BuildContext context,
  PracticeExercise question,
  ExerciseWord word,
) {
  final index = question.variants.indexWhere(
    (variant) => variant.id == word.id,
  );
  return _audioLabel(context, index < 0 ? 0 : index);
}

String _normalizeTypingWord(String value) {
  return value.toLowerCase().replaceAll(RegExp('[^a-z0-9 ]'), '');
}

String _typingInputWithVisibleSpaces(List<String> input) {
  final lastCharacterIndex = input.lastIndexWhere(
    (character) => character != ' ',
  );
  return input.asMap().entries.map((entry) {
    final index = entry.key;
    final character = entry.value;
    if (character == ' ' && index > lastCharacterIndex) return '_';
    return character;
  }).join();
}

class _PracticeBackdrop extends StatelessWidget {
  const _PracticeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_word_study.png',
      key: const ValueKey('review-practice-background'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
    );
  }
}

class _PracticeTopBar extends StatelessWidget {
  const _PracticeTopBar({
    required this.kicker,
    required this.title,
    required this.onClose,
  });

  final String kicker;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Semantics(
              button: true,
              label: context.l10n.text('reviewExitAction'),
              child: IconButton(
                key: const Key('review-practice-close-button'),
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
                style: IconButton.styleFrom(
                  fixedSize: const Size(44, 44),
                  backgroundColor: Colors.white.withValues(alpha: .88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.white),
                  ),
                  shadowColor: const Color(0x332C65A4),
                  elevation: 5,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kicker,
                    style: const TextStyle(
                      color: Color(0xFF176DEB),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
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

class _PracticeProgress extends StatelessWidget {
  const _PracticeProgress({
    required this.label,
    required this.progress,
    required this.current,
    required this.total,
  });

  final String label;
  final double progress;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF176DEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$current / $total',
                style: const TextStyle(
                  color: Color(0xFF176DEB),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            key: const Key('review-practice-progress-track'),
            height: 23,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .66),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: .74)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: ColoredBox(
                color: const Color(0xFFD7E9FA),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: progress.clamp(0, 1).toDouble()),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      // Keep the first question visually noticeable like the
                      // reference, while still advancing on every question.
                      final visibleProgress = value <= 0
                          ? 0.0
                          : (.07 + (value * .93)).clamp(0.0, 1.0);
                      return FractionallySizedBox(
                        key: const Key('review-practice-progress-fill'),
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
          ),
        ],
      ),
    );
  }
}

class _PracticeIntroCard extends StatelessWidget {
  const _PracticeIntroCard({
    required this.words,
    required this.onStart,
    super.key,
  });

  final List<ExerciseWord> words;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D26448B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    context.l10n.text('reviewIntroInstruction'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 310,
                    child: Text(
                      context.l10n.text('reviewIntroBody'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5679B2),
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            const _IntroDashedDivider(),
            const SizedBox(height: 14),
            for (var index = 0; index < words.length; index++) ...[
              _IntroWordRow(word: words[index]),
              if (index != words.length - 1) const SizedBox(height: 9),
            ],
            const SizedBox(height: 14),
            _StartPracticeButton(onPressed: onStart),
          ],
        ),
      ),
    );
  }
}

class _IntroDashedDivider extends StatelessWidget {
  const _IntroDashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const gapWidth = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + gapWidth))
            .floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < dashCount; index++)
              const SizedBox(
                width: dashWidth,
                height: 1,
                child: ColoredBox(color: Color(0xFFBBD6F5)),
              ),
          ],
        );
      },
    );
  }
}

class _IntroWordRow extends StatelessWidget {
  const _IntroWordRow({required this.word});

  final ExerciseWord word;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E7F8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word.writing,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            word.translation,
            textAlign: TextAlign.left,
            style: const TextStyle(color: Color(0xFF5679B2), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _StartPracticeButton extends StatelessWidget {
  const _StartPracticeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B94FF), Color(0xFF1C6FF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1564EE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D1769EA),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 30,
            top: 14,
            child: Text(
              '✦',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const Positioned(
            left: 17,
            top: 28,
            child: Text(
              '✦',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          const Positioned(
            right: 27,
            bottom: 12,
            child: Text(
              '✦',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Positioned(
            right: 17,
            bottom: 25,
            child: Text(
              '✦',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          Positioned.fill(
            child: TextButton(
              key: const Key('review-practice-start-button'),
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(context.l10n.text('reviewStart')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningChoiceCard extends StatelessWidget {
  const _ListeningChoiceCard({
    required this.question,
    required this.selectedAnswer,
    this.isSubmitted = false,
    required this.onSelected,
    required this.onSubmit,
    required this.onPlay,
    required this.onSkip,
  });

  final PracticeExercise question;
  final ExerciseWord? selectedAnswer;
  // Nullable for hot-reload compatibility with instances created before this
  // field was introduced. A missing value is equivalent to an unanswered item.
  final bool? isSubmitted;
  final ValueChanged<ExerciseWord> onSelected;
  final VoidCallback onSubmit;
  final ValueChanged<ExerciseWord> onPlay;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedAnswer != null;
    final submitted = isSubmitted ?? false;
    final isCorrect = selectedAnswer?.id == question.word.id;
    final status = !hasSelection
        ? context.l10n.text(
            'reviewChooseAudioCount',
            values: {'count': '${question.variants.length}'},
          )
        : !submitted
        ? context.l10n.text('reviewAudioSelectedHint')
        : isCorrect
        ? context.l10n.text('reviewAudioCorrect')
        : context.l10n.text('reviewAudioWrong');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // Keep the question surface opaque so the blue-to-light backdrop
            // transition cannot bleed through the card as a horizontal seam.
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0x1208397A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D26448B),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'LISTENING MATCH',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.text('reviewChooseCorrectAudio'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7D8EA8),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        question.word.writing,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 44,
                          height: .95,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.word.translation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6E83A1),
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF5C7493),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _CardDivider(),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < question.variants.length;
                      index++
                    ) ...[
                      _ListeningAudioOption(
                        key: ValueKey(
                          'listening-word-${question.variants[index].id}',
                        ),
                        label: _audioLabel(context, index),
                        option: question.variants[index],
                        correctAnswer: question.word,
                        selectedAnswer: selectedAnswer,
                        isSubmitted: submitted,
                        onTap: () {
                          onPlay(question.variants[index]);
                          if (!submitted) onSelected(question.variants[index]);
                        },
                      ),
                      if (index != question.variants.length - 1)
                        const SizedBox(height: 12),
                    ],
                    if (hasSelection && !submitted) ...[
                      const SizedBox(height: 14),
                      _SubmitAnswerButton(onPressed: onSubmit),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!submitted) ...[
          const SizedBox(height: 14),
          _CannotHearButton(onPressed: onSkip),
        ],
      ],
    );
  }
}

class _ListeningAudioOption extends StatelessWidget {
  const _ListeningAudioOption({
    required this.label,
    required this.option,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.isSubmitted,
    required this.onTap,
    super.key,
  });

  final String label;
  final ExerciseWord option;
  final ExerciseWord correctAnswer;
  final ExerciseWord? selectedAnswer;
  final bool isSubmitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final correct = option.id == correctAnswer.id;
    final selected = selectedAnswer?.id == option.id;
    final showCorrect = isSubmitted && correct;
    final showWrong = isSubmitted && selected && !correct;
    final highlighted = showCorrect || showWrong;
    final background = showCorrect
        ? const LinearGradient(
            colors: [Color(0xFF11C932), Color(0xFF22C347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : showWrong
        ? const LinearGradient(
            colors: [Color(0xFFB7331B), Color(0xFFDA4D2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final caption = showCorrect
        ? context.l10n.text(
            'reviewCorrectPronunciation',
            values: {'word': correctAnswer.writing},
          )
        : showWrong
        ? context.l10n.text('reviewSelectedAudio')
        : context.l10n.text('reviewTapToListen');

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $caption',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background == null ? const Color(0xFFF8FBFF) : null,
            gradient: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlighted
                  ? Colors.transparent
                  : selected
                  ? const Color(0x29155CFF)
                  : const Color(0xFFE7EEF8),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D27477F),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted
                      ? const Color(0x2EFFFFFF)
                      : const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: highlighted ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: highlighted
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: TextStyle(
                        color: highlighted
                            ? const Color(0xD6FFFFFF)
                            : const Color(0xFF7185A2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AudioWave(highlighted: highlighted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioWave extends StatelessWidget {
  const _AudioWave({required this.highlighted});

  final bool highlighted;

  static const _barHeights = [9.0, 16.0, 22.0, 13.0, 18.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < _barHeights.length; index++) ...[
            Container(
              width: 4,
              height: _barHeights[index],
              decoration: BoxDecoration(
                color: highlighted
                    ? const Color(0xC7FFFFFF)
                    : const Color(0xFF8BB7FF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (index != _barHeights.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}

class _SpeakingCard extends StatelessWidget {
  const _SpeakingCard({
    required this.question,
    required this.isRecording,
    required this.isSubmitted,
    required this.recognizedText,
    required this.isCorrect,
    required this.errorMessage,
    required this.onRecord,
    required this.onCheck,
    required this.onPlay,
    required this.onPlaySlow,
    required this.onSkip,
  });

  final PracticeExercise question;
  final bool isRecording;
  final bool isSubmitted;
  final String recognizedText;
  final bool isCorrect;
  final String? errorMessage;
  final Future<void> Function() onRecord;
  final VoidCallback onCheck;
  final Future<void> Function(ExerciseWord) onPlay;
  final Future<void> Function(ExerciseWord) onPlaySlow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final hasTranscript = recognizedText.trim().isNotEmpty;
    final status = isSubmitted
        ? context.l10n.text(
            isCorrect
                ? 'reviewPronunciationCorrect'
                : 'reviewPronunciationRetry',
          )
        : isRecording
        ? context.l10n.text('reviewRecordingActive')
        : hasTranscript
        ? context.l10n.text('reviewRecordingReady')
        : context.l10n.text('reviewRecordingPrompt');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0x1208397A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D26448B),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
                child: Column(
                  children: [
                    Text(
                      context.l10n.text('reviewPronounceWord'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7D8EA8),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        question.word.writing,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ReviewSlowAudioButton(
                          onTap: () => onPlaySlow(question.word),
                        ),
                        const SizedBox(width: 18),
                        _ReviewAudioButton(onTap: () => onPlay(question.word)),
                      ],
                    ),
                  ],
                ),
              ),
              const _QuestionAnswerDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 38),
                child: Column(
                  children: [
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isRecording
                            ? const Color(0xFF3B86D8)
                            : const Color(0xFF8B9AB0),
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SpeakingRecordButton(
                      key: const ValueKey('speaking-record-button'),
                      isRecording: isRecording,
                      isSubmitted: isSubmitted,
                      onTap: onRecord,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE85B49),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (hasTranscript && !isRecording && !isSubmitted) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE8F8)),
                        ),
                        child: Text(
                          recognizedText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => onPlay(question.word),
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: Text(context.l10n.text('listenAgain')),
                          ),
                          TextButton.icon(
                            onPressed: onRecord,
                            icon: const Icon(Icons.mic_none_rounded, size: 18),
                            label: Text(context.l10n.text('reviewSpeakAgain')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: onCheck,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(context.l10n.text('check')),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF20C873),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isSubmitted) ...[
                      const SizedBox(height: 10),
                      Text(
                        recognizedText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isCorrect
                              ? const Color(0xFF18A965)
                              : const Color(0xFFE85B49),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isSubmitted) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B68B5),
                backgroundColor: const Color(0xFFEAF2FF),
                side: const BorderSide(color: Color(0xFFC9DCF6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .1,
                ),
              ),
              child: Text(context.l10n.text('reviewCannotSpeak')),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeakingRecordButton extends StatefulWidget {
  const _SpeakingRecordButton({
    required this.isRecording,
    required this.isSubmitted,
    required this.onTap,
    super.key,
  });

  final bool isRecording;
  final bool isSubmitted;
  final Future<void> Function() onTap;

  @override
  State<_SpeakingRecordButton> createState() => _SpeakingRecordButtonState();
}

class _SpeakingRecordButtonState extends State<_SpeakingRecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isRecording) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SpeakingRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _controller.stop();
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
    final active = widget.isRecording;
    final submitted = widget.isSubmitted;
    Future<void> handleTap() async {
      if (submitted) return;
      await widget.onTap();
    }

    return Semantics(
      button: true,
      label: context.l10n.text(
        submitted
            ? 'reviewRecorded'
            : active
            ? 'reviewStopRecording'
            : 'reviewStartRecording',
      ),
      child: GestureDetector(
        onTap: submitted ? null : handleTap,
        child: SizedBox(
          width: 250,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = active ? 1.0 + (_controller.value * .08) : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (active
                                ? const Color(0xFF56D8FF)
                                : const Color(0xFF56D8FF))
                            .withValues(alpha: active ? .18 : .10),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 28,
                child: Icon(
                  Icons.near_me_rounded,
                  color: const Color(0xFFF4AC24),
                  size: 52,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: submitted
                        ? const [Color(0xFF18B865), Color(0xFF28CE52)]
                        : const [Color(0xFF5EC3FF), Color(0xFF489EEC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x474092E2),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Icon(
                  submitted
                      ? Icons.check_rounded
                      : active
                      ? Icons.stop_rounded
                      : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 62,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceOfFourListeningCard extends StatelessWidget {
  const _ChoiceOfFourListeningCard({
    required this.question,
    required this.selectedAnswer,
    required this.onSelected,
    required this.onPlay,
    required this.onPlaySlow,
    required this.onSkip,
  });

  final PracticeExercise question;
  final ExerciseWord? selectedAnswer;
  final ValueChanged<ExerciseWord> onSelected;
  final Future<void> Function(ExerciseWord) onPlay;
  final Future<void> Function(ExerciseWord) onPlaySlow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final answered = selectedAnswer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0x1208397A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D26448B),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                child: Column(
                  children: [
                    Text(
                      context.l10n.text('reviewListenChooseTranslation'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7D8EA8),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ReviewSlowAudioButton(
                          onTap: () => onPlaySlow(question.word),
                        ),
                        const SizedBox(width: 18),
                        _ReviewAudioButton(onTap: () => onPlay(question.word)),
                      ],
                    ),
                  ],
                ),
              ),
              const _QuestionAnswerDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < question.variants.length;
                      index++
                    ) ...[
                      _ListeningTranslationOption(
                        key: ValueKey(
                          'choice-four-listening-${question.variants[index].id}',
                        ),
                        index: index,
                        option: question.variants[index],
                        correctAnswer: question.word,
                        selectedAnswer: selectedAnswer,
                        onTap: () => onSelected(question.variants[index]),
                      ),
                      if (index != question.variants.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!answered) ...[
          const SizedBox(height: 14),
          _CannotHearButton(onPressed: onSkip),
        ],
      ],
    );
  }
}

class _ReviewSlowAudioButton extends StatefulWidget {
  const _ReviewSlowAudioButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  State<_ReviewSlowAudioButton> createState() => _ReviewSlowAudioButtonState();
}

class _ReviewSlowAudioButtonState extends State<_ReviewSlowAudioButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _controller.repeat(reverse: true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('choice-four-listening-slow'),
      button: true,
      label: context.l10n.text('reviewSlowPronunciationSemantics'),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: _isPlaying
                ? const Color(0xFFE0ECFF)
                : const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: _isPlaying ? AppColors.primary : const Color(0xFFDCE8FF),
            ),
            boxShadow: _isPlaying
                ? const [
                    BoxShadow(
                      color: Color(0x33155CFF),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                child: SvgPicture.asset(
                  'assets/svgs/slow.svg',
                  width: 26,
                  height: 26,
                ),
                builder: (context, child) {
                  final progress = Curves.easeInOut.transform(
                    _controller.value,
                  );
                  return Transform.translate(
                    offset: Offset(progress * 7, 0),
                    child: child,
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                '0.2×',
                style: TextStyle(
                  color: _isPlaying
                      ? AppColors.primary
                      : const Color(0xFF3B68B5),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewAudioButton extends StatefulWidget {
  const _ReviewAudioButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  State<_ReviewAudioButton> createState() => _ReviewAudioButtonState();
}

class _ReviewAudioButtonState extends State<_ReviewAudioButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _controller.repeat(reverse: true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('choice-four-listening-normal'),
      button: true,
      label: context.l10n.text('reviewNormalPronunciationSemantics'),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(27)),
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3D155CFF),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: .88, end: 1.08).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _CannotHearButton extends StatelessWidget {
  const _CannotHearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3B68B5),
          backgroundColor: const Color(0xFFEAF2FF),
          side: const BorderSide(color: Color(0xFFC9DCF6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: .1,
          ),
        ),
        child: Text(context.l10n.text('reviewCannotListen')),
      ),
    );
  }
}

class _ListeningTranslationOption extends StatelessWidget {
  const _ListeningTranslationOption({
    required this.index,
    required this.option,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.onTap,
    super.key,
  });

  final int index;
  final ExerciseWord option;
  final ExerciseWord correctAnswer;
  final ExerciseWord? selectedAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final answered = selectedAnswer != null;
    final selected = selectedAnswer?.id == option.id;
    final correct = option.id == correctAnswer.id;
    final showCorrect = answered && correct;
    final showWrong = answered && selected && !correct;
    final dimmed = answered && !showCorrect && !showWrong;
    final caption = !answered
        ? context.l10n.text('reviewTapToSelect')
        : showCorrect
        ? context.l10n.text(selected ? 'correct' : 'reviewCorrectOption')
        : showWrong
        ? context.l10n.text('reviewYourSelection')
        : context.l10n.text('reviewNotSelected');
    final background = showCorrect
        ? const Color(0xFFEAFBF1)
        : showWrong
        ? const Color(0xFFFFF0ED)
        : const Color(0xFFF5F9FF);
    final border = showCorrect
        ? const Color(0xFFBDEED1)
        : showWrong
        ? const Color(0xFFF5CEC7)
        : const Color(0xFFE1EAF6);
    final accent = showCorrect
        ? const Color(0xFF18B865)
        : showWrong
        ? const Color(0xFFEC5B42)
        : const Color(0xFFEDF4FF);
    final textColor = showCorrect
        ? const Color(0xFF168A5A)
        : showWrong
        ? const Color(0xFFC04738)
        : AppColors.textPrimary;
    final secondaryColor = showCorrect
        ? const Color(0xFF39916D)
        : showWrong
        ? const Color(0xFFC16559)
        : const Color(0xFF7488A4);

    return Semantics(
      button: !answered,
      selected: selected,
      label: option.translation,
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dimmed ? .58 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D11397A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: showCorrect || showWrong
                          ? Colors.white
                          : const Color(0xFF155CFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.translation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        caption,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    showCorrect
                        ? Icons.check_rounded
                        : showWrong
                        ? Icons.close_rounded
                        : answered
                        ? null
                        : Icons.chevron_right_rounded,
                    color: showCorrect
                        ? const Color(0xFF18B865)
                        : showWrong
                        ? const Color(0xFFEC5B42)
                        : const Color(0xFF84A7D4),
                    size: 24,
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

class _ChoiceOfFourCard extends StatelessWidget {
  const _ChoiceOfFourCard({
    required this.question,
    required this.selectedAnswer,
    required this.onSelected,
    required this.onPlay,
  });

  final PracticeExercise question;
  final ExerciseWord? selectedAnswer;
  final ValueChanged<ExerciseWord> onSelected;
  final ValueChanged<ExerciseWord> onPlay;

  @override
  Widget build(BuildContext context) {
    final isFromEng =
        question.trainingExercise == TrainingExerciseType.choiceOfFourFromEng;
    final prompt = context.l10n.text(
      isFromEng ? 'reviewChooseEnglishWord' : 'reviewChooseTranslation',
    );
    final questionText = isFromEng
        ? question.word.translation
        : question.word.writing;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x1208397A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D26448B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: SizedBox(
              height: 154,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 44, right: 56),
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prompt,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF7D8EA8),
                                fontSize: 12,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                questionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 36,
                                  height: .95,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -2,
                                ),
                              ),
                            ),
                            if (!isFromEng &&
                                question.word.transliteration.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                question.word.transliteration,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6E83A1),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 1,
                    right: 0,
                    child: IconButton(
                      onPressed: () => onPlay(question.word),
                      icon: const Icon(Icons.volume_up_rounded, size: 21),
                      color: AppColors.primary,
                      style: IconButton.styleFrom(
                        fixedSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFEDF3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _QuestionAnswerDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text(
                    selectedAnswer == null ? 'chooseOneAnswer' : 'reviewResult',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF7589A5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                for (
                  var index = 0;
                  index < question.variants.length;
                  index++
                ) ...[
                  _AnswerOption(
                    index: index,
                    option: question.variants[index],
                    correctAnswer: question.word,
                    selectedAnswer: selectedAnswer,
                    isFromEng: isFromEng,
                    onTap: () => onSelected(question.variants[index]),
                  ),
                  if (index != question.variants.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.index,
    required this.option,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.isFromEng,
    required this.onTap,
  });

  final int index;
  final ExerciseWord option;
  final ExerciseWord correctAnswer;
  final ExerciseWord? selectedAnswer;
  final bool isFromEng;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final answered = selectedAnswer != null;
    final selected = selectedAnswer?.id == option.id;
    final correct = correctAnswer.id == option.id;
    final showCorrect = answered && correct;
    final showWrong = answered && selected && !correct;
    final dimmed = answered && !showCorrect && !showWrong;
    final answerText = isFromEng ? option.writing : option.translation;
    final caption = !answered
        ? context.l10n.text('reviewTapToSelect')
        : showCorrect
        ? context.l10n.text(selected ? 'correct' : 'reviewCorrectOption')
        : showWrong
        ? context.l10n.text('reviewYourAnswer')
        : context.l10n.text('reviewNotSelected');
    final itemColor = showCorrect
        ? const Color(0xFFE9FBF2)
        : showWrong
        ? const Color(0xFFFFF0EE)
        : const Color(0xFFF7FAFF);
    final itemBorder = showCorrect
        ? const Color(0xFFC8F0DD)
        : showWrong
        ? const Color(0xFFF5D1CC)
        : const Color(0xFFE5EDF8);
    final accent = showCorrect
        ? const Color(0xFF20BF78)
        : showWrong
        ? const Color(0xFFE85B49)
        : const Color(0xFFEAF1FF);
    final primaryText = showCorrect
        ? const Color(0xFF128356)
        : showWrong
        ? const Color(0xFFB74335)
        : AppColors.textPrimary;
    final secondaryText = showCorrect
        ? const Color(0xFF39916D)
        : showWrong
        ? const Color(0xFFC16559)
        : const Color(0xFF8394AB);

    return Semantics(
      button: !answered,
      selected: selected,
      label: answerText,
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dimmed ? .48 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: itemColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: itemBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A27477F),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: showCorrect || showWrong
                          ? Colors.white
                          : const Color(0xFF155CFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answerText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: showCorrect || showWrong
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            showCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        )
                      : answered
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF8DA2BE),
                          size: 20,
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

class _TypingChallengeCard extends StatefulWidget {
  const _TypingChallengeCard({
    required this.question,
    required this.input,
    required this.isSubmitted,
    required this.isCorrect,
    required this.onCharacterSelected,
    required this.onRemoveCharacter,
    required this.onPlay,
  });

  final PracticeExercise question;
  final List<String> input;
  final bool isSubmitted;
  final bool isCorrect;
  final ValueChanged<String> onCharacterSelected;
  final VoidCallback onRemoveCharacter;
  final ValueChanged<ExerciseWord> onPlay;

  @override
  State<_TypingChallengeCard> createState() => _TypingChallengeCardState();
}

class _TypingChallengeCardState extends State<_TypingChallengeCard> {
  late List<String> _characterOrder;

  @override
  void initState() {
    super.initState();
    _characterOrder = _buildCharacterOrder(widget.question);
  }

  @override
  void didUpdateWidget(covariant _TypingChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.word.id != widget.question.word.id ||
        oldWidget.question.word.writing != widget.question.word.writing) {
      _characterOrder = _buildCharacterOrder(widget.question);
    }
  }

  List<String> _buildCharacterOrder(PracticeExercise question) {
    final characters = <String>{
      for (final character in _normalizeTypingWord(
        question.word.writing,
      ).split(''))
        if (character != ' ') character,
    }.toList();
    characters.shuffle(Random());
    return characters;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final input = widget.input;
    final isSubmitted = widget.isSubmitted;
    final isCorrect = widget.isCorrect;
    final onCharacterSelected = widget.onCharacterSelected;
    final onRemoveCharacter = widget.onRemoveCharacter;
    final onPlay = widget.onPlay;
    final target = _normalizeTypingWord(question.word.writing);
    final targetCharacters = target.split('');
    final uniqueCharacters = _characterOrder;
    final usedCounts = <String, int>{};
    for (final character in input) {
      usedCounts[character] = (usedCounts[character] ?? 0) + 1;
    }
    final submittedWrong = isSubmitted && !isCorrect;
    final description = context.l10n.text(
      !isSubmitted
          ? 'reviewTypingInstruction'
          : isCorrect
          ? 'reviewTypingCorrect'
          : 'reviewTypingWrong',
    );
    final answerLabel = context.l10n.text(
      !isSubmitted
          ? 'reviewBuildingWord'
          : isCorrect
          ? 'reviewBuiltWord'
          : 'reviewResult',
    );
    final answerMeta = !isSubmitted
        ? '${input.length} / ${targetCharacters.length}'
        : isCorrect
        ? '${targetCharacters.length} / ${targetCharacters.length}'
        : context.l10n.text('reviewSpellingWrong');
    final visibleInput = isSubmitted
        ? input.join()
        : _typingInputWithVisibleSpaces(input);
    final Widget answerDisplay;
    if (!isSubmitted && input.isEmpty) {
      answerDisplay = Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.text('reviewNoCharactersSelected'),
          style: const TextStyle(
            color: Color(0xFFB1BFD2),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (submittedWrong) {
      answerDisplay = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AutoSizingSingleLineTypingText(
            text: visibleInput,
            textKey: const ValueKey('typing-composing-text'),
            style: const TextStyle(
              color: Color(0xFFE85A43),
              fontSize: 38,
              height: 1.04,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 4,
            ),
          ),
          const SizedBox(height: 10),
          _AutoSizingSingleLineTypingText(
            text: question.word.writing,
            style: const TextStyle(
              color: Color(0xFF26C15D),
              fontSize: 32,
              height: 1.04,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    } else {
      answerDisplay = Align(
        alignment: Alignment.centerLeft,
        child: _AutoSizingSingleLineTypingText(
          text: visibleInput,
          textKey: const ValueKey('typing-composing-text'),
          style: TextStyle(
            color: isCorrect ? const Color(0xFF26C15D) : AppColors.textPrimary,
            fontSize: 42,
            height: 1.04,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.8,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _typingCardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('reviewEnterTranslation'),
                      style: const TextStyle(
                        color: Color(0xFF7D90AC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AutoSizingTypingTranslation(
                      text: question.word.translation,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF7E90AB),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => onPlay(question.word),
                icon: Icon(
                  isSubmitted
                      ? Icons.volume_up_rounded
                      : Icons.lock_outline_rounded,
                  size: 22,
                ),
                color: const Color(0xFF1971FF),
                style: IconButton.styleFrom(
                  fixedSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFFEDF4FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _typingCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      answerLabel,
                      style: const TextStyle(
                        color: Color(0xFF7D90AC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (!isSubmitted)
                    IconButton(
                      key: const ValueKey('typing-remove-last'),
                      onPressed: input.isEmpty ? null : onRemoveCharacter,
                      tooltip: context.l10n.text('reviewDeleteLastCharacter'),
                      icon: const Icon(Icons.backspace_outlined, size: 18),
                      color: const Color(0xFF1971FF),
                      disabledColor: const Color(0xFF1971FF),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFEFF4FF),
                        disabledBackgroundColor: const Color(0xFFEFF4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      answerMeta,
                      style: const TextStyle(
                        color: Color(0xFF1971FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                // Keep the unanswered state as compact as the selected state.
                // A wrong result needs a little more room for its two lines.
                height: submittedWrong ? 92 : 52,
                child: answerDisplay,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.text(
                  !isSubmitted
                      ? 'reviewTypingPendingHint'
                      : isCorrect
                      ? 'reviewTypingCompleteHint'
                      : 'reviewTypingWrongHint',
                ),
                style: const TextStyle(
                  color: Color(0xFF93A2B7),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (!submittedWrong) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _typingCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text(
                        isSubmitted
                            ? 'reviewCharacterSet'
                            : 'reviewAvailableCharacters',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF7D90AC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        context.l10n.text(
                          isSubmitted
                              ? 'reviewCharactersUsed'
                              : 'reviewCharactersNeededOnly',
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF95A6BC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final character in uniqueCharacters)
                      _TypingCharacterChip(
                        character: character,
                        count: targetCharacters
                            .where((item) => item == character)
                            .length,
                        usedCount: usedCounts[character] ?? 0,
                        enabled: !isSubmitted,
                        onTap: () => onCharacterSelected(character),
                      ),
                    _TypingSpaceChip(
                      count: targetCharacters
                          .where((item) => item == ' ')
                          .length,
                      usedCount: usedCounts[' '] ?? 0,
                      enabled: !isSubmitted,
                      onTap: () => onCharacterSelected(' '),
                    ),
                  ],
                ),
                if (!isSubmitted) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.text('reviewCharacterSetHint'),
                    style: const TextStyle(
                      color: Color(0xFF7E90AB),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AutoSizingTypingTranslation extends StatelessWidget {
  const _AutoSizingTypingTranslation({required this.text});

  static const _maximumFontSize = 34.0;
  static const _minimumFontSize = 16.0;
  static const _style = TextStyle(
    color: AppColors.textPrimary,
    fontSize: _maximumFontSize,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
  );

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var fontSize = _maximumFontSize;
        var fitsInTwoLines = false;
        while (fontSize >= _minimumFontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: _style.copyWith(fontSize: fontSize),
            ),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.maybeLocaleOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          if (!painter.didExceedMaxLines) {
            fitsInTwoLines = true;
            break;
          }
          fontSize -= 1;
        }

        final resolvedFontSize = fontSize.clamp(
          _minimumFontSize,
          _maximumFontSize,
        );
        return Text(
          text,
          key: const ValueKey('typing-translation'),
          maxLines: fitsInTwoLines ? 2 : null,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: _style.copyWith(fontSize: resolvedFontSize),
        );
      },
    );
  }
}

class _AutoSizingSingleLineTypingText extends StatelessWidget {
  const _AutoSizingSingleLineTypingText({
    required this.text,
    required this.style,
    this.textKey,
  });

  static const _minimumFontSize = 10.0;

  final String text;
  final TextStyle style;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maximumFontSize = style.fontSize ?? 42;
        var fontSize = maximumFontSize;
        while (fontSize > _minimumFontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontSize: fontSize),
            ),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.maybeLocaleOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          if (!painter.didExceedMaxLines) break;
          fontSize -= 1;
        }

        return Text(
          text,
          key: textKey,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: style.copyWith(
            fontSize: fontSize.clamp(_minimumFontSize, maximumFontSize),
          ),
        );
      },
    );
  }
}

BoxDecoration _typingCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: const [
      BoxShadow(
        color: Color(0x24072762),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );
}

class _TypingCharacterChip extends StatelessWidget {
  const _TypingCharacterChip({
    required this.character,
    required this.count,
    required this.usedCount,
    required this.enabled,
    required this.onTap,
  });

  final String character;
  final int count;
  final int usedCount;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exhausted = usedCount >= count;
    final remainingCount = (count - usedCount).clamp(0, count);
    return Opacity(
      opacity: exhausted ? .34 : 1,
      child: GestureDetector(
        onTap: enabled && !exhausted ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Keep the chip's bounds explicit. An AnimatedContainer here can
            // retain an older unbounded constraint tween during hot reload,
            // which makes Flutter fail when interpolating to these fixed
            // dimensions. The chip itself does not animate any layout
            // property, so a regular Container is sufficient.
            Container(
              width: 44,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E9F8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12072762),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                character,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (remainingCount > 1)
              Positioned(
                top: -7,
                right: -6,
                child: Container(
                  key: ValueKey('typing-count-$character'),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7CFF),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$remainingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

class _TypingSpaceChip extends StatelessWidget {
  const _TypingSpaceChip({
    required this.count,
    required this.usedCount,
    required this.enabled,
    required this.onTap,
  });

  final int count;
  final int usedCount;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exhausted = count == 0 || usedCount >= count;
    return Opacity(
      opacity: exhausted ? .38 : 1,
      child: GestureDetector(
        key: const ValueKey('typing-space'),
        onTap: enabled && !exhausted ? onTap : null,
        child: Container(
          width: 112,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E9F8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12072762),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.space_bar_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 5),
              const Text(
                'space',
                style: TextStyle(
                  color: AppColors.textPrimary,
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
}

class _TypingWrongAnswerSheet extends StatelessWidget {
  const _TypingWrongAnswerSheet({
    required this.question,
    required this.onPlay,
    required this.onContinue,
    required this.isLast,
  });

  final PracticeExercise question;
  final ValueChanged<ExerciseWord> onPlay;
  final VoidCallback onContinue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          AppBottomSheetTitle(
            title: context.l10n.text('correctAnswer'),
            icon: Icons.check_rounded,
            color: Color(0xFF18B865),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text:
                  '${context.l10n.text('reviewWordMeans', values: {'word': question.word.writing})} ',
              children: [
                TextSpan(
                  text: question.word.translation,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '. ${context.l10n.text('reviewListenMemoryHint')}',
                ),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFF7E90AB),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => onPlay(question.word),
              icon: const Icon(Icons.volume_up_rounded),
              color: const Color(0xFF1971FF),
              style: IconButton.styleFrom(
                fixedSize: const Size(36, 36),
                backgroundColor: const Color(0xFFEDF4FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ContinueButton(onPressed: onContinue, isLast: isLast),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: Color(0x14071A3D)),
    );
  }
}

class _QuestionAnswerDivider extends StatelessWidget {
  const _QuestionAnswerDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      child: ColoredBox(color: Color(0xFFD7E1ED)),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed, required this.isLast});

  final VoidCallback onPressed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF20C873),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 19),
            Text(context.l10n.text(isLast ? 'completed' : 'continue')),
            const Icon(Icons.auto_awesome_rounded, size: 19),
          ],
        ),
      ),
    );
  }
}

class _SubmitAnswerButton extends StatelessWidget {
  const _SubmitAnswerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF20C873),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
        child: Text(context.l10n.text('reviewChoose')),
      ),
    );
  }
}

class _ListeningWrongAnswerSheet extends StatelessWidget {
  const _ListeningWrongAnswerSheet({
    required this.question,
    required this.selectedAnswer,
    required this.onPlay,
    required this.onContinue,
    required this.isLast,
  });

  final PracticeExercise question;
  final ExerciseWord selectedAnswer;
  final ValueChanged<ExerciseWord> onPlay;
  final VoidCallback onContinue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          AppBottomSheetTitle(
            title: context.l10n.text('reviewCompareAudioTitle'),
            icon: Icons.volume_up_rounded,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              text: '${context.l10n.text('reviewTargetWordPrefix')} ',
              children: [
                TextSpan(
                  text: question.word.writing,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '. ${context.l10n.text('reviewCompareAudioBody')}',
                ),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFF6F84A2),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _ListeningFeedbackCard(
            label: context.l10n.text('reviewSelectedAudio'),
            audioLabel: _audioLabelFor(context, question, selectedAnswer),
            word: selectedAnswer,
            accent: const Color(0xFFEC5B42),
            onPlay: () => onPlay(selectedAnswer),
          ),
          const SizedBox(height: 12),
          _ListeningFeedbackCard(
            label: context.l10n.text('reviewCorrectAudio'),
            audioLabel: _audioLabelFor(context, question, question.word),
            word: question.word,
            accent: const Color(0xFF18B865),
            onPlay: () => onPlay(question.word),
          ),
          const SizedBox(height: 16),
          _ContinueButton(onPressed: onContinue, isLast: isLast),
        ],
      ),
    );
  }
}

class _ListeningFeedbackCard extends StatelessWidget {
  const _ListeningFeedbackCard({
    required this.label,
    required this.audioLabel,
    required this.word,
    required this.accent,
    required this.onPlay,
  });

  final String label;
  final String audioLabel;
  final ExerciseWord word;
  final Color accent;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .24), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8193AC),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  audioLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlay,
                icon: Icon(Icons.volume_up_rounded, color: accent, size: 22),
                style: IconButton.styleFrom(
                  fixedSize: const Size(58, 58),
                  padding: EdgeInsets.zero,
                  backgroundColor: accent.withValues(alpha: .06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            word.writing,
            style: const TextStyle(
              color: Color(0xFF7286A3),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerSheet extends StatelessWidget {
  const _WrongAnswerSheet({
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onPlay,
    required this.onContinue,
    required this.isLast,
  });

  final ExerciseWord selectedAnswer;
  final ExerciseWord correctAnswer;
  final ValueChanged<ExerciseWord> onPlay;
  final VoidCallback onContinue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          AppBottomSheetTitle(title: context.l10n.text('reviewNotice')),
          const SizedBox(height: 12),
          Text(
            context.l10n.text('reviewAudioDifferenceHint'),
            style: const TextStyle(
              color: Color(0xFF6F84A2),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _FeedbackCard(
            label: context.l10n.text('reviewYourAnswer'),
            word: selectedAnswer,
            accent: const Color(0xFFEC5B42),
            onPlay: () => onPlay(selectedAnswer),
          ),
          const SizedBox(height: 12),
          _FeedbackCard(
            label: context.l10n.text('reviewYourCorrectAnswer'),
            word: correctAnswer,
            accent: const Color(0xFF18B865),
            onPlay: () => onPlay(correctAnswer),
          ),
          const SizedBox(height: 16),
          _ContinueButton(onPressed: onContinue, isLast: isLast),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.label,
    required this.word,
    required this.accent,
    required this.onPlay,
  });

  final String label;
  final ExerciseWord word;
  final Color accent;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .24), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8193AC),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 0),
          Row(
            children: [
              Expanded(
                child: Text(
                  word.translation,
                  style: TextStyle(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlay,
                icon: Icon(Icons.volume_up_rounded, color: accent, size: 20),
                style: IconButton.styleFrom(
                  fixedSize: const Size(50, 50),
                  padding: EdgeInsets.zero,
                  backgroundColor: accent.withValues(alpha: .06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 0),
          Text(
            word.writing,
            style: const TextStyle(
              color: Color(0xFF7286A3),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SpeakingDecision { retry, skip }

class _SpeakingDecisionDialog extends StatelessWidget {
  const _SpeakingDecisionDialog({
    required this.noSound,
    required this.onRetry,
    required this.onSkip,
  });

  final bool noSound;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: noSound ? Icons.mic_off_rounded : Icons.error_outline_rounded,
      title: context.l10n.text(
        noSound ? 'reviewNoSoundTitle' : 'reviewNotRecognizedTitle',
      ),
      message: noSound
          ? context.l10n.text('reviewNoSoundBody')
          : context.l10n.text('reviewNotRecognizedBody'),
      secondaryLabel: context.l10n.text('skip'),
      onSecondary: onSkip,
      primaryLabel: context.l10n.text('retry'),
      onPrimary: onRetry,
    );
  }
}

class _SkipListeningDialog extends StatelessWidget {
  const _SkipListeningDialog({
    required this.title,
    required this.description,
    required this.onCancel,
    required this.onSkip,
  });

  final String title;
  final String description;
  final VoidCallback onCancel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      message: description,
      secondaryLabel: context.l10n.text('reviewNo'),
      onSecondary: onCancel,
      primaryLabel: context.l10n.text('reviewYes'),
      onPrimary: onSkip,
    );
  }
}

class _ExitPracticeDialog extends StatelessWidget {
  const _ExitPracticeDialog({required this.onCancel, required this.onExit});

  final VoidCallback onCancel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      imageAsset: 'assets/images/cancel_icon_dialog.png',
      title: context.l10n.text('reviewEndTitle'),
      message: context.l10n.text('reviewEndBody'),
      secondaryLabel: context.l10n.text('cancel'),
      onSecondary: onCancel,
      primaryLabel: context.l10n.text('reviewEndAction'),
      onPrimary: onExit,
    );
  }
}
