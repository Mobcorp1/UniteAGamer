import 'package:flutter/material.dart';

import '../models/uag_creator_commission_pipeline_models.dart';
import '../repositories/uag_creator_commission_pipeline_repository.dart';

class UagCreatorCommissionLedgerPanel extends StatelessWidget {
  const UagCreatorCommissionLedgerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagCreatorCommissionPipelineRepository();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<UagCreatorCommissionLedgerView>>(
          stream: repository.watchMyCommissionLifecycle(),
          builder: (context, snapshot) {
            final rows =
                snapshot.data ?? const <UagCreatorCommissionLedgerView>[];
            final pending = rows
                .where(
                  (row) =>
                      row.status ==
                      UagCreatorCommissionLifecycleStatus.pendingValidation,
                )
                .fold<int>(0, (total, row) => total + row.commissionPence);
            final payable = rows
                .where(
                  (row) =>
                      row.status == UagCreatorCommissionLifecycleStatus.payable,
                )
                .fold<int>(0, (total, row) => total + row.commissionPence);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'COMMISSION LEDGER',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Validated subscription revenue enters a 30-day validation window before becoming payable.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MoneyMetric(label: 'Pending validation', pence: pending),
                    _MoneyMetric(label: 'Payable', pence: payable),
                    _MoneyMetric(
                      label: 'Ledger events',
                      pence: rows.length * 100,
                      isCount: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Text('No validated Creator billing events yet.')
                else
                  for (final row in rows.take(12))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        '${row.eventType.label} • ${row.planTier.isEmpty ? 'Subscription' : row.planTier}',
                      ),
                      subtitle: Text(
                        '${row.status.label} • ${row.subscriptionId}',
                      ),
                      trailing: Text(
                        '£${(row.commissionPence / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.pence,
    this.isCount = false,
  });

  final String label;
  final int pence;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    final value = isCount
        ? '${pence ~/ 100}'
        : '£${(pence / 100).toStringAsFixed(2)}';
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
