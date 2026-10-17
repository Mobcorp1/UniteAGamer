import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ArcBlueprintGridViewMode {
  inGameFramed,
  fullOverview;

  String get storageValue => switch (this) {
    ArcBlueprintGridViewMode.inGameFramed => 'in_game_framed',
    ArcBlueprintGridViewMode.fullOverview => 'full_overview',
  };

  String get label => switch (this) {
    ArcBlueprintGridViewMode.inGameFramed => 'In-Game Framed View',
    ArcBlueprintGridViewMode.fullOverview => 'Full Grid Overview',
  };

  static ArcBlueprintGridViewMode fromStorage(String? value) {
    return switch (value) {
      'in_game_framed' => ArcBlueprintGridViewMode.inGameFramed,
      'full_overview' => ArcBlueprintGridViewMode.fullOverview,
      _ => ArcBlueprintGridViewMode.fullOverview,
    };
  }
}

class ArcBlueprintGridViewPreferences {
  const ArcBlueprintGridViewPreferences._();

  // V3 migrates the old five-row default to a full-grid-first launch.
  // Explicit choices made from this version onward remain user-scoped.
  // Ownership, duplicate and acquisition storage is unrelated/unmodified.
  static const _storagePrefix = 'arcBlueprintGridViewModeV3';

  static String _storageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return _storagePrefix;
    return '${_storagePrefix}_$uid';
  }

  static Future<ArcBlueprintGridViewMode> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ArcBlueprintGridViewMode.fromStorage(
      preferences.getString(_storageKey()),
    );
  }

  static Future<void> save(ArcBlueprintGridViewMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey(), mode.storageValue);
  }
}
