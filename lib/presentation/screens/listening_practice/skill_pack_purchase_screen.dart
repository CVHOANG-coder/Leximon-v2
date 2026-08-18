import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/iap_packages_response.dart';
import '../../../data/services/iap_catalog_service.dart';
import '../../../data/services/iap_purchase_service.dart';
import '../../../shared/providers/app_providers.dart';

enum SkillPackType {
  listening,
  speaking,
  reading,
  grammar;

  String get productId => switch (this) {
    SkillPackType.listening => 'com.wordisland.learnenglish.ios.pack.listening',
    SkillPackType.speaking => 'com.wordisland.learnenglish.ios.pack.speaking',
    SkillPackType.reading => 'com.wordisland.learnenglish.ios.pack.reading',
    SkillPackType.grammar => 'com.wordisland.learnenglish.ios.pack.grammar',
  };

  String get bannerAsset => switch (this) {
    SkillPackType.listening =>
      'assets/images/in_app_purchase/banner_listening_pack.png',
    SkillPackType.speaking =>
      'assets/images/in_app_purchase/banner_speak_pack.png',
    SkillPackType.reading =>
      'assets/images/in_app_purchase/banner_read_pack.png',
    SkillPackType.grammar =>
      'assets/images/in_app_purchase/banner_grammar_pack.png',
  };

  String get iconAsset => switch (this) {
    SkillPackType.listening =>
      'assets/images/in_app_purchase/listening_pack_icon.png',
    SkillPackType.speaking =>
      'assets/images/in_app_purchase/speak_pack_icon.png',
    SkillPackType.reading => 'assets/images/in_app_purchase/read_pack_icon.png',
    SkillPackType.grammar =>
      'assets/images/in_app_purchase/grammar_pack_icon.png',
  };

  String get benefitAsset => switch (this) {
    SkillPackType.listening => 'assets/images/in_app_purchase/audio_icon.png',
    SkillPackType.speaking => 'assets/images/in_app_purchase/speak_icon.png',
    SkillPackType.reading => 'assets/images/in_app_purchase/read_icon.png',
    SkillPackType.grammar => 'assets/images/in_app_purchase/grammar_icon.png',
  };

  String get titleKey => switch (this) {
    SkillPackType.listening => 'skillPackListeningTitle',
    SkillPackType.speaking => 'skillPackSpeakingTitle',
    SkillPackType.reading => 'skillPackReadingTitle',
    SkillPackType.grammar => 'skillPackGrammarTitle',
  };

  String get descriptionKey => switch (this) {
    SkillPackType.listening => 'skillPackListeningDescription',
    SkillPackType.speaking => 'skillPackSpeakingDescription',
    SkillPackType.reading => 'skillPackReadingDescription',
    SkillPackType.grammar => 'skillPackGrammarDescription',
  };

  String get unlockKey => switch (this) {
    SkillPackType.listening => 'skillPackListeningUnlock',
    SkillPackType.speaking => 'skillPackSpeakingUnlock',
    SkillPackType.reading => 'skillPackReadingUnlock',
    SkillPackType.grammar => 'skillPackGrammarUnlock',
  };

  String get benefitKey => switch (this) {
    SkillPackType.listening => 'skillPackListeningBenefit',
    SkillPackType.speaking => 'skillPackSpeakingBenefit',
    SkillPackType.reading => 'skillPackReadingBenefit',
    SkillPackType.grammar => 'skillPackGrammarBenefit',
  };
}

class SkillPackPurchaseScreen extends ConsumerStatefulWidget {
  const SkillPackPurchaseScreen({required this.skill, super.key});

  final SkillPackType skill;

  @override
  ConsumerState<SkillPackPurchaseScreen> createState() =>
      _SkillPackPurchaseScreenState();
}

