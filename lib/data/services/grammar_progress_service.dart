import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../local/app_database.dart';

class GrammarProgressService {
  const GrammarProgressService(this._database);

  final AppDatabase _database;

  Future<void> saveResponse({
    required int questionId,
    required int topicId,
    required String responseData,
    required bool isCorrect,
    DateTime? now,
  }) {
    return _database.transaction(() async {
      await _database
          .into(_database.grammarUserResponseModels)
          .insertOnConflictUpdate(
            GrammarUserResponseModelsCompanion.insert(
              questionId: Value(questionId),
              topicId: topicId,
              responseData: responseData,
              isCorrect: isCorrect,
              updatedAt: (now ?? DateTime.now()).millisecondsSinceEpoch,
            ),
          );
      await _recalculateTopicAndPack(topicId);
    });
  }

  Future<void> resetQuestion({required int questionId, required int topicId}) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.grammarUserResponseModels,
      )..where((row) => row.questionId.equals(questionId))).go();
      await _recalculateTopicAndPack(topicId);
    });
  }

  Future<void> resetTopic(int topicId) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.grammarUserResponseModels,
      )..where((row) => row.topicId.equals(topicId))).go();
      await _recalculateTopicAndPack(topicId);
    });
  }

  Future<void> resetPack(int packId) {
    return _database.transaction(() async {
      final topics = await (_database.select(
        _database.grammarTopicModels,
      )..where((row) => row.packId.equals(packId))).get();
      final topicIds = topics.map((topic) => topic.id).toList();
      if (topicIds.isNotEmpty) {
        await (_database.delete(
          _database.grammarUserResponseModels,
        )..where((row) => row.topicId.isIn(topicIds))).go();
        await (_database.update(
          _database.grammarTopicModels,
        )..where((row) => row.packId.equals(packId))).write(
          const GrammarTopicModelsCompanion(
            progress: Value(0),
            isComplete: Value(false),
          ),
        );
      }
      await (_database.update(_database.grammarPackModels)
            ..where((row) => row.id.equals(packId)))
          .write(const GrammarPackModelsCompanion(progress: Value(0)));
    });
  }

  Future<void> _recalculateTopicAndPack(int topicId) async {
    final topic = await (_database.select(
      _database.grammarTopicModels,
    )..where((row) => row.id.equals(topicId))).getSingle();
    final totalQuestions = await (_database.select(
      _database.grammarQuestionMappingModels,
    )..where((row) => row.topicId.equals(topicId))).get();
    final responses = await (_database.select(
      _database.grammarUserResponseModels,
    )..where((row) => row.topicId.equals(topicId))).get();
    final topicProgress = totalQuestions.isEmpty
        ? 0
        : math.min(
            100,
            (responses.length * 100 / totalQuestions.length).ceil(),
          );
    await (_database.update(
      _database.grammarTopicModels,
    )..where((row) => row.id.equals(topicId))).write(
      GrammarTopicModelsCompanion(
        progress: Value(topicProgress),
        isComplete: Value(topicProgress >= 100),
      ),
    );
    await _recalculatePack(topic.packId);
  }

  Future<void> _recalculatePack(int packId) async {
    final topics =
        await (_database.select(_database.grammarTopicModels)..where(
              (row) => row.packId.equals(packId) & row.enabled.equals(true),
            ))
            .get();
    final packProgress = topics.isEmpty
        ? 0
        : (topics.fold<int>(0, (sum, topic) => sum + topic.progress) /
                  topics.length)
              .ceil();
    await (_database.update(_database.grammarPackModels)
          ..where((row) => row.id.equals(packId)))
        .write(GrammarPackModelsCompanion(progress: Value(packProgress)));
  }
}
