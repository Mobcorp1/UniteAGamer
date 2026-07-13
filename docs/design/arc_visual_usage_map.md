# ARC Visual Asset Usage Map

Generated for PASS 257A from the canonical identity catalogue and current
Flutter implementation.

Source catalogue:

- `docs/design/arc_identity_asset_catalog.md`
- `docs/design/arc_identity_asset_catalog.json`
- `docs/design/arc_badge_artwork_brief.md`
- `docs/design/arc_asset_filename_manifest.csv`

No production artwork is created by this document. It maps where production
exports will be consumed.

## 1. Player Archetypes

Canonical entries: Balanced Raider, Quest-driven Raider, Blueprint Grinder,
Helper / Support Player, Trader / Resource Runner, PvP Hunter, Rat Hunter,
Casual Squad Player.

| Field | Usage |
|---|---|
| Stable identifiers | `balanced-raider`, `quest-driven-raider`, `blueprint-grinder`, `helper-support-player`, `trader-resource-runner`, `pvp-hunter`, `rat-hunter`, `casual-squad-player` |
| Asset type | Archetype emblem / chip icon |
| Source model | `arc_player_archetype_catalog.dart` |
| Screen/widget locations | Profile setup, Match Rider profile data, trader identity summaries where archetypes are shown |
| Rendered as | Chip icon, list tile icon, profile/match identity metadata |
| Current dimensions/constraints | IconData only; responsive text/chip sizing |
| Current BoxFit | Not applicable |
| Current clipping shape | None |
| Background/brightness | Dark glass card/chip backgrounds |
| Transparency | Required for emblem exports |
| Safe area | 12-16% internal padding recommended |
| Min readable size | 24 px icon use |
| Max displayed size | Not fixed |
| Mobile/tablet/web | Responsive chips/lists |
| Text overlay | No |
| Interactive | Yes where profile choices are selectable |
| Export source size | 1024 x 1024 master |
| Recommended filenames | See `arc_asset_filename_manifest.csv` |
| Current fallback | Material icons from `ArcPlayerArchetypeCatalog` |
| Status | Missing artwork |

## 2. Squad Intents

Canonical entries: Flexible, Squad up, Quest team, Blueprint runs, Trade
focused, Trials, Solo for now.

| Field | Usage |
|---|---|
| Stable identifiers | `squad-flexible`, `squad-up`, `quest-team`, `blueprint-runs`, `trade-focused`, `trials`, `solo-for-now` |
| Asset type | Small intent icon |
| Source model | `onboarding_basic_profile_screen.dart` |
| Locations | Onboarding basic profile, profile identity summaries, matching metadata |
| Rendered as | Chip icon/list tile marker |
| Dimensions/BoxFit/clipping | Not fixed; current fallback is text-first chip/list UI |
| Background/brightness | Dark card, cyan/pink accent states |
| Transparency | Required |
| Safe area | 12-16% |
| Minimum readable size | 20-24 px |
| Maximum displayed size | Not fixed |
| Mobile/tablet/web | Responsive wrap/list |
| Text overlay | No |
| Interactive | Yes during onboarding/profile edit |
| Export source size | 512 x 512 or 1024 x 1024 |
| Filename pattern | `assets/arc_raiders/identity/squad_intents/<id>.png` |
| Current fallback | Text chips |
| Status | Missing artwork |

## 3. Social-Energy States

Canonical entries: Depends on the day, Chatty and outgoing, Quiet but
cooperative, High energy, Low energy today, Prefer pings over voice.

| Field | Usage |
|---|---|
| Stable identifiers | `energy-depends`, `energy-chatty`, `energy-quiet-coop`, `energy-high`, `energy-low`, `energy-pings` |
| Asset type | Mood/communication icon |
| Source model | `onboarding_basic_profile_screen.dart` |
| Locations | Onboarding, profile identity summaries, match compatibility context |
| Rendered as | Chip icon/list tile marker |
| Dimensions/BoxFit/clipping | Not fixed |
| Background/brightness | Dark cards/chips |
| Transparency | Required |
| Safe area | 12-16% |
| Minimum readable size | 20-24 px |
| Maximum displayed size | Not fixed |
| Mobile/tablet/web | Responsive wrap/list |
| Text overlay | No |
| Interactive | Yes during onboarding/profile edit |
| Export source size | 512 x 512 or 1024 x 1024 |
| Filename pattern | `assets/arc_raiders/identity/social_energy/<id>.png` |
| Current fallback | Text chips |
| Status | Missing artwork |

