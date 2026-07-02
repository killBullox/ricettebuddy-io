import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe.dart';
import '../../data/repositories/creative_repository.dart';
import '../../data/repositories/recipe_repository.dart';

/// "Idee nuove": chiama l'Edge Function di generazione e mostra bozze non
/// salvate, che l'utente può salvare nel ricettario.
class GeneratedIdeasPage extends ConsumerStatefulWidget {
  const GeneratedIdeasPage({super.key});

  @override
  ConsumerState<GeneratedIdeasPage> createState() => _GeneratedIdeasPageState();
}

class _GeneratedIdeasPageState extends ConsumerState<GeneratedIdeasPage> {
  bool _loading = false;
  String? _error;
  List<Recipe> _ideas = [];

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ideas = await ref.read(creativeRepositoryProvider).generateIdeas();
      setState(() => _ideas = ideas);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idee nuove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _generate,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Lo Chef sta pensando…'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Errore: $_error')))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [for (final r in _ideas) _IdeaCard(recipe: r)],
                ),
    );
  }
}

class _IdeaCard extends ConsumerWidget {
  final Recipe recipe;
  const _IdeaCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Ingredienti',
                style: Theme.of(context).textTheme.labelLarge),
            for (final ing in recipe.ingredients) Text('• ${ing.rawText}'),
            const SizedBox(height: 8),
            Text('Preparazione',
                style: Theme.of(context).textTheme.labelLarge),
            for (final s in recipe.steps) Text('${s.position + 1}. ${s.text}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Salva nel ricettario'),
                onPressed: () async {
                  await ref.read(recipeRepositoryProvider).create(recipe);
                  ref.invalidate(recipeListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Salvata nel ricettario')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
