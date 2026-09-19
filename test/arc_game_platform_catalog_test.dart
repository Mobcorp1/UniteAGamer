import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_game_platform_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';

void main() {
  group('ArcGamePlatformCatalog', () {
    test('normalises common player platform labels', () {
      expect(
        ArcGamePlatformCatalog.normalize(const <String>[
          'PS5',
          'Steam',
          'Xbox',
        ]),
        const <String>['PlayStation', 'PC', 'Xbox'],
      );
    });

    test('keeps only supported platforms and preserves order', () {
      expect(
        ArcGamePlatformCatalog.normalize(const <String>[
          'PlayStation',
          'PlayStation 5',
          'Switch',
          'PC',
        ]),
        const <String>['PlayStation', 'PC'],
      );
    });

    test('legacy single platform populates the structured profile view', () {
      final profile = ArcTraderProfile.fromMap(const <String, dynamic>{
        'platform': 'PS5',
      });

      expect(profile.primaryPlatform, 'PlayStation');
      expect(profile.normalisedPlatforms, const <String>['PlayStation']);
    });
  });
}
