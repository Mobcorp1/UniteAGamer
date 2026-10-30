import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// Reusable, keyboard-safe ARC overlay shell. Keeps actions and scrolling
/// inside a bounded glass panel without changing their business behaviour.
class ArcModalSurface extends StatelessWidget {
  const ArcModalSurface({
    super.key,
    required this.child,
    this.accent = ArcUiTokens.primaryAccent,
    this.maxWidth = 560,
    this.maxHeightFactor = 0.86,
  });

  final Widget child;
  final Color accent;
  final double maxWidth;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        media.viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + media.viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: (availableHeight * maxHeightFactor)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
            ),
            // Keep the moving cyan/pink charge OUTSIDE the clipped modal.
            // The four-point perimeter inset leaves room for the glow without
            // changing the maximum width or height constraints of the sheet.
            child: ElectricChargeBorder(
              active: true,
              radius: ArcUiTokens.radiusXL + 4,
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: ArcUiTokens.surfaceDecoration(
                  role: ArcSurfaceRole.overlay,
                  accent: accent,
                  borderOpacity: 0.38,
                  radius: ArcUiTokens.radiusXL,
                  glow: true,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
