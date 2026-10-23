import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_modal_surface.dart';

void main() {
  testWidgets(
    'convergence modal remains bounded on narrow portrait viewports',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArcModalSurface(
              child: SingleChildScrollView(
                child: Text('ACCESSIBLE DIALOG CONTENT'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('ACCESSIBLE DIALOG CONTENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blueprint ad slot does not reserve height when ineligible', (
    tester,
  ) async {
    final eligible = ValueNotifier<bool>(false);
    addTearDown(eligible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ArcBlueprintBannerSlot(
                eligibility: eligible,
                banner: const SizedBox(
                  width: 322,
                  height: 52,
                  child: Text('CREATIVE'),
                ),
              ),
              const Text('NEXT CONTENT'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('CREATIVE'), findsNothing);
    expect(find.text('NEXT CONTENT'), findsOneWidget);
    eligible.value = true;
    await tester.pump();
    expect(find.text('CREATIVE'), findsOneWidget);
  });
}
