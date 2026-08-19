import 'package:drift/drift.dart';

import '../datasources/topic_asset_data_source.dart';
import '../local/app_database.dart';
import '../models/topic.dart';

class TopicRepository {
  TopicRepository({
    required AppDatabase database,
    required TopicAssetDataSource assetDataSource,
  }) : _database = database,
       _assetDataSource = assetDataSource;

  final AppDatabase _database;
  final TopicAssetDataSource _assetDataSource;
  Future<void> _lastSynchronization = Future<void>.value();
  String? _activeLanguageCode;

  Future<void> initialize({String languageCode = 'vi'}) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    final synchronization = _lastSynchronization.then((_) async {
      if (_activeLanguageCode == canonicalCode) return;
      final storedLanguage =
          _activeLanguageCode ?? await _database.activeTopicContentLanguage();
      final forceReload =
          storedLanguage != null && storedLanguage != canonicalCode;
      await _synchronizeContent(canonicalCode, forceReload: forceReload);
      _activeLanguageCode = canonicalCode;
    });
    _lastSynchronization = synchronization.catchError(
      (Object error, StackTrace stackTrace) {},
    );
    return synchronization;
  }

  /// Re-imports the server catalogue even when the selected language has not
  /// changed. This is used when the user leaves and re-enters onboarding.
  Future<void> reload({String languageCode = 'vi'}) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    final synchronization = _lastSynchronization.then((_) async {
      await _synchronizeContent(canonicalCode, forceReload: true);
      _activeLanguageCode = canonicalCode;
    });
    _lastSynchronization = synchronization.catchError(
      (Object error, StackTrace stackTrace) {},
    );
    return synchronization;
  }

  Future<List<Topic>> loadTopics({String languageCode = 'vi'}) async {
    await initialize(languageCode: languageCode);

    final topicRows = await _database.enabledTopics();
    final wordRows = await _database.enabledWords();
    final wordsByTopic = <int, List<WordRow>>{};
    for (final word in wordRows) {
      (wordsByTopic[word.topicId] ??= <WordRow>[]).add(word);
    }

    return topicRows
        .map(
          (topic) => Topic(
            id: topic.id,
            order: topic.sortOrder,
            original: topic.originalName ?? '',
            translated: topic.translatedName ?? '',
            words: (wordsByTopic[topic.id] ?? const <WordRow>[])
                .map(_wordToMap)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  Future<Set<int>> selectedTopicOrders() async {
    final rows = await (_database.select(
      _database.topicModels,
    )..where((row) => row.isSelected.equals(true))).get();
    return rows.map((row) => row.sortOrder).toSet();
  }

  Future<void> saveSelectedTopicOrders(Set<int> orders) {
    return _database.transaction(() async {
      await _database
          .update(_database.topicModels)
          .write(const TopicModelsCompanion(isSelected: Value(false)));
      if (orders.isEmpty) return;
      await (_database.update(_database.topicModels)
            ..where((row) => row.sortOrder.isIn(orders)))
          .write(const TopicModelsCompanion(isSelected: Value(true)));
    });
  }

  Future<void> _synchronizeContent(
    String languageCode, {
    required bool forceReload,
  }) async {
    final payload = await _assetDataSource.load(languageCode: languageCode);
    final localRevision = await _database.topicContentRevision(languageCode);
    final hasContent = await _database.hasTopicContent();
    if (!forceReload &&
        hasContent &&
        localRevision != null &&
        localRevision >= payload.version) {
      return;
    }
    await _database.upsertTopicContent(payload, languageCode: languageCode);
  }

  Map<String, dynamic> _wordToMap(WordRow word) {
    return <String, dynamic>{
      'id': word.id,
      'topicId': word.topicId,
      'writing': word.writing,
      'translation': word.translation,
      'transcription': word.transcription,
      'transliteration': word.transliteration,
      'enabled': word.isEnabled,
      'priority': word.priority,
      'level': word.level,
      'showCount': word.showCount,
    };
  }
}
