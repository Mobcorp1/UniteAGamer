import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ScrappyTile extends StatelessWidget {
  const ScrappyTile({
    super.key,
    required this.item,
    required this.state,
    required this.landscape,
    required this.tierColor,
    required this.onTap,
    required this.onLongPress,
  });

  final ArcScrappyItem item;
  final ArcScrappyState state;
  final bool landscape;
  final Color tierColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final owned = state.ownedFor(item.neededCount);
    final surplus = state.surplusFor(item.neededCount);
    final remainingNeeded = state.remainingNeededFor(item.neededCount);
    final tradeable = state.availableToTradeFor(item.neededCount);
    final wanted = state.wantedFor(item.neededCount);
    final accent = owned ? tierColor : Colors.white24;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: AppTheme.tradingCardDecoration(
          radius: 14,
          borderColor: accent.withValues(alpha: owned ? 0.55 : 0.14),
          backgroundColor: owned
              ? AppTheme.cardBackgroundAlt
              : AppTheme.cardBackgroundDeep,
        ),
        child: Padding(
          padding: EdgeInsets.all(landscape ? 6 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.24)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.cardBackgroundAlt, AppTheme.cardBackgroundDeep],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        item.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory_2_rounded,
                            color: owned ? accent : Colors.white38,
                            size: landscape ? 26 : 34,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: landscape ? 4 : 8),
              Text(
                item.name,
                maxLines: landscape ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: landscape ? 10 : 14,
                  color: owned ? Colors.white : Colors.white70,
                ),
              ),
              SizedBox(height: landscape ? 3 : 6),
              if (!landscape)
                Text(
                  '${item.group} • Need ${item.neededCount} • Collected ${state.collectedCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              SizedBox(height: landscape ? 3 : 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _MiniTag(
                    text: 'Need $remainingNeeded',
                    color: remainingNeeded > 0
                        ? Colors.white54
                        : Colors.lightGreenAccent,
                  ),
                  if (surplus > 0)
                    _MiniTag(
                      text: '$surplus spare',
                      color: Colors.amberAccent,
                    )
                  else
                    _MiniTag(
                      text: 'Collected ${state.collectedCount}',
                      color: owned ? AppTheme.neonCyan : Colors.white54,
                    ),
                  if (wanted)
                    const _MiniTag(text: 'Wanted', color: AppTheme.neonPink),
                  if (tradeable)
                    const _MiniTag(
                      text: 'Tradeable',
                      color: Colors.lightGreenAccent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
