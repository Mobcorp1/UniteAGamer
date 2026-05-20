import 'package:flutter/foundation.dart';

class ArcCollapsiblePanelController<T extends Object> extends ChangeNotifier {
  T? _expandedPanel;

  T? get expandedPanel => _expandedPanel;

  bool isExpanded(T panel) => _expandedPanel == panel;

  void expand(T panel) {
    if (_expandedPanel == panel) {
      return;
    }

    _expandedPanel = panel;
    notifyListeners();
  }

  void collapse(T panel) {
    if (_expandedPanel != panel) {
      return;
    }

    _expandedPanel = null;
    notifyListeners();
  }

  void toggle(T panel) {
    if (_expandedPanel == panel) {
      _expandedPanel = null;
    } else {
      _expandedPanel = panel;
    }

    notifyListeners();
  }

  void collapseAll() {
    if (_expandedPanel == null) {
      return;
    }

    _expandedPanel = null;
    notifyListeners();
  }
}
