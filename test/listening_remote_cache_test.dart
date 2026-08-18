import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/data/datasources/listening_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads listening indexes from the server and reuses disk cache',
    () async {
      final cacheDirectory = await Directory.systemTemp.createTemp(
        'leximon-listening-cache-',
      );
      addTearDown(() => cacheDirectory.delete(recursive: true));

      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return http.Response(
          '{"id":2,"name":"Short Stories","lessons":[]}',
          200,
        );
      });
      final source = ListeningAssetDataSource(
        useRemote: true,
        client: client,
        cacheDirectory: () async => cacheDirectory,
      );
      addTearDown(source.dispose);

      final first = await source.loadCourseIndex(
        'assets/data/listens/02-short-stories/course-index.json',
      );

      expect(first['name'], 'Short Stories');
      expect(
        requests.single.path,
        '/data/listens/02-short-stories/course-index.json',
      );
      expect(
        File(
          '${cacheDirectory.path}/02-short-stories/course-index.json',
        ).existsSync(),
        isTrue,
      );

      final offlineSource = ListeningAssetDataSource(
        useRemote: true,
        client: MockClient((_) async => throw const SocketException('offline')),
        cacheDirectory: () async => cacheDirectory,
      );
      addTearDown(offlineSource.dispose);

      final cached = await offlineSource.loadCourseIndex(
        'assets/data/listens/02-short-stories/course-index.json',
      );
      expect(cached['name'], 'Short Stories');
    },
  );
}
