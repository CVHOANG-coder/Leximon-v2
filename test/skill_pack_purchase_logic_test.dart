import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/services/iap_purchase_service.dart';
import 'package:leximon/data/services/iap_transaction_api_service.dart';
import 'package:leximon/presentation/screens/listening_practice/skill_pack_purchase_screen.dart';

void main() {
  const productId = 'com.wordisland.learnenglish.ios.pack.listening';

  test('accepts a skill pack only when ownedProductIds contains its id', () {
    const result = IapPurchaseResult(
      IapPurchaseResultStatus.verified,
      verificationResponse: IapTransactionBuyResponse(
        success: true,
        message: 'Transaction processed',
        data: {
          'isPremium': true,
          'ownedProductIds': [productId],
        },
      ),
    );

    expect(
      ownsSkillPackFromPurchaseResult(result: result, productId: productId),
      isTrue,
    );
    expect(
      ownsSkillPackFromPurchaseResult(
        result: result,
        productId: 'com.wordisland.learnenglish.ios.pack.reading',
      ),
      isFalse,
    );
  });

  test('returns unknown when the response has no ownership list', () {
    const result = IapPurchaseResult(
      IapPurchaseResultStatus.verified,
      verificationResponse: IapTransactionBuyResponse(
        success: true,
        message: 'Transaction processed',
        data: {'isPremium': true},
      ),
    );

    expect(
      ownsSkillPackFromPurchaseResult(result: result, productId: productId),
      isNull,
    );
  });
}
