import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMapMarkerFilterPanel extends StatelessWidget {
  const ArcMapMarkerFilterPanel({
    required this.filters,
    required this.searchController,
    required this.onChanged,
    super.key,
  });

  final ArcRaidMapFilterState filters;
  final TextEditingController searchController;
  final ValueChanged<ArcRaidMapFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedPreset = ArcMapMarkerCatalog.matchingPreset(filters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: AppTheme.tradingInputDecoration(
            label: 'Search blueprint, POI, event, resource or marker',
          ),
          onChanged: (value) => onChanged(filters.copyWith(searchQuery: value)),
        ),
        const SizedBox(height: 12),
        Text(
          'QUICK LAYERS',
          style: AppTheme.bodyTextStyle(
            fontSize: 11,
            color: AppTheme.tradingMutedText,
            isBold: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in ArcMapMarkerCatalog.presets)
              ChoiceChip(
                selected: preset == selectedPreset,
                showCheckmark: false,
                avatar: Icon(preset.icon, size: 16),
                label: Text(preset.label),
                onSelected: (_) {
                  onChanged(
                    ArcMapMarkerCatalog.applyPreset(
                      preset,
                      searchQuery: filters.searchQuery,
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (final group in ArcMapMarkerCatalog.groups) ...[
          ExpansionTile(
            initiallyExpanded: group.id == 'objectives' || group.id == 'map',
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 10),
            leading: Icon(group.icon, color: AppTheme.neonCyan, size: 19),
            title: Text(
              group.label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white,
                isBold: true,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in group.items)
                      FilterChip(
                        avatar: Icon(item.icon, size: 15),
                        label: Text(item.label),
                        selected: item.isSelected(filters),
                        onSelected: (selected) {
                          onChanged(item.apply(filters, selected));
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () {
            searchController.clear();
            onChanged(ArcRaidMapFilterState.defaults);
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text('Reset Filters (${filters.activeCount})'),
        ),
      ],
    );
  }
}
