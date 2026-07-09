import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'social_extractor.dart';

const _mobileUA =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile Safari/604.1';

/// Apre il reel Facebook in una webview con la sessione dell'utente
/// (persistente). Se serve, l'utente accede UNA volta; poi la didascalia della
/// ricetta viene letta dalla pagina e restituita. Le volte successive, essendo
/// già loggato, la lettura è quasi istantanea. Ritorna null se annulla.
Future<ExtractedPost?> importFacebookInteractive(
    BuildContext context, String url) {
  return Navigator.of(context).push<ExtractedPost>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _FbPage(url: url),
  ));
}

class _FbPage extends StatefulWidget {
  final String url;
  const _FbPage({required this.url});
  @override
  State<_FbPage> createState() => _FbPageState();
}

class _FbPageState extends State<_FbPage> {
  InAppWebViewController? _c;
  bool _needLogin = false;
  bool _busy = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _tryExtract() async {
    if (_busy || _c == null || !mounted) return;
    _busy = true;
    try {
      final raw = await _c!.evaluateJavascript(source: r'''
        (function(){
          function m(p){var e=document.querySelector('meta[property="'+p+'"]');return e?e.content:null;}
          var login = !!(document.querySelector('input[name="email"]')||document.querySelector('input[name="pass"]'))
                      || /\/login|\/checkpoint/i.test(location.pathname);
          var best='';
          document.querySelectorAll('div[dir="auto"],span[dir="auto"]').forEach(function(n){
            var t=(n.innerText||'').trim();
            if(t.length>best.length && t.length<6000) best=t;
          });
          return JSON.stringify({login:login, cap:best, title:m('og:title'), img:m('og:image'), href:location.href});
        })();
      ''');
      if (raw == null) return;
      final j = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final login = j['login'] == true;
      if (login != _needLogin && mounted) setState(() => _needLogin = login);
      final cap = (j['cap'] ?? '').toString().trim();
      if (!login && cap.length >= 60 && mounted) {
        _poll?.cancel();
        Navigator.of(context).pop(ExtractedPost(
          title: (j['title'] ?? 'Ricetta da Facebook').toString(),
          text: cap,
          imageUrl:
              (j['img'] ?? '').toString().isEmpty ? null : j['img'].toString(),
          sourceUrl: (j['href'] ?? widget.url).toString(),
        ));
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook'),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: Column(children: [
        if (_needLogin)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF0D6),
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Accedi a Facebook una volta: dopo, le ricette dei reel si importano da sole.',
              style: TextStyle(
                  color: Color(0xFF9A6B00), fontWeight: FontWeight.w700),
            ),
          ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
                userAgent: _mobileUA, javaScriptEnabled: true),
            onWebViewCreated: (c) => _c = c,
            onLoadStop: (c, _) async {
              await Future.delayed(const Duration(seconds: 1));
              await _tryExtract();
              _poll?.cancel();
              _poll = Timer.periodic(
                  const Duration(seconds: 2), (_) => _tryExtract());
            },
          ),
        ),
      ]),
    );
  }
}
