import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';

enum ArcDrawerBadgeTarget { none, blueprintTracker, tradingHub, matchRider }

class ArcCompactNavigationItem {
  const ArcCompactNavigationItem({
    required this.label,
    required this.icon,
    required this.routeName,
    this.selectedRouteNames = const <String>[],
    this.badgeTarget = ArcDrawerBadgeTarget.none,
    this.accessFlag,
    this.comingSoonWhenLocked = false,
  });

  final String label;
  final IconData icon;
  final String routeName;
  final List<String> selectedRouteNames;
  final ArcDrawerBadgeTarget badgeTarget;
  final String? accessFlag;
  final bool comingSoonWhenLocked;

  bool isSelected(String? currentRoute) {
    if (currentRoute == null || currentRoute.isEmpty) return false;
    return routeName == currentRoute ||
        selectedRouteNames.contains(currentRoute);
  }
}

class ArcCompactNavigationGroup {
  const ArcCompactNavigationGroup({required this.label, required this.items});

  final String label;
  final List<ArcCompactNavigationItem> items;
}

class ArcCompactNavigationCatalog {
  const ArcCompactNavigationCatalog._();

  static const groups = <ArcCompactNavigationGroup>[
    ArcCompactNavigationGroup(
      label: 'COMMAND CENTRE',
      items: <ArcCompactNavigationItem>[
        ArcCompactNavigationItem(
          label: 'Command Centre',
          icon: Icons.dashboard_customize_outlined,
          routeName: ArcCommandCentreScreen.routeName,
          selectedRouteNames: <String>[MyHubScreen.routeName],
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'TRACK',
      items: <ArcCompactNavigationItem>[
        ArcCompactNavigationItem(
          label: 'Blueprint Tracker',
          icon: Icons.grid_on_rounded,
          routeName: BlueprintGridScreen.routeName,
          badgeTarget: ArcDrawerBadgeTarget.blueprintTracker,
        ),
        ArcCompactNavigationItem(
          label: 'Progress Trackers',
          icon: Icons.track_changes_rounded,
          routeName: ArcProgressTrackersScreen.routeName,
          selectedRouteNames: <String>[
            ScrappyGridScreen.routeName,
            ScrappyGridScreen.benchRouteName,
            ScrappyGridScreen.questRouteName,
            RaidPlannerHuntTargetsScreen.routeName,
          ],
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'PLAN',
      items: <ArcCompactNavigationItem>[
        ArcCompactNavigationItem(
          label: 'Raid Planner',
          icon: Icons.route_rounded,
          routeName: RaidPlannerScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Favourite Loadout',
          icon: Icons.inventory_2_outlined,
          routeName: FavouriteLoadoutScreen.routeName,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'TRADE',
      items: <ArcCompactNavigationItem>[
        ArcCompactNavigationItem(
          label: 'Trading Hub',
          icon: Icons.storefront_rounded,
          routeName: TraderHubScreen.routeName,
          accessFlag: FeatureAccessFlag.traderHub,
          badgeTarget: ArcDrawerBadgeTarget.tradingHub,
          selectedRouteNames: <String>[
            TradingListingsScreen.routeName,
            TradingCreateListingScreen.routeName,
            TradingActivityScreen.routeName,
            TradingMyListingsScreen.routeName,
            TradingMyOffersScreen.routeName,
            TradingBlueprintWatchesScreen.routeName,
            TradingListingQueuesScreen.routeName,
            TradingTradeSessionsScreen.routeName,
            TradingNotificationsScreen.routeName,
            SmartTradeAssistScreen.routeName,
          ],
        ),
        ArcCompactNavigationItem(
          label: 'Match Rider',
          icon: Icons.groups_2_outlined,
          routeName: ArcMatchRiderScreen.routeName,
          accessFlag: FeatureAccessFlag.matchRaider,
          badgeTarget: ArcDrawerBadgeTarget.matchRider,
          comingSoonWhenLocked: true,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'PROFILE',
      items: <ArcCompactNavigationItem>[
        ArcCompactNavigationItem(
          label: 'My Hub',
          icon: Icons.person_pin_circle_outlined,
          routeName: MyHubScreen.toolDeckRouteName,
          selectedRouteNames: <String>[
            MyHubScreen.toolDeckRouteName,
            TradingProfileScreen.routeName,
            PlayLikeAProScreen.routeName,
            OperationsCommandScreen.routeName,
          ],
        ),
        ArcCompactNavigationItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          routeName: ProfileSettingsScreen.routeName,
        ),
      ],
    ),
  ];

  static Iterable<ArcCompactNavigationItem> get items sync* {
    for (final group in groups) {
      yield* group.items;
    }
  }
}

class ArcDrawerBadgeCounts {
  const ArcDrawerBadgeCounts({
    this.blueprintTracker = 0,
    this.tradingHub = 0,
    this.matchRider = 0,
  });

  final int blueprintTracker;
  final int tradingHub;
  final int matchRider;

  int countFor(ArcDrawerBadgeTarget target) => switch (target) {
    ArcDrawerBadgeTarget.none => 0,
    ArcDrawerBadgeTarget.blueprintTracker => blueprintTracker,
    ArcDrawerBadgeTarget.tradingHub => tradingHub,
    ArcDrawerBadgeTarget.matchRider => matchRider,
  };
}

class ArcDrawerBadgeEngine {
  const ArcDrawerBadgeEngine._();

  static ArcDrawerBadgeCounts fromLiveData({
    Iterable<ArcBlueprintState> blueprintStates = const <ArcBlueprintState>[],
    Iterable<TradingNotification> notifications = const <TradingNotification>[],
    Iterable<ArcMatchRiderInvite> incomingInvites =
        const <ArcMatchRiderInvite>[],
  }) {
    return ArcDrawerBadgeCounts(
      blueprintTracker: blueprintStates
          .where((state) => state.wanted || state.isPrioritized)
          .length,
      tradingHub: notifications
          .where((notification) => !notification.read)
          .length,
      matchRider: incomingInvites
          .where((invite) => invite.status.trim().toLowerCase() == 'pending')
          .length,
    );
  }
}
