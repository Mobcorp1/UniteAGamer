import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcLoadoutIntelligenceSummary extends StatelessWidget {
  const ArcLoadoutIntelligenceSummary({
    super.key,
    required this.primaryWeapon,
    required this.secondaryWeapon,
    required this.primaryAttachments,
    required this.secondaryAttachments,
    required this.equipment,
    required this.consumables,
  });

  final ArcLoadoutWeaponSpec primaryWeapon;
  final ArcLoadoutWeaponSpec secondaryWeapon;
  final List<String> primaryAttachments;
  final List<String> secondaryAttachments;
  final List<String> equipment;
  final List<String> consumables;

  int get blueprintLinkedCount {
    var count = 0;
    if (primaryWeapon.blueprintBased) count++;
    if (secondaryWeapon.blueprintBased) count++;
    count += primaryAttachments.length;
    count += secondaryAttachments.length;
    return count;
  }

  int get craftableCount {
    var count = 0;
    if (primaryWeapon.craftable) count++;
    if (secondaryWeapon.craftable) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final buildItems = <String>[
      primaryWeapon.name,
      secondaryWeapon.name,
      ...primaryAttachments,
      ...secondaryAttachments,
      ...equipment,
      ...consumables,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REAL INTELLIGENCE STATE',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the live-ready bridge between the loadout builder and your tracker systems. The next data pass can swap these readiness rows from calculated build flags to Firestore-backed ownership and trade results.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _IntelMetricRow(
            icon: Icons.inventory_2_rounded,
            label: 'Build items',
            value: '${buildItems.length} selected',
            color: AppTheme.neonCyan,
          ),
          _IntelMetricRow(
            icon: Icons.grid_view_rounded,
            label: 'Blueprint-linked',
            value: blueprintLinkedCount == 0
                ? 'None detected'
                : '$blueprintLinkedCount items need Blueprint Intel checks',
            color: AppTheme.neonPink,
          ),
          _IntelMetricRow(
            icon: Icons.build_rounded,
            label: 'Craftable weapons',
            value: craftableCount == 0
                ? 'No bench-crafted weapons selected'
                : '$craftableCount weapon${craftableCount == 1 ? '' : 's'} need bench readiness checks',
            color: Colors.amberAccent,
          ),
          _IntelMetricRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Trade readiness',
            value: blueprintLinkedCount == 0
                ? 'No trade scan needed yet'
                : 'Ready to scan missing blueprint and duplicate matches',
            color: Colors.lightGreenAccent,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IntelPill(
                label: 'Blueprint ownership pending',
                color: AppTheme.neonCyan,
              ),
              _IntelPill(
                label: 'Bench level pending',
                color: Colors.amberAccent,
              ),
              _IntelPill(label: 'Trade scan pending', color: AppTheme.neonPink),
              _IntelPill(
                label: 'Raid target ready',
                color: Colors.lightGreenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntelMetricRow extends StatelessWidget {
  const _IntelMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 11.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelPill extends StatelessWidget {
  const _IntelPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
