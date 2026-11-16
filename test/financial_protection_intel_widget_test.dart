import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_trade_network_panel.dart';

class _Intel extends ArcBlueprintIntelRepository {
  final calls = <String>[];
  Completer<List<ArcBlueprintDropReport>> pending = Completer();
  @override
  Future<List<ArcBlueprintDropReport>> getReportsForBlueprint(
    String id, {
    int limit = 100,
  }) {
    expect(limit, 3);
    calls.add(id);
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  for (final size in [
    const Size(320, 700),
    const Size(740, 360),
    const Size(768, 1024),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'Intel caches, retries and changes identity at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final intel = _Intel();
        Widget panel(String id) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArcTradeBlueprintIntelPanel(
                blueprintId: id,
                blueprintNameFor: (id) => id,
                intelRepository: intel,
              ),
            ),
          ),
        );
        await tester.pumpWidget(panel('wolfpack'));
        expect(intel.calls, ['wolfpack']);
        expect(find.text('Loading community Intel…'), findsOneWidget);
        for (var i = 0; i < 10; i++) {
          await tester.pumpWidget(panel('wolfpack'));
        }
        expect(intel.calls, ['wolfpack']);
        intel.pending.completeError(StateError('offline'));
        await tester.pumpAndSettle();
        final retry = find.text('Community Intel unavailable. Retry');
        expect(retry, findsOneWidget);
        expect(find.textContaining('No recent community Intel'), findsNothing);
        intel.pending = Completer();
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        await tester.pump();
        expect(intel.calls, ['wolfpack', 'wolfpack']);
        intel.pending.complete([]);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No recent community Intel'),
          findsOneWidget,
        );
        intel.pending = Completer();
        await tester.pumpWidget(panel('tempest'));
        expect(intel.calls, ['wolfpack', 'wolfpack', 'tempest']);
        intel.pending.complete([]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
