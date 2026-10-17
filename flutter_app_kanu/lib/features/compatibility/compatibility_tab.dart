import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/compatibility.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';

/// Onglet « Accords » : compatibilités validées par KANU.
class CompatibilityTab extends ConsumerStatefulWidget {
  const CompatibilityTab({super.key});

  @override
  ConsumerState<CompatibilityTab> createState() => _CompatibilityTabState();
}

class _CompatibilityTabState extends ConsumerState<CompatibilityTab> {
  late Future<List<Compatibility>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Compatibility>> _load() {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return Future<List<Compatibility>>.value(const []);
    return ref.read(compatibilityRepositoryProvider).listFor(self);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Compatibility>>(
      future: _future,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Compatibility>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(label: 'Recherche de vos accords…');
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
          return EmptyStateView(
            title: 'Aucun accord pour le moment',
            message: 'Complétez votre questionnaire : nos conseillers vous '
                'présenteront des profils réellement compatibles.',
            icon: Icons.favorite_border_rounded,
            action: KanuButton(
              label: 'Ouvrir le questionnaire',
              expand: false,
              onPressed: () => context.push('/questionnaire'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SectionHeader(
                title: 'Vos compatibilités',
                overline: 'Sélection humaine',
              ),
              ...items.map(
                (Compatibility c) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: _card(context, c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, Compatibility c) {
    final Member? other = c.otherMember;
    return KanuCard(
      onTap: other == null ? null : () => context.push('/membre/${other.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (other != null)
                MemberAvatar(member: other, size: 52)
              else
                const CircleAvatar(radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other?.fullName ?? 'Membre KANU',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (other?.age != null) '${other!.age} ans',
                        if (other?.city.isNotEmpty == true) other!.city,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ScoreRing(score: c.score, size: 54),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tag(
                context,
                c.scoreLabel,
                c.isHigh ? AppColors.gold : AppColors.rose,
              ),
              const Spacer(),
              Text(
                'Voir le profil',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.silver),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, letterSpacing: 0.8),
      ),
    );
  }
}
