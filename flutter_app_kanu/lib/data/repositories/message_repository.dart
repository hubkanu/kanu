import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/pocketbase_client.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../demo/demo_data.dart';

/// Accès à la messagerie privée (`kanu_messages`).
class MessageRepository {
  MessageRepository(this._client);

  final PocketBaseClient _client;

  /// Construit la liste des conversations à partir de l'ensemble des messages
  /// échangés par [self].
  Future<List<Conversation>> listConversations(Member self) async {
    try {
      final List<Map<String, dynamic>> raw = await _client.getFullList(
        AppConfig.messagesCollection,
        filter: 'expediteur = "${self.id}" || destinataire = "${self.id}"',
        sort: '-created',
      );
      final List<Message> messages = raw.map(Message.fromJson).toList();
      return await _group(messages, self);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return DemoData.conversationsFor(self.id);
      }
      rethrow;
    }
  }

  Future<List<Message>> getMessages(Member self, String otherId) async {
    try {
      final List<Map<String, dynamic>> raw = await _client.getFullList(
        AppConfig.messagesCollection,
        filter: '(expediteur = "${self.id}" && destinataire = "$otherId") '
            '|| (expediteur = "$otherId" && destinataire = "${self.id}")',
        sort: 'created',
      );
      return raw.map(Message.fromJson).toList();
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return DemoData.messagesBetween(self.id, otherId);
      }
      rethrow;
    }
  }

  Future<Message> send({
    required Member self,
    required String recipientId,
    required String content,
    String compatibilityId = '',
  }) async {
    try {
      final Map<String, dynamic> json = await _client.createRecord(
        AppConfig.messagesCollection,
        {
          'expediteur': self.id,
          'destinataire': recipientId,
          'compatibilite_id': compatibilityId,
          'contenu': content,
          'lu': false,
        },
      );
      return Message.fromJson(json);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return Message(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          senderId: self.id,
          recipientId: recipientId,
          content: content,
          compatibilityId: compatibilityId,
          createdAt: DateTime.now(),
          isPending: true,
        );
      }
      rethrow;
    }
  }

  Future<void> markRead(Member self, List<Message> messages) async {
    final Iterable<Message> unread = messages.where(
      (Message m) => m.recipientId == self.id && !m.isRead,
    );
    for (final Message m in unread) {
      try {
        await _client.updateRecord(
          AppConfig.messagesCollection,
          m.id,
          {'lu': true},
        );
      } on ApiException {
        // Silencieux : le marquage de lecture n'est pas critique.
      }
    }
  }

  Future<List<Conversation>> _group(
    List<Message> messages,
    Member self,
  ) async {
    final Map<String, List<Message>> byOther = {};
    for (final Message m in messages) {
      final String otherId =
          m.senderId == self.id ? m.recipientId : m.senderId;
      byOther.putIfAbsent(otherId, () => []).add(m);
    }

    final List<Conversation> result = [];
    for (final MapEntry<String, List<Message>> entry in byOther.entries) {
      final List<Message> list = entry.value
        ..sort((Message a, Message b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      final Member? member = await _member(entry.key);
      if (member == null) continue;
      final int unread = list
          .where((Message m) => m.recipientId == self.id && !m.isRead)
          .length;
      result.add(
        Conversation(
          member: member,
          lastMessage: list.isNotEmpty ? list.first : null,
          unreadCount: unread,
          compatibilityId:
              list.isNotEmpty ? list.first.compatibilityId : '',
        ),
      );
    }
    result.sort((Conversation a, Conversation b) {
      final DateTime da = a.lastMessage?.createdAt ?? DateTime(0);
      final DateTime db = b.lastMessage?.createdAt ?? DateTime(0);
      return db.compareTo(da);
    });
    return result;
  }

  Future<Member?> _member(String id) async {
    try {
      final Map<String, dynamic> json = await _client.getRecord(
        AppConfig.membersCollection,
        id,
      );
      return Member.fromJson(json);
    } on ApiException {
      final Iterable<Member> all = [
        DemoData.currentMember,
        ...DemoData.profiles,
      ];
      for (final Member m in all) {
        if (m.id == id) return m;
      }
      return null;
    }
  }
}
