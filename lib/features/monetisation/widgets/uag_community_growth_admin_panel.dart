import 'package:flutter/material.dart';

import '../repositories/uag_community_growth_repository.dart';

class UagCommunityGrowthAdminPanel extends StatefulWidget {
  const UagCommunityGrowthAdminPanel({super.key});

  @override
  State<UagCommunityGrowthAdminPanel> createState() =>
      _UagCommunityGrowthAdminPanelState();
}

class _UagCommunityGrowthAdminPanelState
    extends State<UagCommunityGrowthAdminPanel> {
  final _controller = TextEditingController();
  final _repository = UagCommunityGrowthRepository();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'COMMUNITY GROWTH CONTROL',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Temporary admin-authoritative bridge until the qualified-active-user aggregate is produced server-side.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Qualified active users',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final value = int.tryParse(_controller.text.trim());
                      if (value == null || value < 0) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid user count.'),
                          ),
                        );
                        return;
                      }
                      setState(() => _busy = true);
                      try {
                        await _repository.adminSetQualifiedActiveUsers(value);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Community growth updated.'),
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Community growth could not be updated.',
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(_busy ? 'UPDATING...' : 'UPDATE'),
            ),
          ],
        ),
      ),
    );
  }
}
