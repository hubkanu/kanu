import 'package:equatable/equatable.dart';

import 'member.dart';

/// Type de réponse attendue pour une question.
enum QuestionType { single, multi, text, yesNo }

/// Définition d'une question du questionnaire de compatibilité.
class Question extends Equatable {
  const Question({
    required this.key,
    required this.section,
    required this.label,
    this.type = QuestionType.single,
    this.options = const [],
    this.helper,
  });

  final String key;
  final String section;
  final String label;
  final QuestionType type;
  final List<QuestionOption> options;
  final String? helper;

  @override
  List<Object?> get props => [key, section, label, type];
}

class QuestionOption extends Equatable {
  const QuestionOption(this.value, this.label);

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

/// Réponses d'un membre au questionnaire (collection `kanu_questionnaires`).
class Questionnaire extends Equatable {
  const Questionnaire({
    this.id = '',
    this.memberId = '',
    this.answers = const {},
    this.completed = false,
    this.updatedAt,
  });

  final String id;
  final String memberId;
  final Map<String, dynamic> answers;
  final bool completed;
  final DateTime? updatedAt;

  Questionnaire copyWith({
    String? id,
    Map<String, dynamic>? answers,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return Questionnaire(
      id: id ?? this.id,
      memberId: memberId,
      answers: answers ?? this.answers,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Questionnaire.fromJson(
    Map<String, dynamic> json, {
    String memberId = '',
  }) {
    final Map<String, dynamic> answers = {};
    json.forEach((String key, dynamic value) {
      if (key == 'id' || key == 'membre_id' || key == 'created' ||
          key == 'updated' || key == 'collectionId' ||
          key == 'collectionName') {
        return;
      }
      answers[key] = value;
    });
    return Questionnaire(
      id: (json['id'] ?? '').toString(),
      memberId: memberId.isNotEmpty
          ? memberId
          : (json['membre_id'] ?? '').toString(),
      answers: answers,
      completed: answers.isNotEmpty,
      updatedAt: MemberDate.parse((json['updated'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, memberId, answers, completed];
}

/// Catalogue des questions KANU, regroupées par thématique.
///
/// Les clés correspondent exactement aux champs `qXX_*` de la collection
/// `kanu_questionnaires` côté PocketBase.
class QuestionnaireCatalog {
  const QuestionnaireCatalog._();

  static const List<Question> all = [
    // --- Projet de vie / intention
    Question(
      key: 'q01_intention',
      section: 'Votre projet',
      label: 'Que recherchez-vous sur KANU ?',
      options: [
        QuestionOption('relation_serieuse', 'Une relation sérieuse'),
        QuestionOption('mariage', 'Le mariage'),
        QuestionOption('vie_commune', 'Construire une vie commune'),
        QuestionOption('decouverte', 'Découvrir, sans précipitation'),
      ],
    ),
    Question(
      key: 'q02_delai_mariage',
      section: 'Votre projet',
      label: 'À quel horizon envisagez-vous un engagement ?',
      options: [
        QuestionOption('moins_6mois', 'Moins de 6 mois'),
        QuestionOption('6_12mois', '6 à 12 mois'),
        QuestionOption('1_2ans', '1 à 2 ans'),
        QuestionOption('2_3ans', '2 à 3 ans'),
        QuestionOption('plus_3ans', 'Plus de 3 ans'),
        QuestionOption('sans_delai', 'Aucun délai précis'),
        QuestionOption('pas_mariage', 'Je ne souhaite pas me marier'),
      ],
    ),
    Question(
      key: 'q03_construire',
      section: 'Votre projet',
      label: "Qu'est-ce qui compte le plus pour construire un couple ?",
      type: QuestionType.multi,
      options: [
        QuestionOption('confiance', 'La confiance'),
        QuestionOption('communication', 'La communication'),
        QuestionOption('respect', 'Le respect'),
        QuestionOption('tendresse', 'La tendresse'),
        QuestionOption('projets', 'Des projets communs'),
        QuestionOption('spiritualite', 'La spiritualité'),
      ],
    ),
    Question(
      key: 'q04_derniere_relation',
      section: 'Votre parcours',
      label: 'Votre dernière relation a duré…',
      options: [
        QuestionOption('moins_1an', 'Moins d’un an'),
        QuestionOption('1_3ans', '1 à 3 ans'),
        QuestionOption('3_10ans', '3 à 10 ans'),
        QuestionOption('plus_10ans', 'Plus de 10 ans'),
        QuestionOption('jamais', 'Jamais été en couple'),
      ],
    ),
    Question(
      key: 'q05_contact_ex',
      section: 'Votre parcours',
      label: 'Gardez-vous contact avec un ex partenaire ?',
      type: QuestionType.yesNo,
    ),
    Question(
      key: 'q06_comportements_amour',
      section: 'Votre parcours',
      label: 'Comment exprimez-vous votre amour ?',
      type: QuestionType.multi,
      options: [
        QuestionOption('paroles', 'Les mots'),
        QuestionOption('temps', 'Le temps passé ensemble'),
        QuestionOption('cadeaux', 'Les attentions'),
        QuestionOption('services', 'Les services rendus'),
        QuestionOption('toucher', 'La tendresse physique'),
      ],
    ),
    // --- Situation
    Question(
      key: 'q07_situation_pro',
      section: 'Votre situation',
      label: 'Votre situation professionnelle actuelle',
      options: [
        QuestionOption('salarie', 'Salarié(e)'),
        QuestionOption('independant', 'Indépendant(e)'),
        QuestionOption('entrepreneur', 'Entrepreneur / Dirigeant'),
        QuestionOption('recherche', 'En recherche'),
        QuestionOption('etudiant', 'En études'),
        QuestionOption('retraite', 'Retraité(e)'),
      ],
    ),
    Question(
      key: 'q10_logement',
      section: 'Votre situation',
      label: 'Vivez-vous…',
      options: [
        QuestionOption('seul', 'Seul(e)'),
        QuestionOption('colocation', 'En colocation'),
        QuestionOption('famille', 'Chez vos proches'),
        QuestionOption('avec_enfant', 'Avec vos enfants'),
      ],
    ),
    Question(
      key: 'q12_mobilite',
      section: 'Votre situation',
      label: 'Êtes-vous prêt(e) à déménager pour votre relation ?',
      type: QuestionType.yesNo,
    ),
    // --- Enfants
    Question(
      key: 'q13_enfants',
      section: 'Famille & enfants',
      label: 'Avez-vous des enfants ?',
      type: QuestionType.yesNo,
    ),
    Question(
      key: 'q15_vouloir_enfants',
      section: 'Famille & enfants',
      label: 'Souhaitez-vous avoir des enfants ?',
      options: [
        QuestionOption('oui', 'Oui'),
        QuestionOption('non', 'Non'),
        QuestionOption('plus_tard', 'Peut-être plus tard'),
        QuestionOption('pas_sur', 'Je ne sais pas encore'),
      ],
    ),
    Question(
      key: 'q16_accepter_enfants_partenaire',
      section: 'Famille & enfants',
      label: 'Accepteriez-vous les enfants de votre partenaire ?',
      type: QuestionType.yesNo,
    ),
    Question(
      key: 'q17_type_famille',
      section: 'Famille & enfants',
      label: 'Quel type de famille souhaitez-vous construire ?',
      options: [
        QuestionOption('traditionnelle', 'Traditionnelle'),
        QuestionOption('recomposee', 'Recomposée'),
        QuestionOption('monoparentale', 'Monoparentale'),
      ],
    ),
    // --- Spiritualité & valeurs
    Question(
      key: 'q24_religion',
      section: 'Spiritualité & valeurs',
      label: 'Quelle est votre rapport à la religion ?',
      options: [
        QuestionOption('pratiquant', 'Pratiquant(e)'),
        QuestionOption('croyant', 'Croyant(e) non pratiquant(e)'),
        QuestionOption('spirituel', 'Spirituel(le) sans religion'),
        QuestionOption('athée', 'Athée'),
      ],
    ),
    Question(
      key: 'q26_place_religion',
      section: 'Spiritualité & valeurs',
      label: 'Quelle place la religion doit-elle occuper dans votre couple ?',
      options: [
        QuestionOption('centrale', 'Centrale'),
        QuestionOption('importante', 'Importante'),
        QuestionOption('secondaire', 'Secondaire'),
        QuestionOption('aucune', 'Aucune'),
      ],
    ),
    Question(
      key: 'q40_cinq_piliers',
      section: 'Spiritualité & valeurs',
      label: 'Vos cinq valeurs essentielles',
      type: QuestionType.multi,
      options: [
        QuestionOption('famille', 'La famille'),
        QuestionOption('honnetete', 'L’honnêteté'),
        QuestionOption('fidelite', 'La fidélité'),
        QuestionOption('franchise', 'La franchise'),
        QuestionOption('generosite', 'La générosité'),
        QuestionOption('ambition', 'L’ambition'),
        QuestionOption('serenite', 'La sérénité'),
      ],
    ),
    // --- Organisation du foyer
    Question(
      key: 'q27_organisation_financiere',
      section: 'Organisation du foyer',
      label: 'Comment envisagez-vous l’organisation financière du couple ?',
      options: [
        QuestionOption('communs', 'Comptes communs'),
        QuestionOption('separes', 'Comptes séparés'),
        QuestionOption('mixte', 'Un peu des deux'),
      ],
    ),
    Question(
      key: 'q28_organisation_maison',
      section: 'Organisation du foyer',
      label: 'Comment répartir les tâches du foyer ?',
      options: [
        QuestionOption('equitable', 'De façon équitable'),
        QuestionOption('traditionnelle', 'Selon les rôles traditionnels'),
        QuestionOption('flexible', 'Au cas par cas'),
      ],
    ),
    // --- Vie affective & intimité
    Question(
      key: 'q41_importance_sexualite',
      section: 'Intimité & affectivité',
      label: 'Quelle place donnez-vous à la sexualité dans le couple ?',
      options: [
        QuestionOption('essentielle', 'Essentielle'),
        QuestionOption('importante', 'Importante'),
        QuestionOption('secondaire', 'Secondaire'),
      ],
    ),
    Question(
      key: 'q46_gestes_affectueux',
      section: 'Intimité & affectivité',
      label: 'Quels gestes d’affection vous touchent le plus ?',
      type: QuestionType.multi,
      options: [
        QuestionOption('cadeaux', 'Les attentions'),
        QuestionOption('tendresse', 'La tendresse'),
        QuestionOption('qualite_temps', 'Le temps de qualité'),
        QuestionOption('encouragements', 'Les encouragements'),
      ],
    ),
    Question(
      key: 'q49_parler_sexualite',
      section: 'Intimité & affectivité',
      label: 'Est-il facile pour vous de parler d’intimité ?',
      type: QuestionType.yesNo,
    ),
    Question(
      key: 'q55_consentement',
      section: 'Intimité & affectivité',
      label: 'Le consentement mutuel est-il primordial à vos yeux ?',
      type: QuestionType.yesNo,
    ),
    // --- Gestion des conflits
    Question(
      key: 'q35_comportements_incompatibles',
      section: 'Gestion des conflits',
      label: 'Quels comportements êtes-vous incapable d’accepter ?',
      type: QuestionType.multi,
      options: [
        QuestionOption('mensonge', 'Le mensonge'),
        QuestionOption('violence', 'La violence'),
        QuestionOption('infidelite', 'L’infidélité'),
        QuestionOption('irrespect', 'L’irrespect'),
        QuestionOption('controle', 'Le contrôle'),
      ],
    ),
    Question(
      key: 'q36_colere',
      section: 'Gestion des conflits',
      label: 'Comment gérez-vous la colère ?',
      options: [
        QuestionOption('calme', 'Je me calme puis je parle'),
        QuestionOption('immediat', 'J’en parle tout de suite'),
        QuestionOption('recul', 'J’ai besoin de recul'),
      ],
    ),
    Question(
      key: 'q37_apres_conflit',
      section: 'Gestion des conflits',
      label: 'Après un conflit, vous avez besoin…',
      options: [
        QuestionOption('temps', 'De temps'),
        QuestionOption('explications', 'D’explications'),
        QuestionOption('reconciliation', 'D’une réconciliation rapide'),
      ],
    ),
  ];

  /// Regroupe les questions par section, dans l'ordre du catalogue.
  static Map<String, List<Question>> get bySection {
    final Map<String, List<Question>> result = {};
    for (final Question q in all) {
      result.putIfAbsent(q.section, () => []).add(q);
    }
    return result;
  }

  static int get total => all.length;
}
