import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class ArcDataAttributionScreen extends StatelessWidget {
  const ArcDataAttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Data Attribution',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 940,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcTacticalPanel(
            icon: Icons.dataset_linked_outlined,
            title: 'ARC Raiders Item Intelligence',
            subtitle:
                'Source, licensing and fan-project boundaries for local item intelligence.',
            accent: ArcUiTokens.primaryAccent,
            child: SizedBox.shrink(),
          ),
          ArcTacticalPanel(
            icon: Icons.policy_outlined,
            title: 'Attribution Brief',
            accent: ArcUiTokens.secondaryAccent,
            child: Text(
              'UAG Raider uses a locally maintained item-intelligence layer for gameplay advice, item recognition, blueprint guidance, trading guidance, recycle/sell suggestions, and progression warnings.\n\n'
              'Where external community datasets are used as references or import sources, they must be used only where their license allows it and with the required attribution preserved.\n\n'
              'RaidTheory arcraiders-data is MIT licensed. If imported, preserve its license notice and attribution in the project repository.\n\n'
              'GamesRadar, MetaForge, ARC Raiders Database, and wiki pages may be used as human reference sources only unless their terms explicitly allow direct reuse. Do not copy copyrighted editorial tables, images, or page content directly into the app.\n\n'
              'ARC Raiders, related names, game data, assets, images, logos, and trademarks belong to their respective rights holders. UAG Arc Raiders Hub is an unofficial fan-made companion tool and is not affiliated with, endorsed by, or supported by Embark Studios AB or Nexon.',
              style: ArcUiTokens.body(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
