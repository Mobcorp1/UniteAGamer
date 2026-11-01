import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';

/// One region preference shared by event displays, planner and drop reports.
/// Keys are user scoped: switching accounts cannot inherit another player's region.
class ArcDropReportRegionStore {
  const ArcDropReportRegionStore._();

  static const _key = 'arc_drop_report_server_region_v2';
  static String get _userKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? '${_key}_guest' : '${_key}_$uid';
  }

  static ArcServerRegion? fromProfilePreference(String? preference) {
    switch (preference?.trim().toLowerCase()) {
      case 'europe':
        return ArcServerRegion.europe;
      case 'north america':
      case 'north-america':
        return ArcServerRegion.northAmerica;
      case 'south america':
      case 'brazil':
        return ArcServerRegion.brazil;
      case 'asia':
      case 'east asia':
      case 'east-asia':
        return ArcServerRegion.eastAsia;
      case 'oceania':
        return ArcServerRegion.oceania;
      default:
        return null;
    }
  }

  static String toProfilePreference(ArcServerRegion region) {
    switch (region) {
      case ArcServerRegion.europe:
        return 'Europe';
      case ArcServerRegion.northAmerica:
        return 'North America';
      case ArcServerRegion.brazil:
        return 'South America';
      case ArcServerRegion.eastAsia:
        return 'Asia';
      case ArcServerRegion.oceania:
        return 'Oceania';
    }
  }

  static Future<ArcServerRegion> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_userKey);
    if (stored != null) {
      for (final region in ArcServerRegion.values) {
        if (region.key == stored || region.name == stored) return region;
      }
    }
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final profile = await ArcTraderProfileRepository().getProfile();
        final profileRegion = fromProfilePreference(profile.serverPreference);
        if (profileRegion != null) {
          await save(profileRegion);
          return profileRegion;
        }
      } catch (_) {
        // Offline account: use a visible Europe default, never a different user's value.
      }
    }
    return ArcServerRegion.europe;
  }

  static Future<void> save(ArcServerRegion region) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, region.key);
  }

  static Future<void> saveAndSyncProfile(ArcServerRegion region) async {
    await save(region);
    if (FirebaseAuth.instance.currentUser == null) return;
    final repository = ArcTraderProfileRepository();
    final profile = await repository.getProfile();
    await repository.saveProfile(
      profile.copyWith(serverPreference: toProfilePreference(region)),
    );
  }
}
