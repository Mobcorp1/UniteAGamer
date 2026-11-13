import 'package:flutter/material.dart';

enum UagProfileGlyphKind {
  readiness,
  reputation,
  loadout,
  playstyle,
  communication,
  identity,
  community,
  generic;

  static UagProfileGlyphKind fromLabel(String label) {
    final value = label.toLowerCase();
    if (value.contains('match') || value.contains('readiness')) {
      return readiness;
    }
    if (value.contains('reputation') || value.contains('trusted')) {
      return reputation;
    }
    if (value.contains('loadout') || value.contains('build')) {
      return loadout;
    }
    if (value.contains('playstyle')) {
      return playstyle;
    }
    if (value.contains('communication') || value.contains('mic')) {
      return communication;
    }
    if (value.contains('identity')) {
      return identity;
    }
    if (value.contains('community')) {
      return community;
    }
    return generic;
  }
}

class UagProfileGlyph extends StatelessWidget {
  const UagProfileGlyph({
    super.key,
    required this.kind,
    required this.accent,
    this.size = 24,
  });

  final UagProfileGlyphKind kind;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _UagProfileGlyphPainter(kind: kind, accent: accent),
      ),
    );
  }
}

class _UagProfileGlyphPainter extends CustomPainter {
  const _UagProfileGlyphPainter({required this.kind, required this.accent});

  final UagProfileGlyphKind kind;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = accent.withValues(alpha: .18);
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * .5, h * .5), w * .44, fill);

    switch (kind) {
      case UagProfileGlyphKind.readiness:
        canvas.drawCircle(Offset(w * .5, h * .5), w * .27, p);
        canvas.drawCircle(Offset(w * .5, h * .5), w * .08, p);
        canvas.drawLine(Offset(w * .5, h * .08), Offset(w * .5, h * .22), p);
        canvas.drawLine(Offset(w * .78, h * .5), Offset(w * .92, h * .5), p);
        break;
      case UagProfileGlyphKind.reputation:
        final path = Path()
          ..moveTo(w * .5, h * .14)
          ..lineTo(w * .78, h * .25)
          ..lineTo(w * .73, h * .62)
          ..quadraticBezierTo(w * .66, h * .78, w * .5, h * .87)
          ..quadraticBezierTo(w * .34, h * .78, w * .27, h * .62)
          ..lineTo(w * .22, h * .25)
          ..close();
        canvas.drawPath(path, p);
        canvas.drawLine(Offset(w * .37, h * .5), Offset(w * .47, h * .61), p);
        canvas.drawLine(Offset(w * .47, h * .61), Offset(w * .67, h * .39), p);
        break;
      case UagProfileGlyphKind.loadout:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .18, h * .23, w * .64, h * .54),
            Radius.circular(w * .08),
          ),
          p,
        );
        canvas.drawLine(Offset(w * .35, h * .23), Offset(w * .35, h * .12), p);
        canvas.drawLine(Offset(w * .65, h * .23), Offset(w * .65, h * .12), p);
        canvas.drawLine(Offset(w * .34, h * .48), Offset(w * .66, h * .48), p);
        break;
      case UagProfileGlyphKind.playstyle:
        canvas.drawCircle(Offset(w * .32, h * .42), w * .11, p);
        canvas.drawCircle(Offset(w * .68, h * .42), w * .11, p);
        canvas.drawPath(
          Path()
            ..moveTo(w * .18, h * .75)
            ..quadraticBezierTo(w * .32, h * .56, w * .46, h * .75),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * .54, h * .75)
            ..quadraticBezierTo(w * .68, h * .56, w * .82, h * .75),
          p,
        );
        break;
      case UagProfileGlyphKind.communication:
        canvas.drawCircle(Offset(w * .34, h * .45), w * .12, p);
        canvas.drawPath(
          Path()
            ..moveTo(w * .18, h * .78)
            ..quadraticBezierTo(w * .34, h * .58, w * .5, h * .78),
          p,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * .58, h * .44), radius: w * .18),
          -.8,
          1.6,
          false,
          p,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * .58, h * .44), radius: w * .3),
          -.75,
          1.5,
          false,
          p,
        );
        break;
      case UagProfileGlyphKind.identity:
        canvas.drawCircle(Offset(w * .5, h * .38), w * .14, p);
        canvas.drawPath(
          Path()
            ..moveTo(w * .25, h * .78)
            ..quadraticBezierTo(w * .5, h * .52, w * .75, h * .78),
          p,
        );
        break;
      case UagProfileGlyphKind.community:
        canvas.drawCircle(Offset(w * .5, h * .5), w * .08, p);
        for (final a in [0.0, 1.5708, 3.1416, 4.7124]) {
          final dx = w * .5 + w * .27 * _axisCos(a);
          final dy = h * .5 + w * .27 * _axisSin(a);
          canvas.drawCircle(Offset(dx, dy), w * .065, p);
          canvas.drawLine(Offset(w * .5, h * .5), Offset(dx, dy), p);
        }
        break;
      case UagProfileGlyphKind.generic:
        canvas.drawCircle(Offset(w * .5, h * .5), w * .23, p);
        canvas.drawLine(Offset(w * .35, h * .65), Offset(w * .65, h * .35), p);
        break;
    }
  }

  double _axisCos(double x) {
    if (x == 0.0) return 1.0;
    if (x > 1.5 && x < 1.7) return 0.0;
    if (x > 3.0 && x < 3.3) return -1.0;
    return 0.0;
  }

  double _axisSin(double x) {
    if (x == 0.0 || (x > 3.0 && x < 3.3)) return 0.0;
    if (x > 1.5 && x < 1.7) return 1.0;
    return -1.0;
  }

  @override
  bool shouldRepaint(covariant _UagProfileGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.accent != accent;
}
