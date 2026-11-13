import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_responsive_policy.dart';

void main() {
  group('ArcBlueprintGridResponsivePolicy', () {
    test('shows the rotate prompt only for narrow portrait in-game view', () {
      expect(
        ArcBlueprintGridResponsivePolicy.shouldShowInGameRotatePrompt(
          width: 390,
          height: 844,
        ),
        isTrue,
      );
      expect(
        ArcBlueprintGridResponsivePolicy.shouldShowInGameRotatePrompt(
          width: 844,
          height: 390,
        ),
        isFalse,
      );
      expect(
        ArcBlueprintGridResponsivePolicy.shouldShowInGameRotatePrompt(
          width: 820,
          height: 1180,
        ),
        isFalse,
      );
    });

    test('sizes one or two search results as readable cards', () {
      final single = ArcBlueprintGridResponsivePolicy.searchLayout(
        resultCount: 1,
        width: 390,
      );
      final pairNarrow = ArcBlueprintGridResponsivePolicy.searchLayout(
        resultCount: 2,
        width: 390,
      );
      final pairWide = ArcBlueprintGridResponsivePolicy.searchLayout(
        resultCount: 2,
        width: 700,
      );

      expect(single.size, ArcBlueprintSearchResultSize.single);
      expect(single.columns, 1);
      expect(single.maxTileWidth, greaterThanOrEqualTo(390));
      expect(pairNarrow.size, ArcBlueprintSearchResultSize.pair);
      expect(pairNarrow.columns, 1);
      expect(pairWide.columns, 2);
      expect(pairWide.maxTileWidth, greaterThan(220));
    });

    test(
      'keeps compact result sets larger before returning to grid density',
      () {
        final compact = ArcBlueprintGridResponsivePolicy.searchLayout(
          resultCount: 4,
          width: 720,
        );
        final mobileGrid = ArcBlueprintGridResponsivePolicy.searchLayout(
          resultCount: 8,
          width: 390,
        );
        final desktopGrid = ArcBlueprintGridResponsivePolicy.searchLayout(
          resultCount: 8,
          width: 1200,
        );

        expect(compact.size, ArcBlueprintSearchResultSize.compactSet);
        expect(compact.columns, 2);
        expect(mobileGrid.size, ArcBlueprintSearchResultSize.grid);
        expect(mobileGrid.columns, 2);
        expect(desktopGrid.columns, 5);
      },
    );
  });
}
