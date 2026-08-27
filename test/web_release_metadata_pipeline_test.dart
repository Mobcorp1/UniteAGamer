import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/prepare_web_release.dart';

void main() {
  group('UAG web release metadata pipeline', () {
    test('prepares and validates Git-backed release metadata', () async {
      final repo = await _createGitRepository();
      addTearDown(() => repo.deleteSync(recursive: true));
      await File('${repo.path}/build/web/main.dart.js').create(recursive: true);

      final metadata = await prepareWebReleaseMetadata(
        WebReleasePrepareOptions(
          repoRoot: repo,
          outputPath: 'build/web/nested/version.json',
        ),
      );
      final head = _git(repo, const <String>['rev-parse', 'HEAD']);
      final versionFile = File('${repo.path}/build/web/nested/version.json');
      final payload =
          jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;

      expect(versionFile.existsSync(), isTrue);
      expect(metadata.buildId, head);
      expect(payload['buildId'], head);
      expect(payload['buildId'], isNotEmpty);
      expect(payload['builtAt'], isNotEmpty);
      expect(DateTime.parse(payload['builtAt'] as String).isUtc, isTrue);
      expect(payload['branch'], 'release-test');
    });

    test('invalid metadata fails validation', () async {
      final directory = await Directory.systemTemp.createTemp(
        'uag-version-bad-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final versionFile = File(
        '${directory.path}/version.json',
      )..writeAsStringSync('{"buildId":"","builtAt":"not-a-date","branch":""}');

      await expectLater(
        validateWebReleaseMetadataFile(versionFile),
        throwsA(isA<FormatException>()),
      );

      versionFile.writeAsStringSync(
        '{"buildId":"abc123","builtAt":"2026-08-27T12:00:00","branch":"main"}',
      );
      await expectLater(
        validateWebReleaseMetadataFile(versionFile),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'tool exits non-zero when required Git identity cannot be resolved',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'uag-version-nogit-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        await File(
          '${directory.path}/build/web/main.dart.js',
        ).create(recursive: true);

        final exitCode = await runPrepareWebRelease(<String>[
          '--repo',
          directory.path,
          '--output',
          'build/web/version.json',
        ]);

        expect(exitCode, isNot(0));
        expect(
          File('${directory.path}/build/web/version.json').existsSync(),
          isFalse,
        );
      },
    );

    test('Firebase Hosting predeploy references the canonical Dart tool', () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync())
              as Map<String, dynamic>;
      final hosting = config['hosting'] as Map<String, dynamic>;
      final predeploy = (hosting['predeploy'] as List).cast<String>();

      expect(predeploy, hasLength(1));
      expect(
        predeploy.single,
        'dart run tool/prepare_web_release.dart --output build/web/version.json',
      );
    });

    test('release scripts share the canonical metadata tool', () {
      final webRelease = File(
        'scripts/deploy_web_release.ps1',
      ).readAsStringSync();
      final candidate = File(
        'scripts/deploy_release_candidate.ps1',
      ).readAsStringSync();

      for (final script in <String>[webRelease, candidate]) {
        expect(script, contains('tool/prepare_web_release.dart'));
        expect(script, contains('--validate-only'));
        expect(script, contains('Build ID:'));
        expect(script, contains('Branch:'));
        expect(script, contains('Built At:'));
        expect(script, contains('Version file path:'));
        expect(script, isNot(contains('write_web_release_metadata.ps1')));
      }
    });

    test(
      'release candidate cannot deploy Hosting before metadata preparation',
      () {
        final candidate = File(
          'scripts/deploy_release_candidate.ps1',
        ).readAsStringSync();
        final metadataIndex = candidate.indexOf(
          'Prepare web release metadata before Hosting deploy',
        );
        final deployIndex = candidate.indexOf('firebase deploy --only hosting');

        expect(metadataIndex, greaterThanOrEqualTo(0));
        expect(deployIndex, greaterThanOrEqualTo(0));
        expect(metadataIndex, lessThan(deployIndex));
        expect(
          candidate,
          contains('test/arc_companion_bottom_dock_layout_test.dart'),
        );
        expect(
          candidate,
          contains('test/blueprint_grid_screen_regression_test.dart'),
        );
      },
    );

    test(
      'production script supports explicit non-production branch deployments',
      () {
        final webRelease = File(
          'scripts/deploy_web_release.ps1',
        ).readAsStringSync();

        expect(webRelease, contains(r'$ExpectedBranch = "beta-stabilisation"'));
        expect(webRelease, contains('AllowNonProductionBranch'));
        expect(webRelease, contains('Test-LiveVersionJson'));
        expect(webRelease, contains('Live version.json verified'));
      },
    );

    test('updater rejects malformed metadata with throttled diagnostics', () {
      final updater = File('web/uag_update_manager.js').readAsStringSync();

      expect(
        updater,
        contains('version.json does not contain a valid buildId'),
      );
      expect(
        updater,
        contains('version.json does not contain a valid UTC builtAt'),
      );
      expect(updater, contains('validateVersionPayload'));
      expect(updater, contains('uagVersionDiagnostics'));
      expect(updater, contains('ERROR_LOG_COOLDOWN_MS'));
      expect(updater, contains('reason'));
      expect(updater, contains('payload'));
      expect(updater, isNot(contains(r'local-${DateTime.now()')));
    });
  });
}

Future<Directory> _createGitRepository() async {
  final repo = await Directory.systemTemp.createTemp('uag-version-git-');
  _git(repo, const <String>['init']);
  _git(repo, const <String>['config', 'user.email', 'test@example.com']);
  _git(repo, const <String>['config', 'user.name', 'UAG Test']);
  File('${repo.path}/README.md').writeAsStringSync('release test\n');
  _git(repo, const <String>['add', 'README.md']);
  _git(repo, const <String>['commit', '-m', 'initial']);
  _git(repo, const <String>['checkout', '-b', 'release-test']);
  return repo;
}

String _git(Directory repo, List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: repo.path,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed: ${result.stderr}\n${result.stdout}',
    );
  }
  return result.stdout.toString().trim();
}
