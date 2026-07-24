import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/plan_push_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';

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

  final _kcal = TextEditingController(text: '2000');
  final _pref = TextEditingController();
  final _avoid = TextEditingController();
  bool _colazione = true;
  bool _snack = true;
  bool _dessert = false;
  bool _frutta = false;
  int _settimane = 1;

  List<String> _csv(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  void dispose() {
    _kcal.dispose();
    _pref.dispose();
    _avoid.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      // mappa codice base -> id ricetta (le voci del piano puntano alle basi)
      final recipes = await ref.read(recipeRepositoryProvider).list();
      final idByCode = <String, String>{
        for (final r in recipes)
          if (r.baseCode != null && r.id != null) r.baseCode!: r.id!,
      };
      final n = await ref.read(planPushRepositoryProvider).generateAndFill(
        weekStart: widget.weekStart,
        idByBaseCode: idByCode,
        input: {
          'kcal': int.tryParse(_kcal.text.trim()),
          'preferiti': _csv(_pref.text),
          'evitare': _csv(_avoid.text),
          'colazione': _colazione,
          'spuntini': _snack,
          'dolci': _dessert,
          'frutta': _frutta,
          'settimane': _settimane,
        },
      );
      if (!mounted) return;
      // porta la vista sulle settimane generate
      ref.invalidate(mealPlanWeekProvider(widget.weekStart));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_settimane > 1
            ? 'Piano generato: $n piatti su $_settimane settimane.'
            : 'Piano generato: $n piatti nella settimana.'),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Generazione non riuscita: $e')));
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
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _kcal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kcal al giorno',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _settimane,
                    decoration: const InputDecoration(
                      labelText: 'Settimane',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final w in [1, 2, 3, 4])
                        DropdownMenuItem(value: w, child: Text('$w')),
                    ],
                    onChanged: (v) => setState(() => _settimane = v ?? 1),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _pref,
                decoration: const InputDecoration(
                  labelText: 'Ingredienti preferiti',
                  hintText: 'es. ceci, pomodoro, zucca',
                  helperText: 'separati da virgola',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _avoid,
                decoration: const InputDecoration(
                  labelText: 'Ingredienti da evitare',
                  hintText: 'es. aglio, cipolla, glutine',
                  helperText: 'separati da virgola',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Colazione'),
                value: _colazione,
                onChanged: (v) => setState(() => _colazione = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Spuntini'),
                value: _snack,
                onChanged: (v) => setState(() => _snack = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dolci'),
                value: _dessert,
                onChanged: (v) => setState(() => _dessert = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Frutta'),
                value: _frutta,
                onChanged: (v) => setState(() => _frutta = v),
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
