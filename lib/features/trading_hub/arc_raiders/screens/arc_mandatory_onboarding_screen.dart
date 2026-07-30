import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMandatoryOnboardingScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/onboarding';

  const ArcMandatoryOnboardingScreen({super.key});

  @override
  State<ArcMandatoryOnboardingScreen> createState() =>
      _ArcMandatoryOnboardingScreenState();
}

class _ArcMandatoryOnboardingScreenState
    extends State<ArcMandatoryOnboardingScreen> {
  final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();
  final ArcUserPersonalisationRepository _personalisationRepository =
      ArcUserPersonalisationRepository();
  Set<ArcPersonalisationGoal> _selectedGoals = const {
    ArcPersonalisationGoal.exploreEverything,
  };
  ArcCommandCentreDensity _density = ArcCommandCentreDensity.compact;
  ArcSoloSquadPreference _squadPreference = ArcSoloSquadPreference.flexible;
  Set<ArcPersonalisationNotificationCategory> _notificationCategories =
      arcDefaultPersonalisationNotificationCategories;
  bool _saving = false;

  Future<void> _completeSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;

    setState(() => _saving = true);
    try {
      final personalisation = _profileFromSelections();
      await _personalisationRepository.markComplete(personalisation);
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'arcMandatoryOnboardingComplete': true,
        'onboardingComplete': true,
        'arcOnboarding': {
          'version': 2,
          'completedAt': FieldValue.serverTimestamp(),
          'flow': ['profile', 'availability', 'blueprints', 'goals', 'trades'],
          'blueprintSetupModes': ['markOwned', 'markMissing'],
          'recommendedBlueprintSetupMode': 'markMissing',
          'personalisationSchemaVersion': personalisation.schemaVersion,
          'personalisationGoals': personalisation.goals
              .map((goal) => goal.name)
              .toList(growable: false),
          'commandCentreDensity': personalisation.commandCentre.density.name,
        },
      }, SetOptions(merge: true));
      await _profileRepository.refreshProfileCompletion();

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(ArcCommandCentreScreen.routeName, (_) => false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ArcUserPersonalisationProfile _profileFromSelections() {
    final goals = _selectedGoals.isEmpty
        ? const {ArcPersonalisationGoal.exploreEverything}
        : _selectedGoals;
    final interests =
        <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{};

    void boost(
      ArcPersonalisationFeature feature, [
      ArcPersonalisationInterestLevel level =
          ArcPersonalisationInterestLevel.high,
    ]) {
      final current = interests[feature];
      if (current == null || level.weight > current.weight) {
        interests[feature] = level;
      }
    }

    for (final goal in goals) {
      switch (goal) {
        case ArcPersonalisationGoal.exploreEverything:
          break;
        case ArcPersonalisationGoal.completeBlueprints:
          boost(ArcPersonalisationFeature.blueprintTracker);
          boost(ArcPersonalisationFeature.blueprintIntelligence);
          boost(ArcPersonalisationFeature.blueprintWatches);
          break;
        case ArcPersonalisationGoal.tradeBlueprints:
          boost(ArcPersonalisationFeature.trading);
          boost(ArcPersonalisationFeature.smartTrade);
          boost(ArcPersonalisationFeature.communications);
          break;
        case ArcPersonalisationGoal.buildFavouriteLoadout:
          boost(ArcPersonalisationFeature.favouriteLoadout);
          break;
        case ArcPersonalisationGoal.progressQuests:
          boost(ArcPersonalisationFeature.questTracker);
          boost(ArcPersonalisationFeature.scrappyTracker);
          break;
        case ArcPersonalisationGoal.upgradeBench:
          boost(ArcPersonalisationFeature.benchTracker);
          boost(ArcPersonalisationFeature.scrappyTracker);
          break;
        case ArcPersonalisationGoal.trackResources:
          boost(ArcPersonalisationFeature.scrappyTracker);
          boost(ArcPersonalisationFeature.nomadicTrader);
          break;
        case ArcPersonalisationGoal.planRaids:
          boost(ArcPersonalisationFeature.raidPlanner);
          boost(ArcPersonalisationFeature.raidIntelligence);
          boost(ArcPersonalisationFeature.huntTargets);
          break;
        case ArcPersonalisationGoal.findSquads:
          boost(ArcPersonalisationFeature.matchRider);
          boost(ArcPersonalisationFeature.availability);
          boost(ArcPersonalisationFeature.favouriteRiders);
          break;
        case ArcPersonalisationGoal.followOperations:
          boost(ArcPersonalisationFeature.operations);
          break;
        case ArcPersonalisationGoal.manageCosmetics:
          boost(ArcPersonalisationFeature.rewardVault);
          boost(ArcPersonalisationFeature.operations);
          break;
        case ArcPersonalisationGoal.receiveCommunityIntel:
          boost(ArcPersonalisationFeature.communityIntel);
          boost(ArcPersonalisationFeature.raidIntelligence);
          break;
        case ArcPersonalisationGoal.improveReputation:
          boost(ArcPersonalisationFeature.profile);
          break;
      }
    }

    return ArcUserPersonalisationProfile(
      completed: true,
      completedAt: DateTime.now(),
      source: 'mandatory_onboarding',
      goals: goals,
      featureInterests: interests,
      squadPreference: _squadPreference,
      notificationCategories: _notificationCategories,
      commandCentre: ArcCommandCentrePreferenceSet(
        density: _density,
        dailyMissions: true,
        recommendations: true,
        riskWarnings: true,
        tradeActivity: goals.contains(ArcPersonalisationGoal.tradeBlueprints),
        socialActivity: goals.contains(ArcPersonalisationGoal.findSquads),
        progressionCards:
            goals.contains(ArcPersonalisationGoal.progressQuests) ||
            goals.contains(ArcPersonalisationGoal.upgradeBench) ||
            goals.contains(ArcPersonalisationGoal.completeBlueprints),
        upcomingAvailability: goals.contains(ArcPersonalisationGoal.findSquads),
        trackerSummaries: true,
        raidPreparation: goals.contains(ArcPersonalisationGoal.planRaids),
        systemShortcuts: true,
      ),
    );
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final steps = <_OnboardingStepData>[
      _OnboardingStepData(
        title: 'Raider Profile',
        subtitle: 'Set your player identity, platform, region and visibility.',
        icon: Icons.badge_rounded,
        onTap: () => _open(const ArcProfileSetupScreen()),
      ),
      _OnboardingStepData(
        title: 'Availability',
        subtitle:
            'Fixed weekly times, rotating shifts, trade windows and match windows.',
        icon: Icons.schedule_rounded,
        onTap: () => _open(const ArcAvailabilityScreen()),
      ),
      _OnboardingStepData(
        title: 'Blueprint Grid',
        subtitle:
            'Mark owned blueprints or mark only missing blueprints to auto-own the rest.',
        icon: Icons.grid_view_rounded,
        onTap: () => _open(const BlueprintGridScreen()),
      ),
      _OnboardingStepData(
        title: 'Goals & Targets',
        subtitle:
            'Choose collection, loadout, quest, bench, resource or PvP/PvE priorities.',
        icon: Icons.track_changes_rounded,
        onTap: () => _open(const FavouriteLoadoutScreen()),
      ),
      _OnboardingStepData(
        title: 'Trade Setup',
        subtitle:
            'Create your first trade intent from dupes, resources, wants and priorities.',
        icon: Icons.swap_horiz_rounded,
        onTap: () => _open(const TradingCreateListingScreen()),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Text(
                  'SET UP YOUR ARC PROFILE',
                  style: AppTheme.tradingHeading(
                    fontSize: 28,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is the only heavy setup. Once complete, matchmaking, trades and Smart Trade Assist can work from your profile, availability, blueprints and targets.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonPink.withValues(alpha: 0.28),
                  ),
                  child: const Text(
                    'Fast Blueprint Setup: existing players can mark only their missing blueprints. Everything else is automatically treated as owned.',
                    style: TextStyle(color: Colors.white, height: 1.32),
                  ),
                ),
                const SizedBox(height: 18),
                ...steps.map((step) => _OnboardingStepCard(step: step)),
                const SizedBox(height: 6),
                _PersonalisationSetupCard(
                  selectedGoals: _selectedGoals,
                  density: _density,
                  squadPreference: _squadPreference,
                  notificationCategories: _notificationCategories,
                  onGoalsChanged: (goals) {
                    setState(() => _selectedGoals = goals);
                  },
                  onDensityChanged: (density) {
                    setState(() => _density = density);
                  },
                  onSquadPreferenceChanged: (preference) {
                    setState(() => _squadPreference = preference);
                  },
                  onNotificationCategoriesChanged: (categories) {
                    setState(() => _notificationCategories = categories);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _completeSetup,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('Complete setup and enter hub'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({required this.step});

  final _OnboardingStepData step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: step.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonCyan.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.38),
                  ),
                ),
                child: Icon(step.icon, color: AppTheme.neonCyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title.toUpperCase(),
                      style: AppTheme.tradingHeading(
                        fontSize: 17,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.28,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalisationSetupCard extends StatelessWidget {
  const _PersonalisationSetupCard({
    required this.selectedGoals,
    required this.density,
    required this.squadPreference,
    required this.notificationCategories,
    required this.onGoalsChanged,
    required this.onDensityChanged,
    required this.onSquadPreferenceChanged,
    required this.onNotificationCategoriesChanged,
  });

  final Set<ArcPersonalisationGoal> selectedGoals;
  final ArcCommandCentreDensity density;
  final ArcSoloSquadPreference squadPreference;
  final Set<ArcPersonalisationNotificationCategory> notificationCategories;
  final ValueChanged<Set<ArcPersonalisationGoal>> onGoalsChanged;
  final ValueChanged<ArcCommandCentreDensity> onDensityChanged;
  final ValueChanged<ArcSoloSquadPreference> onSquadPreferenceChanged;
  final ValueChanged<Set<ArcPersonalisationNotificationCategory>>
  onNotificationCategoriesChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonPink.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.neonPink.withValues(alpha: 0.38),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONALISE COMMAND CENTRE',
                      style: AppTheme.tradingHeading(
                        fontSize: 17,
                        color: AppTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick what matters most. You can change this later in Settings.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.28,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Primary goals'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in ArcPersonalisationGoal.values)
                FilterChip(
                  selected: selectedGoals.contains(goal),
                  label: Text(goal.label),
                  onSelected: (selected) => _toggleGoal(goal, selected),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Command Centre detail'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in ArcCommandCentreDensity.values)
                ChoiceChip(
                  selected: density == value,
                  label: Text(_densityLabel(value)),
                  onSelected: (_) => onDensityChanged(value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Squad preference'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in ArcSoloSquadPreference.values)
                ChoiceChip(
                  selected: squadPreference == value,
                  label: Text(_squadLabel(value)),
                  onSelected: (_) => onSquadPreferenceChanged(value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Notification categories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _visibleNotificationCategories)
                FilterChip(
                  selected: notificationCategories.contains(category),
                  label: Text(_notificationLabel(category)),
                  onSelected: (selected) =>
                      _toggleNotification(category, selected),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleGoal(ArcPersonalisationGoal goal, bool selected) {
    final next = {...selectedGoals};
    if (selected) {
      if (goal == ArcPersonalisationGoal.exploreEverything) {
        next
          ..clear()
          ..add(goal);
      } else {
        next
          ..remove(ArcPersonalisationGoal.exploreEverything)
          ..add(goal);
      }
    } else {
      next.remove(goal);
      if (next.isEmpty) next.add(ArcPersonalisationGoal.exploreEverything);
    }
    onGoalsChanged(next);
  }

  void _toggleNotification(
    ArcPersonalisationNotificationCategory category,
    bool selected,
  ) {
    final next = {...notificationCategories};
    if (selected) {
      next.add(category);
    } else {
      next.remove(category);
    }
    onNotificationCategoriesChanged(next);
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.bodyTextStyle(
          fontSize: 11,
          color: AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }

  String _densityLabel(ArcCommandCentreDensity value) {
    switch (value) {
      case ArcCommandCentreDensity.compact:
        return 'Compact';
      case ArcCommandCentreDensity.balanced:
        return 'Balanced';
      case ArcCommandCentreDensity.detailed:
        return 'Detailed';
    }
  }

  String _squadLabel(ArcSoloSquadPreference value) {
    switch (value) {
      case ArcSoloSquadPreference.solo:
        return 'Solo';
      case ArcSoloSquadPreference.duo:
        return 'Duo';
      case ArcSoloSquadPreference.squad:
        return 'Squad';
      case ArcSoloSquadPreference.flexible:
        return 'Flexible';
    }
  }

  String _notificationLabel(ArcPersonalisationNotificationCategory category) {
    switch (category) {
      case ArcPersonalisationNotificationCategory.tradeActivity:
        return 'Trades';
      case ArcPersonalisationNotificationCategory.listingMatches:
        return 'Listing Matches';
      case ArcPersonalisationNotificationCategory.blueprintWatches:
        return 'Blueprint Watches';
      case ArcPersonalisationNotificationCategory.favouriteRiderActivity:
        return 'Favourite Riders';
      case ArcPersonalisationNotificationCategory.matchRiderActivity:
        return 'Match Rider';
      case ArcPersonalisationNotificationCategory.availabilityReminders:
        return 'Availability';
      case ArcPersonalisationNotificationCategory.questProgress:
        return 'Quests';
      case ArcPersonalisationNotificationCategory.benchProgress:
        return 'Bench';
      case ArcPersonalisationNotificationCategory.scrappyProgress:
        return 'Scrappy';
      case ArcPersonalisationNotificationCategory.raidIntelligence:
        return 'Raid Intel';
      case ArcPersonalisationNotificationCategory.systemAnnouncements:
        return 'System';
      case ArcPersonalisationNotificationCategory.futureBountyActivity:
        return 'Future Bounty';
      case ArcPersonalisationNotificationCategory.futureRatRiskWarnings:
        return 'Future Rat Risk';
    }
  }

  static const _visibleNotificationCategories =
      <ArcPersonalisationNotificationCategory>[
        ArcPersonalisationNotificationCategory.tradeActivity,
        ArcPersonalisationNotificationCategory.listingMatches,
        ArcPersonalisationNotificationCategory.blueprintWatches,
        ArcPersonalisationNotificationCategory.matchRiderActivity,
        ArcPersonalisationNotificationCategory.availabilityReminders,
        ArcPersonalisationNotificationCategory.questProgress,
        ArcPersonalisationNotificationCategory.benchProgress,
        ArcPersonalisationNotificationCategory.scrappyProgress,
        ArcPersonalisationNotificationCategory.raidIntelligence,
        ArcPersonalisationNotificationCategory.systemAnnouncements,
      ];
}
