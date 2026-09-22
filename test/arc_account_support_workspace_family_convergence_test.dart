import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_support_workspace_bar.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('account and support family exposes one compact navigation contract', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_account_support_workspace_bar.dart',
    );

    expect(source, contains('enum ArcAccountSupportWorkspace'));
    expect(ArcAccountSupportWorkspace.values, const [
      ArcAccountSupportWorkspace.plans,
      ArcAccountSupportWorkspace.settings,
      ArcAccountSupportWorkspace.privacy,
      ArcAccountSupportWorkspace.help,
      ArcAccountSupportWorkspace.feedback,
      ArcAccountSupportWorkspace.legal,
    ]);
    expect(source, contains("return '/monetisation';"));
    expect(source, contains("return '/profile-settings';"));
    expect(source, contains("return '/privacy-data';"));
    expect(source, contains("return '/trading-hub/arc-raiders/help';"));
    expect(source, contains("return '/arc-raiders/closed-beta-feedback';"));
    expect(source, contains("return '/legal';"));
    expect(source, contains('rootNavigator: true'));
    expect(source, isNot(contains('UagEntitlementService')));
    expect(source, isNot(contains('ArcBetaFeedbackRepository')));
  });

  test(
    'plans settings privacy help feedback and legal join the support family',
    () {
      final screens = <String, String>{
        'lib/features/monetisation/screens/monetisation_screen.dart':
            'ArcAccountSupportWorkspace.plans',
        'lib/features/profile/screens/profile_settings_screen.dart':
            'ArcAccountSupportWorkspace.settings',
        'lib/features/legal/screens/privacy_data_screen.dart':
            'ArcAccountSupportWorkspace.privacy',
        'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart':
            'ArcAccountSupportWorkspace.help',
        'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart':
            'ArcAccountSupportWorkspace.feedback',
        'lib/features/legal/screens/legal_hub_screen.dart':
            'ArcAccountSupportWorkspace.legal',
      };

      for (final entry in screens.entries) {
        final source = read(entry.key);
        expect(
          source,
          contains('ArcAccountSupportWorkspaceBar('),
          reason: entry.key,
        );
        expect(source, contains(entry.value), reason: entry.key);
      }
    },
  );

  test('legal hub has a registered named route', () {
    final legal = read('lib/features/legal/screens/legal_hub_screen.dart');
    final mainSource = read('lib/main.dart');

    expect(legal, contains("static const routeName = '/legal';"));
    expect(
      mainSource,
      contains('features/legal/screens/legal_hub_screen.dart'),
    );
    expect(mainSource, contains('case LegalHubScreen.routeName:'));
    expect(mainSource, contains('builder: (_) => const LegalHubScreen()'));
  });

  test('support family preserves existing source-of-truth wiring', () {
    final plans = read(
      'lib/features/monetisation/screens/monetisation_screen.dart',
    );
    final settings = read(
      'lib/features/profile/screens/profile_settings_screen.dart',
    );
    final help = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
    );
    final feedback = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
    );
    final legal = read('lib/features/legal/screens/legal_hub_screen.dart');

    expect(plans, contains('_entitlementService.watchMyEntitlement()'));
    expect(plans, contains('_checkoutService.startCheckout(planId: planId)'));
    expect(settings, contains('UagNotificationPreferencesPanel'));
    expect(settings, contains('ArcPersonalisationPreferencesPanel'));
    expect(help, contains('ArcHelpCentreCatalog.categories'));
    expect(
      feedback,
      contains('final _repository = ArcBetaFeedbackRepository();'),
    );
    expect(feedback, contains('final id = await _repository.submit('));
    expect(legal, contains('UagPolicyCatalog.documents'));
  });

  testWidgets('account and support bar is responsive at Sony-class width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: ArcAccountSupportWorkspaceBar(
              current: ArcAccountSupportWorkspace.help,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLANS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('PRIVACY'), findsOneWidget);
    expect(find.text('HELP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
