# UAG rewarded ad commercial model — 14 September 2026

## Recommendation and evidence

Keep rewarded disabled. Pilot only a non-transferable, expiring convenience action already available to Free users, at 3 completed views per user per UTC day and at least 20 minutes apart. Never unlock paid intel, extra paid-tier listing capacity, advanced planner access, subscription time, commission credit, verified-contract counts or leaderboard rank. No price changes.

The existing Google Mobile Ads Flutter SDK supports rewarded loading and earned-reward callbacks: [Google Flutter rewarded documentation](https://developers.google.com/admob/flutter/rewarded). The app currently integrates banners/interstitial/app-open only. A disabled pure policy gate was added, not a production rewarded integration.

Research checked 14 September 2026. [Appodeal's 2025 report](https://appodeal.com/wp-content/uploads/2025/03/Appodeal-The-Latest-eCPM-Report-2025.pdf) covers October–December 2024, despite its 2025 title. It reports rewarded leading other formats and important platform/geographic differences. It is historical context, not a September 2026 UK Android forecast. No validated current numeric UAG benchmark was available from this research, so the following pound-denominated numbers are explicit scenarios, not claimed benchmarks or converted dollar rates.

## Scenario math

Assumptions: every modelled view is completed and monetised, all modelled DAU participate, eCPM is publisher ad revenue per 1,000 monetised impressions. Approximation allocates that revenue to completed views; actual impression and completion counts differ. Gross excludes taxes, operating costs, reward cost, invalid traffic adjustments and subscription cannibalisation. Do not subtract an assumed network fee again from already publisher-net reported eCPM.

Revenue per view = eCPM / 1,000. Daily revenue = participating DAU × completed monetised views per user per day × eCPM / 1,000. No fill factor is applied again once monetised completions are counted.

| Scenario eCPM | Per completed monetised view | 3 views/user/day | 5 views/user/day | 10 views/user/day |
|---|---|---|---|---|
| £5 | £0.005 | £0.015 | £0.025 | £0.050 |
| £10 | £0.010 | £0.030 | £0.050 | £0.100 |
| £15 | £0.015 | £0.045 | £0.075 | £0.150 |
| £20 | £0.020 | £0.060 | £0.100 | £0.200 |

| eCPM | Views/user/day | 100 participating DAU/day | 1,000 participating DAU/day | 10,000 participating DAU/day |
|---|---|---|---|---|
| £5 | 3 | £1.50 | £15.00 | £150.00 |
| £5 | 5 | £2.50 | £25.00 | £250.00 |
| £5 | 10 | £5.00 | £50.00 | £500.00 |
| £10 | 3 | £3.00 | £30.00 | £300.00 |
| £10 | 5 | £5.00 | £50.00 | £500.00 |
| £10 | 10 | £10.00 | £100.00 | £1000.00 |
| £15 | 3 | £4.50 | £45.00 | £450.00 |
| £15 | 5 | £7.50 | £75.00 | £750.00 |
| £15 | 10 | £15.00 | £150.00 | £1500.00 |
| £20 | 3 | £6.00 | £60.00 | £600.00 |
| £20 | 5 | £10.00 | £100.00 | £1000.00 |
| £20 | 10 | £20.00 | £200.00 | £2000.00 |

5 and 10 views are sensitivity cases only, not recommended product caps. For 1,000 total DAU with 20% opt-in, 3 requests/day, 80% fill and 90% completion, expected monetised completions are 432/day; at £10 scenario eCPM that is approximately £4.32/day (£129.60 over 30 identical days), rather than £30/day. This approximation assumes completion-weighted revenue and must be replaced by observed impression revenue. Android-only delivery, geographic mix, consent eligibility, seasonality, match rate, show rate and user retention can materially alter results. Web traffic is not monetised by the present mobile SDK.

## Reward economics and subscription protection

Use a conservative initial incremental fulfilment budget of at most 20% of the £5 scenario: £0.001 per normal reward (0.1p), £0.003/user/day at the recommended cap. This is an internal cost ceiling, not a cash value promised to users and not a guaranteed profitable margin. If measured lower-bound net revenue after variable costs cannot cover it, reduce the cost or disable the placement. Subscription displacement can dwarf a fraction of a penny; no paid entitlements should be substitutable even if their fulfilment cost is zero.

| Candidate | Decision | Protection |
|---|---|---|
| One extra refresh of already-Free non-critical information | Best pilot candidate, subject to API cost and useful freshness | No paid fields; one use; short expiry; no stacking; daily cap |
| Cosmetic temporary badge | Possible after identity design review | Not verified/trusted/creator/hunter status; non-transferable; no payout |
| Convenience credit | Only for a tightly named Free action | No general currency; no transfer/conversion; no accumulation |
| Notification/watch slot | Defer | Can substitute paid capacity; only reconsider with entitlement comparison and absolute concurrent cap |
| Community/Creator Points | Reject for pilot | Existing points may affect commercial eligibility/recognition; avoid connecting to payout or rank |
| Premium snapshot, advanced insight, additional paid listing | Reject | Repeated viewing must not reconstruct Essential or Premium |
| Cash, gift card, transferable prize/credit | Reject | Disallowed direct monetary reward categories and unacceptable economics |

Google requires non-monetary rewards to remain within the publisher's platform and non-transferable; direct money, cryptocurrency and gift cards are prohibited. Clearly disclose the exact reward before each voluntary opt-in, allow dismissal without blocking ordinary use, and deliver the promised reward. Do not use “support us” pressure copy. These constraints inform the recommendations above; they are not a legal approval for a future programme. [Google reward policies](https://support.google.com/admob/answer/7313578?hl=en-GB).

## Architecture required before enabling

Use the same google_mobile_ads package. Add a rewarded unit only after production consent/request gating exists; internal QA must use Google's test unit. Client flow: unavailable → loading → ready → explicit offer → presenting → awaiting verified grant → granted/failed. No-fill, cancellation and presentation failure must preserve normal access and must not grant a reward. Do not equate ad dismissal with successful completion.

Use [Google server-side verification](https://developers.google.com/admob/flutter/ssv) to authenticate callbacks. The server must verify the signature and expected ad unit, bind a short-lived opaque request nonce to the authenticated account and allowed placement/reward, reject expired/replayed transactions, and atomically record transaction identity plus consume the UTC-day cap before granting one expiring use. Persist per-user cap across devices; server time is authoritative. A retry for the same transaction returns the same result. The client displays pending state and queries the durable result; client reward callbacks do not mint entitlement. Reconcile delayed verified callbacks without double grants or losing promised delivery. Device reinstall/clock changes must not reset caps. No client-provided tier, country or reward value is authoritative.

The new `UagRewardedAdPolicy` implements only disabled local eligibility with a hard upper cap, explicit opt-in, consent/server-readiness inputs and cooldown. It is not a server, SDK adapter or security boundary. No Firestore schema/rules/function deployments or production configuration changes were made.

Measure: eligible Free DAU, offers, opt-in, requests, fill, impressions, completions, paid revenue by platform/country, verified grants, duplicates rejected, cap hits, reward consumption, support failures, Free retention and subscription conversion. Roll back on grant divergence, material conversion decline, or negative contribution margin. Validate one reward end-to-end in test inventory before a limited cohort. Pricing and existing referral/commission calculations remain unchanged.

Integration update: release SDK initialisation and ad requests now enforce the existing controller's completed-consent + canRequestAds state. The real UMP flow and rewarded adapter/server grants remain unimplemented and disabled.
