import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';

/// Fiche détaillée d'un profil membre.
class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  late Future<Member?> _future;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(memberRepositoryProvider).getById(widget.memberId);
  }

  Future<void> _requestConnection(Member target) async {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;
    setState(() => _requesting = true);
    try {
      await ref.read(compatibilityRepositoryProvider).requestConnection(
            self: self,
            target: target,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demande envoyée. Un conseiller KANU étudie votre mise en relation.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<Member?>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<Member?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Profil indisponible.',
              onRetry: () => setState(() {
                _future =
                    ref.read(memberRepositoryProvider).getById(widget.memberId);
              }),
            );
          }
          final Member? member = snapshot.data;
          if (member == null) {
            return const EmptyStateView(
              title: 'Profil introuvable',
              icon: Icons.person_off_outlined,
            );
          }
          return _content(context, member);
        },
      ),
    );
  }

  Widget _content(BuildContext context, Member member) {
    final bool isSelf =
        ref.read(authControllerProvider).member?.id == member.id;

    return ListView(
      children: [
        _hero(context, member),
        const SizedBox(height: 4),
        if (isSelf)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: KanuButton(
              label: 'Modifier mon profil',
              variant: KanuButtonVariant.outline,
              icon: Icons.edit_outlined,
              onPressed: () => context.push('/settings'),
            ),
          )
        else
          _actions(context, member),
        const SectionHeader(title: 'À propos', overline: 'Présentation'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            member.bio.isNotEmpty
                ? member.bio
                : 'Ce membre n’a pas encore renseigné de présentation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SectionHeader(title: 'Informations', overline: 'Détails'),
        _infoList(context, member),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _hero(BuildContext context, Member member) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.red.withValues(alpha: 0.12),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          MemberAvatar(member: member, size: 108, showPremiumRing: true),
          const SizedBox(height: 16),
          Text(
            member.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (member.age != null) '${member.age} ans',
              if (member.city.isNotEmpty) member.city,
              if (member.country.isNotEmpty) member.country,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (member.isPremium) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                '✦ MEMBRE PREMIUM',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, Member member) {
    final bool premium = ref.watch(authControllerProvider).isPremium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: KanuButton(
                  label: 'Écrire',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => context.push('/chat/${member.id}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KanuButton(
                  label: 'Mise en relation',
                  variant: KanuButtonVariant.silver,
                  loading: _requesting,
                  onPressed: () => _requestConnection(member),
                ),
              ),
            ],
          ),
          if (!premium) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.lock_outline_rounded, size: 16),
              label: const Text(
                'Certaines informations sont réservées aux membres Premium',
              ),
            ),
          ],
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => context.push('/report/${member.id}'),
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('Signaler ce profil'),
          ),
        ],
      ),
    );
  }

  Widget _infoList(BuildContext context, Member member) {
    final List<MapEntry<String, String>> rows = [
      MapEntry<String, String>('Genre', genderLabel(member.gender)),
      MapEntry<String, String>('Situation', member.familyStatus),
      MapEntry<String, String>(
        'Enfants',
        member.hasChildren
            ? '${member.childrenCount} enfant(s)'
            : 'Sans enfant',
      ),
      MapEntry<String, String>('Secteur', member.professionalField),
      MapEntry<String, String>('Statut pro.', member.employmentStatus),
      MapEntry<String, String>('Religion', member.religion),
    ].where((MapEntry<String, String> e) => e.value.trim().isNotEmpty).toList();

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Aucune information complémentaire.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: KanuCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: rows
              .map(
                (MapEntry<String, String> e) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
