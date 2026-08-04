import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/topic_progress_service.dart';
import 'package:leximon/data/services/topic_repetition_service.dart';
import 'package:leximon/presentation/screens/topic_detail/topic_detail_screen.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  const topic = Topic(
    id: 7,
    order: 1,
    original: 'Travel',
    translated: 'Du lịch',
    words: [],
  );

  testWidgets('locks topic repetition below eight learned words', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(topic: topic, repetitionData: _repetitionData(7)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ôn lặp lại'), findsOneWidget);
    expect(
      find.text('Ngay khi có 8 từ, bạn có thể bắt đầu lặp lại chúng'),
      findsOneWidget,
    );
    expect(find.text('7 / 8'), findsOneWidget);
    expect(_repetitionInkWell(tester).onTap, isNull);
    expect(
      find.byKey(const ValueKey('assets/svgs/complete.svg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assets/svgs/need_practice.svg')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('assets/svgs/study.svg')), findsOneWidget);
    expect(find.byKey(const ValueKey('assets/svgs/new.svg')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/svgs/repeat.svg')),
      findsOneWidget,
    );
    expect(find.text('💡'), findsNothing);
    expect(find.text('🔁'), findsNothing);
    expect(find.text('Sẵn sàng'), findsOneWidget);
    expect(find.text('Chưa mở'), findsOneWidget);
  });

  testWidgets('enables topic repetition at exactly eight learned words', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(topic: topic, repetitionData: _repetitionData(8)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ôn lặp lại'), findsOneWidget);
    expect(
      find.text('Ngay khi có 8 từ, bạn có thể bắt đầu lặp lại chúng'),
      findsNothing,
    );
    expect(_repetitionInkWell(tester).onTap, isNotNull);
    expect(find.text('Sẵn sàng'), findsNWidgets(2));
    expect(find.text('Chưa mở'), findsNothing);
  });

  testWidgets('opens topic word study as a learn session', (tester) async {
    const learningTopic = Topic(
      id: 7,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'airport', 'translation': 'sân bay'},
      ],
    );
    await tester.pumpWidget(
      _testApp(topic: learningTopic, repetitionData: _repetitionData(0)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Học từ mới'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final studyScreen = tester.widget<WordStudyScreen>(
      find.byType(WordStudyScreen),
    );
    expect(studyScreen.dailyTaskType, DailyTaskType.learn);
  });

  testWidgets('opens the current topic tab from view all words', (
    tester,
  ) async {
    const selectedTopic = Topic(
      id: 9,
      order: 4,
      original: 'School',
      translated: 'Trường học',
      words: [
        {'id': 1, 'writing': 'classroom', 'translation': 'lớp học'},
      ],
    );
    await tester.pumpWidget(
      _testApp(topic: selectedTopic, repetitionData: _repetitionData(0)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Xem tất cả'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Xem tất cả'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final studyScreen = tester.widget<WordStudyScreen>(
      find.byType(WordStudyScreen),
    );
    expect(studyScreen.topic.id, selectedTopic.id);
    expect(studyScreen.topic.order, selectedTopic.order);
    expect(studyScreen.dailyTaskType, DailyTaskType.learn);
  });

  testWidgets('shows unclassified topic words first in quick preview', (
    tester,
  ) async {
    const previewTopic = Topic(
      id: 7,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'classified', 'translation': 'đã phân loại'},
        {'id': 2, 'writing': 'first new', 'translation': 'từ mới đầu tiên'},
        {'id': 3, 'writing': 'second new', 'translation': 'từ mới thứ hai'},
        {'id': 4, 'writing': 'third new', 'translation': 'từ mới thứ ba'},
      ],
    );
    await tester.pumpWidget(
      _testApp(
        topic: previewTopic,
        repetitionData: _repetitionData(0),
        wordProgress: {1: _learningProgress(1)},
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('first new'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('first new'), findsOneWidget);
    expect(find.text('second new'), findsOneWidget);
    expect(find.text('third new'), findsOneWidget);
    expect(find.text('classified'), findsNothing);
  });

  testWidgets('shows learning words before learned words when none are new', (
    tester,
  ) async {
    const previewTopic = Topic(
      id: 7,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'learned one', 'translation': 'đã học một'},
        {'id': 2, 'writing': 'learned two', 'translation': 'đã học hai'},
        {'id': 3, 'writing': 'learning one', 'translation': 'đang học một'},
        {'id': 4, 'writing': 'learning two', 'translation': 'đang học hai'},
      ],
    );
    await tester.pumpWidget(
      _testApp(
        topic: previewTopic,
        repetitionData: _repetitionData(0),
        wordProgress: {
          1: _learnedProgress(1),
          2: _learnedProgress(2),
          3: _learningProgress(3),
          4: _learningProgress(4),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('learning one'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('learning one'), findsOneWidget);
    expect(find.text('learning two'), findsOneWidget);
    expect(find.text('learned one'), findsOneWidget);
    expect(find.text('learned two'), findsNothing);
  });

  testWidgets('shows topic sentence training with four eligible words', (
    tester,
  ) async {
    const sentenceTopic = Topic(
      id: 7,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: [
        {'id': 4, 'writing': 'one', 'translation': 'một'},
        {'id': 5, 'writing': 'two', 'translation': 'hai'},
        {'id': 9, 'writing': 'three', 'translation': 'ba'},
        {'id': 11, 'writing': 'four', 'translation': 'bốn'},
      ],
    );
    await tester.pumpWidget(
      _testApp(
        topic: sentenceTopic,
        repetitionData: _repetitionData(0),
        wordProgress: {
          for (final id in [4, 5, 9, 11]) id: _learnedProgress(id),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ghép câu theo chủ đề'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ghép câu theo chủ đề'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Ghép câu theo chủ đề'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });
}

Widget _testApp({
  required Topic topic,
  required TopicRepetitionData repetitionData,
  Map<int, LearningProgressRow> wordProgress =
      const <int, LearningProgressRow>{},
}) {
  return ProviderScope(
    overrides: [
      topicsProvider.overrideWith((ref) async => [topic]),
      wordProgressProvider.overrideWith((ref) async => wordProgress),
      topicProgressDetailsProvider(
        topic.id,
      ).overrideWith((ref) async => TopicProgressDetails.empty(12)),
      topicRepetitionDataProvider(
        topic.id,
      ).overrideWith((ref) async => repetitionData),
    ],
    child: MaterialApp(home: TopicDetailScreen(topic: topic)),
  );
}

LearningProgressRow _learningProgress(int id) {
  return LearningProgressRow(
    id: id,
    creationDate: 0,
    trainingProgress: 1,
    trainingError: 0,
    repetitionStep: 0,
    onFastBrain: false,
    repetitionFastBrainStep: 0,
    markedAsKnown: false,
    deletedByUser: false,
  );
}

LearningProgressRow _learnedProgress(int id) {
  return LearningProgressRow(
    id: id,
    creationDate: 0,
    trainingProgress: 4,
    trainingError: 0,
    repetitionStep: 1,
    learnedDate: 1,
    onFastBrain: false,
    repetitionFastBrainStep: 0,
    markedAsKnown: false,
    deletedByUser: false,
  );
}

TopicRepetitionData _repetitionData(int count) {
  final words = [
    for (var id = 1; id <= count; id++)
      ExerciseWord(
        id: id,
        topicId: 7,
        writing: 'word $id',
        translation: 'nghĩa $id',
        transliteration: '',
      ),
  ];
  return TopicRepetitionData(words: words, distractorWords: words);
}

InkWell _repetitionInkWell(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.text('Ôn lặp lại'),
    matching: find.byType(InkWell),
  );
  return tester.widget<InkWell>(finder.first);
}
