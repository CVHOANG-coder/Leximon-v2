import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';

TopicAssetDataSource testTopicDataSource() {
  return TopicAssetDataSource(
    apiClient: ApiClient(
      client: MockClient((request) async {
        final code = request.url.pathSegments.last
            .replaceFirst('data_en_', '')
            .replaceFirst('.json', '');
        final isGerman = code == 'de';
        final topicNames = isGerman
            ? const ['Reisen', 'Arbeit', 'Essen']
            : const ['Du lịch', 'Công việc', 'Đồ ăn'];
        final wordTranslations = isGerman
            ? const ['reisen', 'arbeiten', 'essen', 'gut']
            : const ['du lịch', 'làm việc', 'đồ ăn', 'tốt'];

        return http.Response(
          jsonEncode({
            'version': 36,
            'topics': [
              for (var index = 0; index < topicNames.length; index++)
                {
                  'id': index + 1,
                  'order': [2, 5, 8][index],
                  'original': ['Travel', 'Work', 'Food'][index],
                  'translated': topicNames[index],
                  'enabled': true,
                  'words': [
                    {
                      'id': index + 1,
                      'writing': ['travel', 'work', 'food'][index],
                      'translation': wordTranslations[index],
                      'enabled': true,
                      'priority': 1,
                      'level': 1,
                    },
                    if (index == 0)
                      {
                        'id': 100,
                        'writing': 'trip',
                        'translation': wordTranslations[3],
                        'enabled': true,
                        'priority': 1,
                        'level': 1,
                      },
                  ],
                },
            ],
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}
