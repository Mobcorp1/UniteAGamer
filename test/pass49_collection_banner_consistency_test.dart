import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_placement_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';

void main() {
  const collectionsRoute = '/trading-hub/arc-raiders/blueprints';

  test('Collections has an allowlisted banner placement', () {
    expect(UagAdPlacementPolicy.permitsBanner(collectionsRoute), isTrue);
    expect(UagAdPlacementPolicy.permitsBanner('/unknown-route'), isFalse);
  });

  testWidgets('Collections banner slot retains a fixed ad lane when eligible',
      (tester) async {
    final eligible = ValueNotifier<bool>(true);
    addTearDown(eligible.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ArcBlueprintBannerSlot(
          placementRoute: collectionsRoute,
          eligibility: eligible,
          banner: const SizedBox(key: Key('collection-test-ad')),
        ),
      ),
    ));
    expect(find.byKey(const Key('collection-test-ad')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-banner-slot')), findsOneWidget);
    eligible.value = false;
    await tester.pump();
    expect(find.byKey(const Key('collection-test-ad')), findsNothing);
  });
}
