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
    final percent = (completion.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: accentColor,
        borderOpacity: 0.20,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.interactive,
              radius: ArcUiTokens.radiusS,
              accent: accentColor,
              borderOpacity: 0.28,
            ),
            child: Text(
              '$percent%',
              style: ArcUiTokens.cardTitle(color: accentColor, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.label(color: accentColor),
                ),
                const SizedBox(height: 3),
                Text(
                  description ?? 'Live tracker intelligence',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completion.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$ownedCount / $totalCount',
                style: ArcUiTokens.cardTitle(
                  color: ArcUiTokens.textPrimary,
                  fontSize: 13,
                ),
              ),
              Text(
                'COMPLETE',
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
