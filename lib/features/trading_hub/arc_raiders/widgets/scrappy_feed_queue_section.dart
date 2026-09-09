import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_food_queue_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_food_queue_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ScrappyFeedQueueSection extends StatefulWidget {
  const ScrappyFeedQueueSection({
    super.key,
    this.goal,
    this.onGoalChanged,
    this.showGoalBar = true,
  });

  final String? goal;
  final ValueChanged<String>? onGoalChanged;
  final bool showGoalBar;

  static const goals = [
    'Overall',
    'Profit',
    'Reactors',
    'Augments',
    'Mods',
    'Explosives',
    'Utility',
    'Medical',
    'Gunsmith',
    'Expedition',
  ];

  @override
  State<ScrappyFeedQueueSection> createState() =>
      _ScrappyFeedQueueSectionState();
}

class _ScrappyFeedQueueSectionState extends State<ScrappyFeedQueueSection> {
  String _goal = 'Overall';

  String get _activeGoal => widget.goal ?? _goal;

  List<ArcScrappyFoodQueueItem> get _ranked {
    final items = [...ArcScrappyFoodQueueData.items];
    items.sort((a, b) {
      final am = a.goals.contains(_activeGoal) ? 1 : 0;
      final bm = b.goals.contains(_activeGoal) ? 1 : 0;
      if (am != bm) return bm.compareTo(am);
      return b.intelRank.compareTo(a.intelRank);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showGoalBar)
              Container(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArcUiTokens.primaryAccent.withValues(alpha: .08),
                      ArcUiTokens.secondaryAccent.withValues(alpha: .05),
                      ArcUiTokens.surfacePanel.withValues(alpha: .70),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                  border: Border.all(
                    color: ArcUiTokens.primaryAccent.withValues(alpha: .16),
                  ),
                ),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ScrappyFeedQueueSection.goals.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final goal = ScrappyFeedQueueSection.goals[i],
                          selected = goal == _activeGoal;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        label: Text(goal.toUpperCase()),
                        labelStyle: TextStyle(
                          color: selected
                              ? ArcUiTokens.background
                              : ArcUiTokens.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                        selectedColor: ArcUiTokens.primaryAccent,
                        backgroundColor: ArcUiTokens.surfacePanel,
                        side: BorderSide(
                          color: selected
                              ? ArcUiTokens.primaryAccent
                              : Colors.white.withValues(alpha: .10),
                        ),
                        onSelected: (_) {
                          if (widget.onGoalChanged != null) {
                            widget.onGoalChanged!(goal);
                          } else {
                            setState(() => _goal = goal);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            if (widget.showGoalBar) const SizedBox(height: 8),
            _hero(ranked.first),
            const SizedBox(height: 8),
            for (var i = 1; i < ranked.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _row(ranked[i], i + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero(ArcScrappyFoodQueueItem item) => Container(
    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
    decoration: ArcUiTokens.surfaceDecoration(
      role: ArcSurfaceRole.raised,
      radius: ArcUiTokens.radiusM,
      accent: ArcUiTokens.primaryAccent,
      borderOpacity: .48,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _image(item, 50),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'BEST FOR ${_activeGoal.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArcUiTokens.label(
                            color: ArcUiTokens.primaryAccent,
                          ),
                        ),
                      ),
                      _pill('#1'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.sectionTitle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${item.resourceBonus}  ${String.fromCharCode(0x2022)}  ${item.rewardPool}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          item.highlights.join('  ${String.fromCharCode(0x2022)}  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ArcUiTokens.metadata(color: ArcUiTokens.success),
        ),
        if ((item.hint ?? '').isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.hint!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
          ),
        ],
      ],
    ),
  );

  Widget _row(ArcScrappyFoodQueueItem item, int rank) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: ArcUiTokens.surfaceDecoration(
      role: ArcSurfaceRole.interactive,
      radius: ArcUiTokens.radiusS,
      accent: ArcUiTokens.secondaryAccent,
      borderOpacity: .12,
    ),
    child: Row(
      children: [
        _image(item, 38),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.cardTitle(fontSize: 12.5),
                    ),
                  ),
                  _pill('#$rank'),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${item.resourceBonus}  ${String.fromCharCode(0x2022)}  ${item.rewardPool}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                item.highlights.join('  ${String.fromCharCode(0x2022)}  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _image(ArcScrappyFoodQueueItem item, double size) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: ArcUiTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Image.asset(
      item.imageAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.restaurant_rounded, color: Colors.white38),
    ),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: AppTheme.tradingPillDecoration(
      color: ArcUiTokens.primaryAccent,
    ),
    child: Text(
      text,
      style: ArcUiTokens.metadata(color: ArcUiTokens.primaryAccent),
    ),
  );
}
