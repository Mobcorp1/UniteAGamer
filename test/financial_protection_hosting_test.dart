import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/version_web_static_assets.dart';

void main() {
  test(
    'public assets get content identities, retain aliases and preserve page links',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'uag-financial-hosting-',
      );
      addTearDown(() => root.delete(recursive: true));
      await Directory('${root.path}/public-assets').create();
      final script = File('${root.path}/public-assets/entry.js');
      await script.writeAsString('console.log(1)');
      final html = File('${root.path}/index.html');
      const page =
          '<script src="/public-assets/entry.js"></script><a href="/app">App</a>';
      await html.writeAsString(page);
      await versionWebStaticAssets(root);
      final first = await html.readAsString();
      expect(first, matches(r'entry\.[a-f0-9]{64}\.js'));
      expect(first, contains('href="/app"'));
      expect(await script.exists(), isTrue);
      await versionWebStaticAssets(root);
      expect(await html.readAsString(), first);
      await script.writeAsString('console.log(2)');
      await html.writeAsString(page);
      await versionWebStaticAssets(root);
      expect(await html.readAsString(), isNot(first));
      final files = await Directory(
        '${root.path}/public-assets',
      ).list().toList();
      expect(files, hasLength(3));
    },
  );
  test(
    'immutable headers are restricted to content-addressed website JS/CSS',
    () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync()) as Map;
      final headers = config['hosting']['headers'] as List;
      final immutable = headers
          .where(
            (h) => (h['headers'] as List).any(
              (v) => '${v['value']}'.contains('immutable'),
            ),
          )
          .toList();
      expect(immutable, hasLength(1));
      expect(immutable.single['regex'], contains('[a-f0-9]{64}'));
      for (final name in [
        '/app.html',
        '/index.html',
        '/flutter_service_worker.js',
        '/firebase-messaging-sw.js',
        '/version.json',
        '/manifest.json',
      ]) {
        final row = headers.firstWhere((h) => h['source'] == name);
        expect(row['headers'][0]['value'], contains('no-cache'));
      }
    },
  );
}
