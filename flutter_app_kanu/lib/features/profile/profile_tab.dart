import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/messages_controller.dart';

/// Onglet « Profil » : espace personnel du membre.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Member? self = ref.watch(authControllerProvider).member;
    if (self == null) {
      return const EmptyStateView(
        title: 'Profil indisponible',
        icon: Icons.person_off_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _header(context, self),
        _stats(context, ref, self),
        const SizedBox(height: 8),
        _menu(context, self),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: KanuButton(
            label: 'Se déconnecter',
            variant: KanuButtonVariant.outline,
            icon: Icons.logout_rounded,
            onPressed: () => _logout(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, Member self) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          MemberAvatar(member: self, size: 76, showPremiumRing: false),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(self.fullName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  [
                    if (self.age != null) '${self.age} ans',
                    if (self.city.isNotEmpty) self.city,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _statusChip(context, self),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, Member self) {
    final bool premium = self.isPremium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (premium ? AppColors.gold : AppColors.muted)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (premium ? AppColors.gold : AppColors.muted)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        premium
            ? 'Premium · jusqu’au ${Formatters.shortDate(self.subscriptionEnd)}'
            : subscriptionLabel(self.subscription),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: premium ? AppColors.gold : AppColors.silver,
            ),
      ),
    );
  }

  Widget _stats(BuildContext context, WidgetRef ref, Member self) {
    final int unread = ref.watch(
      messagesControllerProvider.select((MessagesState s) => s.unreadCount),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              context,
              icon: Icons.assignment_turned_in_outlined,
              label: 'Questionnaire',
              value: self.questionnaireCompleted ? 'Complet' : 'À faire',
              color: self.questionnaireCompleted
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              context,
              icon: Icons.favorite_outline_rounded,
              label: 'Messages non lus',
              value: '$unread',
              color: AppColors.rose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return KanuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, Member self) {
    final List<_MenuItem> items = [
      const _MenuItem(
        icon: Icons.edit_outlined,
        label: 'Modifier mon profil',
        route: '/settings',
      ),
      const _MenuItem(
        icon: Icons.assignment_outlined,
        label: 'Mon questionnaire de compatibilité',
        route: '/questionnaire',
      ),
      _MenuItem(
        icon: Icons.workspace_premium_outlined,
        label: self.isPremium
            ? 'Gérer mon abonnement'
            : 'Passer à KANU Premium',
        route: '/premium',
      ),
      const _MenuItem(
        icon: Icons.groups_outlined,
        label: 'La communauté KANU',
        route: '/community',
      ),
      const _MenuItem(
        icon: Icons.dark_mode_outlined,
        label: 'Apparence et paramètres',
        route: '/settings',
      ),
      const _MenuItem(
        icon: Icons.help_outline_rounded,
        label: 'Le concept & l’aide',
        route: '/concept',
      ),
      const _MenuItem(
        icon: Icons.gavel_outlined,
        label: 'Mentions légales & CGU',
        route: '/legal/mentions-legales',
      ),
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Divider(),
        ),
        ...items.map(
          (_MenuItem item) => ListTile(
            leading: Icon(item.icon, color: AppColors.silver),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.muted),
            onTap: () => context.push(item.route),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre espace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}
