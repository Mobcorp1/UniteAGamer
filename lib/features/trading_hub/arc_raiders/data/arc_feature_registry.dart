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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
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
      id: 'scrappy_tracker',
      label: 'Scrappy Tracker',
      personalisationFeature: ArcPersonalisationFeature.scrappyTracker,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: ScrappyGridScreen.routeName,
      accessFlag: FeatureAccessFlag.scrappyTracker,
    ),
    ArcFeatureRegistryEntry(
      id: 'bench_tracker',
      label: 'Bench Tracker',
      personalisationFeature: ArcPersonalisationFeature.benchTracker,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: ScrappyGridScreen.benchRouteName,
      accessFlag: FeatureAccessFlag.benchTracker,
    ),
    ArcFeatureRegistryEntry(
      id: 'quest_tracker',
      label: 'Quest Tracker',
      personalisationFeature: ArcPersonalisationFeature.questTracker,
      lifecycle: ArcFeatureLifecycle.ready,
      routeName: ScrappyGridScreen.questRouteName,
      accessFlag: FeatureAccessFlag.questTracker,
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
      label: 'Match Raider',
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
      accessFlag: FeatureAccessFlag.raidPlanner,
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
      id: 'play_like_a_pro',
      label: 'Play Like A Pro',
      personalisationFeature: ArcPersonalisationFeature.playLikeAPro,
      lifecycle: ArcFeatureLifecycle.beta,
      routeName: PlayLikeAProScreen.routeName,
      accessFlag: FeatureAccessFlag.playLockerPro,
      notes:
          'Pro-style preparation, performance routines, UAG Mixtapes and preserved session coaching.',
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
    this.availability = FeatureAvailability.live,
  });

  final ArcFeatureRegistryEntry entry;
  final ArcPersonalisationInterestLevel personalisationLevel;
  final bool visible;
  final String reason;
  final FeatureAvailability availability;
}

class ArcClosedBetaJourneyStatus {
  const ArcClosedBetaJourneyStatus({
    required this.label,
    required this.status,
    this.warning = false,
  });

  final String label;
  final String status;
  final bool warning;
}

class ArcClosedBetaConfigurationSummary {
  const ArcClosedBetaConfigurationSummary({
    required this.liveCount,
    required this.comingSoonCount,
    required this.hiddenCount,
    required this.coreJourney,
    required this.warnings,
  });

  final int liveCount;
  final int comingSoonCount;
  final int hiddenCount;
  final List<ArcClosedBetaJourneyStatus> coreJourney;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

class ArcFeatureVisibilityDiagnosticsSnapshot {
  const ArcFeatureVisibilityDiagnosticsSnapshot({
    required this.diagnostics,
    required this.summary,
  });

  final List<ArcFeatureVisibilityDiagnostic> diagnostics;
  final ArcClosedBetaConfigurationSummary summary;
}

class ArcFeatureVisibilityDiagnosticsEngine {
  const ArcFeatureVisibilityDiagnosticsEngine._();

  static List<ArcFeatureVisibilityDiagnostic> build({
    required ArcUserPersonalisationProfile personalisation,
    Map<String, bool> featureAccess = const <String, bool>{},
    Map<String, FeatureAvailability> featureAvailability =
        const <String, FeatureAvailability>{},
    Map<String, bool> adminControls = const <String, bool>{},
  }) {
    return [
      for (final entry in ArcFeatureRegistry.entries)
        _diagnosticFor(
          entry: entry,
          personalisation: personalisation,
          featureAccess: featureAccess,
          featureAvailability: featureAvailability,
          adminControls: adminControls,
        ),
    ];
  }

  static ArcFeatureVisibilityDiagnosticsSnapshot snapshot({
    required ArcUserPersonalisationProfile personalisation,
    Map<String, bool> featureAccess = const <String, bool>{},
    Map<String, FeatureAvailability> featureAvailability =
        const <String, FeatureAvailability>{},
    Map<String, bool> adminControls = const <String, bool>{},
  }) {
    final diagnostics = build(
      personalisation: personalisation,
      featureAccess: featureAccess,
      featureAvailability: featureAvailability,
      adminControls: adminControls,
    );
    return ArcFeatureVisibilityDiagnosticsSnapshot(
      diagnostics: diagnostics,
      summary: summarize(diagnostics),
    );
  }

