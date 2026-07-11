import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';

void main() {
  group('ArcPlayerArchetypeCatalog', () {
    test('includes Rat Hunter with aliases and description', () {
      expect(ArcPlayerArchetypeCatalog.labels, contains('Rat Hunter'));

      final normalized = ArcPlayerArchetypeCatalog.normalizeLabels(
        const <String>['rat hunter', 'Camper hunter', 'Rat Hunter'],
      );

      expect(normalized, const <String>['Rat Hunter']);
      expect(
        ArcPlayerArchetypeCatalog.descriptionFor('Rat Hunter'),
        contains('ambushers'),
      );
    });

    test('normalizes legacy onboarding values', () {
      final normalized = ArcPlayerArchetypeCatalog.normalizeLabels(
        const <String>['Balanced', 'Blueprint grinder', 'PvP hunter'],
      );

      expect(normalized, const <String>[
        'Balanced Raider',
        'Blueprint Grinder',
        'PvP Hunter',
      ]);
    });
  });

  group('ArcTraderProfile archetype mapping', () {
    test('serializes Rat Hunter without losing match-fit fields', () {
      final profile = ArcTraderProfile.empty('raider-1').copyWith(
        archetypes: const <String>['rat hunter'],
        playStyles: const <String>['PvP focused'],
        communicationStyle: 'Pings',
        squadIntent: 'Blueprint runs',
        socialEnergy: 'Quiet but cooperative',
      );

      final map = profile.toMap();

      expect(map['archetypes'], const <String>['Rat Hunter']);
      expect(map['playStyles'], const <String>['PvP focused']);
      expect(map['communicationStyle'], 'Pings');
      expect(map['squadIntent'], 'Blueprint runs');
      expect(map['socialEnergy'], 'Quiet but cooperative');
    });

    test('reads legacy playStyle as a fallback archetype', () {
      final profile = ArcTraderProfile.fromMap(const {
        'uid': 'raider-2',
        'playStyle': 'PvP hunter',
      });

      expect(profile.archetypes, contains('PvP Hunter'));
      expect(profile.playStyles, const <String>['PvP hunter']);
    });
  });
}
