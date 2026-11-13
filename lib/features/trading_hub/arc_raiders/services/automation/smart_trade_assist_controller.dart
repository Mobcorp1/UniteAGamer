import 'package:flutter/foundation.dart';

import 'smart_trade_assist_engine.dart';
import 'smart_trade_inventory_input.dart';

class SmartTradeAssistController extends ChangeNotifier {
  final SmartTradeAssistEngine _engine;

  SmartTradeInventoryInput? _latestInput;
  List<SmartTradeOpportunity> _opportunities = const [];

  SmartTradeAssistController({
    SmartTradeAssistEngine engine = const SmartTradeAssistEngine(),
  }) : _engine = engine;

  SmartTradeInventoryInput? get latestInput => _latestInput;
  List<SmartTradeOpportunity> get opportunities => _opportunities;

  bool get hasInput => _latestInput != null;
  bool get hasOpportunities => _opportunities.isNotEmpty;

  int get listingDraftCount {
    return _opportunities
        .where(
          (item) => item.tier == SmartTradeOpportunityTier.publicListingDraft,
        )
        .length;
  }

  int get missingBlueprintFallbackCount {
    return _opportunities
        .where(
          (item) =>
              item.tier == SmartTradeOpportunityTier.missingBlueprintMatch,
        )
        .length;
  }

  int get resourceBundleFallbackCount {
    return _opportunities
        .where(
          (item) => item.tier == SmartTradeOpportunityTier.usefulResourceBundle,
        )
        .length;
  }

  void rebuild(SmartTradeInventoryInput input) {
    final normalisedInput = input.normalised();

    _latestInput = normalisedInput;
    _opportunities = _engine.buildFullOpportunityStack(
      duplicateBlueprintQuantities:
          normalisedInput.duplicateBlueprintQuantities,
      topFiveWantedBlueprintIds: normalisedInput.topFiveWantedBlueprintIds,
      missingBlueprintIds: normalisedInput.missingBlueprintIds,
      usefulResourceIds: normalisedInput.usefulResourceIds,
    );

    notifyListeners();
  }

  void clear() {
    _latestInput = null;
    _opportunities = const [];
    notifyListeners();
  }
}
