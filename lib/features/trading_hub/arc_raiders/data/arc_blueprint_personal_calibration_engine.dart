import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

@immutable
class ArcBlueprintPersonalCalibrationResult {
  const ArcBlueprintPersonalCalibrationResult({
    required this.samples,
    required this.globalOwnedFloor,
    required this.captureOwnedFloors,
    required this.knownOwnedAnchors,
    required this.suppressedCandidateCount,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final double globalOwnedFloor;
  final Map<String, double> captureOwnedFloors;
  final int knownOwnedAnchors;
  final int suppressedCandidateCount;
}

/// Uses the user's already-confirmed Blueprint ownership as positive anchors
/// for the current scan.
///
/// This is deliberately one-way calibration:
/// - existing owned positions are trusted as positive examples;
/// - existing missing positions are NOT trusted as negative examples because
///   the user may have acquired new Blueprints since the previous scan;
/// - the engine can suppress weak new-owned candidates to uncertain;
/// - it never promotes a candidate that the visual recogniser did not already
///   classify strongly enough to cross the normal owned threshold.
///
/// That makes repeat scans safer while still allowing newly acquired
/// Blueprints to be proposed through the existing review screen.
class ArcBlueprintPersonalCalibrationEngine {
  const ArcBlueprintPersonalCalibrationEngine({
    this.baseOwnedThreshold = 0.84,
    this.minimumAnchorCount = 8,
    this.minimumCaptureAnchorCount = 4,
    this.maximumAdaptiveFloor = 0.94,
    this.medianMargin = 0.055,
  });

  final double baseOwnedThreshold;
  final int minimumAnchorCount;
  final int minimumCaptureAnchorCount;
  final double maximumAdaptiveFloor;
  final double medianMargin;

  ArcBlueprintPersonalCalibrationResult calibrate({
    required List<String> orderedBlueprintIds,
    required List<ArcBlueprintPhotoOccupancySample> samples,
    required Map<String, ArcBlueprintState> existing,
  }) {
    if (orderedBlueprintIds.isEmpty || samples.isEmpty) {
      return ArcBlueprintPersonalCalibrationResult(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(samples),
        globalOwnedFloor: baseOwnedThreshold,
        captureOwnedFloors: const <String, double>{},
        knownOwnedAnchors: 0,
        suppressedCandidateCount: 0,
      );
    }

    final samplesByIndex = <int, ArcBlueprintPhotoOccupancySample>{};
    for (final sample in samples) {
      final index = _indexForSample(sample, orderedBlueprintIds.length);
      if (index != null) samplesByIndex[index] = sample;
    }

    final anchors = <_OwnedAnchor>[];
    for (var index = 0; index < orderedBlueprintIds.length; index++) {
      final blueprintId = orderedBlueprintIds[index];
      if (existing[blueprintId]?.owned != true) continue;

      final sample = samplesByIndex[index];
      if (sample == null) continue;

      anchors.add(
        _OwnedAnchor(
          captureId: sample.captureId,
          score: sample.occupancyScore.clamp(0.0, 1.0).toDouble(),
        ),
      );
    }

    final globalFloor = anchors.length >= minimumAnchorCount
        ? _floorFromScores(anchors.map((anchor) => anchor.score).toList())
        : baseOwnedThreshold;

    final byCapture = <String, List<double>>{};
    for (final anchor in anchors) {
      byCapture
          .putIfAbsent(anchor.captureId, () => <double>[])
          .add(anchor.score);
    }

    final captureFloors = <String, double>{};
    for (final entry in byCapture.entries) {
      if (entry.value.length >= minimumCaptureAnchorCount) {
        captureFloors[entry.key] = math.max(
          globalFloor,
          _floorFromScores(entry.value),
        );
      }
    }

    var suppressed = 0;
    final calibrated = <ArcBlueprintPhotoOccupancySample>[];

    for (final sample in samples) {
      final index = _indexForSample(sample, orderedBlueprintIds.length);
      if (index == null) {
        calibrated.add(sample);
        continue;
      }

      final blueprintId = orderedBlueprintIds[index];
      final alreadyOwned = existing[blueprintId]?.owned == true;
      final score = sample.occupancyScore.clamp(0.0, 1.0).toDouble();
      final floor = captureFloors[sample.captureId] ?? globalFloor;

      // Existing ownership is never altered by this calibration layer.
      if (alreadyOwned || score < baseOwnedThreshold || score >= floor) {
        calibrated.add(sample);
        continue;
      }

      // The base recogniser thought this was owned, but it is materially weaker
      // than the user's positive anchors from the same scan/capture. Hold it in
      // the uncertain band so it cannot silently become a proposed addition.
      suppressed++;
      calibrated.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          occupancyScore: 0.82,
        ),
      );

      if (kDebugMode) {
        debugPrint(
          'ARC PERSONAL CALIBRATION: suppress '
          'index=$index id=$blueprintId '
          'score=${score.toStringAsFixed(3)} '
          'floor=${floor.toStringAsFixed(3)} '
          'capture=${sample.captureId}',
        );
      }
    }

    if (kDebugMode) {
      final captureText = captureFloors.entries
          .map((entry) => '${entry.key}:${entry.value.toStringAsFixed(3)}')
          .join(',');
      debugPrint(
        'ARC PERSONAL CALIBRATION: summary '
        'anchors=${anchors.length} '
        'globalFloor=${globalFloor.toStringAsFixed(3)} '
        'captureFloors={$captureText} '
        'suppressed=$suppressed',
      );
    }

    return ArcBlueprintPersonalCalibrationResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(calibrated),
      globalOwnedFloor: globalFloor,
      captureOwnedFloors: Map<String, double>.unmodifiable(captureFloors),
      knownOwnedAnchors: anchors.length,
      suppressedCandidateCount: suppressed,
    );
  }

  double _floorFromScores(List<double> scores) {
    if (scores.isEmpty) return baseOwnedThreshold;

    final sorted =
        scores.map((score) => score.clamp(0.0, 1.0).toDouble()).toList()
          ..sort();

    // Median is robust against a handful of known-owned cells being blurry,
    // clipped or otherwise misread in this particular scan.
    final median = sorted.length.isOdd
        ? sorted[sorted.length ~/ 2]
        : (sorted[(sorted.length ~/ 2) - 1] + sorted[sorted.length ~/ 2]) / 2;

    return (median - medianMargin)
        .clamp(baseOwnedThreshold, maximumAdaptiveFloor)
        .toDouble();
  }

  int? _indexForSample(
    ArcBlueprintPhotoOccupancySample sample,
    int blueprintCount,
  ) {
    final index = (sample.rowIndex * 10) + sample.columnIndex;
    return index >= 0 && index < blueprintCount ? index : null;
  }
}

@immutable
class _OwnedAnchor {
  const _OwnedAnchor({required this.captureId, required this.score});

  final String captureId;
  final double score;
}
