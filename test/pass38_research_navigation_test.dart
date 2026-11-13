import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_research_workstation_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/research/uag_research_screen.dart';

void main() {
  test('Research Workstation uses the existing registered route', () {
    expect(
      ArcResearchWorkstationScreen.routeName,
      '/trading-hub/arc-raiders/research-workstation',
    );
  });

  test('Embedded research catalogue supports focused entry', () {
    const blueprints = UagResearchScreen(
      embedded: true,
      initialCategory: 'blueprint',
    );
    const designs = UagResearchScreen(
      embedded: true,
      initialCategory: 'design',
    );
    expect(blueprints.embedded, isTrue);
    expect(blueprints.initialCategory, 'blueprint');
    expect(designs.initialCategory, 'design');
  });
}
