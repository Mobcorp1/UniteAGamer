import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_drawer_nav_tile.dart';

void main() {
  group('ArcCompactNavigationCatalog', () {
    test('exposes only the grouped primary drawer destinations', () {
      expect(ArcCompactNavigationCatalog.groups.map((group) => group.label), [
        'COMMAND CENTRE',
        'TRACK',
        'PLAN',
        'TRADE',
        'PROFILE',
      ]);

      final labels = ArcCompactNavigationCatalog.items
          .map((item) => item.label)
          .toList(growable: false);

      expect(labels, [
        'Command Centre',
        'Blueprint Tracker',
        'Progress Trackers',
        'Raid Intelligence',
        'Raid Planner',
        'Favourite Loadout',
        'Trading Hub',
        'Match Rider',
        'My Hub',
        'Settings',
      ]);

      for (final oldDrawerItem in const [
        'Intel Snapshot',
        'Tracking',
        'Scrappy Tracker',
        'Play Like a Pro',
        'Plans & Referrals',
        'Admin Console',
        'Beta Feedback',
        'Help Centre',
      ]) {
        expect(labels, isNot(contains(oldDrawerItem)));
      }
    });

    test(
      'routes grouped secondary destinations to their primary drawer item',
      () {
        expect(
          _item('Command Centre').isSelected(MyHubScreen.routeName),
          isTrue,
        );
        expect(
          _item('Progress Trackers').isSelected(ScrappyGridScreen.routeName),
          isTrue,
        );
        expect(
          _item(
            'Progress Trackers',
          ).isSelected(ScrappyGridScreen.benchRouteName),
          isTrue,
        );
        expect(
          _item(
            'Progress Trackers',
          ).isSelected(RaidPlannerHuntTargetsScreen.routeName),
          isTrue,
        );
        expect(
          _item('Trading Hub').isSelected(SmartTradeAssistScreen.routeName),
          isTrue,
        );
        expect(
          _item('My Hub').isSelected(MyHubScreen.toolDeckRouteName),
          isTrue,
        );
      },
    );

    test('primary route names stay route backed', () {
      final routeNames = ArcCompactNavigationCatalog.items
          .map((item) => item.routeName)
          .toSet();

      expect(routeNames, contains(ArcCommandCentreScreen.routeName));
      expect(routeNames, contains(BlueprintGridScreen.routeName));
      expect(routeNames, contains(ArcProgressTrackersScreen.routeName));
      expect(routeNames, contains(ArcRaidIntelligenceScreen.routeName));
      expect(routeNames, contains(RaidPlannerScreen.routeName));
      expect(routeNames, contains(FavouriteLoadoutScreen.routeName));
      expect(routeNames, contains(TraderHubScreen.routeName));
      expect(routeNames, contains(ArcMatchRiderScreen.routeName));
      expect(routeNames, contains(MyHubScreen.toolDeckRouteName));
      expect(routeNames, contains(ProfileSettingsScreen.routeName));
    });

    test('declares feature gates for controlled drawer destinations', () {
      expect(
        _item('Blueprint Tracker').accessFlag,
        FeatureAccessFlag.blueprintTracker,
      );
      expect(
        _item('Raid Intelligence').accessFlag,
        FeatureAccessFlag.intelExplorer,
      );
      expect(_item('Raid Planner').accessFlag, FeatureAccessFlag.raidPlanner);
      expect(_item('Progress Trackers').accessFlag, isNull);
      expect(
        _item('Progress Trackers').visibilityAccessFlags,
        containsAll(<String>[
          FeatureAccessFlag.scrappyTracker,
          FeatureAccessFlag.benchTracker,
          FeatureAccessFlag.questTracker,
          FeatureAccessFlag.raidPlanner,
        ]),
      );
    });

    test('badge engine counts only actionable primary badge sources', () {
      final counts = ArcDrawerBadgeEngine.fromLiveData(
        blueprintStates: [
          _blueprint('owned', owned: true),
          _blueprint('missing', owned: false),
          _blueprint('priority', owned: true, priorityRank: 1),
        ],
        notifications: [
          _notification('read', read: true),
          _notification('unread-a', read: false),
          _notification('unread-b', read: false),
        ],
        incomingInvites: [
          _invite('accepted', status: 'accepted'),
          _invite('pending-a', status: 'pending'),
          _invite('pending-b', status: ' PENDING '),
        ],
      );

      expect(counts.blueprintTracker, 2);
      expect(counts.tradingHub, 2);
      expect(counts.matchRider, 2);
      expect(counts.countFor(ArcDrawerBadgeTarget.none), 0);
    });

    test('sorts drawer groups by personalisation without removing routes', () {
      const personalisation = ArcUserPersonalisationProfile(
        featureInterests: {
          ArcPersonalisationFeature.favouriteLoadout:
              ArcPersonalisationInterestLevel.primary,
        },
      );

      final groups = ArcCompactNavigationCatalog.groupsForPersonalisation(
        personalisation,
      );
      final plan = groups.firstWhere((group) => group.label == 'PLAN');
      final labels = groups
          .expand((group) => group.items)
          .map((item) => item.label)
          .toList(growable: false);

      expect(plan.items.first.label, 'Favourite Loadout');
      expect(labels, containsAll(['Trading Hub', 'Match Rider', 'Settings']));
    });
  });

  testWidgets('drawer nav tile shows positive badges and hides zero badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UagDrawerNavTile(
            title: 'Trading Hub',
            icon: Icons.storefront_rounded,
            selected: false,
            badgeCount: 5,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UagDrawerNavTile(
            title: 'Trading Hub',
            icon: Icons.storefront_rounded,
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('Trading Hub'), findsOneWidget);
  });
}

ArcCompactNavigationItem _item(String label) {
  return ArcCompactNavigationCatalog.items.firstWhere(
    (item) => item.label == label,
  );
}

ArcBlueprintState _blueprint(
  String id, {
  required bool owned,
  int priorityRank = 0,
}) {
  return ArcBlueprintState(
    blueprintId: id,
    owned: owned,
    dupesOwned: 0,
    priorityRank: priorityRank,
    updatedAt: null,
  );
}

TradingNotification _notification(String id, {required bool read}) {
  return TradingNotification(
    id: id,
    targetUid: 'target',
    actorUid: 'actor',
    title: 'Notification',
    body: 'Body',
    type: TradingNotificationType.sessionUpdated,
    listingId: '',
    offerId: '',
    sessionId: '',
    read: read,
    createdAt: null,
    updatedAt: null,
  );
}

ArcMatchRiderInvite _invite(String id, {required String status}) {
  return ArcMatchRiderInvite(
    id: id,
    senderUid: 'sender',
    senderName: 'Sender',
    recipientUid: 'recipient',
    recipientName: 'Recipient',
    status: status,
    note: '',
    createdAt: null,
    updatedAt: null,
  );
}
