import 'package:equatable/equatable.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/pocketbase_client.dart';
import '../../core/storage/preferences_service.dart';
import '../../models/member.dart';
import '../demo/demo_data.dart';

/// Résultat d'une authentification réussie.
class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.member});

  final String token;
  final Member member;

  @override
  List<Object?> get props => [token, member.id];
}

/// Données du formulaire d'inscription.
class RegistrationData {
  const RegistrationData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.phone,
    required this.country,
    required this.city,
    required this.gender,
    required this.familyStatus,
    required this.hasChildren,
    required this.childrenCount,
    required this.wantsChildren,
    required this.professionalField,
    required this.employmentStatus,
    required this.religion,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
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

  Map<String, dynamic> toPocketBaseBody() {
    final String username =
        '${email.split('@').first.replaceAll(RegExp('[^a-zA-Z0-9]'), '')}'
        '_${DateTime.now().millisecondsSinceEpoch}';
    final String iso = birthDate.toIso8601String().split('T').first;
    return {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'username': username,
      'prenom': firstName,
      'nom': lastName,
      'date_naissance': iso,
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
      'abonnement_statut': 'gratuit',
      'questionnaire_complete': false,
    };
  }
}

/// Accès à l'authentification et au compte courant.
class AuthRepository {
  AuthRepository(this._client, this._prefs);

  final PocketBaseClient _client;
  final PreferencesService _prefs;

  /// Tente une connexion. Repli sur la démo si l'API est injoignable.
  Future<AuthSession> login({
    required String identity,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> json = await _client.authWithPassword(
        collection: AppConfig.membersCollection,
        identity: identity.trim(),
        password: password,
      );
      return await _persistFromAuthResponse(json);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return _demoSession(email: identity.trim());
      }
      rethrow;
    }
  }

  /// Crée un compte puis connecte immédiatement le membre.
  Future<AuthSession> register(RegistrationData data) async {
    try {
      final Map<String, dynamic> created = await _client.createRecord(
        AppConfig.membersCollection,
        data.toPocketBaseBody(),
      );
      // PocketBase peut exiger une confirmation ; on tente la connexion.
      try {
        return await login(
          identity: data.email,
          password: data.password,
        );
      } on ApiException {
        final Member member = Member.fromJson(created);
        await _persist('', member);
        return AuthSession(token: '', member: member);
      }
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return _demoSession(email: data.email, firstName: data.firstName);
      }
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.requestPasswordReset(
        collection: AppConfig.membersCollection,
        email: email.trim(),
      );
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) return;
      rethrow;
    }
  }

  Future<void> logout() async {
    _client.setToken(null);
    await _prefs.clearAuth();
  }

  /// Restaure la session persistée au démarrage.
  Future<AuthSession?> restoreSession() async {
    final String? token = _prefs.token;
    final Map<String, dynamic>? memberJson = _prefs.cachedMember;
    if (memberJson == null) return null;

    final Member cached = Member.fromJson(memberJson);
    if (token != null && token.isNotEmpty) {
      _client.setToken(token);
      // Rafraîchit le profil en arrière-plan (silencieux).
      try {
        final Map<String, dynamic> fresh = await _client.getRecord(
          AppConfig.membersCollection,
          cached.id,
        );
        final Member member = Member.fromJson(fresh);
        await _prefs.setCachedMember(member.toJson());
        return AuthSession(token: token, member: member);
      } on ApiException {
        // On garde le profil en cache.
      }
    }
    return AuthSession(token: token ?? '', member: cached);
  }

  Future<Member> refreshMember(Member current) async {
    try {
      final Map<String, dynamic> fresh = await _client.getRecord(
        AppConfig.membersCollection,
        current.id,
      );
      final Member member = Member.fromJson(fresh);
      await _prefs.setCachedMember(member.toJson());
      return member;
    } on ApiException {
      return current;
    }
  }

  Future<Member> updateMember(Member member, Map<String, dynamic> changes) async {
    try {
      final Map<String, dynamic> updated = await _client.updateRecord(
        AppConfig.membersCollection,
        member.id,
        changes,
      );
      final Member result = Member.fromJson(updated);
      await _prefs.setCachedMember(result.toJson());
      return result;
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        final Member demo = member.copyWith(
          firstName: changes['prenom']?.toString(),
          lastName: changes['nom']?.toString(),
          bio: changes['bio']?.toString(),
          city: changes['ville']?.toString(),
        );
        await _prefs.setCachedMember(demo.toJson());
        return demo;
      }
      rethrow;
    }
  }

  Future<AuthSession> _persistFromAuthResponse(Map<String, dynamic> json) async {
    final String token = (json['token'] ?? '').toString();
    final Map<String, dynamic> record =
        (json['record'] as Map?)?.cast<String, dynamic>() ?? const {};
    final Member member = Member.fromJson(record);
    await _persist(token, member);
    return AuthSession(token: token, member: member);
  }

  Future<void> _persist(String token, Member member) async {
    _client.setToken(token);
    await _prefs.setToken(token);
    await _prefs.setCachedMember(member.toJson());
  }

  Future<AuthSession> _demoSession({
    required String email,
    String firstName = '',
  }) async {
    final Member base = DemoData.currentMember;
    final Member member = firstName.isEmpty
        ? base.copyWith()
        : base.copyWith(firstName: firstName);
    final Member withEmail = Member(
      id: member.id,
      email: email.isEmpty ? member.email : email,
      username: member.username,
      firstName: member.firstName,
      lastName: member.lastName,
      birthDate: member.birthDate,
      phone: member.phone,
      country: member.country,
      city: member.city,
      gender: member.gender,
      familyStatus: member.familyStatus,
      hasChildren: member.hasChildren,
      childrenCount: member.childrenCount,
      wantsChildren: member.wantsChildren,
      professionalField: member.professionalField,
      employmentStatus: member.employmentStatus,
      religion: member.religion,
      bio: member.bio,
      subscription: member.subscription,
      subscriptionEnd: member.subscriptionEnd,
      questionnaireCompleted: member.questionnaireCompleted,
      profileScore: member.profileScore,
    );
    const String demoToken = 'demo-token';
    _client.setToken(demoToken);
    await _prefs.setToken(demoToken);
    await _prefs.setCachedMember(withEmail.toJson());
    return AuthSession(token: demoToken, member: withEmail);
  }
}
