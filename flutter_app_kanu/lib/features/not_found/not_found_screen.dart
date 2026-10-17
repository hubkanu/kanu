import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/kanu_button.dart';

/// Écran affiché lorsqu'aucune route ne correspond (deep links invalides).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KanuLogo(size: 64, showWordmark: false),
                const SizedBox(height: 24),
                Text(
                  'Page introuvable',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Ce lien n’est plus valide ou la page a été déplacée.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                KanuButton(
                  label: 'Revenir à l’accueil',
                  expand: false,
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
