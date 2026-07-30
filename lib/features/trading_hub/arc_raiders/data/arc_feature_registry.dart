import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';

enum ArcFeatureLifecycle {
  ready,
  beta,
  adminPreview,
  foundation,
  dormantFuture,
}

class ArcFeatureRegistryEntry {
  const ArcFeatureRegistryEntry({
    required this.id,
    required this.label,
    required this.personalisationFeature,
    required this.lifecycle,
    this.routeName,
    this.accessFlag,
    this.adminFlag,
    this.notes = '',
  });

  final String id;
  final String label;
  final ArcPersonalisationFeature personalisationFeature;
  final ArcFeatureLifecycle lifecycle;
  final String? routeName;
  final String? accessFlag;
  final String? adminFlag;
  final String notes;

  bool get isDormant => lifecycle == ArcFeatureLifecycle.dormantFuture;
  bool get isRoutable => routeName != null && routeName!.trim().isNotEmpty;
}

class ArcFeatureRegistry {
  const ArcFeatureRegistry._();

  static const entries = <ArcFeatureRegistryEntry>[
    ArcFeatureRegistryEntry(
      id: 'command_centre',
      label: 'Command Centre',
      personalisationFeature: ArcPersonalisationFeature.profile,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: ArcCommandCentreScreen.routeName,
    ),
    ArcFeatureRegistryEntry(
      id: 'tool_deck',
      label: 'Tool Deck',
      personalisationFeature: ArcPersonalisationFeature.profile,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: MyHubScreen.toolDeckRouteName,
    ),
    ArcFeatureRegistryEntry(
      id: 'settings',
      label: 'Settings',
      personalisationFeature: ArcPersonalisationFeature.settings,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: ProfileSettingsScreen.routeName,
    ),
    ArcFeatureRegistryEntry(
      id: 'communications',
      label: 'Communications Centre',
      personalisationFeature: ArcPersonalisationFeature.communications,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: TradingNotificationsScreen.routeName,
    ),
    ArcFeatureRegistryEntry(
      id: 'blueprint_tracker',
      label: 'Blueprint Tracker',
      personalisationFeature: ArcPersonalisationFeature.blueprintTracker,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: BlueprintGridScreen.routeName,
      accessFlag: FeatureAccessFlag.blueprintTracker,
    ),
    ArcFeatureRegistryEntry(
      id: 'favourite_loadout',
      label: 'Favourite Loadout',
      personalisationFeature: ArcPersonalisationFeature.favouriteLoadout,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: FavouriteLoadoutScreen.routeName,
    ),
    ArcFeatureRegistryEntry(
      id: 'progress_trackers',
      label: 'Quest, Bench and Scrappy Trackers',
      personalisationFeature: ArcPersonalisationFeature.scrappyTracker,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: '/trading-hub/arc-raiders/progress-trackers',
    ),
    ArcFeatureRegistryEntry(
      id: 'trading_hub',
      label: 'Trading Hub',
      personalisationFeature: ArcPersonalisationFeature.trading,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: TraderHubScreen.routeName,
      accessFlag: FeatureAccessFlag.traderHub,
    ),
    ArcFeatureRegistryEntry(
      id: 'smart_trade',
      label: 'Smart Trade Assist',
      personalisationFeature: ArcPersonalisationFeature.smartTrade,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: SmartTradeAssistScreen.routeName,
      accessFlag: FeatureAccessFlag.smartTradeAssist,
    ),
    ArcFeatureRegistryEntry(
      id: 'match_rider',
      label: 'Match Rider',
      personalisationFeature: ArcPersonalisationFeature.matchRider,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: ArcMatchRiderScreen.routeName,
      accessFlag: FeatureAccessFlag.matchRaider,
    ),
    ArcFeatureRegistryEntry(
      id: 'raid_planner',
      label: 'Raid Planner',
      personalisationFeature: ArcPersonalisationFeature.raidPlanner,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: RaidPlannerScreen.routeName,
      accessFlag: FeatureAccessFlag.raidPlanner,
    ),
    ArcFeatureRegistryEntry(
      id: 'hunt_targets',
      label: 'Hunt Targets',
      personalisationFeature: ArcPersonalisationFeature.huntTargets,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: RaidPlannerHuntTargetsScreen.routeName,
    ),
    ArcFeatureRegistryEntry(
      id: 'raid_intelligence',
      label: 'Raid Intelligence',
      personalisationFeature: ArcPersonalisationFeature.raidIntelligence,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: ArcRaidIntelligenceScreen.routeName,
      accessFlag: FeatureAccessFlag.intelExplorer,
      adminFlag: 'raidIntelligence',
    ),
    ArcFeatureRegistryEntry(
      id: 'operations_reward_vault',
      label: 'Operations and Reward Vault',
      personalisationFeature: ArcPersonalisationFeature.operations,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: OperationsCommandScreen.routeName,
      adminFlag: 'operations',
    ),
    ArcFeatureRegistryEntry(
      id: 'player_locker_pro',
      label: 'Player Locker Pro',
      personalisationFeature: ArcPersonalisationFeature.playerLockerPro,
      lifecycle: ArcFeatureLifecycle.foundation,
      accessFlag: FeatureAccessFlag.playLockerPro,
    ),
    ArcFeatureRegistryEntry(
      id: 'voice_assistant',
      label: 'Voice Assistant',
      personalisationFeature: ArcPersonalisationFeature.voiceAssistant,
      lifecycle: ArcFeatureLifecycle.foundation,
      accessFlag: FeatureAccessFlag.voiceAssistant,
    ),
    ArcFeatureRegistryEntry(
      id: 'report_a_rat',
      label: 'Report A Rat',
      personalisationFeature: ArcPersonalisationFeature.reportARat,
      lifecycle: ArcFeatureLifecycle.dormantFuture,
      notes: 'Identifier reserved for future trust/safety work only.',
    ),
    ArcFeatureRegistryEntry(
      id: 'hunt_a_rat',
      label: 'Hunt A Rat',
      personalisationFeature: ArcPersonalisationFeature.huntARat,
      lifecycle: ArcFeatureLifecycle.dormantFuture,
      notes: 'Identifier reserved; no functional beta surface.',
    ),
    ArcFeatureRegistryEntry(
      id: 'rat_radar',
      label: 'Rat Radar',
      personalisationFeature: ArcPersonalisationFeature.ratRadar,
      lifecycle: ArcFeatureLifecycle.dormantFuture,
      notes: 'Identifier reserved; must stay hidden until a future pass.',
    ),
    ArcFeatureRegistryEntry(
      id: 'gift_subscriptions',
      label: 'Gift Subscriptions',
      personalisationFeature: ArcPersonalisationFeature.giftSubscriptions,
      lifecycle: ArcFeatureLifecycle.dormantFuture,
      notes: 'Identifier reserved for post-beta monetisation exploration.',
    ),
  ];

