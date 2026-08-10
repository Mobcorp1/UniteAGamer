import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_raider_contract_models.dart';
import '../repositories/arc_raider_contracts_repository.dart';

class ArcRaiderContractsScreen extends StatefulWidget {
  const ArcRaiderContractsScreen({super.key});

  static const routeName = '/raider-contracts';

  @override
  State<ArcRaiderContractsScreen> createState() => _State();
}

class _State extends State<ArcRaiderContractsScreen>
    with SingleTickerProviderStateMixin {
  final repo = ArcRaiderContractsRepository();
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Report a Raider',
        subtitle: 'Moderated community reports and Raider Contracts.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Column(
              children: [
                TabBar(
                  controller: tabs,
                  tabs: const [
                    Tab(text: 'REPORT'),
                    Tab(text: 'LIVE CONTRACTS'),
                    Tab(text: 'MY ACTIVITY'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabs,
                    children: [
                      _ReportForm(repo: repo),
                      _Contracts(repo: repo, live: true),
                      _MyActivity(repo: repo),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.repo});

  final ArcRaiderContractsRepository repo;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final target = TextEditingController();
  final identity = TextEditingController();
  final details = TextEditingController();
  final encounterContextController = TextEditingController();
  final map = TextEditingController();
  final event = TextEditingController();
  final social = TextEditingController();
  final evidence = TextEditingController();

  ArcRaiderReportCategory category = ArcRaiderReportCategory.other;
  bool busy = false;

  Iterable<TextEditingController> get _controllers => [
    target,
    identity,
    details,
    encounterContextController,
    map,
    event,
    social,
    evidence,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      final evidenceItems = evidence.text.trim().isEmpty
          ? const <ArcRaiderEvidence>[]
          : [
              ArcRaiderEvidence(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                submittedByUid: widget.repo.uid,
                kind: 'link',
                url: evidence.text.trim(),
                caption: 'Reporter evidence',
                createdAt: DateTime.now(),
              ),
            ];

      await widget.repo.createReport(
        targetDisplayName: target.text,
        targetGameIdentity: identity.text,
        category: category,
        description: details.text,
        encounterContext: encounterContextController.text,
        mapId: map.text,
        eventContext: event.text,
        socialContentUrl: social.text,
        evidence: evidenceItems,
      );

      if (!mounted) {
        return;
      }

      for (final controller in _controllers) {
        controller.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted for moderator review.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppTheme.pagePadding,
      children: [
        _notice(
          'Reports are private until reviewed. Approval may create a Raider Contract; it never auto-publishes an accusation.',
        ),
        _field(target, 'Target Raider display name *'),
        _field(identity, 'Game identity / platform ID'),
        DropdownButtonFormField<ArcRaiderReportCategory>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Reason'),
          items: ArcRaiderReportCategory.values
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => category = value ?? category);
          },
        ),
        _field(details, 'What happened? *', lines: 5),
        _field(encounterContextController, 'Encounter context', lines: 2),
        _field(map, 'Map'),
        _field(event, 'Event / activity'),
        _field(evidence, 'Evidence URL (screenshot, clip or document)'),
        _field(social, 'Optional TikTok/social post URL'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : submit,
          icon: const Icon(Icons.gavel),
          label: Text(busy ? 'Submitting…' : 'Submit for review'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

Widget _field(TextEditingController controller, String label, {int lines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget _notice(String text) {
  return Container(
    padding: AppTheme.sectionCardPadding,
    decoration: AppTheme.tradingCardDecoration(
      borderColor: AppTheme.neonCyan.withValues(alpha: .3),
    ),
    child: Text(
      text,
      style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
    ),
  );
}

class _Contracts extends StatelessWidget {
  const _Contracts({required this.repo, required this.live});

  final ArcRaiderContractsRepository repo;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArcRaiderContract>>(
      stream: live ? repo.watchLiveContracts() : repo.watchMyContracts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load contracts: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No Raider Contracts here yet.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView(
          padding: AppTheme.pagePadding,
          children: items
              .map(
                (contract) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.targetDisplayName,
                          style: AppTheme.tradingHeading(fontSize: 22),
                        ),
                        Text(
                          contract.status.name,
                          style: const TextStyle(color: AppTheme.neonCyan),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contract.evidenceRequirements,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        if (live)
                          FilledButton(
                            onPressed: () => repo.acceptContract(contract.id),
                            child: const Text('Accept contract'),
                          )
                        else ...[
                          if (contract.status ==
                              ArcRaiderContractStatus.accepted)
                            FilledButton(
                              onPressed: () => repo.startContract(contract.id),
                              child: const Text('Start hunt'),
                            ),
                          if (contract.status ==
                              ArcRaiderContractStatus.inProgress)
                            OutlinedButton(
                              onPressed: () =>
                                  _evidenceDialog(context, repo, contract),
                              child: const Text('Submit evidence'),
                            ),
                          if (contract.status ==
                              ArcRaiderContractStatus.evidenceSubmitted)
                            OutlinedButton(
                              onPressed: () => repo.disputeContract(
                                contract.id,
                                'Hunter requested moderator review.',
                              ),
                              child: const Text('Request review'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

Future<void> _evidenceDialog(
  BuildContext context,
  ArcRaiderContractsRepository repo,
  ArcRaiderContract contract,
) async {
  final url = TextEditingController();
  final social = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Submit contract evidence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Evidence URL *'),
          ),
          TextField(
            controller: social,
            decoration: const InputDecoration(
              labelText: 'Optional TikTok/social URL',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final evidenceUrl = url.text.trim();
            if (evidenceUrl.isEmpty) {
              return;
            }

            await repo.submitEvidence(
              contract.id,
              evidence: [
                ArcRaiderEvidence(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  submittedByUid: repo.uid,
                  kind: 'link',
                  url: evidenceUrl,
                  caption: 'Contract completion evidence',
                  createdAt: DateTime.now(),
                ),
              ],
              socialContentUrl: social.text,
            );

            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );

  url.dispose();
  social.dispose();
}

class _MyActivity extends StatelessWidget {
  const _MyActivity({required this.repo});

  final ArcRaiderContractsRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppTheme.pagePadding,
      children: [
        Text('MY REPORTS', style: AppTheme.tradingHeading(fontSize: 20)),
        StreamBuilder<List<ArcRaiderReport>>(
          stream: repo.watchMyReports(),
          builder: (context, snapshot) {
            final reports = snapshot.data ?? const <ArcRaiderReport>[];
            return Column(
              children: reports
                  .map(
                    (report) => ListTile(
                      title: Text(report.targetDisplayName),
                      subtitle: Text(
                        '${report.category.name} • ${report.status.name}',
                      ),
                      trailing: report.canWithdraw
                          ? TextButton(
                              onPressed: () => repo.withdrawReport(report.id),
                              child: const Text('Withdraw'),
                            )
                          : null,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const Divider(),
        Text('MY CONTRACTS', style: AppTheme.tradingHeading(fontSize: 20)),
        SizedBox(height: 500, child: _Contracts(repo: repo, live: false)),
      ],
    );
  }
}
