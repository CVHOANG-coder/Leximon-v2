import '../../core/network/api_response.dart';

class AuthLoginResponse {
  const AuthLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AuthLoginResponse.fromApiResponse(ApiResponse response) {
    final json = response.mapData;
    if (json == null) {
      throw FormatException('Login response must be a JSON object.');
    }
    return AuthLoginResponse.fromJson(json);
  }

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final message = json['message']?.toString() ?? '';
    final rawData = json['data'];

    if (!success) {
      throw StateError(
        message.isEmpty ? 'Login failed.' : 'Login failed: $message',
      );
    }
    if (rawData is! Map<String, dynamic>) {
      throw FormatException('Login response data is invalid.');
    }

    return AuthLoginResponse(
      success: success,
      message: message,
      data: AuthLoginData.fromJson(rawData),
    );
  }

  final bool success;
  final String message;
  final AuthLoginData data;
}

class AuthLoginData {
  const AuthLoginData({
    required this.user,
    required this.subscription,
    required this.token,
  });

  factory AuthLoginData.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final token = json['token']?.toString().trim() ?? '';
    if (rawUser is! Map<String, dynamic>) {
      throw FormatException('Login user data is invalid.');
    }
    if (token.isEmpty) {
      throw FormatException('Login token is missing.');
    }

    final rawSubscription = json['subscription'];
    return AuthLoginData(
      user: AuthUser.fromJson(rawUser),
      subscription: rawSubscription is Map<String, dynamic>
          ? rawSubscription
          : null,
      token: token,
    );
  }

  final AuthUser user;
  final Map<String, dynamic>? subscription;
  final String token;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.userCode,
    required this.email,
    required this.username,
    required this.avatar,
    required this.platform,
    required this.country,
    required this.isPremium,
    required this.isActived,
    required this.isBanned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']),
      userCode: json['userCode']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      isPremium: json['isPremium'] == true,
      isActived: json['isActived'] == true,
      isBanned: json['isBanned'] == true,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  final int id;
  final String userCode;
  final String email;
  final String? username;
  final String avatar;
  final String platform;
  final String country;
  final bool isPremium;
  final bool isActived;
  final bool isBanned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

DateTime? _asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
