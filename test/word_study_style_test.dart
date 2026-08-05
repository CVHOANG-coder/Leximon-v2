import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/constants/app_colors.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('word study uses the light banner, header and footer style', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    const topic = Topic(
      id: 1,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {
          'id': 1,
          'writing': 'boarding pass',
          'translation': 'thẻ lên máy bay',
          'transcription': '/ˈbɔːrdɪŋ pæs/',
        },
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => const [topic]),
          wordProgressProvider.overrideWith(
            (ref) async => const <int, LearningProgressRow>{},
          ),
          selectedTopicOrdersProvider.overrideWith((ref) => {1}),
        ],
        child: const MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pumpAndSettle();

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('word-study-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_word_study.png',
    );
    expect(background.fit, BoxFit.fill);

    final title = tester.widget<Text>(find.text('Đã chọn 0 / 4 từ').first);
    expect(title.style!.color, AppColors.textPrimary);

    final footer = tester.widget<Container>(
      find.byKey(const Key('word-study-footer')),
    );
    final footerDecoration = footer.decoration! as BoxDecoration;
    expect(footerDecoration.color, isNotNull);
    expect(
      tester.getSize(find.byKey(const Key('word-study-slow-audio-button'))),
      const Size(76, 82),
    );
    expect(
      tester.getSize(find.byKey(const Key('word-study-audio-button'))),
      const Size(94, 94),
    );
    final learnButton = tester.widget<Container>(
      find.byKey(const ValueKey('word-study-action-Học từ này')),
    );
    final learnDecoration = learnButton.decoration! as BoxDecoration;
    expect((learnDecoration.gradient! as LinearGradient).colors, const [
      Color(0xFFFFB10A),
      Color(0xFFFFC83D),
    ]);
    final wordCard = tester.widget<Container>(
      find.byKey(const ValueKey('word-study-word-card-0')),
    );
    expect(wordCard.margin, const EdgeInsets.only(bottom: 16));
    expect(find.text('boarding pass'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
