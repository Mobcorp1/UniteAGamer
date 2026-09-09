import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/uag_avatar_catalog.dart';

void main() {
  test('avatar catalog exposes exactly 24 stable preset avatars', () {
    expect(UagAvatarCatalog.options, hasLength(24));
    expect(
      UagAvatarCatalog.options.map((item) => item.id).toSet(),
      hasLength(24),
    );
    expect(UagAvatarCatalog.byId('missing').id, UagAvatarCatalog.defaultId);
    expect(
      UagAvatarCatalog.options.every(
        (item) => item.assetPath.endsWith('.webp'),
      ),
      isTrue,
    );
  });
}
