import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'ingredient_icon.dart';

/// Icona di ripiego (solo per i rari ingredienti senza né foto né emoji):
/// scelta per CATEGORIA dal nome, così non è mai una foglia generica.
IconData fallbackIconFor(String raw) {
  final t = raw.toLowerCase();
  if (RegExp(r'lievito|bicarbonat|amido|fecola|maizena|farina').hasMatch(t)) {
    return Icons.grain; // polveri
  }
  if (RegExp(r'salsa|aceto|sciroppo|brodo|sugo|passata|worcest|tabasco|senape')
      .hasMatch(t)) {
    return Icons.water_drop_outlined; // liquidi/salse
  }
  if (RegExp(r'spezi|masala|berbere|ras el|curry|zafferan|paprik|pepe|sumac|semi ')
      .hasMatch(t)) {
    return Icons.grain; // spezie in polvere/semi
  }
  return Icons.restaurant; // generico "alimento"
}

/// Avatar ingrediente. Priorità: FOTO realistica dalla libreria Spoonacular
/// (slug [img] fornito dal server, oppure derivato dal nome per frutta secca,
/// semi, spezie, tofu, gocce di cioccolato...); altrimenti emoji; altrimenti
/// una piccola icona LOCALE. Condiviso tra scheda ricetta, spesa e dispensa.
class IngredientAvatar extends StatelessWidget {
  final String raw;
  final String? img; // slug Spoonacular, es. "red-onion"
  final double size;
  const IngredientAvatar({super.key, required this.raw, this.img, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final emoji = ingredientEmoji(raw);
    final radius = size * 0.28;

    // Fallback SENZA rete: emoji se c'è, altrimenti una foglia (icona locale),
    // così non resta mai il "pallino" di un'icona che non arriva.
    Widget fallback() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEDE6),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: emoji.isEmpty
              ? Icon(fallbackIconFor(raw),
                  size: size * 0.54, color: const Color(0xFF9A8F86))
              : Text(emoji, style: TextStyle(fontSize: size * 0.53)),
        );

    // Slug esplicito dal server, altrimenti derivato dal nome dell'ingrediente.
    final slug = (img != null && img!.trim().isNotEmpty)
        ? img!.trim()
        : spoonacularSlug(raw);
    if (slug == null || slug.isEmpty) return fallback();
    final file = slug.contains('.') ? slug : '$slug.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: 'https://img.spoonacular.com/ingredients_250x250/$file',
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
