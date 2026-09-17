import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'bridge/push_notifications.dart';
import 'firebase_options.dart';
import 'webview_screen.dart';

/// True once `flutterfire configure` has replaced the placeholder values in
/// firebase_options.dart. Push notifications are silently disabled until
/// then, so the app can still be built and run to test the WebView shell.
bool get isFirebaseConfigured =>
    DefaultFirebaseOptions.currentPlatform.apiKey != 'REPLACE_ME';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Equivalent of `FirebaseApp.configure()` in AppDelegate.swift.
  // Run `flutterfire configure` once to generate firebase_options.dart
  // for this project before this becomes active.
  if (isFirebaseConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const KanuApp());
}

class KanuApp extends StatelessWidget {
  const KanuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KANU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      home: const WebViewScreen(),
    );
  }
}
