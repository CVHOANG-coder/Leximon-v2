enum SpeakingWordStatus { correct, incorrect, missing, extra }

class SpeakingWordResult {
  const SpeakingWordResult({required this.text, required this.status});

  final String text;
  final SpeakingWordStatus status;
}

class SpeakingAssessment {
  const SpeakingAssessment({
    required this.words,
    required this.accuracyPercent,
    required this.isCorrect,
  });

  final List<SpeakingWordResult> words;
  final int accuracyPercent;
  final bool isCorrect;
}

/// Aligns the expected sentence and speech transcript with edit-distance.
/// This lets the UI distinguish a substituted word from one that was omitted.
class SpeakingAnswerChecker {
  const SpeakingAnswerChecker({this.correctThreshold = 80});

  final int correctThreshold;

  SpeakingAssessment check({
    required String expected,
    required String transcript,
  }) {
    final expectedWords = _tokens(expected);
    final spokenWords = _tokens(transcript);
    if (expectedWords.isEmpty) {
      return const SpeakingAssessment(
        words: [],
        accuracyPercent: 0,
        isCorrect: false,
      );
    }

    final rows = expectedWords.length + 1;
    final columns = spokenWords.length + 1;
    final distance = List.generate(rows, (row) => List<int>.filled(columns, 0));
    for (var row = 0; row < rows; row++) {
      distance[row][0] = row;
    }
    for (var column = 0; column < columns; column++) {
      distance[0][column] = column;
    }
    for (var row = 1; row < rows; row++) {
      for (var column = 1; column < columns; column++) {
        final substitution =
            distance[row - 1][column - 1] +
            (expectedWords[row - 1] == spokenWords[column - 1] ? 0 : 1);
        final deletion = distance[row - 1][column] + 1;
        final insertion = distance[row][column - 1] + 1;
        distance[row][column] = _min(substitution, deletion, insertion);
      }
    }

    var row = expectedWords.length;
    var column = spokenWords.length;
    final reversed = <SpeakingWordResult>[];
    var correctWords = 0;
    while (row > 0 || column > 0) {
      if (row > 0 && column > 0) {
        final same = expectedWords[row - 1] == spokenWords[column - 1];
        final substitutionCost = distance[row - 1][column - 1] + (same ? 0 : 1);
        if (distance[row][column] == substitutionCost) {
          reversed.add(
            SpeakingWordResult(
              text: expectedWords[row - 1],
              status: same
                  ? SpeakingWordStatus.correct
                  : SpeakingWordStatus.incorrect,
            ),
          );
          if (same) correctWords++;
          row--;
          column--;
          continue;
        }
      }
      if (row > 0 && distance[row][column] == distance[row - 1][column] + 1) {
        reversed.add(
          SpeakingWordResult(
            text: expectedWords[row - 1],
            status: SpeakingWordStatus.missing,
          ),
        );
        row--;
        continue;
      }
      if (column > 0) {
        reversed.add(
          SpeakingWordResult(
            text: spokenWords[column - 1],
            status: SpeakingWordStatus.extra,
          ),
        );
        column--;
      }
    }

    final accuracy = (correctWords * 100 / expectedWords.length).round();
    return SpeakingAssessment(
      words: reversed.reversed.toList(growable: false),
      accuracyPercent: accuracy,
      isCorrect: accuracy >= correctThreshold,
    );
  }

  List<String> _tokens(String value) => RegExp(
    r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)?",
  ).allMatches(value.toLowerCase()).map((match) => match.group(0)!).toList();

  int _min(int first, int second, int third) {
    var result = first < second ? first : second;
    if (third < result) result = third;
    return result;
  }
}
