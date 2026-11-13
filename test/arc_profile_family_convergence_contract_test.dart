import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('ARC profile family convergence contract', () {
    test(
      'profile landing page uses canonical wide viewport and mobile tab rail',
      () {
        final source = _read(
          'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
        );

        expect(source, contains('ArcPageViewport('));
        expect(source, contains('width: ArcPageWidth.wide'));
        expect(source, contains('SingleChildScrollView('));
        expect(
          source,
          contains(
            "const labels = ['OVERVIEW', 'RAIDER', 'REPUTATION', 'LOCKER']",
          ),
        );
      },
    );

    test(
      'shared form surface owns canonical form viewport and responsive stats',
      () {
        final source = _read(
          'lib/features/trading_hub/arc_raiders/widgets/foundation/arc_form_surface.dart',
        );

        expect(
          source,
          contains('class ArcFormScrollView extends StatelessWidget'),
        );
        expect(source, contains('width: ArcPageWidth.form'));
        expect(source, contains('ArcLayoutTokens.pagePadding(context)'));
        expect(
          source,
          contains('class ArcFormStatGrid extends StatelessWidget'),
        );
        expect(source, contains('ArcAdaptiveGrid('));
      },
    );

    test('profile setup and edit share ArcFormScrollView', () {
      final setup = _read(
        'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
      );
      final edit = _read(
        'lib/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart',
      );

      expect(setup, contains('ArcFormScrollView('));
      expect(edit, contains('ArcFormScrollView('));
      expect(setup, isNot(contains('BoxConstraints(maxWidth: 860)')));
      expect(edit, isNot(contains('BoxConstraints(maxWidth: 860)')));
    });

    test('availability and away share form viewport and stat grid', () {
      final availability = _read(
        'lib/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart',
      );
      final away = _read(
        'lib/features/trading_hub/arc_raiders/screens/arc_away_screen.dart',
      );

      expect(availability, contains('ArcFormScrollView('));
      expect(availability, contains('ArcFormStatGrid('));
      expect(availability, isNot(contains('BoxConstraints(maxWidth: 900)')));

      expect(away, contains('ArcFormScrollView('));
      expect(away, contains('ArcFormStatGrid('));
      expect(away, isNot(contains('BoxConstraints(maxWidth: 820)')));
    });
  });
}
