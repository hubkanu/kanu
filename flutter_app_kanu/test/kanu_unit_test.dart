import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_kanu/core/utils/formatters.dart';
import 'package:flutter_app_kanu/core/utils/validators.dart';
import 'package:flutter_app_kanu/models/member.dart';
import 'package:flutter_app_kanu/models/search_filters.dart';
import 'package:flutter_app_kanu/models/subscription_plan.dart';

Member _member({
  String id = 'm1',
  String firstName = 'Camille',
  String lastName = 'Moreau',
  DateTime? birthDate,
  SubscriptionStatus subscription = SubscriptionStatus.gratuit,
  DateTime? subscriptionEnd,
}) {
  return Member(
    id: id,
    email: 'camille@exemple.fr',
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    subscription: subscription,
    subscriptionEnd: subscriptionEnd,
  );
}

void main() {
  group('Member', () {
    test('fullName et initiales', () {
      final Member m = _member();
      expect(m.fullName, 'Camille Moreau');
      expect(m.initials, 'CM');
    });

    test('age est calculé à partir de la date de naissance', () {
      final DateTime now = DateTime.now();
      final Member m = _member(
        birthDate: DateTime(now.year - 40, now.month, now.day),
      );
      expect(m.age, 40);
    });

    test('isPremium est vrai si abonnement actif non expiré', () {
      final Member premium = _member(
        subscription: SubscriptionStatus.actif,
        subscriptionEnd: DateTime.now().add(const Duration(days: 30)),
      );
      final Member expired = _member(
        subscription: SubscriptionStatus.actif,
        subscriptionEnd: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(premium.isPremium, isTrue);
      expect(expired.isPremium, isFalse);
    });

    test('fromJson mappe les champs PocketBase', () {
      final Member m = Member.fromJson(<String, dynamic>{
        'id': 'abc',
        'email': 'test@kanu.fr',
        'prenom': 'Thomas',
        'nom': 'Renard',
        'ville': 'Lyon',
        'genre': 'homme',
        'abonnement_statut': 'actif',
        'questionnaire_complete': true,
      });
      expect(m.id, 'abc');
      expect(m.firstName, 'Thomas');
      expect(m.gender, Gender.homme);
      expect(m.subscription, SubscriptionStatus.actif);
      expect(m.questionnaireCompleted, isTrue);
    });
  });

  group('Validation', () {
    test('email', () {
      expect(Validators.email('contact@kanu-rencontres.com'), isNull);
      expect(Validators.email('pas-un-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('mot de passe', () {
      expect(Validators.password('Kanuren1'), isNull);
      expect(Validators.password('court1'), isNotNull);
      expect(Validators.password('sanschiffre'), isNotNull);
    });

    test('confirmation du mot de passe', () {
      expect(Validators.confirmPassword('Kanuren1', 'Kanuren1'), isNull);
      expect(Validators.confirmPassword('Kanuren2', 'Kanuren1'), isNotNull);
    });

    test('date de naissance (majorité)', () {
      final DateTime now = DateTime.now();
      expect(
        Validators.birthDate(DateTime(now.year - 35, now.month, now.day)),
        isNull,
      );
      expect(
        Validators.birthDate(DateTime(now.year - 15, now.month, now.day)),
        isNotNull,
      );
    });
  });

  group('Recherche et formatage', () {
    test('SearchFilters par défaut est vide', () {
      expect(const SearchFilters().isEmpty, isTrue);
      expect(const SearchFilters(city: 'Lyon').isEmpty, isFalse);
    });

    test('Formatters.relative et shortDate', () {
      expect(Formatters.shortDate(null), '—');
      final DateTime now = DateTime.now();
      expect(Formatters.shortDate(now), matches(r'^\d{2}/\d{2}/\d{4}$'));
      expect(
        Formatters.relative(now.subtract(const Duration(minutes: 5))),
        'il y a 5 min',
      );
    });

    test('SubscriptionPlan calcule le prix mensuel', () {
      final SubscriptionPlan tri = SubscriptionPlan.plans.last;
      expect(tri.monthlyPriceCents.round(), 3263);
    });
  });
}
