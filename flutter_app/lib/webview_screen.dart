import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bridge/deep_links.dart';
import 'bridge/js_bridge_shim.dart';
import 'bridge/push_notifications.dart';
import 'config.dart' as cfg;

/// Direct port of `src/KANU/ViewController.swift` + `src/KANU/WebView.swift`.
///
/// A single-webview shell around the kanu-rencontres.com PWA: loading
/// screen with progress bar, connection-error retry loop, navigation
/// policy restricted to [cfg.allowedOrigins]/[cfg.authOrigins], pull to
/// refresh, downloads, and the native bridges (push, print, deep links).
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

enum _LoadingMode { defaultCachePolicy, forceCache }

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;

  late final PushNotificationsBridge _pushBridge;
  late final DeepLinksBridge _deepLinksBridge;

  bool _htmlIsLoaded = false;
  bool _webViewHidden = true;
  bool _showConnectionProblem = false;
  double _progress = 0;
  _LoadingMode _loadingMode = _LoadingMode.defaultCachePolicy;

  /// Non-null while browsing an auth origin, mirrors `toolbarView` visibility.
  bool _showAuthToolbar = false;

  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _pushBridge = PushNotificationsBridge(() => _controller);
    _deepLinksBridge = DeepLinksBridge(() => _controller);
    _deepLinksBridge.init();

    if (cfg.pullToRefresh) {
      _pullToRefreshController = PullToRefreshController(
        settings: PullToRefreshSettings(color: Colors.black),
        onRefresh: _reload,
      );
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _deepLinksBridge.dispose();
    super.dispose();
  }

  Future<void> _setPlatformCookie() async {
    await CookieManager.instance().setCookie(
      url: WebUri(cfg.rootUrl.toString()),
      name: cfg.platformCookieName,
      value: cfg.platformCookieValue,
      domain: cfg.rootUrl.host,
      path: '/',
      isSecure: false,
      expiresDate:
          DateTime.now()
              .add(const Duration(days: 365))
              .millisecondsSinceEpoch,
    );
  }

  Uri get _launchUrl => _deepLinksBridge.initialLink ?? cfg.rootUrl;

  void _reload() {
    _controller?.reload();
  }

  // Equivalent of `loadRootUrl` / the toolbar's "Done" button action.
  Future<void> _loadRootUrl({bool ignoreCache = false}) async {
    setState(() => _showAuthToolbar = false);
    await _controller?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(cfg.rootUrl.toString()),
        cachePolicy: ignoreCache
            ? URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA
            : URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      ),
    );
  }

  // Equivalent of `reloadWebview(loadingMode:)`.
  Future<void> _reloadWebview(_LoadingMode mode) async {
    _loadingMode = mode;
    await _loadRootUrl(ignoreCache: mode == _LoadingMode.forceCache);
  }

  // Equivalent of `webView(_:didFinish:)`.
  void _onLoadStop() {
    _htmlIsLoaded = true;
    setState(() {
      _progress = 1;
      _showConnectionProblem = false;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _webViewHidden = false;
        _progress = 0;
      });
    });
  }

  // Equivalent of `webView(_:didFailProvisionalNavigation:withError:)`.
  void _onLoadError() {
    _htmlIsLoaded = false;
    setState(() => _webViewHidden = true);

    if (_loadingMode == _LoadingMode.defaultCachePolicy) {
      Future.microtask(() => _reloadWebview(_LoadingMode.forceCache));
    } else {
      setState(() {
        _showConnectionProblem = true;
        _progress = 0.05;
      });
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _progress = 0.1);
        _retryTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          _reloadWebview(_LoadingMode.defaultCachePolicy);
        });
      });
    }
  }

  // Equivalent of the `decidePolicyFor navigationAction` switch in WebView.swift.
  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.CANCEL;

    if (url.scheme == 'about') return NavigationActionPolicy.ALLOW;

    if (cfg.externalSchemes.contains(url.scheme.toLowerCase())) {
      final launchable = Uri.tryParse(url.toString());
      if (launchable != null && await canLaunchUrl(launchable)) {
        await launchUrl(launchable, mode: LaunchMode.externalApplication);
      }
      return NavigationActionPolicy.CANCEL;
    }

    final host = url.host;
    if (host.isNotEmpty) {
      final matchesAuthOrigin = cfg.authOrigins.any((o) => host.contains(o));
      if (matchesAuthOrigin) {
        if (!_showAuthToolbar) setState(() => _showAuthToolbar = true);
        return NavigationActionPolicy.ALLOW;
      }

      final matchesAllowedOrigin = cfg.allowedOrigins.any(
        (o) => host.contains(o),
      );
      if (matchesAllowedOrigin) {
        if (_showAuthToolbar) setState(() => _showAuthToolbar = false);
        return NavigationActionPolicy.ALLOW;
      }

      // Unknown host: open externally (equivalent of SFSafariViewController).
      final launchable = Uri.tryParse(url.toString());
      if (launchable != null &&
          (url.scheme == 'http' || url.scheme == 'https')) {
        await launchUrl(launchable, mode: LaunchMode.inAppBrowserView);
      } else if (launchable != null && await canLaunchUrl(launchable)) {
        await launchUrl(launchable);
      }
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.CANCEL;
  }

  // Equivalent of `downloadAndOpenFile` / the WKDownloadDelegate methods.
  Future<void> _onDownloadStartRequest(
    InAppWebViewController controller,
    DownloadStartRequest request,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = request.suggestedFilename ?? 'download';
      final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      if (await file.exists()) await file.delete();

      final client = HttpClient();
      final httpRequest = await client.getUrl(Uri.parse(request.url.toString()));
      final httpResponse = await httpRequest.close();
      await httpResponse.pipe(file.openWrite());

      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint('Download failed: $e');
    }
  }

  void _attachBridges(InAppWebViewController controller) {
    _pushBridge.attach(controller);
    controller.addJavaScriptHandler(
      handlerName: cfg.BridgeMessages.print,
      callback: (_) async {
        await controller.printCurrentPage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: !_showAuthToolbar,
        child: Column(
          children: [
            if (_showAuthToolbar)
              AppBar(
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: () => _loadRootUrl(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_launchUrl.toString()),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      javaScriptCanOpenWindowsAutomatically: true,
                      allowsInlineMediaPlayback: true,
                      useShouldOverrideUrlLoading: true,
                      useOnDownloadStart: true,
                      applicationNameForUserAgent: 'Safari/604.1',
                      isInspectable: true,
                      transparentBackground: false,
                    ),
                    pullToRefreshController: _pullToRefreshController,
                    onWebViewCreated: (controller) async {
                      _controller = controller;
                      await _setPlatformCookie();
                      await controller.addUserScript(
                        userScript: UserScript(
                          source: jsBridgeShim,
                          injectionTime:
                              UserScriptInjectionTime.AT_DOCUMENT_START,
                        ),
                      );
                      _attachBridges(controller);
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _htmlIsLoaded = false;
                        _showConnectionProblem = false;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      if (!_webViewHidden || _htmlIsLoaded) return;
                      var p = progress / 100;
                      if (p >= 0.8) p = 1.0;
                      if (p >= 0.3 && _showConnectionProblem) {
                        setState(() => _showConnectionProblem = false);
                      }
                      setState(() => _progress = p);
                    },
                    onLoadStop: (controller, url) {
                      _pullToRefreshController?.endRefreshing();
                      _onLoadStop();
                    },
                    onReceivedError: (controller, request, error) {
                      _pullToRefreshController?.endRefreshing();
                      if (request.isForMainFrame ?? true) _onLoadError();
                    },
                    shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                    onDownloadStartRequest: _onDownloadStartRequest,
                    onCreateWindow: (controller, action) async {
                      // Redirect new tabs/windows to the main WebView.
                      await controller.loadUrl(urlRequest: action.request);
                      return false;
                    },
                  ),
                  if (_webViewHidden)
                    _LoadingOverlay(
                      progress: _progress,
                      showConnectionProblem: _showConnectionProblem,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equivalent of the storyboard's loadingView + progressView +
/// connectionProblemView stack in Main.storyboard.
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({
    required this.progress,
    required this.showConnectionProblem,
  });

  final double progress;
  final bool showConnectionProblem;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 96, height: 96),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(value: progress == 0 ? null : progress),
            ),
            if (showConnectionProblem) ...[
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: showConnectionProblem ? 1 : 0,
                duration: const Duration(milliseconds: 700),
                child: const Icon(Icons.wifi_off, color: Colors.grey, size: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
