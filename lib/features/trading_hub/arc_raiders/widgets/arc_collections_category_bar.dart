import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;

enum ArcCollectionsCategory { blueprints, stencils, designs }

/// Compact and consistent category navigation for all saved collection grids.
/// This widget does not alter any Blueprint grid, state or tile logic.
class ArcCollectionsCategoryBar extends StatelessWidget {
  const ArcCollectionsCategoryBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showDupes = false,
    this.dupesSelected = false,
    this.onDupesSelected,
  });

  final ArcCollectionsCategory selected;
  final ValueChanged<ArcCollectionsCategory> onSelected;
  final bool showDupes;
  final bool dupesSelected;
  final VoidCallback? onDupesSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: uag_pass14_theme.AppTheme.cardBackgroundDeep.withValues(alpha: 0.90),
        border: Border(bottom: BorderSide(
          color: uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.28), width: 0.8)),
      ),
      child: Row(
        children: [
          for (final category in ArcCollectionsCategory.values) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Material(
                  color: selected == category && !dupesSelected
                      ? uag_pass14_theme.AppTheme.cardBackgroundAlt
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    key: Key('collections-tab-${category.name}'),
                    borderRadius: BorderRadius.circular(5),
                    onTap: () => onSelected(category),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: selected == category && !dupesSelected
                              ? uag_pass14_theme.AppTheme.neonCyan
                              : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.24),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          category.name.toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: selected == category && !dupesSelected
                                ? uag_pass14_theme.AppTheme.neonCyan
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (showDupes && selected == category) Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Material(
                  color: dupesSelected ? uag_pass14_theme.AppTheme.neonPink.withValues(alpha: 0.17) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    key: const Key('collections-tab-dupes'),
                    onTap: onDupesSelected,
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: dupesSelected
                          ? uag_pass14_theme.AppTheme.neonPink : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.24)),
                      ),
                      child: const FittedBox(fit: BoxFit.scaleDown,
                        child: Text('DUPES', maxLines: 1,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                            letterSpacing: 0.7, color: uag_pass14_theme.AppTheme.neonPink)),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ],
        ],
      ),
    );
  }
}
