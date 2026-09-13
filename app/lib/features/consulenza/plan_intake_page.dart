import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plan_request_repository.dart';

/// Form dati antropometrici per richiedere un piano SENZA videoconsulto.
/// Alla conferma crea una richiesta in `plan_requests` che il team elabora.
class PlanIntakePage extends ConsumerStatefulWidget {
  const PlanIntakePage({super.key});

  @override
  ConsumerState<PlanIntakePage> createState() => _PlanIntakePageState();
}

class _PlanIntakePageState extends ConsumerState<PlanIntakePage> {
  static const _beet = Color(0xFFB5326B);
  final _form = GlobalKey<FormState>();

  DateTime? _birth;
  String? _sex; // F | M | Altro
  String? _goal; // dimagrimento | massa | abitudini
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _target = TextEditingController();
  final _weightHistory = TextEditingController();
  final _pathologies = TextEditingController();
  final _activity = TextEditingController();
  final _preferences = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_height, _weight, _target, _weightHistory, _pathologies, _activity, _preferences]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5, now.month, now.day),
      helpText: 'Data di nascita',
    );
    if (d != null) setState(() => _birth = d);
  }

  Future<void> _submit() async {
    // validazioni che il Form non copre (date/scelte)
    final missing = <String>[];
    if (_birth == null) missing.add('data di nascita');
    if (_sex == null) missing.add('sesso');
    if (_goal == null) missing.add('obiettivo');
    if (!(_form.currentState?.validate() ?? false) || missing.isNotEmpty) {
      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compila: ${missing.join(', ')}.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(planRequestRepositoryProvider).submit(
        wantsVideo: false,
        data: {
          'birth_date': _birth!.toIso8601String().split('T').first,
          'sex': _sex,
          'height_cm': double.tryParse(_height.text.replaceAll(',', '.')),
          'weight_kg': double.tryParse(_weight.text.replaceAll(',', '.')),
          'target_weight_kg': double.tryParse(_target.text.replaceAll(',', '.')),
          'weight_history': _weightHistory.text.trim(),
          'pathologies': _pathologies.text.trim(),
          'activity': _activity.text.trim(),
          'preferences': _preferences.text.trim(),
          'goal': _goal,
        },
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Richiesta inviata'),
          content: const Text(
              'Grazie! Il team di consulenza nutrizionale preparerà il tuo piano '
              'su misura e lo troverai nell\'app. Ti avviseremo appena è pronto.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // chiudi dialog
                Navigator.of(context).pop(); // torna indietro
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final birthText = _birth == null
        ? 'Seleziona'
        : '${_birth!.day.toString().padLeft(2, '0')}/${_birth!.month.toString().padLeft(2, '0')}/${_birth!.year}';
    final num3 = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Piano senza videoconsulto')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _beet.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Senza videoconsulto, il nutrizionista prepara il piano dai dati '
                'che inserisci qui. Compila tutto con cura: più sono precisi, '
                'migliore sarà il piano.',
                style: TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ),
            const SizedBox(height: 18),

            // Data di nascita
            InkWell(
              onTap: _pickBirth,
              child: InputDecorator(
                decoration: _dec('Data di nascita *'),
                child: Row(
                  children: [
                    Text(birthText,
                        style: TextStyle(
                            color: _birth == null ? Theme.of(context).hintColor : null)),
                    const Spacer(),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sesso
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: _dec('Sesso *'),
              items: const [
                DropdownMenuItem(value: 'F', child: Text('Femmina')),
                DropdownMenuItem(value: 'M', child: Text('Maschio')),
                DropdownMenuItem(value: 'Altro', child: Text('Altro / preferisco non dirlo')),
              ],
              onChanged: (v) => setState(() => _sex = v),
            ),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: num3,
                  decoration: _dec('Altezza (cm) *'),
                  validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Obbligatorio' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: num3,
                  decoration: _dec('Peso (kg) *'),
                  validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Obbligatorio' : null,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: num3,
              decoration: _dec('Peso desiderato (kg)', hint: 'facoltativo'),
            ),
            const SizedBox(height: 14),

            // Obiettivo
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: _dec('Obiettivo del piano *'),
              items: const [
                DropdownMenuItem(value: 'dimagrimento', child: Text('Dimagrimento')),
                DropdownMenuItem(value: 'massa', child: Text('Massa muscolare')),
                DropdownMenuItem(value: 'abitudini', child: Text('Migliorare le abitudini alimentari')),
              ],
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _activity,
              minLines: 2, maxLines: 4,
              decoration: _dec('Attività fisica *', hint: 'Livello e tipo (es. sedentaria; corsa 3x/sett)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weightHistory,
              minLines: 2, maxLines: 4,
              decoration: _dec('Storia del peso *', hint: 'Variazioni recenti, diete passate...'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pathologies,
              minLines: 2, maxLines: 4,
              decoration: _dec('Patologie / farmaci *', hint: 'Scrivi "nessuna" se non ne hai'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _preferences,
              minLines: 2, maxLines: 4,
              decoration: _dec('Gusti / intolleranze *', hint: 'Cibi che ami/eviti, intolleranze, allergie'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Invia richiesta'),
              style: FilledButton.styleFrom(
                backgroundColor: _beet,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Text('* campi obbligatori',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
