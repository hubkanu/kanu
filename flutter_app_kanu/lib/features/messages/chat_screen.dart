import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/messages_controller.dart';
import '../../state/providers.dart';

/// Fil de discussion privée avec un membre.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.otherId, this.compatibilityId = ''});

  final String otherId;
  final String compatibilityId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Member? _other;
  bool _loadingMember = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;

    final Member? other =
        await ref.read(memberRepositoryProvider).getById(widget.otherId);
    if (!mounted) return;
    setState(() {
      _other = other;
      _loadingMember = false;
    });

    await ref
        .read(messagesControllerProvider.notifier)
        .loadThread(self, widget.otherId);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;

    _controller.clear();
    final bool ok = await ref.read(messagesControllerProvider.notifier).send(
          self,
          widget.otherId,
          text,
          compatibilityId: widget.compatibilityId,
        );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’envoyer le message.')),
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final Member? self = ref.watch(authControllerProvider).member;
    final MessagesState provider = ref.watch(messagesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _header(),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'report') {
                context.push('/report/${widget.otherId}');
              } else if (value == 'profile') {
                context.push('/membre/${widget.otherId}');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text('Voir le profil'),
              ),
              PopupMenuItem<String>(
                value: 'report',
                child: Text('Signaler / bloquer'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingMember
                ? const LoadingView()
                : provider.loadingThread && provider.thread(widget.otherId).isEmpty
                    ? const LoadingView()
                    : _thread(self),
          ),
          _composer(provider.sending),
        ],
      ),
    );
  }

  Widget _header() {
    if (_other == null) return const Text('Conversation');
    return Row(
      children: [
        MemberAvatar(member: _other!, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _other!.firstName.isNotEmpty
                    ? _other!.firstName
                    : _other!.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _other!.isPremium ? 'Membre Premium' : 'Membre KANU',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thread(Member? self) {
    final List<Message> messages =
        ref.watch(messagesControllerProvider).thread(widget.otherId);
    if (messages.isEmpty) {
      return const EmptyStateView(
        title: 'Démarrez la conversation',
        message: 'Présentez-vous en quelques mots sincères.',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int i) {
        final Message m = messages[i];
        final bool mine = self != null && m.isMine(self.id);
        return _bubble(m, mine);
      },
    );
  }

  Widget _bubble(Message m, bool mine) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine
              ? scheme.primary.withValues(alpha: 0.9)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: Border.all(
            color: mine
                ? Colors.transparent
                : scheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              m.content,
              style: TextStyle(
                color: mine ? Colors.white : scheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.clock(m.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? Colors.white70
                        : AppColors.muted,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    m.isPending ? Icons.schedule_rounded : Icons.done_all_rounded,
                    size: 13,
                    color: m.isRead ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(bool sending) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : _send,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
