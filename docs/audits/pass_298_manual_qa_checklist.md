# PASS 298 Manual QA Checklist

Use this checklist after repository validation passes and required provider configuration is available. Do not mark provider/device checks complete from simulator-only or fixture-only runs.

## Environment

- Install Java 21 JDK.
- Set `JAVA_HOME` and `PATH` to Java 21.
- Run `.\scripts\validate_release_environment.ps1 -RequireJava21 -RequireCleanTree`.
- Run `.\scripts\run_firebase_emulator_tests.ps1`.
- Confirm Firebase CLI project target is the intended closed-beta project.

## Fresh Registration And Onboarding

- Create a fresh account.
- Enter a valid adult date of birth.
- Confirm server-recorded 18+ verification.
- Try an under-18 DOB and confirm rejection.
- Try a future DOB and confirm rejection.
- Accept Terms, Acceptable Use, Community Guidelines and Beta Terms separately.
- Acknowledge Privacy Notice and fan-project notice without bundling optional consent.
- Enter Embark ID.
- Complete profile setup, archetypes, communication preferences, squad intent, social energy, availability and shift patterns.
- Continue as Free.
- Verify notification, microphone and photo permissions are requested at the correct moment.
- Confirm final route lands in Command Centre/My Hub.

## Age-Gated Surfaces

- With an unverified test user, attempt messaging, trading, Match Rider, contracts, image import, creator application and checkout.
- Confirm each path is blocked with recoverable age-verification messaging.
- With a verified test user, confirm the same paths can proceed to their next normal validation gate.

## Billing

- Configure Stripe test price IDs for Essential monthly.
- Configure Stripe test price IDs for Premium monthly.
- Configure Stripe test price ID for Founding Supporter monthly.
- Complete Essential sandbox checkout and verify user tier becomes Essential.
- Complete Premium sandbox checkout and verify user tier becomes Premium.
- Complete Founding Supporter sandbox checkout and verify supporter entitlement is active without Premium/Essential tier.
- Cancel each subscription and verify entitlement downgrade state.
- Test failed payment/grace-period webhook where available.
- Open customer portal and return to app.
- Verify Free plus Supporter still follows Free ad policy unless separately configured.

## Creator Programme

- Submit creator application as a verified adult.
- Confirm unverified user cannot submit.
- Request campaign code.
- Admin approves/rejects campaign code.
- Complete referred Stripe checkout.
- Confirm commission ledger entry is created by webhook only.
- Confirm client cannot write commission conversions.

## Messaging, Blocks And Moderation

- Send an ordinary direct message between verified users.
- Block a user and confirm messages, trade offers and Match Rider invites are blocked both directions.
- Send a private contact/payment request and confirm warning state.
- Send a credential phishing/blocked-domain message and confirm quarantine.
- Send a severe threat test string in a controlled test account and confirm blocked/escalated state.
- Enable external moderation provider in test project and confirm provider categories/audit metadata appear.
- Disable or break provider config and confirm provider-unavailable state is clear and reviewable.
- File message and conversation reports.
- Admin reviews queue, warns, dismisses, restores, restricts and records appeal outcome.

## Notifications

- Register current web device token.
- Register current Android device token.
- Send admin test notification to current user.
- Verify foreground notification/inbox entry.
- Verify background notification tap/deep link.
- Verify terminated-app notification tap/deep link.
- Verify unread badge increments and clears.
- Verify invalid-token cleanup after forcing an invalid token in a safe test doc.

## Voice

- Confirm speech recognition availability.
- Grant and deny microphone permission.
- Test wake phrase, timeout, cancel, repeat and stop speaking.
- Ask item relevance/recycle safety questions.
- Ask Scrappy, Bench, quest and Favourite Loadout questions.
- Confirm safe writes require explicit confirmation.
- Confirm TTS uses concise and detailed responses where configured.

## Blueprint Photo Import

- Start a photo import session.
- Confirm OCR/provider-required state appears when provider is missing.
- Upload authorised synthetic/local fixture images only.
- Verify local overlap stitching removes duplicate overlap rows.
- Verify uncertain cells go to review.
- Correct a cell manually.
- Confirm nothing writes ownership state until explicit user confirmation.
- Delete the session and verify screenshot access/removal behaviour.

## Personal Item Intelligence

- Ask whether to keep, trade, sell or recycle a known quest/bench/loadout blocker.
- Confirm protected resources are not marked safe to recycle.
- Confirm surplus can be listed/traded only when requirements are protected.
- Confirm stale/unknown items return UNKNOWN rather than fake recycle advice.

## Trading

- Create direct trade listing.
- Create offer.
- Accept offer.
- Book trade session.
- Share Embark ID.
- Confirm blocked users cannot contact or trade.
- Confirm circular/direct trade recommendations still load.

## Raid Intelligence Maps

- Blue Gate Surface.
- Blue Gate Level 2.
- Buried City Surface.
- Stella Montis Surface.
- Stella Montis Level 2.
- Riven Tides Surface.
- Dam Battlegrounds Surface.
- Spaceport Surface.
- Spaceport Level 2.
- Confirm correct image, layer selector, provisional label, marker cluster, detail card, filters and route builder.

## Responsive UI

Check each at 375, 768, 1024, 1440 and 1920 width:

- Command Centre.
- Onboarding.
- Blueprint Tracker.
- Scrappy, Quest and Bench trackers.
- Favourite Loadout.
- Raid Intelligence.
- Trading Hub and Smart Trade Assist.
- Creator Dashboard.
- Legal Hub.
- Subscription screens.
- Communications Centre.
- Admin Console.

## Legal And Data Rights

- Confirm fan-project notice appears in footer/About/Legal Hub/map-heavy screens.
- Confirm operator details are not fake.
- Submit data export request.
- Submit deletion request.
- Submit copyright/takedown request.
- Submit moderation appeal.
- Confirm admin can see request without exposing private evidence publicly.

## Deployment

- Run web build.
- Run Android debug build.
- Deploy Hosting.
- Deploy Firestore rules.
- Deploy Firestore indexes.
- Deploy Storage rules.
- Deploy Functions only after secrets/config pass.
- Record each result separately.