## 4. Operation Cards

Canonical Operations: 21 seeded Operations across beta, daily, weekly, monthly
and lifetime tracks.

| Field | Usage |
|---|---|
| Asset type | Operation card image / task accent |
| Source model | `arc_operations_seed_data.dart` |
| Locations | `operations_command_screen.dart`, Reward Vault/Operations sections, Command Centre Operations summary |
| Rendered as | Card image where reward artwork exists, fallback icon otherwise |
| Dimensions | Responsive card layout; no fixed exported card size in code |
| BoxFit | Existing image usage is responsive; no single global BoxFit constraint |
| Clipping | Card radius follows existing AppTheme trading/glass cards |
| Background/brightness | Dark industrial glass; bright assets must read on dark backgrounds |
| Transparency | Optional for full card art; required for icon-like exports |
| Safe area | Keep key subject away from edges for card padding |
| Min readable size | Card thumbnail/list tile scale |
| Max displayed size | Responsive, constrained by page/card width |
| Mobile/tablet/web | Responsive cards and detail panels |
| Text overlay | Yes, operation title/progress may sit near artwork |
| Interactive | Yes |
| Export source size | 1600 x 900 master for card art; 1024 x 1024 for emblems |
| Filename pattern | `assets/arc_raiders/operations/cards/<operation_id>.png` |
| Current fallback | First reward asset or `Icons.military_tech_rounded` |
| Status | Mixed: shared artwork and missing operation-specific art |

## 5. Reward Vault Badges

Seeded badges: Beta Access Badge, Founding Raider Badge, Trade Pioneer Badge,
Intel Officer Badge, Community Raider Badge, OG Legend Badge, UAG Inner Circle
Badge.

| Field | Usage |
|---|---|
| Asset type | Badge emblem |
| Source model | `arc_operations_seed_data.dart` / `arc_operations_models.dart` |
| Locations | Reward Vault badge inventory/preview, profile badge slot, trading identity strips, Command Centre reward/Operations summaries, notifications where badge context is used |
| Rendered as | Badge, card image, profile/trader identity accent |
| Current dimensions | Responsive; preview panels render larger than inventory chips |
| BoxFit | Existing image previews use contained emblem-style rendering |
| Clipping | Rounded/glass card container; badge art should be transparent |
| Background/brightness | Dark glass and cyan/pink accents |
| Transparency | Required |
| Safe area | 12-18% to avoid clipping in circular/square badge slots |
| Min readable size | 28-32 px identity strip |
| Max displayed size | Reward preview responsive panel |
| Mobile/tablet/web | Responsive cards and strips |
| Text overlay | No direct text overlay on badge art |
| Interactive | Yes in Reward Vault inventory |
| Export source size | 1024 x 1024 master; production 512, 256, 128 |
| Current fallback | Existing PNG assets for all seven seeded badges |
| Status | Implemented for seeded badge assets |

## 6. Titles

Seeded title: Field Tester Title.

| Field | Usage |
|---|---|
| Asset type | Optional title plate/icon |
| Source model | `arc_operations_seed_data.dart` |
| Locations | Reward Vault title inventory/preview, Profile under username, trading identity strip |
| Rendered as | Text title, optional list tile icon |
| Dimensions/BoxFit | Not fixed; title is text-first |
| Clipping | None for title text |
| Background/brightness | Existing typography on dark UI |
| Transparency | Required only if title plate artwork is exported |
| Safe area | 10-14% if title plate art is introduced |
| Min readable size | Text remains readable at compact identity-strip size |
| Max displayed size | Profile header title line |
| Mobile/tablet/web | Responsive text |
| Text overlay | Title itself is text |
| Interactive | Yes in Reward Vault inventory |
| Export source size | 1600 x 400 if title plate art is produced |
| Filename pattern | `assets/arc_raiders/operations/titles/field_tester.png` |
| Current fallback | Text and title icon |
| Status | Missing optional artwork |

## 7. Profile Frames

