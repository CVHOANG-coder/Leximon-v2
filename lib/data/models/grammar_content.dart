class GrammarPackContent {
  const GrammarPackContent({
    required this.id,
    required this.guid,
    required this.level,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.progress,
    required this.topics,
  });

  final int id;
  final String guid;
  final String level;
  final String title;
  final String description;
  final String iconAsset;
  final int progress;
  final List<GrammarTopicContent> topics;

  int get lessonCount => topics.length;
}

class GrammarTopicContent {
  const GrammarTopicContent({
    required this.id,
    required this.packId,
    required this.label,
    required this.questionCount,
    required this.progress,
    required this.isComplete,
  });

  final int id;
  final int packId;
  final String label;
  final int questionCount;
  final int progress;
  final bool isComplete;
}

class GrammarQuestionContent {
  const GrammarQuestionContent({
    required this.id,
    required this.topicId,
    required this.type,
    required this.rubricJson,
    required this.cluesJson,
    required this.bodyJson,
    required this.leftColumnJson,
    required this.rightColumnJson,
    required this.layout,
    required this.optionsLayout,
    required this.responseType,
    required this.optionsJson,
    required this.answersJson,
    required this.modelParagraph,
    this.savedResponse,
  });

  final int id;
  final int topicId;
  final String type;
  final String rubricJson;
  final String cluesJson;
  final String bodyJson;
  final String leftColumnJson;
  final String rightColumnJson;
  final String layout;
  final String optionsLayout;
  final String responseType;
  final String optionsJson;
  final String answersJson;
  final String modelParagraph;
  final GrammarSavedResponse? savedResponse;
}

class GrammarSavedResponse {
  const GrammarSavedResponse({
    required this.responseData,
    required this.isCorrect,
    required this.updatedAt,
  });

  final String responseData;
  final bool isCorrect;
  final DateTime updatedAt;
}
