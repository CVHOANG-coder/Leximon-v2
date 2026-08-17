import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/services/app_language_service.dart';
import '../../core/services/auth_token_storage.dart';
import '../../core/services/device_info_service.dart';
import '../models/auth_login_response.dart';
import '../models/user_profile_response.dart';

class AuthApiService {
  AuthApiService({
    required ApiClient apiClient,
    required DeviceIdentityProvider deviceIdentityProvider,
    required AppLanguageService languageService,
    AuthTokenStorage? tokenStorage,
    Future<PackageInfo> Function()? packageInfoLoader,
    this.country = 'VN',
  }) : _apiClient = apiClient,
       _deviceIdentityProvider = deviceIdentityProvider,
       _languageService = languageService,
       _tokenStorage = tokenStorage ?? AuthTokenStorage(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform {
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
  final Future<PackageInfo> Function() _packageInfoLoader;
  final String country;

  Future<void> ensureToken() async {
    await _apiClient.loadStoredAuthToken();
    if (_apiClient.authToken?.isNotEmpty != true) await login();
  }

  Future<AuthLoginResponse> login() async {
    final identity = await _deviceIdentityProvider.loadIdentity();
    final packageInfo = await _packageInfoLoader();
    final selectedLanguage = await _languageService.loadSelectedLanguage();
    final language = selectedLanguage?.trim().isNotEmpty == true
        ? selectedLanguage!.trim()
        : defaultLanguage;

    final response = await _apiClient.post(
      loginPath,
      body: {
        'deviceId': identity.deviceId,
        'platform': identity.platform,
        'country': country,
        'language': language,
        'appVersion': packageInfo.version,
      },
    );
    final loginResponse = AuthLoginResponse.fromApiResponse(response);
    await _tokenStorage.saveToken(loginResponse.data.token);
    _apiClient.setAuthToken(loginResponse.data.token);
    return loginResponse;
  }

  Future<UserProfileResponse> getUserProfile() async {
    if (_apiClient.authToken?.isNotEmpty != true) {
      throw StateError('Cannot load user profile before login.');
    }

    final response = await _apiClient.get(userProfilePath);
    return UserProfileResponse.fromApiResponse(response);
  }
}
