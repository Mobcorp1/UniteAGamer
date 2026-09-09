import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/uag_community_referral_policy.dart';
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
      if (!termsAccepted) {
        await _repository.acceptCurrentReferralTerms();
      }
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
        SnackBar(content: Text('Could not create referral link. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _repository.watchMyReferralSummary(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            final validated =
                (data['validatedReferrals'] as num?)?.toInt() ?? 0;
            final pending = (data['pendingReferrals'] as num?)?.toInt() ?? 0;
            final next = UagCommunityReferralPolicy.nextMilestone(validated);

            return StreamBuilder<bool>(
              stream: _repository.watchReferralTermsAccepted(),
              builder: (context, termsSnapshot) {
                final termsAccepted = termsSnapshot.data == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'REFER A RAIDER',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You do not need to be a creator. Bring your squad into UAG and unlock community rewards when genuine referrals stick around.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('$validated VALIDATED')),
                        Chip(label: Text('$pending PENDING')),
                        if (next != null)
                          Chip(
                            label: Text(
                              'NEXT: ${next.validatedReferrals} • ${next.label}',
                            ),
                          ),
                      ],
                    ),
                    if (!termsAccepted) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _termsChecked,
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  setState(() => _termsChecked = value == true),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I accept the Refer a Raider programme terms.',
                        ),
                        subtitle: Text(
                          'Version ${UagReferralTermsPolicy.version}. Genuine referrals only; no self-referrals, duplicate accounts or fabricated activity.',
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'Referral terms accepted • ${UagReferralTermsPolicy.version}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _copyLink(termsAccepted: termsAccepted),
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(_busy ? 'CREATING...' : 'COPY REFERRAL LINK'),
                    ),
                    if (validated >= 5) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Creator Programme fast-track review unlocked. Your referral record is carried into the Creator application review.',
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
