import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/topic_asset_payload.dart';

const _topicAssetPath = 'assets/data/topic_word_params.json';

class TopicAssetDataSource {
  TopicAssetDataSource({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;

  Future<TopicAssetPayload> load() async {
    final rawJson = await bundle.loadString(_topicAssetPath);
    return compute(_decodeTopicPayload, rawJson);
  }
}

TopicAssetPayload _decodeTopicPayload(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Topic asset must contain a JSON object.');
  }
  return TopicAssetPayload.fromJson(decoded);
}
