import 'package:flutter/services.dart';

abstract final class AppSettingsService {
  static const _channel = MethodChannel('leximon/app_settings');

  static Future<bool> openAppSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
