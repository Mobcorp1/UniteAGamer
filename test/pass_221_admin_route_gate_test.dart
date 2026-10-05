import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 221 gates direct admin map routes behind admin access', () {
    final source = File('lib/main.dart').readAsStringSync();

    final mapEditorRoute = RegExp(
      r'case ArcAdminMapEditorScreen\.routeName:[\s\S]{0,260}'
      r'_AdminRouteGate\([\s\S]{0,120}ArcAdminMapEditorScreen\(\)',
    );
    final iconReviewRoute = RegExp(
      r'case ArcMapFilterIconReviewScreen\.routeName:[\s\S]{0,260}'
      r'_AdminRouteGate\([\s\S]{0,120}ArcMapFilterIconReviewScreen\(\)',
    );

    expect(mapEditorRoute.hasMatch(source), isTrue);
    expect(iconReviewRoute.hasMatch(source), isTrue);
    expect(source, contains('FeatureAccess.isAdminOrDev()'));
    expect(source, contains('return const AppEntryGate();'));
    expect(
      source,
      isNot(contains('builder: (_) => const ArcAdminMapEditorScreen()')),
    );
    expect(
      source,
      isNot(contains('builder: (_) => const ArcMapFilterIconReviewScreen()')),
    );
  });
}
