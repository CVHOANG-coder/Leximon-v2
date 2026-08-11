import '../models/listening_exercise.dart';

class ListeningAnswerResult {
  const ListeningAnswerResult({
    required this.isCorrect,
    required this.acceptedAnswer,
    required this.matchingPrefixLength,
  });

  final bool isCorrect;
  final String acceptedAnswer;
  final int matchingPrefixLength;
}

class ListeningAnswerChecker {
  const ListeningAnswerChecker();

  ListeningAnswerResult check(String input, ListeningChallenge challenge) {
    final candidates = _expandSolutions(challenge.solutions);
    if (candidates.isEmpty) candidates.add(challenge.content);
    final normalizedInput = _normalize(input);
    for (final candidate in candidates) {
      if (_normalize(candidate) == normalizedInput) {
        return ListeningAnswerResult(
          isCorrect: true,
          acceptedAnswer: candidate,
          matchingPrefixLength: candidate.split(RegExp(r'\s+')).length,
        );
      }
    }

    var bestCandidate = candidates.first;
    var bestPrefix = -1;
    final inputWords = normalizedInput
        .split(' ')
        .where((word) => word.isNotEmpty);
    for (final candidate in candidates) {
      final candidateWords = _normalize(candidate).split(' ');
      final typedWords = inputWords.toList();
      var prefix = 0;
      while (prefix < typedWords.length &&
          prefix < candidateWords.length &&
          typedWords[prefix] == candidateWords[prefix]) {
        prefix++;
      }
      if (prefix > bestPrefix) {
        bestPrefix = prefix;
        bestCandidate = candidate;
      }
    }
    return ListeningAnswerResult(
      isCorrect: false,
      acceptedAnswer: bestCandidate,
      matchingPrefixLength: bestPrefix < 0 ? 0 : bestPrefix,
    );
  }

  List<String> _expandSolutions(List<List<String>> tokens) {
    var answers = <String>[''];
    for (final variants in tokens) {
      final next = <String>[];
      for (final prefix in answers) {
        for (final variant in variants) {
          next.add(prefix.isEmpty ? variant : '$prefix $variant');
        }
      }
      answers = next;
    }
    return answers;
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (match) => match.group(1)!)
      .replaceFirst(RegExp(r'[.!?]+$'), '');
}
