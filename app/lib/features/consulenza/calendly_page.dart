import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Parametri embed Calendly coordinati col brand Beet-It (sfondo crema,
/// testo prugna, accento beet) e senza banner ridondanti.
String calendlyEmbedUrl(String base) {
  final sep = base.contains('?') ? '&' : '?';
  return '$base${sep}hide_gdpr_banner=1&hide_landing_page_details=1'
      '&background_color=FBFAF7&text_color=3A0E2A&primary_color=B5326B';
}

/// Calendario Calendly INLINE nell'app (webview): l'utente sceglie data/ora e
/// prenota senza uscire da Beet-It.
class CalendlyPage extends StatelessWidget {
  final String title;
  final String url;
  const CalendlyPage({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(calendlyEmbedUrl(url))),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
      ),
    );
  }
}
