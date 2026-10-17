import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/member_repository.dart';
import '../models/member.dart';
import '../models/search_filters.dart';
import 'providers.dart';

/// État de l'écran de recherche de profils.
class SearchState extends Equatable {
  const SearchState({
    this.filters = const SearchFilters(),
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final SearchFilters filters;
  final List<ProfileMatch> results;
  final bool loading;
  final String? error;

  bool get isEmpty => !loading && error == null && results.isEmpty;

  SearchState copyWith({
    SearchFilters? filters,
    List<ProfileMatch>? results,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      filters: filters ?? this.filters,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [filters, results, loading, error];
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  Future<void> search(Member self) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ProfileMatch> results = await ref
          .read(memberRepositoryProvider)
          .search(self, state.filters);
      state = state.copyWith(
        results: results,
        loading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, loading: false);
    } catch (_) {
      state = state.copyWith(
        error: 'Recherche impossible pour le moment.',
        loading: false,
      );
    }
  }

  void reset() {
    state = const SearchState();
  }
}

final searchControllerProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
