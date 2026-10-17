import 'package:equatable/equatable.dart';

import 'member.dart';

/// Message privé (collection `kanu_messages`).
class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.compatibilityId = '',
    this.isRead = false,
    this.createdAt,
    this.isPending = false,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String compatibilityId;
  final bool isRead;
  final DateTime? createdAt;

  /// Message optimiste pas encore confirmé par le serveur.
  final bool isPending;

  bool isMine(String myId) => senderId == myId;

  Message copyWith({bool? isRead, bool? isPending, String? id}) {
    return Message(
      id: id ?? this.id,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      compatibilityId: compatibilityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isPending: isPending ?? this.isPending,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] ?? '').toString(),
      senderId: (json['expediteur'] ?? '').toString(),
      recipientId: (json['destinataire'] ?? '').toString(),
      content: (json['contenu'] ?? '').toString(),
      compatibilityId: (json['compatibilite_id'] ?? '').toString(),
      isRead: json['lu'] == true,
      createdAt: MemberDate.parse((json['created'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, senderId, recipientId, content, isRead];
}

/// Résumé d'une conversation affichée dans la liste de messagerie.
class Conversation extends Equatable {
  const Conversation({
    required this.member,
    this.lastMessage,
    this.unreadCount = 0,
    this.compatibilityId = '',
    this.score,
  });

  final Member member;
  final Message? lastMessage;
  final int unreadCount;
  final String compatibilityId;

  /// Score de compatibilité éventuel pour contextualiser la discussion.
  final int? score;

  Conversation copyWith({
    Message? lastMessage,
    int? unreadCount,
    int? score,
  }) {
    return Conversation(
      member: member,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      compatibilityId: compatibilityId,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props =>
      [member.id, lastMessage?.id, unreadCount, score];
}
