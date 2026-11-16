# Exact files changed by the financial protection pass

This is the explicit 51-path commit allowlist. No artwork, avatar, installer, sync, credential, signing, production Firebase options or unrelated files are included. Generated line-ending-only changes were excluded. The original worktree remains untouched after isolation.

| File | Change and purpose |
|---|---|
| [docs/financial-protection-certification.md](../docs/financial-protection-certification.md) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-changes.md](../docs/financial-protection-changes.md) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-console-checklist.md](../docs/financial-protection-console-checklist.md) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-functions.json](../docs/financial-protection-functions.json) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-inventory.md](../docs/financial-protection-inventory.md) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-live-functions.json](../docs/financial-protection-live-functions.json) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-original-final.json](../docs/financial-protection-original-final.json) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-preservation.json](../docs/financial-protection-preservation.json) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-runbook.md](../docs/financial-protection-runbook.md) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [docs/financial-protection-web-artifacts.json](../docs/financial-protection-web-artifacts.json) | Financial audit, configuration, preservation or verification evidence; no production mutation. |
| [firebase.financial-emulators.json](../firebase.financial-emulators.json) | Demo-only local Firestore/Storage integration test configuration and runner. |
| [firebase.json](../firebase.json) | Cache content-addressed website assets; revalidate unversioned Flutter assets. |
| [firestore.rules](../firestore.rules) | Protect emergency state/audit/limits; gate optional writes; keep explicit user child validations authoritative. |
| [functions/financial_protection.js](../functions/financial_protection.js) | Cached fail-closed control checks, transaction-based rate limits and audited idempotent admin control. |
| [functions/index.js](../functions/index.js) | Wire emergency/rate controls and v2 scaling options; avoid redundant alert ownership reads. |
| [functions/tests/financial_gateway_test.js](../functions/tests/financial_gateway_test.js) | Security, abuse, emergency, concurrency, pagination, retry and duplicate-processing regression tests. |
| [functions/tests/financial_protection_test.js](../functions/tests/financial_protection_test.js) | Security, abuse, emergency, concurrency, pagination, retry and duplicate-processing regression tests. |
| [functions/uag_trade_invite_gateway.js](../functions/uag_trade_invite_gateway.js) | Bound request bodies, local/account rates and optional work; verify App Check tokens; readable failures. |
| [lib/features/legal/data/uag_account_deletion_service.dart](../lib/features/legal/data/uag_account_deletion_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/monetisation/services/uag_checkout_service.dart](../lib/features/monetisation/services/uag_checkout_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/monetisation/services/uag_operation_action_reward_service.dart](../lib/features/monetisation/services/uag_operation_action_reward_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/monetisation/services/uag_raider_mark_service.dart](../lib/features/monetisation/services/uag_raider_mark_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/monetisation/services/uag_referral_action_reward_service.dart](../lib/features/monetisation/services/uag_referral_action_reward_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/notifications/data/uag_notification_repository.dart](../lib/features/notifications/data/uag_notification_repository.dart) | Replace infinite asyncExpand with tested auth-switch lifecycle helper; data/ownership logic retained. |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart) | Replace infinite asyncExpand with tested auth-switch lifecycle helper; data/ownership logic retained. |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart) | Replace infinite asyncExpand with tested auth-switch lifecycle helper; data/ownership logic retained. |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart) | Fix auth switching and cached cosmetic listener disposal; trading business rules retained. |
| [lib/features/trading_hub/arc_raiders/services/uag_trade_invite_service.dart](../lib/features/trading_hub/arc_raiders/services/uag_trade_invite_service.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/features/trading_hub/arc_raiders/widgets/arc_trade_network_panel.dart](../lib/features/trading_hub/arc_raiders/widgets/arc_trade_network_panel.dart) | Keep Intel future stable across rebuilds, refresh by identity/retry, expose distinct loading/error/empty states. |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart](../lib/features/trust/repositories/arc_raider_contracts_repository.dart) | Attach cached App Check header to existing manual HTTP requests; contract failures expose safe unavailable/rate-limit messages. |
| [lib/main.dart](../lib/main.dart) | Initialize opt-in App Check after Firebase; supported providers, bounded token access and monitoring-mode behavior. |
| [lib/services/uag_app_check.dart](../lib/services/uag_app_check.dart) | Initialize opt-in App Check after Firebase; supported providers, bounded token access and monitoring-mode behavior. |
| [lib/services/uag_streams.dart](../lib/services/uag_streams.dart) | Cancel and replace auth-bound inner streams; release shared listener on last subscriber. |
| [macos/Flutter/GeneratedPluginRegistrant.swift](../macos/Flutter/GeneratedPluginRegistrant.swift) | Register the new Firebase App Check plugin on supported build targets. |
| [pubspec.lock](../pubspec.lock) | Add compatible App Check dependency and required Firebase Core patch. |
| [pubspec.yaml](../pubspec.yaml) | Add compatible App Check dependency and required Firebase Core patch. |
| [scripts/financial_hosting_windows_url_shim.cjs](../scripts/financial_hosting_windows_url_shim.cjs) | Explicit test-only in-memory workaround for Windows emulator URL matching; installed tooling unchanged. |
| [scripts/test_financial_emulators.js](../scripts/test_financial_emulators.js) | Demo-only local Firestore/Storage integration test configuration and runner. |
| [scripts/test_financial_hosting.js](../scripts/test_financial_hosting.js) | Local route/header/hash/manifest/validator checks, with CDN/PWA limitations reported. |
| [storage.rules](../storage.rules) | Gate optional creator uploads without changing ownership, type or size checks. |
| [test/financial_protection_hosting_test.dart](../test/financial_protection_hosting_test.dart) | Listener/cache/App Check boundary, responsive Intel and hashed-asset/cache regression tests. |
| [test/financial_protection_intel_widget_test.dart](../test/financial_protection_intel_widget_test.dart) | Listener/cache/App Check boundary, responsive Intel and hashed-asset/cache regression tests. |
| [test/financial_protection_streams_test.dart](../test/financial_protection_streams_test.dart) | Listener/cache/App Check boundary, responsive Intel and hashed-asset/cache regression tests. |
| [tool/prepare_web_release.dart](../tool/prepare_web_release.dart) | Hash generated public JS/CSS by content and update generated HTML links while preserving aliases. |
| [tool/version_web_static_assets.dart](../tool/version_web_static_assets.dart) | Hash generated public JS/CSS by content and update generated HTML links while preserving aliases. |
| [trading/financial-protection.test.js](../trading/financial-protection.test.js) | Security, abuse, emergency, concurrency, pagination, retry and duplicate-processing regression tests. |
| [trading/firestore-rules.test.js](../trading/firestore-rules.test.js) | Correct privileged fixture setup and reject self-admin creation. |
| [trading/raider-contract-rules.test.js](../trading/raider-contract-rules.test.js) | Use shared demo-only project for cross-service Storage/Firestore emulator rules. |
| [windows/flutter/generated_plugin_registrant.cc](../windows/flutter/generated_plugin_registrant.cc) | Register the new Firebase App Check plugin on supported build targets. |
| [windows/flutter/generated_plugins.cmake](../windows/flutter/generated_plugins.cmake) | Register the new Firebase App Check plugin on supported build targets. |
