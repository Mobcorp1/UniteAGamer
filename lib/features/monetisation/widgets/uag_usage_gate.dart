import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import '../models/uag_match_intelligence_copy.dart';
import '../models/uag_subscription_tier.dart';
import '../screens/monetisation_screen.dart';
import '../services/uag_entitlement_service.dart';

class UagUsageGate {
  const UagUsageGate._();

  static Future<bool> consumeOrShowUpgrade(
    BuildContext context, {
    required UagBillableAction action,
    UagEntitlementService? service,
  }) async {
    final entitlementService = service ?? UagEntitlementService();
    final result = await entitlementService.consumeAction(action);
    if (result.allowed) return true;
    if (!context.mounted) return false;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.30),
          ),
        ),
        title: Text(
          'Upgrade for more ${action.label.toLowerCase()}s',
          style: ArcUiTokens.sectionTitle(
            fontSize: 22,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        content: Text(
          _upgradeBody(action, result.reason),
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushNamed(MonetisationScreen.routeName);
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
    return false;
  }

  static String _upgradeBody(UagBillableAction action, String? reason) {
    final intro = reason ?? 'Your current plan limit has been reached.';
    if (action == UagBillableAction.matchmakingSearch) {
      return '$intro\n\nFree includes ${UagMatchIntelligenceCopy.free.label.toLowerCase()}. Essential unlocks ${UagMatchIntelligenceCopy.essential.label.toLowerCase()} with deeper schedule, communication and squad-intent analysis. Premium unlocks ${UagMatchIntelligenceCopy.premium.label.toLowerCase()} for the strongest private-signal recommendations.';
    }
    return '$intro\n\nFree users keep the core app, Intel contribution, Blueprint Tracker and basic UAG Raider access. Essential unlocks regular-player limits. Premium unlocks unlimited power-user tools and no ads.';
  }
}
