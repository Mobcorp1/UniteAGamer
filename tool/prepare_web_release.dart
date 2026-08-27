import 'dart:convert';
import 'dart:io';

class WebReleaseMetadata {
  const WebReleaseMetadata({
    required this.buildId,
    required this.builtAt,
    required this.branch,
  });

  final String buildId;
  final String builtAt;
  final String branch;

  Map<String, Object> toJson() => <String, Object>{
    'buildId': buildId,
    'builtAt': builtAt,
    'branch': branch,
  };

  static WebReleaseMetadata fromJson(Map<String, Object?> json) {
    final buildId = (json['buildId'] as String?)?.trim() ?? '';
    final builtAt = (json['builtAt'] as String?)?.trim() ?? '';
    final branch = (json['branch'] as String?)?.trim() ?? '';

    if (buildId.isEmpty) {
      throw const FormatException('version.json buildId is empty.');
    }
    if (builtAt.isEmpty) {
      throw const FormatException('version.json builtAt is empty.');
    }
    final parsedBuiltAt = DateTime.tryParse(builtAt);
    if (parsedBuiltAt == null || !parsedBuiltAt.isUtc) {
      throw FormatException(
        'version.json builtAt is not UTC ISO-8601: $builtAt',
      );
    }
    if (branch.isEmpty) {
      throw const FormatException('version.json branch is empty.');
    }

    return WebReleaseMetadata(
      buildId: buildId,
      builtAt: builtAt,
      branch: branch,
    );
  }
}

class WebReleasePrepareOptions {
  const WebReleasePrepareOptions({
    required this.repoRoot,
    required this.outputPath,
    this.validateOnly = false,
    this.allowLocalFallback = false,
    this.expectedBuildId,
    this.requireBuildArtifacts = true,
  });

  final Directory repoRoot;
  final String outputPath;
  final bool validateOnly;
  final bool allowLocalFallback;
  final String? expectedBuildId;
  final bool requireBuildArtifacts;
}

Future<int> runPrepareWebRelease(List<String> args) async {
  try {
    final options = _parseArgs(args);
    final metadata = options.validateOnly
        ? await validateWebReleaseMetadataFile(
            File(_resolvePath(options.repoRoot, options.outputPath)),
            expectedBuildId: options.expectedBuildId,
          )
        : await prepareWebReleaseMetadata(options);
    _printMetadata(
      metadata,
      File(_resolvePath(options.repoRoot, options.outputPath)),
    );
    return 0;
  } catch (error) {
    stderr.writeln('UAG web release metadata failed: $error');
    return 1;
  }
}

Future<WebReleaseMetadata> prepareWebReleaseMetadata(
  WebReleasePrepareOptions options,
) async {
  final buildWeb = Directory(_resolvePath(options.repoRoot, 'build/web'));
  final mainDartJs = File(
    _resolvePath(options.repoRoot, 'build/web/main.dart.js'),
  );

  if (options.requireBuildArtifacts) {
    if (!await buildWeb.exists()) {
      throw StateError(
        'Required build directory does not exist: ${buildWeb.path}',
      );
    }
    if (!await mainDartJs.exists()) {
      throw StateError(
        'Required Flutter web entrypoint does not exist: ${mainDartJs.path}',
      );
    }
  }

  final buildId = await _resolveGitValue(
    options.repoRoot,
    const <String>['rev-parse', 'HEAD'],
    allowLocalFallback: options.allowLocalFallback,
    fallback: 'local-${DateTime.now().toUtc().millisecondsSinceEpoch}',
    valueName: 'Git HEAD',
  );
  final branch = await _resolveGitValue(
    options.repoRoot,
    const <String>['branch', '--show-current'],
    allowLocalFallback: true,
    fallback: 'detached',
    valueName: 'Git branch',
  );
  final builtAt = DateTime.now().toUtc().toIso8601String();

  final metadata = WebReleaseMetadata(
    buildId: buildId,
    builtAt: builtAt,
    branch: branch,
  );

  final outputFile = File(_resolvePath(options.repoRoot, options.outputPath));
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(metadata.toJson())}\n',
    flush: true,
  );

  return validateWebReleaseMetadataFile(
    outputFile,
    expectedBuildId: options.expectedBuildId ?? buildId,
  );
}

