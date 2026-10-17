import 'package:equatable/equatable.dart';

import 'member.dart';

enum CompatibilityStatus { nouvelle, vue, accord, refusee }

CompatibilityStatus compatibilityStatusFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'vue':
    case 'seen':
      return CompatibilityStatus.vue;
    case 'accord':
    case 'accepted':
      return CompatibilityStatus.accord;
    case 'refusee':
    case 'refused':
      return CompatibilityStatus.refusee;
    default:
      return CompatibilityStatus.nouvelle;
  }
}

/// Score de compatibilité entre deux membres (collection `kanu_compatibilites`).
class Compatibility extends Equatable {
  const Compatibility({
    required this.id,
    required this.memberAId,
    required this.memberBId,
    required this.score,
    this.status = CompatibilityStatus.nouvelle,
    this.otherMember,
    this.createdAt,
  });

  final String id;
  final String memberAId;
  final String memberBId;
  final int score;
  final CompatibilityStatus status;

  /// Profil de l'autre membre (résolu via `expand` ou chargé à part).
  final Member? otherMember;
  final DateTime? createdAt;

  bool get isHigh => score >= 85;
  bool get isMedium => score >= 70 && score < 85;

  String get scoreLabel {
    if (score >= 90) return 'Exceptionnelle';
    if (score >= 85) return 'Très forte';
    if (score >= 70) return 'Forte';
    if (score >= 50) return 'À explorer';
    return 'Faible';
  }

  Compatibility copyWith({Member? otherMember, CompatibilityStatus? status}) {
    return Compatibility(
      id: id,
      memberAId: memberAId,
      memberBId: memberBId,
      score: score,
      status: status ?? this.status,
      otherMember: otherMember ?? this.otherMember,
      createdAt: createdAt,
    );
  }

  static Member? _resolveOther(Map<String, dynamic> json, String selfId) {
    final Map<String, dynamic>? expand =
        (json['expand'] as Map?)?.cast<String, dynamic>();
    if (expand == null) return null;
    for (final dynamic entry in expand.values) {
      if (entry is Map) {
        final Member m = Member.fromJson(entry.cast<String, dynamic>());
        if (m.id.isNotEmpty && m.id != selfId) return m;
      }
    }
    return null;
  }

  factory Compatibility.fromJson(
    Map<String, dynamic> json, {
    String selfId = '',
  }) {
    final String a = (json['membre_a'] ?? '').toString();
    final String b = (json['membre_b'] ?? '').toString();
    return Compatibility(
      id: (json['id'] ?? '').toString(),
      memberAId: a,
      memberBId: b,
      score: int.tryParse((json['score'] ?? '0').toString()) ?? 0,
      status: compatibilityStatusFrom(json['statut']?.toString()),
      otherMember: _resolveOther(json, selfId),
      createdAt: MemberDate.parse((json['created'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, memberAId, memberBId, score, status];
}
