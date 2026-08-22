import 'dart:ui' show PlatformDispatcher;

import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/services/app_language_service.dart';
import '../../core/services/auth_token_storage.dart';
import '../../core/services/device_id_keychain_storage.dart';
import '../../core/services/device_info_service.dart';
import '../models/auth_login_response.dart';
import '../models/user_profile_response.dart';

class AuthApiService {
  AuthApiService({
    required ApiClient apiClient,
    required DeviceIdentityProvider deviceIdentityProvider,
    required AppLanguageService languageService,
    AuthTokenStorage? tokenStorage,
    DeviceIdStorage? deviceIdStorage,
    Future<PackageInfo> Function()? packageInfoLoader,
    this.country,
    String? Function()? countryCodeLoader,
  }) : _apiClient = apiClient,
       _deviceIdentityProvider = deviceIdentityProvider,
       _languageService = languageService,
       _tokenStorage = tokenStorage ?? AuthTokenStorage(),
       _deviceIdStorage = deviceIdStorage ?? DeviceIdKeychainStorage(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _countryCodeLoader = countryCodeLoader ?? _deviceCountryCode {
    _apiClient.setTokenRefresher(() async {
      final response = await login();
      return response.data.token;
    });
  }

  static const loginPath = '/auth/login';
  static const userProfilePath = '/users/profile';
  static const defaultLanguage = 'en';

  final ApiClient _apiClient;
  final DeviceIdentityProvider _deviceIdentityProvider;
  final AppLanguageService _languageService;
  final AuthTokenStorage _tokenStorage;
  final DeviceIdStorage _deviceIdStorage;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final String? country;
  final String? Function() _countryCodeLoader;

  Future<void> ensureToken() async {
    await _apiClient.loadStoredAuthToken();
    if (_apiClient.authToken?.isNotEmpty != true) await login();
  }

  Future<AuthLoginResponse> login() async {
    final identity = await _deviceIdentityProvider.loadIdentity();
    final previousDeviceId = identity.platform == 'IOS'
        ? await _deviceIdStorage.loadDeviceId()
        : null;
    final packageInfo = await _packageInfoLoader();
    final selectedLanguage = await _languageService.loadSelectedLanguage();
    final language = selectedLanguage?.trim().isNotEmpty == true
        ? selectedLanguage!.trim()
        : defaultLanguage;
    final countryCode = (country ?? _countryCodeLoader())?.trim().toUpperCase();

    final body = <String, dynamic>{
      'deviceId': identity.deviceId,
      'platform': identity.platform,
      'language': language,
      'appVersion': packageInfo.version,
    };
    if (countryCode != null && countryCode.isNotEmpty) {
      body['country'] = countryCode;
    }
    if (previousDeviceId != null && previousDeviceId != identity.deviceId) {
      body['deviceId_old'] = previousDeviceId;
    }

    final response = await _apiClient.post(loginPath, body: body);
    final loginResponse = AuthLoginResponse.fromApiResponse(response);
    await _tokenStorage.saveToken(loginResponse.data.token);
    _apiClient.setAuthToken(loginResponse.data.token);
    if (identity.platform == 'IOS') {
      await _deviceIdStorage.saveDeviceId(identity.deviceId);
    }
    return loginResponse;
  }

  /// Returns the ISO 3166-1 alpha-2 region configured by the operating system.
  ///
  /// The device can expose a language without a region (for example `en`),
  /// so callers must handle a missing value.
  static String? _deviceCountryCode() {
    for (final locale in PlatformDispatcher.instance.locales) {
      final countryCode = locale.countryCode?.trim().toUpperCase();
      if (countryCode != null && countryCode.length == 2) {
        return countryCode;
      }
    }
    return null;
  }

  Future<UserProfileResponse> getUserProfile() async {
    if (_apiClient.authToken?.isNotEmpty != true) {
      throw StateError('Cannot load user profile before login.');
    }

    final response = await _apiClient.get(userProfilePath);
    return UserProfileResponse.fromApiResponse(response);
  }
}
