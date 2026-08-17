import 'dart:convert';

import '../../core/localization/app_localizations.dart';
import '../models/grammar_content.dart';

class GrammarQuestionViewData {
  GrammarQuestionViewData._({
    required this.source,
    required this.rubric,
    required this.body,
    required this.leftColumn,
    required this.rightColumn,
    required this.options,
    required this.answers,
  });

  factory GrammarQuestionViewData.fromContent(GrammarQuestionContent source) {
    return GrammarQuestionViewData._(
      source: source,
      rubric: _decodeElements(source.rubricJson),
      body: _decodeElements(source.bodyJson),
      leftColumn: _decodeElements(source.leftColumnJson),
      rightColumn: _decodeElements(source.rightColumnJson),
      options: _decodeElements(source.optionsJson),
      answers: jsonDecode(source.answersJson),
    );
  }

  final GrammarQuestionContent source;
  final List<GrammarQuestionElement> rubric;
  final List<GrammarQuestionElement> body;
  final List<GrammarQuestionElement> leftColumn;
  final List<GrammarQuestionElement> rightColumn;
  final List<GrammarQuestionElement> options;
  final Object? answers;

  String get type => source.type.toUpperCase();
  String get responseType => source.responseType.toUpperCase();
  String get layout => source.layout.toUpperCase();
  String get instruction => rubric
      .where((element) => element.type == GrammarElementType.text)
      .map((element) => element.data)
      .join('\n');

  List<GrammarQuestionElement> get answerBody =>
      body.isNotEmpty ? body : rightColumn;

  int get gapCount => answerBody
      .where((element) => element.type == GrammarElementType.gap)
      .length;

  String? get requiredWord {
    for (final element in [...body, ...rightColumn, ...leftColumn]) {
      final word = element.requiredWord;
      if (word != null && word.isNotEmpty) return word;
    }
    return null;
  }

  static List<GrammarQuestionElement> _decodeElements(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.map(GrammarQuestionElement.fromJson).toList(growable: false);
  }
}

enum GrammarElementType { text, image, audio, gap, unknown }

class GrammarQuestionElement {
  const GrammarQuestionElement({
    required this.type,
    required this.data,
    this.requiredWord,
  }) : _textSegments = null;

  const GrammarQuestionElement.withSegments({
    required this.type,
    required this.data,
    required this._textSegments,
    this.requiredWord,
  });

