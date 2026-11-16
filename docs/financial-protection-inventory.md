# Firebase source inventory

Source candidates from the isolated checkout, not proof of deployed or active runtime traffic. Dynamic collection paths are not fully enumerated. Main UAG, ARC and public website are covered.

## Functions

All 47 exports use v2. Default maxInstances 10, explicit overrides below. Defaults inherit the platform; they are not verified live settings. Authentication and work bounds are reviewed by handler family in the audit.

| Export/source | Type | Max instances | Memory MiB | Timeout s | Concurrency | Trigger |
|---|---|---:|---|---|---|---|
| [functions/index.js:801](../functions/index.js#L801) createUagCheckoutSession | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:1054](../functions/index.js#L1054) setUagFoundingRaiderStatus | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:1212](../functions/index.js#L1212) createUagCustomerPortalSession | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:1239](../functions/index.js#L1239) redeemUagGift | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:1405](../functions/index.js#L1405) uagStripeWebhook | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:2961](../functions/index.js#L2961) queueCommunityReferralValidation | Firestore event | 10 | [object Object] | [object Object] | [object Object] | users/{referredUid}/monetisation_usage/community_referral_attribution |
| [functions/index.js:2993](../functions/index.js#L2993) activateReferralRewardAuthoritatively | Firestore event | 10 | [object Object] | [object Object] | [object Object] | uag_referral_reward_activation_requests/{requestId} |
| [functions/index.js:3115](../functions/index.js#L3115) releaseCreatorCommissionDaily | schedule | 10 | [object Object] | [object Object] | [object Object] | every day 03:15 |
| [functions/index.js:3169](../functions/index.js#L3169) expireCreatorCancellationGraceDaily | schedule | 10 | [object Object] | [object Object] | [object Object] | every day 03:45 |
| [functions/index.js:3201](../functions/index.js#L3201) validateCommunityReferralsDaily | schedule | 10 | [object Object] | [object Object] | [object Object] | every day 04:15 |
| [functions/index.js:3225](../functions/index.js#L3225) expireReferralRewardsHourly | schedule | 10 | [object Object] | [object Object] | [object Object] | every 60 minutes |
| [functions/index.js:4381](../functions/index.js#L4381) syncTradingSessionNotificationSchedules | Firestore event | 10 | [object Object] | [object Object] | [object Object] | trading_sessions/{sessionId} |
| [functions/index.js:4386](../functions/index.js#L4386) syncUagSessionNotificationSchedules | Firestore event | 10 | [object Object] | [object Object] | [object Object] | uag_sessions/{sessionId} |
| [functions/index.js:4391](../functions/index.js#L4391) processUagNotificationSchedules | schedule | 10 | [object Object] | [object Object] | [object Object] | every 5 minutes |
| [functions/index.js:4417](../functions/index.js#L4417) sendTradingNotificationPush | Firestore event | 10 | [object Object] | [object Object] | [object Object] | trading_notifications/{notificationId} |
| [functions/index.js:4436](../functions/index.js#L4436) sendUagNotificationBroadcast | Firestore event | 10 | [object Object] | [object Object] | [object Object] | notification_broadcasts/{broadcastId} |
| [functions/index.js:4564](../functions/index.js#L4564) uagReleaseHealthCheck | HTTP | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4612](../functions/index.js#L4612) processUagAgeVerificationRequest | Firestore event | 10 | [object Object] | [object Object] | [object Object] | uag_age_verification_requests/{requestId} |
| [functions/index.js:4655](../functions/index.js#L4655) processUagMessageOutbox | Firestore event | 10 | [object Object] | [object Object] | [object Object] | uag_message_outbox/{messageId} |
| [functions/index.js:4792](../functions/index.js#L4792) submitRaiderContractEvidence | callable | 3 | 512 | 60 | 4 |  |
| [functions/index.js:4794](../functions/index.js#L4794) reviewRaiderContractEvidence | callable | 3 | 512 | 60 | 4 |  |
| [functions/index.js:4796](../functions/index.js#L4796) setUagFinancialProtection | callable | 2 | [object Object] | 30 | 4 |  |
| [functions/index.js:4807](../functions/index.js#L4807) recordTradingBetrayal | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4808](../functions/index.js#L4808) attachRaiderReportEvidence | callable | 3 | 512 | 60 | 4 |  |
| [functions/index.js:4810](../functions/index.js#L4810) moderateRaiderReport | callable | 3 | 512 | 60 | 4 |  |
| [functions/index.js:4812](../functions/index.js#L4812) discoverRaiderContracts | callable | 3 | [object Object] | 60 | 8 |  |
| [functions/index.js:4814](../functions/index.js#L4814) acceptRaiderContract | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4815](../functions/index.js#L4815) raiderAccountCases | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4816](../functions/index.js#L4816) challengeRaiderContract | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4817](../functions/index.js#L4817) reviewRaiderContractChallenge | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4818](../functions/index.js#L4818) expireRaiderContracts | schedule | 10 | [object Object] | [object Object] | [object Object] | every 60 minutes |
| [functions/index.js:4819](../functions/index.js#L4819) withdrawRaiderContract | Firestore event | 10 | [object Object] | [object Object] | [object Object] | arc_raider_reports/{reportId} |
| [functions/index.js:4821](../functions/index.js#L4821) raiderContractAdminContext | callable | 10 | [object Object] | [object Object] | [object Object] |  |
| [functions/index.js:4822](../functions/index.js#L4822) auditRaiderContractLifecycle | Firestore event | 10 | [object Object] | [object Object] | [object Object] | arc_raider_contracts/{contractId} |
| [functions/index.js:4838](../functions/index.js#L4838) deleteUagAccount | callable | 10 | 512 | 300 | 4 |  |
| [functions/index.js:4842](../functions/index.js#L4842) preventDeletedAccountResurrection | Firestore event | 10 | [object Object] | [object Object] | [object Object] | users/{userId} |
| [functions/index.js:4846](../functions/index.js#L4846) preventDeletedSupporterEntitlementResurrection | Firestore event | 10 | [object Object] | [object Object] | [object Object] | supporter_entitlements/{userId} |
| [functions/index.js:4855](../functions/index.js#L4855) prepareUagRewardedAd | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4856](../functions/index.js#L4856) cancelUagRewardedAd | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4857](../functions/index.js#L4857) redeemUagRaiderMarks | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4858](../functions/index.js#L4858) verifyUagRewardedAd | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4864](../functions/index.js#L4864) redeemUagReferralActionReward | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4873](../functions/index.js#L4873) redeemUagOperationActionReward | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4882](../functions/index.js#L4882) redeemUagOperationCompletionReward | HTTP | 10 | [object Object] | 60 | [object Object] |  |
| [functions/index.js:4888](../functions/index.js#L4888) uagTradeInviteGateway | HTTP | 3 | [object Object] | 30 | 16 |  |
| [functions/index.js:4898](../functions/index.js#L4898) evaluateUagTradeReferralIncentives | schedule | 10 | [object Object] | [object Object] | [object Object] | every day 06:25 |
| [functions/index.js:4906](../functions/index.js#L4906) notifyAutomaticTradingWatches | Firestore event | 10 | [object Object] | [object Object] | [object Object] | trading_listings/{listingId} |

## Firebase initialization

| Source | Expression |
|---|---|
| [lib/firebase_options.dart:13](../lib/firebase_options.dart#L13) | /// await Firebase.initializeApp( |
| [lib/main.dart:94](../lib/main.dart#L94) | await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); |
| [web/firebase-messaging-sw.js:15](../web/firebase-messaging-sw.js#L15) | firebase.initializeApp({ |
| [functions/index.js:37](../functions/index.js#L37) | admin.initializeApp(); |

## Snapshot listener sites

| Source | Expression |
|---|---|
| [lib/screens/build/feedback_screen.dart:177](../lib/screens/build/feedback_screen.dart#L177) | .snapshots(), |
| [lib/screens/build/feedback_screen.dart:305](../lib/screens/build/feedback_screen.dart#L305) | stream: query.snapshots(), |
| [lib/screens/build/feedback_screen.dart:649](../lib/screens/build/feedback_screen.dart#L649) | .snapshots(), |
| [lib/screens/build/admin_console_screen.dart:234](../lib/screens/build/admin_console_screen.dart#L234) | stream: configRef.snapshots(), |
| [lib/screens/build/admin_console_screen.dart:414](../lib/screens/build/admin_console_screen.dart#L414) | stream: feedbackQuery.snapshots(), |
| [lib/screens/build/admin_console_screen.dart:678](../lib/screens/build/admin_console_screen.dart#L678) | stream: configRef.snapshots(), |
| [lib/screens/build/admin_console_screen.dart:1676](../lib/screens/build/admin_console_screen.dart#L1676) | stream: configRef.snapshots(), |
| [lib/screens/build/admin_business_metrics_panel.dart:13](../lib/screens/build/admin_business_metrics_panel.dart#L13) | stream: firestore.collection('users').snapshots(), |
| [lib/screens/build/admin_business_metrics_panel.dart:20](../lib/screens/build/admin_business_metrics_panel.dart#L20) | .snapshots(), |
| [lib/screens/build/admin_business_metrics_panel.dart:25](../lib/screens/build/admin_business_metrics_panel.dart#L25) | .snapshots(), |
| [lib/screens/admin_console_screen.dart:237](../lib/screens/admin_console_screen.dart#L237) | stream: configRef.snapshots(), |
| [lib/screens/admin_console_screen.dart:372](../lib/screens/admin_console_screen.dart#L372) | stream: feedbackQuery.snapshots(), |
| [lib/screens/admin_console_screen.dart:605](../lib/screens/admin_console_screen.dart#L605) | stream: configRef.snapshots(), |
| [lib/screens/admin_console_screen.dart:1529](../lib/screens/admin_console_screen.dart#L1529) | stream: configRef.snapshots(), |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:58](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L58) | return query.snapshots().map( |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:72](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L72) | .snapshots() |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:128](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L128) | .snapshots() |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:152](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L152) | .snapshots() |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:160](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L160) | .snapshots() |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:273](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L273) | .snapshots() |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:281](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L281) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart:20](../lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart#L20) | .snapshots(), |
| [lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart:26](../lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart#L26) | .snapshots(), |
| [lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart:104](../lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart#L104) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart:115](../lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart#L115) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart:49](../lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart#L49) | .snapshots(), |
| [lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart:3253](../lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart#L3253) | .snapshots(); |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:391](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L391) | .snapshots(), |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:424](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L424) | stream: doc.reference.collection('votes').snapshots(), |
| [lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart:44](../lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart#L44) | .snapshots().map((snapshot) => { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:184](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L184) | () => _tradingProfileDoc(normalizedUid).snapshots().asyncMap( |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:614](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L614) | return _tradingProfileDoc(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:625](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L625) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:680](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L680) | return _tradePreferencesCollection.doc(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:705](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L705) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:884](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L884) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1160](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1160) | return _blueprintStatesCollection(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1225](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1225) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1281](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1281) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1605](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1605) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1625](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1625) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2120](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2120) | senderSub = senderQuery.snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2124](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2124) | receiverSub = receiverQuery.snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2196](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2196) | traderOneSub = traderOneQuery.snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2200](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2200) | traderTwoSub = traderTwoQuery.snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart#L29) | return _doc.snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart:15](../lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart#L15) | return _entries.snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:47](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L47) | return _profileRef(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart:20](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart#L20) | yield* ref.snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart:27](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart#L27) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart:57](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart#L57) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:719](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L719) | return profileDoc(uid).snapshots().asyncMap((profileSnapshot) async { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:818](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L818) | return availabilityDoc(uid).snapshots().map( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:925](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L925) | userSubscription = _userDoc(uid).snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:929](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L929) | profileSubscription = profileDoc(uid).snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:933](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L933) | availabilitySubscription = availabilityDoc(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:1051](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L1051) | return awayDoc(uid).snapshots().map( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:67](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L67) | return _seasonRef(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart:78](../lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart#L78) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:85](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L85) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:98](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L98) | .doc('favourite-loadout').snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:90](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L90) | seasonSubscription = _seasonRef(uid).snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:95](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L95) | questSubscription = _questProgressRef(uid).snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:106](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L106) | questStateSubscription = _questStateRef(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:116](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L116) | scrappySubscription = _scrappyProgressRef(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:125](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L125) | benchSubscription = _benchProgressRef(uid).snapshots().listen((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L29) | return _activeDatasetVersionRef.snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:91](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L91) | return _protections(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:108](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L108) | summarySubscription = _summaryRef(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:115](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L115) | profileSubscription = _profileRef(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:122](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L122) | telemetrySubscription = _telemetrySummaryRef(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:129](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L129) | seasonSubscription = _seasonRef(uid).snapshots().listen((seasonSnapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:134](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L134) | configSubscription = _operationsConfigRef().snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:193](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L193) | userSub = _firestore.collection('users').doc(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:209](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L209) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:217](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L217) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:302](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L302) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:364](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L364) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:378](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L378) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L29) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:69](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L69) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:104](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L104) | return _stateCollection(uid).snapshots().asyncMap( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:337](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L337) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:366](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L366) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:22](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L22) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart:15](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart#L15) | return _collection.doc(blueprintId).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:309](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L309) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:324](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L324) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:340](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L340) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:369](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L369) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:381](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L381) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:31](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L31) | return _targetCollection(uid).snapshots().map((snapshot) { |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:60](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L60) | .snapshots() |
| [lib/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart:161](../lib/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart#L161) | var snapshots = ArcCommandCentreViewMapper.snapshots(decisionState); |
| [lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart:23](../lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart#L23) | return _document().snapshots().map((snap)=>ArcAmplificationState.fromMap(snap.data()?['progress'] is Map<String,dynamic> ? snap.data()!['progress'] as Map<String,dynamic> : null)); |
| [lib/features/release/widgets/uag_release_readiness_panel.dart:17](../lib/features/release/widgets/uag_release_readiness_panel.dart#L17) | .snapshots(), |
| [lib/features/notifications/data/uag_notification_repository.dart:52](../lib/features/notifications/data/uag_notification_repository.dart#L52) | return _preferencesDoc(uid).snapshots().map( |
| [lib/features/notifications/data/uag_notification_repository.dart:165](../lib/features/notifications/data/uag_notification_repository.dart#L165) | .snapshots() |
| [lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart:90](../lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart#L90) | .snapshots(), |
| [lib/features/monetisation/widgets/uag_commercial_offers_panel.dart:239](../lib/features/monetisation/widgets/uag_commercial_offers_panel.dart#L239) | .snapshots(), |
| [lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart:226](../lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart#L226) | stream: _firestore.collection('uag_discount_campaigns').snapshots(), |
| [lib/features/monetisation/services/uag_referral_action_reward_service.dart:86](../lib/features/monetisation/services/uag_referral_action_reward_service.dart#L86) | .snapshots() |
| [lib/features/monetisation/services/uag_raider_mark_service.dart:65](../lib/features/monetisation/services/uag_raider_mark_service.dart#L65) | .snapshots() |
| [lib/features/monetisation/services/uag_raider_mark_service.dart:81](../lib/features/monetisation/services/uag_raider_mark_service.dart#L81) | .snapshots() |
| [lib/features/monetisation/services/uag_operation_action_reward_service.dart:92](../lib/features/monetisation/services/uag_operation_action_reward_service.dart#L92) | .snapshots() |
| [lib/features/monetisation/services/uag_entitlement_service.dart:76](../lib/features/monetisation/services/uag_entitlement_service.dart#L76) | .snapshots() |
| [lib/features/monetisation/services/uag_entitlement_service.dart:173](../lib/features/monetisation/services/uag_entitlement_service.dart#L173) | monthlySub = base.doc(_currentMonthKey()).snapshots().listen(( |
| [lib/features/monetisation/services/uag_entitlement_service.dart:181](../lib/features/monetisation/services/uag_entitlement_service.dart#L181) | weeklySub = base.doc(_currentWeekKey()).snapshots().listen((snapshot) { |
| [lib/features/monetisation/services/uag_entitlement_service.dart:208](../lib/features/monetisation/services/uag_entitlement_service.dart#L208) | .snapshots() |
| [lib/features/monetisation/services/uag_entitlement_service.dart:226](../lib/features/monetisation/services/uag_entitlement_service.dart#L226) | .snapshots() |
| [lib/features/monetisation/repositories/uag_referral_validation_repository.dart:51](../lib/features/monetisation/repositories/uag_referral_validation_repository.dart#L51) | return _user(uid).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:31](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L31) | .snapshots() |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:115](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L115) | .snapshots() |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:21](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L21) | return _firestore.collection('users').doc(uid).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:56](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L56) | .snapshots() |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:68](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L68) | .snapshots() |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:83](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L83) | .snapshots(); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:87](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L87) | return _firestore.collection('users').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:26](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L26) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:47](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L47) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:154](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L154) | _firestore.collection('uag_creator_campaign_code_requests').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:157](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L157) | _firestore.collectionGroup('monetisation_usage').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:40](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L40) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:54](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L54) | return _dashboard(uid).snapshots().map( |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:72](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L72) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:27](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L27) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:45](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L45) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:59](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L59) | .snapshots() |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:30](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L30) | return _applications.where('uid', isEqualTo: uid).limit(20).snapshots().map( |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:57](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L57) | return _applications.limit(limit).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:31](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L31) | _firestore.collectionGroup('monetisation_usage').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:34](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L34) | _firestore.collection('users').doc(uid.trim()).snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:44](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L44) | .snapshots() |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:30](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L30) | return _profile(uid).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:51](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L51) | return _terms(uid).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_community_growth_repository.dart:15](../lib/features/monetisation/repositories/uag_community_growth_repository.dart#L15) | return _ref.snapshots().map((snapshot) { |
| [lib/features/monetisation/ads/uag_ad_runtime_settings.dart:156](../lib/features/monetisation/ads/uag_ad_runtime_settings.dart#L156) | Stream<UagAdRuntimeSettings> watch() => _ref.snapshots().map( |
| [lib/features/legal/repositories/uag_age_verification_repository.dart:28](../lib/features/legal/repositories/uag_age_verification_repository.dart#L28) | .snapshots() |
| [lib/features/feature_access_gate.dart:138](../lib/features/feature_access_gate.dart#L138) | .snapshots() |
| [lib/features/feature_access_gate.dart:173](../lib/features/feature_access_gate.dart#L173) | .snapshots() |

## One-time queries and cursors

| Source | Expression |
|---|---|
| [functions/uag_trade_referral_incentives.js:35](../functions/uag_trade_referral_incentives.js#L35) | const configSnap = await db.collection('config').doc('uag_trade_referral_incentives').get(); |
| [functions/uag_trade_referral_incentives.js:46](../functions/uag_trade_referral_incentives.js#L46) | const events = await db.collection('monetisation_events').where('referralSource', '==', 'uag_trade_invite').limit(1001).get(); |
| [functions/uag_trade_referral_incentives.js:58](../functions/uag_trade_referral_incentives.js#L58) | cohorts.get(uid).push({ ...data, timestamp: at }); |
| [functions/uag_trade_referral_incentives.js:62](../functions/uag_trade_referral_incentives.js#L62) | db.collection('users').doc(uid).get(), |
| [functions/uag_trade_referral_incentives.js:63](../functions/uag_trade_referral_incentives.js#L63) | db.collection('uag_trade_referral_incentive_claims').doc(uid).get(), |
| [functions/uag_trade_referral_incentives.js:73](../functions/uag_trade_referral_incentives.js#L73) | const referred = await db.collection('users').doc(row.uid).get(); |
| [functions/uag_trade_referral_incentives.js:90](../functions/uag_trade_referral_incentives.js#L90) | const [currentClaim, currentUser] = await Promise.all([tx.get(claimRef), tx.get(userRef)]); |
| [functions/uag_trade_invite_gateway.js:98](../functions/uag_trade_invite_gateway.js#L98) | const codeSnap = await db.collection('uag_community_referral_codes').doc(code).get(); |
| [functions/uag_trade_invite_gateway.js:112](../functions/uag_trade_invite_gateway.js#L112) | const [attribution, owner] = await Promise.all([tx.get(attributionRef), tx.get(ownerRef)]); |
| [functions/uag_trade_invite_gateway.js:125](../functions/uag_trade_invite_gateway.js#L125) | db.collection('users').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:126](../functions/uag_trade_invite_gateway.js#L126) | db.collection('arc_trader_profiles').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:140](../functions/uag_trade_invite_gateway.js#L140) | db.collection('uag_community_referral_codes').doc(desiredProgramme).get(), |
| [functions/uag_trade_invite_gateway.js:141](../functions/uag_trade_invite_gateway.js#L141) | db.collection('uag_referral_terms_acceptances').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:153](../functions/uag_trade_invite_gateway.js#L153) | const existing = await tx.get(limitRef); |
| [functions/uag_trade_invite_gateway.js:172](../functions/uag_trade_invite_gateway.js#L172) | const invite = await inviteRef.get(); |
| [functions/uag_trade_invite_gateway.js:202](../functions/uag_trade_invite_gateway.js#L202) | tx.get(attributionRef), tx.get(ownerRef), tx.get(inviteRef), |
| [functions/uag_trade_invite_gateway.js:203](../functions/uag_trade_invite_gateway.js#L203) | tx.get(db.collection('uag_community_referral_codes').doc(data.code)), |
| [functions/uag_rewarded_ads.js:91](../functions/uag_rewarded_ads.js#L91) | const pem = keys.get(match[3]); |
| [functions/uag_rewarded_ads.js:134](../functions/uag_rewarded_ads.js#L134) | tx.get(db.collection('users').doc(uid)), tx.get(db.collection('app_config').doc('ads')), |
| [functions/uag_rewarded_ads.js:135](../functions/uag_rewarded_ads.js#L135) | tx.get(walletRef(uid, test)), |
| [functions/uag_rewarded_ads.js:155](../functions/uag_rewarded_ads.js#L155) | const ref = sessionRef(body.sessionId), snap = await tx.get(ref), data = snap.data(); |
| [functions/uag_rewarded_ads.js:158](../functions/uag_rewarded_ads.js#L158) | const wr = walletRef(uid, data.inventory === 'test'), ws = await tx.get(wr); |
| [functions/uag_rewarded_ads.js:170](../functions/uag_rewarded_ads.js#L170) | tx.get(db.collection('users').doc(uid)), tx.get(wr), tx.get(br), tx.get(receipt), |
| [functions/uag_rewarded_ads.js:194](../functions/uag_rewarded_ads.js#L194) | const [previous, session] = await Promise.all([tx.get(receipt), tx.get(sessionRef(event.custom_data))]); |
| [functions/uag_rewarded_ads.js:205](../functions/uag_rewarded_ads.js#L205) | const [ws, user] = await Promise.all([tx.get(wr), tx.get(db.collection('users').doc(data.uid))]); |
| [functions/uag_referral_action_rewards.js:55](../functions/uag_referral_action_rewards.js#L55) | tx.get(ref), |
| [functions/uag_referral_action_rewards.js:56](../functions/uag_referral_action_rewards.js#L56) | receiptRef ? tx.get(receiptRef) : Promise.resolve(null), |
| [functions/uag_referral_action_rewards.js:125](../functions/uag_referral_action_rewards.js#L125) | tx.get(stateRef), |
| [functions/uag_referral_action_rewards.js:126](../functions/uag_referral_action_rewards.js#L126) | tx.get(bonusRef), |
| [functions/uag_referral_action_rewards.js:127](../functions/uag_referral_action_rewards.js#L127) | tx.get(receiptRef), |
| [functions/uag_operation_action_rewards.js:73](../functions/uag_operation_action_rewards.js#L73) | tx.get(progressRef), |
| [functions/uag_operation_action_rewards.js:74](../functions/uag_operation_action_rewards.js#L74) | tx.get(bonusRef), |
| [functions/uag_operation_action_rewards.js:75](../functions/uag_operation_action_rewards.js#L75) | tx.get(receiptRef), |
| [functions/uag_operation_action_rewards.js:168](../functions/uag_operation_action_rewards.js#L168) | const progressSnaps = await Promise.all(progressRefs.map(item => tx.get(item.ref))); |
| [functions/uag_operation_action_rewards.js:170](../functions/uag_operation_action_rewards.js#L170) | tx.get(bonusRef), |
| [functions/uag_operation_action_rewards.js:171](../functions/uag_operation_action_rewards.js#L171) | tx.get(receiptRef), |
| [web/uag_update_manager.js:172](../web/uag_update_manager.js#L172) | const contentType = response.headers.get('content-type') &#124;&#124; ''; |
| [functions/raider_contract_verification.js:76](../functions/raider_contract_verification.js#L76) | const initial = contract(await ref.get()); |
| [functions/raider_contract_verification.js:82](../functions/raider_contract_verification.js#L82) | const c = contract(await tx.get(ref)); |
| [functions/raider_contract_verification.js:94](../functions/raider_contract_verification.js#L94) | if ((await tx.get(audit)).exists) fail('already-exists', 'Submission ID cannot be reused.'); |
| [functions/raider_contract_verification.js:113](../functions/raider_contract_verification.js#L113) | const initial = contract(await ref.get()); |
| [functions/raider_contract_verification.js:126](../functions/raider_contract_verification.js#L126) | const c = contract(await tx.get(ref)); |
| [functions/raider_contract_verification.js:131](../functions/raider_contract_verification.js#L131) | const result = await tx.get(resultRef); |
| [functions/raider_contract_verification.js:142](../functions/raider_contract_verification.js#L142) | const hunter = d.decision === 'confirm' ? await tx.get(db.collection('users').doc(c.hunterUid)) : null; |
| [functions/raider_contract_intelligence.js:73](../functions/raider_contract_intelligence.js#L73) | const read = async (collection, id) => (await ref(collection, id).get()).data(); |
| [functions/raider_contract_intelligence.js:96](../functions/raider_contract_intelligence.js#L96) | const get = r => tx ? tx.get(r) : r.get(); |
| [functions/raider_contract_intelligence.js:128](../functions/raider_contract_intelligence.js#L128) | const [session, prior] = await Promise.all([tx.get(sessionRef), tx.get(reportRef)]); |
| [functions/raider_contract_intelligence.js:159](../functions/raider_contract_intelligence.js#L159) | const reportRef = ref('arc_raider_reports', reportId), current = (await tx.get(reportRef)).data(); |
| [functions/raider_contract_intelligence.js:161](../functions/raider_contract_intelligence.js#L161) | const c = contractRef ? (await tx.get(contractRef)).data() : null; |
| [functions/raider_contract_intelligence.js:189](../functions/raider_contract_intelligence.js#L189) | const [rs, cs] = await Promise.all([tx.get(reportRef), tx.get(contractRef)]); |
| [functions/raider_contract_intelligence.js:192](../functions/raider_contract_intelligence.js#L192) | const claim = claimRef ? (await tx.get(claimRef)).data() : null; |
| [functions/raider_contract_intelligence.js:230](../functions/raider_contract_intelligence.js#L230) | const reports = await db.collection('arc_raider_reports').where('targetUid', '==', targetUid).get(); |
| [functions/raider_contract_intelligence.js:237](../functions/raider_contract_intelligence.js#L237) | const profile = (await ref('users', uid).collection('trading_activity').doc('profile').get()).data(); |
| [functions/raider_contract_intelligence.js:238](../functions/raider_contract_intelligence.js#L238) | const contracts = await db.collection('arc_raider_contracts').where('status', '==', 'available').get(); |
| [functions/raider_contract_intelligence.js:255](../functions/raider_contract_intelligence.js#L255) | const contractRef = ref('arc_raider_contracts', contractId), c = (await tx.get(contractRef)).data(); |
| [functions/raider_contract_intelligence.js:264](../functions/raider_contract_intelligence.js#L264) | const contracts = await db.collection('arc_raider_contracts').where('targetUid', '==', uid).get(); |
| [functions/raider_contract_intelligence.js:272](../functions/raider_contract_intelligence.js#L272) | const contractRef = ref('arc_raider_contracts', contractId), c = (await tx.get(contractRef)).data(); |
| [functions/raider_contract_intelligence.js:289](../functions/raider_contract_intelligence.js#L289) | const [cs, qs, result] = await Promise.all([tx.get(contractRef), tx.get(challengeRef), tx.get(ref('raider_verified_results', contractId))]); |
| [functions/raider_contract_intelligence.js:312](../functions/raider_contract_intelligence.js#L312) | const history = await ref('arc_raider_contracts', contractId).collection('incident_audit').get(); |
| [functions/raider_contract_intelligence.js:327](../functions/raider_contract_intelligence.js#L327) | const snapshot = await db.collection('arc_raider_contracts').where('expiresAt', '<=', now()).get(); |
| [functions/raider_contract_intelligence.js:329](../functions/raider_contract_intelligence.js#L329) | const c = (await tx.get(doc.ref)).data(); |
| [functions/raider_contract_intelligence.js:341](../functions/raider_contract_intelligence.js#L341) | const c = (await tx.get(contractRef)).data(); |
| [lib/screens/build/feedback_screen.dart:77](../lib/screens/build/feedback_screen.dart#L77) | .get(); |
| [lib/screens/build/feedback_screen.dart:298](../lib/screens/build/feedback_screen.dart#L298) | .orderBy('createdAt', descending: true); |
| [lib/screens/build/feedback_screen.dart:380](../lib/screens/build/feedback_screen.dart#L380) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/build/feedback_screen.dart:499](../lib/screens/build/feedback_screen.dart#L499) | .get(); |
| [lib/screens/build/feedback_screen.dart:648](../lib/screens/build/feedback_screen.dart#L648) | .orderBy('createdAt') |
| [lib/screens/build/app_entry_gate.dart:150](../lib/screens/build/app_entry_gate.dart#L150) | .get(); |
| [lib/screens/build/admin_console_screen.dart:61](../lib/screens/build/admin_console_screen.dart#L61) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/build/admin_console_screen.dart:197](../lib/screens/build/admin_console_screen.dart#L197) | .orderBy('updatedAt', descending: true) |
| [lib/screens/build/admin_console_screen.dart:198](../lib/screens/build/admin_console_screen.dart#L198) | .limit(12); |
| [lib/screens/build/admin_console_screen.dart:1353](../lib/screens/build/admin_console_screen.dart#L1353) | final userData = (await userRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_console_screen.dart:1355](../lib/screens/build/admin_console_screen.dart#L1355) | (await profileRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_console_screen.dart:1357](../lib/screens/build/admin_console_screen.dart#L1357) | (await seasonRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_console_screen.dart:1358](../lib/screens/build/admin_console_screen.dart#L1358) | final trackerDocs = (await trackerRef.get()).docs; |
| [lib/screens/build/admin_console_screen.dart:1360](../lib/screens/build/admin_console_screen.dart#L1360) | (await operationSummaryRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_console_screen.dart:1361](../lib/screens/build/admin_console_screen.dart#L1361) | final operationDocs = (await operationsRef.get()).docs; |
| [lib/screens/build/admin_console_screen.dart:1362](../lib/screens/build/admin_console_screen.dart#L1362) | final rewardDocs = (await rewardRef.get()).docs; |
| [lib/screens/build/admin_console_screen.dart:1364](../lib/screens/build/admin_console_screen.dart#L1364) | (await equippedRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_console_screen.dart:1366](../lib/screens/build/admin_console_screen.dart#L1366) | (await telemetryRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/build/admin_business_metrics_panel.dart:18](../lib/screens/build/admin_business_metrics_panel.dart#L18) | .orderBy('createdAt', descending: true) |
| [lib/screens/build/admin_business_metrics_panel.dart:19](../lib/screens/build/admin_business_metrics_panel.dart#L19) | .limit(500) |
| [lib/screens/admin_console_screen.dart:49](../lib/screens/admin_console_screen.dart#L49) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/admin_console_screen.dart:210](../lib/screens/admin_console_screen.dart#L210) | .orderBy('updatedAt', descending: true) |
| [lib/screens/admin_console_screen.dart:211](../lib/screens/admin_console_screen.dart#L211) | .limit(12); |
| [lib/screens/admin_console_screen.dart:1206](../lib/screens/admin_console_screen.dart#L1206) | final userData = (await userRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/admin_console_screen.dart:1208](../lib/screens/admin_console_screen.dart#L1208) | (await profileRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/admin_console_screen.dart:1210](../lib/screens/admin_console_screen.dart#L1210) | (await seasonRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/admin_console_screen.dart:1211](../lib/screens/admin_console_screen.dart#L1211) | final trackerDocs = (await trackerRef.get()).docs; |
| [lib/screens/admin_console_screen.dart:1213](../lib/screens/admin_console_screen.dart#L1213) | (await operationSummaryRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/admin_console_screen.dart:1214](../lib/screens/admin_console_screen.dart#L1214) | final operationDocs = (await operationsRef.get()).docs; |
| [lib/screens/admin_console_screen.dart:1215](../lib/screens/admin_console_screen.dart#L1215) | final rewardDocs = (await rewardRef.get()).docs; |
| [lib/screens/admin_console_screen.dart:1217](../lib/screens/admin_console_screen.dart#L1217) | (await equippedRef.get()).data() ?? const <String, dynamic>{}; |
| [lib/screens/admin_console_screen.dart:1219](../lib/screens/admin_console_screen.dart#L1219) | (await telemetryRef.get()).data() ?? const <String, dynamic>{}; |
| [functions/account_deletion.js:148](../functions/account_deletion.js#L148) | const snapshot = await collection.limit(QUERY_BATCH_SIZE).get(); |
| [functions/account_deletion.js:163](../functions/account_deletion.js#L163) | .limit(QUERY_BATCH_SIZE) |
| [functions/account_deletion.js:164](../functions/account_deletion.js#L164) | .get(); |
| [functions/account_deletion.js:180](../functions/account_deletion.js#L180) | .limit(QUERY_BATCH_SIZE) |
| [functions/account_deletion.js:181](../functions/account_deletion.js#L181) | .get(); |
| [functions/account_deletion.js:200](../functions/account_deletion.js#L200) | .limit(QUERY_BATCH_SIZE) |
| [functions/account_deletion.js:201](../functions/account_deletion.js#L201) | .get(); |
| [functions/account_deletion.js:221](../functions/account_deletion.js#L221) | .limit(QUERY_BATCH_SIZE) |
| [functions/account_deletion.js:222](../functions/account_deletion.js#L222) | .get(); |
| [functions/account_deletion.js:263](../functions/account_deletion.js#L263) | const existingTombstone = await tombstoneRef.get(); |
| [functions/account_deletion.js:557](../functions/account_deletion.js#L557) | .get(); |
| [functions/financial_protection.js:14](../functions/financial_protection.js#L14) | let entry = windows.get(key); |
| [functions/financial_protection.js:37](../functions/financial_protection.js#L37) | const snapshot = await db.doc(CONTROL_PATH).get(); |
| [functions/financial_protection.js:57](../functions/financial_protection.js#L57) | const data = (await tx.get(ref)).data() &#124;&#124; {}; |
| [functions/financial_protection.js:89](../functions/financial_protection.js#L89) | tx.get(db.collection('users').doc(uid)), tx.get(control), tx.get(audit), |
| [lib/reg/onboarding_basic_profile_screen.dart:172](../lib/reg/onboarding_basic_profile_screen.dart#L172) | .get() |
| [lib/build/app_drawer.dart:106](../lib/build/app_drawer.dart#L106) | .get(); |
| [lib/build/app_bar.dart:63](../lib/build/app_bar.dart#L63) | .get(), |
| [web/public-assets/research-planner.js:28](../web/public-assets/research-planner.js#L28) | for(const [resource,quantity] of Object.entries(items)) totals.set(resource,(totals.get(resource)&#124;&#124;0)+quantity); |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:18](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L18) | final snapshot = await _states(uid).get(); |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:93](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L93) | final contractSnapshot = await tx.get(contractRef); |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:136](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L136) | creatorSnapshots[blueprintId] = await tx.get(creatorRef); |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:137](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L137) | claimantSnapshots[blueprintId] = await tx.get(claimantRef); |
| [web/public-assets/entry.js:6](../web/public-assets/entry.js#L6) | var isCheckoutReturn = ['success', 'cancelled'].indexOf(current.searchParams.get('checkout')) !== -1; |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:71](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L71) | .orderBy('updatedAt', descending: true) |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:180](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L180) | final snapshot = await _contracts.doc(contractId).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:373](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L373) | final profile = (await _db.collection('users').doc(uid).get()).data() ?? {}; |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:445](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L445) | final snapshot = await _reports.doc(id).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:495](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L495) | final snapshot = await _contracts.doc(contractId).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:568](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L568) | final snapshot = await _contracts.doc(id).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:599](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L599) | final snapshot = await _contracts.doc(id).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:615](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L615) | (await _db.collection('users').doc(uid).get()).data() ?? |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:666](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L666) | final snapshot = await _contracts.doc(id).get(); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:678](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L678) | final data = (await _db.collection('users').doc(uid).get()).data() ?? {}; |
| [lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart:25](../lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart#L25) | .get(); |
| [lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart:34](../lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart#L34) | .get(); |
| [lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart:379](../lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart#L379) | final data = (await _preferences?.get())?.data(); |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:68](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L68) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:69](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L69) | .limit(100) |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:70](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L70) | .get(); |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:116](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L116) | _tradeSessions.where('traderOneUid', isEqualTo: uid).limit(75).get(), |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:117](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L117) | _tradeSessions.where('traderTwoUid', isEqualTo: uid).limit(75).get(), |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:167](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L167) | _matchInvites.where('senderUid', isEqualTo: uid).limit(75).get(), |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:168](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L168) | _matchInvites.where('recipientUid', isEqualTo: uid).limit(75).get(), |
| [lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart:103](../lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart#L103) | .orderBy('scheduledAt') |
| [lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart:114](../lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart#L114) | .orderBy('scheduledAt') |
| [lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart:106](../lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart#L106) | .limit(limitPerCollection) |
| [lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart:107](../lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart#L107) | .get(); |
| [lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart:48](../lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart#L48) | .limit(30) |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:390](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L390) | .limit(30) |
| [lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart:55](../lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart#L55) | final saved = await collection.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:124](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L124) | final inventorySnapshot = await _rewardInventoryCollection(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:125](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L125) | final legacyEquippedSnapshot = await _equippedCosmeticsDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:400](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L400) | .limit(1) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:401](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L401) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:413](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L413) | .limit(maxOffers) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:414](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L414) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:425](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L425) | .limit(1) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:426](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L426) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:527](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L527) | final userSnap = await _userDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:573](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L573) | final existing = await profileDoc.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:656](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L656) | final existing = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:770](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L770) | final existing = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:828](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L828) | final snapshot = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:844](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L844) | final snapshot = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:937](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L937) | final snapshot = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:964](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L964) | final queueSnapshot = await transaction.get(queueRef); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:998](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L998) | final activeSnapshot = await transaction.get( |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1018](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1018) | final stateSnapshot = await transaction.get( |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1037](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1037) | final sourceSnapshot = await transaction.get( |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1123](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1123) | final snap = await _tradingProfileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1192](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1192) | final snapshot = await _blueprintStatesCollection(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1224](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1224) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1255](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1255) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1280](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1280) | .orderBy('updatedAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1312](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1312) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1361](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1361) | .limit(1) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1362](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1362) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1564](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1564) | ).doc(normalizedQueueBlueprintId).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1604](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1604) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1624](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1624) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1671](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1671) | final snap = await _listingsCollection.doc(listingId).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1822](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1822) | final listingSnap = await _listingsCollection.doc(offer.listingId).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1861](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1861) | final snap = await _tradingProfileDoc(traderUid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:1932](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L1932) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2012](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2012) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2076](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2076) | .orderBy('createdAt', descending: true); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2080](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2080) | .orderBy('createdAt', descending: true); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2146](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2146) | .orderBy('createdAt', descending: true); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2150](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2150) | .orderBy('createdAt', descending: true); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:2301](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L2301) | final snap = await _tradingProfileDoc(traderUid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart:37](../lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart#L37) | final snapshot = await _doc.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart:34](../lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart#L34) | final snapshot = await _entries.doc(id).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart:59](../lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart#L59) | final existing = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:71](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L71) | final snapshot = await _profileRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:112](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L112) | final current = await profileRef.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:119](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L119) | final userSnapshot = await _userRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:164](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L164) | final snapshot = await collection.limit(1).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart:17](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart#L17) | if (!(await ref.get()).exists) { |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart:26](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart#L26) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart:56](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart#L56) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:28](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L28) | final profileSnapshot = await query.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L29) | final awaySnapshot = await _firestore.collection('arc_trader_away').get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:33](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L33) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:171](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L171) | final existingProfile = await profileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:177](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L177) | final existingReservation = await _uagIdDoc(existingProfileId).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:199](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L199) | final counterSnap = await transaction.get(_uagCounterDoc); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:222](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L222) | final uagIdSnap = await transaction.get(uagIdRef); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:263](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L263) | final profileSnapshot = await profileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:268](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L268) | final existingCodeDoc = await _referralCodeDoc(existingCode).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:290](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L290) | final existing = await transaction.get(codeDoc); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:628](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L628) | final userSnap = await _userDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:631](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L631) | final profileSnapshot = await profileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:675](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L675) | final publicProfileSnapshot = await profileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:685](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L685) | final availabilitySnapshot = await availabilityDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:690](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L690) | final awaySnapshot = await awayDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:703](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L703) | final userSnap = await _userDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:704](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L704) | final profileSnap = await profileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:720](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L720) | final userSnapshot = await _userDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:811](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L811) | final snapshot = await availabilityDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:965](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L965) | final userSnapshot = await _userDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:967](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L967) | ? await profileDoc(uid).get() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:971](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L971) | ? await availabilityDoc(uid).get() |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:1044](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L1044) | final snapshot = await awayDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:76](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L76) | final snapshot = await _seasonRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:85](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L85) | final snapshot = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:96](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L96) | final blueprintSnapshot = await _blueprintStatesRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:97](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L97) | final scrappySnapshot = await _scrappyStatesRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:98](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L98) | final questProgressSnapshot = await _questProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:99](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L99) | final scrappyProgressSnapshot = await _scrappyProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:100](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L100) | final benchProgressSnapshot = await _benchProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:101](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L101) | final operationSnapshot = await _operationProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:102](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L102) | final rewardSnapshot = await _rewardInventoryRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:193](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L193) | final blueprintSnapshot = await _blueprintStatesRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:194](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L194) | final scrappySnapshot = await _scrappyStatesRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:195](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L195) | final questProgressSnapshot = await _questProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:196](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L196) | final scrappyProgressSnapshot = await _scrappyProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:197](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L197) | final benchProgressSnapshot = await _benchProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:198](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L198) | final operationSnapshot = await _operationProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:199](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L199) | final rewardSnapshot = await _rewardInventoryRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:347](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L347) | final snapshot = await _scrappyStatesRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:111](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L111) | final snapshot = await collection.doc('favourite-loadout').get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:121](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L121) | final data = (await collection.doc('favourite-loadout').get()).data(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart:27](../lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart#L27) | final snapshot = await _routes(uid).doc('active').get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart:59](../lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart#L59) | final userData = (await userRef.get()).data() ?? <String, dynamic>{}; |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart:62](../lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart#L62) | (await profile.profileDoc(uid).get()).data() ?? <String, dynamic>{}; |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart:64](../lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart#L64) | (await profile.availabilityDoc(uid).get()).data() ?? |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart:87](../lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart#L87) | (await transaction.get(ref)).data() ?? <String, dynamic>{}; |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:152](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L152) | final season = await _seasonRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:154](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L154) | final questSnapshot = await _questProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:155](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L155) | final questStateSnapshot = await _questStateRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:157](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L157) | final scrappySnapshot = await _scrappyProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:158](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L158) | final benchSnapshot = await _benchProgressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:293](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L293) | final snapshot = await transaction.get(ref); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:299](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L299) | final season = await transaction.get(_seasonRef(uid)); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:341](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L341) | final snapshot = await transaction.get(ref); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:350](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L350) | final season = await transaction.get(_seasonRef(uid)); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:58](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L58) | final snapshot = await _activeDatasetVersionRef.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:162](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L162) | final progressSnapshot = await _progressRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:163](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L163) | final inventorySnapshot = await _inventoryRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:164](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L164) | final equippedSnapshot = await _equippedRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:222](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L222) | final snapshot = await transaction.get(ref); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:263](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L263) | final progressSnapshot = await transaction.get(progressRef); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:356](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L356) | final inventorySnapshot = await _inventoryRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:361](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L361) | final profileSnapshot = await _profileRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:362](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L362) | final equippedSnapshot = await _equippedRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:429](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L429) | final userSnapshot = await _userRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:430](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L430) | final profileSnapshot = await _profileRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:431](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L431) | final telemetrySnapshot = await _telemetrySummaryRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:467](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L467) | final snapshot = await transaction.get( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:566](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L566) | final snapshot = await _seasonRef(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:612](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L612) | final existingEvent = await eventRef.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:634](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L634) | final currentSnapshot = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:65](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L65) | final publicSnap = await _profiles.doc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:70](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L70) | final userSnap = await _userProfileDoc(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:335](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L335) | final existing = await ref.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:363](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L363) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:377](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L377) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:396](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L396) | final existingInvite = await inviteRef.get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:28](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L28) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:88](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L88) | .limit(1) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:89](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L89) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:164](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L164) | final snapshot = await transaction.get(doc); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:121](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L121) | final snapshot = await _stateCollection(uid).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:234](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L234) | final snapshot = await _firestore.collection(path).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:336](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L336) | .limit(100) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:364](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L364) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:365](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L365) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:435](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L435) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:528](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L528) | .limit(1) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:529](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L529) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:20](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L20) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:21](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L21) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:36](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L36) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:37](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L37) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:38](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L38) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart:25](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart#L25) | final doc = await _collection.doc(blueprintId).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:51](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L51) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:87](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L87) | final snapshot = await tx.get(ref); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:414](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L414) | .orderBy('createdAt', descending: true) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:415](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L415) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:416](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L416) | .get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:433](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L433) | .limit(limit) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:434](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L434) | .get(); |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:70](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L70) | ).doc(target.blueprintId).get(); |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:92](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L92) | final snapshot = await _targetCollection(uid).get(); |
| [lib/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart:231](../lib/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart#L231) | .get( |
| [lib/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart:24](../lib/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart#L24) | final snapshot = await _userDoc.get(); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:137](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L137) | final main = await doc.get(); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:141](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L141) | final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get(); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:178](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L178) | final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get(); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:184](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L184) | final current = await txn.get(doc); |
| [lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart:31](../lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart#L31) | final snapshot=await transaction.get(doc); |
| [lib/features/release/models/uag_release_runtime_diagnostics.dart:228](../lib/features/release/models/uag_release_runtime_diagnostics.dart#L228) | final userDoc = await firestore.collection('users').doc(user.uid).get(); |
| [lib/features/release/models/uag_release_runtime_diagnostics.dart:248](../lib/features/release/models/uag_release_runtime_diagnostics.dart#L248) | final featureAccess = await firestore.doc(featureAccessPath).get(); |
| [lib/features/notifications/data/uag_notification_repository.dart:61](../lib/features/notifications/data/uag_notification_repository.dart#L61) | final snapshot = await _preferencesDoc(effectiveUid).get(); |
| [lib/features/notifications/data/uag_notification_repository.dart:82](../lib/features/notifications/data/uag_notification_repository.dart#L82) | .get(); |
| [lib/features/notifications/data/uag_notification_repository.dart:164](../lib/features/notifications/data/uag_notification_repository.dart#L164) | .orderBy('lastSeenAt', descending: true) |
| [lib/features/notifications/data/uag_notification_repository.dart:181](../lib/features/notifications/data/uag_notification_repository.dart#L181) | .limit(500); |
| [lib/features/notifications/data/uag_notification_repository.dart:194](../lib/features/notifications/data/uag_notification_repository.dart#L194) | final snapshot = await query.get(); |
| [lib/features/notifications/data/uag_notification_repository.dart:339](../lib/features/notifications/data/uag_notification_repository.dart#L339) | .get(); |
| [lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart:28](../lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart#L28) | final snap = await ref.get(); |
| [lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart:71](../lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart#L71) | final existing = await ref.get(); |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:87](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L87) | final direct = await _firestore.collection('users').doc(query).get(); |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:95](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L95) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:96](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L96) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:100](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L100) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:101](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L101) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:105](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L105) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:106](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L106) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:110](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L110) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:111](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L111) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:115](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L115) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:116](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L116) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:120](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L120) | .limit(1) |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:121](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L121) | .get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:135](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L135) | _firestore.collection('users').doc(uid).get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:136](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L136) | _firestore.collection('public_profiles').doc(uid).get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:137](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L137) | _firestore.collection('uag_commercial_recognition').doc(uid).get(), |
| [lib/features/monetisation/services/uag_entitlement_service.dart:100](../lib/features/monetisation/services/uag_entitlement_service.dart#L100) | final snapshot = await _firestore.collection('users').doc(currentUid).get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:249](../lib/features/monetisation/services/uag_entitlement_service.dart#L249) | .get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:273](../lib/features/monetisation/services/uag_entitlement_service.dart#L273) | .get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:313](../lib/features/monetisation/services/uag_entitlement_service.dart#L313) | final snapshot = await transaction.get(docRef); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:362](../lib/features/monetisation/services/uag_entitlement_service.dart#L362) | final snapshot = await transaction.get(docRef); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:383](../lib/features/monetisation/services/uag_entitlement_service.dart#L383) | final userSnap = await userRef.get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:396](../lib/features/monetisation/services/uag_entitlement_service.dart#L396) | final codeSnap = await transaction.get(codeRef); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:459](../lib/features/monetisation/services/uag_entitlement_service.dart#L459) | final snap = await userRef.get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:477](../lib/features/monetisation/services/uag_entitlement_service.dart#L477) | final snap = await userRef.get(); |
| [lib/features/monetisation/repositories/uag_referral_validation_repository.dart:84](../lib/features/monetisation/repositories/uag_referral_validation_repository.dart#L84) | final attributionSnap = await transaction.get(attributionRef); |
| [lib/features/monetisation/repositories/uag_referral_validation_repository.dart:101](../lib/features/monetisation/repositories/uag_referral_validation_repository.dart#L101) | final referrerSnap = await transaction.get(referrerRef); |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:30](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L30) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:57](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L57) | final existing = await transaction.get(ref); |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:92](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L92) | final existing = await transaction.get(requestRef); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:32](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L32) | final snapshot = await _firestore.collection('users').doc(uid).get(); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:67](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L67) | .orderBy('sortOrder') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:81](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L81) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:82](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L82) | .limit(limit) |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:102](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L102) | final existing = await transaction.get(codeRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:69](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L69) | .limit(1) |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:70](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L70) | .get(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:115](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L115) | final existing = await ref.get(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:164](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L164) | final snap = await ref.get(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:182](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L182) | final claimSnap = await claimRef.get(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:196](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L196) | .get(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:226](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L226) | final codeSnap = await transaction.get(codeRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:247](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L247) | final dashboardSnap = await transaction.get(dashboardRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:295](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L295) | final claimSnap = await transaction.get(claimRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:309](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L309) | final codeSnap = await transaction.get(codeRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart:35](../lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart#L35) | final claimSnap = await transaction.get(claimRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart:81](../lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart#L81) | final codeSnap = await transaction.get(codeRef); |
| [lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart:108](../lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart#L108) | final userSnap = await transaction.get(userRef); |
| [lib/features/monetisation/repositories/uag_creator_referral_repository.dart:32](../lib/features/monetisation/repositories/uag_creator_referral_repository.dart#L32) | final existing = await transaction.get(ref); |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:38](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L38) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:39](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L39) | .limit(1) |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:70](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L70) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:71](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L71) | .limit(limit) |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:145](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L145) | final existing = await transaction.get(doc); |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:25](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L25) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:26](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L26) | .limit(1) |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:86](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L86) | final existing = await ref.get(); |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:30](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L30) | return _applications.where('uid', isEqualTo: uid).limit(20).snapshots().map( |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:57](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L57) | return _applications.limit(limit).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:119](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L119) | .limit(20) |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:120](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L120) | .get(); |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:203](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L203) | final applicationSnapshot = await transaction.get(applicationRef); |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:208](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L208) | final codeSnapshot = await transaction.get(codeRef); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:40](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L40) | final claimSnap = await transaction.get(claimRef); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:95](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L95) | final userSnap = await transaction.get(userRef); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:42](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L42) | .orderBy('createdAt', descending: true) |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:43](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L43) | .limit(limit) |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:83](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L83) | final existingLedger = await transaction.get(ledgerRef); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:99](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L99) | final attribution = await transaction.get(attributionRef); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:201](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L201) | .limit(limit) |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:202](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L202) | .get(); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:217](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L217) | final fresh = await transaction.get(doc.reference); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:252](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L252) | final original = await transaction.get(originalRef); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:316](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L316) | final snapshot = await transaction.get(ref); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:26](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L26) | _dashboard(creatorUid).get(), |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:27](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L27) | _growth.get(), |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:46](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L46) | final snapshot = await _ledger(creatorUid).get(); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:119](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L119) | final original = await transaction.get(originalRef); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:148](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L148) | .get(); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:158](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L158) | final fresh = await transaction.get(doc.reference); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:190](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L190) | final snapshot = await transaction.get(ref); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:73](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L73) | final snapshot = await _terms(uid).get(); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:89](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L89) | final snapshot = await profile.get(); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:95](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L95) | final registered = await _codeRegistry.doc(existing).get(); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:117](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L117) | final existing = await transaction.get(codeRef); |
| [lib/features/monetisation/ads/uag_ad_runtime_settings.dart:161](../lib/features/monetisation/ads/uag_ad_runtime_settings.dart#L161) | UagAdRuntimeSettings.fromMap((await _ref.get()).data()); |
| [lib/features/legal/repositories/uag_age_verification_repository.dart:26](../lib/features/legal/repositories/uag_age_verification_repository.dart#L26) | .orderBy('createdAt', descending: true) |
| [lib/features/legal/repositories/uag_age_verification_repository.dart:27](../lib/features/legal/repositories/uag_age_verification_repository.dart#L27) | .limit(1) |
| [lib/features/legal/repositories/legal_repository.dart:12](../lib/features/legal/repositories/legal_repository.dart#L12) | final doc = await _firestore.collection('users').doc(uid).get(); |
| [lib/features/feature_access_gate.dart:153](../lib/features/feature_access_gate.dart#L153) | .get(); |
| [lib/features/feature_access_gate.dart:178](../lib/features/feature_access_gate.dart#L178) | .get(); |
| [lib/features/feature_access_gate.dart:199](../lib/features/feature_access_gate.dart#L199) | .get(); |
| [lib/features/feature_access_gate.dart:213](../lib/features/feature_access_gate.dart#L213) | .get(); |
| [lib/features/feature_access_gate.dart:285](../lib/features/feature_access_gate.dart#L285) | .get(); |
| [functions/index.js:291](../functions/index.js#L291) | const snapshot = await db.collection('uag_commercial_recognition').doc(uid).get(); |
| [functions/index.js:438](../functions/index.js#L438) | transaction.get(monthRef), |
| [functions/index.js:439](../functions/index.js#L439) | transaction.get(reservationRef), |
| [functions/index.js:510](../functions/index.js#L510) | transaction.get(campaignRef), |
| [functions/index.js:511](../functions/index.js#L511) | transaction.get(claimRef), |
| [functions/index.js:512](../functions/index.js#L512) | transaction.get(reservationRef), |
| [functions/index.js:619](../functions/index.js#L619) | const reservationSnap = await transaction.get(reservationRef); |
| [functions/index.js:638](../functions/index.js#L638) | const counterSnap = counterRef ? await transaction.get(counterRef) : null; |
| [functions/index.js:691](../functions/index.js#L691) | db.collection('uag_referral_terms_acceptances').doc(ownerUid).get(), |
| [functions/index.js:692](../functions/index.js#L692) | db.collection('users').doc(ownerUid).get(), |
| [functions/index.js:709](../functions/index.js#L709) | db.collection('uag_creator_campaign_code_requests').doc(code).get(), |
| [functions/index.js:710](../functions/index.js#L710) | db.collection('uag_community_referral_codes').doc(code).get(), |
| [functions/index.js:711](../functions/index.js#L711) | db.collection('referral_codes').doc(code).get(), |
| [functions/index.js:712](../functions/index.js#L712) | db.collection('uag_discount_campaigns').doc(code).get(), |
| [functions/index.js:713](../functions/index.js#L713) | db.collection('uag_promotion_claims').doc(${code}_${uid}).get(), |
| [functions/index.js:796](../functions/index.js#L796) | .limit(1) |
| [functions/index.js:797](../functions/index.js#L797) | .get(); |
| [functions/index.js:840](../functions/index.js#L840) | userRef.get(), |
| [functions/index.js:842](../functions/index.js#L842) | creatorAttributionRef.get(), |
| [functions/index.js:843](../functions/index.js#L843) | communityAttributionRef.get(), |
| [functions/index.js:1069](../functions/index.js#L1069) | const callerSnap = await db.collection('users').doc(decoded.uid).get(); |
| [functions/index.js:1087](../functions/index.js#L1087) | .get(); |
| [functions/index.js:1102](../functions/index.js#L1102) | transaction.get(targetRef), |
| [functions/index.js:1103](../functions/index.js#L1103) | transaction.get(recognitionRef), |
| [functions/index.js:1104](../functions/index.js#L1104) | transaction.get(counterRef), |
| [functions/index.js:1223](../functions/index.js#L1223) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:1267](../functions/index.js#L1267) | const giftSnap = await transaction.get(giftRef); |
| [functions/index.js:1300](../functions/index.js#L1300) | transaction.get(userRef), |
| [functions/index.js:1301](../functions/index.js#L1301) | transaction.get(historyRef), |
| [functions/index.js:1475](../functions/index.js#L1475) | transaction.get(checkoutRef), |
| [functions/index.js:1476](../functions/index.js#L1476) | transaction.get(giftRef), |
| [functions/index.js:1477](../functions/index.js#L1477) | transaction.get(monthRef), |
| [functions/index.js:1479](../functions/index.js#L1479) | if (reservationRef) reads.push(transaction.get(reservationRef)); |
| [functions/index.js:1602](../functions/index.js#L1602) | const reads = [transaction.get(campaignRef), transaction.get(claimRef)]; |
| [functions/index.js:1603](../functions/index.js#L1603) | if (reservationRef) reads.push(transaction.get(reservationRef)); |
| [functions/index.js:1686](../functions/index.js#L1686) | const refreshedClaim = await claimRef.get(); |
| [functions/index.js:1769](../functions/index.js#L1769) | const userSnap = await userRef.get(); |
| [functions/index.js:1813](../functions/index.js#L1813) | ? await db.collection('uag_community_referral_paid_subscriptions').doc(subscription.id).get() |
| [functions/index.js:1949](../functions/index.js#L1949) | const snapshot = await transaction.get(userRef); |
| [functions/index.js:2111](../functions/index.js#L2111) | const existing = await transaction.get(eventRef); |
| [functions/index.js:2269](../functions/index.js#L2269) | db.collection('users').doc(referrerUid).get(), |
| [functions/index.js:2272](../functions/index.js#L2272) | .get(), |
| [functions/index.js:2302](../functions/index.js#L2302) | const existing = await transaction.get(stateRef); |
| [functions/index.js:2348](../functions/index.js#L2348) | const referrerSnap = await referrerRef.get(); |
| [functions/index.js:2415](../functions/index.js#L2415) | db.collection('uag_creator_dashboard_aggregates').doc(creatorUid).get(), |
| [functions/index.js:2416](../functions/index.js#L2416) | db.collection('app_config').doc('community_growth').get(), |
| [functions/index.js:2477](../functions/index.js#L2477) | .get(), |
| [functions/index.js:2481](../functions/index.js#L2481) | .get(), |
| [functions/index.js:2642](../functions/index.js#L2642) | .limit(1) |
| [functions/index.js:2643](../functions/index.js#L2643) | .get(); |
| [functions/index.js:2674](../functions/index.js#L2674) | const existing = await transaction.get(rewardRef); |
| [functions/index.js:2706](../functions/index.js#L2706) | const attributionSnap = await attributionRef.get(); |
| [functions/index.js:2768](../functions/index.js#L2768) | transaction.get(attributionRef), |
| [functions/index.js:2769](../functions/index.js#L2769) | transaction.get(referrerRef), |
| [functions/index.js:2770](../functions/index.js#L2770) | transaction.get(queueRef), |
| [functions/index.js:2771](../functions/index.js#L2771) | transaction.get(referredRef), |
| [functions/index.js:2861](../functions/index.js#L2861) | const eventSnap = await eventRef.get(); |
| [functions/index.js:2883](../functions/index.js#L2883) | const ledger = await transaction.get(ledgerRef); |
| [functions/index.js:2885](../functions/index.js#L2885) | ? await transaction.get(paidStateRef) : null; |
| [functions/index.js:3017](../functions/index.js#L3017) | transaction.get(lockerRef), |
| [functions/index.js:3018](../functions/index.js#L3018) | transaction.get(rewardRef), |
| [functions/index.js:3019](../functions/index.js#L3019) | transaction.get(userRef), |
| [functions/index.js:3123](../functions/index.js#L3123) | .limit(500) |
| [functions/index.js:3124](../functions/index.js#L3124) | .get(); |
| [functions/index.js:3133](../functions/index.js#L3133) | const fresh = await transaction.get(doc.ref); |
| [functions/index.js:3176](../functions/index.js#L3176) | .limit(500) |
| [functions/index.js:3177](../functions/index.js#L3177) | .get(); |
| [functions/index.js:3208](../functions/index.js#L3208) | .limit(500) |
| [functions/index.js:3209](../functions/index.js#L3209) | .get(); |
| [functions/index.js:3230](../functions/index.js#L3230) | .limit(250) |
| [functions/index.js:3231](../functions/index.js#L3231) | .get(); |
| [functions/index.js:3239](../functions/index.js#L3239) | const freshLocker = await transaction.get(locker.ref); |
| [functions/index.js:3240](../functions/index.js#L3240) | const freshReward = await transaction.get(rewardRef); |
| [functions/index.js:3413](../functions/index.js#L3413) | .get(); |
| [functions/index.js:3430](../functions/index.js#L3430) | .get(); |
| [functions/index.js:3493](../functions/index.js#L3493) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3516](../functions/index.js#L3516) | .limit(1000); |
| [functions/index.js:3524](../functions/index.js#L3524) | const snap = await query.get(); |
| [functions/index.js:3545](../functions/index.js#L3545) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3548](../functions/index.js#L3548) | if (!userMatchesAudience({ audience, userData: userCache.get(uid) })) { |
| [functions/index.js:3655](../functions/index.js#L3655) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3662](../functions/index.js#L3662) | db.collection('uag_user_blocks').doc(messagingBlockId(leftUid, rightUid)).get(), |
| [functions/index.js:3663](../functions/index.js#L3663) | db.collection('uag_user_blocks').doc(messagingBlockId(rightUid, leftUid)).get(), |
| [functions/index.js:4290](../functions/index.js#L4290) | .get(); |
| [functions/index.js:4297](../functions/index.js#L4297) | const snap = await transaction.get(ref); |
| [functions/index.js:4332](../functions/index.js#L4332) | const existing = await notificationRef.get(); |
| [functions/index.js:4400](../functions/index.js#L4400) | .orderBy('dueAt', 'asc') |
| [functions/index.js:4401](../functions/index.js#L4401) | .limit(100) |
| [functions/index.js:4402](../functions/index.js#L4402) | .get(); |
| [functions/index.js:4472](../functions/index.js#L4472) | const current = await transaction.get(ref); |
| [functions/index.js:4742](../functions/index.js#L4742) | const current = await transaction.get(snap.ref); |
| [functions/index.js:4923](../functions/index.js#L4923) | let query = db.collection('trading_watch_preferences').orderBy(admin.firestore.FieldPath.documentId()).limit(200); |
| [functions/index.js:4924](../functions/index.js#L4924) | if (cursor) query = query.startAfter(cursor); |
| [functions/index.js:4925](../functions/index.js#L4925) | const snapshot = await query.get(); |
| [functions/index.js:4937](../functions/index.js#L4937) | const states = await db.collection('users').doc(uid).collection('arc_blueprints').get(); |

## Collection references

| Source | Expression |
|---|---|
| [functions/uag_trade_referral_incentives.js:35](../functions/uag_trade_referral_incentives.js#L35) | const configSnap = await db.collection('config').doc('uag_trade_referral_incentives').get(); |
| [functions/uag_trade_referral_incentives.js:46](../functions/uag_trade_referral_incentives.js#L46) | const events = await db.collection('monetisation_events').where('referralSource', '==', 'uag_trade_invite').limit(1001).get(); |
| [functions/uag_trade_referral_incentives.js:62](../functions/uag_trade_referral_incentives.js#L62) | db.collection('users').doc(uid).get(), |
| [functions/uag_trade_referral_incentives.js:63](../functions/uag_trade_referral_incentives.js#L63) | db.collection('uag_trade_referral_incentive_claims').doc(uid).get(), |
| [functions/uag_trade_referral_incentives.js:73](../functions/uag_trade_referral_incentives.js#L73) | const referred = await db.collection('users').doc(row.uid).get(); |
| [functions/uag_trade_referral_incentives.js:85](../functions/uag_trade_referral_incentives.js#L85) | const claimRef = db.collection('uag_trade_referral_incentive_claims').doc(uid); |
| [functions/uag_trade_referral_incentives.js:86](../functions/uag_trade_referral_incentives.js#L86) | const userRef = db.collection('users').doc(uid); |
| [functions/uag_trade_invite_gateway.js:98](../functions/uag_trade_invite_gateway.js#L98) | const codeSnap = await db.collection('uag_community_referral_codes').doc(code).get(); |
| [functions/uag_trade_invite_gateway.js:108](../functions/uag_trade_invite_gateway.js#L108) | const attributionRef = db.collection('users').doc(account.uid).collection('monetisation_usage').doc('community_referral_attribution'); |
| [functions/uag_trade_invite_gateway.js:109](../functions/uag_trade_invite_gateway.js#L109) | const ownerRef = db.collection('users').doc(referrerUid); |
| [functions/uag_trade_invite_gateway.js:125](../functions/uag_trade_invite_gateway.js#L125) | db.collection('users').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:126](../functions/uag_trade_invite_gateway.js#L126) | db.collection('arc_trader_profiles').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:140](../functions/uag_trade_invite_gateway.js#L140) | db.collection('uag_community_referral_codes').doc(desiredProgramme).get(), |
| [functions/uag_trade_invite_gateway.js:141](../functions/uag_trade_invite_gateway.js#L141) | db.collection('uag_referral_terms_acceptances').doc(uid).get(), |
| [functions/uag_trade_invite_gateway.js:148](../functions/uag_trade_invite_gateway.js#L148) | const limitRef = db.collection('uag_trade_invite_issue_limits').doc(uid); |
| [functions/uag_trade_invite_gateway.js:149](../functions/uag_trade_invite_gateway.js#L149) | const inviteRef = db.collection('uag_trade_invites').doc(digest); |
| [functions/uag_trade_invite_gateway.js:150](../functions/uag_trade_invite_gateway.js#L150) | const codeRef = db.collection('uag_community_referral_codes').doc(code); |
| [functions/uag_trade_invite_gateway.js:171](../functions/uag_trade_invite_gateway.js#L171) | const inviteRef = db.collection('uag_trade_invites').doc(tokenDigest(raw)); |
| [functions/uag_trade_invite_gateway.js:190](../functions/uag_trade_invite_gateway.js#L190) | const profileRef = db.collection('users').doc(uid); |
| [functions/uag_trade_invite_gateway.js:191](../functions/uag_trade_invite_gateway.js#L191) | const attributionRef = profileRef.collection('monetisation_usage').doc('community_referral_attribution'); |
| [functions/uag_trade_invite_gateway.js:199](../functions/uag_trade_invite_gateway.js#L199) | const ownerRef = db.collection('users').doc(data.ownerUid); |
| [functions/uag_trade_invite_gateway.js:203](../functions/uag_trade_invite_gateway.js#L203) | tx.get(db.collection('uag_community_referral_codes').doc(data.code)), |
| [functions/uag_rewarded_ads.js:107](../functions/uag_rewarded_ads.js#L107) | const sessionRef = id => db.collection('uag_reward_sessions').doc(id); |
| [functions/uag_rewarded_ads.js:108](../functions/uag_rewarded_ads.js#L108) | const walletRef = (uid, test) => db.collection(test ? 'uag_reward_test_wallets' : 'uag_reward_wallets').doc(uid); |
| [functions/uag_rewarded_ads.js:109](../functions/uag_rewarded_ads.js#L109) | const bonusRef = (uid, time) => db.collection('uag_reward_bonuses').doc(uid).collection('months').doc(usageMonthKey(time)); |
| [functions/uag_rewarded_ads.js:134](../functions/uag_rewarded_ads.js#L134) | tx.get(db.collection('users').doc(uid)), tx.get(db.collection('app_config').doc('ads')), |
| [functions/uag_rewarded_ads.js:167](../functions/uag_rewarded_ads.js#L167) | const receipt = db.collection('uag_reward_redemptions').doc(${uid}_${body.requestId}); |
| [functions/uag_rewarded_ads.js:170](../functions/uag_rewarded_ads.js#L170) | tx.get(db.collection('users').doc(uid)), tx.get(wr), tx.get(br), tx.get(receipt), |
| [functions/uag_rewarded_ads.js:192](../functions/uag_rewarded_ads.js#L192) | const receipt = db.collection('uag_reward_transactions').doc(event.transaction_id); |
| [functions/uag_rewarded_ads.js:205](../functions/uag_rewarded_ads.js#L205) | const [ws, user] = await Promise.all([tx.get(wr), tx.get(db.collection('users').doc(data.uid))]); |
| [functions/uag_referral_action_rewards.js:31](../functions/uag_referral_action_rewards.js#L31) | return db.collection('uag_referral_action_rewards') |
| [functions/uag_referral_action_rewards.js:33](../functions/uag_referral_action_rewards.js#L33) | .collection('months') |
| [functions/uag_referral_action_rewards.js:51](../functions/uag_referral_action_rewards.js#L51) | ? db.collection('uag_referral_action_qualification_receipts').doc(receiptId) |
| [functions/uag_referral_action_rewards.js:116](../functions/uag_referral_action_rewards.js#L116) | const bonusRef = db.collection('uag_reward_bonuses') |
| [functions/uag_referral_action_rewards.js:118](../functions/uag_referral_action_rewards.js#L118) | .collection('months') |
| [functions/uag_referral_action_rewards.js:120](../functions/uag_referral_action_rewards.js#L120) | const receiptRef = db.collection('uag_referral_action_redemptions') |
| [functions/uag_operation_action_rewards.js:60](../functions/uag_operation_action_rewards.js#L60) | const progressRef = db.collection('arc_operation_progress') |
| [functions/uag_operation_action_rewards.js:62](../functions/uag_operation_action_rewards.js#L62) | .collection('operations') |
| [functions/uag_operation_action_rewards.js:64](../functions/uag_operation_action_rewards.js#L64) | const bonusRef = db.collection('uag_reward_bonuses') |
| [functions/uag_operation_action_rewards.js:66](../functions/uag_operation_action_rewards.js#L66) | .collection('months') |
| [functions/uag_operation_action_rewards.js:68](../functions/uag_operation_action_rewards.js#L68) | const receiptRef = db.collection('uag_operation_action_redemptions') |
| [functions/uag_operation_action_rewards.js:155](../functions/uag_operation_action_rewards.js#L155) | ref: db.collection('arc_operation_progress') |
| [functions/uag_operation_action_rewards.js:157](../functions/uag_operation_action_rewards.js#L157) | .collection('operations') |
| [functions/uag_operation_action_rewards.js:160](../functions/uag_operation_action_rewards.js#L160) | const bonusRef = db.collection('uag_reward_bonuses') |
| [functions/uag_operation_action_rewards.js:162](../functions/uag_operation_action_rewards.js#L162) | .collection('months') |
| [functions/uag_operation_action_rewards.js:164](../functions/uag_operation_action_rewards.js#L164) | const receiptRef = db.collection('uag_operation_completion_redemptions') |
| [functions/raider_contract_verification.js:75](../functions/raider_contract_verification.js#L75) | const ref = db.collection('arc_raider_contracts').doc(d.contractId); |
| [functions/raider_contract_verification.js:93](../functions/raider_contract_verification.js#L93) | const audit = ref.collection('verification_audit').doc(submission_${d.submissionId}); |
| [functions/raider_contract_verification.js:112](../functions/raider_contract_verification.js#L112) | const ref = db.collection('arc_raider_contracts').doc(d.contractId); |
| [functions/raider_contract_verification.js:130](../functions/raider_contract_verification.js#L130) | const resultRef = db.collection('raider_verified_results').doc(d.contractId); |
| [functions/raider_contract_verification.js:142](../functions/raider_contract_verification.js#L142) | const hunter = d.decision === 'confirm' ? await tx.get(db.collection('users').doc(c.hunterUid)) : null; |
| [functions/raider_contract_verification.js:150](../functions/raider_contract_verification.js#L150) | tx.create(ref.collection('verification_audit').doc(review_${d.submissionId}), { |
| [functions/raider_contract_intelligence.js:72](../functions/raider_contract_intelligence.js#L72) | const ref = (collection, id) => db.collection(collection).doc(id); |
| [functions/raider_contract_intelligence.js:120](../functions/raider_contract_intelligence.js#L120) | tx.set(contractRef.collection('incident_audit').doc(action), { action, actorUid: uid, ...details, createdAt: timestamp() }); |
| [functions/raider_contract_intelligence.js:230](../functions/raider_contract_intelligence.js#L230) | const reports = await db.collection('arc_raider_reports').where('targetUid', '==', targetUid).get(); |
| [functions/raider_contract_intelligence.js:237](../functions/raider_contract_intelligence.js#L237) | const profile = (await ref('users', uid).collection('trading_activity').doc('profile').get()).data(); |
| [functions/raider_contract_intelligence.js:238](../functions/raider_contract_intelligence.js#L238) | const contracts = await db.collection('arc_raider_contracts').where('status', '==', 'available').get(); |
| [functions/raider_contract_intelligence.js:264](../functions/raider_contract_intelligence.js#L264) | const contracts = await db.collection('arc_raider_contracts').where('targetUid', '==', uid).get(); |
| [functions/raider_contract_intelligence.js:312](../functions/raider_contract_intelligence.js#L312) | const history = await ref('arc_raider_contracts', contractId).collection('incident_audit').get(); |
| [functions/raider_contract_intelligence.js:323](../functions/raider_contract_intelligence.js#L323) | await contractRef.collection('incident_audit').doc(key('lifecycle', event.id)).set({ |
| [functions/raider_contract_intelligence.js:327](../functions/raider_contract_intelligence.js#L327) | const snapshot = await db.collection('arc_raider_contracts').where('expiresAt', '<=', now()).get(); |
| [lib/screens/build/feedback_screen.dart:73](../lib/screens/build/feedback_screen.dart#L73) | .collection('trading_notifications') |
| [lib/screens/build/feedback_screen.dart:101](../lib/screens/build/feedback_screen.dart#L101) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:116](../lib/screens/build/feedback_screen.dart#L116) | await feedbackRef.collection('replies').add({ |
| [lib/screens/build/feedback_screen.dart:173](../lib/screens/build/feedback_screen.dart#L173) | .collection('trading_notifications') |
| [lib/screens/build/feedback_screen.dart:297](../lib/screens/build/feedback_screen.dart#L297) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:380](../lib/screens/build/feedback_screen.dart#L380) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/build/feedback_screen.dart:485](../lib/screens/build/feedback_screen.dart#L485) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:487](../lib/screens/build/feedback_screen.dart#L487) | .collection('replies') |
| [lib/screens/build/feedback_screen.dart:497](../lib/screens/build/feedback_screen.dart#L497) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:505](../lib/screens/build/feedback_screen.dart#L505) | .collection('trading_notifications') |
| [lib/screens/build/feedback_screen.dart:526](../lib/screens/build/feedback_screen.dart#L526) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:549](../lib/screens/build/feedback_screen.dart#L549) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:645](../lib/screens/build/feedback_screen.dart#L645) | .collection('beta_feedback') |
| [lib/screens/build/feedback_screen.dart:647](../lib/screens/build/feedback_screen.dart#L647) | .collection('replies') |
| [lib/screens/build/app_entry_gate.dart:126](../lib/screens/build/app_entry_gate.dart#L126) | await FirebaseFirestore.instance.collection('users').doc(uid).set({ |
| [lib/screens/build/app_entry_gate.dart:148](../lib/screens/build/app_entry_gate.dart#L148) | .collection('users') |
| [lib/screens/build/admin_console_screen.dart:61](../lib/screens/build/admin_console_screen.dart#L61) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/build/admin_console_screen.dart:192](../lib/screens/build/admin_console_screen.dart#L192) | .collection('config') |
| [lib/screens/build/admin_console_screen.dart:196](../lib/screens/build/admin_console_screen.dart#L196) | .collection('beta_feedback') |
| [lib/screens/build/admin_console_screen.dart:269](../lib/screens/build/admin_console_screen.dart#L269) | .collection( |
| [lib/screens/build/admin_console_screen.dart:674](../lib/screens/build/admin_console_screen.dart#L674) | .collection('config') |
| [lib/screens/build/admin_console_screen.dart:1336](../lib/screens/build/admin_console_screen.dart#L1336) | final userRef = firestore.collection('users').doc(uid); |
| [lib/screens/build/admin_console_screen.dart:1337](../lib/screens/build/admin_console_screen.dart#L1337) | final profileRef = userRef.collection('trading_activity').doc('profile'); |
| [lib/screens/build/admin_console_screen.dart:1338](../lib/screens/build/admin_console_screen.dart#L1338) | final seasonRef = userRef.collection('arc_season_state').doc('current'); |
| [lib/screens/build/admin_console_screen.dart:1339](../lib/screens/build/admin_console_screen.dart#L1339) | final trackerRef = userRef.collection('arc_scrappy_states'); |
| [lib/screens/build/admin_console_screen.dart:1341](../lib/screens/build/admin_console_screen.dart#L1341) | .collection('arc_operation_progress') |
| [lib/screens/build/admin_console_screen.dart:1343](../lib/screens/build/admin_console_screen.dart#L1343) | final operationsRef = operationSummaryRef.collection('operations'); |
| [lib/screens/build/admin_console_screen.dart:1345](../lib/screens/build/admin_console_screen.dart#L1345) | .collection('arc_rewards_inventory') |
| [lib/screens/build/admin_console_screen.dart:1347](../lib/screens/build/admin_console_screen.dart#L1347) | .collection('items'); |
| [lib/screens/build/admin_console_screen.dart:1348](../lib/screens/build/admin_console_screen.dart#L1348) | final equippedRef = firestore.collection('arc_equipped_cosmetics').doc(uid); |
| [lib/screens/build/admin_console_screen.dart:1350](../lib/screens/build/admin_console_screen.dart#L1350) | .collection('arc_operation_telemetry') |
| [lib/screens/build/admin_console_screen.dart:1673](../lib/screens/build/admin_console_screen.dart#L1673) | .collection('config') |
| [lib/screens/build/admin_business_metrics_panel.dart:13](../lib/screens/build/admin_business_metrics_panel.dart#L13) | stream: firestore.collection('users').snapshots(), |
| [lib/screens/build/admin_business_metrics_panel.dart:17](../lib/screens/build/admin_business_metrics_panel.dart#L17) | .collection('monetisation_events') |
| [lib/screens/build/admin_business_metrics_panel.dart:24](../lib/screens/build/admin_business_metrics_panel.dart#L24) | .collection('arc_operation_telemetry') |
| [lib/screens/admin_console_screen.dart:49](../lib/screens/admin_console_screen.dart#L49) | future: FirebaseFirestore.instance.collection('users').doc(uid).get(), |
| [lib/screens/admin_console_screen.dart:205](../lib/screens/admin_console_screen.dart#L205) | .collection('config') |
| [lib/screens/admin_console_screen.dart:209](../lib/screens/admin_console_screen.dart#L209) | .collection('beta_feedback') |
| [lib/screens/admin_console_screen.dart:272](../lib/screens/admin_console_screen.dart#L272) | .collection( |
| [lib/screens/admin_console_screen.dart:601](../lib/screens/admin_console_screen.dart#L601) | .collection('config') |
| [lib/screens/admin_console_screen.dart:1189](../lib/screens/admin_console_screen.dart#L1189) | final userRef = firestore.collection('users').doc(uid); |
| [lib/screens/admin_console_screen.dart:1190](../lib/screens/admin_console_screen.dart#L1190) | final profileRef = userRef.collection('trading_activity').doc('profile'); |
| [lib/screens/admin_console_screen.dart:1191](../lib/screens/admin_console_screen.dart#L1191) | final seasonRef = userRef.collection('arc_season_state').doc('current'); |
| [lib/screens/admin_console_screen.dart:1192](../lib/screens/admin_console_screen.dart#L1192) | final trackerRef = userRef.collection('arc_scrappy_states'); |
| [lib/screens/admin_console_screen.dart:1194](../lib/screens/admin_console_screen.dart#L1194) | .collection('arc_operation_progress') |
| [lib/screens/admin_console_screen.dart:1196](../lib/screens/admin_console_screen.dart#L1196) | final operationsRef = operationSummaryRef.collection('operations'); |
| [lib/screens/admin_console_screen.dart:1198](../lib/screens/admin_console_screen.dart#L1198) | .collection('arc_rewards_inventory') |
| [lib/screens/admin_console_screen.dart:1200](../lib/screens/admin_console_screen.dart#L1200) | .collection('items'); |
| [lib/screens/admin_console_screen.dart:1201](../lib/screens/admin_console_screen.dart#L1201) | final equippedRef = firestore.collection('arc_equipped_cosmetics').doc(uid); |
| [lib/screens/admin_console_screen.dart:1203](../lib/screens/admin_console_screen.dart#L1203) | .collection('arc_operation_telemetry') |
| [lib/screens/admin_console_screen.dart:1526](../lib/screens/admin_console_screen.dart#L1526) | .collection('config') |
| [functions/account_deletion.js:161](../functions/account_deletion.js#L161) | .collection(collectionName) |
| [functions/account_deletion.js:178](../functions/account_deletion.js#L178) | .collection(collectionName) |
| [functions/account_deletion.js:198](../functions/account_deletion.js#L198) | .collection(collectionName) |
| [functions/account_deletion.js:219](../functions/account_deletion.js#L219) | .collectionGroup(groupName) |
| [functions/account_deletion.js:261](../functions/account_deletion.js#L261) | .collection('account_deletion_tombstones') |
| [functions/account_deletion.js:289](../functions/account_deletion.js#L289) | await deleteDocumentTree(db.collection(collectionName).doc(uid)); |
| [functions/account_deletion.js:507](../functions/account_deletion.js#L507) | await deleteDocumentTree(db.collection('users').doc(uid)); |
| [functions/account_deletion.js:555](../functions/account_deletion.js#L555) | .collection('account_deletion_tombstones') |
| [functions/financial_protection.js:55](../functions/financial_protection.js#L55) | const ref = db.collection('financial_operation_limits').doc(digest); |
| [functions/financial_protection.js:86](../functions/financial_protection.js#L86) | const audit = db.collection('financial_protection_audit').doc(data.requestId); |
| [functions/financial_protection.js:89](../functions/financial_protection.js#L89) | tx.get(db.collection('users').doc(uid)), tx.get(control), tx.get(audit), |
| [lib/reg/onboarding_basic_profile_screen.dart:170](../lib/reg/onboarding_basic_profile_screen.dart#L170) | .collection('users') |
| [lib/reg/onboarding_basic_profile_screen.dart:367](../lib/reg/onboarding_basic_profile_screen.dart#L367) | .collection('users') |
| [lib/build/auth/auth_screen.dart:440](../lib/build/auth/auth_screen.dart#L440) | FirebaseFirestore.instance.collection('users').doc(user.uid).set({ |
| [lib/build/app_drawer.dart:104](../lib/build/app_drawer.dart#L104) | .collection('users') |
| [lib/build/app_bar.dart:61](../lib/build/app_bar.dart#L61) | .collection('users') |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:14](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L14) | _db.collection('users').doc(uid).collection('arc_blueprints'); |
| [lib/features/trust/services/arc_raider_blueprint_reward_service.dart:90](../lib/features/trust/services/arc_raider_blueprint_reward_service.dart#L90) | final contractRef = _db.collection('arc_raider_contracts').doc(contractId); |
| [lib/features/trust/repositories/uag_messaging_safety_repository.dart:19](../lib/features/trust/repositories/uag_messaging_safety_repository.dart#L19) | _firestore.collection('uag_user_blocks'); |
| [lib/features/trust/repositories/uag_messaging_safety_repository.dart:22](../lib/features/trust/repositories/uag_messaging_safety_repository.dart#L22) | _firestore.collection('uag_message_outbox'); |
| [lib/features/trust/repositories/uag_messaging_safety_repository.dart:25](../lib/features/trust/repositories/uag_messaging_safety_repository.dart#L25) | _firestore.collection('uag_message_reports'); |
| [lib/features/trust/repositories/uag_messaging_safety_repository.dart:28](../lib/features/trust/repositories/uag_messaging_safety_repository.dart#L28) | _firestore.collection('uag_conversation_reports'); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:38](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L38) | _db.collection('arc_raider_reports'); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:40](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L40) | _db.collection('arc_raider_contracts'); |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:46](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L46) | Query<Map<String, dynamic>> query = _db.collection( |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:126](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L126) | .collection('arc_contract_challenges') |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:373](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L373) | final profile = (await _db.collection('users').doc(uid).get()).data() ?? {}; |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:615](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L615) | (await _db.collection('users').doc(uid).get()).data() ?? |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:678](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L678) | final data = (await _db.collection('users').doc(uid).get()).data() ?? {}; |
| [lib/features/trust/repositories/arc_raider_contracts_repository.dart:696](../lib/features/trust/repositories/arc_raider_contracts_repository.dart#L696) | final ref = _db.collection('trading_notifications').doc(); |
| [lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart:18](../lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart#L18) | .collection('arc_trade_listings') |
| [lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart:24](../lib/features/trading_hub/arc_raiders/widgets/arc_network_liquidity_admin_panel.dart#L24) | .collection('arc_match_rider_profiles') |
| [lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart:23](../lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart#L23) | .collection('config') |
| [lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart:32](../lib/features/trading_hub/arc_raiders/widgets/arc_feature_visibility_diagnostics_panel.dart#L32) | .collection('config') |
| [lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart:362](../lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart#L362) | .collection('arc_trade_offer_preferences').doc(uid); |
| [lib/features/trading_hub/arc_raiders/widgets/arc_beta_first_run.dart:56](../lib/features/trading_hub/arc_raiders/widgets/arc_beta_first_run.dart#L56) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:42](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L42) | _firestore.collection('trading_listings'); |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:44](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L44) | _firestore.collection('trading_sessions'); |
| [lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart:46](../lib/features/trading_hub/arc_raiders/voice/voice_app_context_service.dart#L46) | _firestore.collection('arc_match_rider_invites'); |
| [lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart:19](../lib/features/trading_hub/arc_raiders/session_planner/session_repository.dart#L19) | _firestore.collection(collectionPath); |
| [lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart:104](../lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart#L104) | .collection(collection) |
| [lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart:306](../lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart#L306) | return _firestore.collection(collection).add(payload); |
| [lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart:320](../lib/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart#L320) | return _firestore.collection(collection).add(<String, dynamic>{ |
| [lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart:46](../lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart#L46) | .collection('arc_blueprint_drop_reports') |
| [lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart:3251](../lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart#L3251) | .collection('config') |
| [lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart:387](../lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart#L387) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart:555](../lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart#L555) | await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:140](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L140) | .collection('uag_community_suggestions') |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:176](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L176) | .collection('uag_community_suggestions') |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:178](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L178) | .collection('votes') |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:388](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L388) | .collection('uag_community_suggestions') |
| [lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart:424](../lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart#L424) | stream: doc.reference.collection('votes').snapshots(), |
| [lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart:43](../lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart#L43) | return _db.collection('users').doc(user).collection('uag_research_progress') |
| [lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart:51](../lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart#L51) | final collection = _db.collection('users').doc(user).collection('uag_research_progress'); |
| [lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart:72](../lib/features/trading_hub/arc_raiders/research/uag_research_repository.dart#L72) | await _db.collection('trading_watch_preferences').doc(user).set({ |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:43](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L43) | return _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:47](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L47) | return _userDoc(uid).collection('trading_activity').doc('profile'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:51](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L51) | _firestore.collection('arc_equipped_cosmetics').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:56](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L56) | .collection('arc_rewards_inventory') |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:58](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L58) | .collection('items'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:62](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L62) | ) => _userDoc(uid).collection('arc_blueprints'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:65](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L65) | _firestore.collection('trading_sessions'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:68](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L68) | _firestore.collection('trading_listings'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:71](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L71) | _firestore.collection('trading_offers'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:74](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L74) | _firestore.collection('trading_notifications'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:77](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L77) | _firestore.collection('arc_trade_preparations'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:80](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L80) | _firestore.collection('arc_favourite_riders'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:83](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L83) | _firestore.collection('arc_blueprint_watches'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:86](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L86) | _firestore.collection('arc_trade_offer_preferences'); |
| [lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart:89](../lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart#L89) | _firestore.collection('arc_trade_listing_queue'); |
| [lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart:23](../lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart#L23) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart:25](../lib/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart#L25) | .collection('trading_activity') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart:12](../lib/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart#L12) | _firestore.collection('wall_of_legends'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L29) | return _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:33](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L33) | return _userRef(uid).collection(collectionName).doc(documentId); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:124](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L124) | _userRef(uid).collection('arc_blueprints'), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:127](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L127) | _userRef(uid).collection('trading_activity'), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:130](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L130) | _userRef(uid).collection('arc_scrappy_states'), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:133](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L133) | await _hasAny(_userRef(uid).collection('arc_quest_progress')) &#124;&#124; |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:134](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L134) | await _hasAny(_userRef(uid).collection('arc_bench_progress')), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart:136](../lib/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart#L136) | _userRef(uid).collection('arc_saved_loadouts'), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart:16](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart#L16) | final ref = _db.collection('trading_watch_preferences').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart:30](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_watch_repository.dart#L30) | await _db.collection('trading_watch_preferences').doc(uid).set({ |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart:16](../lib/features/trading_hub/arc_raiders/repositories/arc_trade_listing_repository.dart#L16) | _firestore.collection('arc_trade_listings'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:17](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L17) | .collection('arc_trader_profiles') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:29](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L29) | final awaySnapshot = await _firestore.collection('arc_trader_away').get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart:31](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_search_repository.dart#L31) | .collection('arc_trade_listings') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:35](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L35) | _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:38](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L38) | _userDoc(uid).collection('trading_activity').doc('profile'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:41](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L41) | _firestore.collection('public_profiles').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:44](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L44) | _userDoc(uid).collection('trading_activity').doc('availability'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:47](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L47) | _userDoc(uid).collection('trading_activity').doc('away'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:50](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L50) | _firestore.collection('referral_codes').doc(code); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:53](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L53) | _firestore.collection('uag_ids').doc(uagId); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart:56](../lib/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart#L56) | _firestore.collection('system_counters').doc('arc_trader_ids'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:30](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L30) | _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:33](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L33) | _userRef(uid).collection('arc_season_state').doc('current'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:36](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L36) | _userRef(uid).collection('arc_season_history'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:39](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L39) | _userRef(uid).collection('arc_blueprints'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:42](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L42) | _userRef(uid).collection('arc_scrappy_states'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:45](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L45) | _userRef(uid).collection('arc_quest_progress'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:48](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L48) | _userRef(uid).collection('arc_scrappy_progress'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:51](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L51) | _userRef(uid).collection('arc_bench_progress'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:54](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L54) | _firestore.collection('arc_operation_progress').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:57](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L57) | _operationSummaryRef(uid).collection('operations'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:61](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L61) | .collection('arc_rewards_inventory') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart:63](../lib/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart#L63) | .collection('items'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart:27](../lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart#L27) | return _firestore.collection('users').doc(uid).collection(_collection); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart:74](../lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart#L74) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart:76](../lib/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart#L76) | .collection(_collection); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:25](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L25) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:27](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L27) | .collection('arc_saved_loadouts'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:80](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L80) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:82](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L82) | .collection('arc_saved_loadouts') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:95](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L95) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart:97](../lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart#L97) | .collection('arc_saved_loadouts') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart:19](../lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart#L19) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart:21](../lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart#L21) | .collection('arc_raid_routes'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart:54](../lib/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart#L54) | return _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:33](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L33) | _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:36](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L36) | _userRef(uid).collection('arc_season_state').doc('current'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:39](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L39) | _userRef(uid).collection('arc_quest_progress'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:42](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L42) | _userRef(uid).collection('arc_quest_state').doc('current'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:45](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L45) | _userRef(uid).collection('arc_scrappy_progress').doc('current'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart:48](../lib/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart#L48) | _userRef(uid).collection('arc_bench_progress'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:20](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L20) | _firestore.collection('arc_item_dataset_versions').doc('active'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:24](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L24) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:26](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L26) | .collection('arc_item_protections'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:126](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L126) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart:128](../lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart#L128) | .collection('arc_item_recommendation_logs') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:30](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L30) | _firestore.collection('arc_operation_progress').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:33](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L33) | _summaryRef(uid).collection('operations'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:37](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L37) | .collection('arc_rewards_inventory') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:39](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L39) | .collection('items'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:42](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L42) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:44](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L44) | .collection('trading_activity') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:48](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L48) | _firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:51](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L51) | _userRef(uid).collection('arc_season_state').doc('current'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:54](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L54) | _firestore.collection('arc_equipped_cosmetics').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:57](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L57) | _firestore.collection('config').doc('arc_operations'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:582](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L582) | .collection('arc_operation_telemetry') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:584](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L584) | .collection('events'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart:587](../lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart#L587) | _firestore.collection('arc_operation_telemetry').doc(uid); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:46](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L46) | _firestore.collection('arc_match_rider_profiles'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:48](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L48) | _firestore.collection('arc_match_rider_invites'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:50](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L50) | _firestore.collection('trading_notifications'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:52](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L52) | _firestore.collection('arc_favourite_riders'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:56](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L56) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:58](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L58) | .collection('trading_activity') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart:193](../lib/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart#L193) | userSub = _firestore.collection('users').doc(uid).snapshots().listen(( |
| [lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart:18](../lib/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart#L18) | _firestore.collection('arc_community_intel_reports'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:32](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L32) | _firestore.collection('users').doc(uid).collection('arc_blueprints'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:47](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L47) | _firestore.collection('arc_blueprint_drop_reports'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:234](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L234) | final snapshot = await _firestore.collection(path).get(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart:433](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart#L433) | .collection('arc_admin_map_markers') |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart:12](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart#L12) | _firestore.collection('arc_blueprint_drop_reports'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart:12](../lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_demand_repository.dart#L12) | _firestore.collection('arc_blueprint_demand'); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_beta_feedback_repository.dart:30](../lib/features/trading_hub/arc_raiders/repositories/arc_beta_feedback_repository.dart#L30) | final document = _firestore.collection('beta_feedback').doc(); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:49](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L49) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:85](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L85) | final ref = _firestore.collection(collectionName).doc(original.id); |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:198](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L198) | _firestore.collection(collectionName).doc(marker.id), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:305](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L305) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:321](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L321) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:338](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L338) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:365](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L365) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:377](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L377) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:413](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L413) | .collection(blueprintReportCollectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:431](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L431) | .collection(communityIntelCollectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:460](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L460) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:482](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L482) | _firestore.collection(collectionName).doc(marker.id), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:495](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L495) | .collection(collectionName) |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:510](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L510) | _firestore.collection(collectionName).doc(markerId), |
| [lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart:526](../lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart#L526) | .collection(coverageCollectionName) |
| [lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart:351](../lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart#L351) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart:353](../lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart#L353) | .collection('arc_blueprints'); |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:18](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L18) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:20](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L20) | .collection('arc_blueprint_targets'); |
| [lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart:58](../lib/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart#L58) | .collection('users') |
| [lib/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart:20](../lib/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart#L20) | return (_firestore ?? FirebaseFirestore.instance).collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:120](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L120) | return firestore.collection('users').doc(uid); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:141](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L141) | final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get(); |
| [lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart:178](../lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart#L178) | final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get(); |
| [lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart:19](../lib/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart#L19) | return _firestore.collection('users').doc(uid).collection('arc_amplification_research').doc('state'); |
| [lib/features/release/widgets/uag_release_readiness_panel.dart:15](../lib/features/release/widgets/uag_release_readiness_panel.dart#L15) | .collection('config') |
| [lib/features/release/models/uag_release_runtime_diagnostics.dart:228](../lib/features/release/models/uag_release_runtime_diagnostics.dart#L228) | final userDoc = await firestore.collection('users').doc(user.uid).get(); |
| [lib/features/notifications/data/uag_notification_repository.dart:27](../lib/features/notifications/data/uag_notification_repository.dart#L27) | .collection('users') |
| [lib/features/notifications/data/uag_notification_repository.dart:29](../lib/features/notifications/data/uag_notification_repository.dart#L29) | .collection('notification_devices'); |
| [lib/features/notifications/data/uag_notification_repository.dart:34](../lib/features/notifications/data/uag_notification_repository.dart#L34) | .collection('users') |
| [lib/features/notifications/data/uag_notification_repository.dart:36](../lib/features/notifications/data/uag_notification_repository.dart#L36) | .collection('notification_preferences') |
| [lib/features/notifications/data/uag_notification_repository.dart:41](../lib/features/notifications/data/uag_notification_repository.dart#L41) | _firestore.collection('notification_broadcasts'); |
| [lib/features/notifications/data/uag_notification_repository.dart:44](../lib/features/notifications/data/uag_notification_repository.dart#L44) | _firestore.collection('uag_notification_schedules'); |
| [lib/features/notifications/data/uag_notification_repository.dart:111](../lib/features/notifications/data/uag_notification_repository.dart#L111) | .collection('users') |
| [lib/features/notifications/data/uag_notification_repository.dart:113](../lib/features/notifications/data/uag_notification_repository.dart#L113) | .collection('notification_tokens') |
| [lib/features/notifications/data/uag_notification_repository.dart:145](../lib/features/notifications/data/uag_notification_repository.dart#L145) | .collection('users') |
| [lib/features/notifications/data/uag_notification_repository.dart:147](../lib/features/notifications/data/uag_notification_repository.dart#L147) | .collection('notification_tokens') |
| [lib/features/notifications/data/uag_notification_repository.dart:179](../lib/features/notifications/data/uag_notification_repository.dart#L179) | .collectionGroup('notification_devices') |
| [lib/features/notifications/data/uag_notification_repository.dart:318](../lib/features/notifications/data/uag_notification_repository.dart#L318) | final doc = _firestore.collection(directInAppNotificationCollection).doc(); |
| [lib/features/notifications/data/uag_notification_repository.dart:337](../lib/features/notifications/data/uag_notification_repository.dart#L337) | .collection(directInAppNotificationCollection) |
| [lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart:26](../lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart#L26) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart:68](../lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart#L68) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart:89](../lib/features/monetisation/widgets/uag_creator_campaign_discount_admin_panel.dart#L89) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/widgets/uag_creator_admin_panel.dart:50](../lib/features/monetisation/widgets/uag_creator_admin_panel.dart#L50) | .collection('uag_creator_dashboard_aggregates') |
| [lib/features/monetisation/widgets/uag_commercial_offers_panel.dart:237](../lib/features/monetisation/widgets/uag_commercial_offers_panel.dart#L237) | .collection('uag_gift_codes') |
| [lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart:70](../lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart#L70) | final ref = _firestore.collection('uag_discount_campaigns').doc(code); |
| [lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart:110](../lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart#L110) | await _firestore.collection('uag_discount_campaigns').doc(code).set({ |
| [lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart:226](../lib/features/monetisation/widgets/uag_commercial_campaign_admin_panel.dart#L226) | stream: _firestore.collection('uag_discount_campaigns').snapshots(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:87](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L87) | final direct = await _firestore.collection('users').doc(query).get(); |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:93](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L93) | .collection('public_profiles') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:98](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L98) | .collection('users') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:103](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L103) | .collection('users') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:108](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L108) | .collection('users') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:113](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L113) | .collection('public_profiles') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:118](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L118) | .collection('public_profiles') |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:135](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L135) | _firestore.collection('users').doc(uid).get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:136](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L136) | _firestore.collection('public_profiles').doc(uid).get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:137](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L137) | _firestore.collection('uag_commercial_recognition').doc(uid).get(), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:345](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L345) | _firestore.collection('uag_commercial_recognition').doc(target.uid), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:355](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L355) | _firestore.collection('users').doc(target.uid), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:477](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L477) | _firestore.collection('uag_commercial_recognition').doc(uid), |
| [lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart:491](../lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart#L491) | batch.set(_firestore.collection('users').doc(uid), <String, dynamic>{ |
| [lib/features/monetisation/services/uag_referral_action_reward_service.dart:82](../lib/features/monetisation/services/uag_referral_action_reward_service.dart#L82) | .collection('uag_referral_action_rewards') |
| [lib/features/monetisation/services/uag_referral_action_reward_service.dart:84](../lib/features/monetisation/services/uag_referral_action_reward_service.dart#L84) | .collection('months') |
| [lib/features/monetisation/services/uag_raider_mark_service.dart:63](../lib/features/monetisation/services/uag_raider_mark_service.dart#L63) | .collection('uag_reward_wallets') |
| [lib/features/monetisation/services/uag_raider_mark_service.dart:79](../lib/features/monetisation/services/uag_raider_mark_service.dart#L79) | .collection('uag_reward_sessions') |
| [lib/features/monetisation/services/uag_operation_action_reward_service.dart:89](../lib/features/monetisation/services/uag_operation_action_reward_service.dart#L89) | .collection('arc_operation_progress') |
| [lib/features/monetisation/services/uag_operation_action_reward_service.dart:91](../lib/features/monetisation/services/uag_operation_action_reward_service.dart#L91) | .collection('operations') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:74](../lib/features/monetisation/services/uag_entitlement_service.dart#L74) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:100](../lib/features/monetisation/services/uag_entitlement_service.dart#L100) | final snapshot = await _firestore.collection('users').doc(currentUid).get(); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:169](../lib/features/monetisation/services/uag_entitlement_service.dart#L169) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:171](../lib/features/monetisation/services/uag_entitlement_service.dart#L171) | .collection('usage_counters'); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:204](../lib/features/monetisation/services/uag_entitlement_service.dart#L204) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:206](../lib/features/monetisation/services/uag_entitlement_service.dart#L206) | .collection('usage_counters') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:222](../lib/features/monetisation/services/uag_entitlement_service.dart#L222) | .collection('uag_reward_bonuses') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:224](../lib/features/monetisation/services/uag_entitlement_service.dart#L224) | .collection('months') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:245](../lib/features/monetisation/services/uag_entitlement_service.dart#L245) | .collection('uag_reward_bonuses') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:247](../lib/features/monetisation/services/uag_entitlement_service.dart#L247) | .collection('months') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:269](../lib/features/monetisation/services/uag_entitlement_service.dart#L269) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:271](../lib/features/monetisation/services/uag_entitlement_service.dart#L271) | .collection('usage_counters') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:307](../lib/features/monetisation/services/uag_entitlement_service.dart#L307) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:309](../lib/features/monetisation/services/uag_entitlement_service.dart#L309) | .collection('usage_counters') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:357](../lib/features/monetisation/services/uag_entitlement_service.dart#L357) | .collection('users') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:359](../lib/features/monetisation/services/uag_entitlement_service.dart#L359) | .collection('usage_counters') |
| [lib/features/monetisation/services/uag_entitlement_service.dart:382](../lib/features/monetisation/services/uag_entitlement_service.dart#L382) | final userRef = _firestore.collection('users').doc(currentUid); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:395](../lib/features/monetisation/services/uag_entitlement_service.dart#L395) | final codeRef = _firestore.collection('referral_codes').doc(code); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:428](../lib/features/monetisation/services/uag_entitlement_service.dart#L428) | await _firestore.collection('payout_requests').add({ |
| [lib/features/monetisation/services/uag_entitlement_service.dart:458](../lib/features/monetisation/services/uag_entitlement_service.dart#L458) | final userRef = _firestore.collection('users').doc(currentUid); |
| [lib/features/monetisation/services/uag_entitlement_service.dart:476](../lib/features/monetisation/services/uag_entitlement_service.dart#L476) | final userRef = _firestore.collection('users').doc(currentUid); |
| [lib/features/monetisation/screens/admin_monetisation_dashboard.dart:371](../lib/features/monetisation/screens/admin_monetisation_dashboard.dart#L371) | await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ |
| [lib/features/monetisation/repositories/uag_referral_validation_repository.dart:41](../lib/features/monetisation/repositories/uag_referral_validation_repository.dart#L41) | _firestore.collection('users').doc(uid); |
| [lib/features/monetisation/repositories/uag_referral_validation_repository.dart:46](../lib/features/monetisation/repositories/uag_referral_validation_repository.dart#L46) | ).collection('monetisation_usage').doc('community_referral_attribution'); |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:19](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L19) | _firestore.collection('uag_referral_reward_lockers').doc(uid); |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:22](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L22) | _lockerState(uid).collection('rewards'); |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:88](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L88) | .collection('uag_referral_reward_activation_requests') |
| [lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart:113](../lib/features/monetisation/repositories/uag_referral_reward_locker_repository.dart#L113) | .collection('uag_referral_reward_activation_requests') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:21](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L21) | return _firestore.collection('users').doc(uid).snapshots().map((snapshot) { |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:32](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L32) | final snapshot = await _firestore.collection('users').doc(uid).get(); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:52](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L52) | .collection('users') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:54](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L54) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:66](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L66) | .collection('impact_pots') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:80](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L80) | .collection('monetisation_events') |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:87](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L87) | return _firestore.collection('users').snapshots(); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:100](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L100) | final codeRef = _firestore.collection('referral_codes').doc(normalised); |
| [lib/features/monetisation/repositories/uag_monetisation_repository.dart:113](../lib/features/monetisation/repositories/uag_monetisation_repository.dart#L113) | transaction.set(_firestore.collection('users').doc(uid), { |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:24](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L24) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:43](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L43) | .collection('users') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:45](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L45) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:67](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L67) | .collection('uag_creator_applications') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:82](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L82) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:111](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L111) | .collection('users') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:113](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L113) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:154](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L154) | _firestore.collection('uag_creator_campaign_code_requests').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:157](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L157) | _firestore.collectionGroup('monetisation_usage').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:162](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L162) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:194](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L194) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:223](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L223) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:245](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L245) | .collection('uag_creator_dashboard_aggregates') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:283](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L283) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_repository.dart:307](../lib/features/monetisation/repositories/uag_creator_reward_repository.dart#L307) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart:79](../lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart#L79) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart:107](../lib/features/monetisation/repositories/uag_creator_reward_activation_repository.dart#L107) | final userRef = _firestore.collection('users').doc(recipientUid); |
| [lib/features/monetisation/repositories/uag_creator_referral_repository.dart:26](../lib/features/monetisation/repositories/uag_creator_referral_repository.dart#L26) | .collection('users') |
| [lib/features/monetisation/repositories/uag_creator_referral_repository.dart:28](../lib/features/monetisation/repositories/uag_creator_referral_repository.dart#L28) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:19](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L19) | _firestore.collection('uag_creator_applications'); |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:22](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L22) | _firestore.collection('uag_creator_campaign_code_requests'); |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:25](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L25) | _firestore.collection('uag_creator_dashboard_aggregates').doc(uid); |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:29](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L29) | .collection('uag_creator_commission_ledgers') |
| [lib/features/monetisation/repositories/uag_creator_programme_repository.dart:31](../lib/features/monetisation/repositories/uag_creator_programme_repository.dart#L31) | .collection('entries'); |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:23](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L23) | .collection('uag_creator_applications') |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:43](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L43) | .collection('uag_creator_dashboard_aggregates') |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:57](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L57) | .collection('uag_creator_campaign_code_requests') |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:82](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L82) | .collection('users') |
| [lib/features/monetisation/repositories/uag_creator_live_repository.dart:84](../lib/features/monetisation/repositories/uag_creator_live_repository.dart#L84) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:18](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L18) | _firestore.collection('uag_creator_applications'); |
| [lib/features/monetisation/repositories/uag_creator_front_door_repository.dart:21](../lib/features/monetisation/repositories/uag_creator_front_door_repository.dart#L21) | _firestore.collection('uag_creator_campaign_code_requests'); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:31](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L31) | _firestore.collectionGroup('monetisation_usage').snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:34](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L34) | _firestore.collection('users').doc(uid.trim()).snapshots(); |
| [lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart:94](../lib/features/monetisation/repositories/uag_creator_entitlement_bridge_repository.dart#L94) | final userRef = _firestore.collection('users').doc(recipientUid); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:20](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L20) | .collection('uag_creator_commission_ledgers') |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:22](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L22) | .collection('entries'); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:25](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L25) | _firestore.collection('uag_creator_dashboard_aggregates').doc(creatorUid); |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:29](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L29) | .collection('users') |
| [lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart:31](../lib/features/monetisation/repositories/uag_creator_commission_pipeline_repository.dart#L31) | .collection('monetisation_usage') |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:14](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L14) | .collection('uag_creator_commission_ledgers') |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:16](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L16) | .collection('entries'); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:19](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L19) | _firestore.collection('uag_creator_dashboard_aggregates').doc(creatorUid); |
| [lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart:22](../lib/features/monetisation/repositories/uag_creator_commission_integrity_repository.dart#L22) | _firestore.collection('app_config').doc('community_growth'); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:19](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L19) | _firestore.collection('users').doc(uid); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:22](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L22) | _firestore.collection('uag_referral_terms_acceptances').doc(uid); |
| [lib/features/monetisation/repositories/uag_community_referral_repository.dart:25](../lib/features/monetisation/repositories/uag_community_referral_repository.dart#L25) | _firestore.collection('uag_community_referral_codes'); |
| [lib/features/monetisation/repositories/uag_community_growth_repository.dart:12](../lib/features/monetisation/repositories/uag_community_growth_repository.dart#L12) | _firestore.collection('app_config').doc('community_growth'); |
| [lib/features/monetisation/ads/uag_ad_runtime_settings.dart:154](../lib/features/monetisation/ads/uag_ad_runtime_settings.dart#L154) | _firestore.collection('app_config').doc('ads'); |
| [lib/features/legal/repositories/uag_age_verification_repository.dart:19](../lib/features/legal/repositories/uag_age_verification_repository.dart#L19) | _firestore.collection('uag_age_verification_requests'); |
| [lib/features/legal/repositories/legal_repository.dart:12](../lib/features/legal/repositories/legal_repository.dart#L12) | final doc = await _firestore.collection('users').doc(uid).get(); |
| [lib/features/legal/repositories/legal_repository.dart:17](../lib/features/legal/repositories/legal_repository.dart#L17) | await _firestore.collection('users').doc(uid).set({ |
| [lib/features/legal/repositories/legal_repository.dart:32](../lib/features/legal/repositories/legal_repository.dart#L32) | await _firestore.collection('users').doc(uid).set({ |
| [lib/features/feature_access_gate.dart:136](../lib/features/feature_access_gate.dart#L136) | .collection('users') |
| [lib/features/feature_access_gate.dart:151](../lib/features/feature_access_gate.dart#L151) | .collection('config') |
| [lib/features/feature_access_gate.dart:171](../lib/features/feature_access_gate.dart#L171) | .collection('config') |
| [lib/features/feature_access_gate.dart:176](../lib/features/feature_access_gate.dart#L176) | .collection('users') |
| [lib/features/feature_access_gate.dart:197](../lib/features/feature_access_gate.dart#L197) | .collection('users') |
| [lib/features/feature_access_gate.dart:211](../lib/features/feature_access_gate.dart#L211) | .collection('config') |
| [lib/features/feature_access_gate.dart:283](../lib/features/feature_access_gate.dart#L283) | .collection('users') |
| [functions/index.js:291](../functions/index.js#L291) | const snapshot = await db.collection('uag_commercial_recognition').doc(uid).get(); |
| [functions/index.js:429](../functions/index.js#L429) | .collection('uag_commercial_checkout_reservations') |
| [functions/index.js:433](../functions/index.js#L433) | .collection('uag_gift_sender_months') |
| [functions/index.js:502](../functions/index.js#L502) | .collection('uag_commercial_checkout_reservations') |
| [functions/index.js:504](../functions/index.js#L504) | const campaignRef = db.collection('uag_discount_campaigns').doc(code); |
| [functions/index.js:505](../functions/index.js#L505) | const claimRef = db.collection('uag_promotion_claims').doc(${code}_${uid}); |
| [functions/index.js:596](../functions/index.js#L596) | .collection('uag_commercial_checkout_reservations') |
| [functions/index.js:615](../functions/index.js#L615) | .collection('uag_commercial_checkout_reservations') |
| [functions/index.js:631](../functions/index.js#L631) | counterRef = db.collection('uag_gift_sender_months').doc(counterDocId); |
| [functions/index.js:635](../functions/index.js#L635) | if (code) counterRef = db.collection('uag_discount_campaigns').doc(code); |
| [functions/index.js:691](../functions/index.js#L691) | db.collection('uag_referral_terms_acceptances').doc(ownerUid).get(), |
| [functions/index.js:692](../functions/index.js#L692) | db.collection('users').doc(ownerUid).get(), |
| [functions/index.js:709](../functions/index.js#L709) | db.collection('uag_creator_campaign_code_requests').doc(code).get(), |
| [functions/index.js:710](../functions/index.js#L710) | db.collection('uag_community_referral_codes').doc(code).get(), |
| [functions/index.js:711](../functions/index.js#L711) | db.collection('referral_codes').doc(code).get(), |
| [functions/index.js:712](../functions/index.js#L712) | db.collection('uag_discount_campaigns').doc(code).get(), |
| [functions/index.js:713](../functions/index.js#L713) | db.collection('uag_promotion_claims').doc(${code}_${uid}).get(), |
| [functions/index.js:793](../functions/index.js#L793) | .collection('uag_creator_applications') |
| [functions/index.js:827](../functions/index.js#L827) | const userRef = db.collection('users').doc(uid); |
| [functions/index.js:829](../functions/index.js#L829) | .collection('monetisation_usage') |
| [functions/index.js:832](../functions/index.js#L832) | .collection('monetisation_usage') |
| [functions/index.js:1008](../functions/index.js#L1008) | await db.collection('monetisation_checkout_sessions').doc(session.id).set({ |
| [functions/index.js:1069](../functions/index.js#L1069) | const callerSnap = await db.collection('users').doc(decoded.uid).get(); |
| [functions/index.js:1085](../functions/index.js#L1085) | .collection('uag_commercial_recognition') |
| [functions/index.js:1092](../functions/index.js#L1092) | const targetRef = db.collection('users').doc(targetUid); |
| [functions/index.js:1094](../functions/index.js#L1094) | .collection('uag_commercial_recognition') |
| [functions/index.js:1097](../functions/index.js#L1097) | .collection('uag_commercial_counters') |
| [functions/index.js:1223](../functions/index.js#L1223) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:1261](../functions/index.js#L1261) | const giftRef = db.collection('uag_gift_codes').doc(code); |
| [functions/index.js:1262](../functions/index.js#L1262) | const userRef = db.collection('users').doc(uid); |
| [functions/index.js:1263](../functions/index.js#L1263) | const historyRef = db.collection('uag_gift_recipient_history').doc(uid); |
| [functions/index.js:1264](../functions/index.js#L1264) | const eventRef = db.collection('monetisation_events').doc(gift_redeemed_${code}); |
| [functions/index.js:1459](../functions/index.js#L1459) | const checkoutRef = db.collection('monetisation_checkout_sessions').doc(session.id); |
| [functions/index.js:1461](../functions/index.js#L1461) | .collection('uag_gift_sender_months') |
| [functions/index.js:1467](../functions/index.js#L1467) | ? db.collection('uag_commercial_checkout_reservations').doc(reservationId) |
| [functions/index.js:1470](../functions/index.js#L1470) | const giftRef = db.collection('uag_gift_codes').doc(candidateCode); |
| [functions/index.js:1471](../functions/index.js#L1471) | const eventRef = db.collection('monetisation_events').doc(gift_${session.id}); |
| [functions/index.js:1592](../functions/index.js#L1592) | const campaignRef = db.collection('uag_discount_campaigns').doc(code); |
| [functions/index.js:1593](../functions/index.js#L1593) | const claimRef = db.collection('uag_promotion_claims').doc(${code}_${uid}); |
| [functions/index.js:1598](../functions/index.js#L1598) | ? db.collection('uag_commercial_checkout_reservations').doc(reservationId) |
| [functions/index.js:1749](../functions/index.js#L1749) | const userRef = db.collection('users').doc(uid); |
| [functions/index.js:1813](../functions/index.js#L1813) | ? await db.collection('uag_community_referral_paid_subscriptions').doc(subscription.id).get() |
| [functions/index.js:1847](../functions/index.js#L1847) | await db.collection('users').doc(uid).set({ |
| [functions/index.js:1932](../functions/index.js#L1932) | await db.collection('uag_commercial_recognition').doc(uid).set({ |
| [functions/index.js:1943](../functions/index.js#L1943) | await db.collection('users').doc(uid).set(userPatch, { merge: true }); |
| [functions/index.js:1947](../functions/index.js#L1947) | const userRef = db.collection('users').doc(uid); |
| [functions/index.js:1978](../functions/index.js#L1978) | transaction.set(db.collection('monetisation_events').doc(session.id), { |
| [functions/index.js:2024](../functions/index.js#L2024) | db.collection('supporter_entitlements').doc(uid).set({ |
| [functions/index.js:2028](../functions/index.js#L2028) | db.collection('users').doc(uid).set({ |
| [functions/index.js:2109](../functions/index.js#L2109) | const eventRef = db.collection('monetisation_events').doc(invoice.id); |
| [functions/index.js:2139](../functions/index.js#L2139) | const walletRef = db.collection('referral_wallets').doc(referralOwnerUid); |
| [functions/index.js:2143](../functions/index.js#L2143) | .collection('uag_community_referral_commission_ledgers') |
| [functions/index.js:2145](../functions/index.js#L2145) | .collection('entries') |
| [functions/index.js:2148](../functions/index.js#L2148) | .collection('uag_creator_commission_ledgers') |
| [functions/index.js:2150](../functions/index.js#L2150) | .collection('entries') |
| [functions/index.js:2159](../functions/index.js#L2159) | transaction.set(walletRef.collection('ledger').doc(invoice.id), { |
| [functions/index.js:2213](../functions/index.js#L2213) | .collection('uag_creator_dashboard_aggregates') |
| [functions/index.js:2269](../functions/index.js#L2269) | db.collection('users').doc(referrerUid).get(), |
| [functions/index.js:2270](../functions/index.js#L2270) | db.collection('uag_community_referral_paid_subscriptions') |
| [functions/index.js:2296](../functions/index.js#L2296) | .collection('uag_community_referral_paid_subscriptions') |
| [functions/index.js:2298](../functions/index.js#L2298) | const referrerRef = db.collection('users').doc(referrerUid); |
| [functions/index.js:2359](../functions/index.js#L2359) | const notificationRef = db.collection('trading_notifications').doc(notificationId); |
| [functions/index.js:2415](../functions/index.js#L2415) | db.collection('uag_creator_dashboard_aggregates').doc(creatorUid).get(), |
| [functions/index.js:2416](../functions/index.js#L2416) | db.collection('app_config').doc('community_growth').get(), |
| [functions/index.js:2475](../functions/index.js#L2475) | db.collection('uag_creator_referred_subscriptions') |
| [functions/index.js:2478](../functions/index.js#L2478) | db.collection('uag_creator_commission_ledgers') |
| [functions/index.js:2480](../functions/index.js#L2480) | .collection('entries') |
| [functions/index.js:2534](../functions/index.js#L2534) | await db.collection('uag_creator_dashboard_aggregates').doc(creatorUid).set({ |
| [functions/index.js:2560](../functions/index.js#L2560) | .collection('uag_creator_referred_subscriptions') |
| [functions/index.js:2587](../functions/index.js#L2587) | .collection('uag_creator_referred_subscriptions') |
| [functions/index.js:2608](../functions/index.js#L2608) | .collection('uag_creator_commission_ledgers') |
| [functions/index.js:2610](../functions/index.js#L2610) | .collection('entries') |
| [functions/index.js:2640](../functions/index.js#L2640) | .collection('monetisation_events') |
| [functions/index.js:2670](../functions/index.js#L2670) | const lockerRef = db.collection('uag_referral_reward_lockers').doc(uid); |
| [functions/index.js:2671](../functions/index.js#L2671) | const rewardRef = lockerRef.collection('rewards').doc(rewardId); |
| [functions/index.js:2701](../functions/index.js#L2701) | .collection('users') |
| [functions/index.js:2703](../functions/index.js#L2703) | .collection('monetisation_usage') |
| [functions/index.js:2760](../functions/index.js#L2760) | const referrerRef = db.collection('users').doc(referrerUid); |
| [functions/index.js:2766](../functions/index.js#L2766) | const referredRef = db.collection('users').doc(referredUid); |
| [functions/index.js:2860](../functions/index.js#L2860) | const eventRef = db.collection('monetisation_events').doc(invoiceId); |
| [functions/index.js:2872](../functions/index.js#L2872) | .collection(ledgerCollection) |
| [functions/index.js:2874](../functions/index.js#L2874) | .collection('entries') |
| [functions/index.js:2881](../functions/index.js#L2881) | const paidStateRef = db.collection('uag_community_referral_paid_subscriptions') |
| [functions/index.js:2893](../functions/index.js#L2893) | transaction.set(db.collection('users').doc(creatorUid), { |
| [functions/index.js:2950](../functions/index.js#L2950) | await db.collection('referral_wallets').doc(creatorUid).set( |
| [functions/index.js:2980](../functions/index.js#L2980) | .collection('uag_community_referral_validation_queue') |
| [functions/index.js:3011](../functions/index.js#L3011) | const lockerRef = db.collection('uag_referral_reward_lockers').doc(uid); |
| [functions/index.js:3012](../functions/index.js#L3012) | const rewardRef = lockerRef.collection('rewards').doc(rewardId); |
| [functions/index.js:3013](../functions/index.js#L3013) | const userRef = db.collection('users').doc(uid); |
| [functions/index.js:3121](../functions/index.js#L3121) | .collectionGroup('entries') |
| [functions/index.js:3154](../functions/index.js#L3154) | await db.collection('referral_wallets').doc(creatorUid).set({ |
| [functions/index.js:3174](../functions/index.js#L3174) | .collection('uag_creator_referred_subscriptions') |
| [functions/index.js:3206](../functions/index.js#L3206) | .collection('uag_community_referral_validation_queue') |
| [functions/index.js:3228](../functions/index.js#L3228) | .collection('uag_referral_reward_lockers') |
| [functions/index.js:3237](../functions/index.js#L3237) | const rewardRef = locker.ref.collection('rewards').doc(rewardId); |
| [functions/index.js:3409](../functions/index.js#L3409) | .collection('users') |
| [functions/index.js:3411](../functions/index.js#L3411) | .collection('notification_devices') |
| [functions/index.js:3427](../functions/index.js#L3427) | .collection('users') |
| [functions/index.js:3429](../functions/index.js#L3429) | .collection('notification_tokens') |
| [functions/index.js:3493](../functions/index.js#L3493) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3513](../functions/index.js#L3513) | let query = db.collectionGroup('notification_devices') |
| [functions/index.js:3545](../functions/index.js#L3545) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3567](../functions/index.js#L3567) | const ref = db.collection('trading_notifications').doc(${broadcastId}_${uid}); |
| [functions/index.js:3655](../functions/index.js#L3655) | const userSnap = await db.collection('users').doc(uid).get(); |
| [functions/index.js:3662](../functions/index.js#L3662) | db.collection('uag_user_blocks').doc(messagingBlockId(leftUid, rightUid)).get(), |
| [functions/index.js:3663](../functions/index.js#L3663) | db.collection('uag_user_blocks').doc(messagingBlockId(rightUid, leftUid)).get(), |
| [functions/index.js:3948](../functions/index.js#L3948) | await db.collection('uag_moderation_queue').doc(id).set({ |
| [functions/index.js:4129](../functions/index.js#L4129) | const ref = db.collection('uag_notification_schedules').doc(schedule.id); |
| [functions/index.js:4145](../functions/index.js#L4145) | batch.set(db.collection('uag_notification_schedules').doc(id), { |
| [functions/index.js:4286](../functions/index.js#L4286) | .collection('users') |
| [functions/index.js:4288](../functions/index.js#L4288) | .collection('notification_preferences') |
| [functions/index.js:4331](../functions/index.js#L4331) | const notificationRef = db.collection('trading_notifications').doc(notificationId); |
| [functions/index.js:4397](../functions/index.js#L4397) | const dueSnap = await db.collection('uag_notification_schedules') |
| [functions/index.js:4524](../functions/index.js#L4524) | await db.collection('notification_delivery_reports').doc(broadcastId).set({ |
| [functions/index.js:4545](../functions/index.js#L4545) | await db.collection('notification_delivery_reports').doc(broadcastId).set({ |
| [functions/index.js:4641](../functions/index.js#L4641) | transaction.set(db.collection('users').doc(uid), { |
| [functions/index.js:4745](../functions/index.js#L4745) | const messageRef = db.collection('uag_messages').doc(messageId); |
| [functions/index.js:4923](../functions/index.js#L4923) | let query = db.collection('trading_watch_preferences').orderBy(admin.firestore.FieldPath.documentId()).limit(200); |
| [functions/index.js:4937](../functions/index.js#L4937) | const states = await db.collection('users').doc(uid).collection('arc_blueprints').get(); |
| [functions/index.js:4947](../functions/index.js#L4947) | const ref = db.collection('trading_notifications').doc(notificationId); |

## External service references

| Source | Expression |
|---|---|
| [functions/index.js:3891](../functions/index.js#L3891) | const response = await fetch('https://language.googleapis.com/v1/documents:moderateText', { |
