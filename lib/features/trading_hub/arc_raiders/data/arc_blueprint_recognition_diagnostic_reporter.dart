import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_recognition_diagnostics.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_recognition_diagnostic_compat.dart';

@immutable
class ArcBlueprintRecognitionDiagnosticSummary {
  const ArcBlueprintRecognitionDiagnosticSummary({
    required this.total,
    required this.owned,
    required this.missing,
    required this.uncertain,
    required this.averageConfidence,
    required this.averageOccupancyScore,
  });

  final int total;
  final int owned;
  final int missing;
  final int uncertain;
  final double averageConfidence;
  final double averageOccupancyScore;

  Map<String, Object> toJson() => <String, Object>{
    'total': total,
    'owned': owned,
    'missing': missing,
    'uncertain': uncertain,
    'averageConfidence': _round(averageConfidence),
    'averageOccupancyScore': _round(averageOccupancyScore),
  };

  static double _round(double value) =>
      (value.clamp(0.0, 1.0) * 10000).round() / 10000;
}

class ArcBlueprintRecognitionDiagnosticReporter {
  const ArcBlueprintRecognitionDiagnosticReporter();

  ArcBlueprintRecognitionDiagnosticSummary summarize(
    List<ArcBlueprintCellDiagnostic> diagnostics,
  ) {
    if (diagnostics.isEmpty) {
      return const ArcBlueprintRecognitionDiagnosticSummary(
        total: 0,
        owned: 0,
        missing: 0,
        uncertain: 0,
        averageConfidence: 0,
        averageOccupancyScore: 0,
      );
    }

    final owned = diagnostics.where((item) => item.isOwned).length;
    final missing = diagnostics.where((item) => item.isMissing).length;
    final uncertain = diagnostics.length - owned - missing;

    final confidence =
        diagnostics.map((item) => item.confidence).reduce((a, b) => a + b) /
        diagnostics.length;
    final occupancy =
        diagnostics.map((item) => item.occupancyScore).reduce((a, b) => a + b) /
        diagnostics.length;

    return ArcBlueprintRecognitionDiagnosticSummary(
      total: diagnostics.length,
      owned: owned,
      missing: missing,
      uncertain: uncertain,
      averageConfidence: confidence,
      averageOccupancyScore: occupancy,
    );
  }

  String toJsonReport({
    required String captureId,
    required List<ArcBlueprintCellDiagnostic> diagnostics,
  }) {
    final summary = summarize(diagnostics);

    final payload = <String, Object>{
      'captureId': captureId,
      'summary': summary.toJson(),
      'cells': diagnostics.map((item) => item.toJson()).toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String toCsv(List<ArcBlueprintCellDiagnostic> diagnostics) {
    final buffer = StringBuffer()
      ..writeln(
        'row,column,classification,occupancyScore,confidence,texture,edgeDensity,saturation,foregroundCoverage,luminanceRange,retryCount,reason',
      );

    for (final item in diagnostics) {
      buffer
        ..write(item.rowIndex + 1)
        ..write(',')
        ..write(item.columnIndex + 1)
        ..write(',')
        ..write(item.classificationLabel)
        ..write(',')
        ..write(item.occupancyScore.toStringAsFixed(4))
        ..write(',')
        ..write(item.confidence.toStringAsFixed(4))
        ..write(',')
        ..write(item.textureVote.toStringAsFixed(4))
        ..write(',')
        ..write(item.edgeVote.toStringAsFixed(4))
        ..write(',')
        ..write(item.colourVote.toStringAsFixed(4))
        ..write(',')
        ..write(item.foregroundVote.toStringAsFixed(4))
        ..write(',')
        ..write(item.silhouetteVote.toStringAsFixed(4))
        ..write(',')
        ..write(item.retryCount)
        ..write(',')
        ..writeln(_escapeCsv(item.reason));
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
