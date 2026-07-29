import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/presentation/screens/difficult_words_training/difficult_words_result_screen.dart';

void main() {
  testWidgets('offers another batch while difficult words remain', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DifficultWordsResultScreen(
          healedWordCount: 3,
          trainedWordCount: 4,
          remainingWordCount: 5,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tuyệt lắm!'), findsOneWidget);
    expect(find.text('Còn 5 từ cần luyện thêm'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Thoát và xem danh sách'), findsOneWidget);
  });

  testWidgets('finishes when every difficult word has been healed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DifficultWordsResultScreen(
          healedWordCount: 4,
          trainedWordCount: 4,
          remainingWordCount: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bạn đã chữa hết!'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.text('Thoát và xem danh sách'), findsNothing);
  });
}
