import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/compatibility.dart';
import '../../models/member.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';

/// Onglet d'accueil : synthèse de l'activité du membre.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late Future<List<Compatibility>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Compatibility>> _load() {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return Future<List<Compatibility>>.value(const []);
    return ref.read(compatibilityRepositoryProvider).listFor(self, limit: 6);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final Member? self = ref.watch(authControllerProvider).member;
    if (self == null) {
      return const LoadingView();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, self)),
          SliverToBoxAdapter(child: _premiumCard(context, self)),
          if (!self.questionnaireCompleted)
            SliverToBoxAdapter(child: _questionnairePrompt(context)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Vos compatibilités',
              overline: 'Sélection KANU',
              trailing: TextButton(
                onPressed: () => context.go('/compatibility'),
                child: const Text('Tout voir'),
              ),
            ),
          ),
          _compatibilitySliver(),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Actions rapides',
              overline: 'Navigation',
            ),
          ),
          SliverToBoxAdapter(child: _quickActions(context)),
          SliverToBoxAdapter(child: _communityTeaser(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Member self) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  self.firstName.isNotEmpty ? self.firstName : self.fullName,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
          ),
          const KanuLogo(size: 40, showWordmark: false),
        ],
      ),
    );
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bel après-midi';
    return 'Bonsoir';
  }

  Widget _premiumCard(BuildContext context, Member self) {
    final bool premium = self.isPremium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: KanuCard(
        highlight: !premium,
        onTap: () => context.push('/premium'),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    premium ? 'KANU Premium actif' : 'Passez à KANU Premium',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    premium
                        ? 'Jusqu’au ${Formatters.shortDate(self.subscriptionEnd)}'
                        : 'Profils complets, photos et messagerie',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _questionnairePrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: KanuCard(
        borderColor: AppColors.red.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    color: AppColors.rose, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Complétez votre questionnaire',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plus vos réponses sont précises, plus vos compatibilités '
              'seront justes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            KanuButton(
              label: 'Démarrer le questionnaire',
              height: 46,
              onPressed: () => context.push('/questionnaire'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compatibilitySliver() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 210,
        child: FutureBuilder<List<Compatibility>>(
          future: _future,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<Compatibility>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              final Object error = snapshot.error!;
              return ErrorView(
                message: error is ApiException
                    ? error.message
                    : 'Chargement impossible.',
                onRetry: _refresh,
              );
            }
            final List<Compatibility> items =
                snapshot.data ?? const <Compatibility>[];
            if (items.isEmpty) {
              return const EmptyStateView(
                title: 'Pas encore de compatibilité',
                message: 'Complétez votre questionnaire pour recevoir '
                    'vos premières sélections.',
                icon: Icons.favorite_border_rounded,
              );
            }
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int i) =>
                  _compatibilityCard(context, items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _compatibilityCard(BuildContext context, Compatibility item) {
    final Member? other = item.otherMember;
    return SizedBox(
      width: 160,
      child: KanuCard(
        padding: const EdgeInsets.all(16),
        onTap: other == null
            ? null
            : () => context.push('/membre/${other.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (other != null)
              MemberAvatar(member: other, size: 58)
            else
              const CircleAvatar(radius: 29),
            const SizedBox(height: 10),
            Text(
              other?.firstName ?? 'Membre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              other?.city.isNotEmpty == true ? other!.city : '—',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            ScoreRing(score: item.score, size: 46, showLabel: true),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    const List<_QuickAction> actions = [
      _QuickAction('Rechercher', Icons.search_rounded, '/search'),
      _QuickAction('Messagerie', Icons.forum_outlined, '/messages'),
      _QuickAction('Communauté', Icons.groups_outlined, '/community'),
      _QuickAction('Premium', Icons.workspace_premium_outlined, '/premium'),
      _QuickAction('Paramètres', Icons.settings_outlined, '/settings'),
      _QuickAction('Le concept', Icons.auto_stories_outlined, '/concept'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: actions
            .map((_QuickAction a) => _quickActionTile(context, a))
            .toList(),
      ),
    );
  }

  Widget _quickActionTile(BuildContext context, _QuickAction action) {
    return KanuCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(action.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: AppColors.rose, size: 26),
          const SizedBox(height: 10),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.silver,
                ),
          ),
        ],
      ),
    );
  }

  Widget _communityTeaser(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: KanuCard(
        onTap: () => context.push('/community'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LES MOTS DE KANU',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 10),
            Text(
              '« L’amour peut arriver après les tempêtes. Parfois, il fallait '
              'simplement traverser hier pour être prêt à reconnaître demain. »',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Rejoindre la communauté',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
