import 'package:flutter/material.dart';

import '../repositories/uag_referral_validation_repository.dart';

class UagReferralValidationAdminPanel extends StatefulWidget {
  const UagReferralValidationAdminPanel({super.key});

  @override
  State<UagReferralValidationAdminPanel> createState() =>
      _UagReferralValidationAdminPanelState();
}

class _UagReferralValidationAdminPanelState
    extends State<UagReferralValidationAdminPanel> {
  final _repository = UagReferralValidationRepository();
  final _referrer = TextEditingController();
  final _referred = TextEditingController();
  final _reason = TextEditingController(text: 'qualified retained referral');
  bool _busy = false;

  @override
  void dispose() {
    _referrer.dispose();
    _referred.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'REFERRAL VALIDATION',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Temporary admin bridge until referral qualification is automated server-side.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referrer,
              decoration: const InputDecoration(labelText: 'Referrer UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referred,
              decoration: const InputDecoration(labelText: 'Referred UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Validation reason'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _busy = true);
                      try {
                        final result = await _repository.validateReferral(
                          referredUid: _referred.text.trim(),
                          referrerUid: _referrer.text.trim(),
                          validationReason: _reason.text.trim(),
                        );
                        if (!mounted) return;
                        final milestones = result.awardedMilestones.isEmpty
                            ? 'No new milestone reward.'
                            : 'Milestones awarded: ${result.awardedMilestones.join(', ')}.';
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Referral validated. ${result.newValidatedReferrals} total. $milestones',
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(_busy ? 'VALIDATING...' : 'VALIDATE REFERRAL'),
            ),
          ],
        ),
      ),
    );
  }
}
