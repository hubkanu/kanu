import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'config.dart' as cfg;

Future<void> showNativeSubscriptionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NativeSubscriptionSheet(),
  );
}

class _NativeSubscriptionSheet extends StatefulWidget {
  const _NativeSubscriptionSheet();

  @override
  State<_NativeSubscriptionSheet> createState() =>
      _NativeSubscriptionSheetState();
}

class _NativeSubscriptionSheetState extends State<_NativeSubscriptionSheet> {
  final InAppPurchase _store = InAppPurchase.instance;
  late Future<List<ProductDetails>> _products;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _products = _loadProducts();
  }

  Future<List<ProductDetails>> _loadProducts() async {
    if (!await _store.isAvailable()) return const [];
    final response = await _store.queryProductDetails(cfg.iapProductIds.toSet());
    return response.productDetails;
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() => _busy = true);
    try {
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await _store.restorePurchases();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FutureBuilder<List<ProductDetails>>(
          future: _products,
          builder: (context, snapshot) {
            final products = snapshot.data ?? const <ProductDetails>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('KANU Premium', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Abonnement acheté de façon sécurisée avec l’App Store.'),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (products.isEmpty)
                  const Text('Abonnement temporairement indisponible. Réessayez plus tard.')
                else
                  ...products.map((product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FilledButton(
                          onPressed: _busy ? null : () => _buy(product),
                          child: Text('${product.title} · ${product.price}'),
                        ),
                      )),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restaurer mes achats'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
