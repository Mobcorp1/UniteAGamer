import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'drawer puts live Raider identity at top and orders groups logically',
    () {
      final drawer = source('lib/build/app_drawer.dart');
      final avatarCatalog = source(
        'lib/features/trading_hub/arc_raiders/data/uag_avatar_catalog.dart',
      );

      expect(
        drawer,
        contains('ArcTraderProfileRepository _traderProfileRepository'),
      );
      expect(
        drawer,
        contains('_buildDrawerProfileHeader(context, dynamicColor, user)'),
      );
      expect(drawer, contains('UagAvatarCatalog.contains(avatarId)'));
      expect(drawer, contains('UagAvatarCatalog.byId(avatarId).assetPath'));
      expect(drawer, contains('profile?.avatarType'));
      expect(drawer, contains('profile?.uagName'));
      expect(drawer, contains('profile?.uagId'));
      expect(drawer, isNot(contains('_buildDrawerStatusFooter')));

      expect(
        drawer.indexOf("case 'ACCOUNT & UAG':"),
        lessThan(drawer.indexOf("case 'DISCOVER & RUN':")),
      );
      expect(
        drawer.indexOf("case 'DISCOVER & RUN':"),
        lessThan(drawer.indexOf("case 'RAID & INTELLIGENCE':")),
      );
      expect(
        drawer.indexOf("case 'RAID & INTELLIGENCE':"),
        lessThan(drawer.indexOf("case 'PROGRESSION & TRACKING':")),
      );
      expect(
        drawer.indexOf("case 'PROGRESSION & TRACKING':"),
        lessThan(drawer.indexOf("case 'TRADE & INVENTORY':")),
      );
      expect(
        drawer.indexOf("case 'TRADE & INVENTORY':"),
        lessThan(drawer.indexOf("case 'SQUAD & COMMUNITY':")),
      );
      expect(
        drawer.indexOf("case 'SQUAD & COMMUNITY':"),
        lessThan(drawer.indexOf("case 'IMPROVE':")),
      );
      expect(
        drawer.indexOf("case 'IMPROVE':"),
        lessThan(drawer.indexOf("case 'FUTURE HUB':")),
      );

      expect(drawer, contains("label: 'COMMUNICATIONS'"));
      expect(drawer, contains("label: 'ADMIN'"));
      expect(drawer, contains(").copyWith(fontSize: 12),"));

      expect(
        avatarCatalog,
        contains(
          "String get assetPath => 'assets/uag/avatars/uag_avatar_\$id.webp';",
        ),
      );
      expect(
        File('assets/uag/avatars/uag_avatar_shadow.webp').existsSync(),
        isTrue,
      );
    },
  );
}
