import '../screens/arc_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/legal_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_data_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_away_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_intel_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart';

enum ArcDrawerBadgeTarget { none, blueprintTracker, tradingHub, matchRider }

class ArcCompactNavigationItem {
  const ArcCompactNavigationItem({
    required this.label,
    required this.icon,
    required this.routeName,
    this.selectedRouteNames = const <String>[],
    this.badgeTarget = ArcDrawerBadgeTarget.none,
    this.accessFlag,
    this.visibilityAccessFlags = const <String>[],
    this.comingSoonWhenLocked = false,
    this.personalisationFeature,
  });

  final String label;
  final IconData icon;
  final String routeName;
  final List<String> selectedRouteNames;
  final ArcDrawerBadgeTarget badgeTarget;
  final String? accessFlag;
  final List<String> visibilityAccessFlags;
  final bool comingSoonWhenLocked;
  final ArcPersonalisationFeature? personalisationFeature;

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
      label: 'DISCOVER & RUN',
      items: [
        ArcCompactNavigationItem(
          label: 'Discover UAG',
          icon: Icons.explore_outlined,
          routeName: ArcRaidersHubScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Events',
          icon: Icons.event_outlined,
          routeName: ArcEventsScreen.routeName,
          accessFlag: FeatureAccessFlag.raidPlanner,
        ),
        ArcCompactNavigationItem(
          label: 'Command Centre',
          icon: Icons.dashboard_customize_outlined,
          routeName: ArcCommandCentreScreen.routeName,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'RAID & INTELLIGENCE',
      items: [
        ArcCompactNavigationItem(
          label: 'Raid Intelligence',
          icon: Icons.radar_rounded,
          routeName: ArcRaidIntelligenceScreen.routeName,
          accessFlag: FeatureAccessFlag.intelExplorer,
        ),
        ArcCompactNavigationItem(
          label: 'Raid Planner',
          icon: Icons.route_rounded,
          routeName: RaidPlannerScreen.routeName,
          accessFlag: FeatureAccessFlag.raidPlanner,
        ),
        ArcCompactNavigationItem(
          label: 'Hunt Targets',
          icon: Icons.track_changes_rounded,
          routeName: RaidPlannerHuntTargetsScreen.routeName,
          accessFlag: FeatureAccessFlag.raidPlanner,
        ),
        ArcCompactNavigationItem(
          label: 'Report a Rat / Contracts',
          icon: Icons.gavel_rounded,
          routeName: ArcRaiderContractsScreen.routeName,
          accessFlag: FeatureAccessFlag.raiderContracts,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'PROGRESSION & TRACKING',
      items: [
        ArcCompactNavigationItem(
          label: 'Blueprint Tracker',
          icon: Icons.grid_on_rounded,
          routeName: BlueprintGridScreen.routeName,
          accessFlag: FeatureAccessFlag.blueprintTracker,
          badgeTarget: ArcDrawerBadgeTarget.blueprintTracker,
        ),
        ArcCompactNavigationItem(
          label: 'Scrappy Tracker',
          icon: Icons.recycling_rounded,
          routeName: ScrappyGridScreen.routeName,
          accessFlag: FeatureAccessFlag.scrappyTracker,
        ),
        ArcCompactNavigationItem(
          label: 'Bench Tracker',
          icon: Icons.handyman_outlined,
          routeName: ScrappyGridScreen.benchRouteName,
          accessFlag: FeatureAccessFlag.benchTracker,
        ),
        ArcCompactNavigationItem(
          label: 'Quest Tracker',
          icon: Icons.assignment_turned_in_outlined,
          routeName: ScrappyGridScreen.questRouteName,
          accessFlag: FeatureAccessFlag.questTracker,
        ),
        ArcCompactNavigationItem(
          label: 'Progress Trackers',
          icon: Icons.track_changes_rounded,
          routeName: ArcProgressTrackersScreen.routeName,
          visibilityAccessFlags: [
            FeatureAccessFlag.scrappyTracker,
            FeatureAccessFlag.benchTracker,
            FeatureAccessFlag.questTracker,
            FeatureAccessFlag.raidPlanner,
          ],
        ),
        ArcCompactNavigationItem(
          label: 'My Intel',
          icon: Icons.insights_outlined,
          routeName: MyIntelScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Favourite Loadout',
          icon: Icons.inventory_2_outlined,
          routeName: FavouriteLoadoutScreen.routeName,
          personalisationFeature: ArcPersonalisationFeature.favouriteLoadout,
        ),
        ArcCompactNavigationItem(
          label: 'Operations',
          icon: Icons.military_tech_outlined,
          routeName: OperationsCommandScreen.routeName,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'TRADE & INVENTORY',
      items: [
        ArcCompactNavigationItem(
          label: 'Trading Hub',
          icon: Icons.storefront_rounded,
          routeName: TraderHubScreen.routeName,
          accessFlag: FeatureAccessFlag.traderHub,
          badgeTarget: ArcDrawerBadgeTarget.tradingHub,
          selectedRouteNames: [
            TradingListingsScreen.routeName,
            TradingCreateListingScreen.routeName,
            TradingActivityScreen.routeName,
            TradingMyListingsScreen.routeName,
            TradingMyOffersScreen.routeName,
            TradingBlueprintWatchesScreen.routeName,
            TradingListingQueuesScreen.routeName,
            TradingTradeSessionsScreen.routeName,
            TradingNotificationsScreen.routeName,
            '/arc-create-trade-listing',
            '/arc-my-trade-listings',
          ],
        ),
        ArcCompactNavigationItem(
          label: 'Smart Trade Assist',
          icon: Icons.auto_awesome_outlined,
          routeName: SmartTradeAssistScreen.routeName,
          accessFlag: FeatureAccessFlag.smartTradeAssist,
        ),
        ArcCompactNavigationItem(
          label: 'Nomadic Trader',
          icon: Icons.local_shipping_outlined,
          routeName: NomadicTraderScreen.routeName,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'SQUAD & COMMUNITY',
      items: [
        ArcCompactNavigationItem(
          label: 'Match Raider',
          icon: Icons.groups_2_outlined,
          routeName: ArcMatchRiderScreen.routeName,
          accessFlag: FeatureAccessFlag.matchRaider,
          badgeTarget: ArcDrawerBadgeTarget.matchRider,
        ),
        ArcCompactNavigationItem(
          label: 'Community Rewards',
          icon: Icons.hub_outlined,
          routeName: '/community-command',
        ),
        ArcCompactNavigationItem(
          label: 'Wall of Legends',
          icon: Icons.emoji_events_outlined,
          routeName: WallOfLegendsScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'My Hub',
          icon: Icons.person_pin_circle_outlined,
          routeName: MyHubScreen.toolDeckRouteName,
          selectedRouteNames: [MyHubScreen.routeName],
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'IMPROVE',
      items: [
        ArcCompactNavigationItem(
          label: 'Play Like a Pro',
          icon: Icons.school_outlined,
          routeName: PlayLikeAProScreen.routeName,
          accessFlag: FeatureAccessFlag.playLockerPro,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'FUTURE HUB',
      items: [
        ArcCompactNavigationItem(
          label: 'Roadmap & Community Ideas',
          icon: Icons.explore_outlined,
          routeName: ArcFutureHubScreen.routeName,
        ),
      ],
    ),
    ArcCompactNavigationGroup(
      label: 'ACCOUNT & UAG',
      items: [
        ArcCompactNavigationItem(
          label: 'Profile & Reputation',
          icon: Icons.person_outline_rounded,
          routeName: TradingProfileScreen.routeName,
          selectedRouteNames: [
            ArcProfileEditScreen.routeName,
            ArcAvailabilityScreen.routeName,
            ArcAwayScreen.routeName,
          ],
        ),
        ArcCompactNavigationItem(
          label: 'Plans & Referrals',
          icon: Icons.workspace_premium_outlined,
          routeName: MonetisationScreen.routeName,
          selectedRouteNames: ['/monetisation/plans'],
        ),
        ArcCompactNavigationItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          routeName: ProfileSettingsScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Privacy & Data',
          icon: Icons.privacy_tip_outlined,
          routeName: UagPrivacyDataScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Help Centre',
          icon: Icons.support_agent_outlined,
          routeName: ArcHelpCentreScreen.routeName,
        ),
        ArcCompactNavigationItem(
          label: 'Beta Feedback',
          icon: Icons.bug_report_outlined,
          routeName: ArcBetaFeedbackScreen.routeName,
          selectedRouteNames: ['/feedback'],
        ),
        ArcCompactNavigationItem(
          label: 'Legal',
          icon: Icons.policy_outlined,
          routeName: LegalHubScreen.routeName,
        ),
      ],
    ),
  ];

  static List<ArcCompactNavigationGroup> groupsForPersonalisation(
    ArcUserPersonalisationProfile personalisation,
  ) {
    return [
      for (final group in groups)
        ArcCompactNavigationGroup(
          label: group.label,
          items: group.label == 'DISCOVER & RUN'
              ? group.items
              : _sortItems(group.items, personalisation),
        ),
    ];
  }

  static List<ArcCompactNavigationItem> _sortItems(
    List<ArcCompactNavigationItem> items,
    ArcUserPersonalisationProfile personalisation,
  ) {
    final indexed = <({ArcCompactNavigationItem item, int index, int score})>[
      for (var i = 0; i < items.length; i++)
        (
          item: items[i],
          index: i,
          score: personalisation
              .interestFor(
                items[i].personalisationFeature ??
                    ArcPersonalisationFeature.profile,
              )
              .weight,
        ),
    ];
    indexed.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) return scoreCompare;
      return left.index.compareTo(right.index);
    });
    return indexed.map((entry) => entry.item).toList(growable: false);
  }

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
