import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/section_header.dart';

class _InfoItem {
  const _InfoItem(this.title, this.body, {this.icon});

  final String title;
  final String body;
  final IconData? icon;
}

class _InfoContent {
  const _InfoContent({
    required this.title,
    required this.overline,
    required this.intro,
    required this.items,
  });

  final String title;
  final String overline;
  final String intro;
  final List<_InfoItem> items;
}

/// Écran d'information : concept, fonctionnement, valeurs, sécurité, FAQ.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final _InfoContent content = _content[slug] ?? _content['concept']!;

    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.overline.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.red),
                ),
                const SizedBox(height: 8),
                Text(content.title,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(content.intro,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SectionHeader(title: 'En détail', overline: 'KANU'),
          ...content.items.map(
            (_InfoItem item) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: KanuCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.icon != null)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red.withValues(alpha: 0.1),
                        ),
                        child: Icon(item.icon,
                            size: 18, color: AppColors.rose),
                      ),
                    if (item.icon != null) const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(item.body,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: KanuButton(
              label: 'Créer mon profil',
              onPressed: () => context.push('/register'),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, _InfoContent> _content = {
    'concept': _InfoContent(
      title: 'Notre concept',
      overline: 'Le concept',
      intro:
          'KANU est une plateforme de rencontres sérieuses pour femmes et '
          'hommes de 30 ans et plus, de toutes origines. Pas de swipe, pas de '
          'catalogue : seulement des compatibilités vraies.',
      items: [
        _InfoItem(
          '✕ Pas de swipe',
          'Aucun défilement de visages, aucune sélection fondée uniquement '
              'sur l’apparence.',
          icon: Icons.swipe_outlined,
        ),
        _InfoItem(
          '✓ Un questionnaire sérieux',
          'Vos réponses construisent un score de compatibilité fondé sur vos '
              'valeurs, vos projets et votre vision du couple.',
          icon: Icons.assignment_turned_in_outlined,
        ),
        _InfoItem(
          '✓ Une validation humaine',
          'Chaque mise en relation est étudiée par un conseiller KANU. '
              'L’humain prime sur l’algorithme.',
          icon: Icons.verified_user_outlined,
        ),
      ],
    ),
    'comment-ca-fonctionne': _InfoContent(
      title: 'Comment ça fonctionne',
      overline: 'La méthode',
      intro:
          'En quatre étapes, KANU vous accompagne d’une inscription sincère à '
          'une mise en relation validée.',
      items: [
        _InfoItem('01 · Inscription',
            'Créez votre profil et signez la charte de sincérité.'),
        _InfoItem('02 · Questionnaire',
            'Répondez au questionnaire de compatibilité en toute confidentialité.'),
        _InfoItem('03 · Sélection',
            'Nos conseillers étudient votre profil et calculent vos '
                'compatibilités.'),
        _InfoItem('04 · Mise en relation',
            'Après accord mutuel, la messagerie s’ouvre et vous échangez '
                'librement.'),
      ],
    ),
    'valeurs': _InfoContent(
      title: 'Nos valeurs',
      overline: 'Nos engagements',
      intro: 'Six principes guident chaque décision au sein de KANU.',
      items: [
        _InfoItem('Sincérité',
            'Chaque information fournie doit être exacte et chaque intention '
                'honnête.'),
        _InfoItem('Respect',
            'Tout comportement irrespectueux entraîne la suspension du compte.'),
        _InfoItem('Discrétion',
            'Vos photos et données sensibles restent protégées.'),
        _InfoItem('Bienveillance',
            'Nos conseillers accompagnent chaque membre avec attention.'),
        _InfoItem('Engagement',
            'KANU s’adresse aux personnes prêtes à construire durablement.'),
        _InfoItem('Fidélité',
            'La relation exclusive et la loyauté sont au cœur de notre vision.'),
      ],
    ),
    'securite': _InfoContent(
      title: 'Sécurité',
      overline: 'Confiance',
      intro:
          'La sécurité et la confidentialité de nos membres sont notre priorité '
          'absolue.',
      items: [
        _InfoItem('Validation des profils',
            'Chaque inscription peut faire l’objet d’une vérification humaine.'),
        _InfoItem('Signalement simplifié',
            'Signalez un profil ou un comportement en un geste depuis '
                'l’application.'),
        _InfoItem('Données protégées',
            'Aucune revente de données, aucune publicité ciblée.'),
        _InfoItem('Accompagnement',
            'Une équipe disponible pour toute question de sécurité.'),
      ],
    ),
    'faq': _InfoContent(
      title: 'Questions fréquentes',
      overline: 'FAQ',
      intro: 'Les réponses aux questions les plus posées par nos membres.',
      items: [
        _InfoItem('KANU est-il gratuit ?',
            'La création de profil et le questionnaire sont gratuits. '
                'L’abonnement Premium ouvre les profils complets et la '
                'messagerie.'),
        _InfoItem('Puis-je choisir qui je contacte ?',
            'Vous explorez des compatibilités suggérées. La mise en relation '
                's’ouvre après accord mutuel.'),
        _InfoItem('Mes photos sont-elles visibles par tous ?',
            'Non. Les photos ne sont accessibles que dans un cadre sécurisé '
                'et consenti.'),
        _InfoItem('Comment résilier mon abonnement ?',
            'À tout moment, depuis la page Premium de l’application, sans '
                'engagement.'),
      ],
    ),
  };
}
