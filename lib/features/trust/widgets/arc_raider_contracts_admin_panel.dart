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
          'Review private reports before any contract becomes live. Resolve disputed completion from evidence.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ArcRaiderReport>>(
          stream: repo.watchModerationReports(),
          builder: (c, s) => Column(
            children: (s.data ?? [])
                .map(
                  (r) => Card(
                    child: ListTile(
                      title: Text(r.targetDisplayName),
                      subtitle: Text('${r.category.name}\n${r.description}'),
                      isThreeLine: true,
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Approve',
                            icon: const Icon(
                              Icons.check,
                              color: Colors.greenAccent,
                            ),
                            onPressed: () => _moderate(c, repo, r, true),
                          ),
                          IconButton(
                            tooltip: 'Reject',
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _moderate(c, repo, r, false),
                          ),
                        ],
                      ),
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
            children: (s.data ?? [])
                .map(
                  (x) => Card(
                    child: ListTile(
                      title: Text('DISPUTE: ${x.targetDisplayName}'),
                      subtitle: Text(x.resolution),
                      trailing: Wrap(
                        children: [
                          TextButton(
                            onPressed: () => repo.resolveContract(
                              x.id,
                              completed: true,
                              resolution:
                                  'Moderator approved submitted evidence.',
                            ),
                            child: const Text('Complete'),
                          ),
                          TextButton(
                            onPressed: () => repo.resolveContract(
                              x.id,
                              completed: false,
                              resolution:
                                  'Moderator rejected submitted evidence.',
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
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
    ArcRaiderReport r,
    bool approve,
  ) async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(approve ? 'Approve report' : 'Reject report'),
        content: TextField(
          controller: c,
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
              await repo.moderateReport(r.id, approve: approve, notes: c.text);
              if (d.mounted) Navigator.pop(d);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    c.dispose();
  }
}
