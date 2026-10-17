import 'package:equatable/equatable.dart';

/// Formule d'abonnement KANU.
///
/// Les montants correspondent à la grille tarifaire du site :
///   • 1 mois  — 39,90 €
///   • 3 mois  — 97,90 € (soit 32,63 €/mois)
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.durationMonths,
    this.badge,
    this.recommended = false,
    this.appStoreProductId,
    this.perks = const [],
  });

  final String id;
  final String title;
  final int priceCents;
  final int durationMonths;
  final String? badge;
  final bool recommended;
  final String? appStoreProductId;
  final List<String> perks;

  String get priceLabel => formatEuros(priceCents);

  double get monthlyPriceCents => priceCents / durationMonths;

  String get monthlyLabel =>
      '${formatEuros(monthlyPriceCents.round())} / mois';

  static String formatEuros(int cents) {
    final String value = (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '$value €';
  }

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: '1m',
      title: '1 mois',
      priceCents: 3990,
      durationMonths: 1,
      appStoreProductId: 'com.kanurencontres.app.subscription.month',
    ),
    SubscriptionPlan(
      id: '3m',
      title: '3 mois',
      priceCents: 9790,
      durationMonths: 3,
      badge: 'Le plus choisi',
      recommended: true,
      appStoreProductId: 'com.kanurencontres.app.subscription.trim',
    ),
  ];

  static const List<String> premiumPerks = [
    'Accès aux profils complets et aux photos autorisées',
    'Score et analyse de compatibilité détaillés',
    'Messagerie après accord mutuel',
    'Notifications de nouvelles compatibilités',
    'Mise en relation accompagnée par nos conseillers',
    'Sans engagement, résiliable à tout moment',
  ];

  @override
  List<Object?> get props => [id, title, priceCents, durationMonths];
}
