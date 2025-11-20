import 'dart:ui';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

typedef JsHandlers = Map<String, void Function(JavaScriptMessage)>;

class SpaceRefWebController {
  SpaceRefWebController._();
  static final SpaceRefWebController instance = SpaceRefWebController._();

  WebViewController? _ctrl;

  WebViewController controller({
    JavaScriptMode jsMode = JavaScriptMode.unrestricted,
    NavigationDelegate? navigationDelegate,
    JsHandlers jsChannels = const {},
    Color background = const Color(0x00000000),
  }) {
    if (_ctrl != null) return _ctrl!;


    PlatformWebViewControllerCreationParams params =
    PlatformWebViewControllerCreationParams();

    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    }

    final c = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(jsMode)
      ..setBackgroundColor(background)
      ..setNavigationDelegate(
        navigationDelegate ?? NavigationDelegate(
          onNavigationRequest: (r) => NavigationDecision.navigate,
        ),
      );

    jsChannels.forEach((name, handler) {
      c.addJavaScriptChannel(name, onMessageReceived: handler);
    });

    if (c.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (c.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(true);
    }

    _ctrl = c;
    return _ctrl!;
  }

  void load(Uri url) => controller().loadRequest(url);

  void reset() {
    _ctrl = null;
  }
}

/*
import 'dart:ui';
import 'package:webview_flutter/webview_flutter.dart';

class SpaceRefWebController {
  SpaceRefWebController._();
  static final SpaceRefWebController instance = SpaceRefWebController._();

  WebViewController? _ctrl;

  WebViewController controller() {
    return _ctrl ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            final host = Uri.parse(r.url).host.toLowerCase();
            return host.contains('spacereference.org')
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
  }
}
*/