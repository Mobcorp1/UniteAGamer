import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_food_queue_data.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ScrappyFeedQueueSection extends StatefulWidget {
  const ScrappyFeedQueueSection({super.key});

  @override
  State<ScrappyFeedQueueSection> createState() =>
      _ScrappyFeedQueueSectionState();
}

class _ScrappyFeedQueueSectionState extends State<ScrappyFeedQueueSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = ArcScrappyFoodQueueData.items;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expanded,
              onExpansionChanged: (value) => setState(() => _expanded = value),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              collapsedIconColor: AppTheme.neonPink,
              iconColor: AppTheme.neonPink,
              title: Text(
                'Feed Scrappy',
                style: AppTheme.tradingHeading(
                  fontSize: 20,
                  color: AppTheme.neonPink,
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Queue food items and keep quick location notes visible when needed.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              children: [
                const SizedBox(height: AppTheme.spaceS),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceS),
                      decoration: AppTheme.tradingCardDecoration(
                        radius: 14,
                        borderColor: Colors.white.withValues(alpha: 0.10),
                        backgroundColor: AppTheme.cardBackgroundDeep,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                              color: AppTheme.cardBackgroundAlt,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                item.imageAsset,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        color: Colors.white38,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.tradingHeading(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  (item.hint ?? '').isEmpty
                                      ? 'World food spawn. Add exact location intel as confirmed.'
                                      : item.hint!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
