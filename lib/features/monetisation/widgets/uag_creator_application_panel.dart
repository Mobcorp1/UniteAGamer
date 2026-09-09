import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_application_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_creator_front_door_repository.dart';

class UagCreatorApplicationPanel extends StatefulWidget {
  const UagCreatorApplicationPanel({super.key});

  @override
  State<UagCreatorApplicationPanel> createState() =>
      _UagCreatorApplicationPanelState();
}

class _UagCreatorApplicationPanelState
    extends State<UagCreatorApplicationPanel> {
  final _repository = UagCreatorFrontDoorRepository();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _audienceController = TextEditingController();
  final Set<String> _platforms = <String>{};
  bool _termsAccepted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final handle = _handleController.text.trim();
      final audience = int.tryParse(_audienceController.text.trim());
      final handles = <String, String>{
        for (final platform in _platforms)
          if (handle.isNotEmpty) platform: handle,
      };
      await _repository.submitApplication(
        displayName: _nameController.text,
        platforms: _platforms.toList(growable: false),
        socialHandles: handles,
        termsAccepted: _termsAccepted,
        audienceSize: audience,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creator application submitted for review.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit creator application. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagCreatorProgrammeApplication?>(
      stream: _repository.watchMyApplication(),
      builder: (context, snapshot) {
        final application = snapshot.data;
        if (application != null) {
          return _ExistingApplicationCard(application: application);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'JOIN THE UAG CREATOR PROGRAMME',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apply to unlock tracked referrals, Creator Points, recurring commission eligibility and Community Arsenal rewards.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Creator / channel name',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final platform
                        in UagCreatorApplicationPolicy.supportedPlatforms)
                      FilterChip(
                        label: Text(platform),
                        selected: _platforms.contains(platform),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _platforms.add(platform);
                            } else {
                              _platforms.remove(platform);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _handleController,
                  decoration: const InputDecoration(
                    labelText: 'Primary social handle / channel',
                    hintText: '@yourhandle',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _audienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Approx. audience size (optional)',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _termsAccepted,
                  onChanged: (value) =>
                      setState(() => _termsAccepted = value ?? false),
                  title: const Text(
                    'I agree to the UAG Creator Programme terms and understand rewards and commission require validation.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting
                        ? 'SUBMITTING...'
                        : 'APPLY TO CREATOR PROGRAMME',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExistingApplicationCard extends StatelessWidget {
  const _ExistingApplicationCard({required this.application});

  final UagCreatorProgrammeApplication application;

  @override
  Widget build(BuildContext context) {
    final approved = application.status == UagCreatorApplicationStatus.approved;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approved ? 'CREATOR PROGRAMME ACTIVE' : 'CREATOR APPLICATION',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(application.status.label),
            if (application.creatorId.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              SelectableText('Creator ID: ${application.creatorId}'),
            ],
            const SizedBox(height: 6),
            Text(application.displayName),
          ],
        ),
      ),
    );
  }
}
