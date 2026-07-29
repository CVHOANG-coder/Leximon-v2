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
}

Widget _testApp({
  required Topic topic,
  required TopicRepetitionData repetitionData,
}) {
  return ProviderScope(
    overrides: [
      topicsProvider.overrideWith((ref) async => [topic]),
      wordProgressProvider.overrideWith(
        (ref) async => const <int, LearningProgressRow>{},
      ),
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
