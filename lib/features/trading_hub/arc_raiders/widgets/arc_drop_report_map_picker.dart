import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcDropReportMapSelection {
  const ArcDropReportMapSelection({
    required this.point,
    required this.layer,
  });

  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
}

Future<ArcDropReportMapSelection?> showArcDropReportMapPicker({
  required BuildContext context,
  required String mapName,
  required String blueprintName,
  String? blueprintAssetPath,
  ArcDropReportMapSelection? initialSelection,
}) {
  return showModalBottomSheet<ArcDropReportMapSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.cardBackgroundDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ArcDropReportMapPickerSheet(
      mapName: mapName,
      blueprintName: blueprintName,
      blueprintAssetPath: blueprintAssetPath,
      initialSelection: initialSelection,
    ),
  );
}

class _ArcDropReportMapPickerSheet extends StatefulWidget {
  const _ArcDropReportMapPickerSheet({
    required this.mapName,
    required this.blueprintName,
    required this.blueprintAssetPath,
    required this.initialSelection,
  });

  final String mapName;
  final String blueprintName;
  final String? blueprintAssetPath;
  final ArcDropReportMapSelection? initialSelection;

  @override
  State<_ArcDropReportMapPickerSheet> createState() =>
      _ArcDropReportMapPickerSheetState();
}

