import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/grammar_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/grammar_repository.dart';
import 'package:leximon/data/services/grammar_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late GrammarRepository repository;
  late GrammarProgressService progressService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GrammarRepository(
      database: database,
      assetDataSource: GrammarAssetDataSource(),
    );
    progressService = GrammarProgressService(database);
  });

  tearDown(() => database.close());

  test('imports all bundled grammar content into local SQLite', () async {
    final packs = await repository.loadPacks();
    final topics = await database.select(database.grammarTopicModels).get();
    final questions = await database
        .select(database.grammarQuestionModels)
        .get();
    final mappings = await database
        .select(database.grammarQuestionMappingModels)
        .get();

    expect(packs, hasLength(9));
    expect(topics, hasLength(128));
    expect(questions, hasLength(2641));
    expect(mappings, hasLength(2641));
    expect(packs.first.guid, 'BCQP0001');
    expect(packs.first.topics.first.label, 'To be');
    expect(packs.first.topics.first.questionCount, 25);
    final firstQuestions = await repository.loadTopicQuestions(
      packs.first.topics.first.id,
    );
    expect(firstQuestions.first.type, 'MCQ');
    expect(firstQuestions.first.responseType, 'BUTTON');
    expect(firstQuestions.first.answersJson, '[2]');
  });

  test(
    'replaces a response and recalculates topic and pack progress',
    () async {
      final packs = await repository.loadPacks();
      final pack = packs.first;
      final topic = pack.topics.first;
      final questions = await repository.loadTopicQuestions(topic.id);
      final question = questions.first;

      await progressService.saveResponse(
        questionId: question.id,
        topicId: topic.id,
        responseData: '[2]',
        isCorrect: false,
        now: DateTime(2026, 8, 12, 10),
      );
      await progressService.saveResponse(
        questionId: question.id,
        topicId: topic.id,
        responseData: '[1]',
        isCorrect: true,
        now: DateTime(2026, 8, 12, 11),
      );

      final responses = await database
          .select(database.grammarUserResponseModels)
          .get();
      final topicRow = await (database.select(
        database.grammarTopicModels,
      )..where((row) => row.id.equals(topic.id))).getSingle();
      final packRow = await (database.select(
        database.grammarPackModels,
      )..where((row) => row.id.equals(pack.id))).getSingle();
      final restoredQuestions = await repository.loadTopicQuestions(topic.id);

      expect(responses, hasLength(1));
      expect(responses.single.responseData, '[1]');
      expect(responses.single.isCorrect, isTrue);
      expect(topicRow.progress, 4); // ceil(1 * 100 / 25)
      expect(packRow.progress, 1); // ceil(4 / 16 enabled topics)
      expect(restoredQuestions.first.savedResponse?.responseData, '[1]');

      final repositoryAfterRestart = GrammarRepository(
        database: database,
        assetDataSource: GrammarAssetDataSource(),
      );
      final packsAfterRestart = await repositoryAfterRestart.loadPacks();
      final questionsAfterRestart = await repositoryAfterRestart
          .loadTopicQuestions(topic.id);
      expect(packsAfterRestart.first.progress, 1);
      expect(packsAfterRestart.first.topics.first.progress, 4);
      expect(questionsAfterRestart.first.savedResponse?.responseData, '[1]');

      await progressService.resetTopic(topic.id);
      final resetPacks = await repository.loadPacks();
      expect(resetPacks.first.progress, 0);
      expect(resetPacks.first.topics.first.progress, 0);
      expect(
        await database.select(database.grammarUserResponseModels).get(),
        isEmpty,
      );
    },
  );

  test(
    'records a weekly session only when a grammar topic completes',
    () async {
      final packs = await repository.loadPacks();
      final topic = packs.first.topics.first;
      final questions = await repository.loadTopicQuestions(topic.id);
      final now = DateTime(2026, 8, 13, 10);

      for (var index = 0; index < questions.length - 1; index++) {
        await progressService.saveResponse(
          questionId: questions[index].id,
          topicId: topic.id,
          responseData: '[0]',
          isCorrect: false,
          now: now,
        );
      }
      expect(
        await database.select(database.practiceSessionHistoryModels).get(),
        isEmpty,
      );

      await progressService.saveResponse(
        questionId: questions.last.id,
        topicId: topic.id,
        responseData: '[0]',
        isCorrect: false,
        now: now,
      );

      final sessions = await database
          .select(database.practiceSessionHistoryModels)
          .get();
      expect(sessions, hasLength(1));
      expect(sessions.single.skill, 'grammar');
      expect(sessions.single.contentId, topic.id.toString());
    },
  );
}
