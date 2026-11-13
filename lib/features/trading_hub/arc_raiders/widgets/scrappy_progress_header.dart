import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ScrappyProgressHeader extends StatelessWidget {
  const ScrappyProgressHeader({
    super.key,
    required this.completion,
    required this.ownedCount,
    required this.totalCount,
    required this.landscape,
    this.title = 'ARC Raiders Scrappy Tracker',
    this.description,
    this.footer,
    this.accentColor = AppTheme.neonPink,
  });

  final double completion;
  final int ownedCount;
  final int totalCount;
  final bool landscape;
  final String title;
  final String? description;
  final String? footer;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final value = completion.clamp(0.0, 1.0);
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: accentColor,
        borderOpacity: 0.20,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              style: ArcUiTokens.cardTitle(color: accentColor, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArcUiTokens.label(color: accentColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$ownedCount / $totalCount',
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
