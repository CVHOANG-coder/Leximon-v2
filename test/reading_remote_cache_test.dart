import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/data/datasources/reading_asset_data_source.dart';

void main() {
  late Directory cacheDirectory;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('reading-cache-');
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  test('downloads reading packages and reuses the persistent cache', () async {
    final requested = <String>[];
    final client = MockClient((request) async {
      final name = request.url.pathSegments.last;
      requested.add(name);
      final isEnglish = name.endsWith('_en.json');
      return http.Response(
        '[{"id":1,"title":"${isEnglish ? 'English' : 'Vietnamese'}",'
        '"content":"Story"}]',
        200,
      );
    });
    final source = ReadingAssetDataSource(
      client: client,
      cacheDirectory: () async => cacheDirectory,
    );

    final firstLoad = await source.load(languageCode: 'vi');
    expect(firstLoad.single.title, 'Vietnamese');
    expect(firstLoad.single.originalTitle, 'English');
    expect(requested, ['language_reading_vi.json', 'language_reading_en.json']);
    source.dispose();

    final cacheOnlySource = ReadingAssetDataSource(
      client: MockClient((_) async => throw StateError('offline')),
      cacheDirectory: () async => cacheDirectory,
    );
    final cachedLoad = await cacheOnlySource.load(languageCode: 'vi');

    expect(cachedLoad.single.title, 'Vietnamese');
    expect(cachedLoad.single.originalTitle, 'English');
    cacheOnlySource.dispose();
  });
}
