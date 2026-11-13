import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_seed_guides.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';

/// Content boundary for Play Like A Pro.
///
/// PASS 341 deliberately ships a curated bundled catalogue for beta reliability.
/// UI code depends on this repository rather than seed data, so a later admin-backed
/// Firestore implementation can replace the source without changing screens or the
/// recommendation engine.
class PlayLikeAProGuideRepository {
  const PlayLikeAProGuideRepository();

  Future<List<PlayLikeAProGuide>> loadPublishedGuides() async {
    try {
      return PlayLikeAProSeedGuides.guides
          .where((guide) => guide.isPublished)
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('Play Like A Pro catalogue load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PlayLikeAProGuide?> loadGuide(String id) async {
    final guides = await loadPublishedGuides();
    for (final guide in guides) {
      if (guide.id == id) return guide;
    }
    return null;
  }
}
