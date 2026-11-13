import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Blueprint Intel player card never renders evidence sourceReference', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_intel_card.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('e.sourceReference')));
    expect(source, contains("community_research_seed"));
  });
}
