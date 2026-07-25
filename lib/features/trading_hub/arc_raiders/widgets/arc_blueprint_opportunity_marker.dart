import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintOpportunityMarker extends StatefulWidget {
  const ArcBlueprintOpportunityMarker({
    required this.marker,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ArcRaidMapMarker marker;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ArcBlueprintOpportunityMarker> createState() =>
      _ArcBlueprintOpportunityMarkerState();
}

class _ArcBlueprintOpportunityMarkerState
    extends State<ArcBlueprintOpportunityMarker> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final blueprints = _blueprints;
    final diameter = widget.marker.blueprintIds.length > 1 ? 48.0 : 42.0;
    final scale = widget.selected ? 1.18 : (_hovered ? 1.10 : 1.0);
    final ringColor = _confidenceColor(widget.marker.confidence);
    final hasPriority = widget.marker.prioritizedBlueprintIds.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.marker.semanticLabel,
        child: Tooltip(
          message: _tooltip(blueprints),
          child: AnimatedScale(
            scale: scale,
            duration: AppTheme.fastAnimation,
            curve: Curves.easeOutBack,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onTap,
                child: SizedBox.square(
                  dimension: diameter + 12,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.84),
                          border: Border.all(
                            color: widget.selected ? Colors.white : ringColor,
                            width: widget.selected ? 3 : 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(
                                alpha: widget.selected || _hovered
                                    ? 0.48
                                    : 0.26,
                              ),
                              blurRadius: widget.selected || _hovered ? 20 : 12,
                              spreadRadius: widget.selected ? 2 : 0,
                            ),
                          ],
                        ),
                      ),
                      for (
                        var index = math.min(blueprints.length, 3) - 1;
                        index >= 0;
                        index--
                      )
                        Transform.translate(
                          offset: Offset(
                            (index - 1) * (blueprints.length > 1 ? 7.0 : 0),
                            0,
                          ),
                          child: _artwork(
                            blueprints[index],
                            diameter: blueprints.length > 1
                                ? diameter * 0.72
                                : diameter - 6,
                          ),
                        ),
                      if (blueprints.isEmpty)
                        Icon(
                          Icons.extension_rounded,
                          color: ringColor,
                          size: 22,
                        ),
                      if (widget.marker.count > 1)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: _countBadge(widget.marker.count),
                        ),
                      if (hasPriority)
                        Positioned(
                          left: -2,
                          top: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.neonPink,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ArcBlueprint> get _blueprints {
    final byId = <String, ArcBlueprint>{
      for (final blueprint in ArcBlueprintSeedData.blueprints)
        blueprint.id: blueprint,
    };
    return widget.marker.blueprintIds
        .map((id) => byId[id])
        .whereType<ArcBlueprint>()
        .toList(growable: false);
  }

  Widget _artwork(ArcBlueprint blueprint, {required double diameter}) {
    final path = blueprint.imageAssetPath;
    return Container(
      width: diameter,
      height: diameter,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardBackgroundDeep,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: path == null || path.trim().isEmpty
          ? Icon(blueprint.icon, color: Colors.white70, size: diameter * 0.46)
          : Image.asset(
              path,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Icon(
                blueprint.icon,
                color: Colors.white70,
                size: diameter * 0.46,
              ),
            ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTheme.bodyTextStyle(
          fontSize: 10,
          color: Colors.white,
          isBold: true,
        ),
      ),
    );
  }

  String _tooltip(List<ArcBlueprint> blueprints) {
    final names = blueprints.map((item) => item.name).take(3).join(', ');
    final extra = blueprints.length > 3 ? ' +${blueprints.length - 3}' : '';
    return names.isEmpty
        ? widget.marker.semanticLabel
        : '$names$extra • ${widget.marker.count} finds • '
              '${widget.marker.confidence.label}';
  }

  Color _confidenceColor(ArcRaidIntelConfidence confidence) {
    if (confidence.score >= 90) return Colors.lightGreenAccent;
    if (confidence.score >= 70) return AppTheme.neonCyan;
    if (confidence.score >= 45) return Colors.amberAccent;
    return Colors.white54;
  }
}
