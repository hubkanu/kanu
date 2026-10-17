import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_text_field.dart';
import '../../state/auth_controller.dart';

/// Demande de réinitialisation du mot de passe.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_email.text);
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent ? _successView() : _formView(auth),
          ),
        ),
      ),
    );
  }

  Widget _formView(AuthState auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: KanuLogo(size: 56, showWordmark: false)),
          const SizedBox(height: 24),
          Text(
            'Réinitialisation',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Indiquez votre adresse e-mail : nous vous enverrons un lien '
            'sécurisé pour définir un nouveau mot de passe.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          if (auth.errorMessage != null) ...[
            Text(
              auth.errorMessage!,
              style: const TextStyle(color: AppColors.rose, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
          KanuTextField(
            controller: _email,
            label: 'Adresse e-mail',
            hint: 'vous@exemple.fr',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          KanuButton(
            label: 'Envoyer le lien',
            loading: auth.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_read_outlined,
            size: 56, color: AppColors.success),
        const SizedBox(height: 24),
        Text(
          'E-mail envoyé',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Si un compte existe pour ${_email.text}, vous recevrez un lien de '
          'réinitialisation. Pensez à vérifier vos courriers indésirables.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 32),
        KanuButton(
          label: 'Retour à la connexion',
          variant: KanuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
