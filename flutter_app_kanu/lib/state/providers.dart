import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/pocketbase_client.dart';
import '../core/storage/preferences_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/compatibility_repository.dart';
import '../data/repositories/member_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/questionnaire_repository.dart';

/// Fournisseurs d'infrastructure (dépôts et services).
///
/// [preferencesServiceProvider] est remplacé au démarrage par une instance
/// concrète (`ProviderScope.overrides`), car [PreferencesService.create] est
/// asynchrone. Tous les autres fournisseurs en dérivent.

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError(
    'preferencesServiceProvider doit être remplacé dans ProviderScope.',
  );
});

final pocketBaseClientProvider = Provider<PocketBaseClient>((ref) {
  return PocketBaseClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(pocketBaseClientProvider),
    ref.watch(preferencesServiceProvider),
  );
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(pocketBaseClientProvider));
});

final compatibilityRepositoryProvider =
    Provider<CompatibilityRepository>((ref) {
  return CompatibilityRepository(ref.watch(pocketBaseClientProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(pocketBaseClientProvider));
});

final questionnaireRepositoryProvider =
    Provider<QuestionnaireRepository>((ref) {
  return QuestionnaireRepository(ref.watch(pocketBaseClientProvider));
});
