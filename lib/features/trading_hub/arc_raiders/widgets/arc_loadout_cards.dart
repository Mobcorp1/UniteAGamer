import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcLoadoutCategoryChip extends StatelessWidget {
  const ArcLoadoutCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ArcLoadoutCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.neonPink : AppTheme.neonCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.78 : 0.38),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          category.shortLabel.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class ArcSavedLoadoutCard extends StatelessWidget {
  const ArcSavedLoadoutCard({
    super.key,
    required this.loadout,
    required this.onTap,
  });

  final ArcSavedLoadoutSeed loadout;
  final VoidCallback onTap;

  Color get _accent {
    switch (loadout.category) {
      case ArcLoadoutCategory.saved:
        return AppTheme.neonCyan;
      case ArcLoadoutCategory.meta:
        return Colors.amberAccent;
      case ArcLoadoutCategory.pvp:
        return AppTheme.neonPink;
      case ArcLoadoutCategory.pve:
        return Colors.lightGreenAccent;
      case ArcLoadoutCategory.balanced:
        return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.13),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: accent, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loadout.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  loadout.category.shortLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              loadout.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LoadoutPill(
                  label: loadout.augment,
                  icon: Icons.health_and_safety_rounded,
                  color: accent,
                ),
                _LoadoutPill(
                  label: loadout.primaryWeapon,
                  icon: Icons.flash_on_rounded,
                  color: AppTheme.neonCyan,
                ),
                _LoadoutPill(
                  label: loadout.secondaryWeapon,
                  icon: Icons.bolt_rounded,
                  color: AppTheme.neonPink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ArcLoadoutSlotCard extends StatelessWidget {
  const ArcLoadoutSlotCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.accent,
    this.blueprintBased = false,
    this.craftable = false,
    this.gunsmithLevel,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color accent;
  final bool blueprintBased;
  final bool craftable;
  final int? gunsmithLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              height: 1.32,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (blueprintBased)
                _LoadoutPill(
                  label: 'Blueprint Intel',
                  icon: Icons.grid_view_rounded,
                  color: AppTheme.neonCyan,
                ),
              if (craftable)
                _LoadoutPill(
                  label: gunsmithLevel == null
                      ? 'Craftable'
                      : 'Gunsmith L$gunsmithLevel',
                  icon: Icons.build_rounded,
                  color: Colors.amberAccent,
                ),
              _LoadoutPill(
                label: 'Trade Hook',
                icon: Icons.swap_horiz_rounded,
                color: AppTheme.neonPink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadoutPill extends StatelessWidget {
  const _LoadoutPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