class _ArcDropReportMapPickerSheetState
    extends State<_ArcDropReportMapPickerSheet> {
  late final TransformationController _transform;
  late final List<MapEntry<ArcRaidMapLayer, ArcRaidMapAsset>> _available;
  late ArcRaidMapLayer _layer;
  ArcNormalizedPoint? _point;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
    final registration = ArcMapAssetRegistry.registrationFor(widget.mapName);
    _available = registration?.layerAssets.entries
            .where((entry) => entry.value.hasRenderableImage)
            .toList(growable: false) ??
        const <MapEntry<ArcRaidMapLayer, ArcRaidMapAsset>>[];

    if (_available.isEmpty) {
      _layer = ArcRaidMapLayer.surface;
      return;
    }

    final initialLayer = widget.initialSelection?.layer;
    _layer = initialLayer != null &&
            _available.any((entry) => entry.key == initialLayer)
        ? initialLayer
        : (_available.any((entry) => entry.key == ArcRaidMapLayer.surface)
              ? ArcRaidMapLayer.surface
              : _available.first.key);
    _point = widget.initialSelection?.layer == _layer
        ? widget.initialSelection?.point
        : null;
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  ArcRaidMapAsset get _asset =>
      _available.firstWhere((entry) => entry.key == _layer).value;

  double get _aspect {
    final asset = _asset;
    if (asset.width != null &&
        asset.height != null &&
        asset.width! > 0 &&
        asset.height! > 0) {
      return asset.width! / asset.height!;
    }
    return 1.18;
  }

  void _setLayer(ArcRaidMapLayer layer) {
    setState(() {
      _layer = layer;
      _point = null;
      _transform.value = Matrix4.identity();
    });
  }

  void _resetZoom() => _transform.value = Matrix4.identity();

  void _zoomBy(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 14.0).toDouble();
    if ((target - current).abs() < .001) return;
    final ratio = target / current;
    _transform.value = _transform.value.scaledByDouble(ratio, ratio, ratio, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_available.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.mapName,
                style: AppTheme.tradingHeading(
                  fontSize: 22,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This map does not currently have a renderable calibrated image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: screenHeight * .96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinpoint exact drop',
                        style: AppTheme.tradingHeading(
                          fontSize: 21,
                          color: AppTheme.neonPink,
                        ),
                      ),
                      Text(
                        '${widget.blueprintName} • ${widget.mapName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white70,
                ),
              ],
            ),
            if (_available.length > 1) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _available.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final entry = _available[index];
                    return ChoiceChip(
                      label: Text(entry.key.label),
                      selected: entry.key == _layer,
                      onSelected: (_) => _setLayer(entry.key),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 6),
            const Text(
              'The full map starts fitted to screen. Tap the exact spot, then pinch or use + / − for fine placement.',
              style: TextStyle(color: Colors.white70, height: 1.25),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: .30),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final mapSize = _containedSize(viewport, _aspect);

                    return Stack(
                      children: [
                        Center(
                          child: SizedBox.fromSize(
                            size: mapSize,
                            child: InteractiveViewer(
                              transformationController: _transform,
                              constrained: false,
                              minScale: 1,
                              maxScale: 14,
                              boundaryMargin: const EdgeInsets.all(420),
                              panEnabled: true,
                              scaleEnabled: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) {
                                  final next = ArcNormalizedPoint(
                                    x: (details.localPosition.dx /
                                            mapSize.width)
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                    y: (details.localPosition.dy /
                                            mapSize.height)
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                  );
                                  setState(() => _point = next);
                                },
                                child: SizedBox.fromSize(
                                  size: mapSize,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: _MapImage(asset: _asset),
                                      ),
                                      if (_point != null)
                                        Positioned(
                                          left: (_point!.x * mapSize.width) - 28,
                                          top: (_point!.y * mapSize.height) - 48,
                                          child: IgnorePointer(
                                            child: _BlueprintPin(
                                              assetPath:
                                                  widget.blueprintAssetPath,
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
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Column(
                            children: [
                              _MapControlButton(
                                tooltip: 'Zoom in',
                                icon: Icons.add_rounded,
                                onPressed: () => _zoomBy(1.6),
                              ),
                              const SizedBox(height: 6),
                              _MapControlButton(
                                tooltip: 'Zoom out',
                                icon: Icons.remove_rounded,
                                onPressed: () => _zoomBy(1 / 1.6),
                              ),
                              const SizedBox(height: 6),
                              _MapControlButton(
                                tooltip: 'Show whole map',
                                icon: Icons.center_focus_strong_rounded,
                                onPressed: _resetZoom,
                              ),
                            ],
                          ),
                        ),
                        if (_point != null)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .78),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.neonPink.withValues(alpha: .5),
                                ),
                              ),
                              child: Text(
                                'Exact pin ${(_point!.x * 100).toStringAsFixed(1)}%, ${(_point!.y * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _point == null
                    ? null
                    : () => Navigator.of(context).pop(
                        ArcDropReportMapSelection(
                          point: _point!,
                          layer: _layer,
                        ),
                      ),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(
                  _point == null
                      ? 'Tap the map to place the blueprint'
                      : 'Use this exact pinpoint',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .80),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppTheme.neonCyan,
        iconSize: 22,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _MapImage extends StatelessWidget {
  const _MapImage({required this.asset});

  final ArcRaidMapAsset asset;

  @override
  Widget build(BuildContext context) {
    final local = asset.localAssetPath?.trim();
    if (local != null && local.isNotEmpty) {
      return Image.asset(local, fit: BoxFit.fill);
    }
    final remote = asset.remoteUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      return Image.network(remote, fit: BoxFit.fill);
    }
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Map image unavailable',
          style: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

class _BlueprintPin extends StatelessWidget {
  const _BlueprintPin({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .90),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.neonPink, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonPink.withValues(alpha: .42),
                blurRadius: 14,
              ),
            ],
          ),
          child: assetPath == null || assetPath!.trim().isEmpty
              ? const Icon(Icons.extension_rounded, color: Colors.white)
              : ClipOval(
                  child: Image.asset(
                    assetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.extension_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const Icon(
          Icons.arrow_drop_down_rounded,
          color: AppTheme.neonPink,
          size: 30,
        ),
      ],
    );
  }
}

Size _containedSize(Size viewport, double aspect) {
  if (!viewport.width.isFinite ||
      !viewport.height.isFinite ||
      viewport.width <= 0 ||
      viewport.height <= 0) {
    return const Size(1, 1);
  }

  var width = viewport.width;
  var height = width / math.max(.2, aspect);
  if (height > viewport.height) {
    height = viewport.height;
    width = height * aspect;
  }

  return Size(
    math.max(1.0, width).toDouble(),
    math.max(1.0, height).toDouble(),
  );
}
