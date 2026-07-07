import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

/// Calendly incorporato inline via <iframe> (solo web).
final Set<String> _registered = {};

Widget buildCalendlyEmbed(String url) {
  final viewType = 'calendly-${url.hashCode}';
  if (!_registered.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen; clipboard-write';
      return iframe;
    });
    _registered.add(viewType);
  }
  return HtmlElementView(viewType: viewType);
}
