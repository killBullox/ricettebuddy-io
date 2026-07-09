import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// Loader animato Beet-It: una pentola in ghisa smaltata (stile Le Creuset) con
/// vapore che sale, un cucchiaio di legno che mescola appena (dentro, senza mai
/// toccare le pareti) e due barbabietole che sobbolliscono nel sugo.
///
/// Il testo sotto: [liveMessage] (cambia in tempo reale, pilotato dai passi
/// EFFETTIVI dell'import) ha la precedenza; altrimenti [message] statico.
class CookingLoader extends StatefulWidget {
  final double size;
  final String? message;
  final ValueListenable<String>? liveMessage;
  const CookingLoader(
      {super.key, this.size = 120, this.message, this.liveMessage});

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _label(String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Text(
          text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF8B1A4A),
              fontWeight: FontWeight.w800,
              fontSize: 15),
        ),
      ),
    );
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
        if (widget.liveMessage != null)
          ValueListenableBuilder<String>(
            valueListenable: widget.liveMessage!,
            builder: (_, v, __) => _label(v),
          )
        else
          _label(widget.message),
      ],
    );
  }
}

class _PotPainter extends CustomPainter {
  final double t; // 0..1 in loop
  _PotPainter(this.t);

  /// Barbabietola riconoscibile: bulbo con gradiente, ciuffo di foglie,
  /// radichetta. [rot] la ruota leggermente.
  void _beet(Canvas c, Offset o, double r, double rot) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    c.translate(-o.dx, -o.dy);

