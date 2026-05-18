import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintTile extends StatelessWidget {
  const BlueprintTile({
    super.key,
    required this.blueprint,
    required this.state,
    required this.landscape,
    required this.rarityColor,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState state;
  final bool landscape;
  final Color rarityColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final owned = state.owned;
    final accent = isSelected
        ? AppTheme.neonPink
        : owned
        ? rarityColor
        : Colors.redAccent.withValues(alpha: 0.55);

    return ElectricChargeBorder(
      active: isSelected,
      radius: 12,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: AppTheme.tradingCardDecoration(
            radius: 12,
            borderColor: accent.withValues(
              alpha: isSelected
                  ? 0.88
                  : owned
                  ? 0.55
                  : 0.24,
            ),
            backgroundColor: isSelected
                ? AppTheme.cardBackgroundAlt.withValues(alpha: 0.96)
                : owned
                ? AppTheme.cardBackgroundAlt
                : AppTheme.cardBackground,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              landscape ? 3 : 5,
              landscape ? 3 : 5,
              landscape ? 3 : 5,
              landscape ? 2 : 3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BlueprintTileVisual(
                    blueprint: blueprint,
                    owned: owned,
                    accent: accent,
                    state: state,
                    isSelectionMode: isSelectionMode,
                    isSelected: isSelected,
                  ),
                ),
                SizedBox(height: landscape ? 2 : 4),
                Text(
                  blueprint.name,
                  maxLines: landscape ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: landscape ? 9 : 12,
                    color: owned ? Colors.white : Colors.white70,
                  ),
                ),
                if (!landscape) ...[
                  const SizedBox(height: 2),
                  Text(
                    blueprint.rarityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueprintTileVisual extends StatelessWidget {
  const _BlueprintTileVisual({
    required this.blueprint,
    required this.owned,
    required this.accent,
    required this.state,
    required this.isSelectionMode,
    required this.isSelected,
  });

  final ArcBlueprint blueprint;
  final bool owned;
  final Color accent;
  final ArcBlueprintState state;
  final bool isSelectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final image = blueprint.imageAssetPath != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: owned
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        )
                      : const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: Image.asset(
                    blueprint.imageAssetPath!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => _placeholder(),
                  ),
                ),
                Container(
                  color: owned
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ],
            ),
          )
        : _placeholder();

    return Stack(
      children: [
        Positioned.fill(child: image),
        Positioned(
          top: 4,
          right: 4,
          child: _cornerBadge(
            icon: state.owned
                ? Icons.check_circle_rounded
                : Icons.close_rounded,
            color: state.owned ? Colors.lightGreenAccent : Colors.redAccent,
          ),
        ),
        if (state.hasDuplicates)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.68),
                ),
              ),
              child: Text(
                'x${state.dupesOwned}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (isSelectionMode)
          Positioned(
            top: 4,
            left: 4,
            child: _cornerBadge(
              icon: isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.neonPink : Colors.white54,
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Center(
        child: Icon(
          Icons.extension_rounded,
          size: 22,
          color: accent.withValues(alpha: 0.90),
        ),
      ),
    );
  }

  Widget _cornerBadge({required IconData icon, required Color color}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.78),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}
