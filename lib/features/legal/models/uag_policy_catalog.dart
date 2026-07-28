class UagPolicyDocument {
  const UagPolicyDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.summary,
    required this.body,
    this.mandatory = true,
    this.requiresLegalReview = true,
    this.missingOperatorDetails = true,
  });

  final String id;
  final String title;
  final int version;
  final String effectiveDate;
  final String summary;
  final String body;
  final bool mandatory;
  final bool requiresLegalReview;
  final bool missingOperatorDetails;
}

class UagFanProjectNotice {
  const UagFanProjectNotice._();

  static const version = 2;

  static const text =
      'UAG ARC Raiders Hub is an independent, unofficial fan-made companion '
      'tool for ARC Raiders. ARC Raiders, Embark Studios, and all related '
      'names, marks, images, game assets and intellectual property belong to '
      'their respective rights holders. This app is not affiliated with, '
      'endorsed by, sponsored by or supported by Embark Studios. Game-related '
      'references are used for community information, compatibility tracking '
      'and player-created intel. Rights-holder takedown requests will be '
      'reviewed and acted on promptly.';
}

class UagPolicyCatalog {
  const UagPolicyCatalog._();

  static const currentPolicyVersion = 1;
  static const effectiveDate = '2026-07-28';
  static const legalReviewNotice =
      'Draft policy text. Requires qualified legal review before launch.';

