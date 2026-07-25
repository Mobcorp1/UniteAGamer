import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_opportunity_marker.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcRaidIntelligenceMapRenderer extends StatelessWidget {
  const ArcRaidIntelligenceMapRenderer({
    super.key,
    required this.state,
    required this.controller,
    this.selectedMarkerId,
    this.onMarkerSelected,
    this.onMapTapped,
    this.onIntelReportRequested,
  });

  final ArcRaidIntelligenceState state;
  final TransformationController controller;
  final String? selectedMarkerId;
  final ValueChanged<ArcRaidMapMarker>? onMarkerSelected;
  final ValueChanged<ArcNormalizedPoint>? onMapTapped;
  final ValueChanged<ArcNormalizedPoint>? onIntelReportRequested;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${state.map.displayName} Raid Intelligence map. ${state.map.schematicLabel}.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.62;
          final viewportSize = Size(
            width.clamp(320.0, 1800.0).toDouble(),
            height.clamp(360.0, 1100.0).toDouble(),
          );
          final mapSize = _fittedMapSize(viewportSize);
          return SizedBox.fromSize(
            size: viewportSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Listener(
                onPointerSignal: _handlePointerSignal,
                child: InteractiveViewer(
                  transformationController: controller,
                  minScale: 0.75,
                  maxScale: 5,
                  boundaryMargin: const EdgeInsets.all(260),
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  panEnabled: true,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () => _doubleTapZoom(mapSize),
                    onTapUp: onMapTapped == null
                        ? null
                        : (details) => onMapTapped!(
                            _canonicalPoint(details.localPosition, mapSize),
                          ),
                    onLongPressStart: onIntelReportRequested == null
                        ? null
                        : (details) => onIntelReportRequested!(
                            _canonicalPoint(details.localPosition, mapSize),
                          ),
                    onSecondaryTapUp: onIntelReportRequested == null
                        ? null
                        : (details) => onIntelReportRequested!(
                            _canonicalPoint(details.localPosition, mapSize),
                          ),
                    child: SizedBox.fromSize(
                      size: mapSize,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _mapBackground()),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ArcRaidSchematicPainter(
                                state: state,
                                selectedMarkerId: selectedMarkerId,
                                showSchematicGuides: !state.map
                                    .hasCalibratedLayer(state.activeLayer),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _modeBadge(state.map),
                          ),
                          for (final marker in state.visibleMarkers)
                            _markerButton(marker, mapSize),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ArcNormalizedPoint _canonicalPoint(Offset localPosition, Size mapSize) {
    final imagePoint = ArcNormalizedPoint(
      x: localPosition.dx / mapSize.width,
      y: localPosition.dy / mapSize.height,
    ).clamp();
    final calibration = state.map.calibrationForLayer(state.activeLayer);
    return calibration?.imageToCanonical(imagePoint) ?? imagePoint;
  }

  Widget _mapBackground() {
    final asset = state.map.assetForLayer(state.activeLayer);
    final localPath = asset?.localAssetPath?.trim();
    if (state.map.hasCalibratedLayer(state.activeLayer) &&
        localPath != null &&
        localPath.isNotEmpty) {
      return Image.asset(
        localPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _schematicBackground(),
      );
    }
    return _schematicBackground();
  }

  Widget _schematicBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackgroundDeep,
            AppTheme.cardBackground,
            Colors.black.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _modeBadge(ArcRaidMap map) {
    final calibrated = map.hasCalibratedLayer(state.activeLayer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: calibrated
              ? Colors.lightGreenAccent.withValues(alpha: 0.42)
              : AppTheme.neonCyan.withValues(alpha: 0.34),
        ),
      ),
      child: Text(
        calibrated
            ? '${state.activeLayer.label} • calibrated game map'
            : '${state.activeLayer.label} • tactical schematic',
        style: AppTheme.bodyTextStyle(
          fontSize: 11,
          color: calibrated ? Colors.lightGreenAccent : AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }

  Widget _markerButton(ArcRaidMapMarker marker, Size mapSize) {
    final selected = marker.id == selectedMarkerId;
    final calibration = state.map.calibrationForLayer(state.activeLayer);
    final point =
        calibration?.canonicalToImage(marker.point) ?? marker.point.clamp();
    final color = _markerColor(marker.category, marker.confidence);
    final size = marker.isBlueprintOpportunity
        ? (marker.blueprintIds.length > 1 ? 60.0 : 54.0)
        : marker.isCluster
        ? 38.0
        : 28.0;
    return Positioned(
      left: (point.x * mapSize.width) - (size / 2),
      top: (point.y * mapSize.height) - (size / 2),
      child: marker.isBlueprintOpportunity
          ? ArcBlueprintOpportunityMarker(
              marker: marker,
              selected: selected,
              onTap: () => onMarkerSelected?.call(marker),
            )
          : Semantics(
              button: true,
              label: marker.semanticLabel,
              child: Tooltip(
                message: marker.semanticLabel,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onMarkerSelected?.call(marker),
                    child: AnimatedContainer(
                      duration: AppTheme.fastAnimation,
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: selected ? 0.90 : 0.72,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : color,
                          width: selected ? 2.2 : 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                              alpha: selected ? 0.48 : 0.22,
                            ),
                            blurRadius: selected ? 20 : 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: marker.isCluster
                            ? Text(
                                marker.count.toString(),
                                style: AppTheme.bodyTextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  isBold: true,
                                ),
                              )
                            : Icon(
                                _markerIcon(marker.category),
                                color: color,
                                size: 15,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Size _fittedMapSize(Size viewportSize) {
    final asset = state.map.assetForLayer(state.activeLayer);
    final width = asset?.width?.toDouble();
    final height = asset?.height?.toDouble();
    final aspectRatio = width != null && height != null && height > 0
        ? width / height
        : 1.25;
    final viewportRatio = viewportSize.width / viewportSize.height;
    if (viewportRatio > aspectRatio) {
      return Size(viewportSize.height * aspectRatio, viewportSize.height);
    }
    return Size(viewportSize.width, viewportSize.width / aspectRatio);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final currentScale = controller.value.getMaxScaleOnAxis();
    final zoomFactor = event.scrollDelta.dy > 0 ? 0.90 : 1.10;
    final targetScale = (currentScale * zoomFactor).clamp(0.75, 5.0);
    if ((targetScale - currentScale).abs() < 0.001) return;

    final scenePoint = controller.toScene(event.localPosition);
    controller.value = Matrix4.identity()
      ..translateByDouble(event.localPosition.dx, event.localPosition.dy, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1)
      ..translateByDouble(-scenePoint.dx, -scenePoint.dy, 0, 1);
  }

  void _doubleTapZoom(Size mapSize) {
    final currentScale = controller.value.getMaxScaleOnAxis();
    if (currentScale > 1.2) {
      controller.value = Matrix4.identity();
      return;
    }
    final center = Offset(mapSize.width / 2, mapSize.height / 2);
    controller.value = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1.85, 1.85, 1.85, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }

  static Color _markerColor(
    ArcRaidMapMarkerCategory category,
    ArcRaidIntelConfidence confidence,
  ) {
    switch (category.filteringGroup) {
      case 'My Objectives':
        return AppTheme.neonPink;
      case 'Loot Sources':
        return Colors.amberAccent;
      case 'Intel Quality':
        return confidence.score >= 70
            ? Colors.lightGreenAccent
            : AppTheme.neonCyan;
      default:
        return AppTheme.neonCyan;
    }
  }

  static IconData _markerIcon(ArcRaidMapMarkerCategory category) {
    switch (category) {
      case ArcRaidMapMarkerCategory.blueprintOpportunity:
      case ArcRaidMapMarkerCategory.topWanted:
        return Icons.extension_rounded;
      case ArcRaidMapMarkerCategory.favouriteLoadoutRequirement:
        return Icons.star_rounded;
      case ArcRaidMapMarkerCategory.tradePreparationRequirement:
        return Icons.swap_horiz_rounded;
      case ArcRaidMapMarkerCategory.standardExtraction:
        return Icons.exit_to_app_rounded;
      case ArcRaidMapMarkerCategory.raiderHatch:
        return Icons.key_rounded;
      case ArcRaidMapMarkerCategory.spawn:
      case ArcRaidMapMarkerCategory.spawnRegion:
        return Icons.my_location_rounded;
      case ArcRaidMapMarkerCategory.routeWaypoint:
        return Icons.route_rounded;
      case ArcRaidMapMarkerCategory.weaponCase:
      case ArcRaidMapMarkerCategory.securityLocker:
      case ArcRaidMapMarkerCategory.firstWaveCache:
      case ArcRaidMapMarkerCategory.raiderCache:
      case ArcRaidMapMarkerCategory.fieldCrate:
      case ArcRaidMapMarkerCategory.containerCluster:
        return Icons.inventory_2_rounded;
      case ArcRaidMapMarkerCategory.mapEvent:
        return Icons.bolt_rounded;
      case ArcRaidMapMarkerCategory.arcThreat:
        return Icons.warning_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

class _ArcRaidSchematicPainter extends CustomPainter {
  const _ArcRaidSchematicPainter({
    required this.state,
    required this.selectedMarkerId,
    required this.showSchematicGuides,
  });

  final ArcRaidIntelligenceState state;
  final String? selectedMarkerId;
  final bool showSchematicGuides;

  @override
  void paint(Canvas canvas, Size size) {
    if (showSchematicGuides) {
      _drawGrid(canvas, size);
      _drawRegions(canvas, size);
    }
    _drawRoute(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var index = 1; index < 10; index++) {
      final x = size.width * index / 10;
      final y = size.height * index / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final radarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.neonPink.withValues(alpha: 0.10);
    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (final radius in [0.18, 0.32, 0.46]) {
      canvas.drawCircle(
        center,
        math.min(size.width, size.height) * radius,
        radarPaint,
      );
    }
  }

  void _drawRegions(Canvas canvas, Size size) {
    for (final region in state.map.regions) {
      final center = _offset(region.center, size);
      final radius =
          math.min(size.width, size.height) * (0.10 + region.risk * 0.08);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = (region.risk > 0.42 ? AppTheme.neonPink : AppTheme.neonCyan)
            .withValues(alpha: 0.055);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (region.risk > 0.42 ? AppTheme.neonPink : AppTheme.neonCyan)
            .withValues(alpha: 0.16);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius, border);
    }
  }

  void _drawRoute(Canvas canvas, Size size) {
    final route = state.routePlan;
    if (route == null) return;
    final points = route.orderedStops
        .map((stop) => _offset(stop.point, size))
        .toList();
    if (points.length < 2) return;
    final linePaint = Paint()
      ..color = AppTheme.neonPink.withValues(alpha: 0.74)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
  }

  Offset _offset(ArcNormalizedPoint point, Size size) {
    final calibration = state.map.calibrationForLayer(state.activeLayer);
    final calibrated = calibration?.canonicalToImage(point) ?? point.clamp();
    return Offset(calibrated.x * size.width, calibrated.y * size.height);
  }

  @override
  bool shouldRepaint(covariant _ArcRaidSchematicPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.selectedMarkerId != selectedMarkerId;
  }
}
