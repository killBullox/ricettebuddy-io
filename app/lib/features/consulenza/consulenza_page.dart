import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'calendly_embed.dart';
import 'calendly_page.dart';

/// Sezione "Consulenza Nutrizionale": due eventi prenotabili su Calendly.
// TODO: sostituire con gli URL Calendly reali appena forniti.
const String kCalendlyFirstUrl =
    'https://calendly.com/beet-it/prima-consulenza';
const String kCalendlyFollowUpUrl = 'https://calendly.com/beet-it/follow-up';

class ConsulenzaPage extends StatefulWidget {
  const ConsulenzaPage({super.key});

  @override
  State<ConsulenzaPage> createState() => _ConsulenzaPageState();
}

class _ConsulenzaPageState extends State<ConsulenzaPage> {
  static const _beet = Color(0xFFB5326B);
  static const _plum = Color(0xFF3A0A45);

  // Evento selezionato per l'iframe sul web (0 = prima, 1 = follow-up).
  int _webEvent = 0;

  /// Apre il calendario dell'evento: inline in-app su mobile, link esterno
  /// come fallback se la webview non è disponibile.
  Future<void> _prenota(BuildContext context, String title, String url) async {
    if (!kIsWeb) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CalendlyPage(title: title, url: url),
      ));
      return;
    }
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
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
          // Due eventi: Prima consulenza e Follow-up.
          _BookCard(
            icon: Icons.person_add_alt_1,
            title: l.consultFirstTitle,
            subtitle: l.consultFirstDesc,
            highlighted: true,
            selected: kIsWeb && _webEvent == 0,
            onTap: () {
              if (kIsWeb) setState(() => _webEvent = 0);
              _prenota(context, l.consultFirstTitle, kCalendlyFirstUrl);
            },
          ),
          const SizedBox(height: 10),
          _BookCard(
            icon: Icons.event_repeat,
            title: l.consultFollowTitle,
            subtitle: l.consultFollowDesc,
            selected: kIsWeb && _webEvent == 1,
            onTap: () {
              if (kIsWeb) setState(() => _webEvent = 1);
              _prenota(context, l.consultFollowTitle, kCalendlyFollowUpUrl);
            },
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            // Calendario incorporato dell'evento selezionato.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 720,
                color: Colors.white,
                child: buildCalendlyEmbed(calendlyEmbedUrl(
                    _webEvent == 0 ? kCalendlyFirstUrl : kCalendlyFollowUpUrl)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card di prenotazione di un evento Calendly.
class _BookCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final bool selected;
  final VoidCallback onTap;
  const _BookCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.selected = false,
  });

  static const _beet = Color(0xFFB5326B);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted ? _beet : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? const BorderSide(color: Color(0xFF2E7D32), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon,
            size: 30, color: highlighted ? Colors.white : _beet),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: highlighted ? Colors.white : null)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12.5,
                color: highlighted ? Colors.white70 : null)),
        trailing: Icon(Icons.chevron_right,
            color: highlighted ? Colors.white : null),
        onTap: onTap,
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
