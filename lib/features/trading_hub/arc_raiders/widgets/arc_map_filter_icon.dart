import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        ? ArcMapFilterIconRegistry.assetPathFor(iconKey ?? '')
        : ArcMapFilterIconRegistry.assetPathForMarker(
            iconKey: iconKey,
            category: category,
          );
    final icon = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: icon);
    }
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}
