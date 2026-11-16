# Firebase / Google Cloud owner configuration checklist

Prepared 16 November 2026 for project `unite-a-gamer`. No console setting was changed. Approval is required for deployments, new alerts/caps/quotas, enforcement, IAM changes, API activation or billing changes.

Read-only observations from 13–14 November: project billing was enabled; 42 deployed functions were reported ACTIVE, all gcfv2/nodejs22/us-central1. See [sanitized observation](financial-protection-live-functions.json). Some responses specified maxInstances 20 or 10; others omitted it. Omission is **not** evidence of unlimited scaling. Source now contains 47 exports; source presence does not establish deployment.

Budget listing could not complete because the Billing Budgets API was disabled in the command's project context; it was not enabled. This does not prove no budgets exist. App Check service inspection returned HTTP 403. Enforcement is therefore **NOT VERIFIED**. Actual usage, expenditure, billing currency and cap eligibility were not obtained.

| Check | Status | Exact console location and evidence required |
|---|---|---|
| 1. Current total spend | NOT VERIFIED | [Billing](https://console.cloud.google.com/billing?project=unite-a-gamer) → linked account → Reports; project filter, current month and last 30 days; export dated gross/net cost, credits, currency, forecast. |
| 2. Billing by service | NOT VERIFIED | Same Billing Reports, group by Service then SKU; include taxes/credits treatment and cost attribution. Do not confuse free-tier allowances with spend caps. |
| 3. Daily Firestore operations | NOT VERIFIED | [Firestore usage](https://console.firebase.google.com/project/unite-a-gamer/firestore/usage); daily reads/writes/deletes, peak/hourly periods and last 7/30-day trends; correlate with active-user/feature usage. |
| 4. Firestore storage/bandwidth | NOT VERIFIED | [Firestore](https://console.cloud.google.com/firestore/databases?project=unite-a-gamer) and Billing Reports; document/index storage, egress, backups, PITR, TTL deletes and query/index-read charges. |
| 5. Hosting bandwidth | NOT VERIFIED | [Firebase Hosting](https://console.firebase.google.com/project/unite-a-gamer/hosting); transfer/storage by site, retention and release count; repeat-request cache hit/304 evidence from an approved preview. |
| 6. Functions invocations/cost | PARTIAL: inventory only | [Functions](https://console.firebase.google.com/project/unite-a-gamer/functions) and [Cloud Run](https://console.cloud.google.com/run?project=unite-a-gamer); per-function requests, instance count, concurrency, duration, CPU/memory, errors/retries and egress. Compare live revisions/options with this branch; source limits are not active yet. |
| 7. Storage charges | NOT VERIFIED | [Buckets](https://console.cloud.google.com/storage/browser?project=unite-a-gamer); bytes, object count, operations, downloads, egress, soft-delete/versioning/retention and location; Billing storage SKUs. Review orphaned evidence without deleting anything automatically. |
| 8. Other enabled services | PARTIAL: enabled inventory | [APIs dashboard](https://console.cloud.google.com/apis/dashboard?project=unite-a-gamer); 57 enabled services observed, including Cloud Run/Functions/Scheduler/Eventarc/PubSub/Build/Artifact Registry/Logging, Storage/Firestore/Auth, BigQuery/Dataform/Dataplex/Analytics Hub, Generative Language, App Engine and Testing. Enabled does not imply used or charged. Export per-API request/byte/cost metrics; inspect Natural Language moderation, build artifacts, logs and third-party Stripe activity separately. |
| 9. Existing budgets/alerts | NOT VERIFIED | [Billing budgets](https://console.cloud.google.com/billing/budgets?project=unite-a-gamer); confirm linked account, project scope, recipients, thresholds, notifications delivered and any pre-existing automation. API-list failure is not evidence of absence. |
| 10. Functions spend-cap eligibility | NOT VERIFIED for this account | Same budget console; verify direct Google billing versus reseller, single-project/single-service scope, supported Cloud Run/Functions service, monthly period, estimated gross-cost basis and available cap controls. Owner must approve service interruption risk. |
| 11. App Check enforcement | NOT VERIFIED (403) | [App Check](https://console.firebase.google.com/project/unite-a-gamer/appcheck); export registered app/provider/domain status plus per-service valid/invalid/missing request metrics and enforcement flags. Validate Android/Apple/web/PWA; resolve Windows before enforcement. |
| 12. Quotas/instance settings | PARTIAL: functions inventory | [Quotas](https://console.cloud.google.com/iam-admin/quotas?project=unite-a-gamer), Cloud Run revisions, [Scheduler](https://console.cloud.google.com/cloudscheduler?project=unite-a-gamer); verify max/min instances, concurrency, timeout, retry/retention policies and per-API quotas. Do not lower quotas blindly. |

## Proposed alert-only budget

Subject to owner approval, account currency and baseline cost: create a project-scoped monthly alert-only budget equivalent to £5. Use actual-spend warnings at 50%, 80%, 100% and forecast at 100%; send to the billing owner plus an agreed backup. Confirm a test notification and who responds. If unavoidable baseline already exceeds this amount, agree a realistic amount rather than ignoring constant alerts. No exchange rate or actual cost is assumed here. An alert budget never guarantees a £5 maximum bill.

Current official documentation offers **preview service spend caps** for selected services including Cloud Functions, with delayed enforcement and possible billed overages. Firestore and classic Firebase Hosting are not listed eligible services; Firebase App Hosting is different. Treat service caps as another protection layer, not a hard project-wide ceiling. [Firebase spend-cap documentation](https://firebase.google.com/docs/projects/billing/spend-caps), [Google Cloud eligibility/configuration](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps).

Do not enable automated billing shutdown. It can interrupt essential account/data services and does not erase already incurred charges.

## Evidence required before controlled beta certification

- Owner confirms actual baseline, budget recipients and incident owner; approved budget/cap decisions are recorded.
- Reviewed Functions/Rules/client/Hosting release is deployed through the normal approved process, followed by live option/rule/index inspection. This task does not authorize deployment.
- Demonstrate emergency activation, five-second cache propagation, audit receipt, essential account/blueprint access, restoration and readable failure on supported clients in an approved non-production environment.
- Validate real App Check providers in monitoring mode, then obtain separate approval before enforcement. A mock verifier or debug provider is not production attestation.
- Run unmodified Hosting checks on Linux CI/approved preview; verify immutable headers, CDN conditional 304s, cold/repeat load, installed PWA update/offline recovery, manifests and push workers.
- Measure actual small-cohort usage before opening broadly. Agree follow-up thresholds for paginated listing/discovery UI, resumable alert fan-out, Storage retention and abuse at public endpoints. No live load test was performed.
