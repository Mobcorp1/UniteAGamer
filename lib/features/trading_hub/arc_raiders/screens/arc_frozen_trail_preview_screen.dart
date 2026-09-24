import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_preview_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_research_workstation_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcFrozenTrailPreviewScreen extends StatelessWidget {
  const ArcFrozenTrailPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FROZEN TRAIL · PREVIEW INTEL',
          style: ArcUiTokens.display(
            fontSize: 20,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            _hero(context),
            const SizedBox(height: 14),
            for (final type in const <ArcFrozenTrailContentType>[
              ArcFrozenTrailContentType.map,
              ArcFrozenTrailContentType.operation,
              ArcFrozenTrailContentType.enemy,
              ArcFrozenTrailContentType.weapon,
              ArcFrozenTrailContentType.gadget,
              ArcFrozenTrailContentType.workstation,
              ArcFrozenTrailContentType.progression,
              ArcFrozenTrailContentType.system,
              ArcFrozenTrailContentType.instrument,
            ])
              ..._cardsFor(type),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1025),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FROZEN TRAIL · 08 OCT 2026',
            style: TextStyle(
              color: ArcUiTokens.primaryAccent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Confirmed Embark preview data is pre-wired. Missing launch-day stats, recipes, Blueprint locations, attachment layouts and exact map coordinates are intentionally not guessed.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(ArcResearchWorkstationScreen.routeName),
            icon: const Icon(Icons.science_rounded),
            label: const Text('Open Research Workstation'),
          ),
          const SizedBox(height: 8),
          const Text(
            ArcFrozenTrailPreviewData.sourceLabel,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _cardsFor(ArcFrozenTrailContentType type) {
    final values = ArcFrozenTrailPreviewData.byType(type);
    return [
      for (final item in values) ...[
        _itemCard(item),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _itemCard(ArcFrozenTrailContentItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF11142A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: item.imageAssetPath == null
                ? _fallback(item.icon)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.imageAssetPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(item.icon),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.typeLabel,
                  style: const TextStyle(
                    color: ArcUiTokens.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.summary,
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
                if (item.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.detail,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: ArcUiTokens.primaryAccent, size: 32),
    );
  }
}