  factory GrammarQuestionElement.fromJson(Object? value) {
    if (value == 'GAP') {
      return const GrammarQuestionElement(
        type: GrammarElementType.gap,
        data: '',
      );
    }
    if (value is! Map<String, dynamic>) {
      return GrammarQuestionElement(
        type: GrammarElementType.unknown,
        data: value?.toString() ?? '',
      );
    }
    final type = switch ((value['type'] as String? ?? '').toLowerCase()) {
      'text' => GrammarElementType.text,
      'image' => GrammarElementType.image,
      'audio' => GrammarElementType.audio,
      _ => GrammarElementType.unknown,
    };
    final rawData = value['data']?.toString() ?? '';
    final requiredWord = RegExp(
      r'<word>(.*?)</word>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(rawData)?.group(1)?.trim();
    final cleanedData = _cleanText(rawData);
    return GrammarQuestionElement.withSegments(
      type: type,
      data: _plainText(cleanedData),
      textSegments: _parseTextSegments(cleanedData),
      requiredWord: requiredWord,
    );
  }

  final GrammarElementType type;
  final String data;
  final List<GrammarTextSegment>? _textSegments;
  final String? requiredWord;

  List<GrammarTextSegment> get textSegments =>
      _textSegments ?? const <GrammarTextSegment>[];

  static String _cleanText(String value) => value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(
        RegExp(r'<word>.*?</word>', caseSensitive: false, dotAll: true),
        '',
      )
      .trim();

  static String _plainText(String value) => value
      .replaceAllMapped(
        RegExp(r'<em>(.*?)</em>', caseSensitive: false, dotAll: true),
        (match) => match.group(1) ?? '',
      )
      .trim();

  static List<GrammarTextSegment> _parseTextSegments(String value) {
    if (value.isEmpty) return const [];
    final expression = RegExp(
      r'<em>(.*?)</em>',
      caseSensitive: false,
      dotAll: true,
    );
    final segments = <GrammarTextSegment>[];
    var cursor = 0;
    for (final match in expression.allMatches(value)) {
      if (match.start > cursor) {
        segments.add(
          GrammarTextSegment(text: value.substring(cursor, match.start)),
        );
      }
      segments.add(
        GrammarTextSegment(text: match.group(1) ?? '', emphasized: true),
      );
      cursor = match.end;
    }
    if (cursor < value.length) {
      segments.add(GrammarTextSegment(text: value.substring(cursor)));
    }
    return segments;
  }
}

class GrammarTextSegment {
  const GrammarTextSegment({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;
}

class GrammarAnswerDraft {
  GrammarAnswerDraft({
    Set<int>? selections,
    List<int>? order,
    List<int?>? gapChoices,
    List<String>? gapTexts,
    List<int?>? groups,
  }) : selections = selections ?? <int>{},
       order = order ?? <int>[],
       gapChoices = gapChoices ?? <int?>[],
       gapTexts = gapTexts ?? <String>[],
       groups = groups ?? <int?>[];

  final Set<int> selections;
  final List<int> order;
  final List<int?> gapChoices;
  final List<String> gapTexts;
  final List<int?> groups;

  factory GrammarAnswerDraft.empty(GrammarQuestionViewData question) {
    return GrammarAnswerDraft(
      gapChoices: List<int?>.filled(question.gapCount, null),
      gapTexts: List<String>.filled(question.gapCount, ''),
      groups: List<int?>.filled(question.body.length, null),
    );
  }

  factory GrammarAnswerDraft.restore(
    GrammarQuestionViewData question,
    String responseData,
  ) {
    final draft = GrammarAnswerDraft.empty(question);
    if (responseData.isEmpty) return draft;
    final decoded = jsonDecode(responseData);
    if (decoded is! List) return draft;
    if (question.type == 'MCQ' || question.type == 'LABELLING') {
      draft.selections.addAll(
        decoded.whereType<num>().map((value) => value.toInt()),
      );
    } else if (question.type == 'FIB' && question.responseType == 'TEXT') {
      for (
        var index = 0;
        index < draft.gapTexts.length && index < decoded.length;
        index++
      ) {
        draft.gapTexts[index] = decoded[index]?.toString() ?? '';
      }
    } else if (question.type == 'FIB') {
      for (
        var index = 0;
        index < draft.gapChoices.length && index < decoded.length;
        index++
      ) {
        final value = decoded[index];
        draft.gapChoices[index] = value is num ? value.toInt() : null;
      }
    } else if (question.type == 'GROUPING') {
      for (
        var index = 0;
        index < draft.groups.length && index < decoded.length;
        index++
      ) {
        final value = decoded[index];
        draft.groups[index] = value is num ? value.toInt() : null;
      }
    } else {
      draft.order.addAll(
        decoded.whereType<num>().map((value) => value.toInt()),
      );
    }
    return draft;
  }
}

class GrammarQuestionEngine {
  const GrammarQuestionEngine({this.localizations});

  final AppLocalizations? localizations;

  AppLocalizations get _l10n => localizations ?? AppLocalizations.fallback();

  bool isComplete(GrammarQuestionViewData question, GrammarAnswerDraft draft) {
    return switch (question.type) {
      'MCQ' || 'LABELLING' => draft.selections.isNotEmpty,
      'FIB' when question.responseType == 'TEXT' =>
        draft.gapTexts.isNotEmpty &&
            draft.gapTexts.every((answer) => answer.trim().isNotEmpty),
      'FIB' =>
        draft.gapChoices.isNotEmpty &&
            draft.gapChoices.every((answer) => answer != null),
      'REORDERING' || 'MATCHSORT' =>
        draft.order.length == question.options.length &&
            draft.order.every((answer) => answer > 0) &&
            draft.order.toSet().length == question.options.length,
      'GROUPING' =>
        draft.groups.isNotEmpty && draft.groups.every((group) => group != null),
      _ => false,
    };
  }

  bool check(GrammarQuestionViewData question, GrammarAnswerDraft draft) {
    if (!isComplete(question, draft)) return false;
    return switch (question.type) {
      'MCQ' || 'LABELLING' => _sameSet(
        draft.selections,
        _numberList(question.answers).toSet(),
      ),
      'FIB' when question.responseType == 'TEXT' => _checkTextGaps(
        draft.gapTexts,
        question.answers,
      ),
      'FIB' => _checkChoiceGaps(
        draft.gapChoices.whereType<int>().toList(),
        question.answers,
      ),
      'REORDERING' || 'MATCHSORT' => _sameList(
        draft.order,
        List<int>.generate(question.options.length, (index) => index + 1),
      ),
      'GROUPING' => _sameList(
        draft.groups.whereType<int>().toList(),
        _groupAnswers(question.answers),
      ),
      _ => false,
    };
  }

  String serialize(GrammarQuestionViewData question, GrammarAnswerDraft draft) {
    final Object value = switch (question.type) {
      'MCQ' || 'LABELLING' => (draft.selections.toList()..sort()),
      'FIB' when question.responseType == 'TEXT' => draft.gapTexts,
      'FIB' => draft.gapChoices,
      'GROUPING' => draft.groups,
      _ => draft.order,
    };
    return jsonEncode(value);
  }

  List<String> correctAnswerLines(GrammarQuestionViewData question) {
    final List<String> lines = switch (question.type) {
      'MCQ' => [
        _numberList(
          question.answers,
        ).map((index) => _optionLabel(question, index)).join(' / '),
      ],
      'FIB' when question.responseType == 'TEXT' => _textAnswerLines(
        question.answers,
        question.gapCount,
      ),
      'FIB' => _choiceGapAnswerLines(question),
      'REORDERING' => [question.options.map((option) => option.data).join(' ')],
      'MATCHSORT' => [
        for (var index = 0; index < question.options.length; index++)
          '${index < question.body.length ? question.body[index].data : index + 1} → ${question.options[index].data}',
      ],
      'LABELLING' => [_labellingAnswer(question)],
      'GROUPING' => _groupingAnswerLines(question),
      _ => const <String>[],
    };
    return lines.where((line) => line.trim().isNotEmpty).toList();
  }

  static List<int> _numberList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<num>().map((item) => item.toInt()).toList();
  }

  static String _optionLabel(GrammarQuestionViewData question, int index) {
    if (index < 1 || index > question.options.length) return '#$index';
    return question.options[index - 1].data;
  }

  List<String> _choiceGapAnswerLines(GrammarQuestionViewData question) {
    final rawAnswers = question.answers;
    if (rawAnswers is! List || rawAnswers.isEmpty) return const [];
    if (rawAnswers.first is List) {
      return [
        _numberList(
          rawAnswers.first,
        ).map((index) => _optionLabel(question, index)).join(' / '),
      ];
    }
    final answers = _numberList(rawAnswers);
    if (answers.length == 1) {
      return [_optionLabel(question, answers.single)];
    }
    return [
      for (var index = 0; index < answers.length; index++)
        _l10n.text(
          'grammarAnswerSlot',
          values: {
            'number': '${index + 1}',
            'answer': _optionLabel(question, answers[index]),
          },
        ),
    ];
  }

  List<String> _textAnswerLines(Object? rawAnswers, int gapCount) {
    if (rawAnswers is! List || rawAnswers.isEmpty) return const [];
    if (gapCount == 1) {
      final alternatives = <String>[
        for (final answer in rawAnswers)
          if (answer is List)
            ...answer.map((value) => value.toString())
          else
            answer.toString(),
      ];
      return [alternatives.join(' / ')];
    }
    return [
      for (var index = 0; index < rawAnswers.length; index++)
        _l10n.text(
          'grammarAnswerSlot',
          values: {
            'number': '${index + 1}',
            'answer': rawAnswers[index] is List
                ? (rawAnswers[index] as List).join(' / ')
                : '${rawAnswers[index]}',
          },
        ),
    ];
  }

  static String _labellingAnswer(GrammarQuestionViewData question) {
    final words = question.body
        .where((element) => element.type == GrammarElementType.text)
        .map((element) => element.data)
        .join(' ')
        .split(RegExp(r'\s+'));
    return _numberList(question.answers)
        .map(
          (position) => position > 0 && position <= words.length
              ? words[position - 1]
              : '#$position',
        )
        .join(', ');
  }

  static List<String> _groupingAnswerLines(GrammarQuestionViewData question) {
    final assignments = _groupAnswers(question.answers);
    return [
      for (var group = 1; group <= question.options.length; group++)
        '${question.options[group - 1].data}: ${[for (var index = 0; index < question.body.length && index < assignments.length; index++)
          if (assignments[index] == group) question.body[index].data].join(', ')}',
    ];
  }

