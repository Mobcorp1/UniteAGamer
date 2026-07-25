import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_filter_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';

void main() {
  testWidgets('renders tactical schematic map and marker semantics', (
    tester,
  ) async {
    final controller = TransformationController();
    final state = const ArcRaidIntelligenceEngine().build(mapId: 'blue_gate');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 520,
            child: ArcRaidIntelligenceMapRenderer(
              state: state,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Surface • calibrated game map'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsWidgets);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(
      images.where(
        (image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName ==
                'assets/arc_raiders/maps/blue_gate/bluegate_master.webp',
      ),
      hasLength(1),
    );
    expect(
      images.where(
        (image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName.startsWith(
              'assets/arc_raiders/blueprints/',
            ),
      ),
      isNotEmpty,
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Listener), findsWidgets);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.trackpadScrollCausesScale, isTrue);
    expect(viewer.minScale, 0.75);
    expect(viewer.maxScale, 5);
    expect(
      find.bySemanticsLabel(RegExp(r'Blue Gate Raid Intelligence map')),
      findsOneWidget,
    );
    expect(find.byTooltip(RegExp(r'.+')), findsWidgets);
  });

  testWidgets('shared marker filter panel exposes global quick layers', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArcMapMarkerFilterPanel(
              filters: ArcRaidMapFilterState.defaults,
              searchController: controller,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Blueprint Opportunities'), findsWidgets);
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Loot Run'), findsOneWidget);
    expect(find.text('Community Intel'), findsOneWidget);
    expect(find.text('Everything'), findsOneWidget);
  });

  testWidgets('map exposes long-press and secondary-click Intel reporting', (
    tester,
  ) async {
    ArcNormalizedPoint? reportedPoint;
    final state = const ArcRaidIntelligenceEngine().build(mapId: 'blue_gate');
    final controller = TransformationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ArcRaidIntelligenceMapRenderer(
              state: state,
              controller: controller,
              onIntelReportRequested: (point) => reportedPoint = point,
            ),
          ),
        ),
      ),
    );

    await tester.longPressAt(const Offset(400, 300));
    await tester.pump();

    expect(reportedPoint, isNotNull);
    expect(reportedPoint!.x, inInclusiveRange(0, 1));
    expect(reportedPoint!.y, inInclusiveRange(0, 1));
  });
}
