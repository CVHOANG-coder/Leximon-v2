import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/topic.dart';

class TopicRepository {
  const TopicRepository();

  Future<List<Topic>> loadTopics() async {
    final raw = await rootBundle.loadString(
      'assets/data/topic_word_params.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final topics = (decoded['topics'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((topic) => topic['enabled'] == true)
        .map(Topic.fromJson)
        .toList();
    topics.sort((a, b) => a.order.compareTo(b.order));
    return topics;
  }
}
