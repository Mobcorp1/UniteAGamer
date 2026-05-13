import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

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

  Future<void> _copyReferralCode(String code) async {
    if (code.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied')));
  }

  Future<void> _shareReferralCode(String code) async {
    if (code.trim().isEmpty) return;
    await Share.share(
      'Join UAG ARC Raiders Hub using my referral code: $code',
      subject: 'UAG ARC Raiders Hub Referral',
    );
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
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: widget.showAppBar
            ? const UagAppBar(
                title: 'Trader Profile',
                subtitle:
                    'Identity, visibility, availability and referral tools.',
              )
            : null,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spaceL),
            padding: const EdgeInsets.all(AppTheme.spaceL),
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
                const SizedBox(height: AppTheme.spaceL),
                ElevatedButton(onPressed: _retry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: widget.showAppBar
          ? const UagAppBar(
              title: 'Trader Profile',
              subtitle:
                  'Identity, visibility, availability and referral tools.',
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
                  padding: const EdgeInsets.all(AppTheme.spaceL),
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
                      const SizedBox(height: AppTheme.spaceL),
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
              padding: const EdgeInsets.all(AppTheme.spaceL),
              children: [
                _summaryCard(profile),
                const SizedBox(height: AppTheme.spaceL),
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
                    _detailRow('Referral Code', profile.referralCode),
                    _detailRow(
                      'Referred By',
                      profile.referredByCode.isEmpty
                          ? 'No referral code used'
                          : profile.referredByCode,
                    ),
                    _detailRow(
                      'Affiliate Programme',
                      profile.affiliateEnabled ? 'Applied' : 'Not applied',
                    ),
                    _detailRow('Payout Method', profile.payoutMethod),
                    _detailRow(
                      'Subscription Status',
                      profile.subscriptionStatus,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
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
                              onPressed: profile.referralCode.trim().isEmpty
                                  ? null
                                  : () =>
                                        _copyReferralCode(profile.referralCode),
                              icon: const Icon(Icons.copy_all_rounded),
                              label: const Text('Copy Code'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: profile.referralCode.trim().isEmpty
                                  ? null
                                  : () => _shareReferralCode(
                                      profile.referralCode,
                                    ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share Code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
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
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonPink.withValues(alpha: 0.16),
                  ),
                  child: const Text(
                    'Embark ID and exact scheduling should stay private until a trade has actually been set up and confirmed.',
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
      padding: const EdgeInsets.all(AppTheme.spaceL),
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
          const SizedBox(height: AppTheme.spaceL),
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

  Widget _detailCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
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
        padding: const EdgeInsets.all(AppTheme.spaceL),
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
