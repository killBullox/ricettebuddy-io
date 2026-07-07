import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'calendly_embed.dart';

/// Sezione "Consulenza Nutrizionale": presenta il servizio e permette di
/// prenotare una consulenza. La prenotazione avviene su Calendly.
// TODO: sostituire con l'URL Calendly reale di Beet-It.
const String kCalendlyUrl = 'https://calendly.com/beet-it/consulenza';

class ConsulenzaPage extends StatelessWidget {
  const ConsulenzaPage({super.key});

  static const _beet = Color(0xFFB5326B);
  static const _plum = Color(0xFF3A0A45);

  Future<void> _prenota(BuildContext context) async {
    final uri = Uri.parse(kCalendlyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire Calendly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.consulenzaTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Hero con logo tondo su fondo prugna
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_plum, _beet],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                SvgPicture.asset('assets/branding/beet_it_round.svg', width: 128),
                const SizedBox(height: 16),
                const Text('Consulenza Nutrizionale',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Un nutrizionista specializzato in alimentazione vegetale, '
                    'al tuo fianco.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Cosa include', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _Benefit(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Analisi personalizzata',
            text: 'Valutazione delle tue abitudini e dei tuoi obiettivi '
                '(dimagrimento, sport, salute, transizione vegana).',
          ),
          const _Benefit(
            icon: Icons.restaurant_menu,
            title: 'Piano alimentare su misura',
            text: 'Menù settimanali bilanciati, 100% vegetali, integrati con '
                'le ricette che salvi in Beet-It.',
          ),
          const _Benefit(
            icon: Icons.monitor_heart_outlined,
            title: 'Monitoraggio e follow-up',
            text: 'Controlli periodici per adattare il percorso ai tuoi '
                'progressi.',
          ),
          const _Benefit(
            icon: Icons.videocam_outlined,
            title: 'Videochiamata',
            text: 'Comodamente da casa, quando vuoi tu.',
          ),

          const SizedBox(height: 28),
          Text('Prenota', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (kIsWeb)
            // Calendario Calendly incorporato: prenoti senza uscire dall'app.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 720,
                color: Colors.white,
                child: buildCalendlyEmbed(kCalendlyUrl),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => _prenota(context),
              icon: const Icon(Icons.event_available),
              label: Text(l.bookConsultation),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _beet,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _prenota(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Apri Calendly a schermo intero'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Benefit({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFB5326B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFB5326B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: Theme.of(context).hintColor, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
