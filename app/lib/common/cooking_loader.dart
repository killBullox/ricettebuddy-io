import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Loader animato Beet-It: una pentola in ghisa smaltata (stile Le Creuset) con
/// un cucchiaio di legno che gira, mentre le barbabietole del logo cadono dentro.
/// Da usare ovunque ci sia un'attesa computazionale (import, caricamenti, ...).
class CookingLoader extends StatefulWidget {
  final double size;
  final String? message;
  const CookingLoader({super.key, this.size = 120, this.message});

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _PotPainter(_c.value)),
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF8B1A4A), fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ],
    );
  }
}

class _PotPainter extends CustomPainter {
  final double t; // 0..1 in loop
  _PotPainter(this.t);

  void _beet(Canvas c, Offset o, double r, double op) {
    if (op <= 0) return;
    // opacità di gruppo (per la dissolvenza quando entra in pentola)
    c.saveLayer(Rect.fromCircle(center: o, radius: r * 4),
        Paint()..color = Colors.black.withValues(alpha: op));

    // --- Foglie (3, ben visibili: sono la firma della barbabietola) ---
    final leaf = Paint()..color = const Color(0xFF2E7D32);
    final leaf2 = Paint()..color = const Color(0xFF3E9142);
    c.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.2, o.dy - r * 0.5)
          ..quadraticBezierTo(o.dx - r * 1.35, o.dy - r * 1.2, o.dx - r * 1.0, o.dy - r * 2.2)
          ..quadraticBezierTo(o.dx - r * 0.28, o.dy - r * 1.35, o.dx + r * 0.05, o.dy - r * 0.5)
          ..close(),
        leaf);
    c.drawPath(
        Path()
          ..moveTo(o.dx + r * 0.2, o.dy - r * 0.5)
          ..quadraticBezierTo(o.dx + r * 1.35, o.dy - r * 1.2, o.dx + r * 1.0, o.dy - r * 2.2)
          ..quadraticBezierTo(o.dx + r * 0.28, o.dy - r * 1.35, o.dx - r * 0.05, o.dy - r * 0.5)
          ..close(),
        leaf);
    c.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.13, o.dy - r * 0.55)
          ..quadraticBezierTo(o.dx - r * 0.12, o.dy - r * 2.15, o.dx, o.dy - r * 2.7)
          ..quadraticBezierTo(o.dx + r * 0.12, o.dy - r * 2.15, o.dx + r * 0.13, o.dy - r * 0.55)
          ..close(),
        leaf2);
    // steli
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx - r * 0.55, o.dy - r * 1.6),
        Paint()..color = const Color(0xFF2E7D32)..strokeWidth = r * 0.12..strokeCap = StrokeCap.round);
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx + r * 0.55, o.dy - r * 1.6),
        Paint()..color = const Color(0xFF2E7D32)..strokeWidth = r * 0.12..strokeCap = StrokeCap.round);

    // --- Bulbo tondo con gradiente ---
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.0,
        colors: const [Color(0xFFE86BA6), Color(0xFF9E1E58)],
      ).createShader(Rect.fromCircle(center: Offset(o.dx, o.dy + r * 0.15), radius: r * 1.35));
    final bulb = Path()
      ..moveTo(o.dx, o.dy - r * 0.78)
      ..cubicTo(o.dx + r * 1.2, o.dy - r * 0.78, o.dx + r * 1.15, o.dy + r * 0.7,
          o.dx + r * 0.3, o.dy + r * 1.15)
      ..quadraticBezierTo(o.dx, o.dy + r * 1.55, o.dx - r * 0.3, o.dy + r * 1.15)
      ..cubicTo(o.dx - r * 1.15, o.dy + r * 0.7, o.dx - r * 1.2, o.dy - r * 0.78,
          o.dx, o.dy - r * 0.78)
      ..close();
    c.drawPath(bulb, body);
    // radichetta
    c.drawLine(Offset(o.dx, o.dy + r * 1.4), Offset(o.dx + r * 0.18, o.dy + r * 2.1),
        Paint()
          ..color = const Color(0xFF7C1642)
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round);
    // riflesso
    c.drawOval(
        Rect.fromCenter(
            center: Offset(o.dx - r * 0.35, o.dy - r * 0.05), width: r * 0.5, height: r * 0.75),
        Paint()..color = Colors.white.withValues(alpha: 0.30));

    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final rimY = s * 0.52;
    final rimRx = s * 0.34, rimRy = s * 0.085;
    final botY = s * 0.90, botRx = s * 0.25;

    // --- Manici (orecchie) della pentola ---
    final ear = Paint()
      ..color = const Color(0xFF8B1A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - rimRx - s * 0.01, rimY + s * 0.09),
            radius: s * 0.055),
        -math.pi * 0.35, math.pi * 1.1, false, ear);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + rimRx + s * 0.01, rimY + s * 0.09),
            radius: s * 0.055),
        -math.pi * 0.75, math.pi * 1.1, false, ear);

    // --- Corpo pentola (smalto, gradiente) ---
    final body = Path()
      ..moveTo(cx - rimRx, rimY)
      ..cubicTo(cx - rimRx, rimY + (botY - rimY) * 0.45, cx - botRx - s * 0.02,
          botY - s * 0.05, cx - botRx, botY)
      ..quadraticBezierTo(cx, botY + s * 0.035, cx + botRx, botY)
      ..cubicTo(cx + botRx + s * 0.02, botY - s * 0.05, cx + rimRx,
          rimY + (botY - rimY) * 0.45, cx + rimRx, rimY)
      ..close();
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCB4A80), Color(0xFF7C1642)],
      ).createShader(Rect.fromLTRB(0, rimY, s, botY));
    canvas.drawPath(body, bodyPaint);
    // riflesso lucido
    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawPath(
        Path()
          ..moveTo(cx - rimRx * 0.6, rimY + s * 0.04)
          ..quadraticBezierTo(cx - rimRx * 0.9, rimY + (botY - rimY) * 0.5,
              cx - botRx * 0.5, botY - s * 0.04)
          ..lineTo(cx - botRx * 0.2, botY - s * 0.05)
          ..quadraticBezierTo(cx - rimRx * 0.5, rimY + (botY - rimY) * 0.5,
              cx - rimRx * 0.25, rimY + s * 0.04)
          ..close(),
        gloss);

    // --- Interno (apertura scura) + superficie del sugo ---
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, rimY), width: rimRx * 2, height: rimRy * 2),
        Paint()..color = const Color(0xFF3A0A2A));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, rimY + s * 0.012), width: rimRx * 1.7, height: rimRy * 1.5),
        Paint()..color = const Color(0xFFB5326B));

    // --- Barbabietole che cadono ---
    const xs = [-0.16, 0.12, -0.02];
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final by = _lerp(s * 0.17, rimY - s * 0.02, p);
      final bx = cx + xs[i] * s + math.sin(p * math.pi) * s * 0.015;
      final op = p < 0.82 ? 1.0 : (1 - (p - 0.82) / 0.18).clamp(0.0, 1.0);
      _beet(canvas, Offset(bx, by), s * 0.052, op);
    }

    // --- Bordo frontale (dà profondità) ---
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, rimY), width: rimRx * 2, height: rimRy * 2),
        0, math.pi, false,
        Paint()
          ..color = const Color(0xFFD64E8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018);

    // --- Cucchiaio di legno che gira ---
    final ang = t * 2 * math.pi;
    final bowl = Offset(
        cx + math.cos(ang) * rimRx * 0.45, rimY + math.sin(ang) * rimRy * 0.7);
    final handleEnd = Offset(cx + math.cos(ang) * rimRx * 0.95,
        rimY - s * 0.30 + math.sin(ang) * rimRy * 0.7);
    canvas.drawLine(
        bowl, handleEnd,
        Paint()
          ..color = const Color(0xFFC8965A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..strokeCap = StrokeCap.round);
    canvas.save();
    canvas.translate(bowl.dx, bowl.dy);
    canvas.rotate(math.atan2(bowl.dy - handleEnd.dy, bowl.dx - handleEnd.dx));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.12, height: s * 0.075),
        Paint()..color = const Color(0xFFB67B3F));
    canvas.restore();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_PotPainter old) => old.t != t;
}
