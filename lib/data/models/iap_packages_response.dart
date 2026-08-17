import '../../core/network/api_response.dart';

class IapPackagesResponse {
  const IapPackagesResponse({
    required this.success,
    required this.message,
    required this.packages,
    required this.total,
  });

  factory IapPackagesResponse.fromApiResponse(ApiResponse response) {
    final json = response.mapData;
    if (json == null) {
      throw FormatException('IAP packages response must be a JSON object.');
    }
    return IapPackagesResponse.fromJson(json);
  }

  factory IapPackagesResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final message = json['message']?.toString() ?? '';
    final rawData = json['data'];
    if (!success) {
      throw StateError(
        message.isEmpty ? 'Could not load IAP packages.' : message,
      );
    }
    if (rawData is! Map<String, dynamic>) {
      throw FormatException('IAP packages data is invalid.');
    }

    final rawPackages = rawData['packages'];
    if (rawPackages is! Map<String, dynamic>) {
      throw FormatException('IAP package groups are invalid.');
    }

    final packages = <String, List<IapPackage>>{};
    for (final entry in rawPackages.entries) {
      final rawItems = entry.value;
      if (rawItems is! List) continue;
      packages[entry.key] = rawItems
          .whereType<Map<String, dynamic>>()
          .map(IapPackage.fromJson)
          .toList(growable: false);
    }

    return IapPackagesResponse(
      success: success,
      message: message,
      packages: packages,
      total: _asInt(rawData['total']),
    );
  }

  final bool success;
  final String message;
  final Map<String, List<IapPackage>> packages;
  final int total;

  List<IapPackage> get enabledPackages =>
      packages.values
          .expand((items) => items)
          .where((item) => item.isEnabled)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

class IapPackage {
  const IapPackage({
    required this.id,
    required this.productId,
    required this.productType,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.platform,
    required this.packDurationDay,
    required this.trialDays,
    required this.isEnabled,
    required this.sortOrder,
    required this.adjustEventToken,
    required this.createdAt,
    required this.updatedAt,
    required this.group,
  });

  factory IapPackage.fromJson(Map<String, dynamic> json) {
    return IapPackage(
      id: _asInt(json['id']),
      productId: json['productId']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _asDouble(json['price']),
      currency: json['currency']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      packDurationDay: _asInt(json['packDurationDay']),
      trialDays: _asInt(json['trialDays']),
      isEnabled: json['isEnabled'] == true,
      sortOrder: _asInt(json['sortOrder']),
      adjustEventToken: json['adjustEventToken']?.toString() ?? '',
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
      group: json['group']?.toString() ?? '',
    );
  }

  final int id;
  final String productId;
  final String productType;
  final String name;
  final String description;

  /// Backend reference price. This value must not be used for Store UI price.
  final double price;

  final String currency;
  final String platform;
  final int packDurationDay;
  final int trialDays;
  final bool isEnabled;
  final int sortOrder;
  final String adjustEventToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String group;
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime? _asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
