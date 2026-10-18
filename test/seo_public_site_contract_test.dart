import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const host = 'https://unite-a-gamer.web.app';
  const publicPaths = <String>[
    '/tools/',
    '/tools/blueprint-tracker/',
    '/tools/trading-hub/',
    '/tools/crafting-planner/',
    '/tools/raid-planner/',
    '/tools/favourite-loadout/',
    '/tools/bench-tracker/',
    '/maps/',
    '/guides/frozen-trail-upgrades/',
    '/guides/research-station/',
    '/guides/outpost-upgrades/',
    '/guides/gunsmith-level-4/',
    '/guides/amplification-modules/',
    '/guides/bantam-stiletto/',
    '/guides/arc-couplers/',
    '/guides/hand-drill/',
  ];

  test('new landing pages are accessible HTML with unique metadata', () {
    final titles = <String>{};
    for (final path in publicPaths) {
      final file = File('web${path}index.html');
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final html = file.readAsStringSync();
      final title = RegExp(
        r'<title>([^<]+)</title>',
      ).firstMatch(html)?.group(1);
      expect(title, isNotNull, reason: '$path has no title');
      expect(titles.add(title!), isTrue, reason: 'Duplicate title for $path');
      expect(html, contains('<h1>'), reason: 'Missing H1 in $path');
      expect(html, contains('name="description"'));
      expect(html, contains('name="robots" content="index,follow'));
      expect(html, contains('rel="canonical" href="$host$path"'));
      expect(html, contains('application/ld+json'));
      expect(html, contains('BreadcrumbList'));
      expect(html, contains('href="/app.html'));
      expect(html, contains('id="main"'));
      expect(html, contains('MobCorp Limited'));
      expect(html, contains('Independent, unofficial fan-made companion'));
      expect(html, contains('google-adsense-account'));
      expect(html, isNot(contains('TODO')));
    }
  });

  test('structured data is valid JSON and URL canonical matches page', () {
    for (final path in publicPaths) {
      final html = File('web${path}index.html').readAsStringSync();
      final jsonText = RegExp(
        r'<script type="application/ld\+json">(.*?)</script>',
        dotAll: true,
      ).firstMatch(html)?.group(1);
      expect(jsonText, isNotNull, reason: 'No schema in $path');
      final structuredData = jsonDecode(jsonText!) as Map<String, dynamic>;
      expect(structuredData['@context'], 'https://schema.org');
      final graph = structuredData['@graph'] as List<dynamic>;
      expect((graph.first as Map<String, dynamic>)['url'], '$host$path');
    }
  });

  test(
    'sitemap lists all new URLs once and preserves existing public URLs',
    () {
      final sitemap = File('web/sitemap.xml').readAsStringSync();
      expect(sitemap, contains('<urlset'));
      for (final path in publicPaths) {
        expect(
          RegExp(
            RegExp.escape('<loc>$host$path</loc>'),
          ).allMatches(sitemap).length,
          1,
          reason: 'Sitemap must include $path exactly once',
        );
      }
      for (final path in <String>[
        '/',
        '/about/',
        '/guides/',
        '/support',
        '/privacy',
        '/terms',
      ]) {
        expect(sitemap, contains('<loc>$host$path</loc>'));
      }
      expect(
        File('web/robots.txt').readAsStringSync(),
        contains('Sitemap: $host/sitemap.xml'),
      );
    },
  );

  test('static SEO routes cannot be swallowed by Flutter SPA catchall', () {
    final firebase = File('firebase.json').readAsStringSync();
    expect(
      firebase,
      contains('!/@(guides|about|public-assets|tools|maps){,/**}'),
    );
    expect(firebase, contains('"destination": "/app.html"'));
    expect(File('web/app.html').readAsStringSync(), contains('noindex,follow'));
    expect(
      File('web/index.html').readAsStringSync(),
      contains('href="/tools/'),
    );
    expect(
      File('web/guides/index.html').readAsStringSync(),
      contains('href="/guides/research-station/'),
    );
    expect(File('web/public-assets/seo.css').existsSync(), isTrue);
  });
}
