import 'dart:convert';

import 'package:drift/drift.dart';

import '../datasources/grammar_asset_data_source.dart';
import '../local/app_database.dart';
import '../models/grammar_content.dart';

class GrammarRepository {
  GrammarRepository({
    required AppDatabase database,
    required GrammarAssetDataSource assetDataSource,
  }) : this._(database, assetDataSource);

  GrammarRepository._(this._database, this._assetDataSource);

  static const _revisionSource = 'bundled_grammar_packs';

  final AppDatabase _database;
  final GrammarAssetDataSource _assetDataSource;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final revision = await (_database.select(
      _database.contentRevisions,
    )..where((row) => row.source.equals(_revisionSource))).getSingleOrNull();
    final packCount = await _database.grammarPackModels.count().getSingle();
    if (revision?.revision == GrammarAssetDataSource.contentVersion &&
        packCount == GrammarAssetDataSource.entries.length) {
      return;
    }
    await _import(await _assetDataSource.loadAll());
  }

  Future<void> _import(List<GrammarAssetPack> packs) {
    return _database.transaction(() async {
      await _database.delete(_database.grammarUserResponseModels).go();
      await _database.delete(_database.grammarQuestionMappingModels).go();
      await _database.delete(_database.grammarQuestionModels).go();
      await _database.delete(_database.grammarTopicModels).go();
      await _database.delete(_database.grammarPackModels).go();

      for (final pack in packs) {
        final packId = await _database
            .into(_database.grammarPackModels)
            .insert(
              GrammarPackModelsCompanion.insert(
                guid: pack.guid,
                title: pack.title,
                description: Value(pack.description),
                level: pack.level,
                iconAsset: pack.iconAsset,
                sortOrder: pack.sortOrder,
              ),
            );
        for (
          var topicIndex = 0;
          topicIndex < pack.topics.length;
          topicIndex++
        ) {
          final topic = pack.topics[topicIndex];
          final topicId = await _database
              .into(_database.grammarTopicModels)
              .insert(
                GrammarTopicModelsCompanion.insert(
                  packId: packId,
                  title: topic.title,
                  description: Value(topic.description),
                  instructionsJson: Value(jsonEncode(topic.instructions)),
                  sortOrder: topicIndex,
                ),
              );
          for (final question in topic.questions) {
            final questionId = await _database
                .into(_database.grammarQuestionModels)
                .insert(
                  GrammarQuestionModelsCompanion.insert(
                    type: question['type'] as String? ?? '',
                    rubricJson: Value(_json(question['rubric'])),
                    cluesJson: Value(_json(question['clues'])),
                    bodyJson: Value(_json(question['questionBody'])),
                    leftColumnJson: Value(_json(question['leftCol'])),
                    rightColumnJson: Value(_json(question['rightCol'])),
                    layout: Value(question['questionLayout'] as String? ?? ''),
                    optionsLayout: Value(
                      question['optionsLayout'] as String? ?? '',
                    ),
                    responseType: Value(
                      question['responseType'] as String? ?? '',
                    ),
                    optionsJson: Value(_json(question['options'])),
                    answersJson: Value(_json(question['answers'])),
                    modelParagraph: Value(
                      question['modelParagraph'] as String? ?? '',
                    ),
                    testEnabled: Value(_asBool(question['testEnabled'])),
                  ),
                );
            await _database
                .into(_database.grammarQuestionMappingModels)
                .insert(
                  GrammarQuestionMappingModelsCompanion.insert(
                    topicId: topicId,
                    questionId: questionId,
                  ),
                );
          }
        }
      }

      await _database
          .into(_database.contentRevisions)
          .insertOnConflictUpdate(
            ContentRevisionsCompanion.insert(
              source: _revisionSource,
              revision: GrammarAssetDataSource.contentVersion,
              syncedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });
  }

  Future<List<GrammarPackContent>> loadPacks() async {
    await initialize();
    final packRows =
        await (_database.select(_database.grammarPackModels)
              ..where((row) => row.enabled.equals(true))
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();
    final topicRows =
        await (_database.select(_database.grammarTopicModels)
              ..where((row) => row.enabled.equals(true))
              ..orderBy([
                (row) => OrderingTerm.asc(row.packId),
                (row) => OrderingTerm.asc(row.sortOrder),
              ]))
            .get();
    final mappings = await _database
        .select(_database.grammarQuestionMappingModels)
        .get();
    final questionCountByTopic = <int, int>{};
    for (final mapping in mappings) {
      questionCountByTopic.update(
        mapping.topicId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final topicsByPack = <int, List<GrammarTopicContent>>{};
    for (final topic in topicRows) {
      topicsByPack
          .putIfAbsent(topic.packId, () => [])
          .add(
            GrammarTopicContent(
              id: topic.id,
              packId: topic.packId,
              label: topic.title,
              questionCount: questionCountByTopic[topic.id] ?? 0,
              progress: topic.progress,
              isComplete: topic.isComplete,
            ),
          );
    }
    return [
      for (final pack in packRows)
        GrammarPackContent(
          id: pack.id,
          guid: pack.guid,
          level: pack.level,
          title: pack.title,
          description: pack.description,
          iconAsset: pack.iconAsset,
          progress: pack.progress,
          topics: topicsByPack[pack.id] ?? const [],
        ),
    ];
  }

  Future<List<GrammarQuestionContent>> loadTopicQuestions(int topicId) async {
    await initialize();
    final mappings =
        await (_database.select(_database.grammarQuestionMappingModels)
              ..where((row) => row.topicId.equals(topicId))
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    if (mappings.isEmpty) return const [];
    final questionIds = mappings.map((mapping) => mapping.questionId).toList();
    final questions = await (_database.select(
      _database.grammarQuestionModels,
    )..where((row) => row.id.isIn(questionIds))).get();
    final responses = await (_database.select(
      _database.grammarUserResponseModels,
    )..where((row) => row.topicId.equals(topicId))).get();
    final responseByQuestion = {
      for (final response in responses) response.questionId: response,
    };
    final questionById = {
      for (final question in questions) question.id: question,
    };
    final result = <GrammarQuestionContent>[];
    for (final mapping in mappings) {
      final question = questionById[mapping.questionId];
      if (question == null) continue;
      final response = responseByQuestion[question.id];
      result.add(
        GrammarQuestionContent(
          id: question.id,
          topicId: topicId,
          type: question.type,
          rubricJson: question.rubricJson,
          cluesJson: question.cluesJson,
          bodyJson: question.bodyJson,
          leftColumnJson: question.leftColumnJson,
          rightColumnJson: question.rightColumnJson,
          layout: question.layout,
          optionsLayout: question.optionsLayout,
          responseType: question.responseType,
          optionsJson: question.optionsJson,
          answersJson: question.answersJson,
          modelParagraph: question.modelParagraph,
          savedResponse: response == null
              ? null
              : GrammarSavedResponse(
                  responseData: response.responseData,
                  isCorrect: response.isCorrect,
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    response.updatedAt,
                  ),
                ),
        ),
      );
    }
    return result;
  }

  static String _json(Object? value) => jsonEncode(value ?? const []);

  static bool _asBool(Object? value) =>
      value == true || value == 1 || value == '1';
}
