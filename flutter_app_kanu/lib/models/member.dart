import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../core/config/app_config.dart';

enum Gender { homme, femme, autre, inconnu }

Gender genderFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'homme':
    case 'h':
      return Gender.homme;
    case 'femme':
    case 'f':
      return Gender.femme;
    case 'autre':
      return Gender.autre;
    default:
      return Gender.inconnu;
  }
}

String genderLabel(Gender g) {
  switch (g) {
    case Gender.homme:
      return 'Homme';
    case Gender.femme:
      return 'Femme';
    case Gender.autre:
      return 'Autre';
    case Gender.inconnu:
      return 'Non précisé';
  }
}

/// Statut d'abonnement d'un membre.
enum SubscriptionStatus { gratuit, enAttente, actif, expire, annule, inconnu }

SubscriptionStatus subscriptionFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'actif':
    case 'active':
      return SubscriptionStatus.actif;
    case 'en_attente':
    case 'pending':
      return SubscriptionStatus.enAttente;
    case 'expire':
    case 'expired':
      return SubscriptionStatus.expire;
    case 'annule':
    case 'cancelled':
      return SubscriptionStatus.annule;
    case 'gratuit':
    case 'free':
      return SubscriptionStatus.gratuit;
    default:
      return SubscriptionStatus.inconnu;
  }
}

String subscriptionLabel(SubscriptionStatus s) {
  switch (s) {
    case SubscriptionStatus.actif:
      return 'Premium actif';
    case SubscriptionStatus.enAttente:
      return 'En attente';
    case SubscriptionStatus.expire:
      return 'Expiré';
    case SubscriptionStatus.annule:
      return 'Annulé';
    case SubscriptionStatus.gratuit:
      return 'Gratuit';
    case SubscriptionStatus.inconnu:
      return 'Inconnu';
  }
}

/// Représente un membre KANU (collection `kanu_members`).
class Member extends Equatable {
  const Member({
    required this.id,
    required this.email,
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.phone = '',
    this.country = 'France',
    this.city = '',
    this.gender = Gender.inconnu,
    this.familyStatus = '',
    this.hasChildren = false,
    this.childrenCount = 0,
    this.wantsChildren = '',
    this.professionalField = '',
    this.employmentStatus = '',
    this.religion = '',
    this.bio = '',
    this.photoUrl,
    this.avatarFile,
    this.subscription = SubscriptionStatus.inconnu,
    this.subscriptionEnd,
    this.questionnaireCompleted = false,
    this.profileScore = 0,
    this.blockedMembers = const [],
  });

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String phone;
  final String country;
  final String city;
  final Gender gender;
  final String familyStatus;
  final bool hasChildren;
  final int childrenCount;
  final String wantsChildren;
  final String professionalField;
  final String employmentStatus;
  final String religion;
  final String bio;
  final String? photoUrl;
  final String? avatarFile;
  final SubscriptionStatus subscription;
  final DateTime? subscriptionEnd;
  final bool questionnaireCompleted;
  final int profileScore;
  final List<String> blockedMembers;

  String get fullName {
    final String name = '$firstName $lastName'.trim();
    return name.isEmpty ? (username.isNotEmpty ? username : email) : name;
  }