    final leaf = Paint()..color = const Color(0xFF2E7D32);
    final leaf2 = Paint()..color = const Color(0xFF43A047);
    c.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.2, o.dy - r * 0.5)
          ..quadraticBezierTo(o.dx - r * 1.4, o.dy - r * 1.2, o.dx - r * 1.05, o.dy - r * 2.3)
          ..quadraticBezierTo(o.dx - r * 0.28, o.dy - r * 1.4, o.dx + r * 0.05, o.dy - r * 0.5)
          ..close(),
        leaf);
    c.drawPath(
        Path()
          ..moveTo(o.dx + r * 0.2, o.dy - r * 0.5)
          ..quadraticBezierTo(o.dx + r * 1.4, o.dy - r * 1.2, o.dx + r * 1.05, o.dy - r * 2.3)
          ..quadraticBezierTo(o.dx + r * 0.28, o.dy - r * 1.4, o.dx - r * 0.05, o.dy - r * 0.5)
          ..close(),
        leaf);
    c.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.14, o.dy - r * 0.55)
          ..quadraticBezierTo(o.dx - r * 0.12, o.dy - r * 2.25, o.dx, o.dy - r * 2.85)
          ..quadraticBezierTo(o.dx + r * 0.12, o.dy - r * 2.25, o.dx + r * 0.14, o.dy - r * 0.55)
          ..close(),
        leaf2);
    final stem = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx - r * 0.55, o.dy - r * 1.7), stem);
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx + r * 0.55, o.dy - r * 1.7), stem);

    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.0,
        colors: const [Color(0xFFEE7CB4), Color(0xFF9E1E58)],
      ).createShader(Rect.fromCircle(
          center: Offset(o.dx, o.dy + r * 0.15), radius: r * 1.35));
    final bulb = Path()
      ..moveTo(o.dx, o.dy - r * 0.82)
      ..cubicTo(o.dx + r * 1.25, o.dy - r * 0.82, o.dx + r * 1.18, o.dy + r * 0.72,
          o.dx + r * 0.3, o.dy + r * 1.2)
      ..quadraticBezierTo(o.dx, o.dy + r * 1.62, o.dx - r * 0.3, o.dy + r * 1.2)
      ..cubicTo(o.dx - r * 1.18, o.dy + r * 0.72, o.dx - r * 1.25, o.dy - r * 0.82,
          o.dx, o.dy - r * 0.82)
      ..close();
    c.drawPath(bulb, body);
    c.drawLine(Offset(o.dx, o.dy + r * 1.45), Offset(o.dx + r * 0.16, o.dy + r * 2.15),
        Paint()
          ..color = const Color(0xFF7C1642)
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(o.dx - r * 0.38, o.dy - r * 0.1), width: r * 0.5, height: r * 0.8),
        Paint()..color = Colors.white.withValues(alpha: 0.32));

    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final rimY = s * 0.54;
    final rimRx = s * 0.34, rimRy = s * 0.085;
    final botY = s * 0.90, botRx = s * 0.25;
    final ang = t * 2 * math.pi;

    final mouth = Rect.fromCenter(
        center: Offset(cx, rimY), width: rimRx * 2, height: rimRy * 2);
    final sauce = Rect.fromCenter(
        center: Offset(cx, rimY + s * 0.012), width: rimRx * 1.7, height: rimRy * 1.5);

    // --- Vapore che sale (dietro la pentola, fade verso l'alto) ---
    for (final i in const [-1, 1]) {
      final baseX = cx + i * s * 0.08;
      final drift = math.sin(ang + i) * s * 0.02;
      final path = Path()..moveTo(baseX, rimY - s * 0.05);
      for (var seg = 1; seg <= 6; seg++) {
        final yy = rimY - s * 0.05 - seg * s * 0.05;
        final xx = baseX + drift + math.sin(seg * 0.9 + ang + i * 1.5) * s * 0.028;
        path.lineTo(xx, yy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02
            ..strokeCap = StrokeCap.round
            ..shader = const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0x66C98FB0), Color(0x00C98FB0)],
            ).createShader(Rect.fromLTRB(0, rimY - s * 0.35, s, rimY)));
    }

    // --- Manici (orecchie) ---
    final ear = Paint()
      ..color = const Color(0xFF8B1A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - rimRx - s * 0.01, rimY + s * 0.09), radius: s * 0.055),
        -math.pi * 0.35, math.pi * 1.1, false, ear);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + rimRx + s * 0.01, rimY + s * 0.09), radius: s * 0.055),
        -math.pi * 0.75, math.pi * 1.1, false, ear);

    // --- Corpo pentola ---
    final body = Path()
      ..moveTo(cx - rimRx, rimY)
      ..cubicTo(cx - rimRx, rimY + (botY - rimY) * 0.45, cx - botRx - s * 0.02,
          botY - s * 0.05, cx - botRx, botY)
      ..quadraticBezierTo(cx, botY + s * 0.035, cx + botRx, botY)
      ..cubicTo(cx + botRx + s * 0.02, botY - s * 0.05, cx + rimRx,
          rimY + (botY - rimY) * 0.45, cx + rimRx, rimY)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCB4A80), Color(0xFF7C1642)],
          ).createShader(Rect.fromLTRB(0, rimY, s, botY)));
    canvas.drawPath(
        Path()
          ..moveTo(cx - rimRx * 0.6, rimY + s * 0.04)
          ..quadraticBezierTo(cx - rimRx * 0.9, rimY + (botY - rimY) * 0.5, cx - botRx * 0.5, botY - s * 0.04)
          ..lineTo(cx - botRx * 0.2, botY - s * 0.05)
          ..quadraticBezierTo(cx - rimRx * 0.5, rimY + (botY - rimY) * 0.5, cx - rimRx * 0.25, rimY + s * 0.04)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.12));

    // --- Interno scuro + superficie del sugo ---
    canvas.drawOval(mouth, Paint()..color = const Color(0xFF3A0A2A));
    canvas.drawOval(sauce, Paint()..color = const Color(0xFFB5326B));

    // --- Contenuto DENTRO la pentola (ritagliato ai lati → non esce mai) ---
    canvas.save();
    canvas.clipRect(
        Rect.fromLTRB(cx - rimRx * 0.92, 0, cx + rimRx * 0.92, rimY + rimRy * 0.85));

    // Cucchiaio: corto, impugnatura poco sopra il bordo, punta con orbita
    // MINIMA e centrale → mescola appena e non tocca mai le pareti.
    final grip = Offset(cx + math.sin(ang) * s * 0.02, rimY - s * 0.19);
    final bowl = Offset(cx + math.cos(ang) * rimRx * 0.16,
        rimY - s * 0.02 + math.sin(ang) * rimRy * 0.4);
    canvas.drawLine(
        grip, bowl,
        Paint()
          ..color = const Color(0xFFC8965A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04
          ..strokeCap = StrokeCap.round);
    canvas.save();
    canvas.translate(bowl.dx, bowl.dy);
    canvas.rotate(math.atan2(bowl.dy - grip.dy, bowl.dx - grip.dx));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.11, height: s * 0.07),
        Paint()..color = const Color(0xFFB67B3F));
    canvas.restore();

    // Barbabietole ben visibili sopra il sugo, che ondeggiano (bob ampio) e
    // ruotano leggermente, sfasate tra loro.
    _beet(canvas, Offset(cx - s * 0.105, rimY - s * 0.085 + math.sin(ang) * s * 0.03),
        s * 0.075, math.sin(ang + 0.6) * 0.18);
    _beet(canvas, Offset(cx + s * 0.11, rimY - s * 0.075 + math.sin(ang + 2.3) * s * 0.03),
        s * 0.068, math.sin(ang) * -0.16);
    canvas.restore();

    // --- Labbro frontale: davanti a cucchiaio e barbabietole (profondità) ---
    final front = Path()
      ..addArc(mouth, 0, math.pi)
      ..addArc(sauce.translate(0, s * 0.006), math.pi, math.pi)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF9E2463));
    canvas.drawArc(mouth, 0, math.pi, false,
        Paint()
          ..color = const Color(0xFFD64E8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.016);
  }

  @override
  bool shouldRepaint(_PotPainter old) => old.t != t;
}
