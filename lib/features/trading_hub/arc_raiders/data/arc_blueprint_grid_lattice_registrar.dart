import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

@immutable
class ArcBlueprintGridLatticeRegistration {
  const ArcBlueprintGridLatticeRegistration({
    required this.imageBytes,
    required this.refined,
    required this.horizontalConfidence,
    required this.verticalConfidence,
  });

  final Uint8List imageBytes;
  final bool refined;
  final double horizontalConfidence;
  final double verticalConfidence;
}

class ArcBlueprintGridLatticeRegistrar {
  const ArcBlueprintGridLatticeRegistrar({
    this.minimumImprovement = 1.08,
    this.minimumRetainedSpan = 0.86,
    this.maximumStartFraction = 0.10,
  });

  final double minimumImprovement;
  final double minimumRetainedSpan;
  final double maximumStartFraction;

  ArcBlueprintGridLatticeRegistration register({
    required Uint8List bytes,
    required int columns,
    required int rows,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || columns <= 0 || rows <= 0) {
      throw const FormatException(
        'The Blueprint grid image could not be registered.',
      );
    }

    final image = img.bakeOrientation(decoded);
    final verticalEnergy = _verticalEdgeEnergy(image);
    final horizontalEnergy = _horizontalEdgeEnergy(image);

    final xFit = _fitAxis(
      verticalEnergy,
      divisions: columns,
      dimension: image.width,
    );
    final yFit = _fitAxis(
      horizontalEnergy,
      divisions: rows,
      dimension: image.height,
    );

    final refineX = xFit.improvement >= minimumImprovement;
    final refineY = yFit.improvement >= minimumImprovement;

    final left = refineX ? xFit.start.round() : 0;
    final right = refineX ? xFit.end.round() : image.width - 1;
    final top = refineY ? yFit.start.round() : 0;
    final bottom = refineY ? yFit.end.round() : image.height - 1;

    final width = math.max(2, right - left + 1);
    final height = math.max(2, bottom - top + 1);

    final retainedX = width / image.width;
    final retainedY = height / image.height;

    final safeRefineX = refineX && retainedX >= minimumRetainedSpan;
    final safeRefineY = refineY && retainedY >= minimumRetainedSpan;

    final cropLeft = safeRefineX ? left : 0;
    final cropRight = safeRefineX ? right : image.width - 1;
    final cropTop = safeRefineY ? top : 0;
    final cropBottom = safeRefineY ? bottom : image.height - 1;

    final crop = img.copyCrop(
      image,
      x: cropLeft,
      y: cropTop,
      width: cropRight - cropLeft + 1,
      height: cropBottom - cropTop + 1,
    );

    final normalized = img.copyResize(
      crop,
      width: columns * 100,
      height: rows * 100,
      interpolation: img.Interpolation.cubic,
    );

    if (kDebugMode) {
      debugPrint(
        'ARC GRID REGISTER: '
        '${columns}x$rows '
        'xImprovement=${xFit.improvement.toStringAsFixed(3)} '
        'yImprovement=${yFit.improvement.toStringAsFixed(3)} '
        'xRefined=$safeRefineX yRefined=$safeRefineY '
        'crop=$cropLeft,$cropTop..$cropRight,$cropBottom',
      );
    }

    return ArcBlueprintGridLatticeRegistration(
      imageBytes: Uint8List.fromList(img.encodeJpg(normalized, quality: 96)),
      refined: safeRefineX || safeRefineY,
      horizontalConfidence: xFit.confidence,
      verticalConfidence: yFit.confidence,
    );
  }

  List<double> _verticalEdgeEnergy(img.Image image) {
    final energy = List<double>.filled(image.width, 0);
    final yStart = (image.height * 0.04).round();
    final yEnd = (image.height * 0.96).round();
    final step = math.max(1, image.height ~/ 220);

    for (var x = 1; x < image.width - 1; x++) {
      var total = 0.0;
      var count = 0;
      for (var y = yStart; y < yEnd; y += step) {
        final a = _luma(image.getPixelSafe(x - 1, y));
        final b = _luma(image.getPixelSafe(x + 1, y));
        total += (a - b).abs();
        count++;
      }
      energy[x] = count == 0 ? 0 : total / count;
    }
    return _smooth(energy, radius: 2);
  }

