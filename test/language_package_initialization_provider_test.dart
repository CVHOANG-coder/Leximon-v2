import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/user_profile_response.dart';
import 'package:leximon/data/repositories/topic_repository.dart';
import 'package:leximon/shared/providers/app_providers.dart';

import 'remote_content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reports language package progress after provider initialization',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final pendingProfile = Completer<UserProfile>();
      final repository = TopicRepository(
        database: database,
        assetDataSource: testTopicDataSource(),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          topicRepositoryProvider.overrideWithValue(repository),
          selectedAppLanguageProvider.overrideWith((ref) => 'en'),
          remoteUserProfileProvider.overrideWith(
            (ref) => pendingProfile.future,
          ),
        ],
      );
      final reportedProgress = <double>[];
      final progressSubscription = container.listen(
        languagePackageLoadingProgressProvider,
        (_, next) => reportedProgress.add(next.progress),
        fireImmediately: true,
      );
      addTearDown(() async {
        progressSubscription.close();
        container.dispose();
        await database.close();
      });

      await expectLater(
        container.read(languagePackageInitializationProvider.future),
        completes,
      );

      expect(reportedProgress, containsAllInOrder([.08, .62, .76, .9, .94]));
      for (var index = 1; index < reportedProgress.length; index++) {
        expect(
          reportedProgress[index],
          greaterThanOrEqualTo(reportedProgress[index - 1]),
        );
      }
    },
  );
}
