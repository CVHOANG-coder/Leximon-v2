import '../../core/network/api_client.dart';
import '../../core/localization/language_code.dart';
import '../models/topic_language.dart';
import '../models/topic_asset_payload.dart';

const _topicRemoteDirectory = '/data/topics';

class TopicAssetDataSource {
  TopicAssetDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const knownLanguages = <TopicLanguage>[
    TopicLanguage(code: 'ar', label: 'العربية'),
    TopicLanguage(code: 'es-US', label: 'Español (Latinoamérica)'),
    TopicLanguage(code: 'es-ES', label: 'Español (España)'),
    TopicLanguage(code: 'ru', label: 'Русский'),
    TopicLanguage(code: 'uk', label: 'Українська'),
    TopicLanguage(code: 'vi', label: 'Tiếng Việt'),
    TopicLanguage(code: 'de', label: 'Deutsch'),
    TopicLanguage(code: 'th', label: 'ไทย'),
    TopicLanguage(code: 'ja', label: '日本語'),
    TopicLanguage(code: 'tr', label: 'Türkçe'),
    TopicLanguage(code: 'pt', label: 'Português'),
    TopicLanguage(code: 'cs', label: 'Čeština'),
    TopicLanguage(code: 'da', label: 'Dansk'),
    TopicLanguage(code: 'fi', label: 'Suomi'),
    TopicLanguage(code: 'fil', label: 'Filipino'),
    TopicLanguage(code: 'fr', label: 'Français'),
    TopicLanguage(code: 'hi', label: 'हिन्दी'),
    TopicLanguage(code: 'hu', label: 'Magyar'),
    TopicLanguage(code: 'in', label: 'Bahasa Indonesia'),
    TopicLanguage(code: 'it', label: 'Italiano'),
    TopicLanguage(code: 'iw', label: 'עברית'),
    TopicLanguage(code: 'ko', label: '한국어'),
    TopicLanguage(code: 'ms', label: 'Bahasa Melayu'),
    TopicLanguage(code: 'nb', label: 'Norsk bokmål'),
    TopicLanguage(code: 'nl', label: 'Nederlands'),
    TopicLanguage(code: 'pl', label: 'Polski'),
    TopicLanguage(code: 'ro', label: 'Română'),
    TopicLanguage(code: 'sv', label: 'Svenska'),
    TopicLanguage(code: 'zh-TW', label: '繁體中文'),
    TopicLanguage(code: 'zh', label: '简体中文'),
  ];

  static String canonicalizeLanguageCode(String languageCode) {
    return canonicalLanguageCode(languageCode);
  }

  Future<List<TopicLanguage>> loadAvailableLanguages() async {
    return knownLanguages;
  }

  Future<TopicAssetPayload> load({String languageCode = 'vi'}) async {
    final canonicalCode = canonicalizeLanguageCode(languageCode);
    // The backend currently has no data_en_en.json. Reuse the Vietnamese
    // source catalogue and map its translated fields to the English source.
    final remoteCode = canonicalCode == 'en' ? 'vi' : canonicalCode;
    final response = await _apiClient.get(
      '$_topicRemoteDirectory/data_en_$remoteCode.json',
    );
    final data = response.mapData;
    if (data == null) {
      throw const FormatException('Topic response must contain a JSON object.');
    }
    if (data['topics'] is! List) {
      throw const FormatException(
        'Topic response does not contain a topics package.',
      );
    }
    final payload = TopicAssetPayload.fromJson(data);
    if (payload.topics.isEmpty) {
      throw const FormatException('Topic package is empty.');
    }
    return canonicalCode == 'en' ? _mapEnglishTopicPayload(payload) : payload;
  }
}

TopicAssetPayload _mapEnglishTopicPayload(TopicAssetPayload payload) {
  return TopicAssetPayload(
    version: payload.version,
    topics: payload.topics
        .map(
          (topic) => TopicAssetItem(
            id: topic.id,
            order: topic.order,
            original: topic.original,
            translated: topic.original,
            isEnabled: topic.isEnabled,
            words: topic.words
                .map(
                  (word) => WordAssetItem(
                    id: word.id,
                    writing: word.writing,
                    translation: word.writing,
                    transcription: word.transcription,
                    transliteration: word.transliteration,
                    isEnabled: word.isEnabled,
                    priority: word.priority,
                    level: word.level,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
  );
}
