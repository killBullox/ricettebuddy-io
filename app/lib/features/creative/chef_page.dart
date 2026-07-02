import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/creative_repository.dart';
import '../recipes/recipe_detail_page.dart';
import 'generated_ideas.dart';
import 'pantry_page.dart';

/// "Chef creativo": due sezioni.
///  1. "Puoi già farle" — ricette del ricettario fattibili con la dispensa (RPC, no AI).
///  2. "Idee nuove" — generate dall'AI su dispensa + gusti (Edge Function, premium).
class ChefPage extends ConsumerWidget {
  const ChefPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doable = ref.watch(doableRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef creativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.kitchen),
            tooltip: 'Dispensa',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PantryPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(doableRecipesProvider),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _SectionHeader(
              icon: Icons.check_circle_outline,
              title: 'Puoi già farle',
              subtitle: 'Ricette del tuo ricettario fattibili con la dispensa',
            ),
            doable.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Errore: $e'),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aggiungi ingredienti alla dispensa (icona in alto) '
                      'per vedere cosa puoi cucinare.',
                    ),
                  );
                }
                return Column(
                  children: [for (final d in list) _DoableTile(doable: d)],
                );
              },
            ),
            const Divider(height: 32),
            const _SectionHeader(
              icon: Icons.auto_awesome,
              title: 'Idee nuove',
              subtitle: 'Generate dall\'AI sui tuoi gusti e ciò che hai in casa',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Genera idee di ricetta'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GeneratedIdeasPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoableTile extends StatelessWidget {
  final DoableRecipe doable;
  const _DoableTile({required this.doable});

  @override
  Widget build(BuildContext context) {
    final pct = (doable.coverage * 100).round();
    final missing = doable.missing;
    return ListTile(
      title: Text(doable.title),
      subtitle: Text(
        missing.isEmpty
            ? 'Hai tutti gli ingredienti 🎉'
            : 'Ti manca: ${missing.take(4).join(', ')}'
                '${missing.length > 4 ? '…' : ''}',
      ),
      trailing: _CoverageBadge(pct: pct),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipeId: doable.recipeId),
        ),
      ),
    );
  }
}

class _CoverageBadge extends StatelessWidget {
  final int pct;
  const _CoverageBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 100
        ? Colors.green
        : pct >= 80
            ? Colors.lightGreen
            : Colors.orange;
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text('$pct%',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
