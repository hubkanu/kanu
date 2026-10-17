import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver host (exécuté sur la machine hôte) qui reçoit les captures d'écran
/// prises par `integration_test/screenshots_test.dart` et les écrit dans le
/// dossier `screenshots/`. Utilisé par `.github/workflows/ios-screenshots.yml`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final File file =
          await File('screenshots/$name.png').create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
