import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app_kanu/app.dart';
import 'package:flutter_app_kanu/core/storage/preferences_service.dart';
import 'package:flutter_app_kanu/models/subscription_plan.dart';
import 'package:flutter_app_kanu/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KANU démarre sur l’écran de démarrage puis l’onboarding',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferencesService prefs = await PreferencesService.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
        ],
        child: const KanuApp(),
      ),
    );
    await tester.pump();

    // L'écran de démarrage affiche la marque et la baseline.
    expect(find.text('KANU'), findsOneWidget);
    expect(find.text('Rencontrer moins. Rencontrer mieux.'), findsOneWidget);

    // Laisse s'écouler le délai de démarrage, le bootstrap puis la redirection.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Premier lancement : on bascule sur l'onboarding.
    expect(find.text('Passer'), findsOneWidget);
  });

  test('La grille tarifaire correspond au site', () {
    expect(SubscriptionPlan.plans, hasLength(2));
    expect(SubscriptionPlan.plans.first.priceCents, 3990);
    expect(SubscriptionPlan.plans.first.priceLabel, '39,90 €');
    expect(SubscriptionPlan.plans.last.priceCents, 9790);
    expect(SubscriptionPlan.plans.last.priceLabel, '97,90 €');
    expect(SubscriptionPlan.plans.last.recommended, isTrue);
  });
}
