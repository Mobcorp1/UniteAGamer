import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';

class ArcNomadicTraderRepository {
  const ArcNomadicTraderRepository();

  static const prefsPrefix = 'arc_nomadic_trader_';

  Future<ArcNomadicTraderTrackerSnapshot> loadTrackerSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final goalName = prefs.getString('${prefsPrefix}goal_name');
    final highTier = prefs.getBool('${prefsPrefix}high_tier') ?? true;
    final targetValue = prefs.getInt('${prefsPrefix}target_value');
    final purchasesJson = prefs.getString('${prefsPrefix}nomadic_purchases');
    final resources = _resourceSnapshots(prefs, highTier: highTier);
    final purchases = _decodePurchases(purchasesJson);
    final savedStateKnown =
        goalName != null ||
        targetValue != null ||
        (purchasesJson != null && purchasesJson.trim().isNotEmpty) ||
        resources.any((resource) => resource.quantity > 0);

    if (!savedStateKnown) return ArcNomadicTraderTrackerSnapshot.empty;

    return ArcNomadicTraderTrackerSnapshot(
      savedStateKnown: true,
      goalName: goalName ?? 'Nomadic Trader',
      highTier: highTier,
      targetValue: targetValue ?? 0,
      resources: resources,
      purchases: purchases,
    );
  }

  List<ArcNomadicTraderResourceSnapshot> _resourceSnapshots(
    SharedPreferences prefs, {
    required bool highTier,
  }) {
    final definitions = highTier
        ? ArcNomadicTraderCatalog.highTierResources
        : ArcNomadicTraderCatalog.lowTierResources;
    return definitions
        .map(
          (resource) => ArcNomadicTraderResourceSnapshot(
            id: resource.id,
            name: resource.name,
            value: resource.value,
            highTier: resource.highTier,
            quantity: prefs.getInt('${prefsPrefix}qty_${resource.id}') ?? 0,
          ),
        )
        .toList(growable: false);
  }

  List<ArcNomadicTraderPurchaseSnapshot> _decodePurchases(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => ArcNomadicTraderPurchaseSnapshot.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
