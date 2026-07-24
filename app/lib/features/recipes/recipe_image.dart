import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../config.dart';

/// Immagine di una ricetta: gestisce sia asset locali ('assets/...') sia URL
/// remoti, con fallback grazioso all'icona se manca o non carica.
class RecipeImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final double iconSize;

  const RecipeImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: iconSize),
    );

    final p = path;
    if (p == null || p.isEmpty) return fallback;

    if (p.startsWith('assets/')) {
      return Image.asset(
        p,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    // Percorsi relativi (es. "media/r12.jpg") = foto salvate sul backend.
    // URL assoluti: su mobile si caricano DIRETTAMENTE (nessun problema di CORS
    // ed evita di dipendere dal proxy del backend, che può non rispondere); solo
    // sul web passano dal proxy same-origin (/img?u=...) perché i CDN remoti non
    // sempre hanno gli header CORS.
    final String url;
    if (p.startsWith('http')) {
      url = kIsWeb
          ? Config.backendUri('img?u=${Uri.encodeQueryComponent(p)}').toString()
          : p;
    } else {
      url = Config.backendUri(p).toString();
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
