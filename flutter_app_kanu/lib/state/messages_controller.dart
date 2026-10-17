import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/message_repository.dart';
import '../models/member.dart';
import '../models/message.dart';
import 'providers.dart';

/// État de la messagerie (liste des conversations + fils courants).
class MessagesState {
  const MessagesState({
    this.conversations = const [],
    this.threads = const {},
    this.loadingConversations = false,
    this.loadingThread = false,
    this.sending = false,
    this.error,
  });

  final List<Conversation> conversations;
  final Map<String, List<Message>> threads;
  final bool loadingConversations;
  final bool loadingThread;
  final bool sending;
  final String? error;

  int get unreadCount =>
      conversations.fold(0, (int sum, Conversation c) => sum + c.unreadCount);

  List<Message> thread(String otherId) => threads[otherId] ?? const [];

  MessagesState copyWith({
    List<Conversation>? conversations,
    Map<String, List<Message>>? threads,
    bool? loadingConversations,
    bool? loadingThread,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return MessagesState(
      conversations: conversations ?? this.conversations,
      threads: threads ?? this.threads,
      loadingConversations: loadingConversations ?? this.loadingConversations,
      loadingThread: loadingThread ?? this.loadingThread,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MessagesController extends Notifier<MessagesState> {
  @override
  MessagesState build() => const MessagesState();

  MessageRepository get _repository => ref.read(messageRepositoryProvider);

  Future<void> loadConversations(Member self) async {
    state = state.copyWith(loadingConversations: true, clearError: true);
    try {
      final List<Conversation> conversations =
          await _repository.listConversations(self);
      state = state.copyWith(
        conversations: conversations,
        loadingConversations: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, loadingConversations: false);
    }
  }

  Future<void> loadThread(Member self, String otherId) async {
    state = state.copyWith(loadingThread: true, clearError: true);
    try {
      final List<Message> messages =
          await _repository.getMessages(self, otherId);
      state = state.copyWith(
        threads: {...state.threads, otherId: messages},
        loadingThread: false,
        clearError: true,
      );
      unawaited(_repository.markRead(self, messages));
      _markConversationRead(otherId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, loadingThread: false);
    }
  }

  Future<bool> send(
    Member self,
    String otherId,
    String content, {
    String compatibilityId = '',
  }) async {
    if (content.trim().isEmpty) return false;
    state = state.copyWith(sending: true);

    final Message optimistic = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      senderId: self.id,
      recipientId: otherId,
      content: content.trim(),
      compatibilityId: compatibilityId,
      createdAt: DateTime.now(),
      isPending: true,
    );
    final List<Message> withOptimistic = [...state.thread(otherId), optimistic];
    state = state.copyWith(
      threads: {...state.threads, otherId: withOptimistic},
    );

    try {
      final Message sent = await _repository.send(
        self: self,
        recipientId: otherId,
        content: content.trim(),
        compatibilityId: compatibilityId,
      );
      final List<Message> updated = state
          .thread(otherId)
          .map((Message m) => m.id == optimistic.id ? sent : m)
          .toList();
      state = state.copyWith(
        threads: {...state.threads, otherId: updated},
        sending: false,
      );
      _updateConversationPreview(otherId, sent);
      return true;
    } on ApiException catch (e) {
      final List<Message> cleaned = state
          .thread(otherId)
          .where((Message m) => m.id != optimistic.id)
          .toList();
      state = state.copyWith(
        threads: {...state.threads, otherId: cleaned},
        error: e.message,
        sending: false,
      );
      return false;
    }
  }

  void _markConversationRead(String otherId) {
    final List<Conversation> updated = state.conversations.map((Conversation c) {
      if (c.member.id == otherId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);
  }

  void _updateConversationPreview(String otherId, Message message) {
    final List<Conversation> updated = state.conversations.map((Conversation c) {
      if (c.member.id == otherId) {
        return c.copyWith(lastMessage: message, unreadCount: 0);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);
  }
}

final messagesControllerProvider =
    NotifierProvider<MessagesController, MessagesState>(MessagesController.new);
