import 'package:flutter/material.dart';

/// Compact tactical map pin whose bottom tip is the authoritative map point.
/// The visual head may grow when selected without moving that anchor.
class ArcPrecisionMapPin extends StatelessWidget {
  const ArcPrecisionMapPin({
    super.key,
    required this.selected,
    required this.accent,
    required this.head,
    required this.label,
    required this.onTap,
    this.detail,
    this.coordinateText,
  });

  final bool selected;
  final Color accent;
  final Widget head;
  final String label;
  final VoidCallback onTap;
  final String? detail;
  final String? coordinateText;

  static const double collapsedWidth = 40;
  static const double collapsedHeight = 42;
  static const double expandedWidth = 184;
  static const double expandedHeight = 92;

  static double widthFor(bool selected) =>
      selected ? expandedWidth : collapsedWidth;
  static double heightFor(bool selected) =>
      selected ? expandedHeight : collapsedHeight;

  @override
  Widget build(BuildContext context) {
    final width = widthFor(selected);
    final height = heightFor(selected);
    final headSize = selected ? 27.0 : 21.0;
    const needleHeight = 14.0;
    final headBottom = needleHeight - 1;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              if (selected)
                Positioned(
                  left: 4,
                  right: 4,
                  top: 0,
                  child: _ExpandedPinCard(
                    label: label,
                    detail: detail,
                    coordinateText: coordinateText,
                    accent: accent,
                  ),
                ),
              Positioned(
                bottom: 0,
                width: 12,
                height: needleHeight + 2,
                child: CustomPaint(painter: _PinNeedlePainter(accent: accent)),
              ),
              Positioned(
                bottom: headBottom,
                width: headSize,
                height: headSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF071019),
                    border: Border.all(
                      color: selected ? Colors.white : accent,
                      width: selected ? 2 : 1.25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: selected ? 0.5 : 0.26),
                        blurRadius: selected ? 12 : 6,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(child: SizedBox.expand(child: head)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedPinCard extends StatelessWidget {
  const _ExpandedPinCard({
    required this.label,
    required this.accent,
    this.detail,
    this.coordinateText,
  });

  final String label;
  final String? detail;
  final String? coordinateText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail?.trim();
    final coordinates = coordinateText?.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xF207111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null && detail.isNotEmpty)
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
            ),
          if (coordinates != null && coordinates.isNotEmpty)
            Text(
              coordinates,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontSize: 9.5),
            ),
        ],
      ),
    );
  }
}

class _PinNeedlePainter extends CustomPainter {
  const _PinNeedlePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.28, 0)
      ..lineTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height - 1),
      1.15,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PinNeedlePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