  static ArcClosedBetaConfigurationSummary summarize(
    List<ArcFeatureVisibilityDiagnostic> diagnostics,
  ) {
    final liveCount = diagnostics
        .where((diagnostic) => diagnostic.availability.isLive)
        .length;
    final comingSoonCount = diagnostics
        .where((diagnostic) => diagnostic.availability.isComingSoon)
        .length;
    final hiddenCount = diagnostics
        .where((diagnostic) => diagnostic.availability.isHidden)
        .length;
    final coreJourney = <ArcClosedBetaJourneyStatus>[
      const ArcClosedBetaJourneyStatus(
        label: 'Authentication',
        status: 'Available',
      ),
      const ArcClosedBetaJourneyStatus(
        label: 'Onboarding',
        status: 'Available',
      ),
      const ArcClosedBetaJourneyStatus(
        label: 'Personalisation',
        status: 'Available',
      ),
      const ArcClosedBetaJourneyStatus(label: 'Profile', status: 'Available'),
      _coreStatus(diagnostics, 'command_centre', fallback: 'Available'),
      _coreStatus(diagnostics, 'blueprint_tracker'),
      _coreStatus(diagnostics, 'bench_tracker'),
      _coreStatus(diagnostics, 'scrappy_tracker'),
    ];
    final warnings = <String>[
      if (_isHidden(diagnostics, 'command_centre') ||
          coreJourney
              .where(
                (status) =>
                    status.label == 'Blueprint Tracker' ||
                    status.label == 'Bench Tracker' ||
                    status.label == 'Scrappy Tracker',
              )
              .every(
                (status) => status.status == FeatureAvailability.hidden.label,
              ))
        'Command Centre is available but all supported beta tracker systems are hidden.',
      if (coreJourney.any(
        (status) => status.label == 'Blueprint Tracker' && status.warning,
      ))
        'Blueprint Tracker is not Live. Closed Beta 2 expects it to be available.',
      if (coreJourney
          .where(
            (status) =>
                status.label == 'Bench Tracker' ||
                status.label == 'Scrappy Tracker',
          )
          .every((status) => status.warning))
        'Bench and Scrappy trackers are both unavailable; progression setup may feel blocked.',
      if (diagnostics.every((diagnostic) => !diagnostic.visible))
        'Personalisation has zero visible feature destinations.',
    ];
    return ArcClosedBetaConfigurationSummary(
      liveCount: liveCount,
      comingSoonCount: comingSoonCount,
      hiddenCount: hiddenCount,
      coreJourney: coreJourney,
      warnings: warnings,
    );
  }

  static ArcFeatureVisibilityDiagnostic _diagnosticFor({
    required ArcFeatureRegistryEntry entry,
    required ArcUserPersonalisationProfile personalisation,
    required Map<String, bool> featureAccess,
    required Map<String, FeatureAvailability> featureAvailability,
    required Map<String, bool> adminControls,
  }) {
    final level = personalisation.interestFor(entry.personalisationFeature);
    final availability = entry.accessFlag == null
        ? FeatureAvailability.live
        : featureAvailability[entry.accessFlag] ??
              (featureAvailability.isNotEmpty
                  ? FeatureAvailability.hidden
                  : (featureAccess[entry.accessFlag] == false
                        ? FeatureAvailability.hidden
                        : FeatureAvailability.live));
    if (entry.isDormant) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Dormant future identifier; no beta route exposed.',
        availability: FeatureAvailability.hidden,
      );
    }
    if (entry.accessFlag != null && availability.isHidden) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Hidden by FeatureAccess flag ${entry.accessFlag}.',
        availability: availability,
      );
    }
    if (entry.adminFlag != null && adminControls[entry.adminFlag] == false) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Hidden by admin control ${entry.adminFlag}.',
        availability: availability,
      );
    }
    if (!entry.isRoutable) {
      return ArcFeatureVisibilityDiagnostic(
        entry: entry,
        personalisationLevel: level,
        visible: false,
        reason: 'Foundational system with no direct beta route.',
        availability: availability,
      );
    }
    return ArcFeatureVisibilityDiagnostic(
      entry: entry,
      personalisationLevel: level,
      visible: true,
      reason: availability.isComingSoon
          ? 'Visible as Coming Soon because the user can express interest before launch.'
          : level.isHighSignal
          ? 'Visible and promoted by personalisation.'
          : 'Visible through normal navigation.',
      availability: availability,
    );
  }

  static ArcClosedBetaJourneyStatus _coreStatus(
    List<ArcFeatureVisibilityDiagnostic> diagnostics,
    String id, {
    String? fallback,
  }) {
    final diagnostic = diagnostics
        .cast<ArcFeatureVisibilityDiagnostic?>()
        .firstWhere(
          (diagnostic) => diagnostic?.entry.id == id,
          orElse: () => null,
        );
    if (diagnostic == null) {
      return ArcClosedBetaJourneyStatus(
        label: fallback ?? id,
        status: fallback ?? 'Unavailable',
        warning: fallback == null,
      );
    }
    return ArcClosedBetaJourneyStatus(
      label: diagnostic.entry.label,
      status: diagnostic.availability.label,
      warning: diagnostic.availability.isHidden,
    );
  }

  static bool _isHidden(
    List<ArcFeatureVisibilityDiagnostic> diagnostics,
    String id,
  ) {
    final diagnostic = diagnostics
        .cast<ArcFeatureVisibilityDiagnostic?>()
        .firstWhere(
          (diagnostic) => diagnostic?.entry.id == id,
          orElse: () => null,
        );
    return diagnostic?.availability.isHidden ?? true;
  }
}
