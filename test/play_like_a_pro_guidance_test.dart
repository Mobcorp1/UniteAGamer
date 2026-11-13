import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_seed_guides.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';

void main() {
  group('Play Like A Pro content model', () {
    test('round-trips maintainable guide metadata', () {
      const guide = PlayLikeAProGuide(
        id: 'test-guide',
        title: 'Test guide',
        summary: 'Summary',
        category: PlayLikeAProCategory.loadouts,
        skillLevel: PlayLikeAProSkillLevel.advanced,
        tags: {'pvp', 'build'},
        mapIds: {ArcMapAssetRegistry.blueGateMapId},
        weaponNames: {'Anvil'},
        loadoutTags: {'balanced'},
        squadScope: PlayLikeAProSquadScope.solo,
        eventIds: {'night-raid'},
        featured: true,
        version: 3,
        relatedGuideIds: ['other'],
        sections: [
          PlayLikeAProSection(
            heading: 'Heading',
            body: 'Body',
            bullets: ['One'],
          ),
        ],
      );

      final decoded = PlayLikeAProGuide.fromMap(guide.id, guide.toMap());
      expect(decoded.title, guide.title);
      expect(decoded.category, PlayLikeAProCategory.loadouts);
      expect(decoded.mapIds, contains(ArcMapAssetRegistry.blueGateMapId));
      expect(decoded.weaponNames, contains('Anvil'));
      expect(decoded.squadScope, PlayLikeAProSquadScope.solo);
      expect(decoded.featured, isTrue);
      expect(decoded.version, 3);
      expect(decoded.sections.single.bullets, ['One']);
    });

    test(
      'bundled beta catalogue contains published expert guidance across core domains',
      () {
        final guides = PlayLikeAProSeedGuides.guides;
        expect(guides.length, greaterThanOrEqualTo(10));
        expect(guides.every((guide) => guide.isPublished), isTrue);
        expect(guides.map((guide) => guide.id).toSet().length, guides.length);
        expect(
          guides.map((guide) => guide.category),
          containsAll(<PlayLikeAProCategory>[
            PlayLikeAProCategory.extraction,
            PlayLikeAProCategory.soloTactics,
            PlayLikeAProCategory.squadTactics,
            PlayLikeAProCategory.loadouts,
            PlayLikeAProCategory.attachments,
            PlayLikeAProCategory.blueprintRoutes,
            PlayLikeAProCategory.mapRoutes,
            PlayLikeAProCategory.pve,
          ]),
        );
      },
    );
  });

  group('Play Like A Pro recommendation engine', () {
    test('promotes blueprint route guidance for blueprint-focused Raiders', () {
      final ranked = const PlayLikeAProRecommendationEngine().rank(
        guides: PlayLikeAProSeedGuides.guides,
        personalisation: const ArcUserPersonalisationProfile(
          goals: {ArcPersonalisationGoal.completeBlueprints},
          squadPreference: ArcSoloSquadPreference.flexible,
        ),
      );
      expect(
        ranked.take(5).map((item) => item.guide.category),
        contains(PlayLikeAProCategory.blueprintRoutes),
      );
    });

    test('uses favourite loadout weapon relevance', () {
      final now = DateTime(2026, 8, 10);
      final loadout = ArcSavedLoadout(
        id: 'favourite-loadout',
        name: 'Favourite',
        category: ArcLoadoutCategory.balanced,
        playStyle: ArcPlayerPlayStyle.balanced,
        augment: 'Survivor',
        primaryWeapon: 'Anvil',
        primaryAttachments: const [],
        secondaryWeapon: 'Stitcher',
        secondaryAttachments: const [],
        equipment: const [],
        consumables: const [],
        createdAt: now,
        updatedAt: now,
      );
      final ranked = const PlayLikeAProRecommendationEngine().rank(
        guides: PlayLikeAProSeedGuides.guides,
        favouriteLoadout: loadout,
      );
      final roleCheck = ranked.firstWhere(
        (item) => item.guide.id == 'loadout-role-check',
      );
      expect(roleCheck.reasons, contains('Relevant to your Favourite Loadout'));
      expect(roleCheck.score, greaterThan(20));
    });

    test('uses active map relevance for future Command Centre handoff', () {
      final ranked = const PlayLikeAProRecommendationEngine().rank(
        guides: PlayLikeAProSeedGuides.guides,
        activeMapId: ArcMapAssetRegistry.blueGateMapId,
      );
      expect(
        ranked.first.guide.mapIds,
        contains(ArcMapAssetRegistry.blueGateMapId),
      );
      expect(ranked.first.reasons, contains('Relevant to your active map'));
    });
  });
}
