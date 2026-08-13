import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/services/speaking_answer_checker.dart';

void main() {
  const checker = SpeakingAnswerChecker();

  test('marks correct, wrong and missing words independently', () {
    final result = checker.check(
      expected: 'I would like some orange juice',
      transcript: 'I would love orange juice',
    );

    expect(result.accuracyPercent, 67);
    expect(result.isCorrect, isFalse);
    expect(
      result.words.map((word) => word.status),
      containsAll(<SpeakingWordStatus>[
        SpeakingWordStatus.correct,
        SpeakingWordStatus.incorrect,
        SpeakingWordStatus.missing,
      ]),
    );
  });

  test('accepts punctuation and capitalization differences', () {
    final result = checker.check(
      expected: "Good morning, how are you?",
      transcript: 'good morning how are you',
    );

    expect(result.accuracyPercent, 100);
    expect(result.isCorrect, isTrue);
    expect(
      result.words.every((word) => word.status == SpeakingWordStatus.correct),
      isTrue,
    );
  });
}
