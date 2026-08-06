import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService {
  static const selectedLanguageKey = 'onboarding.selected_app_language';
  static const selectedLearningLevelKey = 'onboarding.selected_learning_level';
  static const carouselCompletedKey = 'onboarding.carousel_completed';
  static const onboardingCompletedKey = 'onboarding.completed';

  Future<String?> loadSelectedLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(selectedLanguageKey);
  }

  Future<void> saveSelectedLanguage(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      selectedLanguageKey,
      languageCode,
    );
    if (!saved) {
      throw StateError('Could not save the selected app language.');
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

  Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(onboardingCompletedKey, true);
    if (!saved) {
      throw StateError('Could not save the onboarding state.');
    }
  }
}
