import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

class ArcLoadoutBlueprintNeed {
  const ArcLoadoutBlueprintNeed({
    required this.blueprintId,
    required this.itemName,
    required this.slotLabel,
    required this.priorityRank,
    required this.owned,
  });

  final String blueprintId;
  final String itemName;
  final String slotLabel;
  final int priorityRank;
  final bool owned;

  bool get missing => !owned;
}

class ArcLoadoutResourceGap {
  const ArcLoadoutResourceGap({
    required this.itemName,
    required this.requiredQuantity,
    required this.ownedQuantity,
  });

  final String itemName;
  final int requiredQuantity;
  final int ownedQuantity;

  int get missingQuantity =>
      (requiredQuantity - ownedQuantity).clamp(0, requiredQuantity).toInt();

  bool get complete => missingQuantity == 0;
}

class ArcLoadoutIntegrationSnapshot {
  const ArcLoadoutIntegrationSnapshot({
    required this.blueprints,
    required this.resources,
    required this.tradeTemplate,
    required this.completionPercent,
    required this.nextMove,
  });

  final List<ArcLoadoutBlueprintNeed> blueprints;
  final List<ArcLoadoutResourceGap> resources;
  final ArcTradeBundleTemplate tradeTemplate;
  final int completionPercent;
  final String nextMove;

  List<ArcLoadoutBlueprintNeed> get missingBlueprints =>
      blueprints.where((item) => item.missing).toList(growable: false);

  List<ArcLoadoutResourceGap> get missingResources =>
      resources.where((item) => !item.complete).toList(growable: false);

  bool get complete => missingBlueprints.isEmpty && missingResources.isEmpty;
}
