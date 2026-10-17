import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/pocketbase_client.dart';
import '../../models/compatibility.dart';
import '../../models/demande.dart';
import '../../models/member.dart';
import '../demo/demo_data.dart';

/// Accès aux compatibilités et aux demandes de mise en relation.
class CompatibilityRepository {
  CompatibilityRepository(this._client);

  final PocketBaseClient _client;

  /// Compatibilités d'un membre, score décroissant, score minimal 70.
  Future<List<Compatibility>> listFor(
    Member self, {
    int minimumScore = 70,
    int limit = 50,
  }) async {
    final String filter =
        '(membre_a = "${self.id}" || membre_b = "${self.id}") && '
        'score >= $minimumScore';
    try {
      final List<Map<String, dynamic>> raw = await _client.listRecords(
        AppConfig.compatibilitiesCollection,
        perPage: limit,
        filter: filter,
        sort: '-score',
        expand: 'membre_a,membre_b',
      );
      final List<Compatibility> items = raw
          .map((Map<String, dynamic> e) =>
              Compatibility.fromJson(e, selfId: self.id))
          .toList();
      return await _fillMissingProfiles(items, self.id);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return DemoData.compatibilitiesFor(self.id)
            .where((Compatibility c) => c.score >= minimumScore)
            .toList();
      }
      rethrow;
    }
  }

  Future<List<Demande>> listDemandes(Member self) async {
    try {
      final List<Map<String, dynamic>> raw = await _client.getFullList(
        AppConfig.demandesCollection,
        filter: 'demandeur_id = "${self.id}" || '
            'destinataire_id = "${self.id}"',
        sort: '-created',
      );
      return raw.map(Demande.fromJson).toList();
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) return const [];
      rethrow;
    }
  }

  Future<void> requestConnection({
    required Member self,
    required Member target,
    String message = '',
    String compatibilityId = '',
  }) async {
    try {
      await _client.createRecord(AppConfig.demandesCollection, {
        'demandeur_id': self.id,
        'destinataire_id': target.id,
        'message': message,
        'compatibilite_id': compatibilityId,
        'statut': 'en_attente',
      });
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) return;
      rethrow;
    }
  }

  /// Complète les profils manquants lorsque `expand` n'a pas été résolu.
  Future<List<Compatibility>> _fillMissingProfiles(
    List<Compatibility> items,
    String selfId,
  ) async {
    final List<Compatibility> result = [];
    for (final Compatibility c in items) {
      if (c.otherMember != null) {
        result.add(c);
        continue;
      }
      final String otherId = c.memberAId == selfId ? c.memberBId : c.memberAId;
      try {
        final Map<String, dynamic> json = await _client.getRecord(
          AppConfig.membersCollection,
          otherId,
        );
        result.add(c.copyWith(otherMember: Member.fromJson(json)));
      } on ApiException {
        result.add(c);
      }
    }
    return result;
  }
}
