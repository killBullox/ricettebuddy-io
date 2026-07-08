import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

/// Contenuto estratto da un post social, PRIMA dell'AI.
class ExtractedPost {
  final String title;
  final String text; // didascalia/descrizione: la fonte della ricetta
  final String? imageUrl;
  final String sourceUrl;
  const ExtractedPost({
    required this.title,
    required this.text,
    this.imageUrl,
    required this.sourceUrl,
  });
}

/// Estrae il contenuto di un post social **sul dispositivo dell'utente**
/// (connessione e sessioni loggate dell'utente): così YouTube/Facebook/…
/// non bloccano come farebbero verso un IP da datacenter. Al backend arriva
/// solo il testo, che fa l'AI (veganizzazione, ingredienti, quantità, ecc.).
class SocialExtractor {
  static const _iosUA =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile Safari/604.1';

  static Future<ExtractedPost> extract(String url) async {
    final u = url.trim();
    if (RegExp(r'youtube\.com|youtu\.be', caseSensitive: false).hasMatch(u)) {
      return _youtube(u);
    }
    if (RegExp(r'tiktok\.com', caseSensitive: false).hasMatch(u)) {
      return _tiktok(u);
    }
    // Instagram / Facebook / Pinterest / generico → webview (DOM + og:meta).
    return _viaWebView(u);
  }

  // ---- YouTube: API interna InnerTube (client MWEB) via http dal device ----
  static String? _ytId(String url) {
    final m = RegExp(
      r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|shorts/|embed/|live/))([A-Za-z0-9_-]{6,})',
      caseSensitive: false,
    ).firstMatch(url);
    return m?.group(1);
  }

  static Future<ExtractedPost> _youtube(String url) async {
    final id = _ytId(url);
    if (id == null) throw 'Link YouTube non riconosciuto.';
    final r = await http.post(
      Uri.parse('https://www.youtube.com/youtubei/v1/player'
          '?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8&prettyPrint=false'),
      headers: {'Content-Type': 'application/json', 'User-Agent': _iosUA},
      body: jsonEncode({
        'context': {
          'client': {
            'clientName': 'MWEB',
            'clientVersion': '2.20240726.00.00',
            'hl': 'it',
            'gl': 'IT',
          }
        },
        'videoId': id,
      }),
    );
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final vd = (j['videoDetails'] as Map?) ?? const {};
    final title = (vd['title'] ?? 'Ricetta da YouTube').toString();
    var desc = (vd['shortDescription'] ?? '').toString();
    final thumbs =
        ((vd['thumbnail'] as Map?)?['thumbnails'] as List?) ?? const [];
    final image = thumbs.isNotEmpty
        ? thumbs.last['url']?.toString()
        : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';

    if (desc.trim().length < 40) {
      final caps = ((j['captions'] as Map?)?['playerCaptionsTracklistRenderer']
              as Map?)?['captionTracks'] as List? ??
          const [];
      desc = await _ytTranscript(caps);
    }
    if (desc.trim().length < 40) {
      throw 'Il video YouTube non ha una ricetta nella descrizione né sottotitoli.';
    }
    return ExtractedPost(
      title: title,
      text: '$title\n\n$desc',
      imageUrl: image,
      sourceUrl: 'https://www.youtube.com/watch?v=$id',
    );
  }

  static Future<String> _ytTranscript(List caps) async {
    if (caps.isEmpty) return '';
    final pick = caps.firstWhere(
          (c) => RegExp(r'^it', caseSensitive: false)
              .hasMatch((c['languageCode'] ?? '').toString()),
          orElse: () => caps.firstWhere(
            (c) => RegExp(r'^en', caseSensitive: false)
                .hasMatch((c['languageCode'] ?? '').toString()),
            orElse: () => caps.first,
          ),
        );
    final baseUrl = pick['baseUrl']?.toString();
    if (baseUrl == null) return '';
    final r = await http.get(Uri.parse(baseUrl), headers: {'User-Agent': _iosUA});
    final parts = RegExp(r'<text[^>]*>([\s\S]*?)</text>')
        .allMatches(r.body)
        .map((m) => _decode(m.group(1) ?? ''));
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ---- TikTok: oEmbed pubblico via http ----
  static Future<ExtractedPost> _tiktok(String url) async {
    final r = await http.get(
      Uri.parse('https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}'),
      headers: {'User-Agent': _iosUA},
    );
    if (!r.body.trimLeft().startsWith('{')) {
      throw 'TikTok non raggiungibile o video non pubblico.';
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final caption = (j['title'] ?? '').toString().trim();
    if (caption.length < 40) {
      throw 'La didascalia del video TikTok è troppo corta o assente.';
    }
    return ExtractedPost(
      title: caption.split('\n').first,
      text: caption,
      imageUrl: j['thumbnail_url']?.toString(),
      sourceUrl: url,
    );
  }

  // ---- IG / FB / Pinterest / generico: webview headless sul dispositivo ----
  // Carica la pagina con l'IP e le sessioni loggate dell'utente e ne estrae la
  // didascalia dal DOM (og:description/og:title + testo visibile).
  static Future<ExtractedPost> _viaWebView(String url) async {
    final completer = Completer<ExtractedPost>();
    HeadlessInAppWebView? hw;

    Future<void> tryExtract(InAppWebViewController c) async {
      final raw = await c.evaluateJavascript(source: r'''
        (function () {
          function meta(p){var e=document.querySelector('meta[property="'+p+'"]')||document.querySelector('meta[name="'+p+'"]');return e?e.content:null;}
          var title = meta('og:title') || document.title || '';
          var desc  = meta('og:description') || '';
          var img   = meta('og:image') || '';
          // Testo visibile più lungo (didascalia del post) come fallback.
          var best = '';
          document.querySelectorAll('h1,h2,p,span,div[dir="auto"]').forEach(function(n){
            var t = (n.innerText||'').trim();
            if (t.length > best.length && t.length < 4000) best = t;
          });
          return JSON.stringify({title:title, desc:desc, img:img, best:best, href:location.href});
        })();
      ''');
      if (raw == null) return;
      final m = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final title = (m['title'] ?? '').toString().trim();
      final desc = (m['desc'] ?? '').toString().trim();
      final best = (m['best'] ?? '').toString().trim();
      // La didascalia migliore: og:description, o il testo visibile più lungo.
      final caption = (desc.length >= best.length ? desc : best).trim();
      if (caption.length < 40 && !completer.isCompleted) return; // riprova
      if (!completer.isCompleted) {
        completer.complete(ExtractedPost(
          title: title.isNotEmpty ? title : 'Ricetta',
          text: '$title\n\n$caption',
          imageUrl: (m['img'] ?? '').toString().isEmpty ? null : m['img'].toString(),
          sourceUrl: (m['href'] ?? url).toString(),
        ));
      }
    }

    hw = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        userAgent: _iosUA,
        javaScriptEnabled: true,
        clearCache: false, // mantiene i cookie di sessione dell'utente
      ),
      onLoadStop: (controller, _) async {
        // Un paio di tentativi: alcune pagine popolano la didascalia dopo il load.
        await Future.delayed(const Duration(seconds: 2));
        await tryExtract(controller);
        if (!completer.isCompleted) {
          await Future.delayed(const Duration(seconds: 3));
          await tryExtract(controller);
        }
      },
    );

    await hw.run();
    try {
      return await completer.future.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw 'Non riesco a leggere la didascalia del post.';
    } finally {
      await hw.dispose();
    }
  }

  static String _decode(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAllMapped(RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)));
}
