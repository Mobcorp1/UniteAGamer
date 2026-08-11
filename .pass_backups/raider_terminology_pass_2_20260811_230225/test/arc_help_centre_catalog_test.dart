import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_help_centre_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';

void main() {
  group('ArcHelpCentreCatalog', () {
    test('defines the required unique categories', () {
      const expected = [
        'Getting Started',
        'Blueprint Tracker',
        'Favourite Loadout',
        'Trading',
        'Match Rider',
        'Operations',
        'Profile and Reputation',
        'Privacy, Safety and Reporting',
        'Closed Beta Feedback',
      ];

      expect(
        ArcHelpCentreCatalog.categories.map((category) => category.title),
        expected,
      );
      expect(
        ArcHelpCentreCatalog.categories.map((category) => category.id).toSet(),
        hasLength(expected.length),
      );
    });

    test('categories have no empty answer sets', () {
      for (final category in ArcHelpCentreCatalog.categories) {
        expect(category.summary.trim(), isNotEmpty, reason: category.title);
        expect(category.answers, isNotEmpty, reason: category.title);
        for (final answer in category.answers) {
          expect(answer.question.trim(), isNotEmpty, reason: category.title);
          expect(answer.answer.trim(), isNotEmpty, reason: category.title);
        }
      }
    });

    test('direct category resolution supports ids and titles', () {
      expect(
        ArcHelpCentreCatalog.resolve('favourite-loadout').routeName,
        FavouriteLoadoutScreen.routeName,
      );
      expect(
        ArcHelpCentreCatalog.resolve('Favourite Loadout').id,
        'favourite-loadout',
      );
      expect(ArcHelpCentreCatalog.resolve('missing').id, 'getting-started');
    });
  });
}
