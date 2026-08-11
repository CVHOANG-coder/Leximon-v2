import 'package:leximon/app.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';
import 'package:leximon/presentation/screens/review_practice/review_practice_screen.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('opens topic setup from Home and applies the selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationInitializationProvider.overrideWith(
            (ref) async => AppStartupDestination.home,
          ),
        ],
        child: const LeximonApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Leximon'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/tab_personal_inactive.png')),
      findsOneWidget,
    );
    final selectedHomeIcon = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('bottom-nav-icon-Học tập')),
    );
    final selectedHomeDecoration =
        selectedHomeIcon.decoration! as BoxDecoration;
    final selectedGradient = selectedHomeDecoration.gradient! as LinearGradient;
    expect(selectedGradient.colors, const [
      Color(0xFF1658D3),
      Color(0xFF2481FA),
    ]);
    expect(selectedGradient.begin, Alignment.topLeft);
    expect(selectedGradient.end, Alignment.bottomRight);
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('bottom-nav-scale-Học tập')),
          )
          .scale,
      1.08,
    );

    await tester.tap(find.text('Cá nhân'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('assets/images/tab_personal_active.png')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('bottom-nav-scale-Cá nhân')),
          )
          .scale,
      1.08,
    );

    await tester.tap(find.text('Thử thách'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('challenge-screen')), findsOneWidget);
    expect(find.text('Thử thách mỗi ngày'), findsOneWidget);

    final listeningAction = tester.widget<InkWell>(
      find.byKey(const ValueKey('listening-mode-card-action')),
    );
    listeningAction.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('listening-practice-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Học tập'));
    await tester.pump(const Duration(milliseconds: 250));

    final filterButton = find.byType(IconButton);
    await tester.ensureVisible(filterButton);
    // The filter control lives inside the Home scroll view.
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cá nhân hóa lộ trình'), findsOneWidget);
    expect(find.text('Học tập'), findsNothing);
    expect(find.text('Những chủ đề nào phù hợp với bạn?'), findsOneWidget);
    expect(find.text('Bước 2 / 2'), findsNothing);

    await tester.tap(find.text('Áp dụng'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Chọn chủ đề để học'), findsOneWidget);
  });

  testWidgets('swipes between words in the study deck', (tester) async {
    final topic = Topic(
      id: 1,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {
          'writing': 'trip',
          'translation': 'chuyến đi',
          'transcription': '/trɪp/',
        },
        {
          'writing': 'passport',
          'translation': 'hộ chiếu',
          'transcription': '/ˈpɑːspɔːt/',
        },
        {'writing': 'visa', 'translation': 'thị thực'},
        {'writing': 'suitcase', 'translation': 'va li'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('trip'), findsOneWidget);
    await tester.drag(find.text('trip'), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(find.text('passport'), findsOneWidget);
    expect(find.text('0.75×'), findsWidgets);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
  });

  testWidgets('advances after marking a study word as learning or known', (
    tester,
  ) async {
    final topic = Topic(
      id: 1,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {'writing': 'trip', 'translation': 'chuyến đi'},
        {'writing': 'passport', 'translation': 'hộ chiếu'},
        {'writing': 'visa', 'translation': 'thị thực'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Học từ này').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('passport').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Đã biết').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('visa').hitTestable(), findsOneWidget);
  });

  testWidgets('shows feedback for choice-of-four practice answers', (
    tester,
  ) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(words: words, distractorWords: words),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thực hành'), findsOneWidget);
    expect(find.text('Bước khởi động'), findsOneWidget);
    expect(find.text('0 / 24'), findsOneWidget);
    expect(find.text('Bắt đầu ôn tập'), findsOneWidget);
    final practiceBackground = tester.widget<Image>(
      find.byKey(const ValueKey('review-practice-background')),
    );
    expect(
      (practiceBackground.image as AssetImage).assetName,
      'assets/images/bg_word_study.png',
    );
    expect(
      find.byKey(const Key('review-practice-close-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('review-practice-start-button')),
      findsOneWidget,
    );
    expect(find.text('trip'), findsOneWidget);
    expect(find.text('chuyến đi'), findsOneWidget);

    await tester.ensureVisible(find.text('Bắt đầu ôn tập'));
    await tester.tap(find.text('Bắt đầu ôn tập'));
    await tester.pumpAndSettle();

    expect(find.text('Bước khởi động'), findsNothing);
    expect(find.text('1 / 24'), findsOneWidget);
    expect(find.text('trip'), findsOneWidget);

    await tester.tap(find.text('hộ chiếu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Câu trả lời của bạn'), findsWidgets);
    expect(find.text('Đáp án đúng'), findsOneWidget);
    expect(find.text('Chú ý'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('advances the visible practice progress on every question', (
    tester,
  ) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final progressFill = find.byKey(const Key('review-practice-progress-fill'));
    final firstQuestionSize = tester.getSize(progressFill);
    expect(firstQuestionSize.height, greaterThan(0));

    await tester.tap(find.text('chuyến đi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(progressFill).width,
      greaterThan(firstQuestionSize.width),
    );
  });

  testWidgets('difficult practice only rebuilds the remaining error types', (
    tester,
  ) async {
    final words = _practiceWords();
    final constructorMask = LearningProgressService.bitForType(
      TrainingExerciseType.constructor,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          title: 'Từ khó',
          kicker: 'WANT MORE',
          dailyTaskType: DailyTaskType.difficult,
          words: words,
          distractorWords: words,
          exerciseMasksByWordId: {
            for (final word in words) word['id'] as int: constructorMask,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WANT MORE'), findsOneWidget);
    expect(find.text('Từ khó'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
  });

  testWidgets('shows three listening choices and correct feedback', (
    tester,
  ) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 8,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bài nghe chọn âm thanh'), findsOneWidget);
    expect(find.text('9 / 24'), findsOneWidget);
    expect(find.text('LISTENING MATCH'), findsOneWidget);
    expect(find.text('Chọn 1 trong 3 âm thanh'), findsOneWidget);
    expect(find.text('Âm thanh A'), findsOneWidget);
    expect(find.text('Âm thanh B'), findsOneWidget);
    expect(find.text('Âm thanh C'), findsOneWidget);
    expect(find.text('Âm thanh D'), findsNothing);
    expect(find.text('HIỆN TẠI, TÔI KHÔNG THỂ NGHE ĐƯỢC'), findsOneWidget);

    final correctChoice = find.byKey(const ValueKey('listening-word-1'));
    await tester.ensureVisible(correctChoice);
    await tester.tap(correctChoice);
    await tester.pumpAndSettle();

    expect(
      find.text('Đã chọn âm thanh — nhấn Chọn để kiểm tra'),
      findsOneWidget,
    );
    expect(find.text('Chọn'), findsOneWidget);
    expect(find.text('Bạn đã chọn đúng âm thanh'), findsNothing);

    await tester.ensureVisible(find.text('Chọn'));
    await tester.tap(find.text('Chọn'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã chọn đúng âm thanh'), findsOneWidget);
    expect(find.text('Phát âm đúng từ “trip”'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('shows listening comparison after a wrong choice', (
    tester,
  ) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 8,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final wrongChoice = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('listening-word-') &&
          key.value != 'listening-word-1';
    }).first;
    await tester.ensureVisible(wrongChoice);
    await tester.tap(wrongChoice);
    await tester.pumpAndSettle();

    expect(
      find.text('Đã chọn âm thanh — nhấn Chọn để kiểm tra'),
      findsOneWidget,
    );
    expect(find.text('Bạn chọn sai âm thanh'), findsNothing);

    await tester.ensureVisible(find.text('Chọn'));
    await tester.tap(find.text('Chọn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chọn sai âm thanh'), findsOneWidget);
    expect(find.text('Nghe lại để phân biệt'), findsOneWidget);
    expect(find.text('ÂM THANH BẠN ĐÃ CHỌN'), findsOneWidget);
    expect(find.text('ÂM THANH ĐÚNG'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('confirms and skips three-choice listening practice', (
    tester,
  ) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 8,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final skipButton = find.text('HIỆN TẠI, TÔI KHÔNG THỂ NGHE ĐƯỢC');
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bạn có chắc chắn bạn muốn bỏ qua thực hành nghe hiểu vào lúc này?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Có'));
    await tester.pumpAndSettle();

    expect(find.text('13 / 24'), findsOneWidget);
    expect(find.text('Bài ghép chữ'), findsOneWidget);
  });

  testWidgets('shows four listening translation choices', (tester) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 16,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi nghe hiểu'), findsOneWidget);
    expect(find.text('Hãy nghe và chọn bản dịch'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('choice-four-listening-slow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('choice-four-listening-normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('choice-four-listening-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('choice-four-listening-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('choice-four-listening-3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('choice-four-listening-4')),
      findsOneWidget,
    );
    expect(find.text('HIỆN TẠI, TÔI KHÔNG THỂ NGHE ĐƯỢC'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('choice-four-listening-2')),
    );
    await tester.tap(find.byKey(const ValueKey('choice-four-listening-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Chú ý'), findsOneWidget);
    expect(find.text('CÂU TRẢ LỜI CỦA BẠN'), findsOneWidget);
    expect(find.text('CÂU TRẢ LỜI ĐÚNG'), findsOneWidget);
  });

  testWidgets('confirms and skips listening practice', (tester) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 16,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final skipButton = find.text('HIỆN TẠI, TÔI KHÔNG THỂ NGHE ĐƯỢC');
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Bạn có chắc chắn bạn muốn bỏ qua thực hành nghe hiểu vào lúc này?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Bạn có chắc chắn bạn muốn bỏ qua thực hành nghe hiểu vào lúc này?',
      ),
      findsNothing,
    );
    expect(find.text('17 / 24'), findsOneWidget);

    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Có'));
    await tester.pumpAndSettle();

    expect(find.text('21 / 24'), findsOneWidget);
    expect(find.text('HIỆN TẠI, TÔI KHÔNG THỂ NGHE ĐƯỢC'), findsNothing);
  });

  testWidgets('builds a word from character chips', (tester) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 12,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bài ghép chữ'), findsOneWidget);
    expect(find.text('NHẬP BẢN DỊCH'), findsOneWidget);
    expect(find.text('chuyến đi'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('typing-space')), findsOneWidget);

    for (final character in ['t', 'r']) {
      await tester.ensureVisible(find.text(character));
      await tester.tap(find.text(character));
      await tester.pumpAndSettle();
    }

    expect(find.text('tr'), findsOneWidget);
    final composingText = tester.widget<Text>(
      find.byKey(const ValueKey('typing-composing-text')),
    );
    expect(composingText.maxLines, 1);
    expect(composingText.softWrap, isFalse);
    expect(composingText.overflow, TextOverflow.visible);
    await tester.tap(find.byKey(const ValueKey('typing-remove-last')));
    await tester.pumpAndSettle();
    expect(find.text('t'), findsNWidgets(2));

    for (final character in ['r', 'i', 'p']) {
      await tester.ensureVisible(find.text(character));
      await tester.tap(find.text(character));
      await tester.pumpAndSettle();
    }

    expect(find.text('trip'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(
      find.text('Bạn đã ghép đúng từ tiếng Anh tương ứng.'),
      findsOneWidget,
    );
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('shrinks a long typing translation without an ellipsis', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final words = _practiceWords();
    words[0] = {
      ...words[0],
      'translation': 'ăn uống bán phần (sáng + trưa hoặc tối)',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 12,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final translation = tester.widget<Text>(
      find.byKey(const ValueKey('typing-translation')),
    );
    expect(translation.style!.fontSize, lessThan(34));
    expect(translation.overflow, TextOverflow.visible);
    expect(translation.data, contains('hoặc tối'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a long composed word on one line', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final words = _practiceWords();
    words[0] = {...words[0], 'writing': 'wwwwwwwwwwwwwwww'};

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 12,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 16; index++) {
      final character = find.text('w').last;
      await tester.ensureVisible(character);
      await tester.tap(character);
      await tester.pumpAndSettle();
    }

    final composedWord = tester.widget<Text>(
      find.byKey(const ValueKey('typing-composing-text')),
    );
    expect(composedWord.style!.fontSize, lessThan(42));
    expect(composedWord.maxLines, 1);
    expect(composedWord.softWrap, isFalse);
    expect(composedWord.overflow, TextOverflow.visible);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduces repeated character badge as it is used', (tester) async {
    final words = [
      {
        'id': 1,
        'writing': 'pass',
        'translation': 'đỗ xe',
        'transcription': '/pɑːs/',
      },
      {'id': 2, 'writing': 'visa', 'translation': 'thị thực'},
      {'id': 3, 'writing': 'trip', 'translation': 'chuyến đi'},
      {'id': 4, 'writing': 'map', 'translation': 'bản đồ'},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 12,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bài ghép chữ'), findsOneWidget);
    final repeatedCharacterBadge = find.byKey(const ValueKey('typing-count-s'));
    expect(repeatedCharacterBadge, findsOneWidget);

    await tester.ensureVisible(find.text('s').first);
    await tester.tap(find.text('s').first);
    await tester.pumpAndSettle();

    expect(repeatedCharacterBadge, findsNothing);
  });

  testWidgets('records a speaking practice response', (tester) async {
    final words = _practiceWords();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPracticeScreen(
          words: words,
          distractorWords: words,
          initialQuestionIndex: 20,
          showIntroOnStart: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi phát âm'), findsOneWidget);
    expect(find.text('Phát âm từ này'), findsOneWidget);
    expect(find.text('Nhấn nút này để ghi âm'), findsOneWidget);

    final cannotSpeak = find.text('HIỆN TẠI, TÔI KHÔNG THỂ NÓI ĐƯỢC');
    await tester.ensureVisible(cannotSpeak);
    await tester.tap(cannotSpeak);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Bạn có chắc chắn bạn muốn bỏ qua thực hành phát âm vào lúc này?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();

    final recordButton = find.byKey(const ValueKey('speaking-record-button'));
    await tester.ensureVisible(recordButton);
    expect(recordButton, findsOneWidget);
    expect(find.text('Kiểm tra'), findsNothing);
  });

  testWidgets('opens practice after selecting four study words', (
    tester,
  ) async {
    final topic = Topic(
      id: 1,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {
          'id': 1,
          'writing': 'trip',
          'translation': 'chuyến đi',
          'transcription': '/trɪp/',
        },
        {'id': 2, 'writing': 'passport', 'translation': 'hộ chiếu'},
        {'id': 3, 'writing': 'visa', 'translation': 'thị thực'},
        {'id': 4, 'writing': 'suitcase', 'translation': 'va li'},
      ],
    );
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          topicsProvider.overrideWith((ref) async => [topic]),
        ],
        child: MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (var index = 0; index < topic.words.length; index++) {
      await tester.tap(find.text('Học từ này').hitTestable().first);
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    expect(find.text('Thực hành'), findsOneWidget);
    expect(find.text('Bước khởi động'), findsOneWidget);
    expect(find.text('0 / 24'), findsOneWidget);
    expect(find.text('Bắt đầu ôn tập'), findsOneWidget);
    expect(find.text('trip'), findsOneWidget);
  });
}

List<Map<String, dynamic>> _practiceWords() {
  return [
    {
      'id': 1,
      'writing': 'trip',
      'translation': 'chuyến đi',
      'transcription': '/trɪp/',
    },
    {'id': 2, 'writing': 'passport', 'translation': 'hộ chiếu'},
    {'id': 3, 'writing': 'visa', 'translation': 'thị thực'},
    {'id': 4, 'writing': 'suitcase', 'translation': 'va li'},
  ];
}
