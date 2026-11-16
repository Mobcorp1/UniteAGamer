# Financial protection controls and release runbook

Prepared 16 November 2026. These controls exist in this branch only; nothing was deployed.

## Scope and operating contract

[financial_protection.js](../functions/financial_protection.js) adds one server-owned document, `app_config/financial_protection`, and an append-only client-inaccessible audit collection, `financial_protection_audit`. The existing generic app configuration could not provide an atomic audited admin change, so this is a narrowly scoped control within that namespace.

| Protected operation | Enforcement | During restriction |
|---|---|---|
| Contract evidence submission/review and report-evidence attachment | Authenticated callable wrapper | UNAVAILABLE before expensive processing |
| Report moderation and contract discovery | Authenticated callable wrapper | UNAVAILABLE |
| Trade invitation create/resolve/claim/legacyCapture | HTTP gateway | HTTP 503; revoke remains available |
| Optional message outbox processing | Rules on creation and server trigger | New requests rejected; queued work receives blocked_service_unavailable |
| Admin notification broadcasts | Rules on creation and server trigger | New requests rejected; queued broadcasts blocked |
| Automatic trading-watch fan-out | Trigger start and between pages | Stops; skipped alerts are not automatically replayed |
| Creator-content uploads | Storage Rules | New/updated uploads denied; existing reads/deletion remain available |

Account login/profile access, account deletion, blueprint ownership, progression, trading transactions, existing notification reads, payment/webhook/entitlement processing, account challenges and safety reporting are not disabled. Evidence **uploads** (contract/conduct/message), screenshots, profile media, existing asset downloads, public Hosting and direct Firestore reads remain possible. An upload can therefore incur storage costs before a protected verification callable rejects it.

The server cache coalesces concurrent checks and refreshes at most once per five seconds per active warm process. Read failures and malformed existing controls fail closed. A missing document leaves services available for deployment compatibility. Other instances can use a previously allowed result for up to five seconds; in-flight work is not revoked. This is not instantaneous shutdown and not a project-wide spending cap. Direct Rules checks use the control immediately at evaluation time and can add billable rule reads.

## Rate and instance limits

All 47 repository exports use Functions v2. `setGlobalOptions({maxInstances:10})` establishes a per-function ceiling unless overridden. This does not cap aggregate invocation charges or database work. Defaults are proposed deployment settings, not verified active settings.

Evidence and moderation handlers use maxInstances 3, concurrency 4, 512 MiB, 60 seconds; discovery uses 3 / 8 / 60 seconds. The control callable uses 2 / 4 / 30 seconds. Invitations use 3 / 16 / 30 seconds. Account deletion retains 512 MiB and its 300-second timeout, with concurrency 4. Other memory, timeout and concurrency settings are retained. See [complete manifest](financial-protection-functions.json).

Fixed-window per-account limits: evidence submit/review/attach 10 per minute each; report moderation 30; discovery 20; authenticated invitation actions 30. A transaction updates one reusable SHA-256-keyed document per account/operation in `financial_operation_limits`. Concurrent attempts cannot bypass its count. Rejections avoid writes but can still incur transaction reads and invocation cost. These records have no configured TTL and grow with distinct accounts/operations; do not delete them during an incident as that resets limits.

Public invitation requests additionally use an in-memory per-instance 60/minute IP limit with at most 4,096 identities, and a 4 KiB JSON body guard. It is a best-effort shield: many instances, changing IPs, or many accounts can bypass aggregate limits; shared-IP users can encounter 429. No new public rate-limit database is created.

## Admin activation and recovery (owner-approved environment only)

1. First deploy/review Rules and Functions through the existing controlled release process; this pass does not do so. Verify essential account operations against the intended environment.
2. Sign in using an existing, non-disabled admin or developer account. Persisted `users/{uid}.isAdmin` or `isDev` must be exactly true. Client claims alone cannot grant access.
3. Read the control's current revision. Missing control means revision 0.
4. Call `setUagFinancialProtection` in us-central1 with authenticated Firebase callable transport:
   `{active:true, reason:"Investigating unexpected usage spike", expectedRevision:0, requestId:"unique-incident-request-id"}`.
   Use a fresh random request ID of 16–80 letters, digits, underscores or hyphens. Reason is 10–500 characters.
