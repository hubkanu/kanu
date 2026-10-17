import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Petit wrapper autour de [SharedPreferences] pour la persistance locale
/// (jeton d'authentification, profil en cache, thème, onboarding, consentement).
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kToken = 'kanu.auth.token';
  static const String _kMember = 'kanu.auth.member';
  static const String _kTheme = 'kanu.theme.mode';
  static const String _kOnboarding = 'kanu.onboarding.done';
  static const String _kConsent = 'kanu.consent.v1';

  static Future<PreferencesService> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // ---- Auth ------------------------------------------------------------
  String? get token => _prefs.getString(_kToken);

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_kToken);
    } else {
      await _prefs.setString(_kToken, token);
    }
  }

  Map<String, dynamic>? get cachedMember {
    final String? raw = _prefs.getString(_kMember);
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedMember(Map<String, dynamic>? member) async {
    if (member == null) {
      await _prefs.remove(_kMember);
    } else {
      await _prefs.setString(_kMember, jsonEncode(member));
    }
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kMember);
  }

  // ---- Préférences UI --------------------------------------------------
  /// `system`, `light` ou `dark`.
  String get themeMode => _prefs.getString(_kTheme) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_kTheme, mode);
  }

  bool get onboardingDone => _prefs.getBool(_kOnboarding) ?? false;

  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_kOnboarding, value);
  }

  bool get consentGiven => _prefs.getBool(_kConsent) ?? false;

  Future<void> setConsentGiven(bool value) async {
    await _prefs.setBool(_kConsent, value);
  }
}
