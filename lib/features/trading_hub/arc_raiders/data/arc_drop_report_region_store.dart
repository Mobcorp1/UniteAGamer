import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

class ArcDropReportRegionStore {
  const ArcDropReportRegionStore._();

  static const _key = 'arc_drop_report_server_region_v1';

  static Future<ArcServerRegion> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_key)?.trim();
    if (stored == null || stored.isEmpty) return ArcServerRegion.europe;
    for (final region in ArcServerRegion.values) {
      if (region.key == stored || region.name == stored) return region;
    }
    return ArcServerRegion.europe;
  }

  static Future<void> save(ArcServerRegion region) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, region.key);
  }
}
