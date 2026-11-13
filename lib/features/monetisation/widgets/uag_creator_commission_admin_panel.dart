import 'package:flutter/material.dart';

import '../models/uag_creator_commission_pipeline_models.dart';
import '../repositories/uag_creator_commission_pipeline_repository.dart';

class UagCreatorCommissionAdminPanel extends StatefulWidget {
  const UagCreatorCommissionAdminPanel({super.key});

  @override
  State<UagCreatorCommissionAdminPanel> createState() =>
      _UagCreatorCommissionAdminPanelState();
}

class _UagCreatorCommissionAdminPanelState
    extends State<UagCreatorCommissionAdminPanel> {
  final _repository = UagCreatorCommissionPipelineRepository();
  final _creatorUid = TextEditingController();
  final _referredUid = TextEditingController();
  final _subscriptionId = TextEditingController();
  final _eventId = TextEditingController();
  final _gross = TextEditingController();
  final _net = TextEditingController();
  final _rate = TextEditingController(text: '10');
  String _tier = 'premium';
  UagCreatorBillingEventType _eventType =
      UagCreatorBillingEventType.subscriptionStarted;
  bool _busy = false;

  @override
  void dispose() {
    _creatorUid.dispose();
    _referredUid.dispose();
    _subscriptionId.dispose();
    _eventId.dispose();
    _gross.dispose();
    _net.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final event = UagCreatorValidatedBillingEvent(
        id: _eventId.text.trim(),
        creatorUid: _creatorUid.text.trim(),
        referredUid: _referredUid.text.trim(),
        subscriptionId: _subscriptionId.text.trim(),
        eventType: _eventType,
        planTier: _tier,
        grossAmountPence: int.tryParse(_gross.text.trim()) ?? 0,
        eligibleNetAmountPence: int.tryParse(_net.text.trim()) ?? 0,
        commissionRatePercent: double.tryParse(_rate.text.trim()) ?? 0,
        occurredAt: DateTime.now().toUtc(),
      );
      final result = await _repository.processValidatedBillingEvent(
        event: event,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.created
                ? 'Creator billing event added: ${result.lifecycleStatus.label}.'
                : 'Billing event already exists; no duplicate commission created.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update creator commission. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _releaseMatured() async {
    final creator = _creatorUid.text.trim();
    if (creator.isEmpty) return;
    setState(() => _busy = true);
    try {
      final count = await _repository.releaseMaturedCommission(
        creatorUid: creator,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count commission event(s) became payable.')),
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
              'CREATOR COMMISSION PIPELINE',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Admin validation bridge until billing webhooks become authoritative. Entries are idempotent and tied to the referred account attribution.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creatorUid,
              decoration: const InputDecoration(labelText: 'Creator UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referredUid,
              decoration: const InputDecoration(labelText: 'Referred user UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subscriptionId,
              decoration: const InputDecoration(labelText: 'Subscription ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _eventId,
              decoration: const InputDecoration(
                labelText: 'Unique billing event ID',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<UagCreatorBillingEventType>(
              initialValue: _eventType,
              decoration: const InputDecoration(labelText: 'Billing event'),
              items: [
                for (final event in UagCreatorBillingEventType.values)
                  DropdownMenuItem(value: event, child: Text(event.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _eventType = value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              decoration: const InputDecoration(labelText: 'Plan tier'),
              items: const [
                DropdownMenuItem(value: 'essential', child: Text('Essential')),
                DropdownMenuItem(value: 'premium', child: Text('Premium')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _tier = value);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gross,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Gross pence'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _net,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Eligible net pence',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Commission %',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _process,
              child: Text(_busy ? 'PROCESSING...' : 'PROCESS VALIDATED EVENT'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _releaseMatured,
              child: const Text('RELEASE MATURED 30-DAY COMMISSION'),
            ),
          ],
        ),
      ),
    );
  }
}
