import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the last successfully authenticated iOS device ID in Keychain.
abstract interface class DeviceIdStorage {
  Future<String?> loadDeviceId();

  Future<void> saveDeviceId(String deviceId);
}

class DeviceIdKeychainStorage implements DeviceIdStorage {
  DeviceIdKeychainStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const deviceIdKey = 'auth.device_id';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> loadDeviceId() async {
    final deviceId = await _storage.read(key: deviceIdKey);
    final trimmedDeviceId = deviceId?.trim();
    return trimmedDeviceId?.isEmpty == true ? null : trimmedDeviceId;
  }

  @override
  Future<void> saveDeviceId(String deviceId) {
    return _storage.write(key: deviceIdKey, value: deviceId);
  }
}
