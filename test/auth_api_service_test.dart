import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/core/services/auth_token_storage.dart';
import 'package:leximon/core/services/device_id_keychain_storage.dart';
import 'package:leximon/core/services/device_info_service.dart';
import 'package:leximon/data/models/auth_login_response.dart';
import 'package:leximon/data/services/auth_api_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'login sends the device country code and defaults language to English',
    () async {
      SharedPreferences.setMockInitialValues({});
      final requests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(loginResponseJson, 200);
        }),
        baseUrl: 'https://example.com',
      );
      addTearDown(client.close);

      final service = AuthApiService(
        apiClient: client,
        deviceIdentityProvider: _FakeDeviceIdentityProvider(
          const DeviceIdentity(deviceId: 'android-id-123', platform: 'ANDROID'),
        ),
        languageService: AppLanguageService(),
        countryCodeLoader: () => 'us',
        packageInfoLoader: () async => PackageInfo(
          appName: 'Leximon',
          packageName: 'com.leximon.leximon',
          version: '1.0.0',
          buildNumber: '4',
        ),
      );

      final login = await service.login();

      expect(login, isA<AuthLoginResponse>());
      expect(login.success, isTrue);
      expect(login.data.user.id, 2);
      expect(login.data.user.userCode, 'Z16EBPRIXAYE1BST');
      expect(login.data.subscription, isNull);
      expect(login.data.token, 'test-token');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(AuthTokenStorage.tokenKey), 'test-token');

      final loginRequest = requests.single;
      expect(loginRequest.method, 'POST');
      expect(loginRequest.url.path, '/auth/login');
      expect(loginRequest.headers['content-type'], 'application/json');
      expect(jsonDecode(loginRequest.body), {
        'deviceId': 'android-id-123',
        'platform': 'ANDROID',
        'country': 'US',
        'language': 'en',
        'appVersion': '1.0.0',
      });

      await client.get('/profile');
      expect(requests.last.headers['authorization'], 'Bearer test-token');
    },
  );

  test('login uses the language selected in a previous session', () async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'de',
    });
    late Map<String, dynamic> payload;
    final client = ApiClient(
      client: MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(loginResponseJson, 200);
      }),
      baseUrl: 'https://example.com',
    );
    addTearDown(client.close);

    final service = AuthApiService(
      apiClient: client,
      deviceIdentityProvider: _FakeDeviceIdentityProvider(
        const DeviceIdentity(deviceId: 'ios-vendor-id', platform: 'IOS'),
      ),
      deviceIdStorage: _FakeDeviceIdStorage(),
      languageService: AppLanguageService(),
      packageInfoLoader: () async => PackageInfo(
        appName: 'Leximon',
        packageName: 'com.leximon.leximon',
        version: '1.0.0',
        buildNumber: '4',
      ),
    );

    final login = await service.login();

    expect(payload['language'], 'de');
    expect(payload.containsKey('fcmToken'), isFalse);
    expect(login.data.user.platform, 'ANDROID');
  });

  test(
    'iOS first login omits old device ID and stores current device ID',
    () async {
      SharedPreferences.setMockInitialValues({});
      late Map<String, dynamic> payload;
      final deviceIdStorage = _FakeDeviceIdStorage();
      final client = ApiClient(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(loginResponseJson, 200);
        }),
        baseUrl: 'https://example.com',
      );
      addTearDown(client.close);

      final service = AuthApiService(
        apiClient: client,
        deviceIdentityProvider: _FakeDeviceIdentityProvider(
          const DeviceIdentity(deviceId: 'ios-current-id', platform: 'IOS'),
        ),
        deviceIdStorage: deviceIdStorage,
        languageService: AppLanguageService(),
        packageInfoLoader: _packageInfo,
      );

      await service.login();

      expect(payload['deviceId'], 'ios-current-id');
      expect(payload.containsKey('deviceId_old'), isFalse);
      expect(deviceIdStorage.savedDeviceId, 'ios-current-id');
    },
  );

  test(
    'iOS login omits old device ID when Keychain ID matches current ID',
    () async {
      SharedPreferences.setMockInitialValues({});
      late Map<String, dynamic> payload;
      final deviceIdStorage = _FakeDeviceIdStorage(
        storedDeviceId: 'ios-current-id',
      );
      final client = ApiClient(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(loginResponseJson, 200);
        }),
        baseUrl: 'https://example.com',
      );
      addTearDown(client.close);

      final service = AuthApiService(
        apiClient: client,
        deviceIdentityProvider: _FakeDeviceIdentityProvider(
          const DeviceIdentity(deviceId: 'ios-current-id', platform: 'IOS'),
        ),
        deviceIdStorage: deviceIdStorage,
        languageService: AppLanguageService(),
        packageInfoLoader: _packageInfo,
      );

      await service.login();

      expect(payload.containsKey('deviceId_old'), isFalse);
      expect(deviceIdStorage.savedDeviceId, 'ios-current-id');
    },
  );

  test(
    'iOS login sends Keychain ID as old device ID when IDs differ',
    () async {
      SharedPreferences.setMockInitialValues({});
      late Map<String, dynamic> payload;
      final deviceIdStorage = _FakeDeviceIdStorage(
        storedDeviceId: 'ios-old-id',
      );
      final client = ApiClient(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(loginResponseJson, 200);
        }),
        baseUrl: 'https://example.com',
      );
      addTearDown(client.close);

      final service = AuthApiService(
        apiClient: client,
        deviceIdentityProvider: _FakeDeviceIdentityProvider(
          const DeviceIdentity(deviceId: 'ios-current-id', platform: 'IOS'),
        ),
        deviceIdStorage: deviceIdStorage,
        languageService: AppLanguageService(),
        packageInfoLoader: _packageInfo,
      );

      await service.login();

      expect(payload['deviceId'], 'ios-current-id');
      expect(payload['deviceId_old'], 'ios-old-id');
      expect(deviceIdStorage.savedDeviceId, 'ios-current-id');
    },
  );

  test('loads the user profile with the token returned by login', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <http.Request>[];
    final client = ApiClient(
      client: MockClient((request) async {
        requests.add(request);
        final body = request.url.path == '/auth/login'
            ? loginResponseJson
            : profileResponseJson;
        return http.Response(body, 200);
      }),
      baseUrl: 'https://example.com',
    );
    addTearDown(client.close);

    final service = AuthApiService(
      apiClient: client,
      deviceIdentityProvider: _FakeDeviceIdentityProvider(
        const DeviceIdentity(deviceId: 'android-id-123', platform: 'ANDROID'),
      ),
      languageService: AppLanguageService(),
      packageInfoLoader: () async => PackageInfo(
        appName: 'Leximon',
        packageName: 'com.leximon.leximon',
        version: '1.0.0',
        buildNumber: '4',
      ),
    );

    await service.login();
    final profile = await service.getUserProfile();

    expect(profile.success, isTrue);
    expect(profile.data.id, 2);
    expect(profile.data.userCode, 'Z16EBPRIXAYE1BST');
    expect(profile.data.language, 'vi');
    expect(profile.data.appVersion, '1.0.0');
    expect(profile.data.databaseVersion, 0);
    expect(profile.data.notificationEnabled, isTrue);
    expect(profile.data.subscription, isNull);
    expect(profile.data.ownedProducts, isEmpty);
    expect(profile.data.ownedProductIds, isEmpty);
    expect(requests[1].method, 'GET');
    expect(requests[1].url.path, '/users/profile');
    expect(requests[1].headers['authorization'], 'Bearer test-token');
  });

  test('uses a stored token without logging in again', () async {
    SharedPreferences.setMockInitialValues({
      AuthTokenStorage.tokenKey: 'stored-token',
    });
    var loginCalls = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/auth/login') loginCalls++;
        return http.Response(profileResponseJson, 200);
      }),
      baseUrl: 'https://example.com',
      tokenLoader: AuthTokenStorage().loadToken,
    );
    addTearDown(client.close);

    final service = AuthApiService(
      apiClient: client,
      deviceIdentityProvider: _FakeDeviceIdentityProvider(
        const DeviceIdentity(deviceId: 'android-id-123', platform: 'ANDROID'),
      ),
      languageService: AppLanguageService(),
    );

    await service.ensureToken();
    final profile = await service.getUserProfile();

    expect(loginCalls, 0);
    expect(profile.data.id, 2);
  });

  test('refreshes the token and retries a profile request on 401', () async {
    SharedPreferences.setMockInitialValues({
      AuthTokenStorage.tokenKey: 'expired-token',
    });
    var loginCalls = 0;
    var profileCalls = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/auth/login') {
          loginCalls++;
          return http.Response(loginResponseJson, 200);
        }
        profileCalls++;
        if (profileCalls == 1) return http.Response('Unauthorized', 401);
        return http.Response(profileResponseJson, 200);
      }),
      baseUrl: 'https://example.com',
      tokenLoader: AuthTokenStorage().loadToken,
    );
    addTearDown(client.close);

    final service = AuthApiService(
      apiClient: client,
      deviceIdentityProvider: _FakeDeviceIdentityProvider(
        const DeviceIdentity(deviceId: 'android-id-123', platform: 'ANDROID'),
      ),
      languageService: AppLanguageService(),
      packageInfoLoader: () async => PackageInfo(
        appName: 'Leximon',
        packageName: 'com.leximon.leximon',
        version: '1.0.0',
        buildNumber: '4',
      ),
    );

    await service.ensureToken();
    final profile = await service.getUserProfile();

    expect(profile.data.id, 2);
    expect(profileCalls, 2);
    expect(loginCalls, 1);
    expect(client.authToken, 'test-token');
  });

  test('api client exposes decoded response data and API errors', () async {
    final successClient = ApiClient(
      client: MockClient((request) async {
        return http.Response('{"token":"abc"}', 200);
      }),
      baseUrl: 'https://example.com',
    );
    addTearDown(successClient.close);

    final response = await successClient.get('/profile');
    expect(response.mapData?['token'], 'abc');

    final errorClient = ApiClient(
      client: MockClient((request) async {
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
      baseUrl: 'https://example.com',
    );
    addTearDown(errorClient.close);

    await expectLater(
      errorClient.get('/profile'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Unauthorized'),
        ),
      ),
    );
  });
}