class _SkillPackPurchaseScreenState
    extends ConsumerState<SkillPackPurchaseScreen> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(iapCatalogProvider);
    final catalog = catalogState.valueOrNull;
    final package = _findPackage(catalog);
    final product = package == null ? null : catalog?.productFor(package);
    final currentPrice = _currentPrice(product);
    final originalPrice = _originalPrice(context, product);
    final saving = _saving(context, product);
    final isReady = package != null && product != null && currentPrice != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF3FBFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3FBFF),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: Image.asset(
                      widget.skill.bannerAsset,
                      fit: BoxFit.fill,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _PackIntroCard(
                        iconAsset: widget.skill.iconAsset,
                        title: package?.name.trim().isNotEmpty == true
                            ? package!.name.trim()
                            : context.l10n.text(widget.skill.titleKey),
                        description:
                            package?.description.trim().isNotEmpty == true
                            ? package!.description.trim()
                            : context.l10n.text(widget.skill.descriptionKey),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PackBenefit(
                              asset:
                                  'assets/images/in_app_purchase/lock_icon.png',
                              label: context.l10n.text(widget.skill.unlockKey),
                            ),
                          ),
                          Expanded(
                            child: _PackBenefit(
                              asset: widget.skill.benefitAsset,
                              label: context.l10n.text(widget.skill.benefitKey),
                            ),
                          ),
                          Expanded(
                            child: _PackBenefit(
                              asset:
                                  'assets/images/in_app_purchase/unlimited_icon.png',
                              label: context.l10n.text('skillPackForever'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _PackPriceCard(
                      currentPrice:
                          currentPrice ?? context.l10n.text('skillPackLoading'),
                      originalPrice: originalPrice,
                      saving: saving,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Color(0xFF8091B0),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.l10n.text('skillPackSecure'),
                        style: const TextStyle(
                          color: Color(0xFF6E7F9F),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PurchaseButton(
                      enabled: isReady && !_isPurchasing,
                      loading: _isPurchasing,
                      label: context.l10n.text(
                        'skillPackBuy',
                        values: {
                          'price':
                              currentPrice ??
                              context.l10n.text('skillPackLoading'),
                        },
                      ),
                      onTap: _buy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isPurchasing
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16B85A),
                          side: const BorderSide(
                            color: Color(0xFF16B85A),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          context.l10n.text('skillPackLater'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 18,
              child: Material(
                color: Colors.white.withValues(alpha: .9),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  key: const ValueKey('skill-pack-purchase-back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF132A58),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IapPackage? _findPackage(IapCatalog? catalog) {
    if (catalog == null) return null;
    for (final package in catalog.skillPackPackages) {
      if (package.productId == widget.skill.productId) return package;
    }
    return null;
  }

  String? _currentPrice(ProductDetails? product) {
    final price = product?.price.trim();
    return price?.isNotEmpty == true ? price : null;
  }

  String? _originalPrice(BuildContext context, ProductDetails? product) {
    return _storePriceForAmount(context, product, 3.34);
  }

  String? _saving(BuildContext context, ProductDetails? product) {
    return _storePriceForAmount(context, product, 2.34);
  }

  String? _storePriceForAmount(
    BuildContext context,
    ProductDetails? product,
    double multiplier,
  ) {
    if (product == null ||
        !product.rawPrice.isFinite ||
        product.rawPrice <= 0 ||
        !multiplier.isFinite ||
        multiplier <= 0) {
      return null;
    }

    final currencyCode = product.currencyCode.trim().toUpperCase();
    if (currencyCode.isEmpty) return null;

    final currencySymbol = product.currencySymbol.trim();
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: currencySymbol.isEmpty ? currencyCode : currencySymbol,
    ).format(product.rawPrice * multiplier);
  }

  Future<void> _buy() async {
    if (_isPurchasing) return;
    final catalog = ref.read(iapCatalogProvider).valueOrNull;
    final package = _findPackage(catalog);
    final product = package == null ? null : catalog?.productFor(package);
    if (package == null || product == null) {
      _showMessage(context.l10n.text('skillPackUnavailable'));
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      final result = await ref
          .read(iapPurchaseServiceProvider)
          .purchase(package: package, product: product);
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      if (result.isSuccess) {
        ref.invalidate(remoteUserProfileProvider);
        Navigator.of(context).pop(true);
        return;
      }
      if (result.status != IapPurchaseResultStatus.canceled) {
        _showMessage(_purchaseMessage(result));
      }
    } on Object {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      _showMessage(context.l10n.text('skillPackPurchaseError'));
    }
  }

  String _purchaseMessage(IapPurchaseResult result) => switch (result.status) {
    IapPurchaseResultStatus.storeUnavailable => context.l10n.text(
      'iapStoreUnavailable',
    ),
    IapPurchaseResultStatus.productUnavailable => context.l10n.text(
      'skillPackUnavailable',
    ),
    IapPurchaseResultStatus.verificationFailed =>
      result.message?.trim().isNotEmpty == true
          ? result.message!
          : context.l10n.text('iapVerificationFailed'),
    IapPurchaseResultStatus.busy => context.l10n.text('iapPurchaseBusy'),
    _ => context.l10n.text('skillPackPurchaseError'),
  };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PackIntroCard extends StatelessWidget {
  const _PackIntroCard({
    required this.iconAsset,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(27),
      boxShadow: const [
        BoxShadow(
          color: Color(0x172A70B8),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            iconAsset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF102955),
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF627596),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PackBenefit extends StatelessWidget {
  const _PackBenefit({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Image.asset(asset, width: 56, height: 56, fit: BoxFit.contain),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 3,
        style: const TextStyle(
          color: Color(0xFF304A78),
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _PackPriceCard extends StatelessWidget {
  const _PackPriceCard({
    required this.currentPrice,
    required this.originalPrice,
    required this.saving,
  });

  final String currentPrice;
  final String? originalPrice;
  final String? saving;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFB7DFFF), width: 1.5),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.text('skillPackOneTime'),
                  style: const TextStyle(
                    color: Color(0xFF102955),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentPrice,
                  style: const TextStyle(
                    color: Color(0xFF1768E8),
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (originalPrice != null)
                  Text(
                    originalPrice!,
                    style: const TextStyle(
                      color: Color(0xFF8291AD),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                      decorationThickness: 1.6,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (saving != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FBF1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFA9E8C9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/in_app_purchase/gift.png',
                  width: 35,
                  height: 35,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.l10n.text(
                      'skillPackSave',
                      values: {'amount': saving, 'percent': 70},
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0CA65A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 62,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFF55A9FF), Color(0xFF27D5C6)]
              : const [Color(0xFFB5D0E8), Color(0xFFB7DFDD)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x332C95F2),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && !loading ? onTap : null,
          borderRadius: BorderRadius.circular(32),
          child: Center(
            child: loading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}
