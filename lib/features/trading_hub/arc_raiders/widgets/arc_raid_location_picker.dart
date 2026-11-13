import 'package:flutter/material.dart';
import '../models/arc_raid_intelligence_models.dart';
import 'foundation/arc_ui_tokens.dart';

/// Keeps a saved identity visible while asynchronous map records are reconciled.
/// Missing locations cannot be selected or silently replaced by another exit.
class ArcRaidLocationPicker extends StatelessWidget {
  const ArcRaidLocationPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<ArcRaidRouteStop> options;
  final ArcRaidRouteStop? selected;
  final ValueChanged<ArcRaidRouteStop> onChanged;

  @override
  Widget build(BuildContext context) {
    final unique = <String, ArcRaidRouteStop>{};
    for (final option in options) {
      unique.putIfAbsent(option.id, () => option);
    }
    final selectedId = selected?.id;
    final missing = selectedId != null && !unique.containsKey(selectedId);
    return DropdownButtonFormField<String>(
      // FormField retains its own value. Reset that state when a persisted
      // selection changes, including switching between hatch and standard exit.
      key: ValueKey((label, selectedId, missing)),
      initialValue: selectedId,
      isExpanded: true,
      dropdownColor: ArcUiTokens.surfaceOverlay,
      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
      iconEnabledColor: ArcUiTokens.primaryAccent,
      decoration: ArcUiTokens.inputDecoration(labelText: label),
      items: [
        if (missing)
          DropdownMenuItem(
            value: selectedId,
            enabled: false,
            child: const Text(
              'Saved location unavailable — choose another',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        for (final option in unique.values)
          DropdownMenuItem(
            value: option.id,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        final option = unique[id];
        if (option != null) onChanged(option);
      },
    );
  }
}
