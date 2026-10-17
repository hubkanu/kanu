import '../../models/compatibility.dart';
import '../../models/member.dart';
import '../../models/message.dart';

/// Jeu de données de démonstration.
///
/// Utilisé uniquement lorsque l'API KANU est injoignable et que
/// `AppConfig.allowDemoFallback` est vrai (tests, développement, première
/// ouverture hors-ligne). Cela permet à l'application de rester exploreable
/// sans backend.
class DemoData {
  const DemoData._();

  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));

  static DateTime _yearsAgo(int years) =>
      DateTime(DateTime.now().year - years, 6, 15);

  static const String demoMemberId = 'demo_self';

  static Member get currentMember => Member(
        id: demoMemberId,
        email: 'vous@exemple.fr',
        username: 'camille_demo',
        firstName: 'Camille',
        lastName: 'Moreau',
        birthDate: _yearsAgo(36),
        phone: '+33 6 00 00 00 00',
        country: 'France',
        city: 'Lyon',
        gender: Gender.femme,
        familyStatus: 'Célibataire',
        hasChildren: false,
        professionalField: 'Santé',
        employmentStatus: 'Salariée',
        religion: 'Croyante non pratiquante',
        bio: "Amoureuse des choses vraies et des projets qui durent. "
            "J'aime les longues conversations et les dimanches tranquilles.",
        subscription: SubscriptionStatus.gratuit,
        questionnaireCompleted: false,
        profileScore: 68,
      );

  static final List<Member> profiles = [
    Member(
      id: 'demo_p1',
      email: 'thomas@exemple.fr',
      username: 'thomas_r',
      firstName: 'Thomas',
      lastName: 'Renard',
      birthDate: _yearsAgo(39),
      country: 'France',
      city: 'Lyon',
      gender: Gender.homme,
      familyStatus: 'Divorcé',
      hasChildren: true,
      childrenCount: 1,
      professionalField: 'Ingénierie',
      employmentStatus: 'Salarié',
      religion: 'Croyant non pratiquant',
      bio: "Papa attentionné, je cherche une relation sincère et durable.",
      subscription: SubscriptionStatus.actif,
      questionnaireCompleted: true,
      profileScore: 88,
    ),
    Member(
      id: 'demo_p2',
      email: 'julien@exemple.fr',
      username: 'julien_k',
      firstName: 'Julien',
      lastName: 'Kessler',
      birthDate: _yearsAgo(42),
      country: 'France',
      city: 'Paris',
      gender: Gender.homme,
      familyStatus: 'Célibataire',
      hasChildren: false,
      professionalField: 'Finance',
      employmentStatus: 'Indépendant',
      religion: 'Athée',
      bio: "J'aime voyager, cuisiner et les échanges profonds.",
      subscription: SubscriptionStatus.actif,
      questionnaireCompleted: true,
      profileScore: 76,
    ),
    Member(
      id: 'demo_p3',
      email: 'amine@exemple.fr',
      username: 'amine_b',
      firstName: 'Amine',
      lastName: 'Benali',
      birthDate: _yearsAgo(35),
      country: 'France',
      city: 'Marseille',
      gender: Gender.homme,
      familyStatus: 'Célibataire',
      hasChildren: false,
      professionalField: 'Éducation',
      employmentStatus: 'Salarié',
      religion: 'Pratiquant',
      bio: "La famille et le respect sont au centre de ma vie.",
      subscription: SubscriptionStatus.gratuit,
      questionnaireCompleted: true,
      profileScore: 82,
    ),
    Member(
      id: 'demo_p4',
      email: 'lucas@exemple.fr',
      username: 'lucas_m',
      firstName: 'Lucas',
      lastName: 'Mercier',
      birthDate: _yearsAgo(45),
      country: 'Belgique',
      city: 'Bruxelles',
      gender: Gender.homme,
      familyStatus: 'Veuf',
      hasChildren: true,
      childrenCount: 2,
      professionalField: 'Architecture',
      employmentStatus: 'Entrepreneur',
      religion: 'Croyant non pratiquant',
      bio: "Reconstruire à deux, avec douceur et patience.",
      subscription: SubscriptionStatus.actif,
      questionnaireCompleted: true,
      profileScore: 71,
    ),
    Member(
      id: 'demo_p5',
      email: 'mehdi@exemple.fr',
      username: 'mehdi_s',
      firstName: 'Mehdi',
      lastName: 'Saidi',
      birthDate: _yearsAgo(33),
      country: 'France',
      city: 'Lille',
      gender: Gender.homme,
      familyStatus: 'Célibataire',
      hasChildren: false,
      professionalField: 'Développement',
      employmentStatus: 'Salarié',
      religion: 'Croyant non pratiquant',
      bio: "Discret, fidèle, j'aime la simplicité.",
      subscription: SubscriptionStatus.gratuit,
      questionnaireCompleted: true,
      profileScore: 79,
    ),
    Member(
      id: 'demo_p6',
      email: 'paul@exemple.fr',
      username: 'paul_d',
      firstName: 'Paul',
      lastName: 'Dubois',
      birthDate: _yearsAgo(48),
      country: 'France',
      city: 'Bordeaux',
      gender: Gender.homme,
      familyStatus: 'Divorcé',
      hasChildren: true,
      childrenCount: 3,
      professionalField: 'Commerce',
      employmentStatus: 'Indépendant',
      religion: 'Athée',
      bio: "La maturité m'a appris la valeur des choses simples.",
      subscription: SubscriptionStatus.actif,
      questionnaireCompleted: true,
      profileScore: 73,
    ),
  ];

  static List<Compatibility> compatibilitiesFor(String selfId) {
    const List<int> scores = [94, 87, 82, 76, 71, 58];
    return List<Compatibility>.generate(profiles.length, (int i) {
      return Compatibility(
        id: 'demo_c$i',
        memberAId: selfId,
        memberBId: profiles[i].id,
        score: scores[i],
        status: i == 0 ? CompatibilityStatus.nouvelle : CompatibilityStatus.vue,
        otherMember: profiles[i],
        createdAt: _daysAgo(i * 2 + 1),
      );
    });
  }

  static List<Conversation> conversationsFor(String selfId) {
    final Member a = profiles[0];
    final Member b = profiles[1];
    return [
      Conversation(
        member: a,
        unreadCount: 2,
        compatibilityId: 'demo_c0',
        score: 94,
        lastMessage: Message(
          id: 'demo_m_last_0',
          senderId: a.id,
          recipientId: selfId,
          content: 'Bonjour Camille, votre profil m’a beaucoup touché.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ),
      Conversation(
        member: b,
        unreadCount: 0,
        compatibilityId: 'demo_c1',
        score: 87,
        lastMessage: Message(
          id: 'demo_m_last_1',
          senderId: selfId,
          recipientId: b.id,
          content: 'Avec plaisir pour échanger davantage 🙂',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
    ];
  }

  static List<Message> messagesBetween(String selfId, String otherId) {
    final Member other = profiles.firstWhere(
      (Member m) => m.id == otherId,
      orElse: () => profiles.first,
    );
    return [
      Message(
        id: 'demo_m1',
        senderId: other.id,
        recipientId: selfId,
        content: 'Bonjour ${_firstName(selfId)}, ravie de vous découvrir ici.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Message(
        id: 'demo_m2',
        senderId: selfId,
        recipientId: other.id,
        content: 'Bonjour, merci pour votre message. Qu’est-ce qui vous a '
            'plu dans mon profil ?',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 20)),
      ),
      Message(
        id: 'demo_m3',
        senderId: other.id,
        recipientId: selfId,
        content: 'Votre sincérité et le calme qui se dégage de vos réponses.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  static String _firstName(String id) => 'Camille';
}
