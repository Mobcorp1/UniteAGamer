import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 0.92,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.22),
                    ),
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
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      item.imageAsset,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: owned ? accent : Colors.white38,
                            size: landscape ? 28 : 34,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: landscape ? 10.5 : 11.5,
                  color: owned ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
