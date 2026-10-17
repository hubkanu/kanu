import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/preferences_service.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PreferencesService prefs = await PreferencesService.create();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
      ],
      child: const KanuApp(),
    ),
  );
}
