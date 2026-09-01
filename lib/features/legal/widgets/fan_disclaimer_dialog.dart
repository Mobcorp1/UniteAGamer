import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import '../repositories/legal_repository.dart';

class FanDisclaimerDialog extends StatelessWidget {
  const FanDisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        side: BorderSide(
          color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.28),
        ),
      ),
      title: Text(
        'Fan Project Notice',
        style: ArcUiTokens.sectionTitle(
          fontSize: 18,
          color: ArcUiTokens.secondaryAccent,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          UagFanProjectNotice.text,
          style: ArcUiTokens.body(fontSize: 13),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await LegalRepository().acceptFanDisclaimer();
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}
