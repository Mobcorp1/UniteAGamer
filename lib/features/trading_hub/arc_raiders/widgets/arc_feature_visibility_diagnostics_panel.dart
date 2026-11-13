import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_feature_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_control_config.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcFeatureVisibilityDiagnosticsPanel extends StatelessWidget {
  const ArcFeatureVisibilityDiagnosticsPanel({super.key});

  Future<ArcFeatureVisibilityDiagnosticsSnapshot> _load() async {
    final repository = ArcUserPersonalisationRepository();
    final personalisation = await repository.loadProfile();
    final accessFlags = <String>{
      for (final entry in ArcFeatureRegistry.entries)
        if (entry.accessFlag != null) entry.accessFlag!,
    };

    final featureAccessSnapshot = await FirebaseFirestore.instance
        .collection('config')
        .doc('feature_access')
        .get();
    final featureAvailability = FeatureAccess.availabilityMapFromConfigData(
      featureAccessSnapshot.data() ?? const <String, dynamic>{},
      accessFlags,
    );

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

    return ArcFeatureVisibilityDiagnosticsEngine.snapshot(
      personalisation: personalisation,
      featureAvailability: featureAvailability,
      adminControls: adminControls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ArcFeatureVisibilityDiagnosticsSnapshot>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: ArcUiTokens.panelPadding,
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.panel,
              accent: ArcUiTokens.primaryAccent,
              borderOpacity: 0.18,
            ),
            child: const LinearProgressIndicator(
              color: ArcUiTokens.primaryAccent,
            ),
          );
        }

        final diagnostics =
            snapshot.data?.diagnostics ??
            const <ArcFeatureVisibilityDiagnostic>[];
        final summary = snapshot.data?.summary;
        return Container(
          width: double.infinity,
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.panel,
            accent: ArcUiTokens.admin,
            borderOpacity: 0.24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rule_folder_outlined,
                    color: ArcUiTokens.admin,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Feature Visibility Diagnostics',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 16,
                        color: ArcUiTokens.admin,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Read-only view of feature access, personalisation, lifecycle and final visibility. Dormant future systems remain hidden even when named in the registry.',
                style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (summary != null) ...[
                _ConfigurationSummary(summary: summary),
                const SizedBox(height: AppTheme.spaceM),
              ],
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

class _ConfigurationSummary extends StatelessWidget {
  const _ConfigurationSummary({required this.summary});

  final ArcClosedBetaConfigurationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Closed Beta Configuration',
            style: ArcUiTokens.body(
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _CountPill(
                label: 'Live',
                value: summary.liveCount,
                color: ArcUiTokens.primaryAccent,
              ),
              _CountPill(
                label: 'Coming Soon',
                value: summary.comingSoonCount,
                color: ArcUiTokens.warning,
              ),
              _CountPill(
                label: 'Hidden',
                value: summary.hiddenCount,
                color: ArcUiTokens.secondaryAccent,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              for (final status in summary.coreJourney)
                _CoreStatusPill(status: status),
            ],
          ),
          if (summary.hasWarnings) ...[
            const SizedBox(height: AppTheme.spaceM),
            for (final warning in summary.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: ArcUiTokens.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: ArcUiTokens.bodySmall(
                          color: ArcUiTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text('$label: $value', style: ArcUiTokens.label(color: color)),
    );
  }
}

class _CoreStatusPill extends StatelessWidget {
  const _CoreStatusPill({required this.status});

  final ArcClosedBetaJourneyStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.warning
        ? ArcUiTokens.secondaryAccent
        : status.status == FeatureAvailability.comingSoon.label
        ? ArcUiTokens.warning
        : ArcUiTokens.primaryAccent;
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(
        '${status.label}: ${status.status}',
        style: ArcUiTokens.label(color: color),
      ),
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
    final accent = visible
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.secondaryAccent;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        borderOpacity: 0.22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: ArcUiTokens.body(
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
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
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ArcUiTokens.chipDecoration(
        color: positive
            ? ArcUiTokens.primaryAccent
            : ArcUiTokens.secondaryAccent,
      ),
      child: Text(
        label.toUpperCase(),
        style: ArcUiTokens.label(
          color: positive
              ? ArcUiTokens.primaryAccent
              : ArcUiTokens.secondaryAccent,
        ),
      ),
    );
  }

  Widget _textPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ArcUiTokens.chipDecoration(color: ArcUiTokens.textTertiary),
      child: Text(
        label,
        style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
      ),
    );
  }
}
