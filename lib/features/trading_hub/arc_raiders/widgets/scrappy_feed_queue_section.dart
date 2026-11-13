import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_food_queue_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_food_queue_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ScrappyFeedQueueSection extends StatelessWidget {
  const ScrappyFeedQueueSection({super.key});

  static const goals = ['Feed'];

  @override
  Widget build(BuildContext context) {
    final items = [...ArcScrappyFoodQueueData.items]
      ..sort((a, b) => b.intelRank.compareTo(a.intelRank));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Feed Scrappy only. Crafting goals, workbench recipes and material '
              'planning now live in Crafting Planner.',
              style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _FeedItemCard(item: item),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({required this.item});

  final ArcScrappyFoodQueueItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        radius: ArcUiTokens.radiusM,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: .18,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ArcUiTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: .18),
              ),
            ),
            child: Image.asset(
              item.imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const Icon(
                Icons.restaurant_rounded,
                color: ArcUiTokens.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: ArcUiTokens.cardTitle(
                    fontSize: 14,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SCRAPPY FEED ITEM',
                  style: ArcUiTokens.metadata(color: ArcUiTokens.primaryAccent),
                ),
                if ((item.hint ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.hint!,
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textSecondary,
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
}
