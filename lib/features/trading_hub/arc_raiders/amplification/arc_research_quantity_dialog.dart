import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// Keep the controller alive for the entire dialog route, including its exit
/// animation. Disposing a controller immediately after Navigator.pop can
/// invalidate TextField's inherited dependencies while the route is mounted.
class ArcResearchQuantityDialog extends StatefulWidget {
  const ArcResearchQuantityDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.maxValue = 999999,
  });

  final String title;
  final int initialValue;
  final int maxValue;

  @override
  State<ArcResearchQuantityDialog> createState() =>
      _ArcResearchQuantityDialogState();
}

class _ArcResearchQuantityDialogState
    extends State<ArcResearchQuantityDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount < 0 || amount > widget.maxValue) {
      setState(() => _error = 'Enter a number from 0 to ${widget.maxValue}');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArcUiTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
        side: BorderSide(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.35),
        ),
      ),
      title: Text(
        widget.title,
        style: ArcUiTokens.sectionTitle(
          color: ArcUiTokens.primaryAccent,
          fontSize: 19,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'In-game quantity',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
