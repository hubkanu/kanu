import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/section_header.dart';

class _KanuEvent {
  const _KanuEvent(this.title, this.date, this.city, this.description);

  final String title;
  final String date;
  final String city;
  final String description;
}

/// Espace communautaire : « Les Mots de KANU » et rencontres.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const List<String> _words = [
    "L'amour peut arriver après les tempêtes. Parfois, il fallait simplement "
        'traverser hier pour être prêt à reconnaître demain.',
    "Ne laisse pas une personne qui t'a mal aimé te convaincre que tu es "
        'difficile à aimer.',
    'Il existe quelque part une personne qui ne connaît pas encore ton rire, '
        'tes habitudes, tes silences… et qui les aimera.',
    'Rencontrer moins. Rencontrer mieux.',
  ];

  static const List<_KanuEvent> _events = [
    _KanuEvent(
      'Café KANU — Lyon',
      'Samedi 14 février · 15h00',
      'Lyon',
      'Rencontre conviviale entre membres validés, animée par une conseillère.',
    ),
    _KanuEvent(
      'Atelier « Parler d’engagement »',
      'Jeudi 26 février · 19h00',
      'En ligne',
      'Webinaire sur la communication au sein du couple, ouvert à tous.',
    ),
    _KanuEvent(
      'Dîner KANU — Paris',
      'Vendredi 13 mars · 20h00',
      'Paris',
      'Dîner en petit comité, sur inscription et après validation.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('La communauté')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SectionHeader(
            title: 'Les Mots de KANU',
            overline: 'Communauté',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Une pensée à partager, chaque semaine, pour cultiver la '
              'patience et la sincérité.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          ..._words.map(
            (String word) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: KanuCard(
                borderColor: AppColors.gold.withValues(alpha: 0.25),
                child: Text(
                  '« $word »',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                ),
              ),
            ),
          ),
          const SectionHeader(
            title: 'Prochains événements',
            overline: 'Rencontres',
          ),
          ..._events.map(
            (_KanuEvent e) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: KanuCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.red.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.event_outlined,
                          color: AppColors.rose),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${e.date} · ${e.city}',
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 6),
                          Text(e.description,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
