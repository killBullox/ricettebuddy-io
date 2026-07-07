import 'package:flutter/material.dart';

/// Fallback non-web: su mobile la prenotazione inline userà una WebView
/// (in arrivo col build nativo). Per ora si apre esternamente dal pulsante.
Widget buildCalendlyEmbed(String url) => const SizedBox.shrink();
