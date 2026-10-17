# KANU — application mobile native (Flutter)

Application Flutter **100 % native** qui remplace la WebView de
[kanu-rencontres.com](https://kanu-rencontres.com). Elle reproduit l'expérience
de la plateforme de rencontres sérieuses KANU (30 ans et plus) : questionnaire
de compatibilité, sélection humaine, messagerie après accord mutuel et
abonnement Premium.

## Fonctionnalités

- **Authentification** : connexion PocketBase, inscription complète (identité,
  profil, charte de sincérité), réinitialisation du mot de passe.
- **Onboarding** de présentation du concept au premier lancement.
- **Accueil** : synthèse (profil, statut Premium, compatibilités, actions).
- **Recherche** de profils avec filtres (âge, genre, ville, religion, enfants).
- **Accords** : compatibilités validées (score ≥ 70), fiche membre détaillée.
- **Messagerie** privée (conversations, envoi optimiste, lu/non-lu).
- **Premium** : grille tarifaire (39,90 €/mois · 97,90 €/3 mois), achat
  (simulé, prêt pour le paiement natif).
- **Communauté** : « Les Mots de KANU » et prochains événements.
- **Paramètres** : apparence (thème), notifications, édition du profil,
  documents légaux, suppression de compte.
- **Signalement** de profil et contenus légaux (mentions, CGU, CGV, charte,
  confidentialité, cookies, protection des mineurs).

## Architecture

```
lib/
├── app.dart                 # MaterialApp.router + thèmes
├── main.dart                # Bootstrap + injection (Provider)
├── core/
│   ├── config/              # AppConfig (API, collections, tarifs…)
│   ├── network/             # PocketBaseClient (Dio) + ApiException
│   ├── router/              # AppRouter (go_router)
│   ├── storage/             # PreferencesService (SharedPreferences)
│   ├── theme/               # AppColors / AppTheme (design system KANU)
│   └── utils/               # Validators / Formatters
├── data/
│   ├── demo/                # DemoData (repli hors-ligne)
│   └── repositories/        # auth / member / compatibility / message / questionnaire
├── models/                  # Member, Compatibility, Message, Questionnaire…
├── state/                   # Providers (auth, theme, search, messages…)
├── shared/widgets/          # Composants UI réutilisables
└── features/                # Écrans, organisés par domaine
```

- **État** : `flutter_riverpod` (`Notifier` / `NotifierProvider`, calcul des
  dépendances par `ref.watch`).
- **Navigation** : `go_router` (`StatefulShellRoute` à 5 onglets).
- **Réseau** : `dio` vers le backend PocketBase
  `https://1gjvo6i.cserverhost.cloud` (endpoints `/api/collections/...`).
- **Persistance** : `shared_preferences` (jeton, profil, thème, consentement).

## Démarrage

```bash
flutter pub get
flutter run
```

### Vérifications

```bash
flutter analyze
flutter test
```

## Configuration

Tout est centralisé dans `lib/core/config/app_config.dart` :

- `apiBaseUrl` : URL du backend PocketBase ;
- collections (`kanu_members`, `kanu_messages`, `kanu_compatibilites`…) ;
- `allowDemoFallback` : repli sur des données de démonstration lorsque l'API est
  injoignable (activé par défaut en développement ; à passer à `false` en
  production) ;
- coordonnées de l'éditeur et e-mail de support.

## Paiement

L'achat est actuellement simulé dans `SubscriptionProvider` et répercuté sur le
membre courant. Les identifiants de produits pour l'In-App Purchase sont déjà
définis dans `SubscriptionPlan` :

- `com.kanurencontres.app.subscription.monthly`
- `com.kanurencontres.app.subscription.tri`

Le branchement au store (StoreKit / Play Billing) se fait dans
`SubscriptionProvider.purchase`.

## Licence / éditeur

Édité par Lova Film (SIREN 899 947 451) — contact :
contact@kanu-rencontres.com.
