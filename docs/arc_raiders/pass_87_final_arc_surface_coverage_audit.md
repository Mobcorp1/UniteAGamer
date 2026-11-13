# Pass 87 - Final ARC Surface Coverage Audit

Final app-wide screen audit after ARC command-centre standardisation, AdMob foundation, GDPR consent foundation, auth/profile/legal conversion passes.

## Summary

- Total screen-like Dart files checked: 48
- ARC aligned / AppTheme driven: 45
- Raw Material screens: 3
- Watermark-only screens: 0
- Needs manual review: 0

## Notes

- This pass is audit-only.
- No app code, tracker logic, grid logic, carousel logic, trading logic, Firestore wiring, ad logic, auth logic, or loadout logic is changed.
- Use this report to plan the next visual parity / final production polish passes.

## File Coverage

| File | Status | Signals |
|---|---|---|
| .\lib\build\splash_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\legal\screens\arc_data_attribution_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\legal\screens\legal_hub_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\legal\screens\privacy_policy_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\legal\screens\terms_of_use_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\monetisation\screens\admin_monetisation_dashboard.dart | ARC ALIGNED | scaffold=False | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\monetisation\screens\monetisation_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\monetisation\screens\uag_plans_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\profile\screens\profile_settings_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\raid_planner\screens\raid_planner_hunt_targets_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\trading_hub\arc_raiders\raid_planner\screens\raid_planner_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_availability_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_away_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_create_trade_listing_screen.dart | RAW MATERIAL | scaffold=True | appTheme=False | shell/backdrop=False | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_intel_explorer_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_market_intelligence_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_match_rider_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_my_trade_listings_screen.dart | RAW MATERIAL | scaffold=True | appTheme=False | shell/backdrop=False | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_profile_edit_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_profile_setup_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\arc_raiders_hub_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\trading_hub\arc_raiders\screens\arc_trader_search_screen.dart | RAW MATERIAL | scaffold=True | appTheme=False | shell/backdrop=False | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\blueprint_grid_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\favourite_loadout_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\my_hub_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\features\trading_hub\arc_raiders\screens\my_intel_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\play_like_a_pro_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\scrappy_grid_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\smart_trade_assist_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trader_hub_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_activity_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_create_listing_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_listing_detail_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_listings_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_make_offer_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_my_listings_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_my_offers_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_notifications_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_profile_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\features\trading_hub\arc_raiders\screens\trading_trade_sessions_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\reg\onboarding_basic_profile_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\screens\build\admin_console_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\screens\build\app_bar.dart | ARC ALIGNED | scaffold=False | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\screens\build\app_drawer.dart | ARC ALIGNED | scaffold=False | appTheme=True | shell/backdrop=True | watermark=False |
| .\lib\screens\build\app_entry_gate.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\screens\build\auth\auth_landing_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\screens\build\feedback_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
| .\lib\screens\build\splash_screen.dart | ARC ALIGNED | scaffold=True | appTheme=True | shell/backdrop=True | watermark=True |
