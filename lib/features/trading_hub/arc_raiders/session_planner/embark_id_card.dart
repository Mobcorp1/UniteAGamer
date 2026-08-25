import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class EmbarkIdCard extends StatelessWidget {
  const EmbarkIdCard({super.key, required this.label, required this.embarkId});
  final String label;
  final String embarkId;
  @override
  Widget build(BuildContext context) {
    final visible = embarkId.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: AppTheme.neonCyan,
        radius: 16,
        borderOpacity: 0.24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visible ? embarkId : 'Not added yet',
                  style: AppTheme.tradingHeading(
                    fontSize: 16,
                    color: visible ? AppTheme.neonCyan : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy Embark ID',
            onPressed: visible
                ? () => Clipboard.setData(ClipboardData(text: embarkId))
                : null,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}
