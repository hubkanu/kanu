import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/kanu_button.dart';

class _LegalDoc {
  const _LegalDoc({required this.title, required this.sections});

  final String title;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// Écran des documents légaux (mentions, CGU, CGV, confidentialité…).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final _LegalDoc doc = _documents[slug] ?? _documents['mentions-legales']!;

    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(doc.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Dernière mise à jour : janvier 2026',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 20),
          ...doc.sections.map((_LegalSection s) => _section(context, s)),
          const SizedBox(height: 12),
          KanuButton(
            label: 'Ouvrir la version web',
            variant: KanuButtonVariant.outline,
            icon: Icons.open_in_new_rounded,
            onPressed: () => launchUrl(
              Uri.parse('${AppConfig.websiteUrl}/$slug'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Éditeur : ${AppConfig.publisher}. '
            'Contact : ${AppConfig.supportEmail}.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, _LegalSection s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.heading,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.silver),
          ),
          const SizedBox(height: 8),
          Text(s.body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  static const Map<String, _LegalDoc> _documents = {
    'mentions-legales': _LegalDoc(
      title: 'Mentions légales',
      sections: [
        _LegalSection(
          'Éditeur du site',
          'KANU est portée par l’association Lova Film (SIREN 899 947 451), '
              'qui propose un service de mise en relation sélective basé sur un '
              'questionnaire de compatibilité, un calcul de score et une '
              'validation humaine par des conseillers.',
        ),
        _LegalSection(
          'Hébergement',
          'L’application et les données sont hébergées sur une infrastructure '
              'sécurisée située dans l’Union européenne.',
        ),
        _LegalSection(
          'Propriété intellectuelle',
          'L’ensemble des éléments de la marque KANU (nom, logo, chartes, '
              'questionnaires) est protégé. Toute reproduction sans autorisation '
              'est interdite.',
        ),
        _LegalSection(
          'Contact',
          'Pour toute question : ${AppConfig.supportEmail}.',
        ),
      ],
    ),
    'cgu': _LegalDoc(
      title: 'Conditions générales d’utilisation',
      sections: [
        _LegalSection(
          'Objet',
          'KANU met en relation des personnes majeures de 30 ans et plus '
              'recherchant une relation sérieuse. L’accès suppose l’acceptation '
              'pleine des présentes conditions.',
        ),
        _LegalSection(
          'Engagements du membre',
          'Le membre s’engage à fournir des informations exactes, à respecter '
              'les autres membres et à ne tenir aucun propos discriminatoire, '
              'violent ou contraire à la loi.',
        ),
        _LegalSection(
          'Validation et modération',
          'Chaque inscription peut faire l’objet d’une validation humaine. '
              'KANU peut suspendre ou supprimer tout compte ne respectant pas '
              'la charte de sincérité.',
        ),
        _LegalSection(
          'Résiliation',
          'Le membre peut supprimer son compte à tout moment depuis les '
              'paramètres de l’application.',
        ),
      ],
    ),
    'cgv': _LegalDoc(
      title: 'Conditions générales de vente',
      sections: [
        _LegalSection(
          'Abonnement',
          'L’abonnement KANU Essentiel est proposé à 39,90 € par mois ou '
              '97,90 € pour trois mois. Les prix sont indiqués toutes taxes '
              'comprises.',
        ),
        _LegalSection(
          'Paiement',
          'Le paiement est effectué de façon sécurisée via les stores '
              'd’applications ou notre prestataire de paiement.',
        ),
        _LegalSection(
          'Droit de rétractation',
          'Conformément à la réglementation, le membre dispose d’un délai de '
              'rétractation de 14 jours, sauf si le service a déjà été pleinement '
              'exécuté avec son accord.',
        ),
      ],
    ),
    'confidentialite': _LegalDoc(
      title: 'Politique de confidentialité',
      sections: [
        _LegalSection(
          'Données collectées',
          'KANU collecte les informations nécessaires à la mise en relation : '
              'identité, coordonnées, réponses au questionnaire et échanges '
              'internes.',
        ),
        _LegalSection(
          'Finalité',
          'Ces données servent uniquement à calculer des compatibilités, à '
              'sécuriser la communauté et à assurer le suivi par les conseillers.',
        ),
        _LegalSection(
          'Vos droits',
          'Vous disposez d’un droit d’accès, de rectification, d’effacement et '
              'de portabilité. Toute demande peut être adressée à '
              '${AppConfig.supportEmail}.',
        ),
        _LegalSection(
          'Aucune publicité',
          'KANU n’utilise aucun cookie publicitaire ni outil de reciblage tiers.',
        ),
      ],
    ),
    'cookies': _LegalDoc(
      title: 'Cookies',
      sections: [
        _LegalSection(
          'Cookies essentiels',
          'Ils assurent le fonctionnement de l’application (authentification, '
              'sécurité). Ils ne peuvent pas être désactivés.',
        ),
        _LegalSection(
          'Cookies de mesure',
          'Ils permettent de comprendre l’usage de l’application de façon '
              'anonyme. Votre consentement est recueilli au premier lancement.',
        ),
      ],
    ),
    'charte': _LegalDoc(
      title: 'Charte de sincérité',
      sections: [
        _LegalSection(
          'Sincérité',
          'Chaque information fournie doit être exacte. Chaque intention doit '
              'être honnête.',
        ),
        _LegalSection(
          'Respect',
          'Les membres se respectent mutuellement. Tout comportement '
              'irrespectueux entraîne la suspension du compte.',
        ),
        _LegalSection(
          'Discrétion',
          'Vos photos et données sensibles ne sont jamais rendues publiques '
              'sans votre consentement.',
        ),
        _LegalSection(
          'Engagement',
          'KANU s’adresse aux personnes réellement prêtes à construire une '
              'relation durable.',
        ),
      ],
    ),
    'protection-mineurs': _LegalDoc(
      title: 'Protection des mineurs',
      sections: [
        _LegalSection(
          'Accès réservé aux majeurs',
          'KANU est strictement réservé aux personnes majeures. Toute tentative '
              'd’inscription par un mineur est bloquée.',
        ),
        _LegalSection(
          'Signalement',
          'Tout contenu ou comportement mettant en danger un mineur est '
              'immédiatement signalé aux autorités compétentes.',
        ),
      ],
    ),
  };
}
