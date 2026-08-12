import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/datasources/grammar_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/grammar_content.dart';
import 'package:leximon/data/repositories/grammar_repository.dart';
import 'package:leximon/data/services/grammar_progress_service.dart';
import 'package:leximon/presentation/screens/grammar_practice/grammar_exercise_screen.dart';
import 'package:leximon/presentation/screens/grammar_practice/grammar_pack_detail_screen.dart';
import 'package:leximon/presentation/screens/grammar_practice/grammar_practice_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('result screen remains compatible without question details', () {
    const screen = GrammarTopicResultScreen(
      packTitle: 'Beginner Pack 1',
      topicTitle: 'To be',
      answered: 0,
      correct: 0,
      total: 25,
    );

    expect(screen.questions, isEmpty);
  });

  testWidgets('opens a topic, saves its answer and resumes at the next item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GrammarRepository(
      database: database,
      assetDataSource: GrammarAssetDataSource(),
    );
    final progressService = GrammarProgressService(database);
    final packContent = (await tester.runAsync(repository.loadPacks))!.first;
    final pack = GrammarPack.fromContent(packContent);
    final topic = pack.topics.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarProgressServiceProvider.overrideWithValue(progressService),
        ],
        child: MaterialApp(
          key: const ValueKey('grammar-detail-app'),
          theme: buildAppTheme(),
          home: GrammarPackDetailScreen(pack: pack),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('grammar-topic-0')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('grammar-exercise-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-exercise-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-exercise-progress')),
      findsOneWidget,
    );
    final background = tester.widget<Image>(
      find.byKey(const ValueKey('grammar-exercise-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_word_study.png',
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('grammar-exercise-progress')))
          .height,
      23,
    );
    expect(
      find.byKey(const ValueKey('grammar-exercise-progress-fill')),
      findsOneWidget,
    );
    expect(find.text('1/25'), findsOneWidget);

    final wrongOption = find.byKey(const ValueKey('grammar-option-1'));
    await tester.ensureVisible(wrongOption);
    await tester.tap(wrongOption);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-check-button')));
    await tester.pumpAndSettle();

    expect(find.text('Chưa chính xác'), findsOneWidget);
    expect(find.text('Đáp án đúng'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('grammar-correct-answer')),
      findsOneWidget,
    );
    final responses = (await tester.runAsync(
      () => database.select(database.grammarUserResponseModels).get(),
    ))!;
    expect(responses, hasLength(1));
    expect(responses.single.responseData, '[1]');
    expect(responses.single.isCorrect, isFalse);

    await tester.tap(find.byKey(const ValueKey('grammar-check-button')));
    await tester.pump();
    expect(find.text('2/25'), findsOneWidget);

    final refreshedQuestions = (await tester.runAsync(
      () => repository.loadTopicQuestions(topic.id),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarProgressServiceProvider.overrideWithValue(progressService),
        ],
        child: MaterialApp(
          key: const ValueKey('grammar-resume-app'),
          theme: buildAppTheme(),
          home: GrammarExerciseScreen(
            pack: pack,
            topic: topic,
            initialQuestions: refreshedQuestions.take(2).toList(),
            progressService: progressService,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Kiểm tra'), findsOneWidget);

    final labellingQuestion = refreshedQuestions.firstWhere(
      (question) => question.type == 'LABELLING',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarProgressServiceProvider.overrideWithValue(progressService),
        ],
        child: MaterialApp(
          key: const ValueKey('grammar-labelling-app'),
          theme: buildAppTheme(),
          home: GrammarExerciseScreen(
            pack: pack,
            topic: topic,
            initialQuestions: [labellingQuestion],
            progressService: progressService,
          ),
        ),
      ),
    );
    await tester.pump();

    final firstIs = find.byKey(const ValueKey('grammar-label-word-2'));
    final secondIs = find.byKey(const ValueKey('grammar-label-word-6'));
    final thirdIs = find.byKey(const ValueKey('grammar-label-word-17'));
    final missingAre = find.byKey(const ValueKey('grammar-label-word-21'));
    await tester.ensureVisible(thirdIs);
    await tester.tap(firstIs);
    await tester.tap(secondIs);
    await tester.tap(thirdIs);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-check-button')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: firstIs, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: secondIs, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: thirdIs, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: missingAre,
        matching: find.byIcon(Icons.priority_high_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: missingAre, matching: find.text('Thiếu')),
      findsOneWidget,
    );
    expect(find.text('Bạn chọn thiếu 1 đáp án'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result screen identifies correct and wrong questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final questions = [
      _resultQuestion(
        id: 1,
        body: 'She ___ a student.',
        options: const ['am', 'is'],
        answers: '[2]',
        response: GrammarSavedResponse(
          responseData: '[1]',
          isCorrect: false,
          updatedAt: DateTime(2026, 8, 12),
        ),
      ),
      _resultQuestion(
        id: 2,
        body: 'They ___ doctors.',
        options: const ['are', 'is'],
        answers: '[1]',
        response: GrammarSavedResponse(
          responseData: '[1]',
          isCorrect: true,
          updatedAt: DateTime(2026, 8, 12),
        ),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: GrammarTopicResultScreen(
            packTitle: 'Beginner Pack 1',
            topicTitle: 'To be',
            answered: 2,
            correct: 1,
            total: 2,
            questions: questions,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chi tiết câu trả lời'), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-result-trophy')), findsOneWidget);
    final progressCard = find.byKey(
      const ValueKey('grammar-result-progress-card'),
    );
    final accuracyCard = find.byKey(
      const ValueKey('grammar-result-accuracy-card'),
    );
    expect(progressCard, findsOneWidget);
    expect(accuracyCard, findsOneWidget);
    expect(tester.getSize(progressCard).height, 122);
    expect(tester.getSize(accuracyCard).height, 122);
    expect(
      find.descendant(
        of: progressCard,
        matching: find.byKey(const ValueKey('grammar-result-metric-wave')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: accuracyCard,
        matching: find.byKey(const ValueKey('grammar-result-metric-wave')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-result-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-result-question-map')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-result-index-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grammar-result-index-2')),
      findsOneWidget,
    );
    final wrongQuestion = find.byKey(
      const ValueKey('grammar-result-question-1'),
    );
    final correctQuestion = find.byKey(
      const ValueKey('grammar-result-question-2'),
    );
    expect(
      find.descendant(of: wrongQuestion, matching: find.text('Sai')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: wrongQuestion,
        matching: find.text('Đáp án đúng: is'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: correctQuestion, matching: find.text('Đúng')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rewrite exercise renders required word as dedicated UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    const question = GrammarQuestionContent(
      id: 999,
      topicId: 1,
      type: 'FIB',
      rubricJson:
          '[{"type":"text","data":"Complete sentence B using the WORD provided."}]',
      cluesJson: '[]',
      bodyJson:
          '[{"type":"text","data":"A: Her mobile phone is new.<br/><word>GOT</word><br/>B: She "},"GAP",{"type":"text","data":" a new mobile phone."}]',
      leftColumnJson: '[]',
      rightColumnJson: '[]',
      layout: '',
      optionsLayout: '',
      responseType: 'TEXT',
      optionsJson: '[]',
      answersJson: '[["has got"]]',
      modelParagraph: '',
    );
    const pack = GrammarPack(
      guid: 'BCQP0001',
      level: 'Beginner',
      title: 'Beginner Pack 1',
      lessonCount: 1,
      iconAsset: 'assets/images/grammar/beginner_pack1.png',
    );
    const topic = GrammarTopic(id: 1, label: 'Have got', questionCount: 1);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: GrammarExerciseScreen(
            pack: pack,
            topic: topic,
            initialQuestions: const [question],
            progressService: GrammarProgressService(database),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CÂU GỐC'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Her mobile phone is new.'), findsOneWidget);
    expect(find.text('Từ bắt buộc'), findsOneWidget);
    expect(find.text('GOT'), findsOneWidget);
    expect(find.text('VIẾT LẠI CÂU'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('She'), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-rewrite-gap')), findsOneWidget);
    expect(find.textContaining('<word>'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match cards show long answers without overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    const question = GrammarQuestionContent(
      id: 1000,
      topicId: 1,
      type: 'MATCHSORT',
      rubricJson:
          '[{"type":"text","data":"Match the verbs to the correct words."}]',
      cluesJson: '[]',
      bodyJson:
          '[{"type":"text","data":"Listen"},{"type":"text","data":"Close"},{"type":"text","data":"Be"},{"type":"text","data":"Sit"},{"type":"text","data":"Turn off"}]',
      leftColumnJson: '[]',
      rightColumnJson: '[]',
      layout: 'vertical',
      optionsLayout: '',
      responseType: '',
      optionsJson:
          '[{"type":"text","data":"carefully"},{"type":"text","data":"the window"},{"type":"text","data":"very quiet"},{"type":"text","data":"over there"},{"type":"text","data":"the bright living-room light"}]',
      answersJson: '[]',
      modelParagraph: '',
    );
    const pack = GrammarPack(
      guid: 'BCQP0001',
      level: 'Beginner',
      title: 'Beginner Pack 1',
      lessonCount: 1,
      iconAsset: 'assets/images/grammar/beginner_pack1.png',
    );
    const topic = GrammarTopic(
      id: 1,
      label: 'Imperatives (+/-)',
      questionCount: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: GrammarExerciseScreen(
            pack: pack,
            topic: topic,
            initialQuestions: const [question],
            progressService: GrammarProgressService(database),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('grammar-match-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-match-card-4')), findsOneWidget);
    final firstAnswer = find.byKey(const ValueKey('grammar-match-answer-0'));
    await tester.tap(firstAnswer);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('grammar-match-options-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('grammar-match-option-5')));
    await tester.pumpAndSettle();

    final selectedAnswer = find.descendant(
      of: firstAnswer,
      matching: find.text('the bright living-room light'),
    );
    expect(selectedAnswer, findsOneWidget);
    expect(tester.widget<Text>(selectedAnswer).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
}

GrammarQuestionContent _resultQuestion({
  required int id,
  required String body,
  required List<String> options,
  required String answers,
  required GrammarSavedResponse response,
}) {
  final parts = body.split('___');
  return GrammarQuestionContent(
    id: id,
    topicId: 1,
    type: 'FIB',
    rubricJson: '[{"type":"text","data":"Complete the sentence."}]',
    cluesJson: '[]',
    bodyJson:
        '[{"type":"text","data":"${parts.first}"},"GAP",{"type":"text","data":"${parts.last}"}]',
    leftColumnJson: '[]',
    rightColumnJson: '[]',
    layout: '',
    optionsLayout: '',
    responseType: 'BUTTON',
    optionsJson:
        '[${options.map((option) => '{"type":"text","data":"$option"}').join(',')}]',
    answersJson: answers,
    modelParagraph: '',
    savedResponse: response,
  );
}
