import 'package:equatable/equatable.dart';

import 'member.dart';

/// Critères de recherche de profils.
class SearchFilters extends Equatable {
  const SearchFilters({
    this.query = '',
    this.minAge = 30,
    this.maxAge = 60,
    this.gender,
    this.city = '',
    this.country = '',
    this.religion = '',
    this.hasChildren,
    this.minimumScore = 0,
  });

  final String query;
  final int minAge;
  final int maxAge;
  final Gender? gender;
  final String city;
  final String country;
  final String religion;
  final bool? hasChildren;
  final int minimumScore;

  bool get isEmpty =>
      query.trim().isEmpty &&
      city.trim().isEmpty &&
      country.trim().isEmpty &&
      religion.trim().isEmpty &&
      gender == null &&
      hasChildren == null &&
      minAge <= 30 &&
      maxAge >= 60 &&
      minimumScore == 0;

  SearchFilters copyWith({
    String? query,
    int? minAge,
    int? maxAge,
    Gender? gender,
    bool clearGender = false,
    String? city,
    String? country,
    String? religion,
    bool? hasChildren,
    bool clearChildren = false,
    int? minimumScore,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: clearGender ? null : (gender ?? this.gender),
      city: city ?? this.city,
      country: country ?? this.country,
      religion: religion ?? this.religion,
      hasChildren:
          clearChildren ? null : (hasChildren ?? this.hasChildren),
      minimumScore: minimumScore ?? this.minimumScore,
    );
  }

  @override
  List<Object?> get props => [
        query,
        minAge,
        maxAge,
        gender,
        city,
        country,
        religion,
        hasChildren,
        minimumScore,
      ];
}
