import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class MissingScrappyDialog extends StatefulWidget {
  const MissingScrappyDialog({
    super.key,
    required this.item,
    required this.currentState,
    required this.repository,
    required this.tierColor,
  });

  final ArcScrappyItem item;
  final ArcScrappyState currentState;
  final ArcScrappyRepository repository;
  final Color tierColor;

  @override
  State<MissingScrappyDialog> createState() => _MissingScrappyDialogState();
}

class _MissingScrappyDialogState extends State<MissingScrappyDialog> {
  late TextEditingController _collectedController;
  bool _saving = false;

  int get _collected => int.tryParse(_collectedController.text.trim()) ?? 0;

  int get _neededRemaining {
    final remaining = widget.item.neededCount - _collected;
    return remaining < 0 ? 0 : remaining;
  }

  int get _surplus {
    final extra = _collected - widget.item.neededCount;
    return extra > 0 ? extra : 0;
  }

  @override
  void initState() {
    super.initState();
    _collectedController = TextEditingController(
      text: widget.currentState.collectedCount.toString(),
    );
  }

  @override
  void dispose() {
    _collectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.neonPink.withValues(alpha: 0.28)),
      ),
      title: Text(
        widget.item.name,
        style: AppTheme.tradingHeading(fontSize: 24, color: widget.tierColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.item.category} • ${widget.item.group} • ${widget.item.tierLabel}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _collectedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.tradingInputDecoration(
                label: 'Collected Amount',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            Text(
              'Total Needed: ${widget.item.neededCount}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Still Needed: $_neededRemaining',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
            Text(
              'Surplus (Tradeable): $_surplus',
              style: const TextStyle(color: Colors.lightGreenAccent),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await widget.repository.saveScrappyState(
        widget.currentState.copyWith(
          collectedCount: _collected,
          updatedAt: DateTime.now(),
        ),
        neededCount: widget.item.neededCount,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save scrappy item.')),
      );
    }
  }
}
