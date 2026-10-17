import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_text_field.dart';
import '../../shared/widgets/ornamental_divider.dart';
import '../../state/auth_controller.dart';

/// Écran de connexion à l'espace membre.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool ok = await ref.read(authControllerProvider.notifier).login(
          identity: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: KanuLogo(size: 64, showWordmark: false)),
                  const SizedBox(height: 24),
                  const Center(child: OrnamentalDivider(label: 'Espace membre')),
                  const SizedBox(height: 20),
                  Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Accédez à votre espace membre',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  if (auth.errorMessage != null) ...[
                    _ErrorBanner(message: auth.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  KanuTextField(
                    controller: _email,
                    label: 'Adresse e-mail',
                    hint: 'vous@exemple.fr',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 18),
                  KanuTextField(
                    controller: _password,
                    label: 'Mot de passe',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    validator: (String? v) =>
                        Validators.required(v, field: 'Le mot de passe'),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  KanuButton(
                    label: 'Se connecter',
                    loading: auth.busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Créer un profil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/onboarding'),
                    child: const Text('Revoir la présentation'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.rose),
            ),
          ),
        ],
      ),
    );
  }
}