  String get initials {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    final String result = '$f$l'.toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  int? get age {
    final DateTime? d = birthDate;
    if (d == null) return null;
    final DateTime now = DateTime.now();
    int years = now.year - d.year;
    if (now.month < d.month ||
        (now.month == d.month && now.day < d.day)) {
      years--;
    }
    return years;
  }

  bool get isPremium =>
      subscription == SubscriptionStatus.actif &&
      (subscriptionEnd == null || subscriptionEnd!.isAfter(DateTime.now()));

  /// URL de la photo, compatible PocketBase (`/api/files/...`) et URLs absolues.
  String? get resolvedPhotoUrl {
    final String? raw = photoUrl ?? avatarFile;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${AppConfig.apiBaseUrl}/api/files/'
        '${AppConfig.membersCollection}/$id/$raw';
  }

  Member copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? phone,
    String? country,
    String? city,
    Gender? gender,
    String? familyStatus,
    bool? hasChildren,
    int? childrenCount,
    String? wantsChildren,
    String? professionalField,
    String? employmentStatus,
    String? religion,
    String? bio,
    String? photoUrl,
    String? avatarFile,
    SubscriptionStatus? subscription,
    DateTime? subscriptionEnd,
    bool? questionnaireCompleted,
    int? profileScore,
    List<String>? blockedMembers,
  }) {
    return Member(
      id: id,
      email: email,
      username: username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      familyStatus: familyStatus ?? this.familyStatus,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenCount: childrenCount ?? this.childrenCount,
      wantsChildren: wantsChildren ?? this.wantsChildren,
      professionalField: professionalField ?? this.professionalField,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      religion: religion ?? this.religion,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarFile: avatarFile ?? this.avatarFile,
      subscription: subscription ?? this.subscription,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      questionnaireCompleted:
          questionnaireCompleted ?? this.questionnaireCompleted,
      profileScore: profileScore ?? this.profileScore,
      blockedMembers: blockedMembers ?? this.blockedMembers,
    );
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    final String dateRaw = (json['date_naissance'] ?? '').toString();
    final List<String> blocked =
        _parseStringList(json['membres_bloques']);

    return Member(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['prenom'] ?? json['firstName'] ?? '').toString(),
      lastName: (json['nom'] ?? json['lastName'] ?? '').toString(),
      birthDate: _parseDate(dateRaw),
      phone: (json['telephone'] ?? '').toString(),
      country: (json['pays'] ?? 'France').toString(),
      city: (json['ville'] ?? '').toString(),
      gender: genderFrom(json['genre']?.toString()),
      familyStatus: (json['situation_familiale'] ?? '').toString(),
      hasChildren: json['a_des_enfants'] == true,
      childrenCount:
          int.tryParse((json['nombre_enfants'] ?? '0').toString()) ?? 0,
      wantsChildren: (json['desir_enfants'] ?? '').toString(),
      professionalField: (json['secteur_professionnel'] ?? '').toString(),
      employmentStatus: (json['statut_emploi'] ?? '').toString(),
      religion: (json['religion'] ?? '').toString(),
      bio: (json['bio'] ?? json['presentation'] ?? '').toString(),
      photoUrl: json['photo']?.toString(),
      avatarFile: json['avatar']?.toString(),
      subscription: subscriptionFrom(json['abonnement_statut']?.toString()),
      subscriptionEnd: _parseDate((json['abonnement_fin'] ?? '').toString()),
      questionnaireCompleted: json['questionnaire_complete'] == true,
      profileScore:
          int.tryParse((json['score_profil'] ?? '0').toString()) ?? 0,
      blockedMembers: blocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'prenom': firstName,
        'nom': lastName,
        'date_naissance': birthDate?.toIso8601String(),
        'telephone': phone,
        'pays': country,
        'ville': city,
        'genre': gender.name,
        'situation_familiale': familyStatus,
        'a_des_enfants': hasChildren,
        'nombre_enfants': childrenCount,
        'desir_enfants': wantsChildren,
        'secteur_professionnel': professionalField,
        'statut_emploi': employmentStatus,
        'religion': religion,
        'bio': bio,
        'photo': photoUrl,
        'abonnement_statut': subscription.name,
        'abonnement_fin': subscriptionEnd?.toIso8601String(),
        'questionnaire_complete': questionnaireCompleted,
      };

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final String s = raw.toString().trim();
    if (s.isEmpty) return const [];
    if (s.startsWith('[')) {
      try {
        final dynamic decoded = jsonDecode(s);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Ignore : on retombe sur le split par virgule.
      }
    }
    return s
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, subscription];
}

/// Helper de parsing des dates renvoyées par PocketBase
/// (format « 2026-01-31 12:00:00.000Z »).
class MemberDate {
  const MemberDate._();

  static DateTime? parse(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }
}
