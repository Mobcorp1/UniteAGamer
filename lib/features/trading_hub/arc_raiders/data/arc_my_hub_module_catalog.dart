import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_intel_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';

class ArcMyHubModuleDefinition {
  const ArcMyHubModuleDefinition({
    required this.title,
    required this.routeName,
    required this.personalLayer,
  });

  final String title;
  final String routeName;
  final bool personalLayer;
}

class ArcMyHubModuleCatalog {
  const ArcMyHubModuleCatalog._();

  static const List<ArcMyHubModuleDefinition> modules = [
    ArcMyHubModuleDefinition(
      title: 'Blueprint Tracker',
      routeName: BlueprintGridScreen.routeName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'Scrappy Tracker',
      routeName: ScrappyGridScreen.routeName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'Bench Tracker',
      routeName: ScrappyGridScreen.benchRouteName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'Quest Tracker',
      routeName: ScrappyGridScreen.questRouteName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'My Loadout',
      routeName: FavouriteLoadoutScreen.routeName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'My Intel',
      routeName: MyIntelScreen.routeName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'Smart Trade Assist',
      routeName: SmartTradeAssistScreen.routeName,
      personalLayer: false,
    ),
    ArcMyHubModuleDefinition(
      title: 'Trading Overview',
      routeName: TraderHubScreen.routeName,
      personalLayer: false,
    ),
    ArcMyHubModuleDefinition(
      title: 'Nomadic Trader',
      routeName: NomadicTraderScreen.routeName,
      personalLayer: false,
    ),
    ArcMyHubModuleDefinition(
      title: 'Profile & Reputation',
      routeName: TradingProfileScreen.routeName,
      personalLayer: true,
    ),
    ArcMyHubModuleDefinition(
      title: 'Operation Rewards',
      routeName: OperationsCommandScreen.routeName,
      personalLayer: true,
    ),
  ];

  static ArcMyHubModuleDefinition? byTitle(String title) {
    final target = title.trim().toLowerCase();
    for (final module in modules) {
      if (module.title.toLowerCase() == target) return module;
    }
    return null;
  }
}