  static ArcFeatureRegistryEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}

class ArcFeatureVisibilityDiagnostic {
  const ArcFeatureVisibilityDiagnostic({
    required this.entry,
    required this.personalisationLevel,
    required this.visible,
    required this.reason,
  });

  final ArcFeatureRegistryEntry entry;
  final ArcPersonalisationInterestLevel personalisationLevel;
  final bool visible;
  final String reason;
}

class ArcFeatureVisibilityDiagnosticsEngine {
  const ArcFeatureVisibilityDiagnosticsEngine._();

  static List<ArcFeatureVisibilityDiagnostic> build({
    required ArcUserPersonalisationProfile personalisation,
    Map<String, bool> featureAccess = const <String, bool>{},
    Map<String, bool> adminControls = const <String, bool>{},
  }) {
    return [
      for (final entry in ArcFeatureRegistry.entries)
        _diagnosticFor(
          entry: entry,
          personalisation: personalisation,
          featureAccess: featureAccess,
          adminControls: adminControls,
        ),
    ];
  }

  static ArcFeatureVisibilityDiagnostic _diagnosticFor({
    required ArcFeatureRegistryEntry entry,
    required ArcUserPersonalisationProfile personalisation,
    required Map<String, bool> featureAccess,
    required Map<String, bool> adminControls,
  }) {
    final level = personalisation.interestFor(entry.personalisationFeature);
    if (entry.isDormant) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Dormant future identifier; no beta route exposed.',
      );
    }
    if (entry.accessFlag != null && featureAccess[entry.accessFlag] == false) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Hidden by FeatureAccess flag ${entry.accessFlag}.',
      );
    }
    if (entry.adminFlag != null && adminControls[entry.adminFlag] == false) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Hidden by admin control ${entry.adminFlag}.',
      );
    }
    if (!entry.isRoutable) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Foundational system with no direct beta route.',
      );
    }
    return ArcFeatureVisibilityDiagnostic(
      entry: entry,
      personalisationLevel: level,
      visible: true,
      reason: level.isHighSignal
          ? 'Visible and promoted by personalisation.'
          : 'Visible through normal navigation.',
    );
  }
}
