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
      _ => ArcBlueprintGridViewMode.inGameFramed,
    };
  }
}

class ArcBlueprintGridViewPreferences {
  const ArcBlueprintGridViewPreferences._();

  // V2 resets the legacy full-grid-first preference so the tracker opens in
  // the five-row in-game view. New user choices are still persisted.
  static const _storagePrefix = 'arcBlueprintGridViewModeV2';

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
