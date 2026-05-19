# Next Consolidation Pass Plan

## Pass 1 - Single Source of Truth

Primary target files to preserve as canonical:

- Blueprints: lib/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart
- POIs: lib/features/trading_hub/arc_raiders/data/arc_poi_data.dart
- Containers: lib/features/trading_hub/arc_raiders/data/arc_container_types.dart
- Unified item index: lib/features/trading_hub/arc_raiders/data/unified_item_index.dart

Files that should eventually become derived wrappers or adapters instead of independent truth sources:

- arc_trade_catalog.dart
- trade_items_data.dart
- arc_voice_item_database.dart
- arc_scrappy_seed_data.dart
- arc_bench_upgrade_seed_data.dart
- arc_quest_requirement_seed_data.dart

## Pass 2 - UI Architecture

- Collapsed by default for heavy sections
- One-open accordion for tracker groups
- AppTheme only
- Runtime generated separators using String.fromCharCode(0x2022)
- No developer/debug explanatory text in production UI

## Pass 3 - Admin Completion

- Standardise statuses: new, reviewing, planned, actioned, closed
- Admin/dev read all feedback
- Admin/dev update feedback
- Admin/dev delete feedback
- Admin/dev create replies
- User read their own feedback/replies

## Pass 4 - Smart Automation

- Wire SmartTradeIntelligenceService into Blueprint duplicate flow
- Wire voice assistant item checks into listings and wants
- Add listing detail suggestions
- Add My Duplicate tracker intelligence
- Use priority wanted blueprint list
