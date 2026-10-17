import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Client REST minimal pour un backend [PocketBase].
///
/// PocketBase expose une API générique :
///   POST   /api/collections/{collection}/records
///   GET    /api/collections/{collection}/records
///   PATCH  /api/collections/{collection}/records/{id}
///   DELETE /api/collections/{collection}/records/{id}
///   POST   /api/collections/{collection}/auth-with-password
///   POST   /api/collections/{collection}/request-password-reset
class PocketBaseClient {
  PocketBaseClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.networkTimeout,
                receiveTimeout: AppConfig.networkTimeout,
                sendTimeout: AppConfig.networkTimeout,
                contentType: Headers.jsonContentType,
                // On gère nous-mêmes les codes > 300 pour produire des
                // exceptions typées.
                validateStatus: (_) => true,
              ),
            );

  final Dio _dio;

  Dio get dio => _dio;

  /// Définit le jeton d'authentification courant (attaché à chaque requête).
  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = token;
    }
  }

  // ---------------------------------------------------------------------
  // Authentification
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> authWithPassword({
    required String collection,
    required String identity,
    required String password,
  }) {
    return _post('/api/collections/$collection/auth-with-password', {
      'identity': identity,
      'password': password,
    });
  }

  Future<void> requestPasswordReset({
    required String collection,
    required String email,
  }) {
    return _post(
      '/api/collections/$collection/request-password-reset',
      {'email': email},
    );
  }

  // ---------------------------------------------------------------------
  // CRUD générique
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> createRecord(
    String collection,
    Map<String, dynamic> body,
  ) {
    return _post('/api/collections/$collection/records', body);
  }

  Future<Map<String, dynamic>> updateRecord(
    String collection,
    String id,
    Map<String, dynamic> body,
  ) {
    return _send(
      'PATCH',
      '/api/collections/$collection/records/$id',
      body: body,
    );
  }

  Future<Map<String, dynamic>> getRecord(String collection, String id) {
    return _send('GET', '/api/collections/$collection/records/$id');
  }

  /// Liste paginée. [filter] utilise la syntaxe de filtre PocketBase.
  Future<List<Map<String, dynamic>>> listRecords(
    String collection, {
    int page = 1,
    int perPage = 50,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'perPage': perPage,
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (expand != null && expand.isNotEmpty) 'expand': expand,
    };
    final Map<String, dynamic> json = await _send(
      'GET',
      '/api/collections/$collection/records',
      query: query,
    );
    final List<dynamic> items = (json['items'] as List<dynamic>?) ?? const [];
    return items
        .map((dynamic e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  /// Récupère tous les enregistrements en itérant sur les pages.
  Future<List<Map<String, dynamic>>> getFullList(
    String collection, {
    String? filter,
    String? sort,
    int pageSize = 100,
  }) async {
    final List<Map<String, dynamic>> all = [];
    int page = 1;
    while (true) {
      final List<Map<String, dynamic>> items = await listRecords(
        collection,
        page: page,
        perPage: pageSize,
        filter: filter,
        sort: sort,
      );
      all.addAll(items);
      if (items.length < pageSize) break;
      page++;
    }
    return all;
  }

  // ---------------------------------------------------------------------
  // Interne
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );

      final int status = response.statusCode ?? 0;
      final dynamic data = response.data;

      if (status >= 200 && status < 300) {
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{'data': data};
      }

      final Map<String, dynamic> errorBody = data is Map
          ? data.cast<String, dynamic>()
          : <String, dynamic>{'message': data?.toString()};
      throw ApiException.fromPocketBase(status, errorBody);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        _mapDioMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException('Erreur inattendue : $e');
    }
  }

  String _mapDioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Le serveur KANU met trop de temps à répondre.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur KANU.';
      case DioExceptionType.badCertificate:
        return 'Certificat serveur invalide.';
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return e.message ?? 'Erreur réseau inconnue.';
    }
  }
}
