import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcAssetThumbnail extends StatelessWidget {
  const ArcAssetThumbnail({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.color = AppTheme.neonCyan,
    this.size = 42,
    this.fit = BoxFit.cover,
    this.padding = 3,
    this.borderRadius,
    this.showGlow = true,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final Color color;
  final double size;
  final BoxFit fit;
  final double padding;
  final BorderRadius? borderRadius;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.72)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.20),
        child: Image.asset(
          assetPath,
          fit: fit,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              Icon(fallbackIcon, color: color, size: size * 0.52),
        ),
      ),
    );
  }
}

class ArcItemAssetResolver {
  const ArcItemAssetResolver._();

  static String itemPath(String itemName) {
    return 'assets/arc_raiders/items/${slug(itemName)}.webp';
  }

  static String slug(String itemName) {
    final key = itemName.trim().toLowerCase();

    const overrides = <String, String>{
      'queen reactor': 'queen_reactor',
      'queen reactors': 'queen_reactor',
      'matriarch reactor': 'matriarch_reactor',
      'matriarch reactors': 'matriarch_reactor',
      'bombardier cell': 'bombardier_cells',
      'bombardier cells': 'bombardier_cells',
      'assessor matrix': 'assessor_matrix',
      'assessor matrices': 'assessor_matrix',
      'turbine compressor': 'turbine_compressor',
      'turbine compressors': 'turbine_compressor',
      'leaper pulse unit': 'leaper_pulse_unit',
      'leaper pulse units': 'leaper_pulse_unit',
      'bastion cell': 'bastion_cell',
      'bastion cells': 'bastion_cell',
      'vaporizer regulator': 'vaporizer_regulator',
      'vaporizer regulators': 'vaporizer_regulator',
      'rocketeer driver': 'rocketeer_driver',
      'rocketeer drivers': 'rocketeer_driver',
      'stash expansion': 'stash_expansion',
      'expedition vault': 'expedition_vault',
      'backpack charm': 'backpack_charm',
      'pack charm': 'backpack_charm',
      'raider token': 'raider_tokens',
      'raider tokens': 'raider_tokens',
      'raiders token': 'raider_tokens',
      'raiders tokens': 'raider_tokens',
      'cosmetic': 'cosmetics',
      'cosmetics': 'cosmetics',
      'emote': 'emotes',
      'emotes': 'emotes',
      'quick use': 'quick_use',
      'recyclable': 'recyclable',
      'recyclables': 'recyclable',
      'blueprint': 'blueprint',
      'blueprints': 'blueprint',
      'duplicate blueprint': 'blueprint',
      'duplicate blueprints': 'blueprint',
      'train model': 'train_model',
      'train models': 'train_model',
      'trade model': 'train_model',
      'vintage steering wheel': 'vintage_steering_wheel',
      'industrial magnet': 'industrial_magnet',
      'industrial magnets': 'industrial_magnet',
      'number plate': 'number_plate',
      'number plates': 'number_plate',
      'air freshener': 'air_freshener',
      'air fresheners': 'air_freshener',
      'arc coolant': 'arc_coolant',
      'arc coolants': 'arc_coolant',
      'arc synthetic resin': 'arc_synthetic_resin',
      'arc thermo lining': 'arc_thermo_lining',
      'arc thermal lining': 'arc_thermo_lining',
      'arc performance steel': 'arc_performance_steel',
    };

    final override = overrides[key];
    if (override != null) return override;

    return key
        .replaceAll('&', 'and')
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+'), '')
        .replaceAll(RegExp(r'_+$'), '');
  }
}
