import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/theme_controller.dart';

/// Racine de l'application KANU.
class KanuApp extends ConsumerWidget {
  const KanuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeControllerProvider);
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