Future<WebReleaseMetadata> validateWebReleaseMetadataFile(
  File versionFile, {
  String? expectedBuildId,
}) async {
  if (!await versionFile.exists()) {
    throw StateError('version.json does not exist: ${versionFile.path}');
  }

  final raw = await versionFile.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('version.json must contain a JSON object.');
  }

  final metadata = WebReleaseMetadata.fromJson(decoded);
  final expected = expectedBuildId?.trim();
  if (expected != null && expected.isNotEmpty && metadata.buildId != expected) {
    throw StateError(
      'version.json buildId does not match expected build. '
      'Expected $expected, got ${metadata.buildId}.',
    );
  }

  return metadata;
}

WebReleasePrepareOptions _parseArgs(List<String> args) {
  var repoRoot = Directory.current;
  var outputPath = 'build/web/version.json';
  var validateOnly = false;
  var allowLocalFallback = false;
  String? expectedBuildId;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String nextValue(String flag) {
      if (i + 1 >= args.length) {
        throw FormatException('$flag requires a value.');
      }
      return args[++i];
    }

    switch (arg) {
      case '--repo':
        repoRoot = Directory(nextValue(arg));
      case '--output':
        outputPath = nextValue(arg);
      case '--validate-only':
        validateOnly = true;
        if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          outputPath = args[++i];
        }
      case '--expected-build-id':
        expectedBuildId = nextValue(arg);
      case '--allow-local-fallback':
        allowLocalFallback = true;
      case '--help':
      case '-h':
        throw const FormatException(_usage);
      default:
        throw FormatException('Unknown argument: $arg\n$_usage');
    }
  }

  return WebReleasePrepareOptions(
    repoRoot: repoRoot,
    outputPath: outputPath,
    validateOnly: validateOnly,
    allowLocalFallback: allowLocalFallback,
    expectedBuildId: expectedBuildId,
  );
}

Future<String> _resolveGitValue(
  Directory repoRoot,
  List<String> args, {
  required bool allowLocalFallback,
  required String fallback,
  required String valueName,
}) async {
  final result = await Process.run('git', <String>[
    '-C',
    repoRoot.path,
    ...args,
  ], runInShell: Platform.isWindows);
  final value = result.stdout.toString().trim();
  if (result.exitCode == 0 && value.isNotEmpty) return value;
  if (allowLocalFallback) return fallback;

  final stderrText = result.stderr.toString().trim();
  throw StateError(
    'Unable to resolve $valueName. '
    '${stderrText.isEmpty ? 'git ${args.join(' ')} failed.' : stderrText}',
  );
}

String _resolvePath(Directory repoRoot, String path) {
  if (path.trim().isEmpty) {
    throw const FormatException('Output path cannot be empty.');
  }
  if (_isAbsolutePath(path)) return path;
  return '${repoRoot.path}${Platform.pathSeparator}$path';
}

bool _isAbsolutePath(String path) {
  if (Platform.isWindows) {
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
  }
  return path.startsWith('/');
}

void _printMetadata(WebReleaseMetadata metadata, File versionFile) {
  stdout.writeln('Build ID: ${metadata.buildId}');
  stdout.writeln('Branch: ${metadata.branch}');
  stdout.writeln('Built At: ${metadata.builtAt}');
  stdout.writeln('Version file path: ${versionFile.path}');
}

const _usage = '''
Usage:
  dart run tool/prepare_web_release.dart --output build/web/version.json
  dart run tool/prepare_web_release.dart --validate-only build/web/version.json

Options:
  --repo <path>              Repository root. Defaults to current directory.
  --output <path>            version.json output path.
  --validate-only [path]     Validate an existing version file.
  --expected-build-id <sha>  Require a specific buildId.
  --allow-local-fallback     Allow non-Git local build IDs.
''';

Future<void> main(List<String> args) async {
  exitCode = await runPrepareWebRelease(args);
}
