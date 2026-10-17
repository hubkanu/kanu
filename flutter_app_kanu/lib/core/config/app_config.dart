/// Configuration centrale de l'application KANU.
///
/// L'API est un backend [PocketBase] exposé par le site
/// `https://kanu-rencontres.com`. Toutes les données (membres, messages,
/// compatibilités, questionnaires…) passent par les endpoints REST
/// `/api/collections/...`.
///
/// En l'absence de backend joignable (mode développement, tests, premier
/// lancement hors-ligne), l'application bascule automatiquement sur un jeu de
/// données de démonstration **uniquement lorsque** [allowDemoFallback] est vrai.
class AppConfig {
  const AppConfig._();

  /// Nom affiché de l'application.
  static const String appName = 'KANU';

  /// Baseline marketing.
  static const String tagline = 'Rencontrer moins. Rencontrer mieux.';

  /// Site public (mentions légales, CGU, partage…).
  static const String websiteUrl = 'https://kanu-rencontres.com';

  /// URL du backend PocketBase.
  static const String apiBaseUrl = 'https://1gjvo6i.cserverhost.cloud';

  /// Collections PocketBase utilisées par KANU.
  static const String membersCollection = 'kanu_members';
  static const String questionnairesCollection = 'kanu_questionnaires';
  static const String messagesCollection = 'kanu_messages';
  static const String compatibilitiesCollection = 'kanu_compatibilites';
  static const String demandesCollection = 'kanu_demandes';
  static const String contactsCollection = 'kanu_contacts';
  static const String reportsCollection = 'kanu_signalements';

  /// Email de contact affiché dans les écrans d'aide.
  static const String supportEmail = 'contact@kanu-rencontres.com';

  /// Adresse de l'association éditrice.
  static const String publisher = "Lova Film (SIREN 899 947 451)";

  /// Délai réseau maximal.
  static const Duration networkTimeout = Duration(seconds: 15);

  /// Active le repli sur les données de démo si l'API est injoignable.
  /// Mettre à `false` en production pour n'afficher que des erreurs réelles.
  static const bool allowDemoFallback = true;
}
