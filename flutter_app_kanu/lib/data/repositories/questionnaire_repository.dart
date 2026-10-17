import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/pocketbase_client.dart';
import '../../models/member.dart';
import '../../models/questionnaire.dart';

/// Accès au questionnaire de compatibilité (`kanu_questionnaires`).
class QuestionnaireRepository {
  QuestionnaireRepository(this._client);

  final PocketBaseClient _client;

  Future<Questionnaire?> loadFor(String memberId) async {
    try {
      final List<Map<String, dynamic>> items = await _client.getFullList(
        AppConfig.questionnairesCollection,
        filter: 'membre_id = "$memberId"',
      );
      if (items.isEmpty) return null;
      return Questionnaire.fromJson(items.first, memberId: memberId);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) return null;
      rethrow;
    }
  }

  /// Enregistre (crée ou met à jour) les réponses du membre.
  Future<void> save(Member self, Map<String, dynamic> answers) async {
    final Map<String, dynamic> body = {'membre_id': self.id};
    answers.forEach((String key, dynamic value) {
      body[key] = value is List ? jsonEncode(value) : value;
    });

    try {
      final List<Map<String, dynamic>> existing = await _client.getFullList(
        AppConfig.questionnairesCollection,
        filter: 'membre_id = "${self.id}"',
      );
      if (existing.isNotEmpty) {
        await _client.updateRecord(
          AppConfig.questionnairesCollection,
          (existing.first['id'] ?? '').toString(),
          body,
        );
      } else {
        await _client.createRecord(
          AppConfig.questionnairesCollection,
          body,
        );
      }
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) return;
      rethrow;
    }
  }
}
