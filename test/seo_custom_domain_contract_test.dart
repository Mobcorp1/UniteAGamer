import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const canonicalHost = 'https://uniteagamer.com';
  const legacyHost = 'https://unite-a-gamer.web.app';
  const sitePaths = <String>[
    '/',
    '/guides/',
    '/guides/blueprint-tracking/',
    '/guides/raid-planning/',
    '/guides/favourite-loadout/',
    '/guides/safer-trading/',
    '/about/',
    '/support',
    '/privacy',
    '/terms',
    '/subscriptions-refunds',
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

  String sourcePath(String urlPath) {
    if (urlPath == '/') return 'web/index.html';
    if (const <String>{
      '/privacy',
      '/terms',
      '/support',
      '/subscriptions-refunds',
    }.contains(urlPath)) {
      return 'web$urlPath.html';
    }
    return 'web${urlPath}index.html';
  }

  test('all 27 URLs point to verified custom domain', () {
    final sitemap = File('web/sitemap.xml').readAsStringSync();
    final locs = RegExp(
      r'<loc>([^<]+)</loc>',
    ).allMatches(sitemap).map((match) => match.group(1)!).toList();
    expect(locs.length, 27);
    expect(locs.toSet().length, 27);
    expect(locs, sitePaths.map((p) => '$canonicalHost$p').toList());
    expect(sitemap, isNot(contains(legacyHost)));
    final robots = File('web/robots.txt').readAsStringSync();
    expect(robots, contains('Sitemap: $canonicalHost/sitemap.xml'));
    expect(robots, isNot(contains(legacyHost)));
  });

  test('every public SEO page has its own custom-domain canonical', () {
    for (final path in sitePaths) {
      final file = File(sourcePath(path));
      expect(file.existsSync(), isTrue, reason: 'Missing page for $path');
      final html = file.readAsStringSync();
      expect(
        html,
        contains('rel="canonical" href="$canonicalHost$path"'),
        reason: 'Wrong canonical for $path',
      );
      expect(
        html,
        isNot(contains(legacyHost)),
        reason: 'Legacy SEO host remains in $path',
      );
    }
  });

  test('Google-visible metadata aligns with canonical host', () {
    for (final path in sitePaths) {
      final html = File(sourcePath(path)).readAsStringSync();
      expect(html, contains('$canonicalHost$path'));
      if (const <String>{
        '/privacy',
        '/terms',
        '/support',
        '/subscriptions-refunds',
      }.contains(path)) {
        continue; // Legal/support pages have their own established metadata.
      }
      // Existing policy/support pages have canonical tags but do not yet
      // carry the article metadata used by landing pages. Do not expand
      // PASS 12C beyond its host-only migration boundary.
      if (!const <String>{
        '/privacy',
        '/terms',
        '/support',
        '/subscriptions-refunds',
      }.contains(path)) {
        expect(html, contains('name="description"'));
        expect(html, contains('application/ld+json'));
      }
    }
  });

  test('app shell, login routes and Firebase Hosting are preserved', () {
    final app = File('web/app.html').readAsStringSync();
    expect(app, contains('noindex,follow'));
    final firebase = File('firebase.json').readAsStringSync();
    expect(firebase, contains('"destination": "/app.html"'));
    expect(
      firebase,
      contains('!/@(guides|about|public-assets|tools|maps){,/**}'),
    );
    expect(File('web/public-assets/entry.js').existsSync(), isTrue);
    expect(File('web/public-assets/app-entry.js').existsSync(), isTrue);
  });
}