Seeded frames: Beta Signal Frame, Guardian Signal Frame.

| Field | Usage |
|---|---|
| Asset type | Avatar frame overlay |
| Source model | `arc_operations_seed_data.dart` / equipped cosmetics |
| Locations | Reward Vault frame inventory/preview, profile avatar, trading identity strip |
| Rendered as | Avatar overlay / frame preview |
| Dimensions | Avatar sizes are responsive; compact identity strip is smallest use |
| BoxFit | Overlay should preserve aspect ratio |
| Clipping | Must support circular avatar clipping inside the frame |
| Background/brightness | Transparent frame over avatar/dark glass |
| Transparency | Required |
| Safe area | Inner hole must not cover avatar face; outer edge should survive clipping |
| Min readable size | 40-48 px avatar strip |
| Max displayed size | Profile header avatar and Reward Vault large preview |
| Mobile/tablet/web | Responsive avatar sizes |
| Text overlay | No |
| Interactive | Yes in Reward Vault inventory |
| Export source size | 1024 x 1024 master; production 512, 256 |
| Filename pattern | `assets/arc_raiders/operations/frames/<id>.png` |
| Current fallback | Generated/glass placeholder with avatar icon |
| Status | Placeholder |

## 8. Profile Banners

Seeded banners: Beta Command Banner, Guardian Banner.

| Field | Usage |
|---|---|
| Asset type | Wide profile banner/header |
| Source model | `arc_operations_seed_data.dart` / equipped cosmetics |
| Locations | Reward Vault banner inventory/preview, profile header backdrop, compact trading identity headers where space allows |
| Rendered as | Banner, profile header, card backdrop |
| Dimensions | Responsive wide area; no fixed code size |
| BoxFit | Cover or contain depending on header surface; do not distort |
| Clipping | Rounded header/card clipping |
| Background/brightness | Dark UI; banner must tolerate text nearby/over it |
| Transparency | Optional; opaque wide artwork acceptable |
| Safe area | 12% horizontal and vertical safe area for crop tolerance |
| Min readable size | Compact trader strip/header |
| Max displayed size | Profile header and Reward Vault large preview |
| Mobile/tablet/web | Must crop safely from mobile portrait to desktop wide |
| Text overlay | Yes on profile/trader identity surfaces |
| Interactive | Yes in Reward Vault inventory |
| Export source size | 2400 x 900 master; production 1600 x 600, 1200 x 450 |
| Filename pattern | `assets/arc_raiders/operations/banners/<id>.png` |
| Current fallback | Generated/glass placeholder with banner icon |
| Status | Placeholder |

## 9. Trading Identity Strips

| Field | Usage |
|---|---|
| Asset families | Badge, title, profile frame, profile banner |
| Source widgets | `trading_cosmetic_identity_strip.dart`, trading listing/offers/cards |
| Rendered as | Compact badge/icon, avatar/frame accent, optional banner/header |
| Dimensions | Responsive compact row/card; not fixed globally |
| BoxFit | Badge/frame contained; banner cover/contain by surface |
| Clipping | Avatar frame and rounded card clipping |
| Background/brightness | Dark card/glass |
| Transparency | Required for badge/frame |
| Safe area | Compact identity strips need strong silhouettes |
| Minimum readable size | 28 px badge, 40 px avatar/frame |
| Maximum displayed size | Listing/detail trader identity blocks |
| Mobile/tablet/web | Must wrap without overflow |
| Text overlay | Title/username text adjacent; banner may sit behind text |
| Interactive | Usually card-level interactive |
| Status | Implemented with fallbacks and seeded badge art |

## 10. Match Rider Cards

| Field | Usage |
|---|---|
| Asset families | Archetype icons, squad intent icons, social-energy icons, profile cosmetics |
| Source models/widgets | `arc_match_rider_profile.dart`, Match Rider screens/cards |
| Rendered as | List/card icon, chip icon, identity accent |
| Dimensions | Responsive; no fixed exported constraints |
| BoxFit/clipping | Icon-like contained art, rounded cards |
| Background/brightness | Dark command-centre cards |
| Transparency | Required for icon/emblem families |
| Safe area | 12-16% |
| Minimum readable size | 20-32 px |
| Maximum displayed size | Card/header responsive |
| Text overlay | No direct overlay on icon art |
| Interactive | Yes where cards open rider/profile surfaces |
| Status | Mostly fallback icons/text until production art exists |

