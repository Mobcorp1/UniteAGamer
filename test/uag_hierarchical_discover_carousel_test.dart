import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Discover UAG mirrors the drawer hierarchy with two-level carousels', () {
    final hub = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    );
    final catalog = source(
      'lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart',
    );

    expect(hub, contains('ArcCompactNavigationCatalog.groups'));
    expect(hub, contains('List<_ArcHubGroup> _buildHubGroups()'));
    expect(hub, contains("label: 'COMMUNICATIONS'"));
    expect(hub, contains("openLabel: 'OPEN GROUP'"));
    expect(hub, contains('String? _activeGroupLabel'));
    expect(hub, contains("'DISCOVER UAG  >  \$activeGroupLabel'"));
    expect(hub, contains('feature.routeName == ArcRaidersHubScreen.routeName'));

    final account = hub.indexOf("case 'ACCOUNT & UAG':");
    final discover = hub.indexOf("case 'DISCOVER & RUN':");
    final communications = hub.indexOf("case 'COMMUNICATIONS':");
    final raid = hub.indexOf("case 'RAID & INTELLIGENCE':");
    final progression = hub.indexOf("case 'PROGRESSION & TRACKING':");
    final trade = hub.indexOf("case 'TRADE & INVENTORY':");
    final squad = hub.indexOf("case 'SQUAD & COMMUNITY':");
    final improve = hub.indexOf("case 'IMPROVE':");
    final future = hub.indexOf("case 'FUTURE HUB':");

    expect(account, greaterThanOrEqualTo(0));
    expect(account, lessThan(discover));
    expect(discover, lessThan(communications));
    expect(communications, lessThan(raid));
    expect(raid, lessThan(progression));
    expect(progression, lessThan(trade));
    expect(trade, lessThan(squad));
    expect(squad, lessThan(improve));
    expect(improve, lessThan(future));

    for (final label in <String>[
      'ACCOUNT & UAG',
      'DISCOVER & RUN',
      'RAID & INTELLIGENCE',
      'PROGRESSION & TRACKING',
      'TRADE & INVENTORY',
      'SQUAD & COMMUNITY',
      'IMPROVE',
      'FUTURE HUB',
    ]) {
      expect(catalog, contains("label: '$label'"));
    }
  });
}
