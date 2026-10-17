import 'package:equatable/equatable.dart';

import 'member.dart';

enum DemandeStatus { enAttente, acceptee, refusee }

DemandeStatus demandeStatusFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'acceptee':
    case 'accepte':
    case 'accepted':
      return DemandeStatus.acceptee;
    case 'refusee':
    case 'refuse':
    case 'refused':
      return DemandeStatus.refusee;
    default:
      return DemandeStatus.enAttente;
  }
}

String demandeStatusLabel(DemandeStatus s) {
  switch (s) {
    case DemandeStatus.acceptee:
      return 'Acceptée';
    case DemandeStatus.refusee:
      return 'Refusée';
    case DemandeStatus.enAttente:
      return 'En attente';
  }
}

/// Demande de mise en relation (collection `kanu_demandes`).
class Demande extends Equatable {
  const Demande({
    required this.id,
    required this.senderId,
    required this.recipientId,
    this.status = DemandeStatus.enAttente,
    this.message = '',
    this.compatibilityId = '',
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final DemandeStatus status;
  final String message;
  final String compatibilityId;
  final DateTime? createdAt;

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: (json['id'] ?? '').toString(),
      senderId: (json['demandeur_id'] ?? '').toString(),
      recipientId: (json['destinataire_id'] ?? '').toString(),
      status: demandeStatusFrom(json['statut']?.toString()),
      message: (json['message'] ?? '').toString(),
      compatibilityId: (json['compatibilite_id'] ?? '').toString(),
      createdAt: MemberDate.parse((json['created'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props =>
      [id, senderId, recipientId, status, compatibilityId];
}
