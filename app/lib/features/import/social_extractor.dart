import 'dart:async';
import 'dart:convert';

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

/// Facebook richiede login per leggere la didascalia dei reel: segnala che
/// serve collegare l'account (gestito nella UI con una webview di login).
class FacebookLoginNeeded implements Exception {}

/// Estrae il contenuto di un post social **sul dispositivo dell'utente** con una
/// semplice fetch HTTP (User-Agent da crawler): veloce, niente webview. YouTube
/// e TikTok usano le loro API pubbliche. Facebook è gestito a parte (login).
class SocialExtractor {
  static const _iosUA =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile Safari/604.1';
  // Gli UA da crawler ricevono i meta og: (anteprime link) senza muri.
  static const _crawlerUA = 'Mozilla/5.0 (compatible; Twitterbot/1.0)';

  static Future<ExtractedPost> extract(String url) async {
    final u = url.trim();
    if (RegExp(r'youtube\.com|youtu\.be', caseSensitive: false).hasMatch(u)) {
      return _youtube(u);
    }
    if (RegExp(r'tiktok\.com', caseSensitive: false).hasMatch(u)) {
      return _tiktok(u);
    }
    // Instagram / Pinterest / siti generici: fetch HTTP + meta og:.
    return _viaHttp(u);
  }

  static bool isFacebook(String url) =>
      RegExp(r'facebook\.com|fb\.watch', caseSensitive: false).hasMatch(url);

  // ---- Fetch HTTP + parsing meta og: (veloce) ----
  static String? _meta(String html, String prop) {
    final a = RegExp(
            '<meta[^>]+(?:property|name)=["\']' + prop + '["\'][^>]+content=["\']([^"\']*)["\']',
            caseSensitive: false)
        .firstMatch(html);
    if (a != null) return a.group(1);
    final b = RegExp(
            '<meta[^>]+content=["\']([^"\']*)["\'][^>]+(?:property|name)=["\']' + prop + '["\']',
            caseSensitive: false)
        .firstMatch(html);
    return b?.group(1);
  }

  static Future<ExtractedPost> _viaHttp(String url) async {
    final r = await http
        .get(Uri.parse(url), headers: {'User-Agent': _crawlerUA})
        .timeout(const Duration(seconds: 15));
    final html = r.body;
    final title = _htmlDecode(_meta(html, 'og:title') ?? '');
    final desc = _htmlDecode(_meta(html, 'og:description') ?? '');
    final img = _meta(html, 'og:image');
    final ogUrl = _meta(html, 'og:url') ?? url;

    var caption = desc.trim();
    if (caption.length < 40) {
      final slug = _deslug(ogUrl);
      if (slug.length > caption.length) caption = slug;
    }
    if (caption.length < 40) {
      throw 'Non riesco a leggere la ricetta da questo link.';
    }
    return ExtractedPost(
      title: title.isNotEmpty ? title : 'Ricetta',
      text: '$title\n\n$caption',
      imageUrl: (img == null || img.isEmpty) ? null : img,
      sourceUrl: ogUrl,
    );
  }

  // ---- YouTube: API interna InnerTube (client MWEB) ----
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
    ).timeout(const Duration(seconds: 15));
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
    return RegExp(r'<text[^>]*>([\s\S]*?)</text>')
        .allMatches(r.body)
        .map((m) => _htmlDecode(m.group(1) ?? ''))
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ---- TikTok: oEmbed pubblico ----
  static Future<ExtractedPost> _tiktok(String url) async {
    final r = await http.get(
      Uri.parse('https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}'),
      headers: {'User-Agent': _iosUA},
    ).timeout(const Duration(seconds: 15));
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

  static String _deslug(String ogUrl) {
    try {
      final segs = Uri.parse(ogUrl)
          .pathSegments
          .where((s) => s.contains('-') && s.length > 12)
          .toList();
      return segs.isEmpty ? '' : segs.last.replaceAll('-', ' ');
    } catch (_) {
      return '';
    }
  }

  static String _htmlDecode(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAllMapped(RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)));
}
