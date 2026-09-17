import '../config.dart';

/// The original iOS shell exposes native features to the PWA through
/// `window.webkit.messageHandlers.<name>.postMessage(...)`, which is the
/// standard WKWebView bridge (see WebView.swift `userContentController.add`).
///
/// flutter_inappwebview instead uses `window.flutter_inappwebview.callHandler`.
/// Rather than requiring changes on the kanu-rencontres.com side, this shim
/// is injected before any page script runs and re-implements the
/// `window.webkit.messageHandlers.*` surface on top of callHandler, so the
/// existing PWA code (written for the PWABuilder iOS wrapper) keeps working
/// unmodified.
final String jsBridgeShim = () {
  const handlers = [
    BridgeMessages.print,
    BridgeMessages.pushSubscribe,
    BridgeMessages.pushPermissionRequest,
    BridgeMessages.pushPermissionState,
    BridgeMessages.pushToken,
  ];

  final handlerEntries = handlers
      .map((name) => '''
    "$name": {
      postMessage: function(message) {
        window.flutter_inappwebview.callHandler('$name', message);
      }
    }''')
      .join(',\n');

  return '''
(function() {
  if (window.webkit && window.webkit.messageHandlers) return;
  window.webkit = window.webkit || {};
  window.webkit.messageHandlers = {
$handlerEntries
  };
})();
''';
}();
