import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public legal pages expose canonical operator and support details', () {
    final privacy = File('web/privacy.html').readAsStringSync();
    final terms = File('web/terms.html').readAsStringSync();
    final refunds = File('web/subscriptions-refunds.html').readAsStringSync();
    final support = File('web/support.html').readAsStringSync();

    for (final source in [privacy, terms, refunds, support]) {
      expect(source, contains('MobCorp Limited'));
      expect(source, contains('contact@mobcorp.co.uk'));
    }

    expect(privacy, contains('Google Cloud Natural Language'));
    expect(privacy, contains('Google Cloud Vision'));
    expect(refunds, contains('Google Play Billing'));
    expect(refunds, contains('Stripe'));
    expect(support, contains('id="account-deletion"'));
    expect(privacy, contains('id="account-deletion"'));
    expect(terms, contains('Independent professional UK legal review'));
    expect(
      [privacy, terms, refunds].join(' '),
      isNot(contains('qualified UK legal review before general public launch')),
    );
  });

  test(
    'Firebase Hosting exposes stable clean legal URLs before SPA fallback',
    () {
      final firebase = File('firebase.json').readAsStringSync();

      expect(firebase, contains('"source": "/privacy"'));
      expect(firebase, contains('"destination": "/privacy.html"'));
      expect(firebase, contains('"source": "/terms"'));
      expect(firebase, contains('"source": "/subscriptions-refunds"'));
      expect(firebase, contains('"source": "/support"'));

      final privacyIndex = firebase.indexOf('"source": "/privacy"');
      final spaFallback = firebase.indexOf('"source": "**"');
      expect(privacyIndex, greaterThanOrEqualTo(0));
      expect(spaFallback, greaterThan(privacyIndex));
    },
  );

  test('server health check reports selected moderation and OCR providers', () {
    final functions = File('functions/index.js').readAsStringSync();

    expect(functions, contains("'google_natural_language'"));
    expect(functions, contains("'google_cloud_vision'"));
    expect(functions, contains('UAG_MODERATION_PROVIDER_ENABLED'));
    expect(functions, contains('UAG_OCR_PROVIDER_ENABLED'));
    expect(functions, contains('ocr: {'));
  });
}
