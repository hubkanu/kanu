import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_text_field.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';

/// Signalement d'un profil (harcèlement, faux profil, propos inappropriés…).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  static const List<String> _reasons = [
    'Faux profil',
    'Propos inappropriés',
    'Harcèlement',
    'Comportement irrespectueux',
    'Autre',
  ];

  String _reason = _reasons.first;
  final TextEditingController _details = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final Member? self = ref.read(authControllerProvider).member;
    setState(() => _submitting = true);
    try {
      await ref.read(pocketBaseClientProvider).createRecord(
            AppConfig.reportsCollection,
            {
              'membre_id': self?.id ?? '',
              'cible_id': widget.memberId,
              'motif': _reason,
              'details': _details.text.trim(),
              'statut': 'nouveau',
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signalement transmis. Merci pour votre vigilance.'),
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (e.isNetwork && AppConfig.allowDemoFallback) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement enregistré.')),
        );
        context.pop();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Votre signalement est confidentiel. Un conseiller KANU '
                    'étudiera la situation.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Motif', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (String? v) => setState(() => _reason = v ?? _reason),
            child: Column(
              children: _reasons
                  .map(
                    (String r) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: r,
                      activeColor: AppColors.red,
                      title: Text(r),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          KanuTextField(
            controller: _details,
            label: 'Détails (optionnel)',
            maxLines: 5,
            maxLength: 600,
            hint: 'Décrivez les faits, dates, captures…',
          ),
          const SizedBox(height: 24),
          KanuButton(
            label: 'Envoyer le signalement',
            variant: KanuButtonVariant.danger,
            loading: _submitting,
            icon: Icons.flag_outlined,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
