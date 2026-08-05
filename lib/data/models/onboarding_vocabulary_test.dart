import 'sentence_exercise.dart';

enum VocabularyTaskType {
  text,
  inverseText,
  audioThree,
  audioFour,
  constructor;

  factory VocabularyTaskType.fromAssetValue(String value) {
    return switch (value) {
      '1/4 text' => VocabularyTaskType.text,
      '1/4 text inverse' => VocabularyTaskType.inverseText,
      '1/3 audio' => VocabularyTaskType.audioThree,
      '1/4 audio' => VocabularyTaskType.audioFour,
      'Constructor' => VocabularyTaskType.constructor,
      _ => throw FormatException('Unsupported vocabulary task type: $value'),
    };
  }
}

enum VocabularyStartingBand {
  beginner('beginner', BrightLevel.a2),
  intermediate('intermediate', BrightLevel.b2),
  advanced('advanced', BrightLevel.c2);

  const VocabularyStartingBand(this.queryValue, this.initialLevel);

  final String queryValue;
  final BrightLevel initialLevel;

  factory VocabularyStartingBand.fromQuery(String? value) {
    return values.firstWhere(
      (band) => band.queryValue == value,
      orElse: () => VocabularyStartingBand.beginner,
    );
  }
}

enum BrightLevel {
  a1('A1'),
  a2('A2'),
  a3('A3'),
  b1('B1'),
  b2('B2'),
  b3('B3'),
  c1('C1'),
  c2('C2'),
  c3('C3');

  const BrightLevel(this.label);

  final String label;

  factory BrightLevel.fromAssetValue(String value) {
    return values.firstWhere(
      (level) => level.label == value,
      orElse: () => throw FormatException('Unsupported Bright level: $value'),
    );
  }
}

class VocabularyTestDefinition {
  const VocabularyTestDefinition({
    required this.id,
    required this.task,
    required this.frequency,
    required this.type,
    required this.level,
  });

  factory VocabularyTestDefinition.fromJson(Map<String, dynamic> json) {
    return VocabularyTestDefinition(
      id: json['id'] as int,
      task: json['task'] as String,
      frequency: json['frequency'] as int,
      type: VocabularyTaskType.fromAssetValue(json['taskType'] as String),
      level: BrightLevel.fromAssetValue(json['brightLevel'] as String),
    );
  }

  final int id;
  final String task;
  final int frequency;
  final VocabularyTaskType type;
  final BrightLevel level;
}

class VocabularyTestChoice {
  const VocabularyTestChoice({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;
}

class VocabularyTestQuestion {
  const VocabularyTestQuestion({
    required this.definition,
    required this.writing,
    required this.translation,
    required this.transcription,
    required this.choices,
    this.sentenceExercise,
  });

  final VocabularyTestDefinition definition;
  final String writing;
  final String translation;
  final String transcription;
  final List<VocabularyTestChoice> choices;
  final SentenceExercise? sentenceExercise;

  bool get isConstructor => definition.type == VocabularyTaskType.constructor;

  bool get hasSentenceExercise => sentenceExercise != null;
}

class VocabularyAssessmentNode {
  const VocabularyAssessmentNode(this.level, {this.failed, this.passed});

  final BrightLevel level;
  final VocabularyAssessmentNode? failed;
  final VocabularyAssessmentNode? passed;

  bool get isResult => failed == null && passed == null;

  VocabularyAssessmentNode next({required bool didPass}) {
    final node = didPass ? passed : failed;
    if (node == null) {
      throw StateError('A result node does not have another assessment part.');
    }
    return node;
  }
}

abstract final class VocabularyAssessmentTree {
  static VocabularyAssessmentNode forBand(VocabularyStartingBand band) {
    return switch (band) {
      VocabularyStartingBand.beginner => _beginner(),
      VocabularyStartingBand.intermediate => _intermediate(),
      VocabularyStartingBand.advanced => _advanced(),
    };
  }

  static VocabularyAssessmentNode _result(BrightLevel level) =>
      VocabularyAssessmentNode(level);

  static VocabularyAssessmentNode _beginner() {
    return VocabularyAssessmentNode(
      BrightLevel.a2,
      failed: VocabularyAssessmentNode(
        BrightLevel.a1,
        failed: _result(BrightLevel.a1),
        passed: _result(BrightLevel.a1),
      ),
      passed: VocabularyAssessmentNode(
        BrightLevel.a3,
        failed: VocabularyAssessmentNode(
          BrightLevel.a1,
          failed: _result(BrightLevel.a1),
          passed: _result(BrightLevel.a2),
        ),
        passed: VocabularyAssessmentNode(
          BrightLevel.b1,
          failed: _result(BrightLevel.a3),
          passed: _result(BrightLevel.b1),
        ),
      ),
    );
  }

  static VocabularyAssessmentNode _intermediate() {
    return VocabularyAssessmentNode(
      BrightLevel.b2,
      failed: VocabularyAssessmentNode(
        BrightLevel.b1,
        failed: VocabularyAssessmentNode(
          BrightLevel.a3,
          failed: _result(BrightLevel.a2),
          passed: _result(BrightLevel.a3),
        ),
        passed: VocabularyAssessmentNode(
          BrightLevel.a3,
          failed: _result(BrightLevel.a2),
          passed: _result(BrightLevel.b1),
        ),
      ),
      passed: VocabularyAssessmentNode(
        BrightLevel.b3,
        failed: VocabularyAssessmentNode(
          BrightLevel.b1,
          failed: _result(BrightLevel.a3),
          passed: _result(BrightLevel.b1),
        ),
        passed: VocabularyAssessmentNode(
          BrightLevel.c1,
          failed: _result(BrightLevel.b3),
          passed: _result(BrightLevel.c1),
        ),
      ),
    );
  }

  static VocabularyAssessmentNode _advanced() {
    return VocabularyAssessmentNode(
      BrightLevel.c2,
      failed: VocabularyAssessmentNode(
        BrightLevel.c1,
        failed: VocabularyAssessmentNode(
          BrightLevel.b3,
          failed: _result(BrightLevel.b2),
          passed: _result(BrightLevel.b3),
        ),
        passed: VocabularyAssessmentNode(
          BrightLevel.b3,
          failed: _result(BrightLevel.b2),
          passed: _result(BrightLevel.b3),
        ),
      ),
      passed: VocabularyAssessmentNode(
        BrightLevel.c3,
        failed: VocabularyAssessmentNode(
          BrightLevel.c1,
          failed: _result(BrightLevel.b3),
          passed: _result(BrightLevel.c2),
        ),
        passed: VocabularyAssessmentNode(
          BrightLevel.c2,
          failed: _result(BrightLevel.c1),
          passed: _result(BrightLevel.c2),
        ),
      ),
    );
  }
}
