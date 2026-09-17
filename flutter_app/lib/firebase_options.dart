// File generated normally by the FlutterFire CLI, hand-written here as a
// placeholder because `src/KANU/GoogleService-Info.plist` only ever held
// PWABuilder's template values (project "pwabuilder-ios-template", all-zero
// keys) — the original iOS app never had a real Firebase project wired up
// either (see AppDelegate.swift: `FirebaseApp.configure()` is commented out).
//
// Before push notifications can work, create/reuse a Firebase project for
// kanu-rencontres.com and run from this directory:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That regenerates this file for real, and drops google-services.json /
// GoogleService-Info.plist into android/app and ios/Runner respectively.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run `flutterfire configure` from this directory.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform - '
          'run `flutterfire configure` from this directory.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZ4cSXWxfq37ehY2nuKbqhOGzN4iZxqP4',
    appId: '1:305257104345:android:761ff1838b9162f8e58fc8',
    messagingSenderId: '305257104345',
    projectId: 'kanu-rencontres',
    storageBucket: 'kanu-rencontres.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSHIbB0_xcIweyKlx1d_uG3fTRXBxzqBA',
    appId: '1:305257104345:ios:1a4de17a206e842be58fc8',
    messagingSenderId: '305257104345',
    projectId: 'kanu-rencontres',
    storageBucket: 'kanu-rencontres.firebasestorage.app',
    iosBundleId: 'com.kanu.kanu',
  );
}
