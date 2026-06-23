import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';
import '../screens/arc_availability_screen.dart';
import '../screens/arc_away_screen.dart';
import '../screens/arc_profile_edit_screen.dart';
import '../screens/arc_profile_setup_screen.dart';

class TradingProfileScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile';

  const TradingProfileScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingProfileScreen> createState() => _TradingProfileScreenState();
}

class _TradingProfileScreenState extends State<TradingProfileScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();

  bool _isInitialising = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _repository.ensureDocsExist().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _initError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('TradingProfileScreen._init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _initError = 'Trader profile init failed: $error';
      });
    }
  }

  Future<void> _openSetupIfNeeded() async {
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;

      if (!profile.hasCoreDetails) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ArcProfileSetupScreen()),
        );
        if (!mounted) return;
        setState(() {});
      }
    } catch (error, stackTrace) {
      debugPrint('TradingProfileScreen._openSetupIfNeeded failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _initError = 'Could not open profile setup: $error';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isInitialising = true;
      _initError = null;
    });
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return const Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.darkBackground,
        appBar: widget.showAppBar
            ? const UagAppBar(
                title: 'Trader Profile',
                subtitle:
                    'Identity, reputation, availability and match readiness.',
              )
            : null,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spaceL),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceM,
              AppTheme.spaceS,
              AppTheme.spaceM,
              AppTheme.spaceL,
            ),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: Colors.redAccent.withValues(alpha: 0.28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 34,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: AppTheme.spaceM),
                ElevatedButton(onPressed: _retry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.darkBackground,
      appBar: widget.showAppBar
          ? const UagAppBar(
              title: 'Trader Profile',
              subtitle:
                  'Identity, reputation, availability and match readiness.',
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<ArcTraderProfile>(
          stream: _repository.watchProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(AppTheme.spaceL),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    AppTheme.spaceS,
                    AppTheme.spaceM,
                    AppTheme.spaceL,
                  ),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: Colors.redAccent.withValues(alpha: 0.28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load trader profile data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      ElevatedButton(
                        onPressed: _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return Center(
                child: ElevatedButton(
                  onPressed: _openSetupIfNeeded,
                  child: const Text('Set Up Profile'),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceS,
                AppTheme.spaceM,
                AppTheme.spaceL,
              ),
              children: [
                _summaryCard(profile),
                const SizedBox(height: AppTheme.spaceM),
                _reputationSnapshot(profile),
                const SizedBox(height: AppTheme.spaceM),
                _archetypeSection(),
                const SizedBox(height: AppTheme.spaceM),
                _badgeGallery(),
                const SizedBox(height: AppTheme.spaceM),
                _loadoutPreview(),
                const SizedBox(height: AppTheme.spaceM),
                _detailCard(
                  title: 'Public Profile Details',
                  children: [
                    _detailRow('UAG ID', profile.uagId),
                    _detailRow('UAG Name', profile.uagName),
                    _detailRow('Region', profile.region),
                    _detailRow('Preferred Platform', profile.platform),
                    _detailRow(
                      'Embark ID',
                      profile.embarkId.isEmpty
                          ? 'Hidden until trade confirmed'
                          : profile.embarkId,
                    ),
                    _detailRow('Timezone', profile.timezone),
                    _detailRow(
                      'Subscription Status',
                      profile.subscriptionStatus,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceM),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    AppTheme.spaceS,
                    AppTheme.spaceM,
                    AppTheme.spaceL,
                  ),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonPink.withValues(alpha: 0.20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Tools',
                        style: AppTheme.tradingHeading(
                          fontSize: 20,
                          color: AppTheme.neonPink,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      const Text(
                        'Copy or share your referral code for signup tracking and future affiliate rewards.',
                        style: TextStyle(color: Colors.white70, height: 1.35),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.copy_all_rounded),
                              label: const Text('Copy Code'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share Code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _actionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Trader Profile',
                  subtitle:
                      'Update your UAG identity, platform, region and visibility.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ArcProfileEditScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _actionTile(
                  icon: Icons.schedule_outlined,
                  title: 'Availability',
                  subtitle:
                      'Set a weekly, rotation or flexible trade schedule.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ArcAvailabilityScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _actionTile(
                  icon: Icons.beach_access_outlined,
                  title: 'Away Mode',
                  subtitle:
                      'Hide yourself from search while on holiday or away.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArcAwayScreen()),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    AppTheme.spaceS,
                    AppTheme.spaceM,
                    AppTheme.spaceL,
                  ),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonPink.withValues(alpha: 0.16),
                  ),
                  child: const Text(
                    'Embark ID stays private until a trade is confirmed. Public profile surfaces reputation, archetypes, badges and favourite loadout only.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(ArcTraderProfile profile) {
    final statusColor = profile.isProfileComplete
        ? AppTheme.neonCyan
        : AppTheme.neonPink;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        AppTheme.spaceS,
        AppTheme.spaceM,
        AppTheme.spaceL,
      ),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: statusColor.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: statusColor.withValues(alpha: 0.16),
                child: Icon(Icons.person_outline, color: statusColor),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.uagName.isEmpty
                          ? 'No UAG Name yet'
                          : profile.uagName,
                      style: AppTheme.tradingHeading(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.uagId.isEmpty
                          ? 'Set up your profile to appear in searches later.'
                          : profile.uagId,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppTheme.tradingPillDecoration(color: statusColor),
                child: Text(
                  profile.isProfileComplete ? 'Ready' : 'Incomplete',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _miniTag(
                icon: Icons.public_outlined,
                text: profile.region.isEmpty
                    ? 'Region not set'
                    : profile.region,
              ),
              _miniTag(
                icon: Icons.sports_esports_outlined,
                text: profile.platform.isEmpty
                    ? 'Platform not set'
                    : profile.platform,
              ),
              _miniTag(
                icon: Icons.mic_outlined,
                text: profile.micOk ? 'Mic okay' : 'Mic off',
              ),
              _miniTag(
                icon: Icons.travel_explore_outlined,
                text: profile.crossRegionOk
                    ? 'Cross-region okay'
                    : 'Local only',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reputationSnapshot(ArcTraderProfile profile) {
    final ready = profile.isProfileComplete;
    return _profilePanel(
      accent: ready ? AppTheme.neonCyan : AppTheme.neonPink,
      title: 'Reputation Snapshot',
      icon: Icons.verified_user_rounded,
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: [
          _profileChip(
            icon: Icons.shield_outlined,
            label: ready ? 'Trusted setup' : 'Profile incomplete',
            accent: ready ? AppTheme.neonCyan : AppTheme.neonPink,
          ),
          _profileChip(
            icon: Icons.visibility_outlined,
            label: profile.visibleInSearch ? 'Visible' : 'Hidden',
            accent: AppTheme.neonCyan,
          ),
          _profileChip(
            icon: Icons.mic_rounded,
            label: profile.micOk ? 'Mic ready' : 'No mic',
            accent: AppTheme.neonPink,
          ),
          _profileChip(
            icon: Icons.public_rounded,
            label: profile.crossPlatformOk ? 'Crossplay' : 'Platform locked',
            accent: AppTheme.neonCyan,
          ),
        ],
      ),
    );
  }

  Widget _archetypeSection() {
    const archetypes = <({IconData icon, String label, String copy})>[
      (
        icon: Icons.health_and_safety_rounded,
        label: 'Guardian',
        copy: 'Protects squad',
      ),
      (
        icon: Icons.medical_services_rounded,
        label: 'Medic',
        copy: 'Revive focused',
      ),
      (
        icon: Icons.backpack_rounded,
        label: 'Loot Goblin',
        copy: 'Resource hunter',
      ),
      (icon: Icons.handshake_rounded, label: 'Trader', copy: 'Swap ready'),
    ];

    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Player Archetypes',
      icon: Icons.groups_rounded,
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: archetypes
            .map(
              (item) => _archetypeBadge(
                icon: item.icon,
                label: item.label,
                copy: item.copy,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _badgeGallery() {
    const badges = <({IconData icon, String label})>[
      (icon: Icons.military_tech_rounded, label: 'Beta'),
      (icon: Icons.route_rounded, label: 'Pathfinder'),
      (icon: Icons.local_fire_department_rounded, label: 'Trailblazer'),
      (icon: Icons.diamond_rounded, label: 'Supporter'),
      (icon: Icons.workspace_premium_rounded, label: 'Trusted'),
    ];

    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Badges',
      icon: Icons.auto_awesome_rounded,
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: badges
            .map((badge) => _badgeThumb(icon: badge.icon, label: badge.label))
            .toList(growable: false),
      ),
    );
  }

  Widget _loadoutPreview() {
    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Favourite Loadout',
      icon: Icons.inventory_2_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Public preview of primary, secondary, shield, augment and five favourite equipment slots.',
            style: TextStyle(color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            children: [
              Expanded(child: _loadoutSlot('Primary', Icons.gps_fixed_rounded)),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: _loadoutSlot('Secondary', Icons.flash_on_rounded),
              ),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: _loadoutSlot('Utility', Icons.blur_circular_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profilePanel({
    required Color accent,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: accent.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: AppTheme.spaceS),
              Text(
                title,
                style: AppTheme.tradingHeading(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );
  }

  Widget _profileChip({
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppTheme.tradingPillDecoration(color: accent),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _archetypeBadge({
    required IconData icon,
    required String label,
    required String copy,
  }) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.neonPink, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            copy,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _badgeThumb({required IconData icon, required String label}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(label, style: const TextStyle(color: Colors.white)),
          content: Icon(icon, size: 72, color: AppTheme.neonCyan),
        ),
      ),
      child: Container(
        width: 72,
        height: 78,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.neonCyan, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadoutSlot(String label, IconData icon) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        AppTheme.spaceS,
        AppTheme.spaceM,
        AppTheme.spaceL,
      ),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'Not set' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceM,
          AppTheme.spaceS,
          AppTheme.spaceM,
          AppTheme.spaceL,
        ),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: Colors.white.withValues(alpha: 0.10),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, color: AppTheme.neonPink),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.tradingHeading(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _miniTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
