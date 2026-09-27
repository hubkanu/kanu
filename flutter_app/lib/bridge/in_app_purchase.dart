import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart' as cfg;

/// IAP bridge: exposes subscription purchase to the PWA through the same
/// `window.webkit.messageHandlers.*` surface as the other bridges.
///
/// Web -> native handlers:
///  - "iap-load-products": query StoreKit for [cfg.iapProductIds] and dispatch
///    "iap-products-loaded" with the available products.
///  - "iap-purchase": start a StoreKit purchase for the given productId
///    (payload: { productId, applicationUserName? }). applicationUserName is
///    the KANU member id, stored on the receipt to link the purchase to the
///    right account server-side.
///  - "iap-restore-purchases": restore previously purchased subscriptions.
///
/// Native -> web events (CustomEvents on window):
///  - iap-products-loaded: { products: [{ productId, title, description,
///      price, currencySymbol, priceAmountMicros }] }
///  - iap-purchase-result: { productId, status, transactionId?,
///      receipt?, applicationUserName?, reason } — one per bought product on
///      the purchaseStream. `receipt` is the base64 App Store receipt
///      (serverVerificationData) and MUST be validated by the
///      kanu-rencontres.com backend (App Store Server API / verifyReceipt)
///      before premium is unlocked for the member.
///  - iap-restore-result: { status: 'ok' | 'error', reason }
class InAppPurchaseBridge {
  InAppPurchaseBridge(this._getController);

  /// Returns the currently active WebView controller, or null while the
  /// page hasn't finished loading yet.
  final InAppWebViewController? Function() _getController;

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _streamSubscribed = false;

  void attach(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: cfg.BridgeMessages.iapLoadProducts,
      callback: (_) => _handleLoadProducts(),
    );
    controller.addJavaScriptHandler(
      handlerName: cfg.BridgeMessages.iapPurchase,
      callback: (args) => _handlePurchase(args),
    );
    controller.addJavaScriptHandler(
      handlerName: cfg.BridgeMessages.iapRestorePurchases,
      callback: (_) => _handleRestorePurchases(),
    );

    _subscribePurchaseStream();
  }

  void _subscribePurchaseStream() {
    if (_streamSubscribed) return;
    _streamSubscribed = true;
    _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchaseDetails(purchase);
      }
    });
  }

  Future<void> _handleLoadProducts() async {
    try {
      final response = await _iap.queryProductDetails(
        cfg.iapProductIds.toSet(),
      );
      final products = response.productDetails
          .map((d) => {
                'productId': d.id,
                'title': d.title,
                'description': d.description,
                'price': d.price,
                'currencySymbol': d.currencySymbol,
                'priceAmountMicros': d.rawPrice.round(),
              })
          .toList();
      _dispatchEvent(
        cfg.BridgeEvents.iapProductsLoaded,
        jsonEncode({'products': products}),
      );
    } catch (e) {
      _dispatchError('iap-load-products', 'Failed to load products: $e');
    }
  }

  Future<void> _handlePurchase(List<dynamic> args) async {
    dynamic payload;
    try {
      payload = args.isNotEmpty ? args.first : null;
    } catch (_) {
      _dispatchError('iap-purchase', 'Invalid arguments');
      return;
    }

    String productId = '';
    String? applicationUserName;
    if (payload is Map) {
      productId = payload['productId'] as String? ?? '';
      applicationUserName = payload['applicationUserName'] as String?;
    } else if (payload is String) {
      productId = payload;
    }
    if (productId.isEmpty) {
      _dispatchError('iap-purchase', 'Missing productId');
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _dispatchError('iap-purchase', 'StoreKit is not available');
      return;
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      _dispatchError(
        'iap-purchase',
        'No product found for "$productId" (not configured in App Store Connect?)',
      );
      return;
    }

    final product = response.productDetails.first;
    final purchased = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
      ),
    );
    if (!purchased) {
      _dispatchError('iap-purchase', 'Purchase request was not sent');
    }
  }

  Future<void> _handleRestorePurchases() async {
    try {
      await _iap.restorePurchases();
      _dispatchEvent(
        cfg.BridgeEvents.iapRestoreResult,
        jsonEncode({'status': 'ok'}),
      );
    } catch (e) {
      _dispatchEvent(
        cfg.BridgeEvents.iapRestoreResult,
        jsonEncode({'status': 'error', 'reason': '$e'}),
      );
    }
  }

  void _handlePurchaseDetails(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
        _dispatchEvent(
          cfg.BridgeEvents.iapPurchaseResult,
          jsonEncode({
            'productId': purchase.productID,
            'status': 'purchased',
            'transactionId': purchase.purchaseID,
            'applicationUserName': purchase.verificationData.source,
            'receipt': purchase.verificationData.serverVerificationData,
          }),
        );
        _complete(purchase);
      case PurchaseStatus.restored:
        _dispatchEvent(
          cfg.BridgeEvents.iapPurchaseResult,
          jsonEncode({
            'productId': purchase.productID,
            'status': 'restored',
            'transactionId': purchase.purchaseID,
            'receipt': purchase.verificationData.serverVerificationData,
          }),
        );
        _complete(purchase);
      case PurchaseStatus.pending:
        _dispatchEvent(
          cfg.BridgeEvents.iapPurchaseResult,
          jsonEncode({
            'productId': purchase.productID,
            'status': 'pending',
          }),
        );
      case PurchaseStatus.error:
        _dispatchEvent(
          cfg.BridgeEvents.iapPurchaseResult,
          jsonEncode({
            'productId': purchase.productID,
            'status': 'error',
            'reason': purchase.error?.message ?? 'Purchase failed',
          }),
        );
      case PurchaseStatus.canceled:
        _dispatchEvent(
          cfg.BridgeEvents.iapPurchaseResult,
          jsonEncode({
            'productId': purchase.productID,
            'status': 'canceled',
          }),
        );
    }
  }

  void _complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (_) {
        // Re-delivered on next launch; nothing else to do here.
      }
    }
  }

  void _dispatchError(String source, String message) {
    _dispatchEvent(
      cfg.BridgeEvents.iapError,
      jsonEncode({'source': source, 'message': message}),
    );
  }

  void _dispatchEvent(String event, String jsonDetail) {
    final controller = _getController();
    if (controller == null) {
      Future.delayed(const Duration(seconds: 1), () {
        _dispatchEvent(event, jsonDetail);
      });
      return;
    }
    controller.evaluateJavascript(
      source:
          "window.dispatchEvent(new CustomEvent('$event', { detail: $jsonDetail }));",
    );
  }
}