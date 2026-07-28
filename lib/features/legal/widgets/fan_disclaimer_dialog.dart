import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import '../repositories/legal_repository.dart';

class FanDisclaimerDialog extends StatelessWidget {
  const FanDisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.neonPink.withValues(alpha: 0.24)),
      ),
      title: Text(
        'Fan Project Notice',
        style: AppTheme.tradingHeading(fontSize: 24, color: AppTheme.neonPink),
      ),
      content: const SingleChildScrollView(
        child: Text(
          UagFanProjectNotice.text,
          style: TextStyle(color: Colors.white70, height: 1.45),
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
