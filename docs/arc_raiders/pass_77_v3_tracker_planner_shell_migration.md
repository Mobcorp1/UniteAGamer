# Pass 77 v3 - Tracker and Planner Shell Migration

This pass applies conservative visual shell flags to tracker/planner surfaces only. It does not rewrite grids, carousel logic, ownership state, hunt sync, Firestore, or trading logic.

- lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart | sharedShell=False | scaffold=True | touched=True
- lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart | sharedShell=False | scaffold=True | touched=True
- MISSING: lib/features/trading_hub/arc_raiders/screens/arc_collection_tracker_screen.dart
- MISSING: lib/features/trading_hub/arc_raiders/screens/arc_collection_screen.dart
- lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart | sharedShell=False | scaffold=True | touched=True
- lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart | sharedShell=False | scaffold=True | touched=True
- MISSING: lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_active_hunt_screen.dart
- MISSING: lib/features/trading_hub/arc_raiders/screens/arc_blueprint_intel_screen.dart
- MISSING: lib/features/trading_hub/arc_raiders/screens/blueprint_intel_screen.dart
- MISSING: lib/features/trading_hub/arc_raiders/screens/arc_community_intel_screen.dart
