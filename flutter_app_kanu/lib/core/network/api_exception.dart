/// Exception applicative normalisée pour toutes les erreurs réseau/API.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  /// Traduit une erreur PocketBase (`data.data`) en message lisible.
  factory ApiException.fromPocketBase(
    int? statusCode,
    Map<String, dynamic> body,
  ) {
    final Map<String, dynamic> data =
        (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final String? message = body['message'] as String?;

    if (data.isNotEmpty) {
      final String field = data.keys.first;
      final Object? entry = data[field];
      String detail = 'Valeur invalide';
      if (entry is Map && entry.isNotEmpty) {
        detail = entry.values.first.toString();
      } else if (entry is String) {
        detail = entry;
      }
      return ApiException(
        _fieldLabel(field, detail),
        statusCode: statusCode,
        data: data,
      );
    }

    return ApiException(
      message ?? _defaultMessage(statusCode),
      statusCode: statusCode,
      data: data,
    );
  }

  static String _fieldLabel(String field, String detail) {
    const Map<String, String> labels = {
      'email': 'E-mail',
      'password': 'Mot de passe',
      'passwordConfirm': 'Confirmation',
      'identity': 'Identifiants',
      'prenom': 'Prénom',
      'nom': 'Nom',
      'telephone': 'Téléphone',
      'date_naissance': 'Date de naissance',
    };
    final String label = labels[field] ?? field;
    return '$label : $detail';
  }

  static String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Requête invalide.';
      case 401:
      case 403:
        return 'Identifiants incorrects ou accès refusé.';
      case 404:
        return 'Ressource introuvable.';
      case 422:
        return 'Les informations fournies sont invalides.';
      case 429:
        return 'Trop de tentatives. Réessayez dans un instant.';
      case null:
        return 'Impossible de joindre le serveur KANU. Vérifiez votre connexion.';
      default:
        return 'Une erreur est survenue (code $status).';
    }
  }

  @override
  String toString() => 'ApiException($message)';
}
