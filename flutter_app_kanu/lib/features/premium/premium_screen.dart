import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../models/subscription_plan.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/auth_controller.dart';
import '../../state/subscription_controller.dart';

/// Écran d'abonnement KANU Premium.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SubscriptionState subscription =
        ref.watch(subscriptionControllerProvider);
    final Member? self = ref.watch(authControllerProvider).member;

    return Scaffold(
      appBar: AppBar(title: const Text('KANU Premium')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _hero(context, self),
          const SectionHeader(title: 'Vos bénéfices', overline: 'Inclus'),
          ...SubscriptionPlan.premiumPerks.map(
            (String perk) => _perkTile(context, perk),
          ),
          const SectionHeader(title: 'Choisissez votre formule', overline: 'Tarifs'),
          _planCards(context, ref, subscription),
          _purchaseArea(context, ref, subscription, self),
          _footerNote(context),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Member? self) {
    final bool premium = self?.isPremium ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.14),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 48, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            premium ? 'Vous êtes Premium' : 'Rencontrez mieux',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            premium
                ? 'Votre abonnement est actif. Merci de votre confiance.'
                : 'Accédez aux profils complets, aux photos autorisées et à '
                    'la messagerie après accord mutuel.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _perkTile(BuildContext context, String perk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(perk, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _planCards(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState subscription,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: SubscriptionPlan.plans.map((SubscriptionPlan plan) {
          final bool selected = subscription.selected.id == plan.id;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: plan == SubscriptionPlan.plans.first ? 10 : 0,
              ),
              child: KanuCard(
                highlight: selected || plan.recommended,
                borderColor: selected ? AppColors.red : null,
                onTap: () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .select(plan),
                child: Column(
                  children: [
                    if (plan.badge != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          plan.badge!.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.gold),
                        ),
                      ),
                    Text(plan.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(plan.priceLabel,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(plan.monthlyLabel,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 14),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.red : AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _purchaseArea(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState subscription,
    Member? self,
  ) {
    final bool premium = self?.isPremium ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          if (subscription.message != null) ...[
            Text(
              subscription.message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subscription.state == PurchaseState.success
                        ? AppColors.success
                        : AppColors.muted,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          KanuButton(
            label: premium
                ? 'Abonnement actif'
                : 'S’abonner · ${subscription.selected.priceLabel}',
            loading: subscription.processing,
            onPressed: premium
                ? null
                : () async {
                    final Member? current =
                        ref.read(authControllerProvider).member;
                    if (current == null) return;
                    final Member? updated = await ref
                        .read(subscriptionControllerProvider.notifier)
                        .purchase(current);
                    if (updated != null) {
                      await ref
                          .read(authControllerProvider.notifier)
                          .applyMember(updated);
                    }
                  },
          ),
          const SizedBox(height: 10),
          KanuButton(
            label: 'Restaurer mes achats',
            variant: KanuButtonVariant.ghost,
            onPressed: subscription.processing
                ? null
                : () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .restore(),
          ),
        ],
      ),
    );
  }

  Widget _footerNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Text(
        'Paiement sécurisé. Sans engagement, résiliable à tout moment. '
        'En vous abonnant, vous acceptez les CGV de KANU.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
