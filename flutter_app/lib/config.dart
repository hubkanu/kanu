import 'dart:io' show Platform;

/// Direct port of `src/KANU/Settings.swift`.
/// Central place to tweak the shell's behaviour without touching the rest
/// of the code.

/// URL loaded on first launch.
final Uri rootUrl = Uri.parse('https://kanu-rencontres.com');

/// Navigation staying inside the WebView must match one of these hosts.
/// Mirrors `allowedOrigins` in Settings.swift / WKAppBoundDomains in Info.plist.
const List<String> allowedOrigins = ['kanu-rencontres.com'];

/// Hosts that open in the modal toolbar view (e.g. a login provider).
/// Mirrors `authOrigins` in Settings.swift. Empty in the original app.
const List<String> authOrigins = <String>[];

/// Cookie identifying the wrapper as a native app store build.
/// Value adapted per-OS since the original was iOS-only.
String get platformCookieValue {
  if (Platform.isAndroid) return 'Android App Store';
  if (Platform.isIOS) return 'iOS App Store';
  return 'Flutter App';
}

const String platformCookieName = 'app-platform';

/// UI options (see Settings.swift for the original comments).
const String displayMode = 'standalone'; // standalone / fullscreen
const bool adaptiveUIStyle = true; // adapt status bar to page background
const bool pullToRefresh = true;

/// JS bridge message names, shared between the WebView shim and the
/// native handlers. Matches the WKScriptMessageHandler names registered
/// in WebView.swift.
class BridgeMessages {
  static const String print = 'print';
  static const String pushSubscribe = 'push-subscribe';
  static const String pushPermissionRequest = 'push-permission-request';
  static const String pushPermissionState = 'push-permission-state';
  static const String pushToken = 'push-token';
}

/// Custom event names dispatched back into the page, matching the
/// `dispatchEvent(new CustomEvent(...))` calls in PushNotifications.swift.
class BridgeEvents {
  static const String pushPermissionRequest = 'push-permission-request';
  static const String pushPermissionState = 'push-permission-state';
  static const String pushToken = 'push-token';
  static const String pushNotification = 'push-notification';
  static const String pushNotificationClick = 'push-notification-click';
}

/// Schemes that must always be handed off to another app rather than
/// loaded in the WebView. Matches `externalSchemes` in WebView.swift.
const List<String> externalSchemes = [
  'tel',
  'telprompt',
  'mailto',
  'facetime',
  'facetime-audio',
  'fb',
  'fb-messenger',
  'sms',
  'itms-services',
  'itms-apps',
  'itms',
  'maps',
];
