import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_recognition_diagnostic_reporter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_recognition_diagnostics.dart';

ArcBlueprintCellDiagnostic diagnostic({
  required int row,
  required int column,
  required double score,
  double confidence = 0.9,
  double texture = 0.2,
  double edges = 0.2,
  double colour = 0.2,
  double foreground = 0.2,
  double range = 0.2,
  int retries = 0,
}) {
  return ArcBlueprintCellDiagnostic(
    rowIndex: row,
    columnIndex: column,
    occupancyScore: score,
    confidence: confidence,
    textureVote: texture,
    edgeVote: edges,
    colourVote: colour,
    foregroundVote: foreground,
    silhouetteVote: range,
    retryCount: retries,
  );
}

void main() {
  test('summarizes owned missing and uncertain classifications', () {
    final summary = const ArcBlueprintRecognitionDiagnosticReporter()
        .summarize(<ArcBlueprintCellDiagnostic>[
          diagnostic(
            row: 0,
            column: 0,
            score: 0.90,
            foreground: 0.40,
            colour: 0.30,
          ),
          diagnostic(
            row: 0,
            column: 1,
            score: 0.10,
            texture: 0.05,
            edges: 0.05,
            colour: 0.05,
            foreground: 0.05,
            range: 0.05,
          ),
          diagnostic(
            row: 0,
            column: 2,
            score: 0.50,
            confidence: 0.55,
            retries: 9,
          ),
        ]);

    expect(summary.total, 3);
    expect(summary.owned, 1);
    expect(summary.missing, 1);
    expect(summary.uncertain, 1);
  });

  test('JSON report contains every per-cell signal and reason', () {
    final report = const ArcBlueprintRecognitionDiagnosticReporter()
        .toJsonReport(
          captureId: 'top',
          diagnostics: <ArcBlueprintCellDiagnostic>[
            diagnostic(
              row: 2,
              column: 4,
              score: 0.88,
              foreground: 0.42,
              colour: 0.31,
              retries: 9,
            ),
          ],
        );

    final decoded = jsonDecode(report) as Map<String, dynamic>;
    expect(decoded['captureId'], 'top');

    final cells = decoded['cells'] as List<dynamic>;
    expect(cells, hasLength(1));

    final cell = cells.single as Map<String, dynamic>;
    expect(cell['row'], 3);
    expect(cell['column'], 5);
    expect(cell['classification'], 'owned');
    expect(cell['reason'], isNotEmpty);
    expect(cell.containsKey('foregroundCoverage'), isTrue);
    expect(cell.containsKey('retryCount'), isTrue);
  });

  test('CSV report is one row per diagnostic cell', () {
    final csv = const ArcBlueprintRecognitionDiagnosticReporter().toCsv(
      <ArcBlueprintCellDiagnostic>[
        diagnostic(row: 0, column: 0, score: 0.90),
        diagnostic(row: 0, column: 1, score: 0.12),
      ],
    );

    final lines = csv.trim().split('\n');
    expect(lines, hasLength(3));
    expect(lines.first, contains('classification'));
    expect(lines[1], contains('owned'));
    expect(lines[2], contains('missing'));
  });
}
