import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
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
          'Raider Reports & Contracts',
          style: AppTheme.tradingHeading(fontSize: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review private reports and structured incident intelligence before any requested contract becomes live.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ArcRaiderReport>>(
          stream: repo.watchModerationReports(),
          builder: (c, s) => Column(
            children: (s.data ?? const <ArcRaiderReport>[])
                .map(
                  (r) => Card(
                    child: ExpansionTile(
                      title: Text(r.targetDisplayName),
                      subtitle: Text(
                        '${r.category.name} • ${r.mapDisplayName} • ${r.serverRegion}',
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
                            'Location: ${r.locationLabel}\n'
                            'Coordinates: ${r.locationX?.toStringAsFixed(4)}, ${r.locationY?.toStringAsFixed(4)}\n'
                            'Extraction: ${r.atExtraction ? r.extractionName : 'No'}\n'
                            'Behaviour: ${r.rattingSubtype}\n'
                            'Incident: ${r.incidentAt}\n'
                            'Repeat: ${r.repeatBehaviour.name} × ${r.repeatCount}\n'
                            'Reporter reputation snapshot: ${r.reporterReputationSnapshot}\n'
                            'Contract requested: ${r.requestContract ? 'Yes' : 'No'}\n'
                            'Reward: ${r.rewardItems.map((e) => '${e.quantity}× ${e.name}').join(' • ')}',
                          ),
                        ),
                        if (r.evidence.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Evidence: ${r.evidence.map((e) => e.url).join('\n')}',
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
                              onPressed: () => _moderate(c, repo, r, false),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _moderate(c, repo, r, true),
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
          builder: (c, s) => Column(
            children: (s.data ?? const <ArcRaiderContract>[])
                .map(
                  (x) => Card(
                    child: ExpansionTile(
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
                              onPressed: () => repo.resolveContract(
                                x.id,
                                completed: false,
                                resolution:
                                    'Moderator rejected submitted evidence.',
                              ),
                              child: const Text('Reject evidence'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => repo.resolveContract(
                                x.id,
                                completed: true,
                                resolution:
                                    'Moderator approved submitted evidence.',
                              ),
                              child: const Text('Complete contract'),
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

  Future<void> _moderate(
    BuildContext context,
    ArcRaiderContractsRepository repo,
    ArcRaiderReport report,
    bool approve,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(approve ? 'Approve report' : 'Reject report'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Moderation notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await repo.moderateReport(
                report.id,
                approve: approve,
                notes: controller.text,
              );
              if (d.mounted) Navigator.pop(d);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}
