import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/ipa_sound.dart';
import 'package:leximon/data/services/ipa_progress_service.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/presentation/screens/pronunciation/pronunciation_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('represents all IPA groups with remote media URLs', () async {
    final sounds = _remoteSoundsFixture();

    expect(sounds, hasLength(43));
    expect(
      sounds.where((sound) => sound.group == IpaSoundGroup.vowel),
      hasLength(15),
    );
    expect(
      sounds.where((sound) => sound.group == IpaSoundGroup.rControlledVowel),
      hasLength(4),
    );
    expect(
      sounds.where((sound) => sound.group == IpaSoundGroup.consonant),
      hasLength(24),
    );
    expect(sounds.first.example, 'brown');
    expect(sounds.first.audioAsset, startsWith('https://'));
    expect(sounds.first.spellingWords.first.name, 'brown');
    expect(sounds.first.spellingWords.first.transcription, '/braʊn/');
  });

  testWidgets('sound tile opens a vertical full-width detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const word = IpaWord(name: 'brown', audioAsset: '');
    const sound = IpaSound(
      symbol: 'aʊ',
      name: 'ow sound',
      example: 'brown',
      audioAsset: '',
      group: IpaSoundGroup.vowel,
      spellingWords: [word],
      beginningWords: [word],
      middleWords: [word],
      endWords: [word],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const PronunciationScreen(sounds: [sound]),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ipa-sound-aʊ')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ipa-sound-detail-screen')), findsOne);
    expect(find.byKey(const ValueKey('ipa-youtube-player')), findsNothing);
    final mouthCard = find.byKey(const ValueKey('ipa-mouth-card'));
    final descriptionCard = find.byKey(const ValueKey('ipa-description-card'));
    expect(tester.getSize(mouthCard).width, greaterThan(390));
    expect(tester.getSize(descriptionCard).width, greaterThan(390));
    expect(
      tester.getTopLeft(descriptionCard).dy,
      greaterThan(tester.getBottomLeft(mouthCard).dy),
    );

    for (final key in [
      const ValueKey('ipa-spelling-section'),
      const ValueKey('ipa-beginning-section'),
      const ValueKey('ipa-middle-section'),
      const ValueKey('ipa-end-section'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.getSize(find.byKey(key)).width, greaterThan(390));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the Sounds UI from remote IPA data', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sounds = _remoteSoundsFixture();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PronunciationScreen(sounds: sounds),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pronunciation-screen')), findsOneWidget);
    final background = tester.widget<Image>(
      find.byKey(const ValueKey('pronunciation-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_word_study.png',
    );
    expect(find.text('Sounds'), findsOneWidget);
    expect(find.text('Vowel Sounds'), findsOneWidget);
    expect(find.text('R-controlled vowels'), findsOneWidget);
    expect(find.text('Consonant Sounds'), findsOneWidget);
    expect(find.text('brown'), findsOneWidget);
    expect(find.text('bathe', skipOffstage: false), findsOneWidget);
    expect(find.text('thin', skipOffstage: false), findsOneWidget);

    final firstRowY = tester
        .getCenter(find.byKey(const ValueKey('ipa-sound-aʊ')))
        .dy;
    expect(
      tester.getCenter(find.byKey(const ValueKey('ipa-sound-ju'))).dy,
      firstRowY,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('ipa-sound-oʊ'))).dy,
      greaterThan(firstRowY),
    );

    await tester.drag(
      find.byKey(const ValueKey('pronunciation-scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ipa-sound-θ')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks viewed and completed IPA cards from local progress', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final progress = IpaProgressService(database);
    await progress.recordOpened('aʊ');
    await progress.recordPracticed('eɪ');

    const sounds = [
      IpaSound(
        symbol: 'aʊ',
        name: 'ow sound',
        example: 'brown',
        audioAsset: '',
        group: IpaSoundGroup.vowel,
      ),
      IpaSound(
        symbol: 'eɪ',
        name: 'ay sound',
        example: 'day',
        audioAsset: '',
        group: IpaSoundGroup.vowel,
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PronunciationScreen(sounds: sounds),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ipa-sound-viewed-aʊ')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ipa-sound-completed-eɪ')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ipa-sound-completed-aʊ')), findsNothing);
  });

  testWidgets('sound tiles do not overflow on supported phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sounds = _remoteSoundsFixture();

    for (final width in [400.0, 375.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PronunciationScreen(sounds: sounds),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Sounds screen overflowed at ${width.toInt()}px',
      );
    }
  });

  testWidgets('pronunciation challenge card opens the Sounds screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [topicsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MessagesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('pronunciation-mode-card')),
    );
    await tester.tap(find.byKey(const ValueKey('pronunciation-mode-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('pronunciation-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

List<IpaSound> _remoteSoundsFixture() {
  const vowels = [
    'aʊ',
    'eɪ',
    'i',
    'ju',
    'oʊ',
    'u',
    'æ',
    'ɑ',
    'ɑɪ',
    'ɔ',
    'ɔɪ',
    'ɛ',
    'ɪ',
    'ʊ',
    'ʌ',
  ];
  const rControlled = ['ɑr', 'ɔr', 'ɚ', 'ɛr'];
  const consonants = [
    'b',
    'd',
    'f',
    'g',
    'h',
    'k',
    'l',
    'm',
    'n',
    'p',
    'r',
    's',
    't',
    'v',
    'w',
    'y',
    'z',
    'ð',
    'ŋ',
    'ʃ',
    'ʒ',
    'ʤ',
    'ʧ',
    'θ',
  ];
  const examples = {'aʊ': 'brown', 'ð': 'bathe', 'θ': 'thin'};
  final symbols = [...vowels, ...rControlled, ...consonants];

  return symbols
      .map(
        (symbol) => IpaSound(
          symbol: symbol,
          name: '$symbol sound',
          example: examples[symbol] ?? symbol,
          audioAsset:
              'https://leximonenglish.giddychat.com/data/ipa/result/$symbol.mp3',
          photoAsset:
              'https://leximonenglish.giddychat.com/data/ipa/result/$symbol.gif',
          group: vowels.contains(symbol)
              ? IpaSoundGroup.vowel
              : rControlled.contains(symbol)
              ? IpaSoundGroup.rControlledVowel
              : IpaSoundGroup.consonant,
          spellingWords: symbol == 'aʊ'
              ? const [
                  IpaWord(
                    name: 'brown',
                    transcription: '/braʊn/',
                    audioAsset:
                        'https://leximonenglish.giddychat.com/data/ipa/result/brown.mp3',
                  ),
                ]
              : const [],
        ),
      )
      .toList(growable: false);
}
