import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_community_referral_policy.dart';
import '../models/uag_referral_commission_policy.dart';
import '../models/uag_referral_terms_policy.dart';
import '../repositories/uag_community_referral_repository.dart';

class UagReferARaiderPanel extends StatefulWidget {
  const UagReferARaiderPanel({super.key});

  @override
  State<UagReferARaiderPanel> createState() => _UagReferARaiderPanelState();
}

class _UagReferARaiderPanelState extends State<UagReferARaiderPanel> {
  final _repository = UagCommunityReferralRepository();
  bool _busy = false;
  bool _termsChecked = false;

  Future<void> _copyLink({required bool termsAccepted}) async {
    if (_busy) return;
    if (!termsAccepted && !_termsChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accept the Refer a Raider terms first.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      if (!termsAccepted) await _repository.acceptCurrentReferralTerms();
      final code = await _repository.ensureMyReferralCode();
      final uri = _repository.referralUri(code);
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refer a Raider link copied.')),
      );
    } on StateError catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create referral link. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _repository.watchMyReferralSummary(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final validated = (data['validatedReferrals'] as num?)?.toInt() ?? 0;
        final pending = (data['pendingReferrals'] as num?)?.toInt() ?? 0;
        final activePaid = (data['activePaidReferrals'] as num?)?.toInt() ?? 0;
        final tier = (data['_subscriptionTier'] ?? '').toString().toLowerCase();
        final status = (data['_subscriptionStatus'] ?? '').toString().toLowerCase();
        final premiumActive = tier == 'premium' &&
            const {'active', 'trialing', 'trial', 'paid'}.contains(status);
        final baseRate = UagReferralCommissionPolicy.baseRatePercent(activePaid);
        final effectiveRate = UagReferralCommissionPolicy.effectiveRatePercent(
          activePaidReferrals: activePaid,
          premiumActive: premiumActive,
        );
        final nextBand = UagReferralCommissionPolicy.nextBand(activePaid);
        final nextReward = UagCommunityReferralPolicy.nextMilestone(validated);

        return StreamBuilder<bool>(
          stream: _repository.watchReferralTermsAccepted(),
          builder: (context, termsSnapshot) {
            final termsAccepted = termsSnapshot.data == true;
            return ArcTacticalPanel(
              icon: Icons.person_add_alt_1_rounded,
              title: 'REFER & EARN',
              subtitle:
                  'Share UAG. Your Raider gets 10% off their first paid purchase; you earn recurring commission when paid referrals stay active.',
              accent: ArcUiTokens.secondaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ArcUiTokens.gapS,
                    runSpacing: ArcUiTokens.gapS,
                    children: [
                      _Stat(label: 'ACTIVE PAID', value: '$activePaid'),
                      _Stat(label: 'VALIDATED', value: '$validated'),
                      _Stat(label: 'PENDING', value: '$pending'),
                      _Stat(
                        label: 'YOUR RATE',
                        value: effectiveRate <= 0
                            ? '5% from first paid referral'
                            : '${_pct(effectiveRate)}%',
                        accent: ArcUiTokens.secondaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: ArcUiTokens.gapM),
                  Text(
                    premiumActive && baseRate > 0
                        ? 'Premium boost active: ${_pct(baseRate)}% base + 2.5 percentage points.'
                        : 'Commission ladder: 5% → 7.5% → 10% → 12.5% → 15%. Premium adds +2.5 percentage points while active.',
                    style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
                  ),
                  if (nextBand != null) ...[
                    const SizedBox(height: ArcUiTokens.gapXS),
                    Text(
                      'Next cash rate at ${nextBand.minActivePaidReferrals} active paid referrals: ${_pct(nextBand.baseRatePercent)}% base.',
                      style: ArcUiTokens.metadata(color: ArcUiTokens.primaryAccent),
                    ),
                  ],
                  if (nextReward != null) ...[
                    const SizedBox(height: ArcUiTokens.gapXS),
                    Text(
                      'Next community reward: ${nextReward.validatedReferrals} validated referrals • ${nextReward.label}.',
                      style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
                    ),
                  ],
                  if (!termsAccepted) ...[
                    const SizedBox(height: ArcUiTokens.gapM),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _termsChecked,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _termsChecked = value == true),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ArcUiTokens.secondaryAccent,
                      title: Text(
                        'I accept the Refer a Raider programme terms.',
                        style: ArcUiTokens.body(fontSize: 12.5),
                      ),
                      subtitle: Text(
                        'Version ${UagReferralTermsPolicy.version}. Genuine referrals only; no self-referrals, duplicate accounts or fabricated activity.',
                        style: ArcUiTokens.bodySmall(),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: ArcUiTokens.gapM),
                    Text(
                      'Referral terms accepted • ${UagReferralTermsPolicy.version}',
                      style: ArcUiTokens.metadata(color: ArcUiTokens.success),
                    ),
                  ],
                  const SizedBox(height: ArcUiTokens.gapM),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: ArcUiTokens.textButtonStyle(
                        accent: ArcUiTokens.secondaryAccent,
                        primary: true,
                      ),
                      onPressed: _busy
                          ? null
                          : () => _copyLink(termsAccepted: termsAccepted),
                      icon: const Icon(Icons.link_rounded),
                      label: Text(_busy ? 'CREATING...' : 'COPY REFERRAL LINK'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ArcUiTokens.primaryAccent;
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArcUiTokens.label(color: ArcUiTokens.textTertiary)),
          const SizedBox(height: 3),
          Text(value, style: ArcUiTokens.numeric(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

String _pct(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
