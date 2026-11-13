import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_application_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_creator_front_door_repository.dart';

class UagCreatorApplicationAdminPanel extends StatefulWidget {
  const UagCreatorApplicationAdminPanel({super.key});

  @override
  State<UagCreatorApplicationAdminPanel> createState() =>
      _UagCreatorApplicationAdminPanelState();
}

class _UagCreatorApplicationAdminPanelState
    extends State<UagCreatorApplicationAdminPanel> {
  final _repository = UagCreatorFrontDoorRepository();
  String? _busyId;

  Future<void> _approve(UagCreatorProgrammeApplication application) async {
    final policy = const UagCreatorApplicationPolicy();
    final creatorIdController = TextEditingController(
      text: policy.creatorIdFor(
        uid: application.uid,
        displayName: application.displayName,
      ),
    );
    final codeController = TextEditingController(
      text: policy.defaultCodeFor(application.displayName),
    );

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Creator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(application.displayName),
            const SizedBox(height: 12),
            TextField(
              controller: creatorIdController,
              decoration: const InputDecoration(labelText: 'Creator ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Primary code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );

    if (approved != true) {
      creatorIdController.dispose();
      codeController.dispose();
      return;
    }

    setState(() => _busyId = application.id);
    try {
      final result = await _repository.approveApplication(
        application: application,
        creatorId: creatorIdController.text,
        primaryCode: codeController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approved ${application.displayName}: ${result.creatorId} / ${result.primaryCode}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update creator application. Try again.'),
        ),
      );
    } finally {
      creatorIdController.dispose();
      codeController.dispose();
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _reject(UagCreatorProgrammeApplication application) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Creator Application'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Decision reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) {
      return;
    }

    setState(() => _busyId = application.id);
    try {
      await _repository.rejectApplication(
        application: application,
        reason: reason,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update creator application. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<UagCreatorProgrammeApplication>>(
          stream: _repository.watchApplicationsForAdmin(),
          builder: (context, snapshot) {
            final applications =
                snapshot.data ?? const <UagCreatorProgrammeApplication>[];
            final pending = applications
                .where(
                  (application) =>
                      application.status == UagCreatorApplicationStatus.pending,
                )
                .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CREATOR APPLICATION CONTROL',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${pending.length} application(s) awaiting review'),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  const Text('No pending Creator Programme applications.')
                else
                  for (final application in pending)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              application.displayName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(application.platforms.join(' • ')),
                            if (application.socialHandles.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                application.socialHandles.entries
                                    .map(
                                      (entry) => '${entry.key}: ${entry.value}',
                                    )
                                    .join(' • '),
                              ),
                            ],
                            if (application.audienceSize != null) ...[
                              const SizedBox(height: 4),
                              Text('Audience: ${application.audienceSize}'),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busyId == null
                                        ? () => _reject(application)
                                        : null,
                                    child: const Text('REJECT'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _busyId == null
                                        ? () => _approve(application)
                                        : null,
                                    child: Text(
                                      _busyId == application.id
                                          ? 'WORKING...'
                                          : 'APPROVE',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
