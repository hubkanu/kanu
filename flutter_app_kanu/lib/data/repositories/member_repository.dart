import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/pocketbase_client.dart';
import '../../models/member.dart';
import '../../models/search_filters.dart';
import '../demo/demo_data.dart';

/// Un profil associé à un éventuel score de compatibilité.
class ProfileMatch {
  const ProfileMatch({required this.member, this.score});

  final Member member;
  final int? score;
}

/// Accès aux profils membres (`kanu_members`).
class MemberRepository {
  MemberRepository(this._client);

  final PocketBaseClient _client;

  Future<List<ProfileMatch>> search(
    Member self,
    SearchFilters filters,
  ) async {
    final List<String> clauses = <String>[
      'id != "${self.id}"',
    ];

    if (self.gender == Gender.femme) {
      clauses.add('genre = "homme"');
    } else if (self.gender == Gender.homme) {
      clauses.add('genre = "femme"');
    }

    final DateTime now = DateTime.now();
    final DateTime maxBirth =
        DateTime(now.year - filters.minAge, now.month, now.day);
    final DateTime minBirth =
        DateTime(now.year - filters.maxAge - 1, now.month, now.day);
    clauses.add(
      'date_naissance <= "${_date(maxBirth)}" && '
      'date_naissance >= "${_date(minBirth)}"',
    );

    if (filters.gender != null && filters.gender != Gender.inconnu) {
      clauses.add('genre = "${filters.gender!.name}"');
    }
    if (filters.city.trim().isNotEmpty) {
      clauses.add('ville ~ "${filters.city.trim()}"');
    }
    if (filters.country.trim().isNotEmpty) {
      clauses.add('pays ~ "${filters.country.trim()}"');
    }
    if (filters.religion.trim().isNotEmpty) {
      clauses.add('religion ~ "${filters.religion.trim()}"');
    }
    if (filters.hasChildren != null) {
      clauses.add('a_des_enfants = ${filters.hasChildren!}');
    }
    final String q = filters.query.trim();
    if (q.isNotEmpty) {
      clauses.add(
        '(prenom ~ "$q" || nom ~ "$q" || ville ~ "$q" || '
        'secteur_professionnel ~ "$q")',
      );
    }

    try {
      final List<Map<String, dynamic>> raw = await _client.getFullList(
        AppConfig.membersCollection,
        filter: clauses.join(' && '),
        sort: '-created',
      );
      return raw.map((Map<String, dynamic> e) {
        return ProfileMatch(member: Member.fromJson(e));
      }).toList();
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        return _demoSearch(self, filters);
      }
      rethrow;
    }
  }

  Future<Member?> getById(String id) async {
    try {
      final Map<String, dynamic> json = await _client.getRecord(
        AppConfig.membersCollection,
        id,
      );
      return Member.fromJson(json);
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        final Iterable<Member> all = [
          DemoData.currentMember,
          ...DemoData.profiles,
        ];
        for (final Member m in all) {
          if (m.id == id) return m;
        }
        return null;
      }
      rethrow;
    }
  }

  List<ProfileMatch> _demoSearch(Member self, SearchFilters filters) {
    final Map<String, int> scores = {
      for (final dynamic c in DemoData.compatibilitiesFor(self.id))
        (c.memberBId as String): (c.score as int),
    };
    final List<Member> pool = [
      ...DemoData.profiles,
      DemoData.currentMember,
    ];
    final Iterable<ProfileMatch> results = pool
        .where((Member m) => m.id != self.id)
        .where((Member m) {
          if (filters.gender != null &&
              filters.gender != Gender.inconnu &&
              m.gender != filters.gender) {
            return false;
          }
          final int? age = m.age;
          if (age != null &&
              (age < filters.minAge || age > filters.maxAge)) {
            return false;
          }
          if (filters.city.trim().isNotEmpty &&
              !m.city.toLowerCase().contains(
                    filters.city.trim().toLowerCase(),
                  )) {
            return false;
          }
          if (filters.hasChildren != null &&
              m.hasChildren != filters.hasChildren) {
            return false;
          }
          final String q = filters.query.trim().toLowerCase();
          if (q.isNotEmpty &&
              !m.fullName.toLowerCase().contains(q) &&
              !m.city.toLowerCase().contains(q) &&
              !m.professionalField.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        })
        .map((Member m) => ProfileMatch(member: m, score: scores[m.id]));
    return results.toList();
  }

  String _date(DateTime d) {
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day 00:00:00.000Z';
  }
}
