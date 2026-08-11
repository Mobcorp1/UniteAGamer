import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_availability_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_match_compatibility_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_notification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_favourite_rider.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_objective_signals.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_listing_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';

void main() {
  group('closed beta match privacy', () {
    const engine = ArcMatchCompatibilityEngine();

    test('maps percentage bands to protected labels', () {
      expect(ArcMatchCompatibilityEngine.matchLabel(100), 'Strong fit');
      expect(ArcMatchCompatibilityEngine.matchLabel(92), 'Strong fit');
      expect(ArcMatchCompatibilityEngine.matchLabel(77), 'Good fit');
      expect(ArcMatchCompatibilityEngine.matchLabel(60), 'Compatible');
      expect(ArcMatchCompatibilityEngine.matchLabel(40), 'Worth a look');
    });

    test('keeps public summary free of internal reasons', () {
      final result = engine.score(me: _profile('me'), other: _profile('other'));

      expect(result.percentageLabel, endsWith('% Match'));
      expect(result.publicLabel, isNotEmpty);
      expect(
        result.publicExplanation,
        'Your score is based on compatibility signals from your profile, availability and activity.',
      );
      expect(result.publicExplanation, isNot(contains('Shared')));
      expect(result.publicExplanation, isNot(contains('Blueprint')));
    });

    test('scores owned blueprint helper fit without active duplicate', () {
      final helper = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
        meSignals: const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Bettina'],
        ),
        otherSignals: const ArcMatchObjectiveSignals(
          neededBlueprintIds: <String>['Bettina'],
        ),
      );
      final neutralBase = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
      );

      expect(helper.score, greaterThan(neutralBase.score));
    });

    test('rewards complementary blueprint hunts above one-way help', () {
      final oneWay = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
        meSignals: const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Bettina'],
        ),
        otherSignals: const ArcMatchObjectiveSignals(
          neededBlueprintIds: <String>['Bettina'],
        ),
      );
      final complementary = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
        meSignals: const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Bettina'],
          neededBlueprintIds: <String>['Tempest'],
        ),
        otherSignals: const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Tempest'],
          neededBlueprintIds: <String>['Bettina'],
        ),
      );

      expect(complementary.score, greaterThan(oneWay.score));
    });

    test('uses trials and session intent compatibility internally', () {
      final result = engine.score(
        me: _profile('me').copyWith(sessionIntent: 'Trials'),
        other: _profile('other').copyWith(sessionIntent: 'Trials'),
        meSignals: const ArcMatchObjectiveSignals(
          trialIds: <String>['weekly-trial'],
        ),
        otherSignals: const ArcMatchObjectiveSignals(
          trialIds: <String>['weekly-trial'],
        ),
      );

      expect(result.score, greaterThanOrEqualTo(70));
      expect(result.reasons, contains('Same session intent: Trials'));
    });
  });

  group('favourite riders and preferences', () {
    test('maps favourite rider relationship history privately', () {
      final favourite = ArcFavouriteRider(
        id: ArcFavouriteRider.idFor('owner', 'rider'),
        ownerUid: 'owner',
        riderUid: 'rider',
        completedTrades: 2,
        squadSessions: 1,
        previousBlueprintOffer: true,
      );
      final restored = ArcFavouriteRider.fromMap(favourite.toMap());

      expect(restored.ownerUid, 'owner');
      expect(restored.riderUid, 'rider');
      expect(restored.relationshipSummary, contains('2 completed trades'));
      expect(
        restored.relationshipSummary,
        contains('Previous blueprint offer'),
      );
    });

    test('maps trade preferences into ranking tags', () {
      const preferences = ArcTradePreferences(
        ownerUid: 'owner',
        fastTrades: true,
        favouriteRidersFirst: true,
        noUnsolicitedMessages: true,
      );

      expect(preferences.rankingTags, contains('Fast trades'));
      expect(preferences.rankingTags, contains('Favourite Raiders first'));
      expect(preferences.rankingTags, contains('No unsolicited messages'));
      expect(
        ArcTradePreferences.fromMap(preferences.toMap()).ownerUid,
        'owner',
      );
    });
  });

  group('availability and notification intelligence', () {
    const availabilityEngine = ArcAvailabilityIntelligenceEngine();
    const notificationEngine = ArcTradeNotificationEngine();

    test('detects two-player and three-player overlap', () {
      final first = _availability('mon', '18:00', '21:00');
      final second = _availability('mon', '19:00', '22:00');
      final third = _availability('mon', '20:00', '23:00');

      final two = availabilityEngine.twoPlayerOverlap(
        first: first,
        second: second,
        now: DateTime(2026, 7, 13, 19, 30),
      );
      final three = availabilityEngine.threePlayerOverlap(
        first: first,
        second: second,
        third: third,
        now: DateTime(2026, 7, 13, 20, 30),
      );

      expect(two.bothAvailableNow, isTrue);
      expect(two.fromTime, '19:00');
      expect(three.hasSharedWindow, isTrue);
      expect(three.fromTime, '20:00');
    });

    test('respects quiet hours and next-login notification preferences', () {
      final quiet = notificationEngine.evaluate(
        preference: ArcBlueprintWatchNotificationPreference.immediate,
        favouriteRiderEvent: true,
        userAvailableNow: true,
        sellerAvailableNow: true,
        quietHoursActive: true,
        watchedTradeReady: true,
      );
      final nextLogin = notificationEngine.evaluate(
        preference: ArcBlueprintWatchNotificationPreference.nextLogin,
        favouriteRiderEvent: true,
        userAvailableNow: true,
        sellerAvailableNow: true,
        quietHoursActive: false,
        watchedTradeReady: true,
      );

      expect(quiet.shouldNotifyNow, isFalse);
      expect(quiet.queueForNextLogin, isTrue);
      expect(nextLogin.shouldNotifyNow, isFalse);
      expect(nextLogin.queueForNextLogin, isTrue);
    });
  });

  group('structured offers and private inventory protection', () {
    test(
      'blueprint watch IDs prevent duplicate records per owner objective',
      () {
        final id = ArcBlueprintWatch.idFor(
          ownerUid: 'owner',
          blueprintId: 'wolfpack',
        );
        final duplicateAttempt = ArcBlueprintWatch.idFor(
          ownerUid: 'owner',
          blueprintId: 'Wolfpack',
        );
        final otherOwner = ArcBlueprintWatch.idFor(
          ownerUid: 'other',
          blueprintId: 'wolfpack',
        );

        final watch = ArcBlueprintWatch(
          id: id,
          ownerUid: 'owner',
          type: ArcBlueprintWatchType.blueprint,
          blueprintId: 'wolfpack',
          blueprintDisplayName: 'Wolfpack',
        );

        expect(duplicateAttempt, id);
        expect(otherOwner, isNot(id));
        expect(watch.copyWith(active: false).isPaused, isTrue);
        expect(watch.copyWith(active: true).active, isTrue);
        expect(watch.copyWith(linkedListingId: 'listing-1').hasMatch, isTrue);
      },
    );

    test('calculates duplicate queue release timing', () {
      const queueItem = ArcTradeListingQueueItem(
        id: 'queue-1',
        ownerUid: 'owner',
        blueprintId: 'wolfpack',
        blueprintName: 'Wolfpack',
        sourceListingId: 'listing-1',
        releasePolicy: ArcDuplicateReleasePolicy.afterThirtyMinutes,
      );
      final completedAt = DateTime(2026, 1, 1, 12);
      final releaseAt = queueItem.nextReleaseAt(completedAt);

      expect(releaseAt, DateTime(2026, 1, 1, 12, 30));
      expect(
        queueItem
            .copyWithReleaseAt(releaseAt)
            .shouldReleaseAt(DateTime(2026, 1, 1, 12, 31)),
        isTrue,
      );
    });

    test('duplicate queue state keeps private stock off public listings', () {
      final queue = ArcTradeListingQueueItem.createForListing(
        id: ArcTradeListingQueueItem.idFor(
          ownerUid: 'owner',
          sourceListingId: 'listing-1',
        ),
        ownerUid: 'owner',
        blueprintId: 'wolfpack',
        blueprintName: 'Wolfpack',
        sourceListingId: 'listing-1',
        releasePolicy: ArcDuplicateReleasePolicy.askBeforeRelisting,
        queuedQuantity: 3,
        now: DateTime(2026, 1),
      );

      expect(queue.remainingQuantity, 3);
      expect(queue.publicQuantity, 1);
      expect(queue.canManuallyRelease, isTrue);
      expect(queue.copyWith(releasedQuantity: 3).canManuallyRelease, isFalse);

      final listing = _listing().copyWith(
        queueId: queue.id,
        queueSourceListingId: queue.sourceListingId,
        queueReleaseNumber: 1,
      );
      final map = listing.toMap();

      expect(map['queueId'], queue.id);
      expect(map['queueReleaseNumber'], 1);
      expect(map.containsKey('remainingQuantity'), isFalse);
      expect(map.containsKey('totalQueued'), isFalse);
    });

    test('trade objective notifications expose safe target metadata', () {
      final notification = TradingNotification(
        id: 'notification-1',
        targetUid: 'owner',
        actorUid: 'owner',
        title: 'Watch match',
        body: 'Wolfpack has a match.',
        type: TradingNotificationType.blueprintWatchMatch,
        listingId: 'listing-1',
        offerId: '',
        sessionId: '',
        watchId: 'watch-1',
        queueId: '',
        read: false,
        createdAt: DateTime(2026, 1),
        updatedAt: DateTime(2026, 1),
      );
      final restored = TradingNotification.fromMap(notification.toMap());

      expect(restored.typeLabel, 'Watch Match');
      expect(restored.hasListingTarget, isTrue);
      expect(restored.hasWatchTarget, isTrue);
      expect(restored.hasQueueTarget, isFalse);
    });

    test('structured offer expiry is deterministic', () {
      final offer = _offer(expiresAt: DateTime(2026, 1, 1, 12));

      expect(offer.isExpiredAt(DateTime(2026, 1, 1, 11, 59)), isFalse);
      expect(offer.isExpiredAt(DateTime(2026, 1, 1, 12, 1)), isTrue);
      expect(offer.effectiveStatus, TradingOfferStatus.expired);
    });

    test('structured offer summaries preserve preparation state', () {
      final offer = TradingOffer(
        id: 'offer-structured',
        listingId: 'listing-1',
        senderUid: 'buyer',
        receiverUid: 'seller',
        senderName: 'Buyer',
        senderGamerTag: '',
        senderPlatform: 'PC',
        offeredBlueprintText: '',
        smallBundles: 0,
        mediumBundles: 0,
        largeBundles: 0,
        seedTotal: 0,
        includesResources: false,
        resourcesText: '',
        exactBundleOffer: const ArcExactTradeBundleOffer(
          templateId: 'payment',
          preparing: true,
          components: <ArcTradeBundleComponent>[
            ArcTradeBundleComponent(
              id: 'queen-reactor',
              type: ArcTradeBundleComponentType.resource,
              itemId: 'queen-reactor',
              itemName: 'Queen Reactor',
              quantity: 2,
            ),
          ],
        ),
        note: '',
        status: TradingOfferStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      final restored = TradingOffer.fromMap(offer.toMap());

      expect(restored.offerSummary, contains('Queen Reactor'));
      expect(restored.offerSummary, contains('preparing bundle'));
    });

    test('listing maps mode fields without public duplicate stock counts', () {
      final listing = _listing().copyWithModeForTest();
      final map = listing.toMap();

      expect(map['listingMode'], TradingListingMode.favouriteRidersFirst.name);
      expect(map.containsKey('duplicateReleasePolicy'), isTrue);
      expect(map.containsKey('totalDuplicateInventory'), isFalse);
      expect(map.containsKey('duplicateStockCount'), isFalse);
      expect(map.containsKey('publicStockCount'), isFalse);
    });

    test('public match profile deletes private inventory fields', () {
      final map = _profile('me')
          .copyWith(
            helperBlueprintIds: const <String>['bettina'],
            blueprintTargets: const <String>['tempest'],
          )
          .toPublicMap();

      expect(map.containsKey('helperBlueprintIds'), isTrue);
      expect(
        map.values.map((value) => value.toString()),
        isNot(contains('bettina')),
      );
      expect(
        map.values.map((value) => value.toString()),
        isNot(contains('tempest')),
      );
      expect(map.containsKey('ownedBlueprintIds'), isTrue);
      expect(map.containsKey('duplicateBlueprintIds'), isTrue);
      expect(map.containsKey('dupesOwned'), isTrue);
    });
  });
}

