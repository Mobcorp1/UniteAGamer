import 'package:flutter/foundation.dart';

import 'arc_feature_access_state.dart';

class ArcFeatureAccessController extends ChangeNotifier {
  ArcFeatureAccessState _state;

  ArcFeatureAccessController({ArcFeatureAccessState? initialState})
    : _state = initialState ?? ArcFeatureAccessState.defaults();

  ArcFeatureAccessState get state => _state;

  bool isEnabled(ArcFeatureKey key) {
    return _state.isEnabled(key);
  }

  void setFeatureEnabled({required ArcFeatureKey key, required bool enabled}) {
    if (_state.isEnabled(key) == enabled) {
      return;
    }

    _state = _state.copyWithFeature(key: key, enabled: enabled);
    notifyListeners();
  }

  void applyRemoteConfig(Map<String, dynamic> data) {
    final updates = <ArcFeatureKey, bool>{};

    for (final entry in data.entries) {
      final key = _keyFromString(entry.key);
      final value = entry.value;

      if (key != null && value is bool) {
        updates[key] = value;
      }
    }

    if (updates.isEmpty) {
      return;
    }

    _state = _state.copyWithMap(updates);
    notifyListeners();
  }

  ArcFeatureKey? _keyFromString(String value) {
    switch (value) {
      case 'tradersHub':
        return ArcFeatureKey.tradersHub;
      case 'scrappyTracker':
        return ArcFeatureKey.scrappyTracker;
      case 'raidPlanner':
        return ArcFeatureKey.raidPlanner;
      case 'playLikeAPro':
        return ArcFeatureKey.playLikeAPro;
      case 'voiceAssist':
        return ArcFeatureKey.voiceAssist;
      case 'smartTradeAssist':
        return ArcFeatureKey.smartTradeAssist;
      case 'automationSystems':
        return ArcFeatureKey.automationSystems;
      case 'adminConsole':
        return ArcFeatureKey.adminConsole;
    }

    return null;
  }
}
