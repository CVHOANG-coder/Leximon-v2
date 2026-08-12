import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/grammar_content.dart';
import 'package:leximon/data/services/grammar_question_engine.dart';

void main() {
  const engine = GrammarQuestionEngine();

  GrammarQuestionViewData question({
    required String type,
    String responseType = '',
    List<Object?> body = const [],
    List<Object?> options = const [],
    Object answers = const [],
  }) {
    return GrammarQuestionViewData.fromContent(
      GrammarQuestionContent(
        id: 1,
        topicId: 1,
        type: type,
        rubricJson: '[]',
        cluesJson: '[]',
        bodyJson: jsonEncode(body),
        leftColumnJson: '[]',
        rightColumnJson: '[]',
        layout: '',
        optionsLayout: '',
        responseType: responseType,
        optionsJson: jsonEncode(options),
        answersJson: jsonEncode(answers),
        modelParagraph: '',
      ),
    );
  }

  test('checks single and multiple choice answers as one-based sets', () {
    final item = question(
      type: 'MCQ',
      options: const [
        {'type': 'text', 'data': 'A'},
        {'type': 'text', 'data': 'B'},
        {'type': 'text', 'data': 'C'},
      ],
      answers: const [1, 3],
    );
    final draft = GrammarAnswerDraft(selections: {3, 1});
    expect(engine.check(item, draft), isTrue);
    expect(engine.serialize(item, draft), '[1,3]');
    expect(engine.correctAnswerLines(item), ['A / C']);
  });

  test('accepts text alternatives without case or extra spaces', () {
    final item = question(
      type: 'FIB',
      responseType: 'TEXT',
      body: const [
        {'type': 'text', 'data': 'I '},
        'GAP',
      ],
      answers: const [
        ['am going', "'m going"],
      ],
    );
    final draft = GrammarAnswerDraft(gapTexts: ['  AM   GOING ']);
    expect(engine.check(item, draft), isTrue);
    expect(engine.correctAnswerLines(item), ["am going / 'm going"]);
  });

  test('checks choice gaps, natural reordering, labelling and grouping', () {
    final fib = question(
      type: 'FIB',
      responseType: 'DRAGDROP',
      body: const ['GAP', 'GAP'],
      answers: const [2, 1],
    );
    expect(engine.check(fib, GrammarAnswerDraft(gapChoices: [2, 1])), isTrue);

    final fibWithAlternatives = question(
      type: 'FIB',
      responseType: 'BUTTON',
      body: const ['GAP'],
      answers: const [
        [1, 4],
      ],
    );
    expect(
      engine.check(fibWithAlternatives, GrammarAnswerDraft(gapChoices: [4])),
      isTrue,
    );

    final reorder = question(
      type: 'REORDERING',
      options: const [
        {'type': 'text', 'data': 'I'},
        {'type': 'text', 'data': 'am'},
        {'type': 'text', 'data': 'here'},
      ],
    );
    expect(engine.check(reorder, GrammarAnswerDraft(order: [1, 2, 3])), isTrue);

    final label = question(type: 'LABELLING', answers: const [2, 6]);
    expect(engine.check(label, GrammarAnswerDraft(selections: {6, 2})), isTrue);

    final grouping = question(
      type: 'GROUPING',
      body: const [
        {'type': 'text', 'data': 'train'},
        {'type': 'text', 'data': 'air'},
      ],
      answers: const [
        [2, 1],
      ],
    );
    expect(engine.check(grouping, GrammarAnswerDraft(groups: [2, 1])), isTrue);
  });

  test('restores a saved response into the matching draft shape', () {
    final item = question(
      type: 'FIB',
      responseType: 'TEXT',
      body: const ['GAP', 'GAP'],
    );
    final draft = GrammarAnswerDraft.restore(item, '["There","is"]');
    expect(draft.gapTexts, ['There', 'is']);
  });

  test('extracts the required rewrite word and removes its internal tag', () {
    final item = question(
      type: 'FIB',
      responseType: 'TEXT',
      body: const [
        {
          'type': 'text',
          'data':
              'A: Her mobile phone is new.<br/><word>GOT</word><br/>B: She ',
        },
        'GAP',
        {'type': 'text', 'data': ' a new mobile phone.'},
      ],
      answers: const [
        ['has got'],
      ],
    );

    expect(item.requiredWord, 'GOT');
    expect(item.body.first.data, isNot(contains('<word>')));
    expect(item.body.first.data, contains('A: Her mobile phone is new.'));
    expect(item.body.first.data, contains('B: She'));
  });

  test('parses line breaks and emphasized text as display metadata', () {
    final element = GrammarQuestionElement.fromJson(const {
      'type': 'text',
      'data': 'Another<br/>way to say <em>Do you have a pen?</em> is…',
    });

    expect(element.type, GrammarElementType.text);
    expect(element.data, 'Another\nway to say Do you have a pen? is…');
    expect(element.data, isNot(contains('<em>')));
    expect(
      element.textSegments.where((segment) => segment.emphasized).single.text,
      'Do you have a pen?',
    );
  });

  test('falls back safely when styled segments are unavailable', () {
    const element = GrammarQuestionElement(
      type: GrammarElementType.text,
      data: 'Legacy text',
    );

    expect(element.textSegments, isEmpty);
    expect(element.data, 'Legacy text');
  });
}