ArcMatchRiderProfile _profile(String uid) {
  return ArcMatchRiderProfile.empty(uid).copyWith(
    uid: uid,
    displayName: uid,
    archetypes: const <String>['Blueprint Grinder'],
    playstyles: const <String>['Blueprint farming'],
    goals: const <String>['Blueprint farming'],
    comms: const <String>['Pings'],
    squadPreferences: const <String>['Duos'],
    platform: 'PC',
    region: 'EU',
    serverPreference: 'Europe',
    crossplayEnabled: true,
    lookingNow: true,
  );
}

ArcMatchRiderProfile _neutralProfile(String uid) {
  return ArcMatchRiderProfile.empty(uid).copyWith(
    uid: uid,
    displayName: uid,
    platform: 'PC',
    region: 'EU',
    serverPreference: 'Europe',
    crossplayEnabled: true,
    lookingNow: false,
  );
}

ArcAvailability _availability(String dayKey, String fromTime, String toTime) {
  return ArcAvailability(
    scheduleType: 'weekly',
    useEveryWeek: true,
    weeks: <ArcAvailabilityWeek>[
      ArcAvailabilityWeek(
        label: 'Week 1',
        slots: <ArcAvailabilitySlot>[
          ArcAvailabilitySlot(
            dayKey: dayKey,
            enabled: true,
            fromTime: fromTime,
            toTime: toTime,
          ),
        ],
      ),
    ],
  );
}

