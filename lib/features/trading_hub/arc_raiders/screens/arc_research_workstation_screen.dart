import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_preview_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_two_content.dart';
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
            _confirmed(),
            const SizedBox(height: AppTheme.spaceM),
            _currentContent(),
            const SizedBox(height: AppTheme.spaceM),
            _pending(),
          ],
        ),
      ),
    );
  }

  Widget _hero(ArcFrozenTrailContentItem research) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArcUiTokens.surfacePanel,
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                research.imageAssetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black.withValues(alpha: 0.28),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.science_rounded,
                    size: 38,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FROZEN TRAIL · 08 OCT 2026',
                  style: TextStyle(
                    color: ArcUiTokens.secondaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  research.summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  research.detail,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmed() {
    return _section('CONFIRMED FUNCTION', const <String>[
      'Located in the new Outpost.',
      'Used to research new elements of the world.',
      'Unlocks higher levels of weapon customisation and modding.',
      'Research Station level IV plus Gunsmith level IV unlock weapon quality V.',
      'Outpost IV is required for these workshop upgrades; amplification cannot be reversed.',
      'Embark says the first rollout covers 15 weapons.',
    ], ArcUiTokens.success);
  }

  Widget _currentContent() {
    final outpost = ArcFrozenTrailProgressionCatalog.outpost
        .map(
          (tier) =>
              'Outpost Lv.${tier.level}: ${tier.materials.entries.map((m) => '${m.value}x ${m.key.replaceAll('_', ' ')}').join(', ')}. ${tier.source}',
        )
        .toList(growable: false);
    final research = ArcFrozenTrailProgressionCatalog.researchStation
        .map(
          (tier) =>
              'Research Lv.${tier.level}: ${tier.materials.entries.map((m) => '${m.value}x ${m.key.replaceAll('_', ' ')}').join(', ')}. ${tier.source}',
        )
        .toList(growable: false);
    final modules = ArcFrozenTrailProgressionCatalog
        .amplificationMarkByWeapon
        .entries
        .map((entry) => '${entry.key}: Mk.${entry.value} Amplification Module')
        .toList(growable: false);
    final researchReturns = ArcFrozenTrailProgressionCatalog
        .researchPointYield
        .entries
        .map(
          (item) =>
              '${item.key.replaceAll('_', ' ')}: ${item.value} Research Points when studied',
        )
        .toList(growable: false);
    return Column(
      children: <Widget>[
        _section(
          'RESEARCH ITEMS / POINTS',
          researchReturns,
          ArcUiTokens.success,
        ),
        const SizedBox(height: 12),
        _section('OUTPOST LEVELS', outpost, ArcUiTokens.primaryAccent),
        const SizedBox(height: 12),
        _section(
          'RESEARCH STATION MATERIALS',
          research,
          ArcUiTokens.secondaryAccent,
        ),
        const SizedBox(height: 12),
        _section(
          'AMPLIFICATION MODULES - 15 WEAPONS',
          modules,
          ArcUiTokens.success,
        ),
      ],
    );
  }

  Widget _pending() {
    return _section(
      'STILL AWAITING IN-GAME VALIDATION',
      const <String>[
        'Exact research-node unlock costs and node-specific materials for every amplified weapon.',
        'Current user Outpost level is not yet saved or enforced; this view is a cost reference.',
        'Amplified repair quantities vary with installed weapon perks.',
        'Not every visible material is guaranteed to be tradeable in an actual raid.',
      ],
      ArcUiTokens.warning,
      footer:
          'The materials above are 2.0 reference values; player-specific Outpost completion is not yet synchronised.',
    );
  }

  Widget _section(
    String title,
    List<String> values,
    Color accent, {
    String? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chevron_right_rounded, size: 17, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
