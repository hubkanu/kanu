/// Validateurs de formulaires réutilisables (messages en français).
class Validators {
  const Validators._();

  static final RegExp _email =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone =
      RegExp(r'^(\+?\d{1,3}[\s.-]?)?(\d[\s.-]?){9,14}$');

  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field est requis.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L’adresse e-mail est requise.';
    }
    if (!_email.hasMatch(value.trim())) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    if (!_phone.hasMatch(value.trim())) {
      return 'Numéro de téléphone invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 8) {
      return 'Au moins 8 caractères.';
    }
    if (!RegExp('[A-Za-z]').hasMatch(value) ||
        !RegExp('[0-9]').hasMatch(value)) {
      return 'Mélangez lettres et chiffres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Merci de confirmer le mot de passe.';
    }
    if (value != original) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  static String? name(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field est requis.';
    }
    if (value.trim().length < 2) {
      return '$field est trop court.';
    }
    return null;
  }

  static String? birthDate(DateTime? value, {int minimumAge = 18}) {
    if (value == null) {
      return 'La date de naissance est requise.';
    }
    final DateTime now = DateTime.now();
    int age = now.year - value.year;
    if (now.month < value.month ||
        (now.month == value.month && now.day < value.day)) {
      age--;
    }
    if (age < minimumAge) {
      return 'Vous devez avoir au moins $minimumAge ans.';
    }
    if (age > 110) {
      return 'Date de naissance invalide.';
    }
    return null;
  }
}
