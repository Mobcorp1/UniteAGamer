import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapFilterIcon extends StatelessWidget {
  const ArcMapFilterIcon({
    super.key,
    this.iconKey,
    this.category,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final String? iconKey;
  final ArcRaidMapMarkerCategory? category;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    final assetPath = category == null
        ? ArcMapFilterIconRegistry.tryAssetPathFor(iconKey ?? '')
        : ArcMapFilterIconRegistry.tryAssetPathForMarker(
            iconKey: iconKey,
            category: category,
          );

    final Widget icon = assetPath == null
        ? Icon(
            _fallbackIcon(category),
            size: size,
            color: color ?? Colors.white70,
          )
        : Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Icon(
              _fallbackIcon(category),
              size: size,
              color: color ?? Colors.white70,
            ),
          );

    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(label: semanticLabel, image: true, child: icon);
  }

  IconData _fallbackIcon(ArcRaidMapMarkerCategory? category) {
    if (category == null) return Icons.location_on_outlined;
    return switch (category) {
      ArcRaidMapMarkerCategory.standardExtraction ||
      ArcRaidMapMarkerCategory.raiderHatch => Icons.logout,
      ArcRaidMapMarkerCategory.weaponCase ||
      ArcRaidMapMarkerCategory.securityLocker ||
      ArcRaidMapMarkerCategory.firstWaveCache ||
      ArcRaidMapMarkerCategory.raiderCache ||
      ArcRaidMapMarkerCategory.fieldCrate ||
      ArcRaidMapMarkerCategory.containerCluster ||
      ArcRaidMapMarkerCategory.generalLoot => Icons.inventory_2_outlined,
      ArcRaidMapMarkerCategory.arcThreat ||
      ArcRaidMapMarkerCategory.configuredHazard => Icons.warning_amber_rounded,
      ArcRaidMapMarkerCategory.questObjective ||
      ArcRaidMapMarkerCategory.operationObjective ||
      ArcRaidMapMarkerCategory.teammateObjective => Icons.flag_outlined,
      _ => Icons.location_on_outlined,
    };
  }
}
