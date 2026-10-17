import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/messages_controller.dart';

/// Onglet de messagerie : liste des conversations.
class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;
    await ref.read(messagesControllerProvider.notifier).loadConversations(self);
  }

  @override
  Widget build(BuildContext context) {
    final MessagesState provider = ref.watch(messagesControllerProvider);

    if (provider.loadingConversations && provider.conversations.isEmpty) {
      return const LoadingView(label: 'Chargement de vos messages…');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Messages',
              overline: 'Concordances acceptées',
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            ),
          ),
          if (provider.error != null && provider.conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: provider.error!,
                onRetry: _load,
              ),
            )
          else if (provider.conversations.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Aucune conversation',
                message: 'La messagerie s’ouvre après un accord mutuel. '
                    'Explorez vos compatibilités pour commencer.',
                icon: Icons.forum_outlined,
              ),
            )
          else
            SliverList.separated(
              itemCount: provider.conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) =>
                  _tile(context, provider.conversations[i]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Conversation c) {
    final Message? last = c.lastMessage;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () => context.push('/chat/${c.member.id}'),
      leading: MemberAvatar(member: c.member, size: 52),
      title: Text(
        c.member.fullName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          last?.content ?? 'Nouvelle conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.relative(last?.createdAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          if (c.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${c.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
