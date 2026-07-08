import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config.dart';
import 'ingredient_icon.dart';

/// Avatar ingrediente: emoji se disponibile, altrimenti icona SVG generata
/// dall'AI lato server (creata una volta e riusata dalla cache). Condiviso tra
/// scheda ricetta, lista della spesa e dispensa.
class IngredientAvatar extends StatelessWidget {
  final String raw;
  final double size;
  const IngredientAvatar({super.key, required this.raw, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final emoji = ingredientEmoji(raw);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDE6),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: emoji.isEmpty
          ? _AiIngredientIcon(raw: raw, size: size * 0.73)
          : Text(emoji, style: TextStyle(fontSize: size * 0.53)),
    );
  }
}

/// Icona SVG dell'ingrediente servita da /api/ingredient-icon (cache-first).
/// Mostra un pallino neutro mentre carica o se la generazione non riesce.
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
    return SvgPicture.network(
      url,
      width: size,
      height: size,
      placeholderBuilder: (_) => dot,
    );
  }
}
