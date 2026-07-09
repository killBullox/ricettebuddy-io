import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config.dart';
import 'ingredient_icon.dart';

/// Avatar ingrediente. Priorità: FOTO realistica dalla libreria Spoonacular
/// (se l'enrich ha fornito lo slug [img]); altrimenti emoji; altrimenti icona
/// SVG generata dall'AI. Condiviso tra scheda ricetta, spesa e dispensa.
class IngredientAvatar extends StatelessWidget {
  final String raw;
  final String? img; // slug Spoonacular, es. "red-onion"
  final double size;
  const IngredientAvatar({super.key, required this.raw, this.img, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final emoji = ingredientEmoji(raw);
    final radius = size * 0.28;

    Widget fallback() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEDE6),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: emoji.isEmpty
              ? _AiIngredientIcon(raw: raw, size: size * 0.73)
              : Text(emoji, style: TextStyle(fontSize: size * 0.53)),
        );

    final slug = img?.trim();
    if (slug == null || slug.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: 'https://img.spoonacular.com/ingredients_250x250/$slug.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      ),
    );
  }
}

/// Icona SVG dell'ingrediente servita da /api/ingredient-icon (cache-first).
class _AiIngredientIcon extends StatelessWidget {
  final String raw;
  final double size;
  const _AiIngredientIcon({required this.raw, required this.size});

  @override
  Widget build(BuildContext context) {
    final dot = Icon(Icons.circle, size: size * 0.32, color: Theme.of(context).hintColor);
    final url = Config
        .backendUri('api/ingredient-icon?name=${Uri.encodeQueryComponent(raw)}')
        .toString();
    return SvgPicture.network(url, width: size, height: size, placeholderBuilder: (_) => dot);
  }
}
