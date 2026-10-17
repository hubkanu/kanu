import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../state/startup_controller.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.overline,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String overline;
  final String title;
  final String body;
}

/// Onboarding d'accueil (présentation du concept KANU).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.favorite_border_rounded,
      overline: 'Rencontres sérieuses',
      title: 'Pas de swipe.\nPas de catalogue.',
      body: 'KANU est une plateforme sélective pour femmes et hommes de '
          '30 ans et plus qui cherchent une relation vraie et durable.',
    ),
    _Slide(
      icon: Icons.psychology_alt_outlined,
      overline: 'Compatibilité',
      title: 'Un questionnaire,\npas un algorithme aveugle.',
      body: 'Vos réponses alimentent un vrai score de compatibilité. '
          'Moins de profils, mais les bons.',
    ),
    _Slide(
      icon: Icons.verified_user_outlined,
      overline: 'Confiance',
      title: 'Chaque mise en relation\nest validée par un conseiller.',
      body: 'Validation humaine, charte de sincérité et confidentialité '
          'totale. Vous gardez le contrôle de vos photos.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool goRegister}) async {
    await ref.read(startupControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(goRegister ? '/register' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const KanuLogo(size: 34, showWordmark: true),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(goRegister: false),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (int i) => setState(() => _index = i),
                itemBuilder: (BuildContext context, int i) {
                  final _Slide slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 40,
                            color: AppColors.rose,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.overline.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.red),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_slides.length, (int i) {
                final bool active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.red : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                children: [
                  KanuButton(
                    label: isLast ? 'Créer mon profil' : 'Continuer',
                    onPressed: () {
                      if (isLast) {
                        _finish(goRegister: true);
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  KanuButton(
                    label: 'J’ai déjà un compte',
                    variant: KanuButtonVariant.ghost,
                    onPressed: () => _finish(goRegister: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
