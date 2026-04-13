import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
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
        style: AppTheme.tradingHeading(
          fontSize: 24,
          color: AppTheme.neonPink,
        ),
      ),
      content: const SingleChildScrollView(
        child: Text(
          'This application is a fan-made companion tool for ARC Raiders.\n\n'
          'ARC Raiders and all related game names, images, assets, trademarks, and rights belong to Embark Studios AB.\n\n'
          'This app is not affiliated with, endorsed by, or supported by Embark Studios.\n\n'
          'Game-related images and references are used only for informational and community purposes. If requested by the rights holder, assets will be removed.',
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
