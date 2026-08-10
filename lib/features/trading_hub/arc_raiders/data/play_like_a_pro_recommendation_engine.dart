import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';

class PlayLikeAProRecommendation {
  const PlayLikeAProRecommendation({
    required this.guide,
    required this.score,
    required this.reasons,
  });

  final PlayLikeAProGuide guide;
  final int score;
  final List<String> reasons;
}

class PlayLikeAProRecommendationEngine {
  const PlayLikeAProRecommendationEngine();

  List<PlayLikeAProRecommendation> rank({
    required Iterable<PlayLikeAProGuide> guides,
    ArcUserPersonalisationProfile personalisation =
        ArcUserPersonalisationProfile.defaults,
    ArcSavedLoadout? favouriteLoadout,
    String? activeMapId,
    int limit = 6,
  }) {
    final ranked = <PlayLikeAProRecommendation>[];
    for (final guide in guides.where((item) => item.isPublished)) {
      var score = guide.featured ? 16 : 0;
      final reasons = <String>[];

      final categoryScore = _goalScore(guide, personalisation.goals);
      if (categoryScore > 0) {
        score += categoryScore;
        reasons.add('Matches your saved goals');
      }

      if (_matchesSquad(guide.squadScope, personalisation.squadPreference)) {
        score += guide.squadScope == PlayLikeAProSquadScope.any ? 2 : 12;
        if (guide.squadScope != PlayLikeAProSquadScope.any) {
          reasons.add(
            'Matches your ${personalisation.squadPreference.name} preference',
          );
        }
      } else if (guide.squadScope != PlayLikeAProSquadScope.any) {
        score -= 8;
      }

      final playStyleText = <String>{
        ...personalisation.playStyleIds,
        ...personalisation.archetypeIds,
      }.join(' ').toLowerCase();
      if (playStyleText.isNotEmpty &&
          guide.tags.any((tag) => playStyleText.contains(tag.toLowerCase()))) {
        score += 10;
        reasons.add('Matches your play style');
      }

      if (favouriteLoadout != null) {
        final weapons = <String>{
          favouriteLoadout.primaryWeapon.toLowerCase(),
          favouriteLoadout.secondaryWeapon.toLowerCase(),
        };
        if (guide.weaponNames.any(
          (weapon) => weapons.contains(weapon.toLowerCase()),
        )) {
          score += 22;
          reasons.add('Relevant to your Favourite Loadout');
        }
        if (guide.loadoutTags.contains(favouriteLoadout.playStyle.name) ||
            guide.loadoutTags.contains(favouriteLoadout.category.name)) {
          score += 10;
          reasons.add('Fits your saved loadout style');
        }
      }

      final mapId = activeMapId?.trim();
      if (mapId?.isNotEmpty == true && guide.mapIds.contains(mapId)) {
        score += 24;
        reasons.add('Relevant to your active map');
      }

      ranked.add(
        PlayLikeAProRecommendation(
          guide: guide,
          score: score,
          reasons: reasons,
        ),
      );
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      if (a.guide.featured != b.guide.featured) {
        return a.guide.featured ? -1 : 1;
      }
      return a.guide.title.compareTo(b.guide.title);
    });
    return ranked.take(limit).toList(growable: false);
  }

  int _goalScore(PlayLikeAProGuide guide, Set<ArcPersonalisationGoal> goals) {
    var score = 0;
    for (final goal in goals) {
      score += switch (goal) {
        ArcPersonalisationGoal.completeBlueprints =>
          guide.category == PlayLikeAProCategory.blueprintRoutes ||
                  guide.tags.contains('blueprints')
              ? 18
              : 0,
        ArcPersonalisationGoal.buildFavouriteLoadout =>
          guide.isLoadoutRelevant ||
                  {
                    PlayLikeAProCategory.loadouts,
                    PlayLikeAProCategory.weapons,
                    PlayLikeAProCategory.attachments,
                  }.contains(guide.category)
              ? 18
              : 0,
        ArcPersonalisationGoal.planRaids =>
          {
                PlayLikeAProCategory.mapRoutes,
                PlayLikeAProCategory.lootRoutes,
                PlayLikeAProCategory.blueprintRoutes,
                PlayLikeAProCategory.extraction,
              }.contains(guide.category)
              ? 18
              : 0,
        ArcPersonalisationGoal.trackResources ||
        ArcPersonalisationGoal.upgradeBench =>
          {
                PlayLikeAProCategory.resourcePriorities,
                PlayLikeAProCategory.inventoryPreparation,
              }.contains(guide.category)
              ? 14
              : 0,
        ArcPersonalisationGoal.progressQuests ||
        ArcPersonalisationGoal.followOperations =>
          {
                PlayLikeAProCategory.eventPreparation,
                PlayLikeAProCategory.inventoryPreparation,
                PlayLikeAProCategory.extraction,
              }.contains(guide.category)
              ? 12
              : 0,
        ArcPersonalisationGoal.findSquads =>
          guide.category == PlayLikeAProCategory.squadTactics ? 18 : 0,
        ArcPersonalisationGoal.exploreEverything => guide.featured ? 4 : 0,
        ArcPersonalisationGoal.tradeBlueprints ||
        ArcPersonalisationGoal.manageCosmetics ||
        ArcPersonalisationGoal.receiveCommunityIntel ||
        ArcPersonalisationGoal.improveReputation => 0,
      };
    }
    return score.clamp(0, 30);
  }

  bool _matchesSquad(
    PlayLikeAProSquadScope guideScope,
    ArcSoloSquadPreference preference,
  ) {
    if (guideScope == PlayLikeAProSquadScope.any ||
        preference == ArcSoloSquadPreference.flexible) {
      return true;
    }
    return switch (preference) {
      ArcSoloSquadPreference.solo => guideScope == PlayLikeAProSquadScope.solo,
      ArcSoloSquadPreference.duo => guideScope == PlayLikeAProSquadScope.duo,
      ArcSoloSquadPreference.squad =>
        guideScope == PlayLikeAProSquadScope.squad,
      ArcSoloSquadPreference.flexible => true,
    };
  }
}
