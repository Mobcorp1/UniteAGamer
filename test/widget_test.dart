import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UAG Arc Raiders Hub app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const UAGTradersHubApp());

    expect(find.byType(UAGTradersHubApp), findsOneWidget);
  });
}
