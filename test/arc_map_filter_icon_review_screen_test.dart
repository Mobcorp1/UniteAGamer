import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_map_filter_icon_review_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_filter_icon.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  testWidgets('icon review atlas renders every taxonomy icon at review sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 1440, child: ArcMapFilterIconReviewAtlas()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconCount =
        ArcMapFilterTaxonomy.all.length +
        ArcMapFilterIconRegistry.uagCommunityIconKeys.length;

    expect(find.text('Map Filter Icon Atlas'), findsOneWidget);
    expect(find.byType(ArcMapFilterIcon), findsNWidgets(iconCount * 5));

    for (final entry in ArcMapFilterTaxonomy.all) {
      expect(
        find.byKey(ValueKey<String>('map-icon-review-${entry.iconKey}')),
        findsOneWidget,
        reason: entry.iconKey,
      );
      expect(find.text(entry.iconKey), findsOneWidget, reason: entry.iconKey);
    }
    final expectedSectionOrder = [
      'ARC',
      'Extraction',
      'Loot',
      'Infrastructure',
      'Access',
      'Nature',
      'Quest',
      'UAG Community',
    ];
    var previousTop = double.negativeInfinity;
    for (final title in expectedSectionOrder) {
      final top = tester.getTopLeft(find.text(title).first).dy;
      expect(top, greaterThan(previousTop), reason: title);
      previousTop = top;
    }

    expect(find.text('Report A Rat'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('map-icon-review-community_report_rat'),
      ),
      findsOneWidget,
    );
    expect(find.text('community_report_rat'), findsOneWidget);

    for (final size in ['18px', '24px', '32px', '48px', '128px']) {
      expect(find.text(size), findsNWidgets(iconCount), reason: size);
    }
  });

  testWidgets('icon review launch card invokes the admin navigation action', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: ArcMapFilterIconReviewLaunchCard(onOpen: () => opened = true),
        ),
      ),
    );

    await tester.tap(find.text('Review Icons'));
    await tester.pump();

    expect(opened, isTrue);
  });
}