  List<double> _horizontalEdgeEnergy(img.Image image) {
    final energy = List<double>.filled(image.height, 0);
    final xStart = (image.width * 0.03).round();
    final xEnd = (image.width * 0.97).round();
    final step = math.max(1, image.width ~/ 260);

    for (var y = 1; y < image.height - 1; y++) {
      var total = 0.0;
      var count = 0;
      for (var x = xStart; x < xEnd; x += step) {
        final a = _luma(image.getPixelSafe(x, y - 1));
        final b = _luma(image.getPixelSafe(x, y + 1));
        total += (a - b).abs();
        count++;
      }
      energy[y] = count == 0 ? 0 : total / count;
    }
    return _smooth(energy, radius: 2);
  }

  _AxisFit _fitAxis(
    List<double> energy, {
    required int divisions,
    required int dimension,
  }) {
    final nominalPitch = (dimension - 1) / divisions;
    final nominal = _scoreLattice(
      energy,
      start: 0,
      pitch: nominalPitch,
      divisions: divisions,
    );

    var bestScore = nominal;
    var bestStart = 0.0;
    var bestPitch = nominalPitch;

    final maxStart = dimension * maximumStartFraction;
    for (var scale = 0.90; scale <= 1.02; scale += 0.005) {
      final pitch = nominalPitch * scale;
      final span = pitch * divisions;
      if (span < dimension * minimumRetainedSpan || span > dimension - 1) {
        continue;
      }

      final maximumAllowedStart = math.min(maxStart, dimension - 1 - span);

      for (var start = 0.0; start <= maximumAllowedStart; start += 1.5) {
        final score = _scoreLattice(
          energy,
          start: start,
          pitch: pitch,
          divisions: divisions,
        );
        if (score > bestScore) {
          bestScore = score;
          bestStart = start;
          bestPitch = pitch;
        }
      }
    }

    final sorted = List<double>.from(energy)..sort();
    final median = sorted.isEmpty ? 0.0 : sorted[sorted.length ~/ 2];
    final high = sorted.isEmpty ? 0.0 : sorted[(sorted.length * 0.90).floor()];
    final confidence = high <= median + 0.001
        ? 0.0
        : ((bestScore - median) / (high - median)).clamp(0.0, 1.0);

    return _AxisFit(
      start: bestStart,
      end: bestStart + (bestPitch * divisions),
      improvement: nominal <= 0.001 ? 1.0 : bestScore / nominal,
      confidence: confidence.toDouble(),
    );
  }

  double _scoreLattice(
    List<double> energy, {
    required double start,
    required double pitch,
    required int divisions,
  }) {
    var total = 0.0;
    var weightTotal = 0.0;
    final radius = math.max(2, (pitch * 0.035).round());

    for (var index = 0; index <= divisions; index++) {
      final position = (start + pitch * index).round();
      if (position < 0 || position >= energy.length) return 0;

      var localPeak = 0.0;
      for (var offset = -radius; offset <= radius; offset++) {
        final sample = position + offset;
        if (sample < 0 || sample >= energy.length) continue;
        localPeak = math.max(localPeak, energy[sample]);
      }

      final weight = (index == 0 || index == divisions) ? 0.55 : 1.0;
      total += localPeak * weight;
      weightTotal += weight;
    }

    return weightTotal <= 0 ? 0 : total / weightTotal;
  }

  List<double> _smooth(List<double> source, {required int radius}) {
    if (source.isEmpty || radius <= 0) return source;
    final output = List<double>.filled(source.length, 0);

    for (var index = 0; index < source.length; index++) {
      var total = 0.0;
      var count = 0;
      for (var offset = -radius; offset <= radius; offset++) {
        final sample = index + offset;
        if (sample < 0 || sample >= source.length) continue;
        total += source[sample];
        count++;
      }
      output[index] = count == 0 ? source[index] : total / count;
    }
    return output;
  }

  double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);
}

@immutable
class _AxisFit {
  const _AxisFit({
    required this.start,
    required this.end,
    required this.improvement,
    required this.confidence,
  });

  final double start;
  final double end;
  final double improvement;
  final double confidence;
}
