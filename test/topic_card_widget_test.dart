import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/widgets/leximon_widgets.dart';

void main() {
  testWidgets(
    'topic percentage badges overlap artwork and change by progress',
    (tester) async {
      final progressValues = <int, double>{1: .03, 2: .04, 3: .5, 4: 1};
      final expectedColors = <int, List<Color>>{
        1: const [Color(0xFFEF5B63), Color(0xFFD83B45)],
        2: const [Color(0xFFE08A30), Color(0xFFBE6E20)],
        3: const [Color(0xFF4A96F5), Color(0xFF236BCF)],
        4: const [Color(0xFF39C875), Color(0xFF15964D)],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final entry in progressValues.entries)
                  SizedBox(
                    width: 180,
                    height: 84,
                    child: TopicCard(
                      topic: _topic(entry.key),
                      progress: entry.value,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      for (final entry in expectedColors.entries) {
        final badgeFinder = find.byKey(
          ValueKey('topic-progress-badge-${entry.key}'),
        );
        final badge = tester.widget<Container>(badgeFinder);
        final decoration = badge.decoration! as BoxDecoration;
        final gradient = decoration.gradient! as LinearGradient;
        expect(gradient.colors, entry.value);
        expect(gradient.begin, Alignment.topCenter);
        expect(gradient.end, Alignment.bottomCenter);
      }

      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('topic-progress-badge-1')),
      );
      final artworkRect = tester.getRect(
        find.byKey(const ValueKey('topic-artwork-1')),
      );
      expect(badgeRect.top - artworkRect.top, closeTo(-2, .01));
      expect(badgeRect.left, lessThan(artworkRect.right));
      expect(badgeRect.right - artworkRect.right, inInclusiveRange(0, 1));

      final shadowContainer = tester.widget<Container>(
        find.byKey(const ValueKey('topic-card-shadow-1')),
      );
      final cardDecoration = shadowContainer.decoration! as BoxDecoration;
      expect(cardDecoration.boxShadow, const [
        BoxShadow(
          color: Color(0x247A96B8),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ]);
    },
  );
}

Topic _topic(int id) => Topic(
  id: id,
  order: id,
  original: 'Topic $id',
  translated: 'Chủ đề $id',
  words: List.generate(100, (index) => {'id': index}),
);
