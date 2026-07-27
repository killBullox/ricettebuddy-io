import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'social_extractor.dart';

const _mobileUA =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile Safari/604.1';

/// Estrae la didascalia caricando il post in una **webview headless sul
/// telefono** (IP dell'utente + eventuale sessione già loggata nel WebView).
/// La pagina esegue il JavaScript come un browser vero, quindi i meta og: sono
/// popolati anche dove la semplice fetch HTTP riceve il muro di login di
/// Instagram/TikTok. Ritorna null se non riesce: il chiamante ripiega.
///
/// È il metodo che, dagli IP dei datacenter bloccati (yt-dlp lato server), non
/// era più possibile: qui gira sul dispositivo dell'utente, non bloccato.
Future<ExtractedPost?> extractViaWebView(String url) async {
  final done = Completer<String?>();
  HeadlessInAppWebView? hw;
  Timer? watchdog;

  void finish(String? html) {
    if (!done.isCompleted) done.complete(html);
  }

  hw = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
    initialSettings: InAppWebViewSettings(
      userAgent: _mobileUA,
      javaScriptEnabled: true,
      clearCache: false, // mantiene i cookie: se l'utente è loggato, legge tutto
      incognito: false,
      mediaPlaybackRequiresUserGesture: true,
    ),
    onLoadStop: (controller, uri) async {
      // Lascia un momento al JS per popolare i meta og: / la didascalia.
      await Future.delayed(const Duration(milliseconds: 1800));
      try {
        final html = await controller.evaluateJavascript(
            source: 'document.documentElement.outerHTML');
        finish(html is String ? html : html?.toString());
      } catch (_) {
        finish(null);
      }
    },
    onReceivedError: (controller, request, error) => finish(null),
  );

  try {
    await hw.run();
    watchdog = Timer(const Duration(seconds: 20), () => finish(null));
    final html = await done.future;
    if (html == null || html.length < 100) return null;
    final post = SocialExtractor.fromRenderedHtml(html, url);
    return post.text.trim().length >= 40 ? post : null;
  } catch (_) {
    return null;
  } finally {
    watchdog?.cancel();
    await hw.dispose();
  }
}