  static bool _checkChoiceGaps(List<int> response, Object? rawAnswers) {
    if (rawAnswers is! List || rawAnswers.isEmpty) return false;
    if (rawAnswers.first is List) {
      if (response.length != 1) return false;
      return _numberList(rawAnswers.first).contains(response.single);
    }
    return _sameList(response, _numberList(rawAnswers));
  }

  static List<int> _groupAnswers(Object? value) {
    if (value is! List || value.isEmpty) return const [];
    return _numberList(value.first);
  }

  static bool _checkTextGaps(List<String> response, Object? rawAnswers) {
    if (rawAnswers is! List || rawAnswers.isEmpty) return false;
    final acceptedByGap = <List<String>>[];
    if (response.length == 1) {
      acceptedByGap.add([
        for (final alternative in rawAnswers)
          if (alternative is List)
            ...alternative.map((value) => value.toString())
          else
            alternative.toString(),
      ]);
    } else if (rawAnswers.length == response.length) {
      for (final answers in rawAnswers) {
        acceptedByGap.add(
          answers is List
              ? answers.map((value) => value.toString()).toList()
              : [answers.toString()],
        );
      }
    } else {
      return false;
    }
    for (var index = 0; index < response.length; index++) {
      final normalized = _normalize(response[index]);
      if (!acceptedByGap[index].any(
        (answer) => _normalize(answer) == normalized,
      )) {
        return false;
      }
    }
    return true;
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool _sameSet(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);

  static bool _sameList(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