TradingOffer _offer({required DateTime expiresAt}) {
  return TradingOffer(
    id: 'offer-1',
    listingId: 'listing-1',
    senderUid: 'buyer',
    receiverUid: 'seller',
    senderName: 'Buyer',
    senderGamerTag: '',
    senderPlatform: 'PC',
    offeredBlueprintText: 'Tempest',
    smallBundles: 0,
    mediumBundles: 0,
    largeBundles: 0,
    seedTotal: 0,
    includesResources: false,
    resourcesText: '',
    note: '',
    status: TradingOfferStatus.pending,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    expiresAt: expiresAt,
  );
}

TradingListing _listing() {
  final now = DateTime(2026, 1, 1);
  return TradingListing(
    id: 'listing-1',
    ownerUid: 'seller',
    traderName: 'Seller',
    gamerTag: '',
    preferredPlatform: 'PC',
    title: 'Wolfpack for Tempest',
    offeredItem: 'Wolfpack',
    wantedText: 'Tempest',
    offeredBlueprintNames: const <String>['Wolfpack'],
    wantedBlueprintNames: const <String>['Tempest'],
    offeredAssetNames: const <String>[],
    wantedAssetNames: const <String>[],
    offeredTradeItemIds: const <String>['wolfpack'],
    wantedTradeItemIds: const <String>['tempest'],
    offeredTradeItemNames: const <String>['Wolfpack'],
    wantedTradeItemNames: const <String>['Tempest'],
    wantsNothing: false,
    listingType: TradingListingType.specificWant,
    riskLevel: TradingRiskLevel.low,
    completedTrades: 0,
    noShows: 0,
    betrayalFlags: 0,
    region: 'EU',
    playWindow: 'Evenings',
    smallBundles: 0,
    mediumBundles: 0,
    largeBundles: 0,
    seedTotalOffered: 0,
    acceptsBlueprints: true,
    acceptsSeeds: false,
    acceptsResources: true,
    seriousOffersOnly: false,
    tradeAsBundle: true,
    allowPartialOffers: false,
    listingMode: TradingListingMode.favouriteRidersFirst,
    duplicateReleasePolicy: ArcDuplicateReleasePolicy.askBeforeRelisting,
    favouriteRidersFirst: true,
    maxActiveOffers: 3,
    expiresAt: now.add(const Duration(days: 3)),
    notes: '',
    active: true,
    createdAt: now,
    updatedAt: now,
  );
}

extension on ArcTradeListingQueueItem {
  ArcTradeListingQueueItem copyWithReleaseAt(DateTime? releaseAt) {
    return ArcTradeListingQueueItem(
      id: id,
      ownerUid: ownerUid,
      blueprintId: blueprintId,
      blueprintName: blueprintName,
      sourceListingId: sourceListingId,
      releasePolicy: releasePolicy,
      position: position,
      publiclyReleased: publiclyReleased,
      createdAt: createdAt,
      releaseAt: releaseAt,
      updatedAt: updatedAt,
    );
  }
}

extension on TradingListing {
  TradingListing copyWithModeForTest() => this;
}