## 11. Command Centre Priorities

| Field | Usage |
|---|---|
| Asset families | Operation cards, reward badges, system icons, trade objective icons |
| Source widgets | `arc_command_centre_content.dart`, command centre widgets |
| Rendered as | Priority card icon, compact snapshot icon, recommendation/action icon |
| Dimensions | Responsive compact cards; first screen must remain short |
| BoxFit | Not fixed for icons; card art should be responsive |
| Clipping | Card radius from existing glass style |
| Background/brightness | Dark hero/summary cards with cyan/pink accents |
| Transparency | Required for icon/emblem assets |
| Safe area | 12-16% |
| Minimum readable size | 20-28 px |
| Maximum displayed size | Today's Mission/priority card scale |
| Text overlay | Yes, priority text is adjacent/over shared panel space |
| Interactive | Yes through action cards/buttons |
| Status | Uses existing icons/assets; new trade objective screens are route-backed |

## 12. Notifications

| Field | Usage |
|---|---|
| Asset families | Notification type icons for offers, watches, queues, sessions, availability, feedback |
| Source widgets | `trading_notifications_screen.dart`, `trading_notification.dart` |
| Rendered as | Notification icon/dot/chip |
| Dimensions | Compact list tile/card; not fixed |
| BoxFit | Not applicable for current dot/icon usage |
| Clipping | Rounded notification card |
| Background/brightness | Dark card; unread neon border |
| Transparency | Required for future notification icons |
| Safe area | 12-16% |
| Minimum readable size | 18-24 px |
| Maximum displayed size | Notification list tile |
| Text overlay | No direct overlay |
| Interactive | Yes, whole card opens target route |
| Status | Route-backed with fallback icon/dot styling |

## 13. Missing Visual Placements

- Archetype artwork: missing for all eight selectable archetypes.
- Squad intent icons: missing for all seven canonical intents.
- Social-energy icons: missing for all six canonical states.
- Operation-specific card art: many operations share reward artwork or icon
  fallback.
- Field Tester title plate: optional artwork missing.
- Profile frames: both seeded frames use placeholder rendering.
- Profile banners: both seeded banners use placeholder rendering.
- Notification-type icons: current implementation uses colour/status dots and
  Material icons, not bespoke notification artwork.

## 14. Export Matrix

| asset_family | source_size | production_sizes | format | transparency | aspect_ratio | safe_area |
|---|---:|---|---|---|---|---|
| Player archetypes | 1024 x 1024 | 512, 256, 128 | PNG/WebP | Yes | 1:1 | 12-16% |
| Squad intents | 1024 x 1024 | 256, 128, 64 | PNG/WebP | Yes | 1:1 | 12-16% |
| Social-energy states | 1024 x 1024 | 256, 128, 64 | PNG/WebP | Yes | 1:1 | 12-16% |
| Operation cards | 1600 x 900 | 1200 x 675, 800 x 450 | PNG/WebP | Optional | 16:9 | Responsive |
| Reward Vault badges | 1024 x 1024 | 512, 256, 128 | PNG/WebP | Yes | 1:1 | 12-18% |
| Titles | 1600 x 400 | 800 x 200, 400 x 100 | PNG/WebP | Yes | 4:1 | 10-14% |
| Profile frames | 1024 x 1024 | 512, 256 | PNG/WebP | Yes | 1:1 | Avatar-safe inner ring |
| Profile banners | 2400 x 900 | 1600 x 600, 1200 x 450 | PNG/WebP | Optional | 8:3 | 12% crop-safe |
| Trading identity strips | Responsive | Not fixed | PNG/WebP | Yes for badge/frame | Mixed | 12-16% |
| Match Rider cards | Responsive | Not fixed | PNG/WebP | Yes for icon/emblem | Mixed | 12-16% |
| Command Centre priorities | Responsive | Not fixed | PNG/WebP | Yes for icon/emblem | Mixed | 12-16% |
| Notifications | 512 x 512 | 128, 64, 32 | PNG/WebP | Yes | 1:1 | 12-16% |
