import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_feature_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_control_config.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcFeatureVisibilityDiagnosticsPanel extends StatelessWidget {
  const ArcFeatureVisibilityDiagnosticsPanel({super.key});

  Future<List<ArcFeatureVisibilityDiagnostic>> _load() async {
    final repository = ArcUserPersonalisationRepository();
    final personalisation = await repository.loadProfile();
    final featureAvailability = <String, FeatureAvailability>{};
    for (final entry in ArcFeatureRegistry.entries) {
      final flag = entry.accessFlag;
      if (flag == null || featureAvailability.containsKey(flag)) continue;
      featureAvailability[flag] = await FeatureAccess.getAvailability(flag);
    }

    final adminSnapshot = await FirebaseFirestore.instance
        .collection('config')
        .doc('arc_admin_controls')
        .get();
    final adminConfig = ArcAdminControlConfig.fromDocument(
      adminSnapshot.data(),
    );
    final adminControls = <String, bool>{
      for (final entry in ArcFeatureRegistry.entries)
        if (entry.adminFlag != null)
          entry.adminFlag!: adminConfig.isFeatureEnabled(entry.adminFlag!),
    };

    return ArcFeatureVisibilityDiagnosticsEngine.build(
      personalisation: personalisation,
      featureAvailability: featureAvailability,
      adminControls: adminControls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArcFeatureVisibilityDiagnostic>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: AppTheme.sectionCardPadding,
            decoration: AppTheme.tradingCardDecoration(),
            child: const LinearProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        final diagnostics =
            snapshot.data ?? const <ArcFeatureVisibilityDiagnostic>[];
        return Container(
          width: double.infinity,
          padding: AppTheme.sectionCardPadding,
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonPink.withValues(alpha: 0.24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rule_folder_outlined,
                    color: AppTheme.neonPink,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Feature Visibility Diagnostics',
                      style: AppTheme.tradingHeading(fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Read-only view of feature access, personalisation, lifecycle and final visibility. Dormant future systems remain hidden even when named in the registry.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 900
                      ? (constraints.maxWidth - AppTheme.spaceM) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppTheme.spaceM,
                    runSpacing: AppTheme.spaceM,
                    children: [
                      for (final diagnostic in diagnostics)
                        SizedBox(
                          width: cardWidth,
                          child: _DiagnosticTile(diagnostic: diagnostic),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({required this.diagnostic});

  final ArcFeatureVisibilityDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final entry = diagnostic.entry;
    final visible = diagnostic.visible;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: visible
              ? AppTheme.neonCyan.withValues(alpha: 0.22)
              : AppTheme.neonPink.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
              ),
              _pill(visible ? 'Visible' : 'Hidden', visible),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _textPill('Interest: ${diagnostic.personalisationLevel.name}'),
              _textPill('Lifecycle: ${entry.lifecycle.name}'),
              if (entry.accessFlag != null)
                _textPill('Access: ${diagnostic.availability.label}'),
              if (entry.adminFlag != null)
                _textPill('Admin: ${entry.adminFlag}'),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            diagnostic.reason,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.tradingMutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppTheme.tradingPillDecoration(
        color: positive ? AppTheme.neonCyan : AppTheme.neonPink,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.bodyTextStyle(
          fontSize: 10,
          color: positive ? AppTheme.neonCyan : AppTheme.neonPink,
          isBold: true,
        ),
      ),
    );
  }

  Widget _textPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(
          fontSize: 10,
          color: Colors.white70,
          isBold: true,
        ),
      ),
    );
  }
}
