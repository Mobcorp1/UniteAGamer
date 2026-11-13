import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_network_liquidity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcNetworkLiquidityAdminPanel extends StatelessWidget {
  const ArcNetworkLiquidityAdminPanel({super.key});

  static const int tradePlanningTarget = 100;
  static const int matchmakingPlanningTarget = 1000;

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('arc_trade_listings')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, listingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('arc_match_rider_profiles')
              .where('visibleInSearch', isEqualTo: true)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (listingSnapshot.hasError || profileSnapshot.hasError) {
              return const Text(
                'Trade / Match readiness could not be loaded.',
                style: TextStyle(color: Colors.redAccent),
              );
            }
            if (!listingSnapshot.hasData || !profileSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final metrics = const ArcNetworkLiquidityEngine().calculate(
              listings: [
                for (final doc in listingSnapshot.data!.docs) doc.data(),
              ],
              profiles: [
                for (final doc in profileSnapshot.data!.docs)
                  <String, dynamic>{...doc.data(), 'uid': doc.id},
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _metric('Open listings', metrics.openListings),
                    _metric('Active traders', metrics.activeTraders),
                    _metric('Aligned trades', metrics.alignedListingPairs),
                    _metric('Reciprocal swaps', metrics.reciprocalTradePairs),
                    _metric(
                      'Searchable Match profiles',
                      metrics.searchableMatchProfiles,
                    ),
                    _metric(
                      'Profiles with candidate',
                      metrics.profilesWithPotentialCandidate,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _target(
                  'Trade planning target',
                  metrics.activeTraders,
                  tradePlanningTarget,
                  '${metrics.alignedListingPairs} aligned pairs · '
                      '${metrics.reciprocalTradePairs} reciprocal swaps',
                ),
                const SizedBox(height: 10),
                _target(
                  'Match Raider planning target',
                  metrics.searchableMatchProfiles,
                  matchmakingPlanningTarget,
                  '${metrics.potentialCandidatePairs} region/platform-compatible candidate pairs',
                ),
                const SizedBox(height: 10),
                const Text(
                  'These are planning targets, not hard launch gates. Actual aligned listings and compatible candidates are the stronger readiness signal.',
                  style: TextStyle(color: Colors.white54, height: 1.3),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _metric(String label, int value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _target(String label, int current, int target, String detail) {
    final progress = target <= 0
        ? 1.0
        : (current / target).clamp(0.0, 1.0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$current / $target',
                style: const TextStyle(
                  color: ArcUiTokens.primaryAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 7),
          const SizedBox(height: 7),
          Text(
            detail,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
