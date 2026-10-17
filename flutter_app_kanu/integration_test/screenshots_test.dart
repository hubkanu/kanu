import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app_kanu/app.dart';
import 'package:flutter_app_kanu/core/network/pocketbase_client.dart';
import 'package:flutter_app_kanu/core/router/app_router.dart';
import 'package:flutter_app_kanu/core/storage/preferences_service.dart';
import 'package:flutter_app_kanu/data/demo/demo_data.dart';
import 'package:flutter_app_kanu/state/providers.dart';

/// Génère les captures d'écran App Store (iPhone + iPad) de KANU.
///
/// L'application est lancée hors-ligne : le backend PocketBase est remplacé
/// par un client pointant vers une URL injoignable, ce qui déclenche le repli
/// sur les données de démonstration (`AppConfig.allowDemoFallback`). Les écrans
/// connectés sont obtenus en pré-injectant une session de démonstration dans
/// `SharedPreferences`, puis en naviguant via le routeur.
///
/// Les PNG sont écrits par le driver host (`test_driver/integration_test.dart`)
/// dans `screenshots/` — voir `.github/workflows/ios-screenshots.yml`.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture App Store screenshots', (WidgetTester tester) async {
    final PreferencesService prefs = await PreferencesService.create();

    // ---------------------------------------------------------------
    // Phase 1 — Écrans non connectés : onboarding + connexion.
    // ---------------------------------------------------------------
    await prefs.clearAuth();
    await prefs.setOnboardingDone(false);
    await _pumpApp(tester, prefs);

    await _waitFor(tester, find.text('Pas de swipe.\nPas de catalogue.'));
    await _shot(binding, tester, 'store_1_onboarding_rencontres');

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await _waitFor(
      tester,
      find.text('Un questionnaire,\npas un algorithme aveugle.'),
    );
    await _shot(binding, tester, 'store_2_onboarding_compatibilite');

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await _waitFor(
      tester,
      find.text('Chaque mise en relation\nest validée par un conseiller.'),
    );
    await _shot(binding, tester, 'store_3_onboarding_confiance');

    await tester.tap(find.text('J’ai déjà un compte'));
    await _waitFor(tester, find.text('Connexion'));
    await tester.pump(const Duration(milliseconds: 500));
    await _shot(binding, tester, 'store_4_connexion');

    // ---------------------------------------------------------------
    // Phase 2 — Écrans connectés (session démo).
    // ---------------------------------------------------------------
    await prefs.setToken('demo-token');
    await prefs.setCachedMember(DemoData.currentMember.toJson());
    await prefs.setOnboardingDone(true);
    await _pumpApp(tester, prefs);

    await _waitFor(tester, find.text('Vos compatibilités'));
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_5_accueil');

    await _go(tester, AppRouter.search);
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_6_recherche');

    await _go(tester, AppRouter.compatibility);
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_7_accords');

    await _go(tester, AppRouter.messages);
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_8_messages');

    await _go(tester, AppRouter.profile);
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_9_profil');

    await _go(tester, '/premium');
    await tester.pump(const Duration(seconds: 1));
    await _shot(binding, tester, 'store_10_premium');
  });
}

/// Monte l'application avec les dépendances d'infrastructure remplacées par des
/// versions de démonstration (backend injoignable, préférences partagées).
Future<void> _pumpApp(WidgetTester tester, PreferencesService prefs) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        pocketBaseClientProvider.overrideWithValue(
          PocketBaseClient(baseUrl: 'http://127.0.0.1:9'),
        ),
      ],
      child: const KanuApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Navigue vers [route] en pilotant le routeur GoRouter de l'application.
Future<void> _go(WidgetTester tester, String route) async {
  final ProviderContainer container =
      ProviderScope.containerOf(tester.element(find.byType(KanuApp)));
  container.read(routerProvider).go(route);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pompe jusqu'à ce que [finder] soit présent (le splash, la restauration de
/// session et le repli démo rendent l'arrivée des écrans asynchrone). Évite
/// `pumpAndSettle`, qui boucle sur les indicateurs de chargement.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutSeconds = 60,
}) async {
  final DateTime deadline =
      DateTime.now().add(Duration(seconds: timeoutSeconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('Timeout en attente de $finder');
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 400));
  await binding.takeScreenshot(name);
}
