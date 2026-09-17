import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Direct port of `src/KANU/SceneDelegate.swift`.
///
/// Handles universal links (https://kanu-rencontres.com/...) and custom
/// scheme links, navigating the SPA in place via `location.href` instead
/// of reloading the WebView from scratch — same trick the Swift shell used.
class DeepLinksBridge {
  DeepLinksBridge(this._getController);

  final InAppWebViewController? Function() _getController;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// Link the app was launched with, consumed once by the WebView screen's
  /// initial `loadRootUrl` call (mirrors `universalLinkToLaunch`).
  Uri? initialLink;

  Future<void> init() async {
    initialLink = await _appLinks.getInitialLink();

    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _navigate(uri);
    });
  }

  void _navigate(Uri uri) {
    final controller = _getController();
    if (controller == null) return;
    controller.evaluateJavascript(source: "location.href = '$uri';");
  }

  void dispose() {
    _subscription?.cancel();
  }
}
