import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintFilterBar extends StatelessWidget {
  const BlueprintFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.counts,
    required this.selectionMode,
    this.onEnterSelectionMode,
    this.onSelectionToolSelected,
  });

  final ArcBlueprintFilter selectedFilter;
  final ValueChanged<ArcBlueprintFilter> onFilterSelected;
  final Map<ArcBlueprintFilter, int> counts;
  final bool selectionMode;
  final VoidCallback? onEnterSelectionMode;
  final ValueChanged<String>? onSelectionToolSelected;

  static const List<MapEntry<ArcBlueprintFilter, String>> _filters = [
    MapEntry(ArcBlueprintFilter.all, 'All'),
    MapEntry(ArcBlueprintFilter.owned, 'Owned'),
    MapEntry(ArcBlueprintFilter.missing, 'Missing'),
    MapEntry(ArcBlueprintFilter.duplicates, 'Dupes'),
  ];

  String _filterLabel(ArcBlueprintFilter filter) {
    final label = _filters.firstWhere((entry) => entry.key == filter).value;
    return '$label (${counts[filter] ?? 0})';
  }

  Widget _buildViewField() {
    return ElectricChargeBorder(
      active: true,
      radius: 14,
      child: DropdownButtonFormField<ArcBlueprintFilter>(
        initialValue: selectedFilter,
        decoration: AppTheme.tradingInputDecoration(label: 'View'),
        dropdownColor: AppTheme.cardBackgroundAlt,
        items: _filters
            .map(
              (entry) => DropdownMenuItem<ArcBlueprintFilter>(
                value: entry.key,
                child: Text(_filterLabel(entry.key)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) {
            onFilterSelected(value);
          }
        },
      ),
    );
  }

  Widget _buildSelectionField() {
    if (!selectionMode) {
      return OutlinedButton.icon(
        onPressed: onEnterSelectionMode,
        icon: const Icon(Icons.bolt_rounded),
        label: const Text('Select'),
      );
    }

    return ElectricChargeBorder(
      active: true,
      radius: 14,
      child: DropdownButtonFormField<String>(
        initialValue: null,
        decoration: AppTheme.tradingInputDecoration(label: 'Select'),
        dropdownColor: AppTheme.cardBackgroundAlt,
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Select all visible')),
          DropdownMenuItem(value: 'row', child: Text('Select row')),
          DropdownMenuItem(value: 'column', child: Text('Select column')),
          DropdownMenuItem(value: 'clear', child: Text('Clear selection')),
        ],
        onChanged: (value) {
          if (value != null) {
            onSelectionToolSelected?.call(value);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final viewField = _buildViewField();
        final selectionField = _buildSelectionField();

        if (compact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              viewField,
              const SizedBox(height: AppTheme.spaceM),
              selectionField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: viewField),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(child: selectionField),
          ],
        );
      },
    );
  }
}
