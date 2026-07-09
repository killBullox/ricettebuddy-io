import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fasi mostrate durante l'import di una ricetta (scorrono nel loader).
/// Includono la veganizzazione: se la ricetta è già vegana quel passo è
/// istantaneo lato server, ma la fase resta un tocco carino.
const kImportPhases = [
  'Sto analizzando la ricetta…',
  'Sto veganizzando gli ingredienti…',
  'Sto scrivendo le istruzioni di preparazione…',
  'Sto calcolando i valori nutrizionali…',
  'Sto stimando l\'impatto ambientale (CO₂)…',
];

/// Loader animato Beet-It: una pentola in ghisa smaltata (stile Le Creuset) con
/// un cucchiaio di legno che gira DENTRO, mentre poche barbabietole grandi e
/// riconoscibili cadono dentro. Da usare ovunque ci sia un'attesa.
///
/// Se [phases] è valorizzato, il testo sotto scorre tra le fasi (es. import:
/// "Sto analizzando…", "Sto veganizzando…", …). Altrimenti mostra [message].
class CookingLoader extends StatefulWidget {
  final double size;
  final String? message;
  final List<String>? phases;
  const CookingLoader({super.key, this.size = 120, this.message, this.phases});

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  Timer? _phaseTimer;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    if ((widget.phases?.length ?? 0) > 1) {
      _phaseTimer = Timer.periodic(const Duration(milliseconds: 2300), (_) {
        if (mounted) setState(() => _phase = (_phase + 1) % widget.phases!.length);
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
    final label = widget.phases != null && widget.phases!.isNotEmpty
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
            builder: (_, __) => CustomPaint(painter: _PotPainter(_c.value)),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF8B1A4A),
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }
}

class _PotPainter extends CustomPainter {
  final double t; // 0..1 in loop
  _PotPainter(this.t);

  /// Disegna una barbabietola grande e riconoscibile: bulbo con gradiente,
  /// ciuffo di foglie verdi, radichetta. [rot] la ruota leggermente.
  void _beet(Canvas c, Offset o, double r, double op, double rot) {
    if (op <= 0) return;
    c.saveLayer(Rect.fromCircle(center: o, radius: r * 4),
        Paint()..color = Colors.black.withValues(alpha: op));
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    c.translate(-o.dx, -o.dy);

    // --- Foglie (ciuffo, la firma della barbabietola) ---
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
    // steli
    final stem = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx - r * 0.55, o.dy - r * 1.7), stem);
    c.drawLine(Offset(o.dx, o.dy - r * 0.4), Offset(o.dx + r * 0.55, o.dy - r * 1.7), stem);

    // --- Bulbo tondo con gradiente ---
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
    // radichetta a punta
    c.drawLine(Offset(o.dx, o.dy + r * 1.45), Offset(o.dx + r * 0.16, o.dy + r * 2.15),
        Paint()
          ..color = const Color(0xFF7C1642)
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round);
    // riflesso
    c.drawOval(
        Rect.fromCenter(
            center: Offset(o.dx - r * 0.38, o.dy - r * 0.1), width: r * 0.5, height: r * 0.8),
        Paint()..color = Colors.white.withValues(alpha: 0.32));

    c.restore();
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final rimY = s * 0.54;
    final rimRx = s * 0.34, rimRy = s * 0.085;
    final botY = s * 0.90, botRx = s * 0.25;

    // --- Manici (orecchie) della pentola ---
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

    // --- Barbabietole che cadono DIETRO il bordo frontale (poche e grandi) ---
    // Due barbabietole, cadute sfalsate e con velocità/rotazione diverse
    // (moto irregolare, non "regolare").
    final beetR = s * 0.092;
    _fallingBeet(canvas, cx, rimY, s, beetR, phase: (t + 0.00) % 1.0, x0: -0.14, spin: 1.0);
    _fallingBeet(canvas, cx, rimY, s, beetR, phase: (t + 0.55) % 1.0, x0: 0.13, spin: -0.7);

    // --- Corpo pentola (smalto, gradiente) ---
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
    // riflesso lucido
    canvas.drawPath(
        Path()
          ..moveTo(cx - rimRx * 0.6, rimY + s * 0.04)
          ..quadraticBezierTo(cx - rimRx * 0.9, rimY + (botY - rimY) * 0.5, cx - botRx * 0.5, botY - s * 0.04)
          ..lineTo(cx - botRx * 0.2, botY - s * 0.05)
          ..quadraticBezierTo(cx - rimRx * 0.5, rimY + (botY - rimY) * 0.5, cx - rimRx * 0.25, rimY + s * 0.04)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.12));

    // --- Interno (apertura scura) + superficie del sugo ---
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, rimY), width: rimRx * 2, height: rimRy * 2),
        Paint()..color = const Color(0xFF3A0A2A));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, rimY + s * 0.012), width: rimRx * 1.7, height: rimRy * 1.5),
        Paint()..color = const Color(0xFFB5326B));

    // --- Cucchiaio di legno che gira DENTRO la pentola ---
    // Impugnatura fissa in alto (la "mano"), la parte immersa traccia una piccola
    // ellisse DENTRO il sugo: sembra mescolare, e resta dentro la pentola.
    final ang = t * 2 * math.pi;
    final bowl = Offset(
        cx + math.cos(ang) * rimRx * 0.40, rimY + math.sin(ang) * rimRy * 0.72);
    final grip = Offset(
        cx + math.cos(ang) * s * 0.05, rimY - s * 0.30);
    canvas.drawLine(
        bowl, grip,
        Paint()
          ..color = const Color(0xFFC8965A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..strokeCap = StrokeCap.round);
    canvas.save();
    canvas.translate(bowl.dx, bowl.dy);
    canvas.rotate(math.atan2(bowl.dy - grip.dy, bowl.dx - grip.dx));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.125, height: s * 0.08),
        Paint()..color = const Color(0xFFB67B3F));
    canvas.restore();

    // --- Bordo frontale (davanti al cucchiaio: dà profondità "dentro") ---
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, rimY), width: rimRx * 2, height: rimRy * 2),
        0, math.pi, false,
        Paint()
          ..color = const Color(0xFFD64E8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02);
  }

  // Una barbabietola che cade dall'alto dentro la pentola, con easing (accelera)
  // e leggera rotazione: caduta "irregolare", non lineare.
  void _fallingBeet(Canvas canvas, double cx, double rimY, double s, double r,
      {required double phase, required double x0, required double spin}) {
    final eased = phase * phase; // accelera cadendo (gravità)
    final by = _lerp(s * 0.12, rimY - s * 0.01, eased);
    final bx = cx + x0 * s + math.sin(phase * math.pi * 2) * s * 0.01;
    final op = phase < 0.86 ? 1.0 : (1 - (phase - 0.86) / 0.14).clamp(0.0, 1.0);
    _beet(canvas, Offset(bx, by), r, op, math.sin(phase * math.pi) * 0.5 * spin);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_PotPainter old) => old.t != t;
}
