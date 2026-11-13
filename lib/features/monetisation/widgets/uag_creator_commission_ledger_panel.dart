import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import '../models/uag_creator_commission_pipeline_models.dart';
import '../repositories/uag_creator_commission_pipeline_repository.dart';

class UagCreatorCommissionLedgerPanel extends StatelessWidget {
  const UagCreatorCommissionLedgerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagCreatorCommissionPipelineRepository();
    return StreamBuilder<List<UagCreatorCommissionLedgerView>>(
      stream: repository.watchMyCommissionLifecycle(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <UagCreatorCommissionLedgerView>[];
        final pending = rows
            .where(
              (row) =>
                  row.status ==
                  UagCreatorCommissionLifecycleStatus.pendingValidation,
            )
            .fold<int>(0, (total, row) => total + row.commissionPence);
        final payable = rows
            .where(
              (row) => row.status == UagCreatorCommissionLifecycleStatus.payable,
            )
            .fold<int>(0, (total, row) => total + row.commissionPence);

        return Container(
          width: double.infinity,
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: ArcUiTokens.secondaryAccent,
            borderOpacity: 0.22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMISSION LEDGER',
                style: ArcUiTokens.cardTitle(
                  color: ArcUiTokens.secondaryAccent,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapXS),
              Text(
                'Billing events validate for 30 days before becoming payable.',
                style: ArcUiTokens.bodySmall(),
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              Wrap(
                spacing: ArcUiTokens.gapS,
                runSpacing: ArcUiTokens.gapS,
                children: [
                  _MoneyMetric(label: 'Pending', pence: pending),
                  _MoneyMetric(label: 'Payable', pence: payable),
                  _MoneyMetric(
                    label: 'Events',
                    pence: rows.length * 100,
                    isCount: true,
                  ),
                ],
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              if (rows.isEmpty)
                Text(
                  'No validated Creator billing events yet.',
                  style: ArcUiTokens.bodySmall(),
                )
              else
                for (final row in rows.take(8))
                  Container(
                    margin: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
                    padding: ArcUiTokens.compactPanelPadding,
                    decoration: ArcUiTokens.surfaceDecoration(
                      role: ArcSurfaceRole.interactive,
                      accent: ArcUiTokens.primaryAccent,
                      borderOpacity: 0.14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${row.eventType.label} • ${row.planTier.isEmpty ? 'Subscription' : row.planTier}',
                                style: ArcUiTokens.cardTitle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${row.status.label} • ${row.subscriptionId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ArcUiTokens.metadata(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: ArcUiTokens.gapS),
                        Text(
                          '£${(row.commissionPence / 100).toStringAsFixed(2)}',
                          style: ArcUiTokens.numeric(
                            fontSize: 15,
                            color: ArcUiTokens.secondaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
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
      constraints: const BoxConstraints(minWidth: 126),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: ArcUiTokens.label()),
          const SizedBox(height: 3),
          Text(value, style: ArcUiTokens.numeric(fontSize: 16)),
        ],
      ),
    );
  }
}
