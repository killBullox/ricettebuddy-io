import 'package:flutter/material.dart';

import '../../data/models/diet.dart';

/// Mostra i regimi soddisfatti da una ricetta come piccoli chip.
class DietBadges extends StatelessWidget {
  final List<String> dietTags;
  const DietBadges({super.key, required this.dietTags});

  @override
  Widget build(BuildContext context) {
    final diets = Diet.fromNames(dietTags);
    if (diets.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final d in diets)
          Chip(
            label: Text(d.label, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
