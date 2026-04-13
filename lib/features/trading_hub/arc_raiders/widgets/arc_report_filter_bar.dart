import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_report_filters.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcReportFilterBar extends StatelessWidget {
  const ArcReportFilterBar({
    super.key,
    required this.filters,
    required this.mapOptions,
    required this.containerOptions,
    required this.conditionOptions,
    required this.onChanged,
    required this.onReset,
  });

  final ArcReportFilters filters;
  final List<String> mapOptions;
  final List<String> containerOptions;
  final List<String> conditionOptions;
  final ValueChanged<ArcReportFilters> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Report Filters',
                  style: AppTheme.tradingHeading(
                    fontSize: 20,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextField(
            controller: TextEditingController(text: filters.query)
              ..selection = TextSelection.collapsed(
                offset: filters.query.length,
              ),
            onChanged: (value) => onChanged(filters.copyWith(query: value)),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search map, POI, notes or condition',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppTheme.cardBackgroundDeep,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDropdown<String>(
                width: 220,
                value: filters.mapName,
                label: 'Map',
                items: mapOptions,
                onChanged: (value) => onChanged(
                  value == null
                      ? filters.copyWith(clearMapName: true)
                      : filters.copyWith(mapName: value),
                ),
              ),
              _buildDropdown<String>(
                width: 220,
                value: filters.containerLabel,
                label: 'Container',
                items: containerOptions,
                onChanged: (value) => onChanged(
                  value == null
                      ? filters.copyWith(clearContainerLabel: true)
                      : filters.copyWith(containerLabel: value),
                ),
              ),
              _buildDropdown<ArcRaidType>(
                width: 180,
                value: filters.raidType,
                label: 'Raid Type',
                items: ArcRaidType.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => onChanged(
                  value == null
                      ? filters.copyWith(clearRaidType: true)
                      : filters.copyWith(raidType: value),
                ),
              ),
              _buildDropdown<ArcTimeOfDay>(
                width: 180,
                value: filters.timeOfDay,
                label: 'Time of Day',
                items: ArcTimeOfDay.values,
                labelBuilder: (value) => value.label,
                onChanged: (value) => onChanged(
                  value == null
                      ? filters.copyWith(clearTimeOfDay: true)
                      : filters.copyWith(timeOfDay: value),
                ),
              ),
              _buildDropdown<String>(
                width: 220,
                value: filters.conditionLabel,
                label: 'Condition',
                items: conditionOptions,
                onChanged: (value) => onChanged(
                  value == null
                      ? filters.copyWith(clearConditionLabel: true)
                      : filters.copyWith(conditionLabel: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: filters.onlyWithNotes,
            onChanged: (value) =>
                onChanged(filters.copyWith(onlyWithNotes: value)),
            title: const Text(
              'Only show reports with location notes',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Useful when you want the most actionable intel first.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required double width,
    required T? value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T value)? labelBuilder,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: items.contains(value) ? value : null,
        onChanged: onChanged,
        dropdownColor: AppTheme.cardBackgroundDeep,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: AppTheme.cardBackgroundDeep,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        hint: Text('All $label', style: const TextStyle(color: Colors.white54)),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder?.call(item) ?? item.toString(),
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
