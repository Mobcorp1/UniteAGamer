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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: AppTheme.tradingCardDecoration(
          radius: 12,
          borderColor: accent.withValues(alpha: owned ? 0.52 : 0.14),
          backgroundColor:
              owned ? AppTheme.cardBackgroundAlt : AppTheme.cardBackgroundDeep,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.cardBackgroundAlt,
                        AppTheme.cardBackgroundDeep,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      item.imageAsset,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: owned ? accent : Colors.white38,
                            size: landscape ? 22 : 26,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: landscape ? 10 : 11,
                  color: owned ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _compactGroupLabel(item.group),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tierColor.withValues(alpha: 0.84),
                  fontSize: landscape ? 8 : 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                alignment: WrapAlignment.center,
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
                    _MiniTag(text: '$surplus spare', color: Colors.amberAccent)
                  else
                    _MiniTag(
                      text: 'Got ${state.collectedCount}',
                      color: owned ? AppTheme.neonCyan : Colors.white54,
                    ),
                  if (wanted)
                    const _MiniTag(text: 'Wanted', color: AppTheme.neonPink),
                  if (tradeable)
                    const _MiniTag(
                      text: 'Trade',
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

  String _compactGroupLabel(String group) {
    final tierMatch = RegExp(
      r'Tier\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(group);
    if (tierMatch != null) return 'Tier ${tierMatch.group(1)}';
    final levelMatch = RegExp(
      r'Lv\.?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(group);
    if (levelMatch != null) return 'Tier ${levelMatch.group(1)}';
    return group;
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
