# UAG ARC Raiders Hub — UK Legal & Compliance Self-Audit

**Status date:** 18 September 2026
**Operator:** MobCorp Limited (company no. 16857854)
**Contact:** contact@mobcorp.co.uk
**Purpose:** Internal compliance control for beta and Play release preparation.

> This is an internal operational self-audit, not solicitor sign-off or formal legal advice. Independent professional UK legal review is planned once UAG begins generating revenue or before material commercial/international scale.

## Current position

- Operator identity, service address, support contact and public policy URLs are configured.
- Privacy, Terms, Subscriptions & Refunds and Support policies are available in-app and prepared for Firebase Hosting.
- UAG is expressly described as an independent, unofficial ARC Raiders companion and not affiliated with or endorsed by Embark Studios.
- Android paid digital access is designated for Google Play Billing; web billing remains the Stripe route.
- Google Cloud Natural Language and Google Cloud Vision are selected providers but remain configuration items until enabled server-side.
- Independent professional legal review is **deferred/advisory**, not a closed-beta blocker.

## Compliance checks

### 1. Consumer information and distance selling — operationally covered, billing implementation still pending
Before paid checkout, UAG must clearly show the trader identity, description of the service, total price, billing period, renewal/cancellation conditions and applicable cancellation information. The policy set preserves statutory rights rather than attempting to contract them away. Google Play/Stripe checkout and confirmation flows must provide the final transaction-specific information and durable confirmation.

### 2. Subscriptions and cancellation — configuration required before taking Android payments
The Play Console app is now created. Before Android subscriptions go live, create product IDs/base plans, expose an easy-to-use Google Play subscription-management/cancellation link from account settings, and verify provider-confirmed entitlement changes, cancellation, refund, revocation and chargeback handling.

### 3. Privacy transparency — operationally covered; maintain as features change
The Privacy Policy identifies MobCorp Limited, the data categories used by UAG, purposes/lawful bases, provider categories, international transfers, rights, complaints, retention principles, moderation/OCR providers and support contact. Update the policy whenever data collection, providers, ads, billing, analytics or moderation materially change.

### 4. Account deletion — implemented in source; production deployment/release verification required
The source now provides Privacy & Data > Delete My Account with recent password reauthentication, explicit acknowledgement and typed DELETE confirmation. Deletion is backend-orchestrated: ordinary account-owned data and account storage are removed, shared trust/safety/dispute and legal records are minimised where retention is justified, and a server-only tombstone prevents delayed account writes from recreating deleted user records. The public Support and Privacy pages continue to expose the external request route using contact@mobcorp.co.uk and the support-page anchor. Before Play release, deploy the account-deletion Functions, verify the production route end-to-end, and confirm associated user data is deleted except for information lawfully retained for security, fraud prevention, disputes, billing, tax, payout or legal obligations. Account deletion is explicitly separate from third-party subscription cancellation.

### 5. Age/safeguarding — policy position is 18+
The current UAG policy catalogue defines the account service as 18+. Play Console target-audience declarations, onboarding age controls and moderation/safeguarding behaviour must stay consistent with that position. If the product later intentionally admits minors, a dedicated child-data and age-appropriate design review is required before that change.

### 6. Advertising and consent — separate monetisation pass required
The legal framework allows ads and consent records, but real Android UMP/AdMob placement and consent implementation remains a separate release task. Privacy/Data Safety declarations must match the final SDK behaviour.

### 7. User-generated content, reports and moderation — operational policy coverage present
Trader conduct, user content, reporting, moderation/appeals and safety policies exist. Automated moderation must remain support for proportionate enforcement, with human review routes where appropriate. Cloud moderation must not be described as active until the provider is actually configured.

### 8. Third-party game intellectual property — attribution/independence language present
Public and in-app policies state that UAG is unofficial, independent and not endorsed by Embark Studios, and that third-party names, marks, artwork, images and game assets remain the property of their rights holders. Rights-holder takedown requests have a support route. This reduces confusion risk but does not create a licence to use third-party IP.

### 9. International availability — review at scale
UK law is the operating baseline. Mandatory consumer/data-protection rights in a user's jurisdiction are not contracted away. Before material expansion into additional markets or materially higher revenue, review local consumer, privacy, tax and platform requirements.

### 10. Evidence and maintenance
Re-run this self-audit when any of the following materially change: subscriptions/pricing, payment provider, ads/consent SDKs, account deletion, age eligibility, moderation/OCR providers, data collection, international launch markets, user-content features, or third-party IP use.

## Current release-readiness outcome

- **Legal/compliance self-audit:** Ready for beta operations.
- **Independent professional legal review:** Deferred until revenue begins or before material commercial/international scale.
- **Account deletion:** In-app and external routes implemented in source; Firebase Functions deployment and production end-to-end verification remain required before Play release.
- **Google Play Billing:** Configuration required now that the Play app exists.
- **No claim of solicitor sign-off:** Correct.

## Official guidance used for this self-audit

- GOV.UK — Online and distance selling: https://www.gov.uk/online-and-distance-selling-for-businesses
- GOV.UK — Online selling / digital services: https://www.gov.uk/online-and-distance-selling-for-businesses/online-selling
- ICO — What privacy information should we provide?: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/the-right-to-be-informed/what-privacy-information-should-we-provide/
- ICO — Legitimate interests guidance: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/a-guide-to-lawful-basis/legitimate-interests/
- ICO — Children and the UK GDPR: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/children-and-the-uk-gdpr/
- Google Play — User data / privacy policy / account deletion: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play — Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- Google Play — Payments policy: https://support.google.com/googleplay/android-developer/answer/10281818
- Google Play — Subscriptions, cancellation and refunds: https://support.google.com/googleplay/android-developer/answer/9900533
