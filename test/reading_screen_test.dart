import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/datasources/reading_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/reading_story.dart';
import 'package:leximon/data/services/reading_progress_service.dart';
import 'package:leximon/data/services/reading_word_translation_service.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/presentation/screens/reading/reading_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  const stories = [
    ReadingStory(
      id: 0,
      title: 'Cái ôm ấm áp của mùa đông',
      content: 'Nội dung câu chuyện mùa đông.',
      imageAsset: 'assets/images/reading/0.jpg',
      englishTitle: "The Warmth of Winter's Embrace",
      englishContent: 'Once upon a time in a winter village.',
    ),
    ReadingStory(
      id: 1,
      title: 'Vinh quang sân cỏ',
      content: 'Nội dung câu chuyện bóng đá.',
      imageAsset: 'assets/images/reading/1.jpg',
      englishTitle: 'Goal of Glory',
      englishContent: 'A young player dreamed of winning the final.',
    ),
  ];

  test('maps app language codes to bundled Reading assets', () {
    final source = ReadingAssetDataSource();

    expect(
      source.assetPathFor('vi'),
      'assets/data/books/language_reading_vi.json',
    );
    expect(
      source.assetPathFor('es-US'),
      'assets/data/books/language_reading_es.json',
    );
    expect(
      source.assetPathFor('in'),
      'assets/data/books/language_reading_id.json',
    );
    expect(
      source.assetPathFor('fi'),
      'assets/data/books/language_reading_en.json',
    );
  });

  test('loads all Vietnamese stories from bundled assets', () async {
    final loadedStories = await ReadingAssetDataSource().load(
      languageCode: 'vi',
    );

    expect(loadedStories, hasLength(30));
    expect(loadedStories.first.title, isNotEmpty);
    expect(loadedStories.first.content, isNotEmpty);
    expect(loadedStories.first.originalTitle, "The Warmth of Winter's Embrace");
    expect(loadedStories.first.hasTranslation, isTrue);
    expect(loadedStories.last.imageAsset, 'assets/images/reading/29.jpg');
  });

  test(
    'loads the selected app language instead of a fixed translation',
    () async {
      final japaneseStories = await ReadingAssetDataSource().load(
        languageCode: 'ja',
      );

      expect(japaneseStories.first.title, '冬の抱擁の温もり。');
      expect(
        japaneseStories.first.originalTitle,
        "The Warmth of Winter's Embrace",
      );
      expect(japaneseStories.first.hasTranslation, isTrue);
    },
  );

  testWidgets('shows Reading header and opens a story', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStoriesProvider.overrideWith((ref) async => stories),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const ReadingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-screen')), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('2 bài đọc'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.byIcon(Icons.translate_rounded), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reading-story-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-detail-screen')), findsOneWidget);
    expect(find.text("The Warmth of Winter's Embrace"), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('reading-story-content')),
          )
          .textSpan!
          .toPlainText(),
      'Once upon a time in a winter village.',
    );

    await tester.tap(find.byKey(const ValueKey('reading-translate-action')));
    await tester.pumpAndSettle();

    expect(find.text('Cái ôm ấm áp của mùa đông'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('reading-story-content')),
          )
          .textSpan!
          .toPlainText(),
      'Nội dung câu chuyện mùa đông.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a database word shows its meaning and saves it', (
    tester,
  ) async {
    var translatorCreations = 0;
    final spokenWords = <String>[];
    const ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          if (call.method == 'speak') {
            final arguments = call.arguments;
            spokenWords.add(
              arguments is Map
                  ? arguments['text'] as String
                  : arguments as String,
            );
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, null),
    );
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.wordModels)
        .insert(
          WordModelsCompanion.insert(
            id: 101,
            topicId: 2,
            writing: 'winter',
            translation: 'mùa đông',
            transcription: const Value('/ˈwɪn.tər/'),
            isEnabled: true,
            priority: 1,
            level: 1,
          ),
        );
    const story = ReadingStory(
      id: 9,
      title: 'Mùa đông',
      content: 'Mùa đông đã đến.',
      imageAsset: 'assets/images/reading/0.jpg',
      englishTitle: 'Winter',
      englishContent: 'Winter came quietly.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          readingWordTranslatorProvider.overrideWith((ref) {
            translatorCreations++;
            return _FakeReadingWordTranslator('unused');
          }),
        ],
        child: const MaterialApp(home: ReadingDetailScreen(story: story)),
      ),
    );
    await tester.pumpAndSettle();

    final selectable = tester.widget<SelectableText>(
      find.byKey(const ValueKey('reading-story-content')),
    );
    final winterSpan = selectable.textSpan!.children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == 'Winter');
    (winterSpan.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-word-writing')), findsOneWidget);
    expect(find.text('mùa đông'), findsOneWidget);
    expect(find.text('/ˈwɪn.tər/'), findsOneWidget);
    expect(translatorCreations, 0);
    expect(
      find.byKey(const ValueKey('reading-word-speaker-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reading-word-speaker-button')));
    await tester.pumpAndSettle();
    expect(spokenWords, contains('winter'));

    await tester.tap(find.byKey(const ValueKey('reading-add-word-button')));
    await tester.pumpAndSettle();

    expect(find.text('Đã thêm vào danh sách học'), findsOneWidget);
    final saved = await database.select(database.readingSavedWordModels).get();
    expect(saved, hasLength(1));
    expect(saved.single.wordId, 101);
    expect(saved.single.storyId, 9);
  });

  testWidgets('translates a missing word without offering to save it', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final translator = _FakeReadingWordTranslator('bí ẩn');
    var translatorCreations = 0;
    const story = ReadingStory(
      id: 10,
      title: 'Bí ẩn',
      content: 'Một điều bí ẩn.',
      imageAsset: 'assets/images/reading/0.jpg',
      englishTitle: 'Mystery',
      englishContent: 'Mystery appeared.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          readingWordTranslatorProvider.overrideWith((ref) {
            translatorCreations++;
            return translator;
          }),
        ],
        child: const MaterialApp(home: ReadingDetailScreen(story: story)),
      ),
    );
    await tester.pumpAndSettle();
    expect(translatorCreations, 0);

    final selectable = tester.widget<SelectableText>(
      find.byKey(const ValueKey('reading-story-content')),
    );
    final mysterySpan = selectable.textSpan!.children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == 'Mystery');
    (mysterySpan.recognizer! as TapGestureRecognizer).onTap!();
    (mysterySpan.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Dịch từ trong bài đọc'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-word-translation')),
      findsOneWidget,
    );
    expect(find.text('bí ẩn'), findsOneWidget);
    expect(translatorCreations, 1);
    expect(find.text('Dịch từ trong bài đọc'), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-add-word-button')), findsNothing);
    expect(translator.translatedWords, ['Mystery']);
    expect(
      await database.select(database.readingSavedWordModels).get(),
      isEmpty,
    );
  });

  testWidgets('shows viewed and completed status on Reading card images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final progress = ReadingProgressService(database);
    await progress.recordOpened(0);
    await progress.recordOpened(1);
    await progress.recordScrollProgress(1, 100);
    const unreadStory = ReadingStory(
      id: 2,
      title: 'Bài chưa đọc',
      content: 'Nội dung chưa đọc.',
      imageAsset: 'assets/images/reading/2.jpg',
      englishTitle: 'Unread story',
      englishContent: 'Unread content.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          readingStoriesProvider.overrideWith(
            (ref) async => const [...stories, unreadStory],
          ),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const ReadingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-viewed-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-completed-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-viewed-2')), findsNothing);
    expect(find.byKey(const ValueKey('reading-completed-2')), findsNothing);
    expect(find.text('❄️'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boss challenge opens the Reading screen', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => []),
          readingStoriesProvider.overrideWith((ref) async => stories),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MessagesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('reading-mode-card-action')),
    );
    await tester.tap(find.byKey(const ValueKey('reading-mode-card-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-screen')), findsOneWidget);
    expect(find.text('2 bài đọc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reading grid does not overflow on supported phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [430.0, 375.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingStoriesProvider.overrideWith((ref) async => stories),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const ReadingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Reading screen overflowed at ${width.toInt()}px',
      );
    }
  });

  testWidgets('Reading detail does not overflow on supported phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [430.0, 375.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ReadingDetailScreen(story: stories.first),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Reading detail overflowed at ${width.toInt()}px',
      );
    }
  });

  testWidgets('Reading headers stay fixed while content scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longStories = List.generate(
      8,
      (index) => ReadingStory(
        id: index,
        title: 'Bài đọc $index',
        content: 'Nội dung $index',
        imageAsset: 'assets/images/reading/$index.jpg',
        englishTitle: 'Story $index',
        englishContent: 'Story content $index',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStoriesProvider.overrideWith((ref) async => longStories),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const ReadingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final listBack = find.byKey(const ValueKey('reading-back-button'));
    final listBackPosition = tester.getTopLeft(listBack);
    final listBackSize = tester.getSize(listBack);
    expect(listBackSize, const Size(40, 40));
    expect(tester.widget<InkWell>(listBack).customBorder, isA<CircleBorder>());

    await tester.drag(
      find.byKey(const ValueKey('reading-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(listBack), listBackPosition);

    final longStory = ReadingStory(
      id: 0,
      title: 'Bản dịch',
      content: List.filled(80, 'Nội dung bản dịch.').join(' '),
      imageAsset: 'assets/images/reading/0.jpg',
      englishTitle: 'A long story',
      englishContent: List.filled(
        80,
        'This is a long reading passage.',
      ).join(' '),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ReadingDetailScreen(story: longStory),
      ),
    );
    await tester.pumpAndSettle();

    final detailBack = find.byKey(const ValueKey('reading-back-button'));
    final detailBackPosition = tester.getTopLeft(detailBack);
    await tester.drag(
      find.byKey(const ValueKey('reading-detail-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(detailBack), detailBackPosition);
  });
}

class _FakeReadingWordTranslator implements ReadingWordTranslator {
  _FakeReadingWordTranslator(this.result);

  final String result;
  final List<String> translatedWords = [];

  @override
  Future<String> translateWord(String word) async {
    translatedWords.add(word);
    return result;
  }
}
