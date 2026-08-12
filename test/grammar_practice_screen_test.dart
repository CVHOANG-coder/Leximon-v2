import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/datasources/grammar_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/grammar_repository.dart';
import 'package:leximon/data/services/grammar_progress_service.dart';
import 'package:leximon/presentation/screens/grammar_practice/grammar_pack_detail_screen.dart';
import 'package:leximon/presentation/screens/grammar_practice/grammar_practice_screen.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'grammar catalog reads pack metadata from bundled JSON assets',
    () async {
      final packs = await GrammarPackCatalog.load();

      expect(packs, hasLength(9));
      expect(packs.first.guid, 'BCQP0001');
      expect(packs.first.title, 'Beginner Pack 1');
      expect(packs.first.lessonCount, 16);
      expect(packs.first.topics.first.label, 'To be');
      expect(packs.first.topics.first.questionCount, 25);
      expect(packs.where((pack) => pack.level == 'Elementary'), hasLength(3));
      expect(packs.last.guid, 'ACQP0002');
    },
  );

  testWidgets('grammar practice screen renders all level groups', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final packs = (await tester.runAsync(GrammarPackCatalog.load))!;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: GrammarPracticeScreen(packs: packs),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Ngữ pháp'), findsOneWidget);
    expect(find.text('Beginner Pack 1'), findsOneWidget);
    expect(find.text('BEGINNER'), findsOneWidget);

    final titleRect = tester.getRect(
      find.byKey(const ValueKey('grammar-hero-title')),
    );
    final subtitleRect = tester.getRect(
      find.byKey(const ValueKey('grammar-hero-subtitle')),
    );
    final progressRect = tester.getRect(
      find.byKey(const ValueKey('grammar-hero-progress')),
    );
    final ringRect = tester.getRect(
      find.byKey(const ValueKey('grammar-hero-ring')),
    );
    expect(titleRect.overlaps(ringRect), isFalse);
    expect(
      subtitleRect.overlaps(progressRect),
      isFalse,
      reason: 'subtitle: $subtitleRect, progress: $progressRect',
    );
    expect(progressRect.overlaps(ringRect), isFalse);

    await tester.drag(
      find.byKey(const ValueKey('grammar-practice-scroll')),
      const Offset(0, -2500),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ADVANCED', skipOffstage: false), findsOneWidget);
    expect(find.text('Advanced Pack 2', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meaning matching card opens grammar practice screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MessagesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('grammar-mode-card')));
    await tester.tap(find.byKey(const ValueKey('grammar-mode-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ngữ pháp'), findsOneWidget);
    expect(find.byKey(const ValueKey('grammar-back-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pack card opens details populated from grammar assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final packs = (await tester.runAsync(GrammarPackCatalog.load))!;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: GrammarPracticeScreen(packs: packs),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-pack-BCQP0001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('grammar-pack-detail-screen')),
      findsOneWidget,
    );
    expect(find.text('Beginner Pack 1'), findsWidgets);
    expect(find.text('16 topics in this pack'), findsOneWidget);
    expect(find.text('To be'), findsOneWidget);
    expect(find.text('Have got'), findsOneWidget);
    expect(find.text('Imperatives (+/-)'), findsOneWidget);
    expect(find.text('0%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog reloads SQLite progress after returning from a pack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GrammarRepository(
      database: database,
      assetDataSource: GrammarAssetDataSource(),
    );
    final progressService = GrammarProgressService(database);
    final contents = (await tester.runAsync(repository.loadPacks))!;
    final firstTopic = contents.first.topics.first;
    final firstQuestion = (await tester.runAsync(
      () => repository.loadTopicQuestions(firstTopic.id),
    ))!.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarProgressServiceProvider.overrideWithValue(progressService),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const GrammarPracticeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    final packTile = find.byKey(const ValueKey('grammar-pack-BCQP0001'));
    final heroProgress = find.byKey(const ValueKey('grammar-hero-progress'));
    final beginnerLevel = find.byKey(const ValueKey('grammar-level-Beginner'));
    expect(
      find.descendant(of: packTile, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heroProgress, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: beginnerLevel, matching: find.text('0% hoàn thành')),
      findsOneWidget,
    );

    await tester.tap(packTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('grammar-pack-detail-screen')),
      findsOneWidget,
    );

    await tester.runAsync(
      () => progressService.saveResponse(
        questionId: firstQuestion.id,
        topicId: firstTopic.id,
        responseData: '[1]',
        isCorrect: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('grammar-pack-back-button')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('grammar-practice-scroll')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: packTile, matching: find.text('1%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heroProgress, matching: find.text('1%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: beginnerLevel, matching: find.text('1% hoàn thành')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('grammar-edit-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-reset-pack-BCQP0001')));
    await tester.pumpAndSettle();
    expect(find.text('Đặt lại tiến độ pack?'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => database.select(database.grammarUserResponseModels).get(),
      ))!,
      hasLength(1),
    );
    await tester.tap(
      find.byKey(const ValueKey('grammar-reset-confirm-button')),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(
      await tester.runAsync(
        () => database.select(database.grammarUserResponseModels).get(),
      ),
      isEmpty,
    );
    expect(
      find.descendant(of: packTile, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heroProgress, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('topic reset asks for confirmation and clears its work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GrammarRepository(
      database: database,
      assetDataSource: GrammarAssetDataSource(),
    );
    final progressService = GrammarProgressService(database);
    final topic = (await tester.runAsync(
      repository.loadPacks,
    ))!.first.topics.first;
    final question = (await tester.runAsync(
      () => repository.loadTopicQuestions(topic.id),
    ))!.first;
    await tester.runAsync(
      () => progressService.saveResponse(
        questionId: question.id,
        topicId: topic.id,
        responseData: '[1]',
        isCorrect: true,
      ),
    );
    final startedPack = GrammarPack.fromContent(
      (await tester.runAsync(repository.loadPacks))!.first,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarProgressServiceProvider.overrideWithValue(progressService),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: GrammarPackDetailScreen(pack: startedPack),
        ),
      ),
    );
    await tester.pump();
    final topicCard = find.byKey(const ValueKey('grammar-topic-0'));
    expect(
      find.descendant(of: topicCard, matching: find.text('4%')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('grammar-pack-edit-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-reset-topic-0')));
    await tester.pumpAndSettle();
    expect(find.text('Đặt lại tiến độ bài học?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('grammar-reset-topic-cancel-button')),
    );
    await tester.pumpAndSettle();
    expect(
      (await tester.runAsync(
        () => database.select(database.grammarUserResponseModels).get(),
      ))!,
      hasLength(1),
    );

    await tester.tap(find.byKey(const ValueKey('grammar-reset-topic-0')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('grammar-reset-topic-confirm-button')),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(
      await tester.runAsync(
        () => database.select(database.grammarUserResponseModels).get(),
      ),
      isEmpty,
    );
    expect(
      find.descendant(of: topicCard, matching: find.text('0%')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('elementary pack detail shows every topic from its JSON', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final packs = (await tester.runAsync(GrammarPackCatalog.load))!;
    final pack = packs.singleWhere((item) => item.guid == 'ECQP0002');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: GrammarPackDetailScreen(pack: pack),
      ),
    );
    await tester.pump();

    expect(find.text('Elementary Pack 2'), findsWidgets);
    expect(find.text('14 topics in this pack'), findsOneWidget);
    expect(find.text('Gerunds'), findsOneWidget);
    expect(find.text('Expressing purpose (To + infinitive)'), findsOneWidget);
    expect(find.text('Verb + to + infinitive'), findsOneWidget);
    expect(find.text('Easy'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pack created without topics is rehydrated before navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const stalePack = GrammarPack(
      guid: 'BCQP0001',
      level: 'Beginner',
      title: 'Beginner Pack 1',
      lessonCount: 16,
      iconAsset: 'assets/images/grammar/beginner_pack1.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const GrammarPracticeScreen(packs: [stalePack]),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('grammar-pack-BCQP0001')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('grammar-pack-detail-screen')),
      findsOneWidget,
    );
    expect(find.text('16 topics in this pack'), findsOneWidget);
    expect(find.text('To be'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
