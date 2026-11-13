import 'arc_collapsible_panel_controller.dart';

enum ArcRaidersPanelSection {
  communityIntel,
  dropReport,
  blueprintFilters,
  trackerSummary,
  smartTradeAssist,
  arcAssist,
}

class ArcRaidersSectionController
    extends ArcCollapsiblePanelController<ArcRaidersPanelSection> {
  ArcRaidersSectionController({ArcRaidersPanelSection? initiallyExpanded}) {
    if (initiallyExpanded != null) {
      expand(initiallyExpanded);
    }
  }

  void showCommunityIntel() {
    expand(ArcRaidersPanelSection.communityIntel);
  }

  void showDropReport() {
    expand(ArcRaidersPanelSection.dropReport);
  }

  void showSmartTradeAssist() {
    expand(ArcRaidersPanelSection.smartTradeAssist);
  }

  void showArcAssist() {
    expand(ArcRaidersPanelSection.arcAssist);
  }
}
