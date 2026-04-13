import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_food_queue_data.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ScrappyFeedQueueSection extends StatelessWidget {
  const ScrappyFeedQueueSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ArcScrappyFoodQueueData.items;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feed Scrappy',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          const Text(
            'Items to queue for feeding Scrappy.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: AppTheme.tradingCardDecoration(
                radius: 14,
                borderColor: Colors.white.withValues(alpha: 0.10),
                backgroundColor: AppTheme.cardBackgroundDeep,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white38,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if ((item.hint ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.hint!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
