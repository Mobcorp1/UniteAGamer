import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcReferenceSectionFrame extends StatelessWidget {
  const ArcReferenceSectionFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArcUiTokens.surfacePanel.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.tradingHeading(fontSize: 14, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: ArcUiTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ArcArtworkPlaceholder extends StatelessWidget {
  const ArcArtworkPlaceholder({
    super.key,
    required this.assetPath,
    this.height = 112,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String assetPath;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ArcUiTokens.surfaceRaised,
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: Text(
              'ARTWORK PENDING',
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: ArcUiTokens.textTertiary,
                isBold: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
