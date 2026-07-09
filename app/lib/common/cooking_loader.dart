import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Stile del loader Beet-It.
enum BeetLoaderStyle {
  /// Grande: una barbabietola che ondeggia con un anello di progresso (import).
  ring,

  /// Piccolo: tre barbabietole che rimbalzano (caricamenti inline).
  bounce,
}

/// Payoff del brand mostrato sotto il loader (in inglese, identità Beet-It).
const kPayoff = 'Plant-based nutrition that rocks';

/// Fasi dell'import mostrate nel loader. Avanzano UNA volta sola (niente loop):
/// niente ripetizioni, riflettono i passi reali dell'elaborazione.
List<String> importPhases(AppLocalizations l) => [
      l.phaseReading,
      l.phaseVeganizing,
      l.phaseInstructions,
      l.phaseNutrition,
      l.phaseCo2,
    ];

/// Loader animato Beet-It.
/// - [phases]: voci di progresso che avanzano una volta e si fermano sull'ultima.
/// - [message]: testo statico (se non ci sono [phases]).
/// - [payoff]: riga brand secondaria, sotto, in tono tenue.
class CookingLoader extends StatefulWidget {
  final double size;
  final String? message;
  final List<String>? phases;
  final String? payoff;
  final BeetLoaderStyle style;
  const CookingLoader({
    super.key,
    this.size = 120,
    this.message,
    this.phases,
    this.payoff,
    this.style = BeetLoaderStyle.ring,
  });

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  Timer? _phaseTimer;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    final n = widget.phases?.length ?? 0;
    if (n > 1) {
      // Avanza UNA sola volta lungo le fasi e si ferma sull'ultima.
      _phaseTimer = Timer.periodic(const Duration(milliseconds: 2400), (t) {
        if (!mounted) return;
        if (_phase < n - 1) {
          setState(() => _phase++);
        } else {
          t.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = (widget.phases != null && widget.phases!.isNotEmpty)
        ? widget.phases![_phase]
        : widget.message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              painter: widget.style == BeetLoaderStyle.ring
                  ? _RingPainter(_c.value)
                  : _BouncePainter(_c.value),
            ),
          ),
        ),
        if (label != null && label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                label,
                key: ValueKey(label),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8B1A4A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2),
              ),
            ),
          ),
        if (widget.payoff != null && widget.payoff!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.payoff!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: const Color(0xFF8B1A4A).withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.3),
            ),
          ),
      ],
    );
  }
}

// Barbabietola pulita (teardrop + foglie) disegnata attorno all'origine, raggio r.
void _beet(Canvas c, double r, double rot) {
  c.save();
  c.rotate(rot);
  void leaf(double x0, double y0, double cx1, double cy1, double x1, double y1,
      double cx2, double cy2, double x2, double y2, Paint p) {
    c.drawPath(
        Path()
          ..moveTo(x0, y0)
          ..quadraticBezierTo(cx1, cy1, x1, y1)
          ..quadraticBezierTo(cx2, cy2, x2, y2)
          ..close(),
        p);
  }

  final leafP = Paint()..color = const Color(0xFF2E7D32);
  final leafHi = Paint()..color = const Color(0xFF43A047);
  leaf(-r * 0.2, -r * 0.5, -r * 1.35, -r * 1.15, -r * 1.02, -r * 2.25, -r * 0.28,
      -r * 1.35, r * 0.05, -r * 0.5, leafP);
  leaf(r * 0.2, -r * 0.5, r * 1.35, -r * 1.15, r * 1.02, -r * 2.25, r * 0.28,
      -r * 1.35, -r * 0.05, -r * 0.5, leafP);
  leaf(-r * 0.14, -r * 0.55, -r * 0.12, -r * 2.2, 0, -r * 2.8, r * 0.12, -r * 2.2,
      r * 0.14, -r * 0.55, leafHi);
  final stem = Paint()
    ..color = const Color(0xFF2E7D32)
    ..strokeWidth = r * 0.12
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(0, -r * 0.4), Offset(-r * 0.5, -r * 1.6), stem);
  c.drawLine(Offset(0, -r * 0.4), Offset(r * 0.5, -r * 1.6), stem);

  final body = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 1.0,
      colors: const [Color(0xFFEE7CB4), Color(0xFF9E1E58)],
    ).createShader(Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 1.5));
  c.drawPath(
      Path()
        ..moveTo(0, -r * 0.82)
        ..cubicTo(r * 1.25, -r * 0.82, r * 1.18, r * 0.72, r * 0.3, r * 1.2)
        ..quadraticBezierTo(0, r * 1.62, -r * 0.3, r * 1.2)
        ..cubicTo(-r * 1.18, r * 0.72, -r * 1.25, -r * 0.82, 0, -r * 0.82)
        ..close(),
      body);
  c.drawLine(Offset(0, r * 1.45), Offset(r * 0.16, r * 2.1),
      Paint()
        ..color = const Color(0xFF7C1642)
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round);
  c.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.38, -r * 0.08), width: r * 0.48, height: r * 0.8),
      Paint()..color = Colors.white.withValues(alpha: 0.34));
  c.restore();
}

/// Opzione 1: barbabietola che ondeggia + anello di progresso.
class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final cx = d / 2, cy = d / 2;
    final ang = t * 2 * math.pi;
    final bob = math.sin(ang) * d * 0.02;

    // ombra
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + d * 0.30),
            width: d * 0.30 - bob, height: d * 0.06),
        Paint()..color = const Color(0xFF7C1642).withValues(alpha: 0.14));

    // anello
    canvas.drawCircle(Offset(cx, cy), d * 0.40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = d * 0.03
          ..color = const Color(0xFFB5326B).withValues(alpha: 0.16));
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: d * 0.40),
        ang, 1.7, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = d * 0.03
          ..color = const Color(0xFFB5326B));

    // barbabietola
    canvas.save();
    canvas.translate(cx, cy + bob);
    _beet(canvas, d * 0.14, math.sin(ang) * 0.12);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// Opzione 3: tre barbabietole che rimbalzano in sequenza.
class _BouncePainter extends CustomPainter {
  final double t;
  _BouncePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final ang = t * 2 * math.pi;
    final cy = d * 0.56, gap = d * 0.28, r = d * 0.115;
    for (var i = 0; i < 3; i++) {
      final cx = d / 2 + (i - 1) * gap;
      final hop = math.max(0.0, math.sin(ang - i * 0.6));
      final y = cy - hop * d * 0.20;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy + d * 0.22),
              width: r * (1.1 - hop * 0.4), height: r * 0.22),
          Paint()..color = const Color(0xFF7C1642).withValues(alpha: 0.13));
      canvas.save();
      canvas.translate(cx, y);
      _beet(canvas, r, 0);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BouncePainter old) => old.t != t;
}
