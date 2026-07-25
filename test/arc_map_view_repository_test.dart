import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_view_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'persists and restores map layer and transformation independently',
    () async {
      const repository = ArcMapViewRepository();
      final surface = ArcMapViewSnapshot(
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        matrixValues: List<double>.generate(
          16,
          (index) => index % 5 == 0 ? 1 : 0,
        ),
        updatedAt: DateTime.utc(2026, 7, 25),
      );
      final underground = ArcMapViewSnapshot(
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.underground,
        matrixValues: <double>[
          2,
          0,
          0,
          0,
          0,
          2,
          0,
          0,
          0,
          0,
          2,
          0,
          -120,
          -80,
          0,
          1,
        ],
        updatedAt: DateTime.utc(2026, 7, 25, 1),
      );

      await repository.save(surface);
      await repository.save(underground);

      final restoredSurface = await repository.loadFor(
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
      );
      final restoredUnderground = await repository.loadLast();

      expect(restoredSurface, isNotNull);
      expect(restoredSurface!.layer, ArcRaidMapLayer.surface);
      expect(restoredSurface.matrixValues, surface.matrixValues);
      expect(restoredUnderground, isNotNull);
      expect(restoredUnderground!.layer, ArcRaidMapLayer.underground);
      expect(restoredUnderground.matrixValues, underground.matrixValues);
    },
  );

  test('rejects malformed persisted matrices', () async {
    const repository = ArcMapViewRepository();
    await repository.save(
      ArcMapViewSnapshot(
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        matrixValues: const <double>[1, 0, 0],
        updatedAt: DateTime.utc(2026, 7, 25),
      ),
    );

    expect(
      await repository.loadFor(
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
      ),
      isNull,
    );
  });
}
