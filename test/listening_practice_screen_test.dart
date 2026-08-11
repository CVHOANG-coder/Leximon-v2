import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/presentation/screens/listening_practice/listening_practice_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('loads and filters listening courses from bundled assets', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ListeningPracticeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('listening-practice-screen')),
      findsOneWidget,
    );
    expect(find.text('Short Stories'), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('listening-course-6'))).width,
      greaterThan(350),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('listening-course-6'))).height,
      124,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('listening-search-field')),
      'TOEIC',
    );
    await tester.pump();

    expect(find.text('TOEIC Listening'), findsOneWidget);
    expect(find.text('Short Stories'), findsNothing);
    expect(find.text('Conversations'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('listening-search-field')),
      '',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('featured-listening-course')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('listening-course-detail-screen')),
      findsOneWidget,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.text('Section 1'), findsOneWidget);
    expect(find.text('First snowfall'), findsNothing);

    await tester.tap(find.text('Section 1'));
    await tester.pump();

    expect(find.text('First snowfall'), findsOneWidget);
    expect(find.text('21 phần'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
