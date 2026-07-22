import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_wall_of_legends_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart';

void main() {
  group('Wall of Legends models', () {
    test('only approved named entries are visible', () {
      const approved = ArcWallOfLegendsEntry(
        id: 'founder-1',
        category: ArcWallOfLegendsCategory.founders,
        displayName: 'Founder Raider',
        approved: true,
      );
      const hidden = ArcWallOfLegendsEntry(
        id: 'draft-1',
        category: ArcWallOfLegendsCategory.creators,
        displayName: 'Draft Creator',
        approved: false,
      );
      const unnamed = ArcWallOfLegendsEntry(
        id: 'unnamed-1',
        category: ArcWallOfLegendsCategory.communityHeroes,
        displayName: '',
        approved: true,
      );

      expect(approved.isVisible, isTrue);
      expect(hidden.isVisible, isFalse);
      expect(unnamed.isVisible, isFalse);
    });

    test('sorts by category, sort order and display name', () {
      const creator = ArcWallOfLegendsEntry(
        id: 'creator',
        category: ArcWallOfLegendsCategory.creators,
        displayName: 'Zed',
        approved: true,
      );
      const founderB = ArcWallOfLegendsEntry(
        id: 'founder-b',
        category: ArcWallOfLegendsCategory.founders,
        displayName: 'Bravo',
        sortOrder: 2,
        approved: true,
      );
      const founderA = ArcWallOfLegendsEntry(
        id: 'founder-a',
        category: ArcWallOfLegendsCategory.founders,
        displayName: 'Alpha',
        sortOrder: 1,
        approved: true,
      );

      final entries = <ArcWallOfLegendsEntry>[creator, founderB, founderA]
        ..sort(ArcWallOfLegendsRepository.compareEntries);

      expect(entries.map((entry) => entry.id), <String>[
        'founder-a',
        'founder-b',
        'creator',
      ]);
    });

    test('admin or dev can manage wall entries', () {
      expect(
        ArcWallOfLegendsPermissions.canManage(isAdmin: true, isDev: false),
        isTrue,
      );
      expect(
        ArcWallOfLegendsPermissions.canManage(isAdmin: false, isDev: true),
        isTrue,
      );
      expect(
        ArcWallOfLegendsPermissions.canManage(isAdmin: false, isDev: false),
        isFalse,
      );
    });
  });
}
