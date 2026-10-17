import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_logo.dart';
import '../../state/auth_controller.dart';

/// Écran de démarrage : restaure la session puis redirige.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Laisse le temps à l'animation de marque, puis restaure la session.
    // La redirection (go_router) prend ensuite le relais dès que l'état
    // d'authentification change.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KanuLogo(
              size: 96,
              showWordmark: false,
              glow: true,
            ),
            const SizedBox(height: 28),
            Text(
              'KANU',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.white,
                    letterSpacing: 12,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Rencontrer moins. Rencontrer mieux.',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 44),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
