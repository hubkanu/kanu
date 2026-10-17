import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import '../models/subscription_plan.dart';

enum PurchaseState { idle, processing, success, error, cancelled, restored }

/// État de l'abonnement premium.
///
/// Dans cette version, l'achat est simulé localement puis répercuté sur le
/// membre courant (statut `actif`, échéance). Le branchement réel (Stripe ou
/// In-App Purchase) se fait dans [purchase] via le service de paiement natif.
class SubscriptionState {
  const SubscriptionState({
    required this.selected,
    this.state = PurchaseState.idle,
    this.message,
  });

  final SubscriptionPlan selected;
  final PurchaseState state;
  final String? message;

  bool get processing => state == PurchaseState.processing;

  SubscriptionState copyWith({
    SubscriptionPlan? selected,
    PurchaseState? state,
    String? message,
    bool clearMessage = false,
  }) {
    return SubscriptionState(
      selected: selected ?? this.selected,
      state: state ?? this.state,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class SubscriptionController extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() =>
      SubscriptionState(selected: SubscriptionPlan.plans.first);

  void select(SubscriptionPlan plan) {
    state = state.copyWith(selected: plan);
  }

  /// Simule / déclenche l'achat de la formule sélectionnée.
  /// Retourne le membre mis à jour en cas de succès.
  Future<Member?> purchase(Member self) async {
    state = state.copyWith(state: PurchaseState.processing, clearMessage: true);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    final DateTime now = DateTime.now();
    final DateTime end = DateTime(
      now.year,
      now.month + state.selected.durationMonths,
      now.day,
    );
    final Member updated = self.copyWith(
      subscription: SubscriptionStatus.actif,
      subscriptionEnd: end,
    );

    state = state.copyWith(
      state: PurchaseState.success,
      message: 'Abonnement activé jusqu’au '
          '${end.day.toString().padLeft(2, '0')}/'
          '${end.month.toString().padLeft(2, '0')}/${end.year}.',
    );
    return updated;
  }

  Future<void> restore() async {
    state = state.copyWith(state: PurchaseState.processing);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      state: PurchaseState.restored,
      message: 'Aucun achat à restaurer sur cet appareil.',
    );
  }

  void reset() {
    state = state.copyWith(state: PurchaseState.idle, clearMessage: true);
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
  SubscriptionController.new,
);
