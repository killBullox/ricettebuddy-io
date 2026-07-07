// Embed Calendly inline. Su web usa un <iframe> (nessuna uscita dall'app);
// su mobile un fallback (la WebView arriverà col build nativo).
export 'calendly_embed_stub.dart'
    if (dart.library.html) 'calendly_embed_web.dart';
