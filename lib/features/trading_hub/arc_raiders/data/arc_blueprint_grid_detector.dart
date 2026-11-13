import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintGridDetector {
  const ArcBlueprintGridDetector({
    this.analysisWidth = 720,
    this.minimumConfidence = 0.58,
    this.columns = 10,
    this.rows = 5,
  });

  final int analysisWidth;
  final double minimumConfidence;
  final int columns;
  final int rows;

  ArcBlueprintGridDetection detect(Uint8List bytes) {
    final decoded = _decode(bytes);
    if (decoded == null) {
      return ArcBlueprintGridDetection.notFound(
        message: 'Captured image could not be decoded.',
        columns: columns,
        rows: rows,
      );
    }

    return detectImage(img.bakeOrientation(decoded));
  }

  ArcBlueprintGridDetection detectImage(img.Image image) {
    final oriented = img.bakeOrientation(image);
    final scale = oriented.width > analysisWidth
        ? analysisWidth / oriented.width
        : 1.0;
    final resized = scale < 1
        ? img.copyResize(
            oriented,
            width: analysisWidth,
            interpolation: img.Interpolation.average,
          )
        : oriented;

    if (resized.width < 220 || resized.height < 120) {
      return ArcBlueprintGridDetection.notFound(
        message: 'Captured image is too small for grid detection.',
        columns: columns,
        rows: rows,
      );
    }

    final vertical = _findRegularGrid(
      profile: _verticalEdgeProfile(resized),
      expectedLines: columns + 1,
      minimumSpanFraction: 0.44,
    );
    final horizontal = _findRegularGrid(
      profile: _horizontalEdgeProfile(resized),
      expectedLines: rows + 1,
      minimumSpanFraction: rows >= 5 ? 0.32 : 0.20,
    );

    if (vertical == null || horizontal == null) {
      final panelFallback = _detectFromBlueprintPanel(resized);
      if (panelFallback != null) {
        return panelFallback;
      }
      return ArcBlueprintGridDetection.notFound(
        message:
            'No Blueprint panel/grid lock. Keep the dark Blueprint panel inside '
            'the guide and reduce strong reflections if possible.',
        columns: columns,
        rows: rows,
      );
    }

    final width = resized.width.toDouble();
    final height = resized.height.toDouble();
    final verticalDividers = vertical.positions
        .map((position) => position / width)
        .toList(growable: false);
    final horizontalDividers = horizontal.positions
        .map((position) => position / height)
        .toList(growable: false);

    final confidence = _combinedConfidence(
      vertical.confidence,
      horizontal.confidence,
    );

    final detection = ArcBlueprintGridDetection(
      topLeft: Offset(verticalDividers.first, horizontalDividers.first),
      topRight: Offset(verticalDividers.last, horizontalDividers.first),
      bottomLeft: Offset(verticalDividers.first, horizontalDividers.last),
      bottomRight: Offset(verticalDividers.last, horizontalDividers.last),
      confidence: confidence,
      message: confidence >= minimumConfidence
          ? 'Grid locked'
          : 'Grid detected with low confidence',
      columns: columns,
      rows: rows,
      verticalDividers: verticalDividers,
      horizontalDividers: horizontalDividers,
    );

    if (!detection.isValid || !detection.hasSegmentedGrid) {
      final panelFallback = _detectFromBlueprintPanel(resized);
      if (panelFallback != null) return panelFallback;
      return ArcBlueprintGridDetection.notFound(
        message: 'The detected Blueprint panel is not a valid grid.',
        columns: columns,
        rows: rows,
      );
    }

    final detectedWidth = (detection.topRight.dx - detection.topLeft.dx).abs();
    final detectedHeight = (detection.bottomLeft.dy - detection.topLeft.dy)
        .abs();

    // PASS 353A-FIX5: if the strict detector has already produced the exact
    // expected divider counts, a large credible span and highly regular cell
    // spacing, the geometry itself is strong independent evidence. TV glare
    // can depress edge strength without changing spacing. This path is kept
    // separate from the panel fallback, so a featureless rectangle still
    // cannot invent 11 x 6 recurring divider positions.
    if (detection.confidence < minimumConfidence &&
        detection.verticalDividers.length == columns + 1 &&
        detection.horizontalDividers.length == rows + 1 &&
        detectedWidth >= 0.50 &&
        detectedHeight >= (rows >= 5 ? 0.24 : 0.16) &&
        _dividerSpacingRegularity(detection.verticalDividers) >= 0.74 &&
        _dividerSpacingRegularity(detection.horizontalDividers) >= 0.68) {
      return ArcBlueprintGridDetection(
        topLeft: detection.topLeft,
        topRight: detection.topRight,
        bottomLeft: detection.bottomLeft,
        bottomRight: detection.bottomRight,
        confidence: math.max(minimumConfidence, detection.confidence),
        message: 'Grid locked (verified regular spacing)',
        columns: columns,
        rows: rows,
        verticalDividers: detection.verticalDividers,
        horizontalDividers: detection.horizontalDividers,
      );
    }

    // PASS 353A-FIX4: on a television, glare/moiré can lower the strict
    // regular-line confidence even when the detector has found the correct
    // 10-column geometry. Verify that geometry with the independent periodic
    // internal-grid evidence gate before falling back to panel detection.
    //
    // This does NOT allow a plain rectangle to become a lock: the same FIX2
    // evidence guard must prove recurring internal Blueprint boundaries.
    if (detectedWidth >= 0.50 &&
        detectedHeight >= (rows >= 5 ? 0.24 : 0.16) &&
        detection.confidence < minimumConfidence) {
      final verifiedEvidence = _internalGridEvidence(
        resized,
        topLeft: detection.topLeft,
        topRight: detection.topRight,
        bottomLeft: detection.bottomLeft,
        bottomRight: detection.bottomRight,
      );

      if (verifiedEvidence.isCredible) {
        return ArcBlueprintGridDetection(
          topLeft: detection.topLeft,
          topRight: detection.topRight,
          bottomLeft: detection.bottomLeft,
          bottomRight: detection.bottomRight,
          confidence: math.max(minimumConfidence, detection.confidence),
          message: 'Grid locked (verified internal evidence)',
          columns: columns,
          rows: rows,
          verticalDividers: detection.verticalDividers,
          horizontalDividers: detection.horizontalDividers,
        );
      }
    }

    if (detectedWidth < 0.50 ||
        detectedHeight < (rows >= 5 ? 0.24 : 0.16) ||
        detection.confidence < minimumConfidence) {
      final panelFallback = _detectFromBlueprintPanel(resized);
      // PASS 353A-FIX3: the strict divider detector and TV-panel fallback use
      // different confidence scales. Once FIX2 has proven recurring internal
      // grid evidence, a credible TV fallback is safer than retaining a
      // low-confidence strict detection merely because its numeric score is a
      // little higher.
      if (panelFallback != null) {
        return panelFallback;
      }
    }

    return detection;
  }

  ArcBlueprintGridDetection? _detectFromBlueprintPanel(img.Image image) {
    // PASS 353A fallback for a phone camera looking at a television.
    // Instead of requiring every thin cell divider to survive moire/reflection,
    // first isolate the large dark/navy Blueprint panel, then use the stable
    // relative grid geometry inside that panel.
    final topSearch = (image.height * 0.08).round();
    final bottomSearch = (image.height * 0.94).round();
    final leftSearch = (image.width * 0.04).round();
    final rightSearch = (image.width * 0.97).round();

    final samples = <_PanelRowSample>[];
    for (var y = topSearch; y <= bottomSearch; y += 3) {
      final row = _panelSpanForRow(
        image,
        y,
        leftSearch: leftSearch,
        rightSearch: rightSearch,
      );
      if (row != null && row.width >= image.width * 0.42) {
        samples.add(row);
      }
    }

    if (samples.length < math.max(12, image.height ~/ 35)) return null;

    final grouped = _largestContiguousPanelGroup(samples);
    if (grouped.length < 10) return null;

    final topY = grouped.first.y.toDouble();
    final bottomY = grouped.last.y.toDouble();
    final panelHeight = bottomY - topY;
    if (panelHeight < image.height * 0.34) return null;

    // Median/trimmed rows resist a bright blind reflection cutting through the
    // middle of the panel.
    final topBand = grouped.take(math.max(3, grouped.length ~/ 5)).toList();
    final bottomBand = grouped
        .skip(math.max(0, grouped.length - math.max(3, grouped.length ~/ 5)))
        .toList();

    final leftTop = _median(topBand.map((e) => e.left.toDouble()).toList());
    final rightTop = _median(topBand.map((e) => e.right.toDouble()).toList());
    final leftBottom = _median(
      bottomBand.map((e) => e.left.toDouble()).toList(),
    );
    final rightBottom = _median(
      bottomBand.map((e) => e.right.toDouble()).toList(),
    );

    final panelTopLeft = Offset(leftTop / image.width, topY / image.height);
    final panelTopRight = Offset(rightTop / image.width, topY / image.height);
    final panelBottomLeft = Offset(
      leftBottom / image.width,
      bottomY / image.height,
    );
    final panelBottomRight = Offset(
      rightBottom / image.width,
      bottomY / image.height,
    );

    // ARC's Blueprint screen keeps the grid at a stable relative position
    // inside the panel. These are structural proportions, not a screenshot
    // pixel template, so ownership patterns and future Blueprint art can vary.
    const gridLeft = 0.065;
    const gridRight = 0.945;
    const gridTop = 0.205;
    const gridBottom = 0.905;

    Offset bilinear(double u, double v) {
      final left = Offset.lerp(panelTopLeft, panelBottomLeft, v)!;
      final right = Offset.lerp(panelTopRight, panelBottomRight, v)!;
      return Offset.lerp(left, right, u)!;
    }

    final topLeft = bilinear(gridLeft, gridTop);
    final topRight = bilinear(gridRight, gridTop);
    final bottomLeft = bilinear(gridLeft, gridBottom);
    final bottomRight = bilinear(gridRight, gridBottom);

    final gridWidth = (topRight.dx - topLeft.dx).abs();
    final gridHeight = (bottomLeft.dy - topLeft.dy).abs();
    if (gridWidth < 0.44 || gridHeight < (rows >= 5 ? 0.24 : 0.16)) {
      return null;
    }

    // PASS 353A-FIX2: a large dark rectangle is not enough to prove that this
    // is ARC's Blueprint grid. Require periodic internal divider evidence near
    // the geometry where Blueprint cell boundaries should be. This remains
    // deliberately tolerant: glare/moiré may erase several lines, but an
    // arbitrary menu panel / TV bezel must not become a false lock.
    final evidence = _internalGridEvidence(
      image,
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    );
    if (!evidence.isCredible) {
      return null;
    }

    final verticalDividers = List<double>.generate(
      columns + 1,
      (index) => topLeft.dx + ((topRight.dx - topLeft.dx) * index / columns),
      growable: false,
    );
    final horizontalDividers = List<double>.generate(
      rows + 1,
      (index) => topLeft.dy + ((bottomLeft.dy - topLeft.dy) * index / rows),
      growable: false,
    );

    final panelCoverage =
        (((rightTop - leftTop) + (rightBottom - leftBottom)) /
                (2 * image.width))
            .clamp(0.0, 1.0);
    final confidence = (0.58 + ((panelCoverage - 0.45).clamp(0.0, 0.40) * 0.65))
        .clamp(0.0, 0.86)
        .toDouble();

    return ArcBlueprintGridDetection(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
      confidence: confidence,
      message: 'TV Blueprint panel locked',
      columns: columns,
      rows: rows,
      verticalDividers: verticalDividers,
      horizontalDividers: horizontalDividers,
    );
  }

  double _dividerSpacingRegularity(List<double> dividers) {
    if (dividers.length < 3) return 0;

    final gaps = <double>[];
    for (var i = 1; i < dividers.length; i++) {
      final gap = (dividers[i] - dividers[i - 1]).abs();
      if (gap <= 0) return 0;
      gaps.add(gap);
    }

    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    if (mean <= 0) return 0;

    var deviation = 0.0;
    for (final gap in gaps) {
      deviation += (gap - mean).abs();
    }
    deviation /= gaps.length;

    // 1.0 = perfectly even spacing. Values remain comparable across image
    // sizes because divider positions are normalized.
    return (1.0 - (deviation / mean)).clamp(0.0, 1.0);
  }

  _InternalGridEvidence _internalGridEvidence(
    img.Image image, {
    required Offset topLeft,
    required Offset topRight,
    required Offset bottomLeft,
    required Offset bottomRight,
  }) {
    Offset pointAt(double u, double v) {
      final left = Offset.lerp(topLeft, bottomLeft, v)!;
      final right = Offset.lerp(topRight, bottomRight, v)!;
      return Offset.lerp(left, right, u)!;
    }

    var credibleVertical = 0;
    final verticalTotal = math.max(1, columns - 1);

    for (var column = 1; column < columns; column++) {
      final u = column / columns;
      var hits = 0;
      var samples = 0;

      // Avoid the outer panel/header/footer and horizontal divider crossings.
      for (var sample = 1; sample <= 11; sample++) {
        final v = 0.08 + (sample * 0.07);
        final p = pointAt(u, v);
        final x = (p.dx * image.width).round();
        final y = (p.dy * image.height).round();

        if (x < 8 || x >= image.width - 8 || y < 4 || y >= image.height - 4) {
          continue;
        }

        samples += 1;
        if (_hasLocalDividerRidge(image, x, y, vertical: true)) {
          hits += 1;
        }
      }

      if (samples > 0 && hits / samples >= 0.27) {
        credibleVertical += 1;
      }
    }

    var credibleHorizontal = 0;
    final horizontalTotal = math.max(1, rows - 1);

    for (var row = 1; row < rows; row++) {
      final v = row / rows;
      var hits = 0;
      var samples = 0;

      for (var sample = 1; sample <= 13; sample++) {
        final u = 0.05 + (sample * 0.065);
        final p = pointAt(u, v);
        final x = (p.dx * image.width).round();
        final y = (p.dy * image.height).round();

        if (x < 4 || x >= image.width - 4 || y < 8 || y >= image.height - 8) {
          continue;
        }

        samples += 1;
        if (_hasLocalDividerRidge(image, x, y, vertical: false)) {
          hits += 1;
        }
      }

      if (samples > 0 && hits / samples >= 0.25) {
        credibleHorizontal += 1;
      }
    }

    final verticalRatio = credibleVertical / verticalTotal;
    final horizontalRatio = credibleHorizontal / horizontalTotal;

    return _InternalGridEvidence(
      credibleVertical: credibleVertical,
      credibleHorizontal: credibleHorizontal,
      verticalRatio: verticalRatio,
      horizontalRatio: horizontalRatio,
    );
  }

  bool _hasLocalDividerRidge(
    img.Image image,
    int x,
    int y, {
    required bool vertical,
  }) {
    // Search a small band around the expected divider. TV perspective,
    // resampling and moiré can shift a visible line by a few pixels.
    for (var offset = -7; offset <= 7; offset++) {
      final sx = vertical ? x + offset : x;
      final sy = vertical ? y : y + offset;

      final center = image.getPixelSafe(sx, sy);
      final a = vertical
          ? image.getPixelSafe(sx - 5, sy)
          : image.getPixelSafe(sx, sy - 5);
      final b = vertical
          ? image.getPixelSafe(sx + 5, sy)
          : image.getPixelSafe(sx, sy + 5);

      final centreLuma = _luma(center);
      final sideLuma = (_luma(a) + _luma(b)) * 0.5;
      final ridgeContrast = (centreLuma - sideLuma).abs();

      final colourContrast =
          (_colourDistance(center, a) + _colourDistance(center, b)) * 0.5;

      final nearA = vertical
          ? image.getPixelSafe(sx - 2, sy)
          : image.getPixelSafe(sx, sy - 2);
      final nearB = vertical
          ? image.getPixelSafe(sx + 2, sy)
          : image.getPixelSafe(sx, sy + 2);
      final crossGradient = (_luma(nearA) - _luma(nearB)).abs();

      if (ridgeContrast >= 6.0 ||
          colourContrast >= 13.0 ||
          crossGradient >= 10.0) {
        return true;
      }
    }

    return false;
  }

  double _colourDistance(img.Pixel a, img.Pixel b) {
    final dr = a.r.toDouble() - b.r.toDouble();
    final dg = a.g.toDouble() - b.g.toDouble();
    final db = a.b.toDouble() - b.b.toDouble();
    return math.sqrt((dr * dr) + (dg * dg) + (db * db));
  }

  _PanelRowSample? _panelSpanForRow(
    img.Image image,
    int y, {
    required int leftSearch,
    required int rightSearch,
  }) {
    var bestLeft = -1;
    var bestRight = -1;
    var runLeft = -1;
    var misses = 0;

    bool panelLike(img.Pixel pixel) {
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      final luma = (r * 0.2126) + (g * 0.7152) + (b * 0.0722);
      final navyBias = b + 28 >= r && b + 24 >= g;
      return luma <= 92 && navyBias;
    }

    for (var x = leftSearch; x <= rightSearch; x += 2) {
      if (panelLike(image.getPixelSafe(x, y))) {
        if (runLeft < 0) runLeft = x;
        misses = 0;
      } else if (runLeft >= 0) {
        // Small bright gaps are often grid lines or reflections.
        misses += 1;
        if (misses > 4) {
          final runRight = x - (misses * 2);
          if (runRight - runLeft > bestRight - bestLeft) {
            bestLeft = runLeft;
            bestRight = runRight;
          }
          runLeft = -1;
          misses = 0;
        }
      }
    }

    if (runLeft >= 0) {
      final runRight = rightSearch;
      if (runRight - runLeft > bestRight - bestLeft) {
        bestLeft = runLeft;
        bestRight = runRight;
      }
    }

    if (bestLeft < 0 || bestRight <= bestLeft) return null;
    return _PanelRowSample(y: y, left: bestLeft, right: bestRight);
  }

  List<_PanelRowSample> _largestContiguousPanelGroup(
    List<_PanelRowSample> samples,
  ) {
    if (samples.isEmpty) return const <_PanelRowSample>[];
    final groups = <List<_PanelRowSample>>[];
    var current = <_PanelRowSample>[samples.first];

    for (var index = 1; index < samples.length; index++) {
      if (samples[index].y - current.last.y <= 9) {
        current.add(samples[index]);
      } else {
        groups.add(current);
        current = <_PanelRowSample>[samples[index]];
      }
    }
    groups.add(current);
    groups.sort((a, b) {
      final aScore =
          a.length * (a.map((e) => e.width).reduce((x, y) => x + y) / a.length);
      final bScore =
          b.length * (b.map((e) => e.width).reduce((x, y) => x + y) / b.length);
      return bScore.compareTo(aScore);
    });
    return groups.first;
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    values.sort();
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return values[middle];
    return (values[middle - 1] + values[middle]) / 2;
  }

  img.Image? _decode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } on Object {
      return null;
    }
  }

  List<double> _verticalEdgeProfile(img.Image image) {
    final startY = (image.height * 0.05).round();
    final endY = (image.height * 0.95).round();
    final profile = List<double>.filled(image.width, 0);

    for (var x = 1; x < image.width - 1; x++) {
      var gradient = 0.0;
      var contrast = 0.0;
      var count = 0;

      for (var y = startY; y < endY; y += 2) {
        final left = _luma(image.getPixelSafe(x - 1, y));
        final right = _luma(image.getPixelSafe(x + 1, y));
        final centre = _luma(image.getPixelSafe(x, y));

        gradient += (right - left).abs();
        contrast += ((centre - left).abs() + (centre - right).abs()) * 0.5;
        count++;
      }

      profile[x] = count == 0
          ? 0
          : ((gradient * 0.72) + (contrast * 0.28)) / count;
    }

    return _smooth(profile, radius: 2);
  }

  List<double> _horizontalEdgeProfile(img.Image image) {
    final startX = (image.width * 0.04).round();
    final endX = (image.width * 0.96).round();
    final profile = List<double>.filled(image.height, 0);

    for (var y = 1; y < image.height - 1; y++) {
      var gradient = 0.0;
      var contrast = 0.0;
      var count = 0;

      for (var x = startX; x < endX; x += 2) {
        final above = _luma(image.getPixelSafe(x, y - 1));
        final below = _luma(image.getPixelSafe(x, y + 1));
        final centre = _luma(image.getPixelSafe(x, y));

        gradient += (below - above).abs();
        contrast += ((centre - above).abs() + (centre - below).abs()) * 0.5;
        count++;
      }

      profile[y] = count == 0
          ? 0
          : ((gradient * 0.72) + (contrast * 0.28)) / count;
    }

    return _smooth(profile, radius: 2);
  }

  _AxisSegmentation? _findRegularGrid({
    required List<double> profile,
    required int expectedLines,
    required double minimumSpanFraction,
  }) {
    if (expectedLines < 2 || profile.length < expectedLines * 7) {
      return null;
    }

    final peaks = _candidatePeaks(profile);
    if (peaks.length < expectedLines) return null;

    final strongest = List<int>.from(peaks)
      ..sort((a, b) => profile[b].compareTo(profile[a]));
    final anchors = strongest.take(math.min(30, strongest.length)).toList();

    final minimumStep = math.max(6.0, profile.length * 0.025);
    final maximumStep = profile.length / (expectedLines - 1);

    _AxisSegmentation? best;

    for (final first in anchors) {
      for (final last in anchors) {
        if (last <= first) continue;

        final span = last - first;
        if (span < profile.length * minimumSpanFraction) continue;

        final step = span / (expectedLines - 1);
        if (step < minimumStep || step > maximumStep) continue;

        final radius = math.max(2, (step * 0.22).round());
        final positions = <int>[];
        final strengths = <double>[];

        var previous = -1;
        var valid = true;

        for (var line = 0; line < expectedLines; line++) {
          final expected = (first + (step * line)).round();
          final snapped = _nearestStrongPeak(profile, expected, radius);

          if (snapped == null || snapped <= previous) {
            valid = false;
            break;
          }

          positions.add(snapped);
          strengths.add(profile[snapped]);
          previous = snapped;
        }

        if (!valid || positions.toSet().length != expectedLines) continue;

        final spacingScore = _spacingRegularity(positions);
        final strengthScore = _relativeStrength(profile, strengths);
        final alignmentScore = _expectedAlignmentScore(
          positions,
          first: first,
          last: last,
        );
        final coverageScore =
            ((positions.last - positions.first) / profile.length).clamp(
              0.0,
              1.0,
            );

        final score =
            (spacingScore * 0.38) +
            (strengthScore * 0.34) +
            (alignmentScore * 0.20) +
            (coverageScore * 0.08);

        if (best == null || score > best.confidence) {
          best = _AxisSegmentation(
            positions: positions,
            confidence: score.clamp(0.0, 1.0),
          );
        }
      }
    }

    if (best == null || best.confidence < 0.42) return null;
    return best;
  }

  List<int> _candidatePeaks(List<double> profile) {
    final sorted = List<double>.from(profile)..sort();
    final median = sorted[sorted.length ~/ 2];
    final high = sorted[(sorted.length * 0.82).floor()];
    final threshold = median + ((high - median) * 0.42);

    final candidates = <int>[];

    for (var index = 2; index < profile.length - 2; index++) {
      final value = profile[index];
      if (value < threshold) continue;

      if (value >= profile[index - 1] &&
          value >= profile[index + 1] &&
          value >= profile[index - 2] &&
          value >= profile[index + 2]) {
        candidates.add(index);
      }
    }

    final collapsed = <int>[];
    for (final candidate in candidates) {
      if (collapsed.isEmpty || candidate - collapsed.last > 4) {
        collapsed.add(candidate);
      } else if (profile[candidate] > profile[collapsed.last]) {
        collapsed[collapsed.length - 1] = candidate;
      }
    }

    return collapsed;
  }

  int? _nearestStrongPeak(List<double> profile, int centre, int radius) {
    final start = (centre - radius).clamp(1, profile.length - 2);
    final end = (centre + radius).clamp(start + 1, profile.length - 1);

    var bestIndex = -1;
    var bestValue = -1.0;

    for (var index = start; index < end; index++) {
      if (profile[index] > bestValue) {
        bestValue = profile[index];
        bestIndex = index;
      }
    }

    if (bestIndex < 0) return null;

    final sorted = List<double>.from(profile)..sort();
    final median = sorted[sorted.length ~/ 2];
    final high = sorted[(sorted.length * 0.82).floor()];
    final minimum = median + ((high - median) * 0.28);

    return bestValue >= minimum ? bestIndex : null;
  }

  double _spacingRegularity(List<int> positions) {
    if (positions.length < 3) return 0;

    final gaps = <double>[
      for (var index = 1; index < positions.length; index++)
        (positions[index] - positions[index - 1]).toDouble(),
    ];

    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    if (mean <= 0) return 0;

    final variance =
        gaps
            .map((gap) => math.pow(gap - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        gaps.length;

    final coefficient = math.sqrt(variance) / mean;
    return (1 - (coefficient / 0.22)).clamp(0.0, 1.0);
  }

  double _expectedAlignmentScore(
    List<int> positions, {
    required int first,
    required int last,
  }) {
    final step = (last - first) / (positions.length - 1);
    if (step <= 0) return 0;

    var error = 0.0;
    for (var index = 0; index < positions.length; index++) {
      final expected = first + (step * index);
      error += (positions[index] - expected).abs() / step;
    }

    return (1 - ((error / positions.length) / 0.20)).clamp(0.0, 1.0);
  }

  double _relativeStrength(List<double> profile, List<double> strengths) {
    final sorted = List<double>.from(profile)..sort();
    final baseline = sorted[(sorted.length * 0.60).floor()];
    final upper = sorted[(sorted.length * 0.95).floor()];

    if (upper <= baseline) return 0;

    final average = strengths.reduce((a, b) => a + b) / strengths.length;

    return ((average - baseline) / (upper - baseline)).clamp(0.0, 1.0);
  }

  List<double> _smooth(List<double> source, {required int radius}) {
    final result = List<double>.filled(source.length, 0);

    for (var index = 0; index < source.length; index++) {
      var weighted = 0.0;
      var weights = 0.0;

      final start = math.max(0, index - radius);
      final end = math.min(source.length - 1, index + radius);

      for (var sample = start; sample <= end; sample++) {
        final distance = (sample - index).abs();
        final weight = (radius + 1 - distance).toDouble();
        weighted += source[sample] * weight;
        weights += weight;
      }

      result[index] = weights == 0 ? source[index] : weighted / weights;
    }

    return result;
  }

  double _combinedConfidence(double vertical, double horizontal) {
    final weaker = math.min(vertical, horizontal);
    final stronger = math.max(vertical, horizontal);
    return ((weaker * 0.76) + (stronger * 0.24)).clamp(0.0, 1.0);
  }

  double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);
}

class _AxisSegmentation {
  const _AxisSegmentation({required this.positions, required this.confidence});

  final List<int> positions;
  final double confidence;
}

class _InternalGridEvidence {
  const _InternalGridEvidence({
    required this.credibleVertical,
    required this.credibleHorizontal,
    required this.verticalRatio,
    required this.horizontalRatio,
  });

  final int credibleVertical;
  final int credibleHorizontal;
  final double verticalRatio;
  final double horizontalRatio;

  bool get isCredible {
    // At least three recurring vertical boundaries are required. Horizontal
    // evidence can compensate when glare removes additional verticals, but a
    // featureless rectangle can never satisfy this contract.
    if (credibleVertical >= 4) return true;
    return credibleVertical >= 3 &&
        credibleHorizontal >= 1 &&
        (verticalRatio >= 0.28 || horizontalRatio >= 0.25);
  }
}

class _PanelRowSample {
  const _PanelRowSample({
    required this.y,
    required this.left,
    required this.right,
  });
  final int y;
  final int left;
  final int right;
  int get width => right - left;
}
