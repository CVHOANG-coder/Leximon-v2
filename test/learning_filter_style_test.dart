import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/constants/app_colors.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/learning_filter/learning_filter_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('learning filters matches the light topic-selection style', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final topics = [for (var order = 1; order <= 5; order++) _topic(order)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => topics),
          selectedTopicOrdersProvider.overrideWith((ref) => {1, 2, 3}),
        ],
        child: MaterialApp(home: LearningFilterScreen(onExit: () {})),
      ),
    );
    await tester.pumpAndSettle();

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('learning-filter-header-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/banner_header.png',
    );
    expect(background.fit, BoxFit.fill);

    final heading = tester.widget<Text>(find.text('Cá nhân hóa lộ trình'));
    expect(heading.style!.color, AppColors.textPrimary);
    expect(
      find.byKey(const Key('learning-filter-header-button')),
      findsOneWidget,
    );

    final selectedTopic = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('learning-filter-topic-1')),
    );
    final selectedDecoration = selectedTopic.decoration! as BoxDecoration;
    expect(selectedDecoration.border!.top.color, const Color(0xFF2A7DF4));
    expect(
      find.byKey(const Key('learning-filter-apply-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Topic _topic(int order) => Topic(
  id: order,
  order: order,
  original: 'Topic $order',
  translated: 'Chủ đề $order',
  words: List.generate(10, (index) => {'id': order * 100 + index}),
);