class _FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  const _FakeDeviceIdentityProvider(this.identity);

  final DeviceIdentity identity;

  @override
  Future<DeviceIdentity> loadIdentity() async => identity;
}

class _FakeDeviceIdStorage implements DeviceIdStorage {
  _FakeDeviceIdStorage({this.storedDeviceId});

  String? storedDeviceId;
  String? savedDeviceId;

  @override
  Future<String?> loadDeviceId() async => storedDeviceId;

  @override
  Future<void> saveDeviceId(String deviceId) async {
    savedDeviceId = deviceId;
    storedDeviceId = deviceId;
  }
}

Future<PackageInfo> _packageInfo() async => PackageInfo(
  appName: 'Leximon',
  packageName: 'com.leximon.leximon',
  version: '1.0.0',
  buildNumber: '4',
);

const loginResponseJson = '''
{
  "success": true,
  "message": "success",
  "data": {
    "user": {
      "id": 2,
      "userCode": "Z16EBPRIXAYE1BST",
      "email": "",
      "username": null,
      "avatar": "",
      "platform": "ANDROID",
      "country": "",
      "isPremium": false,
      "isActived": true,
      "isBanned": false,
      "createdAt": "2026-08-16T08:33:26.163Z",
      "updatedAt": "2026-08-16T08:33:26.163Z"
    },
    "subscription": null,
    "token": "test-token"
  }
}
''';

const profileResponseJson = '''
{
  "success": true,
  "message": "success",
  "data": {
    "id": 2,
    "userCode": "Z16EBPRIXAYE1BST",
    "email": "",
    "username": null,
    "avatar": "",
    "platform": "ANDROID",
    "country": "",
    "isPremium": false,
    "createdAt": "2026-08-16T08:33:26.163Z",
    "language": "vi",
    "appVersion": "1.0.0",
    "databaseVersion": 0,
    "notificationEnabled": true,
    "subscription": null,
    "ownedProducts": [],
    "ownedProductIds": []
  }
}
''';
