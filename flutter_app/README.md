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

## Firebase

Configuré pour de vrai sur le projet **`kanu-rencontres`**
(console : https://console.firebase.google.com/project/kanu-rencontres/overview) —
`lib/firebase_options.dart`, `android/app/google-services.json` et
`ios/Runner/GoogleService-Info.plist` contiennent de vraies clés (pas des
secrets sensibles côté client, mais évitez de les republier ailleurs sans
raison). Le `GoogleService-Info.plist` original du shell iOS ne contenait que
des valeurs de template PWABuilder (projet `pwabuilder-ios-template`, clés à
zéro) — Firebase n'avait jamais été réellement branché, même côté iOS
(`AppDelegate.swift` a `FirebaseApp.configure()` commenté).

Pour reconfigurer plus tard (nouveau projet, nouvelles plateformes) :

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## À faire avant de publier

1. **iOS — associated domains & push**. `ios/Runner/Runner.entitlements` a
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

## "Application non reconnue" / Play Protect à l'installation

En installant l'APK debug hors Play Store (sideload), Android peut afficher
un avertissement du type "application non reconnue" ou bloquer l'installation
via Play Protect. C'est normal et attendu pour n'importe quel APK debug non
distribué par le Play Store : il est signé avec la clé de debug (pas une clé
de confiance), et Google n'a aucune réputation sur ce binaire. Ça disparaît
dès que l'app est distribuée via un canal Play Console (même la piste
"test interne"), qui applique la signature Play App Signing.

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

## Builds

- **Android** : `flutter build apk --debug` fonctionne directement (testé — voir
  `.github/workflows/flutter-build.yml`). Le projet a dû être épinglé sur
  Gradle 8.14.2 / AGP 8.11.1 / Kotlin 2.2.20 car le plugin
  `flutter_inappwebview_android` casse avec l'AGP 9 par défaut du template
  Flutter (appel à une API de proguard supprimée).

  Pour une release signée + obfusquée (ce qu'attend le Play Store) :

  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
  ```

  Un vrai keystore de release existe déjà (`android/keystore/kanu-release.jks`
  + `android/key.properties`, tous les deux **gitignorés** — jamais commités).
  `android/app/build.gradle.kts` l'utilise automatiquement s'il est présent,
  sinon retombe sur la clé debug (c'est ce qui permet à la CI, qui n'a pas ces
  secrets, de continuer à fonctionner). **Le keystore et ses mots de passe
  doivent être sauvegardés en lieu sûr en dehors de ce repo** (password
  manager, coffre chiffré) : sans eux, impossible de publier une mise à jour
  de l'app sous la même identité de signature Play Store. Si vous les perdez,
  générez-en un nouveau avec `keytool -genkeypair` et remplissez
  `key.properties` en conséquence.

- **iOS** : je n'ai pas de Mac dans cet environnement, donc je n'ai pas pu
  compiler ni tester l'app iOS moi-même. Le pipeline CI
  (`.github/workflows/flutter-build.yml`, job `ios`) compile la cible iOS
  en `--no-codesign` à chaque push pour valider que ça build, mais ça ne
  produit pas d'`.ipa` distribuable. Pour un vrai build iOS, il faut :
  1. Ouvrir `ios/Runner.xcworkspace` sur un Mac avec Xcode.
  2. Renseigner une équipe Apple Developer (Signing & Capabilities) et
     ajouter les capacités "Associated Domains" + "Push Notifications"
     (voir plus haut).
  3. `flutter build ios` puis archiver/exporter depuis Xcode, ou passer par
     Xcode Cloud / Codemagic / Fastlane si vous voulez l'automatiser sans
     Mac local.
