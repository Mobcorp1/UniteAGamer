import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_entitlement_test_mode.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagEntitlementTestModeCard extends StatelessWidget {
  const UagEntitlementTestModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = UagEntitlementService();
    return StreamBuilder(
      stream: service.watchMyEntitlement(),
      builder: (context, snapshot) {
        final entitlement = snapshot.data;
        if (entitlement == null || !entitlement.hasAdminBypass) {
          return const SizedBox.shrink();
        }

        final simulating = entitlement.testMode != UagEntitlementTestMode.real;

        return Container(
          width: double.infinity,
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.panel,
            accent: AppTheme.warningAmber,
            borderOpacity: 0.34,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: AppTheme.warningAmber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'TEST ACCOUNT MODE',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 16,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ),
                  if (simulating)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppTheme.warningAmber.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppTheme.warningAmber.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        'TEST: ${entitlement.testMode.label.toUpperCase()}',
                        style: ArcUiTokens.body(
                          fontSize: 11,
                          color: AppTheme.warningAmber,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Admin/dev only. Switch how this account experiences UAG without changing the real subscription.',
                style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UagEntitlementTestMode.values.map((mode) {
                  final selected = entitlement.testMode == mode;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(mode.label),
                    onSelected: selected
                        ? null
                        : (_) async {
                            try {
                              await service.setMyEntitlementTestMode(mode);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    mode == UagEntitlementTestMode.real
                                        ? 'Returned to real entitlement.'
                                        : 'Test account mode: ${mode.label}',
                                  ),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not change test account mode.',
                                  ),
                                ),
                              );
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                simulating
                    ? 'SIMULATING ${entitlement.testMode.label.toUpperCase()} • real entitlement remains ${entitlement.tier.label}'
                    : 'REAL MODE • current entitlement: ${entitlement.tier.label}',
                style: ArcUiTokens.body(
                  color: simulating
                      ? AppTheme.warningAmber
                      : ArcUiTokens.textSecondary,
                  weight: FontWeight.w700,
                ),
              ),
              if (simulating) ...[
                const SizedBox(height: AppTheme.spaceM),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await service.setMyEntitlementTestMode(
                        UagEntitlementTestMode.real,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Returned to real entitlement.'),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not return to real entitlement.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('RETURN TO REAL ENTITLEMENT'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
