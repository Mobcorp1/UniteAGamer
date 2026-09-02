import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_monetisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_impact_pots_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/reg/onboarding_basic_profile_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class AdminMonetisationDashboard extends StatelessWidget {
  const AdminMonetisationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagMonetisationRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monetisation',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.admin,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          'Private admin view for users, subscription mix, referral exposure, revenue, platform fees and impact pot allocation.',
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        const SizedBox(height: AppTheme.spaceL),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repository.watchAdminUsers(),
          builder: (context, snapshot) {
            final docs =
                snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final stats = _AdminUserStats.fromDocs(docs);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                final cards = [
                  _StatCard(
                    label: 'Free Users',
                    value: '${stats.freeUsers}',
                    color: Colors.white70,
                  ),
                  _StatCard(
                    label: 'Essential Users',
                    value: '${stats.essentialUsers}',
                    color: AppTheme.neonCyan,
                  ),
                  _StatCard(
                    label: 'Premium Users',
                    value: '${stats.premiumUsers}',
                    color: AppTheme.neonPink,
                  ),
                  _StatCard(
                    label: 'Admin / Dev',
                    value: '${stats.adminUsers}',
                    color: AppTheme.warningAmber,
                  ),
                ];
                if (!isWide) {
                  return Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceM,
                            ),
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                }
                return Row(
                  children: cards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppTheme.spaceM,
                            ),
                            child: card,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceL),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repository.watchAdminRevenueEvents(limit: 80),
          builder: (context, snapshot) {
            final docs =
                snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final stats = _RevenueStats.fromDocs(docs);
            return Container(
              padding: ArcUiTokens.panelPadding,
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.panel,
                accent: ArcUiTokens.primaryAccent,
                borderOpacity: 0.22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Snapshot',
                    style: ArcUiTokens.sectionTitle(
                      fontSize: 16,
                      color: ArcUiTokens.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _moneyRow('Gross paid revenue logged', stats.grossPence),
                  _moneyRow('Estimated Stripe fees', stats.stripeFeesPence),
                  _moneyRow(
                    'Referral commission owed',
                    stats.referralCommissionPence,
                  ),
                  _moneyRow(
                    'Net platform profit logged',
                    stats.netPlatformProfitPence,
                  ),
                  _moneyRow('Charity impact allocated', stats.charityPence),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceL),
        const UagImpactPotsPanel(showAdminDetail: true),
        const SizedBox(height: AppTheme.spaceL),
        const _OnboardingSimulatorCard(),
        const SizedBox(height: AppTheme.spaceL),
        _PaymentMethodCard(),
      ],
    );
  }

  Widget _moneyRow(String label, int pence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
            ),
          ),
          Text(
            'GBP ${(pence / 100).toStringAsFixed(2)}',
            style: ArcUiTokens.body(
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SimulatorProfileState { fresh, active, postExpedition }

enum _SimulatorBlueprintState { setupNow, skipForNow }

class _OnboardingSimulatorCard extends StatefulWidget {
  const _OnboardingSimulatorCard();

  @override
  State<_OnboardingSimulatorCard> createState() =>
      _OnboardingSimulatorCardState();
}

class _OnboardingSimulatorCardState extends State<_OnboardingSimulatorCard> {
  _SimulatorProfileState _profileState = _SimulatorProfileState.fresh;
  _SimulatorBlueprintState _blueprintState =
      _SimulatorBlueprintState.skipForNow;
  bool _reachedLevel25 = false;
  bool _isWriting = false;

  bool get _isFreshOrReset =>
      _profileState == _SimulatorProfileState.fresh ||
      _profileState == _SimulatorProfileState.postExpedition;

  String get _profileStateId => switch (_profileState) {
    _SimulatorProfileState.active => 'active',
    _SimulatorProfileState.postExpedition => 'postExpedition',
    _ => 'fresh',
  };

  String get _blueprintStateId => switch (_blueprintState) {
    _SimulatorBlueprintState.setupNow => 'setupNow',
    _ => 'skipForNow',
  };

  void _setProfileState(_SimulatorProfileState state) {
    setState(() {
      _profileState = state;
      if (_isFreshOrReset) {
        _reachedLevel25 = false;
        _blueprintState = _SimulatorBlueprintState.skipForNow;
      }
    });
  }

  Map<String, Object?> _simulatorArgs({int step = 0}) {
    final reachedLevel25 = !_isFreshOrReset && _reachedLevel25;
    return {
      'source': 'adminOnboardingSimulator',
      'playerState': _profileStateId,
      'reachedRaiderLevel25': reachedLevel25,
      'blueprintSetup': _blueprintStateId,
      'step': step,
    };
  }

  Future<void> _writeSimulation({bool resetProgress = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signed-in admin user found.')),
      );
      return;
    }

    setState(() => _isWriting = true);
    final reachedLevel25 = !_isFreshOrReset && _reachedLevel25;
    final blueprintConfigured =
        _blueprintState == _SimulatorBlueprintState.setupNow;
    final blueprintSkipped = !blueprintConfigured;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        if (resetProgress) 'onboardingComplete': false,
        'traderProfile': {'raiderLevel': reachedLevel25 ? 25 : 0},
        'arcOnboarding': {
          'version': 3,
          'playerState': _profileStateId,
          'raiderLevel': reachedLevel25 ? 25 : 0,
          'nomadicTraderUnlocked': reachedLevel25,
          'nomadicTraderLockedReason': reachedLevel25
              ? null
              : 'Nomadic Trader unlocks at Raider Level 25. Update your Raider Level in the app when you reach 25 to unlock Nomadic Trader planning.',
          'blueprintSetupSkipped': blueprintSkipped,
          'blueprintTrackerConfigured': blueprintConfigured,
          'blueprintOwnershipReset': _isFreshOrReset,
          'questProgressReset': _isFreshOrReset,
          'benchProgressReset': _isFreshOrReset,
          'favouriteLoadoutsRetained': true,
          'simulatedByAdmin': true,
          'simulatorUpdatedAt': FieldValue.serverTimestamp(),
        },
        'modules': {
          'blueprintTracker': blueprintConfigured,
          'nomadicTrader': reachedLevel25,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resetProgress
                ? 'Onboarding simulation applied and progress reset.'
                : 'Onboarding simulation applied.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isWriting = false);
    }
  }

  Future<void> _launchOnboarding({
    int step = 0,
    bool resetProgress = false,
  }) async {
    await _writeSimulation(resetProgress: resetProgress);
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      OnboardingBasicProfileScreen.routeName,
      arguments: _simulatorArgs(step: step),
    );
  }

  void _openCommandCentre() {
    Navigator.of(context).pushNamed(ArcCommandCentreScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final reachedLevel25 = !_isFreshOrReset && _reachedLevel25;
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_rounded,
                color: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Onboarding Simulator',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 16,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Admin-only onboarding preview. Applies simulated state to your admin account and opens the real onboarding flow without creating or deleting test accounts.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceM),
          _sectionLabel('Profile State'),
          _segmentedWrap([
            _simButton(
              'New Player',
              _profileState == _SimulatorProfileState.fresh,
              () => _setProfileState(_SimulatorProfileState.fresh),
            ),
            _simButton(
              'Existing Player',
              _profileState == _SimulatorProfileState.active,
              () => _setProfileState(_SimulatorProfileState.active),
            ),
            _simButton(
              'After Expedition Reset',
              _profileState == _SimulatorProfileState.postExpedition,
              () => _setProfileState(_SimulatorProfileState.postExpedition),
            ),
          ]),
          const SizedBox(height: AppTheme.spaceM),
          _sectionLabel('Reached Raider Level 25?'),
          _segmentedWrap([
            _simButton(
              'No',
              !reachedLevel25,
              _isFreshOrReset
                  ? null
                  : () => setState(() => _reachedLevel25 = false),
            ),
            _simButton(
              'Yes',
              reachedLevel25,
              _isFreshOrReset
                  ? null
                  : () => setState(() => _reachedLevel25 = true),
            ),
          ]),
          if (_isFreshOrReset) ...[
            const SizedBox(height: 8),
            Text(
              'Fresh starts and expedition resets force this to No because Raider Level returns to 0.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.warning),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          _sectionLabel('Blueprint Tracker'),
          _segmentedWrap([
            _simButton(
              'Set Up Now',
              _blueprintState == _SimulatorBlueprintState.setupNow,
              _isFreshOrReset
                  ? null
                  : () => setState(
                      () => _blueprintState = _SimulatorBlueprintState.setupNow,
                    ),
            ),
            _simButton(
              'Skip For Now',
              _blueprintState == _SimulatorBlueprintState.skipForNow,
              () => setState(
                () => _blueprintState = _SimulatorBlueprintState.skipForNow,
              ),
            ),
          ]),
          if (_isFreshOrReset) ...[
            const SizedBox(height: 8),
            Text(
              'Blueprint ownership, quests and benches reset. Favourite Loadouts are retained.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
          ],
          const SizedBox(height: AppTheme.spaceL),
          Wrap(
            spacing: AppTheme.spaceM,
            runSpacing: AppTheme.spaceM,
            children: [
              _actionButton(
                label: 'Apply Simulation',
                icon: Icons.save_alt_rounded,
                onPressed: _isWriting ? null : () => _writeSimulation(),
              ),
              _actionButton(
                label: 'Reset + Launch',
                icon: Icons.restart_alt_rounded,
                onPressed: _isWriting
                    ? null
                    : () => _launchOnboarding(step: 0, resetProgress: true),
              ),
              _actionButton(
                label: 'Jump To Wipe State',
                icon: Icons.flag_rounded,
                onPressed: _isWriting ? null : () => _launchOnboarding(step: 1),
              ),
              _actionButton(
                label: 'Jump To Blueprint',
                icon: Icons.grid_view_rounded,
                onPressed: _isWriting ? null : () => _launchOnboarding(step: 2),
              ),
              _actionButton(
                label: 'Command Centre',
                icon: Icons.dashboard_customize_rounded,
                onPressed: _isWriting ? null : _openCommandCentre,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
      ),
    );
  }

  Widget _segmentedWrap(List<Widget> children) {
    return Wrap(spacing: 10, runSpacing: 10, children: children);
  }

  Widget _simButton(String label, bool selected, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? ArcUiTokens.background
            : ArcUiTokens.textPrimary,
        backgroundColor: selected
            ? ArcUiTokens.primaryAccent
            : ArcUiTokens.surfaceRaised.withValues(alpha: 0.84),
        side: BorderSide(
          color: selected
              ? ArcUiTokens.primaryAccent
              : ArcUiTokens.borderMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: ArcUiTokens.textButtonStyle(
        accent: ArcUiTokens.primaryAccent,
        primary: true,
      ),
      icon: _isWriting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(_isWriting ? 'WRITING...' : label),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.warning,
        borderOpacity: 0.22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Channels',
            style: ArcUiTokens.sectionTitle(
              fontSize: 16,
              color: ArcUiTokens.warning,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Active launch route: Stripe Checkout and Stripe Customer Portal. Card wallets are handled by Stripe. Bacs Direct Debit is enabled in the function payment method config. PayPal is not enabled in this pass to avoid splitting subscription authority, webhook logic and payout reporting across two providers.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(value, style: ArcUiTokens.numeric(fontSize: 28, color: color)),
        ],
      ),
    );
  }
}

class _AdminUserStats {
  const _AdminUserStats({
    required this.freeUsers,
    required this.essentialUsers,
    required this.premiumUsers,
    required this.adminUsers,
  });

  final int freeUsers;
  final int essentialUsers;
  final int premiumUsers;
  final int adminUsers;

  factory _AdminUserStats.fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var free = 0;
    var essential = 0;
    var premium = 0;
    var admin = 0;
    for (final doc in docs) {
      final data = doc.data();
      if (data['isAdmin'] == true || data['isDev'] == true) admin++;
      final entitlement = UagEntitlement.fromUserDoc(doc.id, data);
      switch (entitlement.tier) {
        case UagPlanTier.free:
          free++;
          break;
        case UagPlanTier.essential:
          essential++;
          break;
        case UagPlanTier.premium:
          premium++;
          break;
      }
    }
    return _AdminUserStats(
      freeUsers: free,
      essentialUsers: essential,
      premiumUsers: premium,
      adminUsers: admin,
    );
  }
}

class _RevenueStats {
  const _RevenueStats({
    required this.grossPence,
    required this.stripeFeesPence,
    required this.referralCommissionPence,
    required this.netPlatformProfitPence,
    required this.charityPence,
  });

  final int grossPence;
  final int stripeFeesPence;
  final int referralCommissionPence;
  final int netPlatformProfitPence;
  final int charityPence;

  factory _RevenueStats.fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var gross = 0;
    var stripe = 0;
    var referral = 0;
    var net = 0;
    var charity = 0;
    for (final doc in docs) {
      final data = doc.data();
      gross += (data['grossPence'] as num?)?.toInt() ?? 0;
      stripe += (data['stripeFeePence'] as num?)?.toInt() ?? 0;
      referral += (data['referralCommissionPence'] as num?)?.toInt() ?? 0;
      net += (data['netPlatformProfitPence'] as num?)?.toInt() ?? 0;
      charity += (data['charityPence'] as num?)?.toInt() ?? 0;
    }
    return _RevenueStats(
      grossPence: gross,
      stripeFeesPence: stripe,
      referralCommissionPence: referral,
      netPlatformProfitPence: net,
      charityPence: charity,
    );
  }
}
