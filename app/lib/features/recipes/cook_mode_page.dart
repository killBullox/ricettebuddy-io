import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/recipe.dart';
import '../../data/models/recipe_step.dart';
import 'recipe_image.dart';

/// Cook Mode: procedimento a schermo intero, un passo alla volta, con timer
/// automatico quando il passo cita dei minuti.
class CookModePage extends StatefulWidget {
  final Recipe recipe;
  const CookModePage({super.key, required this.recipe});

  @override
  State<CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends State<CookModePage> {
  final _controller = PageController();
  int _index = 0;

  Timer? _timer;
  int _remaining = 0; // secondi
  bool get _running => _timer?.isActive ?? false;

  List<RecipeStep> get _steps =>
      [...widget.recipe.steps]..sort((a, b) => a.position - b.position);

  int? _minutesIn(String text) {
    final m = RegExp(r'(\d+)\s*(minut|min\b)').firstMatch(text.toLowerCase());
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() => _remaining = minutes * 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏰ Timer finito!')),
        );
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF17321F),
      body: SafeArea(
        child: Column(
          children: [
            // header: titolo + progress + chiudi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / steps.length,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(scheme.secondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Passo ${_index + 1} di ${steps.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() { _index = i; _stopTimer(); }),
                itemBuilder: (_, i) {
                  final s = steps[i];
                  final mins = _minutesIn(s.text);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}',
                            style: TextStyle(color: scheme.secondary, fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
                        const SizedBox(height: 12),
                        if (s.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: RecipeImage(path: s.imageUrl, width: double.infinity, height: 200),
                            ),
                          ),
                        Text(s.text,
                            style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.4)),
                        if (mins != null) ...[
                          const SizedBox(height: 24),
                          _TimerBox(
                            minutes: mins,
                            running: _running,
                            remaining: _remaining,
                            fmt: _fmt,
                            onStart: () => _startTimer(mins),
                            onStop: _stopTimer,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // nav
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_index > 0)
                    OutlinedButton.icon(
                      onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Indietro', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _index < steps.length - 1
                        ? () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
                        : () => Navigator.of(context).pop(),
                    icon: Icon(_index < steps.length - 1 ? Icons.arrow_forward : Icons.check),
                    label: Text(_index < steps.length - 1 ? 'Avanti' : 'Fine'),
                    style: FilledButton.styleFrom(backgroundColor: scheme.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerBox extends StatelessWidget {
  final int minutes;
  final bool running;
  final int remaining;
  final String Function(int) fmt;
  final VoidCallback onStart;
  final VoidCallback onStop;
  const _TimerBox({
    required this.minutes,
    required this.running,
    required this.remaining,
    required this.fmt,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            running ? fmt(remaining) : '$minutes:00',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: running ? onStop : onStart,
            child: Text(running ? 'Ferma' : 'Avvia timer'),
          ),
        ],
      ),
    );
  }
}
