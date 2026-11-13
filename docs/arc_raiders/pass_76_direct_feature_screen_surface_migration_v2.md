# Pass 76 v2 - Direct ARC Feature-Screen Surface Migration

This pass targets high-traffic ARC feature screens directly instead of only the hub/My Hub/shared shell layer.

Screens targeted:
- Match Rider
- Community Intel / Intel Explorer
- Market Intelligence
- Trader Hub
- Trader Search
- Availability / Away
- Trading activity, listings, offers, profile, notifications and trade sessions
- Smart Trade Assist
- Play Like A Pro

Safe scope:
- Replaces old StaticWatermark surfaces with the shared ARC cinematic backdrop where present.
- Enables extendBody on migrated Scaffold layouts so the dock feels integrated with the tactical surface.
- Tightens legacy page padding and large vertical gaps.
- Does not rewrite tracker logic, ownership logic, Firestore, trading repositories, carousel logic, grid logic, raid planner logic or loadout persistence.

Changed files:
lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart
lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart
lib/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_trader_search_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_away_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_make_offer_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart
lib/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart
lib/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart
lib/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart
