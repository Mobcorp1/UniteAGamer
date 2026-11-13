import 'package:url_launcher/url_launcher.dart';
import 'arc_contract_discovery.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import '../models/arc_raider_contract_models.dart';
import '../repositories/arc_raider_contracts_repository.dart';

class ArcRaiderContractsAdminPanel extends StatelessWidget {
  const ArcRaiderContractsAdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ArcRaiderContractsRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rat Reports & Contracts',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.admin,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review private reports and structured incident intelligence before any requested contract becomes live.',
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: repo.watchChallenges(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Challenges unavailable. Reopen to retry.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return Column(
              children: [
                const Text('ACCOUNT CHALLENGES'),
                if (snapshot.requireData.isEmpty)
                  const Text('No pending challenges.'),
                for (final item in snapshot.requireData)
                  Card(
                    child: ListTile(
                      title: Text('Case ${item['contractId']}'),
                      subtitle: Text('${item['reason']}'),
                      trailing: Wrap(
                        children: [
                          for (final overturn in [false, true])
                            TextButton(
                              onPressed: () async {
                                final notes = await arcContractReason(
                                  context,
                                  overturn ? 'Overturn case' : 'Uphold case',
                                  'Independent review notes',
                                );
                                if (notes == null) return;
                                try {
                                  await repo.reviewChallenge(
                                    item['contractId'] as String,
                                    overturn,
                                    notes,
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Challenge review could not be saved. Retry.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(overturn ? 'Overturn' : 'Uphold'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ArcRaiderReport>>(
          stream: repo.watchModerationReports(),
          builder: (c, s) => s.hasError
              ? const Text('Review queue unavailable. Reopen to retry.')
              : !s.hasData
              ? const LinearProgressIndicator()
              : Column(
                  children: (s.data ?? const <ArcRaiderReport>[])
                      .map(
                        (r) => _reviewCard(
                          accent: ArcUiTokens.admin,
                          child: ExpansionTile(
                            iconColor: ArcUiTokens.admin,
                            collapsedIconColor: ArcUiTokens.textTertiary,
                            title: Text(r.targetDisplayName),
                            subtitle: Text(
                              '${r.category.name} - ${r.mapDisplayName} - ${r.serverRegion}',
                            ),
                            childrenPadding: const EdgeInsets.all(14),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(r.description),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Target account: ${r.targetUid.isEmpty ? 'Canonical account binding required' : r.targetUid}\n'
                                  'Report reference: ${r.id}\n'
                                  'Location: ${r.locationLabel}\n'
                                  'Coordinates: ${r.locationX?.toStringAsFixed(4)}, ${r.locationY?.toStringAsFixed(4)}\n'
                                  'Extraction: ${r.atExtraction ? r.extractionName : 'No'}\n'
                                  'Behaviour: ${r.rattingSubtype}\n'
                                  'Incident: ${r.incidentAt}\n'
                                  'Repeat: ${r.repeatBehaviour.name} x ${r.repeatCount}\n'
                                  'Reporter reputation snapshot: ${r.reporterReputationSnapshot}\n'
                                  'Contract requested: ${r.requestContract ? 'Yes' : 'No'}\n'
                                  'Reward: ${r.rewardItems.map((e) => '${e.quantity}x ${e.name}').join(' - ')}',
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    final data = await repo.adminContext(r.id);
                                    if (!c.mounted) return;
                                    await showDialog<void>(
                                      context: c,
                                      builder: (d) => AlertDialog(
                                        title: const Text(
                                          'Incident review trail',
                                        ),
                                        content: SingleChildScrollView(
                                          child: Text(
                                            'Source: ${data['source']}\nTrade: ${data['sourceSessionId']}\n'
                                            'Verification: ${data['incidentVerification']}\nContract: ${data['contractStatus']}\n'
                                            'Coarse intelligence: ${data['intelligence']}\nHistory: ${data['history']}',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(d),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (_) {
                                    if (c.mounted) {
                                      ScaffoldMessenger.of(c).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Review trail unavailable. Retry.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  'Review trail & intelligence',
                                ),
                              ),
                              for (final evidence in r.evidence)
                                TextButton.icon(
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('Review incident clip'),
                                  onPressed: () async {
                                    try {
                                      final url = await repo.reportEvidenceUrl(
                                        evidence,
                                      );
                                      if (!await launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
                                      )) {
                                        throw StateError('Clip unavailable');
                                      }
                                    } catch (_) {
                                      if (c.mounted) {
                                        ScaffoldMessenger.of(c).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Evidence unavailable. Do not approve until it can be reviewed.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              if (r.evidence.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Evidence: ${r.evidence.map((e) => e.storagePath).join('\n')}',
                                  ),
                                ),
                              ],
                              if (r.socialContentUrl.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Social: ${r.socialContentUrl}'),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: ArcUiTokens.textButtonStyle(
                                      accent: ArcUiTokens.danger,
                                    ),
                                    onPressed: () =>
                                        _moderate(c, repo, r, false),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: ArcUiTokens.textButtonStyle(
                                      accent: ArcUiTokens.success,
                                      primary: true,
                                    ),
                                    onPressed: () =>
                                        _moderate(c, repo, r, true),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ArcRaiderContract>>(
          stream: repo.watchDisputedContracts(),
          builder: (c, s) => s.hasError
              ? const Text('Review queue unavailable. Reopen to retry.')
              : !s.hasData
              ? const LinearProgressIndicator()
              : Column(
                  children: (s.data ?? const <ArcRaiderContract>[])
                      .map(
                        (x) => _reviewCard(
                          accent: ArcUiTokens.warning,
                          child: ExpansionTile(
                            iconColor: ArcUiTokens.warning,
                            collapsedIconColor: ArcUiTokens.textTertiary,
                            title: Text('DISPUTE: ${x.targetDisplayName}'),
                            subtitle: Text(x.rewardSummary),
                            childrenPadding: const EdgeInsets.all(14),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(x.resolution),
                              ),
                              if (x.evidence.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Evidence: ${x.evidence.map((e) => e.url).join('\n')}',
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: ArcUiTokens.textButtonStyle(
                                      accent: ArcUiTokens.danger,
                                    ),
                                    onPressed: () => repo.resolveContract(
                                      x.id,
                                      completed: false,
                                      resolution:
                                          'Moderator rejected submitted evidence.',
                                    ),
                                    child: const Text('Reject evidence'),
                                  ),
                                  const Flexible(
                                    child: Text(
                                      'Completion requires issuer video review.',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _reviewCard({required Widget child, required Color accent}) {
    return Card(
      color: ArcUiTokens.surfaceRaised.withValues(alpha: 0.88),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        side: BorderSide(color: accent.withValues(alpha: 0.20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Future<void> _moderate(
    BuildContext context,
    ArcRaiderContractsRepository repo,
    ArcRaiderReport report,
    bool approve,
  ) async {
    final controller = TextEditingController();
    final target = TextEditingController(text: report.targetUid);
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: (approve ? ArcUiTokens.success : ArcUiTokens.danger)
                .withValues(alpha: 0.28),
          ),
        ),
        title: Text(
          approve ? 'Approve report' : 'Reject report',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: approve ? ArcUiTokens.success : ArcUiTokens.danger,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (approve)
              TextField(
                controller: target,
                readOnly: report.targetUid.isNotEmpty,
                decoration: const InputDecoration(
                  labelText: 'Verified UAG target account ID',
                ),
              ),
            if (approve)
              const Text(
                'Confirm the clip proves the incident and identifies this account. Activation is blocked without a stored video.',
              ),
            TextField(
              controller: controller,
              maxLines: 3,
              style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
              decoration: ArcUiTokens.inputDecoration(
                labelText: 'Moderation notes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: approve ? ArcUiTokens.success : ArcUiTokens.danger,
            ),
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: approve ? ArcUiTokens.success : ArcUiTokens.danger,
              primary: true,
            ),
            onPressed: () async {
              try {
                await repo.moderateReport(
                  report.id,
                  approve: approve,
                  notes: controller.text,
                  targetUid: target.text.trim(),
                );
                if (d.mounted) Navigator.pop(d);
              } catch (_) {
                if (d.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Review not saved. Check the canonical account, video evidence and review notes.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    target.dispose();
  }
}