  static const documents = <UagPolicyDocument>[
    UagPolicyDocument(
      id: 'terms_of_use',
      title: 'Terms of Use',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Account rules, acceptable use and platform limitations.',
      body:
          '$legalReviewNotice Users must follow platform rules, keep account '
          'details accurate, avoid abuse, and understand that game data may '
          'change during beta.',
    ),
    UagPolicyDocument(
      id: 'privacy_policy',
      title: 'Privacy Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Personal data, account data and Firebase storage usage.',
      body:
          '$legalReviewNotice The app stores profile, progression, trading, '
          'notification and consent data needed to operate the companion.',
    ),
    UagPolicyDocument(
      id: 'fan_project_notice',
      title: 'Fan Project Notice',
      version: UagFanProjectNotice.version,
      effectiveDate: effectiveDate,
      summary: 'Unofficial ARC Raiders fan project and rights-holder notice.',
      body: UagFanProjectNotice.text,
    ),
    UagPolicyDocument(
      id: 'data_attribution',
      title: 'Data Attribution',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Community intel, sources and correction handling.',
      body:
          '$legalReviewNotice Community and public-source data should be '
          'credited, reviewable and removable when inaccurate or unauthorised.',
    ),
    UagPolicyDocument(
      id: 'trader_code_of_conduct',
      title: 'Trader Code of Conduct',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Fair trading, session behaviour and trust expectations.',
      body:
          '$legalReviewNotice Users must avoid scams, harassment, impersonation '
          'and pressure tactics during trades or group sessions.',
    ),
    UagPolicyDocument(
      id: 'community_intel_policy',
      title: 'Community Intel Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Intel reporting, verification, disputes and confidence.',
      body:
          '$legalReviewNotice Intel reports may be verified, disputed, hidden '
          'or removed when evidence is weak, abusive or misleading.',
    ),
    UagPolicyDocument(
      id: 'blueprint_report_policy',
      title: 'Blueprint Report Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Blueprint drop report evidence and map intelligence rules.',
      body:
          '$legalReviewNotice Personally found reports may feed map intel. '
          'Gifted or indirect reports need original find context before they '
          'are treated as location evidence.',
    ),
    UagPolicyDocument(
      id: 'gifted_drop_policy',
      title: 'Gifted Drop Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Gifted, traded and recovered in-raid item disclosures.',
      body:
          '$legalReviewNotice Gifted or handed-over items must identify the '
          'handover source and should not be used as precise location proof '
          'without original pickup context.',
    ),
    UagPolicyDocument(
      id: 'conduct_report_policy',
      title: 'Conduct Report Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Report intake, evidence, review and outcomes.',
      body:
          '$legalReviewNotice Conduct reports require relevant context and '
          'should protect reporters, accused users and admins from misuse.',
    ),
    UagPolicyDocument(
      id: 'contracts_rewards_policy',
      title: 'Contracts and Rewards Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Community contracts, evidence and reward handling.',
      body:
          '$legalReviewNotice Contracts are not escrow and rewards must not be '
          'represented as guaranteed unless a real fulfilment provider exists.',
    ),
    UagPolicyDocument(
      id: 'reward_vault_policy',
      title: 'Reward Vault Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Cosmetic unlocks, profile display and entitlement storage.',
      body:
          '$legalReviewNotice Reward Vault cosmetics are app profile cosmetics '
          'and do not grant ARC Raiders in-game items.',
    ),
    UagPolicyDocument(
      id: 'subscriptions_ads_policy',
      title: 'Subscriptions and Ads Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Free, Essential, Premium, ads and billing boundaries.',
      body:
          '$legalReviewNotice Free may show passive or rewarded ads. Essential '
          'and Premium are configured as no-ad tiers. Billing checkout must use '
          'real provider confirmation before granting paid entitlements.',
    ),
    UagPolicyDocument(
      id: 'supporter_programme_policy',
      title: 'Supporter Programme Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Founding supporter recognition and future discount intent.',
      body:
          '$legalReviewNotice Supporter status is separate from subscriptions '
          'and must not imply Premium entitlement, in-game rewards or finalised '
          'future discounts until commercially approved.',
    ),
    UagPolicyDocument(
      id: 'referrals_creator_policy',
      title: 'Referrals and Creator Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Referral discounts, commission timing and payout review.',
      body:
          '$legalReviewNotice Referral and Creator Programme participation is '
          'not employment, does not guarantee earnings, requires truthful '
          'promotion and disclosure where required, prohibits spam, '
          'self-referrals, fraudulent accounts and prohibited brand claims, '
          'and keeps balances pending during refund or chargeback risk. Paid '
          'conversions and commissions require provider-confirmed ledger '
          'events before they are payable.',
    ),
    UagPolicyDocument(
      id: 'age_restriction_policy',
      title: '18+ Age Restriction Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'UAG ARC Raiders Hub accounts are restricted to adults.',
      body:
          '$legalReviewNotice UAG ARC Raiders Hub is an 18+ account service. '
          'Users must complete the age gate before messaging, trading, '
          'creator, subscription or community features are made available. '
          'Rejected users may request human review where operationally '
          'available.',
    ),
    UagPolicyDocument(
      id: 'notifications_policy',
      title: 'Notifications Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Push, in-app, reminders and preference categories.',
      body:
          '$legalReviewNotice Users should be able to control notification '
          'categories including trading, intel, contracts, conduct and policy '
          'updates where allowed by law.',
    ),
    UagPolicyDocument(
      id: 'voice_companion_policy',
      title: 'Voice Companion Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Voice commands, speech recognition and safety limits.',
      body:
          '$legalReviewNotice Voice companion responses are assistance only; '
          'users remain responsible for trades, reports and route choices.',
    ),
    UagPolicyDocument(
      id: 'image_import_ocr_policy',
      title: 'Image Import and OCR Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Screenshot import, OCR confidence and user confirmation.',
      body:
          '$legalReviewNotice OCR output must be user-confirmed before it '
          'writes progression, report or inventory state.',
    ),
    UagPolicyDocument(
      id: 'user_content_policy',
      title: 'User Content Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Uploaded content, links, screenshots and profile material.',
      body:
          '$legalReviewNotice Users must only upload content they have rights '
          'to share and must not upload harmful, abusive or private material.',
    ),
    UagPolicyDocument(
      id: 'moderation_appeals_policy',
      title: 'Moderation and Appeals Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Moderation outcomes, appeals and admin review.',
      body:
          '$legalReviewNotice UAG may analyse messages, reports and user '
          'content with automated rules and configured service providers to '
          'detect abuse, threats, scams, doxxing, sexual or grooming risk, '
          'spam and blocked links. High-risk material may be withheld for '
          'human review, preserved as evidence and appealed where practical. '
          'Moderation decisions should be logged, reviewable and appealable '
          'where practical.',
    ),
    UagPolicyDocument(
      id: 'data_rights_policy',
      title: 'Data Rights and Deletion Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Access, correction, deletion and account closure requests.',
      body:
          '$legalReviewNotice Users need a clear way to request data access, '
          'correction, deletion and account closure once operator details are '
          'confirmed.',
    ),
    UagPolicyDocument(
      id: 'copyright_takedown_policy',
      title: 'Copyright and Takedown Policy',
      version: currentPolicyVersion,
      effectiveDate: effectiveDate,
      summary: 'Rights-holder requests, asset removal and disputes.',
      body:
          '$legalReviewNotice Rights-holder requests should capture claimant '
          'identity, affected content, requested action and review outcome.',
    ),
  ];

  static UagPolicyDocument byId(String id) {
    return documents.firstWhere(
      (document) => document.id == id,
      orElse: () => documents.first,
    );
  }
}
