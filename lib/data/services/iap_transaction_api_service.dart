import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class IapTransactionApiService {
  IapTransactionApiService(this._apiClient);

  static const transactionBuyPath = '/iap/transaction-buy';

  final ApiClient _apiClient;

  Future<IapTransactionBuyResponse> verifyPurchase(
    IapTransactionBuyRequest request,
  ) async {
    final response = await _apiClient.post(
      transactionBuyPath,
      body: request.toJson(),
    );
    return IapTransactionBuyResponse.fromApiResponse(response);
  }
}

class IapTransactionBuyRequest {
  const IapTransactionBuyRequest({
    required this.platform,
    required this.productId,
    required this.signedTransaction,
  });

  final String platform;
  final String productId;
  final String signedTransaction;

  Map<String, Object?> toJson() => {
    'platform': platform,
    'receipt': {'productId': productId, 'signedTransaction': signedTransaction},
  };
}

class IapTransactionBuyResponse {
  const IapTransactionBuyResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory IapTransactionBuyResponse.fromApiResponse(ApiResponse response) {
    final json = response.mapData;
    if (json == null) {
      throw const FormatException(
        'IAP transaction response must be a JSON object.',
      );
    }

    final success = json['success'] != false;
    final message = json['message']?.toString() ?? '';
    if (!success) {
      throw StateError(
        message.isEmpty ? 'The purchase could not be verified.' : message,
      );
    }

    final rawData = json['data'];
    return IapTransactionBuyResponse(
      success: success,
      message: message,
      data: rawData is Map<String, dynamic> ? rawData : const {},
    );
  }

  final bool success;
  final String message;
  final Map<String, dynamic> data;

  /// The backend returns the user's current entitlement after processing the
  /// transaction. A successful request can still contain `isPremium: false`
  /// when the transaction is an expired renewal that only needed cleanup.
  bool? get isPremium {
    final value = data['isPremium'];
    return value is bool ? value : null;
  }

  String? get lifetimeProductId {
    final value = data['lifetimeProductId'];
    return value is String && value.isNotEmpty ? value : null;
  }

  Set<String> get ownedProductIds {
    final value = data['ownedProductIds'];
    if (value is! List) return const {};
    return value.map((item) => item.toString()).toSet();
  }
}