5. Confirm the returned revision and audit document with the same request ID. Repeating exactly the same request is idempotent. If the revision changed, read it and retry with a new request ID. Do not change the control directly in Firestore: client writes, including admin SDK client writes, are denied. Trusted Admin SDK/IAM can bypass Rules, so IAM security remains essential.
6. Within five seconds verify a protected callable returns UNAVAILABLE, invitations return 503, queued outbox/broadcast work is marked blocked, and essential account/blueprint operations remain available.
7. Investigate service metrics and abusive identities. After remediation, call the same endpoint with `active:false`, current revision, a recovery reason and a new request ID. Confirm new work succeeds and inspect the audit. Review blocked messages/broadcasts before user/admin resubmission; do not blindly replay potentially harmful queued work.

Keep account tokens inside the authenticated application/approved admin tooling. Do not paste credentials into tickets, logs or this report. No new admin dashboard or public toggle was added.

## App Check staged rollout

[UagAppCheck](../lib/services/uag_app_check.dart) initializes immediately after Firebase initialization. It is disabled by default. The installed FlutterFire package supports Android Play Integrity, Apple App Attest with DeviceCheck fallback, and web reCAPTCHA v3. Windows/Linux return unsupported rather than inventing attestation. See [official Flutter setup](https://firebase.google.com/docs/app-check/flutter/default-providers).

For an approved monitoring build use `--dart-define=UAG_APP_CHECK_ENABLED=true`; web also needs `--dart-define=UAG_APP_CHECK_WEB_SITE_KEY=<public-site-key>`. Debug providers require both a debug build and explicit `UAG_APP_CHECK_DEBUG=true`; register any debug token securely in the test project only. No token was requested or logged by our code.

Firebase SDK traffic attaches its own tokens after activation. The existing manual HTTP/callable clients now attach cached `X-Firebase-AppCheck` tokens, with bounded waits. Monitoring-mode initialization/token failures preserve account access; this behavior is not enforcement. The invitation gateway verifies presented tokens and can require them with the future server setting `UAG_REQUIRE_APP_CHECK=true`. Other onRequest handlers do not thereby gain enforcement. Callable enforcement flags remain off.

Before enabling any enforcement: register each app/provider and approved web domain; test real signed Android installs, Apple devices, web/PWA, token refresh, sign-out/sign-in, expired/invalid tokens and offline recovery; inspect valid/invalid/missing metrics; resolve Windows support or explicitly revise the supported-client policy. Emulator tests exercise an injected verifier, not Google attestation. Never infer real-device validity from a debug APK or mocked token.

## Hosting and PWA

The release metadata tool makes SHA-256-named copies of public-site JS/CSS and updates generated HTML references; aliases remain for existing links. Only these content-addressed names receive a one-year immutable cache. Flutter assets use revalidation (max-age=0), preserving update correctness with 304 responses. HTML, service workers, bootstraps, manifests, version metadata and the update manager keep their prior conservative cache policy.

Run `flutter build web --release --no-wasm-dry-run`, then `dart run tool/prepare_web_release.dart --output build/web/version.json` before serving/releasing. Do not deploy from raw source or skip metadata preparation. The existing release scripts already invoke that preparation. Cache limits are not bandwidth spending limits. Old hashed resources may disappear in a later deployment; retain the previous release for rollback and test refresh/navigation across versions before production release.

HTTP/artifact tests do not certify native PWA installation, push delivery or an offline upgrade. Those device/browser checks remain required. The Windows Firebase CLI 15.11.0/superstatic 10 path helper converts URL slashes to backslashes, preventing custom header matching locally. The explicit test-only preload `scripts/financial_hosting_windows_url_shim.cjs` normalizes these in memory; it changes neither installed dependencies nor production. Revalidate unmodified on Linux CI and on an approved preview before deployment.

## Deployment and rollback boundaries

No new composite indexes are required by the changed queries. Existing index availability, deployed Rules, IAM, quotas and budget/enforcement state remain console checks. Deploy Rules/Functions/client/Hosting as a reviewed compatible release; do not assume deploying only the Flutter app activates server protections. Monitor latency and rejection rates before narrowing limits further.

Rollback to a reviewed prior release needs owner approval. Do not roll back only Rules and leave the admin control client-writable. Preserve audit records. Do not disable billing, delete user data, remove retention settings, alter signing, or change monetisation entitlements as an emergency shortcut.
