class UagAdReleaseSafety {
  const UagAdReleaseSafety._();

  static const List<String> requiredBeforeProductionAds = <String>[
    'Use test ads in all debug/internal builds.',
    'Confirm GDPR/UK consent flow is fully implemented.',
    'Confirm privacy policy explains ads, consent and data use.',
    'Publish app-ads.txt for the production publisher account.',
    'Verify AdMob app and banner unit are approved.',
    'Confirm production ads are not shown to premium users.',
    'Confirm banner placement never covers navigation, dock, buttons or gameplay-critical UI.',
    'Confirm no accidental clicks are encouraged by spacing or wording.',
    'Run a signed release build QA pass before enabling production IDs.',
  ];

  static const String productionAdWarning =
      'Production ads are locked until releaseBuildAllowsProductionAds, '
      'releaseChecklistComplete, consent, and the production toggle are all true.';
}
