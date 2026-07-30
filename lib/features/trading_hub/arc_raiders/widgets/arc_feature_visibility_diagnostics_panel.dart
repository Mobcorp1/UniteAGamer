import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_feature_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_control_config.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
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
            padding: AppTheme.sectionCardPadding,
            decoration: AppTheme.tradingCardDecoration(),
            child: const LinearProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        final diagnostics =
            snapshot.data?.diagnostics ??
            const <ArcFeatureVisibilityDiagnostic>[];
        final summary = snapshot.data?.summary;
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
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Closed Beta Configuration',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: Colors.white,
              isBold: true,
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
                color: AppTheme.neonCyan,
              ),
              _CountPill(
                label: 'Coming Soon',
                value: summary.comingSoonCount,
                color: Colors.amberAccent,
              ),
              _CountPill(
                label: 'Hidden',
                value: summary.hiddenCount,
                color: AppTheme.neonPink,
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
                      color: Colors.amberAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 12,
                          color: Colors.white70,
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
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(fontSize: 11, color: color, isBold: true),
      ),
    );
  }
}

class _CoreStatusPill extends StatelessWidget {
  const _CoreStatusPill({required this.status});

  final ArcClosedBetaJourneyStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.warning
        ? AppTheme.neonPink
        : status.status == FeatureAvailability.comingSoon.label
        ? Colors.amberAccent
        : AppTheme.neonCyan;
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '${status.label}: ${status.status}',
        style: AppTheme.bodyTextStyle(fontSize: 11, color: color, isBold: true),
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
