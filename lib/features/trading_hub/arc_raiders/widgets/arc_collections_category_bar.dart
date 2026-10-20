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
      decoration: const BoxDecoration(
        color: Color(0xDD08151D),
        border: Border(bottom: BorderSide(color: Color(0xFF21606E), width: 0.8)),
      ),
      child: Row(
        children: [
          for (final category in ArcCollectionsCategory.values) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Material(
                  color: selected == category && !dupesSelected
                      ? const Color(0xFF123D4D)
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
                              ? const Color(0xFF33DCE8)
                              : const Color(0xFF32515A),
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
                                ? const Color(0xFF65F4F7)
                                : const Color(0xFFCEDDE1),
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
                  color: dupesSelected ? const Color(0xFF563048) : Colors.transparent,
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
                          ? uag_pass14_theme.AppTheme.neonPink : const Color(0xFF32515A)),
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
