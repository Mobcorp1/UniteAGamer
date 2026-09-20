import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import '../models/arc_contract_projections.dart';
import '../repositories/arc_raider_contracts_repository.dart';

class ArcContractDiscovery extends StatefulWidget {
  const ArcContractDiscovery({
    super.key,
    required this.load,
    required this.accept,
  });
  final Future<List<ArcContractDiscoveryItem>> Function(String search) load;
  final Future<void> Function(String id) accept;
  @override
  State<ArcContractDiscovery> createState() => _ArcContractDiscoveryState();
}

class _ArcContractDiscoveryState extends State<ArcContractDiscovery> {
  final search = TextEditingController();
  List<ArcContractDiscoveryItem>? items;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = await widget.load(search.text.trim());
      if (mounted) setState(() => items = next);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Contracts unavailable. Retry to refresh.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> accept(String id) async {
    setState(() => loading = true);
    try {
      await widget.accept(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contract accepted. Continue in Activity → Your hunts.',
          ),
        ),
      );
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Could not accept this Contract. Refresh and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: ArcUiTokens.panelPadding,
    children: [
      Text(
        'CONTRACT OPERATIONS',
        style: ArcUiTokens.sectionTitle(fontSize: 20),
      ),
      const Text('Verified incidents • eligible assignments'),
      const SizedBox(height: 12),
      TextField(
        controller: search,
        onSubmitted: (_) {
          if (!loading) refresh();
        },
        decoration: ArcUiTokens.inputDecoration(labelText: 'Search Raider'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: loading ? null : refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh contracts'),
        ),
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(error!, style: TextStyle(color: ArcUiTokens.warning)),
        ),
      if (!loading && error == null && items?.isEmpty == true)
        const Text('No eligible Contracts match this search.'),
      if (error != null && items?.isNotEmpty == true)
        const Text('Showing the last loaded Contracts.'),
      for (final item in items ?? <ArcContractDiscoveryItem>[])
        Card(
          color: ArcUiTokens.surfaceRaised,
          child: Padding(
            padding: ArcUiTokens.panelPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.targetDisplayName,
                  style: ArcUiTokens.sectionTitle(fontSize: 20),
                ),
                Text(
                  '${item.category.toUpperCase()} • AVAILABLE • ${item.evidenceState}',
                ),
                const SizedBox(height: 12),
                Text(item.rewardSummary),
                Text(
                  'MAP AFFINITY: ${item.mapAffinity.replaceAll('_', ' ').toUpperCase()}',
                ),
                Text('REGION MATCH: ${item.regionMatch}'),
                Text('INTELLIGENCE CONFIDENCE: ${item.confidence}'),
                const Text('TARGET ACTIVITY: UNKNOWN'),
                if (item.confidence == 'LOW')
                  const Text(
                    'Not enough recent verified incident context for intelligence.',
                  ),
                const Text(
                  'Incident context is not live location or presence.',
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: loading ? null : () => accept(item.id),
                  child: const Text('Accept Contract'),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class ArcContractAccountStatus extends StatefulWidget {
  const ArcContractAccountStatus({
    super.key,
    required this.load,
    required this.challenge,
  });
  final Future<List<ArcContractAccountCase>> Function() load;
  final Future<void> Function(String, String) challenge;
  @override
  State<ArcContractAccountStatus> createState() =>
      _ArcContractAccountStatusState();
}

class _ArcContractAccountStatusState extends State<ArcContractAccountStatus> {
  List<ArcContractAccountCase>? cases;
  bool loading = false;
  String? error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = await widget.load();
      if (mounted) setState(() => cases = next);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Account cases unavailable. Retry to refresh.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> challenge(ArcContractAccountCase item) async {
    final reason = await arcContractReason(
      context,
      'Challenge this case',
      'Explain why this case should be reviewed',
    );
    if (reason == null || !mounted) return;
    setState(() => loading = true);
    try {
      await widget.challenge(item.id, reason);
      if (mounted) await refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error =
              'Challenge could not be submitted. Use 10–1000 characters and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('YOUR ACCOUNT CASES', style: ArcUiTokens.sectionTitle(fontSize: 20)),
      const Text(
        'Your case status and a moderator challenge are available to every account.',
      ),
      TextButton(
        onPressed: loading ? null : refresh,
        child: const Text('Refresh account status'),
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null) Text(error!),
      if (!loading && error == null && cases?.isEmpty == true)
        const Text('No account cases.'),
      for (final item in cases ?? <ArcContractAccountCase>[])
        Card(
          child: ListTile(
            title: Text(
              '${item.category.toUpperCase()} • ${item.status.toUpperCase()}',
            ),
            subtitle: Text(
              'Evidence: ${item.evidenceState}\nChallenge: ${item.challengeStatus}',
            ),
            trailing: item.canChallenge
                ? TextButton(
                    onPressed: loading ? null : () => challenge(item),
                    child: const Text('Challenge'),
                  )
                : null,
          ),
        ),
    ],
  );
}

Future<String?> arcContractReason(
  BuildContext context,
  String title,
  String label,
) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLength: 1000,
        maxLines: 4,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  // The dialog route retains its controller until its exit animation completes.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return result;
}

Future<void> arcAttachReportClip(
  BuildContext context,
  ArcRaiderContractsRepository repo,
  String reportId,
) async {
  try {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await repo.attachReportEvidence(reportId, file);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clip submitted for independent review.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Clip could not be submitted. Choose an MP4 up to 25 MB and retry.',
          ),
        ),
      );
    }
  }
}
