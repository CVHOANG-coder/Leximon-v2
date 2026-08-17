import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStorage {
  static const tokenKey = 'auth.access_token';

  Future<String?> loadToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(tokenKey)?.trim();
    return token?.isEmpty == true ? null : token;
  }

  Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(tokenKey, token);
    if (!saved) {
      throw StateError('Could not save the authentication token.');
    }
  }

  Future<void> clearToken() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(tokenKey);
    if (!removed && preferences.containsKey(tokenKey)) {
      throw StateError('Could not clear the authentication token.');
    }
  }
}
