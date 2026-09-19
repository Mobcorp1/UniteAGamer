import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_game_platform_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcGamePlatformSelector extends StatelessWidget {
  const ArcGamePlatformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.errorText,
    this.compact = false,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final String? errorText;
  final bool compact;

  IconData _iconFor(String platform) {
    return switch (platform) {
      ArcGamePlatformCatalog.playStation => Icons.videogame_asset_rounded,
      ArcGamePlatformCatalog.xbox => Icons.sports_esports_rounded,
      ArcGamePlatformCatalog.pc => Icons.computer_rounded,
      _ => Icons.gamepad_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHERE DO YOU PLAY?',
          style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
        ),
        const SizedBox(height: 5),
        Text(
          'Choose every platform you actively use. UAG will only ask for gaming IDs that match.',
          style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
        ),
        SizedBox(height: compact ? 8 : 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final platform in ArcGamePlatformCatalog.values)
              FilterChip(
                selected: selected.contains(platform),
                avatar: Icon(
                  _iconFor(platform),
                  size: 17,
                  color: selected.contains(platform)
                      ? ArcUiTokens.primaryAccent
                      : ArcUiTokens.textSecondary,
                ),
                label: Text(platform),
                showCheckmark: false,
                selectedColor: ArcUiTokens.primaryAccent.withValues(
                  alpha: 0.16,
                ),
                backgroundColor: ArcUiTokens.surfaceInteractive.withValues(
                  alpha: 0.72,
                ),
                side: BorderSide(
                  color:
                      (selected.contains(platform)
                              ? ArcUiTokens.primaryAccent
                              : ArcUiTokens.borderSubtle)
                          .withValues(alpha: 0.64),
                ),
                labelStyle: ArcUiTokens.label(
                  color: selected.contains(platform)
                      ? ArcUiTokens.primaryAccent
                      : ArcUiTokens.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                ),
                onSelected: (_) {
                  final next = <String>{...selected};
                  if (!next.add(platform)) {
                    next.remove(platform);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
        if (errorText != null && errorText!.trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            errorText!,
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.danger),
          ),
        ],
      ],
    );
  }
}
