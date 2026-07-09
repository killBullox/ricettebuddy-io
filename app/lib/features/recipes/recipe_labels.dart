import 'package:flutter/material.dart';

import '../../data/models/diet.dart';
import '../../data/models/recipe.dart';
import '../../l10n/app_localizations.dart';

/// Testo localizzato di una label nutrizionale (chiave stabile → testo lingua).
String nutritionLabelText(AppLocalizations l, String key) => switch (key) {
      'HIGH PROTEIN' => l.labelHighProtein,
      'LOW CARB' => l.labelLowCarb,
      'LIGHT' => l.labelLight,
      'HIGH FIBER' => l.labelHighFiber,
      _ => key,
    };

/// Testo localizzato di un regime (per ora gestiamo il caso comune "vegan").
String dietLabelText(AppLocalizations l, Diet d) =>
    d == Diet.vegan ? l.labelVegan : d.label;

/// Etichette di una ricetta: badge "Veganized" (se veganizzata), i regimi
/// (Vegano, …) e le label nutrizionali (HIGH PROTEIN, LOW CARB…). Localizzate.
class RecipeLabels extends StatelessWidget {
  final Recipe recipe;
  const RecipeLabels({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final diets = Diet.fromNames(recipe.dietTags).toList();
    final nutri = recipe.nutritionLabels;
    if (!recipe.isVeganized && diets.isEmpty && nutri.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (recipe.isVeganized)
          _Pill(
              text: l.badgeVeganized,
              icon: Icons.eco,
              bg: const Color(0xFF2E7D32),
              fg: Colors.white),
        for (final d in diets)
          _Pill(
              text: dietLabelText(l, d),
              bg: const Color(0xFFEFEDE6),
              fg: const Color(0xFF3A0E2A)),
        for (final n in nutri)
          _Pill(
              text: nutritionLabelText(l, n),
              bg: const Color(0xFFFFF0D6),
              fg: const Color(0xFF9A6B00)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, this.icon, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 3),
            ],
            Text(text,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );
}
