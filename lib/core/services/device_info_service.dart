import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceIdentity {
  const DeviceIdentity({required this.deviceId, required this.platform});

  final String deviceId;
  final String platform;
}

abstract interface class DeviceIdentityProvider {
  Future<DeviceIdentity> loadIdentity();
}

/// Reads the stable identifier and API platform name for the current device.
class DeviceInfoService implements DeviceIdentityProvider {
  DeviceInfoService({
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<String?> Function()? androidIdLoader,
  }) : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
       _androidIdLoader = androidIdLoader ?? const AndroidId().getId;

  final DeviceInfoPlugin _deviceInfoPlugin;
  final Future<String?> Function() _androidIdLoader;

  @override
  Future<DeviceIdentity> loadIdentity() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Login device identity is only supported on Android and iOS.',
      );
    }

    final info = await _deviceInfoPlugin.deviceInfo;

    if (info is AndroidDeviceInfo) {
      final deviceId = (await _androidIdLoader())?.trim();
      if (deviceId == null || deviceId.isEmpty) {
        throw StateError('Could not read the Android device ID.');
      }
      return DeviceIdentity(deviceId: deviceId, platform: 'ANDROID');
    }

    if (info is IosDeviceInfo) {
      final deviceId = info.identifierForVendor?.trim();
      if (deviceId == null || deviceId.isEmpty) {
        throw StateError('Could not read the iOS vendor identifier.');
      }
      return DeviceIdentity(deviceId: deviceId, platform: 'IOS');
    }

    throw StateError('Could not identify the current mobile platform.');
  }
}
