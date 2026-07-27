import 'package:leximon/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the Leximon learning shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LeximonApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Leximon'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('MỤC TIÊU HÔM NAY'), findsOneWidget);

    await tester.tap(find.text('Tiến độ'));
    await tester.pump();

    expect(find.text('Hành trình của bạn'), findsOneWidget);
  });
}
