import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import 'auto_planner.dart';

/// Sheet "pianifica settimana": tre modalità.
/// 1. Manuale (com'è ora: aggiungi tu le ricette ai pasti)
/// 2. Automatica: filtri + tetto calorico → il piano si riempie da solo
/// 3. Da consulenza nutrizionale (fase successiva — disattivata)
class PlanGenerateSheet extends ConsumerStatefulWidget {
  final DateTime weekStart;
  const PlanGenerateSheet({super.key, required this.weekStart});

  @override
  ConsumerState<PlanGenerateSheet> createState() => _PlanGenerateSheetState();
}

class _PlanGenerateSheetState extends ConsumerState<PlanGenerateSheet> {
  bool _auto = false; // config automatica aperta
  bool _busy = false;

  int? _maxKcal = 1800;
  final Set<String> _excl = {};
  final Set<String> _labels = {};
  bool _snack = false;
  bool _dessert = false;

  void _toggle(Set<String> s, String v) =>
      setState(() => s.contains(v) ? s.remove(v) : s.add(v));

  Future<void> _generate() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final recipes = await ref.read(recipeRepositoryProvider).list();
      final existing = await ref
          .read(mealPlanRepositoryProvider)
          .forWeek(widget.weekStart);
      final res = await generateAutoPlan(
        planRepo: ref.read(mealPlanRepositoryProvider),
        recipes: recipes,
        existing: existing,
        weekStart: widget.weekStart,
        opts: AutoPlanOptions(
          maxKcalPerDay: _maxKcal,
          excludeAllergens: _excl,
          labels: _labels,
          includeSnack: _snack,
          includeDessert: _dessert,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.complete
            ? l.planResultAll('${res.filled}')
            : l.planResultPartial('${res.filled}', '${res.total - res.filled}')),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.planHowTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            // 1. Manuale
            _ModeTile(
              icon: Icons.edit_calendar,
              title: l.planManualTitle,
              subtitle: l.planManualDesc,
              selected: !_auto,
              onTap: () => Navigator.of(context).pop(),
            ),
            // 2. Automatica
            _ModeTile(
              icon: Icons.auto_awesome,
              title: l.planAutoTitle,
              subtitle: l.planAutoDesc,
              selected: _auto,
              onTap: () => setState(() => _auto = true),
            ),
            // 3. Consulenza (fase successiva)
            _ModeTile(
              icon: Icons.health_and_safety,
              title: l.planConsultTitle,
              subtitle: l.planConsultDesc,
              enabled: false,
              trailing: Chip(
                label: Text(l.planComingSoon,
                    style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (_auto) ...[
              const Divider(height: 24),
              Text(l.planMaxKcal,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final k in [1400, 1800, 2200])
                  ChoiceChip(
                    label: Text('$k kcal'),
                    selected: _maxKcal == k,
                    onSelected: (_) => setState(() => _maxKcal = k),
                  ),
                ChoiceChip(
                  label: Text(l.planNoLimit),
                  selected: _maxKcal == null,
                  onSelected: (_) => setState(() => _maxKcal = null),
                ),
              ]),
              const SizedBox(height: 14),
              Text(l.filterNoAllergens,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final e in {
                  l.allergenGluten: 'glutine',
                  l.allergenSoy: 'soia',
                  l.allergenNuts: 'frutta a guscio',
                  l.allergenLactose: 'lattosio',
                }.entries)
                  FilterChip(
                    label: Text(e.key),
                    selected: _excl.contains(e.value),
                    onSelected: (_) => _toggle(_excl, e.value),
                  ),
              ]),
              const SizedBox(height: 14),
              Text(l.filterLabels,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final key in Recipe.nutritionLabelKeys)
                  FilterChip(
                    label: Text(nutritionLabelTextOf(l, key)),
                    selected: _labels.contains(key),
                    onSelected: (_) => _toggle(_labels, key),
                  ),
              ]),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.planIncludeSnack),
                value: _snack,
                onChanged: (v) => setState(() => _snack = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.planIncludeDessert),
                value: _dessert,
                onChanged: (v) => setState(() => _dessert = v),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(l.planGenerateBtn),
                  onPressed: _busy ? null : _generate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Testo localizzato label nutrizionale (evita import incrociato).
String nutritionLabelTextOf(AppLocalizations l, String key) => switch (key) {
      'HIGH PROTEIN' => l.labelHighProtein,
      'LOW CARB' => l.labelLowCarb,
      'LIGHT' => l.labelLight,
      'HIGH FIBER' => l.labelHighFiber,
      _ => key,
    };

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected ? const Color(0xFFF7E4EE) : null,
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon,
            color: selected ? const Color(0xFFB5326B) : null),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: trailing,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
