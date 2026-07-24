import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final outputArgIndex = args.indexOf('--output');
  final outputPath = outputArgIndex >= 0 && outputArgIndex + 1 < args.length
      ? args[outputArgIndex + 1]
      : null;

  if (outputPath == null || outputPath.trim().isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/generate_web_version.dart --output <path>',
    );
    exitCode = 64;
    return;
  }

  final buildId = Platform.environment['UAG_BUILD_ID']?.trim();
  final builtAt = Platform.environment['UAG_BUILT_AT']?.trim();
  final branch = Platform.environment['UAG_BRANCH']?.trim();

  final resolvedBuildId = buildId != null && buildId.isNotEmpty
      ? buildId
      : 'local-${DateTime.now().toUtc().millisecondsSinceEpoch}';
  final resolvedBuiltAt = builtAt != null && builtAt.isNotEmpty
      ? builtAt
      : DateTime.now().toUtc().toIso8601String();
  final resolvedBranch = branch != null && branch.isNotEmpty ? branch : 'local';

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'buildId': resolvedBuildId,
      'builtAt': resolvedBuiltAt,
      'branch': resolvedBranch,
    }),
    flush: true,
  );
}
