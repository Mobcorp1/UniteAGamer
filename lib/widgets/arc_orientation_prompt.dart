import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

/// The single compact treatment for landscape-only ARC workspaces.
///
/// It is deliberately a content-sized card, not a full-width instruction
/// panel. Normal routes retain the app-wide cinematic background. Camera
/// overlays can set [coverContent] to conceal the live feed with the same art.
class ArcOrientationPrompt extends StatelessWidget {
  const ArcOrientationPrompt({
    super.key,
    required this.message,
    this.title = 'ROTATE TO LANDSCAPE',
    this.coverContent = false,
    this.maxWidth = 360,
  });

  final String title;
  final String message;
  final bool coverContent;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 340;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (coverContent)
              const UagCinematicBackground(
                backgroundAsset: UagVisualAssets.arcBackground,
                backgroundOpacity: 0.28,
                showWatermark: false,
                showGrid: false,
              ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x4703060A),
                        Color(0x1603060A),
                        Color(0x5203060A),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                primary: false,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: compactHeight ? 6 : 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: DecoratedBox(
                            key: const Key('arc-orientation-card'),
                            decoration: ArcUiTokens.surfaceDecoration(
                              role: ArcSurfaceRole.overlay,
                              accent: ArcUiTokens.primaryAccent,
                              borderOpacity: 0.34,
                              radius: ArcUiTokens.radiusXXL,
                              glow: true,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(compactHeight ? 12 : 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.screen_rotation_rounded,
                                    size: compactHeight ? 30 : 36,
                                    color: ArcUiTokens.primaryAccent,
                                    semanticLabel: 'Rotate device',
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: ArcUiTokens.sectionTitle(
                                            fontSize: compactHeight ? 15 : 17,
                                            color: ArcUiTokens.primaryAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          message,
                                          style: ArcUiTokens.body(
                                            fontSize: compactHeight ? 11.5 : 12.5,
                                            color: ArcUiTokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A non-blocking recommendation for map and image editing workspaces which
/// remain functional in portrait but offer more room in landscape.
class ArcLandscapeAdvisory extends StatelessWidget {
  const ArcLandscapeAdvisory({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.orientationOf(context) != Orientation.portrait) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const Key('arc-landscape-advisory'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.24,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.screen_rotation_rounded,
            size: 20,
            color: ArcUiTokens.primaryAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: ArcUiTokens.bodySmall(
                color: ArcUiTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
