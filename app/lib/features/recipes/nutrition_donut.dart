import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Grafico a ciambella dei macronutrienti (proteine/carboidrati/grassi) con
/// etichette dirette. Palette categoriale validata (CVD-safe).
/// I valori [n] sono PER PORZIONE; con [servings] mostra anche il totale.
class NutritionDonut extends StatelessWidget {
  final Map<String, dynamic> n;
  final int? servings;
  const NutritionDonut({super.key, required this.n, this.servings});

  static const _protein = Color(0xFF2A78D6); // blu
  static const _carbs = Color(0xFF1BAF7A); // acqua
  static const _fat = Color(0xFFEDA100); // giallo
  static const _fiber = Color(0xFF8A7BD8); // viola (secondario)

  double _g(String k) => (n[k] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = _g('protein_g'), c = _g('carbs_g'), f = _g('fat_g');
    final fiber = _g('fiber_g');
    final kcal = (n['kcal'] as num?)?.round() ?? 0;
    final total = (p + c + f) == 0 ? 1 : (p + c + f);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valori nutrizionali',
              style: Theme.of(context).textTheme.titleMedium),
          Text('per porzione', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: -90,
                      sections: [
                        _sec(p / total, _protein),
                        _sec(c / total, _carbs),
                        _sec(f / total, _fat),
                      ],
                    )),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$kcal',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
                        const Text('kcal', style: TextStyle(fontSize: 12, color: Color(0xFF898781))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _legend('Proteine', p, _protein),
                    const SizedBox(height: 8),
                    _legend('Carboidrati', c, _carbs),
                    const SizedBox(height: 8),
                    _legend('Grassi', f, _fat),
                    if (fiber > 0) ...[
                      const SizedBox(height: 8),
                      _legend('Fibre', fiber, _fiber),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Totale ricetta = per porzione × porzioni (trasparenza sui numeri).
          if (servings != null && servings! > 1) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFAF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Totale ricetta (${servings!} porzioni): '
                '${(kcal * servings!)} kcal · '
                'P ${(p * servings!).round()} g · '
                'C ${(c * servings!).round()} g · '
                'G ${(f * servings!).round()} g',
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).hintColor,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PieChartSectionData _sec(double frac, Color color) => PieChartSectionData(
        value: frac <= 0 ? 0.001 : frac,
        color: color,
        radius: 20,
        showTitle: false,
      );

  Widget _legend(String label, double grams, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text('${grams.toStringAsFixed(grams % 1 == 0 ? 0 : 1)} g',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
      ],
    );
  }
}
