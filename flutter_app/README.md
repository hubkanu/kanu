# KANU — Flutter shell

Portage Flutter de la coquille iOS générée par PWABuilder (`../src/KANU`).
Comme l'app iOS d'origine, ceci **n'est pas** une réimplémentation native de
kanu-rencontres.com : c'est une WebView plein écran pointant vers le site,
avec les mêmes ponts natifs (push, impression, deep links, cookie
plateforme). Toute la logique métier reste sur le site web.

## Correspondance avec les sources iOS

| Original (`src/KANU/...`)     | Flutter (`lib/...`)              |
|--------------------------------|-----------------------------------|
| `Settings.swift`               | `config.dart`                     |
| `WebView.swift` + `ViewController.swift` | `webview_screen.dart`   |
| `PushNotifications.swift`      | `bridge/push_notifications.dart`  |
| `Printer.swift`                | `printCurrentPage()` (inline, voir `_attachBridges`) |
| `SceneDelegate.swift`          | `bridge/deep_links.dart`          |
| `AppDelegate.swift` (Firebase) | `main.dart`                       |

La PWA appelle `window.webkit.messageHandlers.<nom>.postMessage(...)`
(API WKWebView). `bridge/js_bridge_shim.dart` réimplémente cette API
au-dessus de `flutter_inappwebview` pour que le site fonctionne sans
modification.

## À faire avant de lancer l'app

1. **Firebase** (push notifications). Le `GoogleService-Info.plist` original
   ne contenait que des valeurs de template PWABuilder (projet
   `pwabuilder-ios-template`, clés à zéro) — Firebase n'a jamais été
   réellement branché, même côté iOS (`AppDelegate.swift` a
   `FirebaseApp.configure()` commenté). Il faut créer/relier un vrai projet :

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Ça régénère `lib/firebase_options.dart` et dépose `google-services.json`
   / `GoogleService-Info.plist` au bon endroit.

2. **iOS — associated domains & push**. `ios/Runner/Runner.entitlements` a
   été créé (associated domains `kanu-rencontres.com` + `aps-environment`)
   mais Xcode doit être configuré pour l'utiliser : ouvrir
   `ios/Runner.xcworkspace`, sélectionner la target Runner → Signing &
   Capabilities → ajouter "Associated Domains" et "Push Notifications" (Xcode
   liera alors automatiquement ce fichier via `CODE_SIGN_ENTITLEMENTS`).

3. **Android — liens universels**. Le `AndroidManifest.xml` déclare
   l'intent-filter `autoVerify` pour `https://kanu-rencontres.com`, mais ça
   nécessite qu'un fichier `.well-known/assetlinks.json` référençant
   l'empreinte SHA-256 de signature de l'app soit publié sur le site.

4. **Icônes / launch screen**. `assets/images/logo.png` réutilise l'icône
   iOS existante juste pour l'écran de chargement. Pour l'icône de l'app
   elle-même, utiliser `flutter_launcher_icons` avec les PNG de
   `../src/KANU/Assets.xcassets/AppIcon.appiconset`.

## Différences assumées par rapport à l'original

- Le thème adaptatif clair/sombre basé sur la couleur de fond de la page
  (`adaptiveUIStyle` dans `Settings.swift`) n'a pas été reporté — c'est un
  raffinement iOS 15+ non essentiel au fonctionnement de l'app.
- Le shim JS ne couvre que les 5 handlers du fichier `WebView.swift` fourni.
  Si le site utilise d'autres ponts natifs (Android-only, etc.) que ce repo
  ne référence pas, il faudra les ajouter à `config.dart` /
  `js_bridge_shim.dart`.

## Lancer l'app

```bash
flutter pub get
flutter run
```
