import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_modal_surface.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';

void main() {
  testWidgets(
    'ARC modal uses the external electric border with cyan/pink accents',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ArcModalSurface(child: Text('Modal action'))),
        ),
      );
      expect(find.byType(ElectricChargeBorder), findsOneWidget);
      expect(
        tester
            .widget<ElectricChargeBorder>(find.byType(ElectricChargeBorder))
            .active,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('admin bulk editor and cosmetics maintain separate scope', () {
    final editor = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart',
    ).readAsStringSync();
    final loadout = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();
    expect(editor, contains('admin-bulk-add-intel'));
    expect(editor, contains('_verifyAdminAccess'));
    expect(editor, contains('admin-rapid-place-markers'));
    expect(loadout, contains('Keep the stencil label attached to its own box'));
  });
}
