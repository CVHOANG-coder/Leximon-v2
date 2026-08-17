import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/data/datasources/ipa_asset_data_source.dart';
import 'package:leximon/data/datasources/ipa_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'downloads IPA metadata lazily, then caches media on demand',
    () async {
      final testDirectory = await Directory.systemTemp.createTemp(
        'leximon-ipa-test-',
      );
      IpaLocalDataSource.setStorageDirectoryForTesting(testDirectory);
      await IpaLocalDataSource.clearCacheForTesting();
      addTearDown(() async {
        IpaLocalDataSource.setStorageDirectoryForTesting(null);
        if (await testDirectory.exists()) {
          await testDirectory.delete(recursive: true);
        }
      });
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/manifest.json')) {
          return http.Response(
            jsonEncode({
              'version': 1,
              'jsonDirectory': 'json',
              'descriptionsDirectory': 'descriptions',
              'youtubeCatalog': 'youtube_videos.json',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/youtube_videos.json')) {
          return http.Response(
            jsonEncode({'videoId': 'demo', 'startSeconds': {}}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/descriptions/en.json')) {
          return http.Response(
            jsonEncode({'aʊ': 'Remote description'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'transcription': 'aʊ',
            'name': 'ow sound',
            'audioPath':
                'AmericanSounds/result/vowelSounds/aʊ/pronunciation/aʊ.mp3',
            'photoPath':
                'AmericanSounds/result/vowelSounds/aʊ/pronunciation/aʊ.gif',
            'spellingWordList': [],
            'soundPracticeWords': {},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final sounds = await IpaAssetDataSource.load(client: client);
      client.close();

      expect(sounds, hasLength(43));
      expect(sounds.first.description, 'Remote description');
      expect(
        sounds.first.audioAsset,
        endsWith('result/vowelSounds/aʊ/pronunciation/aʊ.mp3'),
      );
      expect(
        sounds.first.photoAsset,
        endsWith('result/vowelSounds/aʊ/pronunciation/aʊ.gif'),
      );
      expect(
        requests,
        contains(
          Uri.parse(
            'https://leximonenglish.giddychat.com/data/ipa/json/a%CA%8A.json',
          ),
        ),
      );
      expect(
        requests.any((request) => request.path.endsWith('.mp3')),
        isFalse,
      );

      final mediaClient = MockClient(
        (_) async => http.Response.bytes([1, 2, 3], 200),
      );
      await IpaLocalDataSource.ensureMediaReady(
        sound: sounds.first,
        client: mediaClient,
      );
      mediaClient.close();
      expect(await File(sounds.first.audioAsset).exists(), isTrue);
      expect(await File(sounds.first.photoAsset).exists(), isTrue);

      final cachedClient = MockClient((_) async {
        throw StateError('The cache should be used instead of the network.');
      });
      final cachedSounds = await IpaAssetDataSource.load(client: cachedClient);
      cachedClient.close();
      expect(cachedSounds.first.description, 'Remote description');
    },
  );

  test('reports a download failure when IPA data is not cached', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'leximon-ipa-test-',
    );
    IpaLocalDataSource.setStorageDirectoryForTesting(testDirectory);
    await IpaLocalDataSource.clearCacheForTesting();
    addTearDown(() async {
      IpaLocalDataSource.setStorageDirectoryForTesting(null);
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final client = MockClient(
      (_) async => http.Response('{"message":"server unavailable"}', 503),
    );

    expect(
      IpaAssetDataSource.load(client: client),
      throwsA(isA<IpaDownloadException>()),
    );
    client.close();
  });
}
