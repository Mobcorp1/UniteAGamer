import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ReferralToolsScreen extends StatefulWidget {
  const ReferralToolsScreen({super.key});

  @override
  State<ReferralToolsScreen> createState() => _ReferralToolsScreenState();
}

class _ReferralToolsScreenState extends State<ReferralToolsScreen> {
  static const _betaReferralCode = 'UAG-BETA';

  Future<void> _copyCode() async {
    await Clipboard.setData(const ClipboardData(text: _betaReferralCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 760;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 16,
                12,
                wide ? 28 : 16,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _ReferralHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 14),
                  _ReferralHeroCard(onCopy: _copyCode),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        const _ReferralMetricCard(
                          label: 'Invites sent',
                          value: '0',
                          icon: Icons.mail_outline_rounded,
                        ),
                        const _ReferralMetricCard(
                          label: 'Joined raiders',
                          value: '0',
                          icon: Icons.groups_rounded,
                        ),
                        const _ReferralMetricCard(
                          label: 'Rewards pending',
                          value: 'Beta',
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ];

                      if (constraints.maxWidth < 680) {
                        return Column(
                          children: cards
                              .map(
                                (card) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
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
                                  padding: const EdgeInsets.only(right: 10),
                                  child: card,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const _ReferralHistoryCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralHeader extends StatelessWidget {
  const _ReferralHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Referral Tools',
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: AppTheme.neonCyan,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferralHeroCard extends StatelessWidget {
  const _ReferralHeroCard({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grow the closed beta squad',
            style: AppTheme.tradingHeading(fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite trusted raiders, track future supporter rewards and keep referral tools separate from your public player profile.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.neonPink.withValues(alpha: 0.28),
                  ),
                ),
                child: const Text(
                  'UAG-BETA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy Code'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Copy Invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralMetricCard extends StatelessWidget {
  const _ReferralMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonCyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTheme.tradingHeading(fontSize: 20)),
                Text(label, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralHistoryCard extends StatelessWidget {
  const _ReferralHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral history',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Referral tracking is ready for the beta reward system. Invites, accepted signups and reward status will appear here once live.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}
