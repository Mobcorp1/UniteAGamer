import 'package:flutter/material.dart';

import '../models/uag_creator_commission_pipeline_models.dart';
import '../repositories/uag_creator_commission_integrity_repository.dart';

class UagCreatorCommercialIntegrityAdminPanel extends StatefulWidget {
  const UagCreatorCommercialIntegrityAdminPanel({super.key});

  @override
  State<UagCreatorCommercialIntegrityAdminPanel> createState() =>
      _UagCreatorCommercialIntegrityAdminPanelState();
}

class _UagCreatorCommercialIntegrityAdminPanelState
    extends State<UagCreatorCommercialIntegrityAdminPanel> {
  final _repository = UagCreatorCommissionIntegrityRepository();
  final _creator = TextEditingController();
  final _ledger = TextEditingController();
  final _original = TextEditingController();
  final _payout = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _creator.dispose();
    _ledger.dispose();
    _original.dispose();
    _payout.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final message = await action();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Commercial integrity action could not be completed.'),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'COMMERCIAL INTEGRITY',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Reconcile Creator balances, release matured commission, reverse original events and close payout lifecycle.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _creator,
              decoration: const InputDecoration(labelText: 'Creator UID'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final rate = await _repository
                              .authoritativeCommissionRate(
                                _creator.text.trim(),
                              );
                          return 'Effective Creator rate: ${rate.toStringAsFixed(1)}%.';
                        }),
                  child: const Text('CHECK RATE'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final count = await _repository.releaseMaturedSafely(
                            _creator.text.trim(),
                          );
                          return '$count commission event(s) became payable.';
                        }),
                  child: const Text('RELEASE 30-DAY'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _repository.reconcileCommissionDashboard(
                            _creator.text.trim(),
                          );
                          return 'Creator commission dashboard reconciled from ledger.';
                        }),
                  child: const Text('RECONCILE'),
                ),
              ],
            ),
            const Divider(height: 24),
            TextField(
              controller: _original,
              decoration: const InputDecoration(
                labelText: 'Original billing event ID',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _repository.reverseOriginal(
                            creatorUid: _creator.text.trim(),
                            originalBillingEventId: _original.text.trim(),
                            reversalType: UagCreatorBillingEventType.refund,
                            reason: 'admin validated refund',
                          );
                          return 'Original event reversed for refund.';
                        }),
                  child: const Text('REFUND'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _repository.reverseOriginal(
                            creatorUid: _creator.text.trim(),
                            originalBillingEventId: _original.text.trim(),
                            reversalType: UagCreatorBillingEventType.chargeback,
                            reason: 'admin validated chargeback',
                          );
                          return 'Original event reversed for chargeback.';
                        }),
                  child: const Text('CHARGEBACK'),
                ),
              ],
            ),
            const Divider(height: 24),
            TextField(
              controller: _ledger,
              decoration: const InputDecoration(
                labelText: 'Payable ledger entry ID',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payout,
              decoration: const InputDecoration(labelText: 'Payout reference'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _repository.markPayableEntryPaid(
                        creatorUid: _creator.text.trim(),
                        ledgerId: _ledger.text.trim(),
                        payoutReference: _payout.text.trim(),
                      );
                      return 'Commission marked paid and dashboard reconciled.';
                    }),
              child: const Text('MARK PAID'),
            ),
          ],
        ),
      ),
    );
  }
}
