import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/datasources/ipa_asset_data_source.dart';
import 'package:leximon/data/models/ipa_sound.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/presentation/screens/pronunciation/pronunciation_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all IPA groups and pronunciation audio from assets', () async {
    final sounds = await IpaAssetDataSource.load();

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
    expect(sounds.first.audioAsset, endsWith('/aʊ/pronunciation/aʊ.mp3'));

    for (final sound in sounds) {
      expect(await rootBundle.load(sound.audioAsset), isNotNull);
    }
  });

  testWidgets('renders the Sounds UI from IPA asset data', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sounds = (await tester.runAsync(IpaAssetDataSource.load))!;
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

  testWidgets('sound tiles do not overflow on supported phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sounds = (await tester.runAsync(IpaAssetDataSource.load))!;

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
