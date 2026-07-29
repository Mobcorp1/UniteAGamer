import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/release/models/uag_release_runtime_diagnostics.dart';
import 'package:uag_arc_raiders_hub/features/release/models/uag_release_readiness_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagReleaseReadinessPanel extends StatelessWidget {
  const UagReleaseReadinessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('release_readiness')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final readiness = UagReleaseReadinessSnapshot.fromMap(data);
        return Container(
          padding: AppTheme.sectionCardPadding,
          decoration: AppTheme.tradingCardDecoration(
            borderColor: readiness.blockerCount > 0
                ? AppTheme.tradingDanger.withValues(alpha: 0.42)
                : AppTheme.neonCyan.withValues(alpha: 0.32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    readiness.blockerCount > 0
                        ? Icons.warning_amber_rounded
                        : Icons.verified_outlined,
                    color: readiness.blockerCount > 0
                        ? AppTheme.tradingDanger
                        : AppTheme.neonCyan,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Release Readiness',
                          style: AppTheme.tradingHeading(
                            fontSize: 22,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          readiness.canCallClosedBetaReady
                              ? 'Repository checks are release-candidate shaped. Remaining items are configuration or device QA.'
                              : 'Release blockers remain. Do not call this production-ready until the blocked rows are cleared.',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 14,
                            color: AppTheme.tradingMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  _MetricPill('Ready', readiness.readyCount.toString()),
                  _MetricPill(
                    'Config',
                    readiness.configurationRequiredCount.toString(),
                  ),
                  _MetricPill('Manual QA', readiness.manualQaCount.toString()),
                  _MetricPill('Blocked', readiness.blockerCount.toString()),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return Wrap(
                    spacing: AppTheme.spaceM,
                    runSpacing: AppTheme.spaceM,
                    children: readiness.checks
                        .map(
                          (check) => SizedBox(
                            width: wide
                                ? (constraints.maxWidth - AppTheme.spaceM) / 2
                                : constraints.maxWidth,
                            child: _ReadinessCheckTile(check: check),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
              const _ReleaseRuntimeDiagnosticsCard(),
            ],
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.24)),
        color: Colors.black.withValues(alpha: 0.26),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

class _ReleaseRuntimeDiagnosticsCard extends StatelessWidget {
  const _ReleaseRuntimeDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UagReleaseRuntimeDiagnosticsSnapshot>(
      future: UagReleaseRuntimeDiagnosticsSnapshot.load(),
      builder: (context, snapshot) {
        final diagnostics = snapshot.data;
        if (diagnostics == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.20),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Loading runtime diagnostics...',
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: AppTheme.tradingMutedText,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.20),
            border: Border.all(
              color: diagnostics.hasBlocked
                  ? AppTheme.tradingDanger.withValues(alpha: 0.34)
                  : AppTheme.neonCyan.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    diagnostics.hasBlocked
                        ? Icons.report_problem_outlined
                        : Icons.query_stats_rounded,
                    color: diagnostics.hasBlocked
                        ? AppTheme.tradingDanger
                        : AppTheme.neonCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Runtime Diagnostics',
                      style: AppTheme.tradingHeading(fontSize: 16),
                    ),
                  ),
                  Text(
                    diagnostics.generatedAt.toLocal().toString(),
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return Wrap(
                    spacing: AppTheme.spaceS,
                    runSpacing: AppTheme.spaceS,
                    children: diagnostics.entries
                        .map(
                          (entry) => SizedBox(
                            width: wide
                                ? (constraints.maxWidth - AppTheme.spaceS) / 2
                                : constraints.maxWidth,
                            child: _ReleaseDiagnosticTile(entry: entry),
                          ),
                        )
                        .toList(growable: false),
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

class _ReleaseDiagnosticTile extends StatelessWidget {
  const _ReleaseDiagnosticTile({required this.entry});

  final UagReleaseDiagnosticEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(entry.level);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_levelIcon(entry.level), color: color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white),
          ),
          if (entry.detail.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _levelColor(UagReleaseDiagnosticLevel level) {
    switch (level) {
      case UagReleaseDiagnosticLevel.ready:
        return AppTheme.neonCyan;
      case UagReleaseDiagnosticLevel.warning:
        return AppTheme.warningAmber;
      case UagReleaseDiagnosticLevel.blocked:
        return AppTheme.tradingDanger;
      case UagReleaseDiagnosticLevel.info:
        return Colors.white54;
    }
  }

  IconData _levelIcon(UagReleaseDiagnosticLevel level) {
    switch (level) {
      case UagReleaseDiagnosticLevel.ready:
        return Icons.check_circle_outline_rounded;
      case UagReleaseDiagnosticLevel.warning:
        return Icons.info_outline_rounded;
      case UagReleaseDiagnosticLevel.blocked:
        return Icons.error_outline_rounded;
      case UagReleaseDiagnosticLevel.info:
        return Icons.circle_outlined;
    }
  }
}

class _ReadinessCheckTile extends StatelessWidget {
  const _ReadinessCheckTile({required this.check});

  final UagReleaseReadinessCheck check;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(check.state);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_stateIcon(check.state), color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  check.label,
                  style: AppTheme.tradingHeading(fontSize: 15),
                ),
              ),
              Text(
                check.state.label,
                style: AppTheme.bodyTextStyle(fontSize: 11, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            check.detail,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.tradingMutedText,
            ),
          ),
          if (check.owner.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Owner: ${check.owner}',
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _stateColor(UagReleaseReadinessState state) {
    switch (state) {
      case UagReleaseReadinessState.ready:
        return AppTheme.neonCyan;
      case UagReleaseReadinessState.configurationRequired:
        return AppTheme.warningAmber;
      case UagReleaseReadinessState.manualQaRequired:
        return AppTheme.neonPink;
      case UagReleaseReadinessState.blocked:
        return AppTheme.tradingDanger;
      case UagReleaseReadinessState.unknown:
        return Colors.white54;
    }
  }

  IconData _stateIcon(UagReleaseReadinessState state) {
    switch (state) {
      case UagReleaseReadinessState.ready:
        return Icons.check_circle_outline_rounded;
      case UagReleaseReadinessState.configurationRequired:
        return Icons.settings_suggest_outlined;
      case UagReleaseReadinessState.manualQaRequired:
        return Icons.fact_check_outlined;
      case UagReleaseReadinessState.blocked:
        return Icons.report_problem_outlined;
      case UagReleaseReadinessState.unknown:
        return Icons.help_outline_rounded;
    }
  }
}
