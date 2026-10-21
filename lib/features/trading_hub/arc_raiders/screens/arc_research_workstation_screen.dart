import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_workspace.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_preview_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_progression_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcResearchWorkstationScreen extends StatelessWidget {
  const ArcResearchWorkstationScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/research-workstation';

  @override
  Widget build(BuildContext context) {
    final research = ArcFrozenTrailPreviewData.researchWorkstation;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RESEARCH WORKSTATION',
          style: ArcUiTokens.display(
            fontSize: 20,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
          children: [
            const ArcProgressionWorkspaceBar(
              current: ArcProgressionWorkspace.research,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.spaceM),
            _hero(research),
            const SizedBox(height: AppTheme.spaceM),
            const ArcAmplificationWorkspace(),
          ],
        ),
      ),
    );
  }

  Widget _hero(ArcFrozenTrailContentItem research) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusXL,
        borderOpacity: 0.3,
      ),
      child: Row(children: [
        SizedBox(
          width: 62,
          height: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              research.imageAssetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.science_rounded,
                color: ArcUiTokens.primaryAccent,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESEARCH WORKSTATION', style: ArcUiTokens.display(
              fontSize: 21, color: ArcUiTokens.primaryAccent,
            )),
            const SizedBox(height: 4),
            const Text('Track research, materials and unlocked perks.',
              style: TextStyle(color: ArcUiTokens.textSecondary, fontSize: 12)),
          ],
        )),
      ]),
    );
  }
}
