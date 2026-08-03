import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_setup.dart';

void main() {
  group('PASS 307 onboarding setup', () {
    test('validates onboarding account fields', () {
      expect(validateArcOnboardingEmail('mike@example.com'), isNull);
      expect(validateArcOnboardingEmail('not-an-email'), isNotNull);
      expect(
        validateArcOnboardingConfirmEmail(
          email: 'Mike@Example.com',
          confirmEmail: 'mike@example.com',
        ),
        isNull,
      );
      expect(
        validateArcOnboardingConfirmEmail(
          email: 'mike@example.com',
          confirmEmail: 'other@example.com',
        ),
        isNotNull,
      );
      expect(validateArcOnboardingPassword('Raider1'), isNull);
      expect(validateArcOnboardingPassword('raider1'), isNotNull);
      expect(validateArcOnboardingPassword('Raider'), isNotNull);
      expect(
        validateArcOnboardingConfirmPassword(
          password: 'Raider1',
          confirmPassword: 'Raider1',
        ),
        isNull,
      );
      expect(
        validateArcOnboardingConfirmPassword(
          password: 'Raider1',
          confirmPassword: 'Raider2',
        ),
        isNotNull,
      );
    });

    test('builds the pending account creation payload', () {
      final payload = buildArcOnboardingAccountCreationPayload(
        email: '  MIKE@Example.com ',
        riderName: '  Mike  ',
      );

      expect(payload['email'], 'mike@example.com');
      expect(payload['displayName'], 'Mike');
      expect(payload['uagName'], 'Mike');
      expect(payload['onboardingComplete'], isFalse);
      expect(payload['arcMandatoryOnboardingComplete'], isFalse);
      expect(payload['createdAt'], isA<FieldValue>());
      expect(payload['updatedAt'], isA<FieldValue>());
      expect(payload.containsKey('ageVerification'), isFalse);

      final onboarding = payload['arcOnboarding'] as Map<String, dynamic>;
      expect(onboarding['version'], 4);
      expect(onboarding['accountCreatedDuringOnboarding'], isTrue);
      expect(onboarding['accountCreatedAt'], isA<FieldValue>());
      expect(onboarding['flow'], [
        'account',
        'legal',
        'primaryGoal',
        'blueprintSetup',
      ]);
    });

    test('builds a safe account profile sync payload', () {
      final payload = buildArcOnboardingAccountProfilePayload(
        email: '  MIKE@Example.com ',
        riderName: '  Mike  ',
      );

      expect(payload['email'], 'mike@example.com');
      expect(payload['displayName'], 'Mike');
      expect(payload['uagName'], 'Mike');
      expect(payload['updatedAt'], isA<FieldValue>());
      expect(payload.containsKey('onboardingComplete'), isFalse);
      expect(payload.containsKey('arcMandatoryOnboardingComplete'), isFalse);
      expect(payload.containsKey('createdAt'), isFalse);

      final onboarding = payload['arcOnboarding'] as Map<String, dynamic>;
      expect(onboarding['accountCreatedDuringOnboarding'], isTrue);
      expect(onboarding.containsKey('accountCreatedAt'), isFalse);
    });

    test('validates Raider names', () {
      expect(validateArcRiderName('Mike'), isNull);
      expect(validateArcRiderName('Arc-Rider.01'), isNull);
      expect(validateArcRiderName(''), isNotNull);
      expect(validateArcRiderName('ab'), isNotNull);
      expect(validateArcRiderName('name@invalid'), isNotNull);
      expect(validateArcRiderName('x' * 25), isNotNull);
    });

    test('routes fresh admin previews to account creation', () {
      final freshPreview = ArcMandatoryOnboardingScreen.fromRouteSettings(
        const RouteSettings(
          arguments: <String, Object>{
            'adminPreview': true,
            'playerState': 'fresh',
          },
        ),
      );
      final activePreview = ArcMandatoryOnboardingScreen.fromRouteSettings(
        const RouteSettings(
          arguments: <String, Object>{
            'adminPreview': true,
            'playerState': 'active',
          },
        ),
      );
      final normalRoute = ArcMandatoryOnboardingScreen.fromRouteSettings(
        const RouteSettings(
          arguments: <String, Object>{
            'adminPreview': false,
            'playerState': 'fresh',
          },
        ),
      );

      expect(freshPreview.adminPreview, isTrue);
      expect(freshPreview.previewAccountCreation, isTrue);
      expect(activePreview.adminPreview, isTrue);
      expect(activePreview.previewAccountCreation, isFalse);
      expect(normalRoute.adminPreview, isFalse);
      expect(normalRoute.previewAccountCreation, isFalse);
    });

    test(
      'selects account creation for new users and admin registration previews',
      () {
        expect(
          shouldShowArcOnboardingAccountCreation(
            adminPreview: false,
            previewAccountCreation: false,
            accountCreatedDuringOnboarding: false,
            hasCurrentUser: false,
          ),
          isTrue,
        );
        expect(
          shouldShowArcOnboardingAccountCreation(
            adminPreview: false,
            previewAccountCreation: false,
            accountCreatedDuringOnboarding: false,
            hasCurrentUser: true,
          ),
          isFalse,
        );
        expect(
          shouldShowArcOnboardingAccountCreation(
            adminPreview: true,
            previewAccountCreation: false,
            accountCreatedDuringOnboarding: false,
            hasCurrentUser: true,
          ),
          isFalse,
        );
        expect(
          shouldShowArcOnboardingAccountCreation(
            adminPreview: true,
            previewAccountCreation: true,
            accountCreatedDuringOnboarding: false,
            hasCurrentUser: true,
          ),
          isTrue,
        );
        expect(
          shouldShowArcOnboardingAccountCreation(
            adminPreview: true,
            previewAccountCreation: true,
            accountCreatedDuringOnboarding: true,
            hasCurrentUser: false,
          ),
          isFalse,
        );
      },
    );

    test('builds the essential version 4 completion payload', () {
      final payload = buildArcOnboardingCompletionPayload(
        riderName: '  Mike  ',
        primaryGoal: 'completeBlueprints',
        blueprintSetupMode: 'importScreenshots',
        recommendedFirstSystem: 'blueprintTracker',
        legalAccepted: const <String, dynamic>{
          'termsOfServiceAccepted': true,
          'ageConfirmationAccepted': true,
        },
        accountCreatedDuringOnboarding: true,
      );

      expect(payload['displayName'], 'Mike');
      expect(payload['onboardingComplete'], isTrue);
      expect(payload['arcMandatoryOnboardingComplete'], isTrue);
      expect(payload['updatedAt'], isA<FieldValue>());

      final ageVerification =
          payload['ageVerification'] as Map<String, dynamic>;
      expect(ageVerification['verifiedOver18'], isTrue);
      expect(ageVerification['source'], 'arcMandatoryOnboarding');
      expect(ageVerification['verifiedAt'], isA<FieldValue>());

      final onboarding = payload['arcOnboarding'] as Map<String, dynamic>;
      expect(onboarding['version'], 4);
      expect(onboarding['accountCreatedDuringOnboarding'], isTrue);
      expect(onboarding['flow'], [
        'account',
        'legal',
        'primaryGoal',
        'blueprintSetup',
      ]);
      expect(onboarding['riderName'], 'Mike');
      expect(onboarding['primaryGoal'], 'completeBlueprints');
      expect(onboarding['blueprintSetupMode'], 'importScreenshots');
      expect(onboarding['recommendedFirstSystem'], 'blueprintTracker');
      expect(onboarding['completedAt'], isA<FieldValue>());
    });
  });
}
