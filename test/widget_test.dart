// Basic widget test for UAG ARC Raiders Hub.
//
// This test just verifies that the root app widget builds.

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_traders_hub/main.dart';

void main() {
  testWidgets('UAG ARC Raiders Hub app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const UAGTradersHubApp());
    expect(find.byType(UAGTradersHubApp), findsOneWidget);
  });
}
