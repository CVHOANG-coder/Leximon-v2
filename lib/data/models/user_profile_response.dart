import '../../core/network/api_response.dart';

class UserProfileResponse {
  const UserProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromApiResponse(ApiResponse response) {
    final json = response.mapData;
    if (json == null) {
      throw FormatException('User profile response must be a JSON object.');
    }
    return UserProfileResponse.fromJson(json);
  }

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final message = json['message']?.toString() ?? '';
    final rawData = json['data'];

    if (!success) {
      throw StateError(
        message.isEmpty ? 'Could not load user profile.' : message,
      );
    }
    if (rawData is! Map<String, dynamic>) {
      throw FormatException('User profile data is invalid.');
    }

    return UserProfileResponse(
      success: success,
      message: message,
      data: UserProfile.fromJson(rawData),
    );
  }

  final bool success;
  final String message;
  final UserProfile data;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.userCode,
    required this.email,
    required this.username,
    required this.avatar,
    required this.platform,
    required this.country,
    required this.isPremium,
    required this.createdAt,
    required this.language,
    required this.appVersion,
    required this.notificationEnabled,
    required this.subscription,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawSubscription = json['subscription'];
    return UserProfile(
      id: _asInt(json['id']),
      userCode: json['userCode']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      isPremium: json['isPremium'] == true,
      createdAt: _asDateTime(json['createdAt']),
      language: json['language']?.toString() ?? '',
      appVersion: json['appVersion']?.toString() ?? '',
      notificationEnabled: json['notificationEnabled'] == true,
      subscription: rawSubscription is Map<String, dynamic>
          ? rawSubscription
          : null,
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
  final DateTime? createdAt;
  final String language;
  final String appVersion;
  final bool notificationEnabled;
  final Map<String, dynamic>? subscription;
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

DateTime? _asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
