import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/sentence_exercise.dart';
import 'package:leximon/data/services/sentence_lesson_service.dart';
import 'package:leximon/presentation/screens/sentence_training/sentence_training_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('sentence flow opens intro and checks a local answer', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final sentence = SentenceRecord(
      translationId: 1,
      wordId: 1,
      sentenceId: 1,
      spelling: 'I like tea',
      translation: 'Tôi thích trà',
      difficulty: 0,
      wrongSpellings: const [],
      taskSpellings: const ['tea'],
      task: 'I like |tea|',
      soundUrl: '',
      alternativeTranslations: const [],
    );
    final lesson = SentenceLesson(
      wordIds: const [1, 2, 3, 4],
      exercises: [
        SentenceExercise(
          sentence: sentence,
          type: SentenceExerciseType.constructor,
          choices: const ['I', 'like', 'tea'],
          expectedTokens: const ['I', 'like', 'tea'],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: SentenceTrainingScreen(
            source: SentenceTrainingSource.daily,
            lessonService: _FakeLessonService(database, lesson),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Từ vựng sống trong câu'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu ghép câu'));
    await tester.pump();

    expect(find.text('GHÉP CÂU TIẾNG ANH'), findsOneWidget);
    for (final token in ['I', 'like', 'tea']) {
      await tester.tap(find.text(token).last);
      await tester.pump();
    }
    await tester.tap(find.text('Kiểm tra'));
    await tester.pumpAndSettle();

    expect(find.text('Chính xác!'), findsOneWidget);
    expect(find.text('Đáp án đúng'), findsOneWidget);
    expect(find.text('Xem kết quả'), findsOneWidget);

    await tester.tap(find.text('Xem kết quả'));
    await tester.pumpAndSettle();

    expect(find.text('Hoàn thành phiên ghép câu!'), findsOneWidget);
    expect(find.text('Luyện thêm 4 từ khác'), findsNothing);
    expect(
      await database.select(database.wordSentenceProgressModels).get(),
      hasLength(4),
    );
  });

  testWidgets('skipping listening removes the remaining audio exercises', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final sentence = SentenceRecord(
      translationId: 2,
      wordId: 4,
      sentenceId: 20,
      spelling: 'I drink tea',
      translation: 'Tôi uống trà',
      difficulty: 0,
      wrongSpellings: const [],
      taskSpellings: const ['tea'],
      task: 'I drink |tea|',
      soundUrl: '',
      alternativeTranslations: const [],
    );
    final lesson = SentenceLesson(
      wordIds: const [4, 5, 9, 11],
      sentences: [sentence],
      exercises: [
        SentenceExercise(
          sentence: sentence,
          type: SentenceExerciseType.audio,
          choices: const ['I', 'drink', 'tea'],
          expectedTokens: const ['I', 'drink', 'tea'],
        ),
        SentenceExercise(
          sentence: sentence,
          type: SentenceExerciseType.constructor,
          choices: const ['I', 'drink', 'tea'],
          expectedTokens: const ['I', 'drink', 'tea'],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: SentenceTrainingScreen(
            lessonService: _FakeLessonService(database, lesson),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu ghép câu'));
    await tester.pump();

    expect(find.text('NGHE VÀ GHÉP CÂU'), findsOneWidget);
    await tester.ensureVisible(find.text('Không thể nghe'));
    await tester.tap(find.text('Không thể nghe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua bài nghe'));
    await tester.pumpAndSettle();

    expect(find.text('GHÉP CÂU TIẾNG ANH'), findsOneWidget);
    expect(find.text('NGHE VÀ GHÉP CÂU'), findsNothing);
  });
}

class _FakeLessonService extends SentenceLessonService {
  _FakeLessonService(AppDatabase database, this.lesson)
    : super(database: database);

  final SentenceLesson lesson;

  @override
  Future<SentenceLesson> loadLesson({int? topicId}) async => lesson;
}
