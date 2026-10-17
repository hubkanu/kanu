import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/auth_repository.dart';
import '../models/member.dart';
import 'providers.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// État global d'authentification.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.member,
    this.errorMessage,
    this.busy = false,
  });

  final AuthStatus status;
  final Member? member;
  final String? errorMessage;
  final bool busy;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isPremium => member?.isPremium ?? false;
  bool get needsQuestionnaire =>
      isAuthenticated && !(member?.questionnaireCompleted ?? true);

  AuthState copyWith({
    AuthStatus? status,
    Member? member,
    String? errorMessage,
    bool? busy,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      member: member ?? this.member,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [status, member, errorMessage, busy];
}

/// Contrôleur d'authentification (bootstrap, connexion, inscription, profil).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Restaure une éventuelle session persistée au démarrage.
  Future<void> bootstrap() async {
    final AuthSession? session = await _repository.restoreSession();
    if (session != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        member: session.member,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  Future<bool> login({
    required String identity,
    required String password,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final AuthSession session = await _repository.login(
        identity: identity,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        member: session.member,
        busy: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, busy: false);
      return false;
    }
  }

  Future<bool> register(RegistrationData data) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final AuthSession session = await _repository.register(data);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        member: session.member,
        busy: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, busy: false);
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repository.requestPasswordReset(email);
      state = state.copyWith(busy: false, clearError: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, busy: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refresh() async {
    final Member? current = state.member;
    if (current == null) return;
    final Member updated = await _repository.refreshMember(current);
    state = state.copyWith(member: updated);
  }

  /// Met à jour le profil et propage l'état.
  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    final Member? current = state.member;
    if (current == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final Member updated = await _repository.updateMember(current, changes);
      state = state.copyWith(member: updated, busy: false, clearError: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, busy: false);
      return false;
    }
  }

  /// Applique un membre localement (ex. après un achat premium simulé).
  Future<void> applyMember(Member member) async {
    state = state.copyWith(member: member);
    await ref.read(preferencesServiceProvider).setCachedMember(member.toJson());
  }

  Future<void> markQuestionnaireCompleted() async {
    final Member? current = state.member;
    if (current == null) return;
    final Member updated = current.copyWith(questionnaireCompleted: true);
    state = state.copyWith(member: updated);
    await ref.read(preferencesServiceProvider).setCachedMember(updated.toJson());
    await _repository.updateMember(current, {'questionnaire_complete': true});
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
