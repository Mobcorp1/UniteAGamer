import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_coordinate_projection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_filter_icon.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_precision_map_pin.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcRaidIntelligenceMapRenderer extends StatelessWidget {
  const ArcRaidIntelligenceMapRenderer({
    super.key,
    required this.state,
    required this.controller,
    this.selectedMarkerId,
    this.highlightedMarkerIds = const <String>{},
    this.onMarkerSelected,
    this.onMapTapped,
    this.onIntelReportRequested,
    this.showBlueprintIntel = true,
    this.playerFacingLabels = false,
  });

  final ArcRaidIntelligenceState state;
  final TransformationController controller;
  final String? selectedMarkerId;
  final Set<String> highlightedMarkerIds;
  final ValueChanged<ArcRaidMapMarker>? onMarkerSelected;
  final ValueChanged<ArcNormalizedPoint>? onMapTapped;
  final ValueChanged<ArcNormalizedPoint>? onIntelReportRequested;
  final bool showBlueprintIntel;
  final bool playerFacingLabels;

  Iterable<ArcRaidMapMarker> get _renderableMarkers => showBlueprintIntel
      ? state.visibleMarkers
      : state.visibleMarkers.where(
          (marker) =>
              marker.category != ArcRaidMapMarkerCategory.blueprintOpportunity,
        );

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
            width.clamp(1.0, 1800.0).toDouble(),
            height.clamp(1.0, 1100.0).toDouble(),
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
                  constrained: false,
                  minScale: 0.75,
                  maxScale: 5,
                  boundaryMargin: const EdgeInsets.all(260),
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  panEnabled: true,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: true,
                  child: SizedBox.fromSize(
                    size: viewportSize,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
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
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(child: _mapBackground()),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ArcRaidSchematicPainter(
                                    state: state,
                                    selectedMarkerId: selectedMarkerId,
                                    showSchematicGuides: !state.map
                                        .hasRenderableLayer(state.activeLayer),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: _modeBadge(state.map),
                              ),
                              for (final marker in _renderableMarkers)
                                _markerButton(marker, mapSize),
                            ],
                          ),
                        ),
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
    return ArcMapCoordinateProjection.canvasToCanonical(
      localPosition: localPosition,
      mapSize: mapSize,
      calibration: state.map.calibrationForLayer(state.activeLayer),
    );
  }

  Widget _mapBackground() {
    final asset = state.map.assetForLayer(state.activeLayer);
    final localPath = asset?.localAssetPath?.trim();
    if (state.map.hasRenderableLayer(state.activeLayer) &&
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
    final renderable = map.hasRenderableLayer(state.activeLayer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: calibrated
              ? Colors.lightGreenAccent.withValues(alpha: 0.42)
              : renderable
              ? Colors.amberAccent.withValues(alpha: 0.42)
              : AppTheme.neonCyan.withValues(alpha: 0.34),
        ),
      ),
      child: Text(
        calibrated
            ? (playerFacingLabels
                  ? state.activeLayer.label
                  : '${state.activeLayer.label} • calibrated game map')
            : renderable
            ? (playerFacingLabels
                  ? state.activeLayer.label
                  : '${state.activeLayer.label} • calibrated game map')
            : '${state.activeLayer.label} • tactical schematic',
        style: AppTheme.bodyTextStyle(
          fontSize: 11,
          color: calibrated
              ? Colors.lightGreenAccent
              : renderable
              ? Colors.amberAccent
              : AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }

  Widget _markerButton(ArcRaidMapMarker marker, Size mapSize) {
    final selected =
        marker.id == selectedMarkerId ||
        highlightedMarkerIds.contains(marker.id);
    final calibration = state.map.calibrationForLayer(state.activeLayer);
    final anchor = ArcMapCoordinateProjection.canonicalToCanvas(
      point: marker.point,
      mapSize: mapSize,
      calibration: calibration,
    );
    final color = _markerColor(marker.category, marker.confidence);
    final pinWidth = ArcPrecisionMapPin.widthFor(selected);
    final pinHeight = ArcPrecisionMapPin.heightFor(selected);
    final detail = marker.detail.trim().isNotEmpty
        ? marker.detail
        : marker.category.label;
    final head = marker.isBlueprintOpportunity
        ? _blueprintPinHead(marker, color, selected)
        : marker.isCluster
        ? Center(
            child: Text(
              marker.count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : ArcMapFilterIcon(
            iconKey: marker.iconKey,
            category: marker.category,
            color: color,
            size: selected ? 20 : 16,
          );

    return Positioned(
      left: anchor.dx - (pinWidth / 2),
      top: anchor.dy - pinHeight,
      child: Tooltip(
        message: marker.semanticLabel,
        child: ArcPrecisionMapPin(
          selected: selected,
          accent: color,
          head: head,
          label: marker.label,
          detail: detail,
          coordinateText:
              'X ${marker.point.x.toStringAsFixed(4)} • Y ${marker.point.y.toStringAsFixed(4)}',
          onTap: () => onMarkerSelected?.call(marker),
        ),
      ),
    );
  }

  Widget _blueprintPinHead(
    ArcRaidMapMarker marker,
    Color color,
    bool selected,
  ) {
    final byId = {
      for (final blueprint in ArcBlueprintSeedData.blueprints)
        blueprint.id: blueprint,
    };
    final blueprint = marker.blueprintIds.isEmpty
        ? null
        : byId[marker.blueprintIds.first];
    final path = blueprint?.imageAssetPath?.trim();
    final fallbackIcon = blueprint?.icon ?? Icons.extension_rounded;
    final image = path == null || path.isEmpty
        ? Icon(fallbackIcon, color: color, size: selected ? 20 : 16)
        : Image.asset(
            path,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) =>
                Icon(fallbackIcon, color: color, size: selected ? 20 : 16),
          );

    if (marker.blueprintIds.length <= 1) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color, width: 0.8),
            ),
            child: Text(
              '${marker.blueprintIds.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Size _fittedMapSize(Size viewportSize) {
    final asset = state.map.assetForLayer(state.activeLayer);
    return ArcMapCoordinateProjection.containSize(
      viewport: viewportSize,
      sourceWidth: asset?.width?.toDouble(),
      sourceHeight: asset?.height?.toDouble(),
    );
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
    _drawGrid(canvas, size, showRadar: showSchematicGuides);
    if (showSchematicGuides) {
      _drawRegions(canvas, size);
    }
    _drawRoute(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size, {required bool showRadar}) {
    final gridPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: showRadar ? 0.08 : 0.05)
      ..strokeWidth = 1;
    for (var index = 1; index < 10; index++) {
      final x = size.width * index / 10;
      final y = size.height * index / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final labelStyle = AppTheme.bodyTextStyle(
      fontSize: 9,
      color: Colors.white.withValues(alpha: showRadar ? 0.48 : 0.34),
      isBold: true,
    );
    for (var index = 0; index < 10; index++) {
      _drawLabel(
        canvas,
        String.fromCharCode(65 + index),
        Offset((size.width * index / 10) + 6, 6),
        labelStyle,
      );
      _drawLabel(
        canvas,
        '${index + 1}',
        Offset(6, (size.height * index / 10) + 20),
        labelStyle,
      );
    }
    if (!showRadar) return;
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

  void _drawLabel(Canvas canvas, String value, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
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
    return ArcMapCoordinateProjection.canonicalToCanvas(
      point: point,
      mapSize: size,
      calibration: state.map.calibrationForLayer(state.activeLayer),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRaidSchematicPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.selectedMarkerId != selectedMarkerId;
  }
}
