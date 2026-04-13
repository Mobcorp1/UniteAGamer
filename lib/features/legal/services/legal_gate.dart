import 'package:flutter/material.dart';
import '../repositories/legal_repository.dart';
import '../widgets/fan_disclaimer_dialog.dart';

class LegalGate {
  static Future<void> checkFanDisclaimer(BuildContext context) async {
    final legal = await LegalRepository().getLegal();
    if (legal['fanDisclaimerAccepted'] != true) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const FanDisclaimerDialog(),
      );
    }
  }
}
