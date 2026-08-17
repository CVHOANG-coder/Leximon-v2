import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService {
  static const selectedLanguageKey = 'onboarding.selected_app_language';
  // Kept as an alias so the persisted value is explicitly available as the
  // app language while remaining compatible with existing installations.
  static const appLanguageKey = selectedLanguageKey;

  /// Language associated with the last successfully synchronized content.
  static const nativeLanguageKey = 'content.native_language';
  static const databaseVersionKey = 'content.database_version';
  static const selectedLearningLevelKey = 'onboarding.selected_learning_level';
  static const carouselCompletedKey = 'onboarding.carousel_completed';
  static const onboardingCompletedKey = 'onboarding.completed';
  static const vocabularyAssessmentLevelKey = 'brightLevel';

  Future<String?> loadSelectedLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(appLanguageKey);
  }

  Future<void> saveSelectedLanguage(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(appLanguageKey, languageCode);
    if (!saved) {
      throw StateError('Could not save the selected app language.');
    }
  }

  Future<String?> loadNativeLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(nativeLanguageKey);
  }

  Future<int?> loadDatabaseVersion() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(databaseVersionKey);
  }

  Future<void> saveContentSyncMetadata({
    required String languageCode,
    required int databaseVersion,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final languageSaved = await preferences.setString(
      nativeLanguageKey,
      languageCode,
    );
    final versionSaved = await preferences.setInt(
      databaseVersionKey,
      databaseVersion,
    );
    if (!languageSaved || !versionSaved) {
      throw StateError('Could not save content synchronization metadata.');
    }
  }

  Future<bool> isCarouselCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(carouselCompletedKey) ?? false;
  }

  Future<void> completeCarousel() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(carouselCompletedKey, true);
    if (!saved) {
      throw StateError('Could not save the carousel state.');
    }
  }

  Future<void> resetCarousel() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(carouselCompletedKey, false);
    if (!saved) {
      throw StateError('Could not reset the carousel state.');
    }
  }

  Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(onboardingCompletedKey) ?? false;
  }

  Future<String?> loadSelectedLearningLevel() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(selectedLearningLevelKey);
  }

  Future<void> saveSelectedLearningLevel(String level) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(selectedLearningLevelKey, level);
    if (!saved) {
      throw StateError('Could not save the selected learning level.');
    }
  }

  Future<String?> loadVocabularyAssessmentLevel() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(vocabularyAssessmentLevelKey);
  }

  Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(onboardingCompletedKey, true);
    if (!saved) {
      throw StateError('Could not save the onboarding state.');
    }
  }
}
