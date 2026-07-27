import 'package:leximon/app.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('opens topic setup from Home and applies the selection', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LeximonApp()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Leximon'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('MỤC TIÊU HÔM NAY'), findsOneWidget);

    final filterButton = find.byType(IconButton);
    await tester.ensureVisible(filterButton);
    // The filter control lives inside the Home scroll view.
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cá nhân hóa lộ trình'), findsOneWidget);
    expect(find.text('Học tập'), findsNothing);
    expect(find.text('Sơ cấp'), findsWidgets);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Những chủ đề nào phù hợp với bạn?'), findsOneWidget);

    await tester.tap(find.text('Hoàn tất'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Chọn chủ đề để học'), findsOneWidget);
  });

  testWidgets('swipes between words in the study deck', (tester) async {
    final topic = Topic(
      id: 1,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {
          'writing': 'trip',
          'translation': 'chuyến đi',
          'transcription': '/trɪp/',
        },
        {
          'writing': 'passport',
          'translation': 'hộ chiếu',
          'transcription': '/ˈpɑːspɔːt/',
        },
        {'writing': 'visa', 'translation': 'thị thực'},
        {'writing': 'suitcase', 'translation': 'va li'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('trip'), findsOneWidget);
    await tester.drag(find.text('trip'), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(find.text('passport'), findsOneWidget);
  });
}
