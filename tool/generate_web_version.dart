import 'dart:io';

import 'prepare_web_release.dart' as release;

Future<void> main(List<String> args) async {
  exitCode = await release.runPrepareWebRelease(args);
}
