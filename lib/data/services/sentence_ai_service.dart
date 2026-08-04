import 'dart:convert';
import 'dart:io';

import '../models/sentence_exercise.dart';

class SentenceAiService {
  const SentenceAiService();

  static final _endpoint = Uri.parse(
    'https://engbright.com/api/v1/vocabulary/sentences/ai/',
  );

  Future<String?> explain({
    required SentenceExercise exercise,
    required String userAnswer,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(_endpoint);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'application': 'en',
          'sentence_translation_id': exercise.sentence.translationId,
          'user_answer': userAnswer,
          'training_type': exercise.trainingType,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final source = await utf8.decoder.bind(response).join();
      final json = jsonDecode(source) as Map<String, dynamic>;
      final explanation = json['ai_answer'] as String?;
      return explanation?.trim().isNotEmpty == true
          ? explanation!.trim()
          : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
