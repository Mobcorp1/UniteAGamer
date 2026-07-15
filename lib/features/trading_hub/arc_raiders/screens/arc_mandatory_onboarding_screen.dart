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
  bool _saving = false;

  Future<void> _completeSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'arcMandatoryOnboardingComplete': true,
        'onboardingComplete': true,
        'arcOnboarding': {
          'version': 2,
          'completedAt': FieldValue.serverTimestamp(),
          'flow': ['profile', 'availability', 'blueprints', 'goals', 'trades'],
          'blueprintSetupModes': ['markOwned', 'markMissing'],
          'recommendedBlueprintSetupMode': 'markMissing',
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
      backgroundColor: AppTheme.darkBackground,
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
