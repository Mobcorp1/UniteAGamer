import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UAG Arc Raiders Hub app builds in test mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UAGTradersHubApp(testMode: true));

    expect(find.byType(UAGTradersHubApp), findsOneWidget);
  });
}
