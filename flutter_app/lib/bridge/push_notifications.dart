import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config.dart';

/// Direct port of `src/KANU/PushNotifications.swift`.
///
/// Bridges the "push-subscribe", "push-permission-request",
/// "push-permission-state" and "push-token" JS handlers to
/// firebase_messaging, and forwards incoming/tapped notifications back
/// into the page as CustomEvents, exactly like the Swift shell did.
class PushNotificationsBridge {
  PushNotificationsBridge(this._getController);

  /// Returns the currently active WebView controller, or null while the
  /// page hasn't finished loading yet (mirrors `checkViewAndEvaluate`).
  final InAppWebViewController? Function() _getController;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  void attach(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: BridgeMessages.pushSubscribe,
      callback: (args) => _handleSubscribeTouch(args),
    );
    controller.addJavaScriptHandler(
      handlerName: BridgeMessages.pushPermissionRequest,
      callback: (_) => _handlePushPermission(),
    );
    controller.addJavaScriptHandler(
      handlerName: BridgeMessages.pushPermissionState,
      callback: (_) => _handlePushState(),
    );
    controller.addJavaScriptHandler(
      handlerName: BridgeMessages.pushToken,
      callback: (_) => _handleFcmToken(),
    );

    FirebaseMessaging.onMessage.listen((message) {
      _sendPushToWebView(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _sendPushClickToWebView(message);
    });
  }

  // Equivalent of handleSubscribeTouch / parseSubscribeMessage.
  Future<void> _handleSubscribeTouch(List<dynamic> args) async {
    if (args.isEmpty) return;
    final raw = args.first;
    final List<Map<String, dynamic>> messages = [];

    dynamic decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return;
      }
    }

    if (decoded is Map) {
      messages.add(Map<String, dynamic>.from(decoded));
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) messages.add(Map<String, dynamic>.from(item));
      }
    }

    if (messages.isEmpty) return;
    final first = messages.first;
    final topic = first['topic'] as String? ?? '';
    final unsubscribe = first['unsubscribe'] as bool? ?? false;
    if (topic.isEmpty) return;

    if (unsubscribe) {
      await _messaging.unsubscribeFromTopic(topic);
    } else {
      await _messaging.subscribeToTopic(topic);
    }
  }

  // Equivalent of handlePushPermission / returnPermissionResult.
  Future<void> _handlePushPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    _dispatchEvent(
      BridgeEvents.pushPermissionRequest,
      "'${granted ? 'granted' : 'denied'}'",
    );
  }

  // Equivalent of handlePushState / returnPermissionState.
  Future<void> _handlePushState() async {
    final settings = await _messaging.getNotificationSettings();
    final String state;
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.notDetermined:
        state = 'notDetermined';
      case AuthorizationStatus.denied:
        state = 'denied';
      case AuthorizationStatus.authorized:
        state = 'authorized';
      case AuthorizationStatus.provisional:
        state = 'provisional';
      // ignore: unreachable_switch_default
      default:
        state = 'unknown';
    }
    _dispatchEvent(BridgeEvents.pushPermissionState, "'$state'");
  }

  // Equivalent of handleFCMToken.
  Future<void> _handleFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        _dispatchEvent(BridgeEvents.pushToken, "'ERROR GET TOKEN'");
      } else {
        _dispatchEvent(BridgeEvents.pushToken, "'$token'");
      }
    } catch (_) {
      _dispatchEvent(BridgeEvents.pushToken, "'ERROR GET TOKEN'");
    }
  }

  // Equivalent of sendPushToWebView.
  void _sendPushToWebView(RemoteMessage message) {
    _dispatchEvent(BridgeEvents.pushNotification, jsonEncode(message.data));
  }

  // Equivalent of sendPushClickToWebView.
  void _sendPushClickToWebView(RemoteMessage message) {
    _dispatchEvent(
      BridgeEvents.pushNotificationClick,
      jsonEncode(message.data),
    );
  }

  // Equivalent of checkViewAndEvaluate: retries until the WebView is ready.
  void _dispatchEvent(String event, String jsonDetail) {
    final controller = _getController();
    if (controller == null) {
      Future.delayed(const Duration(seconds: 1), () {
        _dispatchEvent(event, jsonDetail);
      });
      return;
    }
    controller.evaluateJavascript(
      source:
          "window.dispatchEvent(new CustomEvent('$event', { detail: $jsonDetail }));",
    );
  }
}

/// Must be a top-level function: handles data messages while the app is
/// terminated or in the background. Equivalent of the AppDelegate
/// `didReceiveRemoteNotification` background handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI to update while backgrounded; the OS displays the notification
  // and onMessageOpenedApp fires the click bridge when the user taps it.
}
