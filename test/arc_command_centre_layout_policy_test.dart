import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_layout_policy.dart';

void main() {
  group('ArcCommandCentreLayoutPolicy', () {
    test('keeps next moves single-column on narrow command surfaces', () {
      expect(ArcCommandCentreLayoutPolicy.moveColumns(320), 1);
      expect(ArcCommandCentreLayoutPolicy.moveColumns(390), 1);
      expect(ArcCommandCentreLayoutPolicy.moveColumns(519), 1);
      expect(ArcCommandCentreLayoutPolicy.moveColumns(520), 2);
      expect(ArcCommandCentreLayoutPolicy.moveColumns(899), 2);
      expect(ArcCommandCentreLayoutPolicy.moveColumns(900), 3);
    });

    test('daily mission board uses stable responsive columns', () {
      expect(ArcCommandCentreLayoutPolicy.dailyColumns(320), 1);
      expect(ArcCommandCentreLayoutPolicy.dailyColumns(429), 1);
      expect(ArcCommandCentreLayoutPolicy.dailyColumns(430), 2);
      expect(ArcCommandCentreLayoutPolicy.dailyColumns(759), 2);
      expect(ArcCommandCentreLayoutPolicy.dailyColumns(760), 3);
    });

    test('compact cards reserve enough vertical space for their content', () {
      expect(ArcCommandCentreLayoutPolicy.moveTileHeight(390), 112);
      expect(ArcCommandCentreLayoutPolicy.moveTileHeight(520), 102);
      expect(ArcCommandCentreLayoutPolicy.dailyTileHeight(390), 86);
      expect(ArcCommandCentreLayoutPolicy.dailyTileHeight(430), 80);
    });

    test('systems ring stays compact across mobile and desktop widths', () {
      expect(ArcCommandCentreLayoutPolicy.systemRingHeight(390), 170);
      expect(ArcCommandCentreLayoutPolicy.systemRingHeight(619), 170);
      expect(ArcCommandCentreLayoutPolicy.systemRingHeight(620), 164);
      expect(ArcCommandCentreLayoutPolicy.systemRingHeight(1280), 164);
    });
  });
}
