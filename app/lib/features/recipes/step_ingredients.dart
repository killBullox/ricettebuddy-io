import 'package:flutter/material.dart';

import '../../data/models/ingredient.dart';
import 'ingredient_avatar.dart';

/// Striscia orizzontale con le FOTO degli ingredienti citati in un passaggio
/// del procedimento (foto realistiche grandi + nome sotto, stile ricettario).
class StepIngredients extends StatelessWidget {
  final String stepText;
  final List<Ingredient> ingredients;
  final double size;
  final Color labelColor;

  const StepIngredients({
    super.key,
    required this.stepText,
    required this.ingredients,
    this.size = 72,
    this.labelColor = const Color(0xFF3A0E2A),
  });

  // Parole che non identificano l'ingrediente (qualificatori comuni).
  static const _stop = {
    'di', 'del', 'della', 'dello', 'con', 'per', 'una', 'uno', 'the',
    'fresco', 'fresca', 'freschi', 'fresche', 'secco', 'secca', 'nero',
    'nera', 'neri', 'nere', 'rosso', 'rossa', 'rossi', 'rosse', 'bianco',
    'bianca', 'tritato', 'tritata', 'cotto', 'cotta', 'cotti', 'grattugiato',
    'grattugiata', 'extra', 'vergine', 'tipo', 'q.b', 'qb',
  };

  /// Ingredienti citati nel testo del passaggio (match sul sostantivo
  /// principale del nome normalizzato, tollerante a singolare/plurale).
  static List<Ingredient> matchIn(String text, List<Ingredient> all) {
    final t = text.toLowerCase();
    final out = <Ingredient>[];
    final seen = <String>{};
    for (final ing in all) {
      final name = (ing.normalizedName ?? ing.rawText).toLowerCase().trim();
      if (name.isEmpty || seen.contains(name)) continue;
      final tokens = name
          .split(RegExp(r"[^a-zàèéìòù]+"))
          .where((w) => w.length >= 3 && !_stop.contains(w))
          .toList();
      if (tokens.isEmpty) continue;
      final matched = tokens.any((w) {
        // stem: toglie l'ultima vocale → pomodoro/pomodori, cipolla/cipolle
        final stem = w.length >= 5 ? w.substring(0, w.length - 1) : w;
        return RegExp('\\b${RegExp.escape(stem)}\\w*', caseSensitive: false)
            .hasMatch(t);
      });
      if (matched) {
        out.add(ing);
        seen.add(name);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final matched = matchIn(stepText, ingredients);
    if (matched.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final ing in matched)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                width: size + 14,
                child: Column(
                  children: [
                    IngredientAvatar(
                        raw: ing.rawText, img: ing.img, size: size),
                    const SizedBox(height: 5),
                    Text(
                      ing.normalizedName ?? ing.rawText,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: labelColor),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
