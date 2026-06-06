import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_loadout_cards.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FavouriteLoadoutScreen extends StatefulWidget {
  const FavouriteLoadoutScreen({super.key});

  static const routeName = '/favourite-loadout';

  @override
  State<FavouriteLoadoutScreen> createState() => _FavouriteLoadoutScreenState();
}

class _FavouriteLoadoutScreenState extends State<FavouriteLoadoutScreen> {
  ArcLoadoutCategory _selectedCategory = ArcLoadoutCategory.saved;
  ArcPlayerPlayStyle _selectedPlayStyle = ArcPlayerPlayStyle.balanced;

  List<ArcSavedLoadoutSeed> get _recommendedLoadouts {
    return ArcLoadoutSeedData.recommendedLoadouts(_selectedPlayStyle);
  }

  List<ArcSavedLoadoutSeed> get _visibleLoadouts {
    if (_selectedCategory == ArcLoadoutCategory.saved) {
      return ArcLoadoutSeedData.starterLoadouts;
    }

    return ArcLoadoutSeedData.starterLoadouts
        .where((loadout) => loadout.category == _selectedCategory)
        .toList(growable: false);
  }

  ArcLoadoutWeaponSpec _weapon(String name) {
    return ArcLoadoutSeedData.weapons.firstWhere(
      (weapon) => weapon.name == name,
      orElse: () => ArcLoadoutSeedData.weapons.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadouts = _visibleLoadouts;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Loadout'),
      appBar: AppBar(
        title: Text(
          'FAVOURITE LOADOUTS',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: ArcRaidersPageList(
              children: [
                _buildHero(),
                const SizedBox(height: 18),
                _buildPlayStyleSelector(),
                const SizedBox(height: 18),
                _buildRecommendedSection(),
                const SizedBox(height: 18),
                _buildCategoryChips(),
                const SizedBox(height: 18),
                if (loadouts.isEmpty)
                  _buildEmptyState()
                else
                  for (final loadout in loadouts) ...[
                    ArcSavedLoadoutCard(
                      loadout: loadout,
                      onTap: () => _openLoadoutPreview(loadout),
                    ),
                    const SizedBox(height: 14),
                  ],
                const SizedBox(height: 18),
                _buildBuilderFoundation(),
                const SizedBox(height: 112),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.12),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonPink.withValues(alpha: 0.13),
              border: Border.all(
                color: AppTheme.neonPink.withValues(alpha: 0.48),
              ),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.neonPink,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOADOUT INTELLIGENCE',
                  style: AppTheme.tradingHeading(
                    fontSize: 20,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build PvP, PvE and balanced setups that connect back into Blueprint Intel, bench readiness, trades and raid planning.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayStyleSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPink.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUILD AROUND YOUR PLAY STYLE',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the way you usually raid first. Meta builds and saved builds come after your own style.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in ArcPlayerPlayStyle.values)
                _PlayStyleChip(
                  label: style.shortLabel,
                  selected: _selectedPlayStyle == style,
                  onTap: () => setState(() {
                    _selectedPlayStyle = style;
                    _selectedCategory =
                        ArcLoadoutSeedData.recommendedForPlayStyle(style);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final loadouts = _recommendedLoadouts;

    if (loadouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED FOR ',
          style: AppTheme.tradingHeading(
            fontSize: 18,
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(height: 10),
        for (final loadout in loadouts) ...[
          ArcSavedLoadoutCard(
            loadout: loadout,
            onTap: () => _openLoadoutPreview(loadout),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in ArcLoadoutCategory.values)
          ArcLoadoutCategoryChip(
            category: category,
            selected: _selectedCategory == category,
            onTap: () => setState(() => _selectedCategory = category),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.25)),
      ),
      child: Text(
        'No loadouts in this category yet.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBuilderFoundation() {
    final balanced = ArcLoadoutSeedData.starterLoadouts.first;
    final primary = _weapon(balanced.primaryWeapon);
    final secondary = _weapon(balanced.secondaryWeapon);

    final cards = [
      ArcLoadoutSlotCard(
        title: 'Augment',
        value: balanced.augment,
        description:
            'First card in the builder flow. Augment choice sets the build identity.',
        icon: Icons.health_and_safety_rounded,
        accent: AppTheme.neonPink,
      ),
      ArcLoadoutSlotCard(
        title: 'Primary Weapon',
        value: primary.name,
        description: primary.role,
        icon: Icons.flash_on_rounded,
        accent: AppTheme.neonCyan,
        blueprintBased: primary.blueprintBased,
        craftable: primary.craftable,
        gunsmithLevel: primary.gunsmithLevel,
      ),
      ArcLoadoutSlotCard(
        title: 'Primary Attachments',
        value: primary.slots.isEmpty
            ? 'No attachments'
            : primary.slots.join(', '),
        description:
            'Attachment slots will use Blueprint Intel where blueprint-based options are selected.',
        icon: Icons.tune_rounded,
        accent: Colors.amberAccent,
        blueprintBased: true,
      ),
      ArcLoadoutSlotCard(
        title: 'Secondary Weapon',
        value: secondary.name,
        description: secondary.role,
        icon: Icons.bolt_rounded,
        accent: AppTheme.neonPink,
        blueprintBased: secondary.blueprintBased,
        craftable: secondary.craftable,
        gunsmithLevel: secondary.gunsmithLevel,
      ),
      ArcLoadoutSlotCard(
        title: 'Secondary Attachments',
        value: secondary.slots.isEmpty
            ? 'No attachments'
            : secondary.slots.join(', '),
        description:
            'Secondary attachment intelligence will mirror the primary weapon flow.',
        icon: Icons.settings_suggest_rounded,
        accent: Colors.lightGreenAccent,
        blueprintBased: true,
      ),
      const ArcLoadoutSlotCard(
        title: 'Equipment',
        value: 'Shield Level 2 / Snap Hook',
        description:
            'Equipment cards track craftable, owned and missing states.',
        icon: Icons.shield_rounded,
        accent: Colors.cyanAccent,
        craftable: true,
      ),
      const ArcLoadoutSlotCard(
        title: 'Consumables',
        value: 'Vita Shot / Lure Grenade',
        description:
            'Consumables stay lightweight and focused on combat-readiness.',
        icon: Icons.medical_services_rounded,
        accent: Colors.lightGreenAccent,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUILDER FLOW',
          style: AppTheme.tradingHeading(
            fontSize: 19,
            color: AppTheme.neonPink,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }

  void _openLoadoutPreview(ArcSavedLoadoutSeed loadout) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final primary = _weapon(loadout.primaryWeapon);
        final secondary = _weapon(loadout.secondaryWeapon);

        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.38),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loadout.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTheme.tradingHeading(
                  fontSize: 24,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 14),
              _PreviewRow(label: 'Augment', value: loadout.augment),
              _PreviewRow(
                label: 'Primary',
                value: '${primary.name} — ${primary.category}',
              ),
              _PreviewRow(
                label: 'Secondary',
                value: '${secondary.name} — ${secondary.category}',
              ),
              _PreviewRow(
                label: 'Equipment',
                value: loadout.equipment.join(', '),
              ),
              _PreviewRow(
                label: 'Consumables',
                value: loadout.consumables.join(', '),
              ),
              const SizedBox(height: 14),
              Text(
                'Blueprint Intel, Bench Readiness, Trade Assist and Raid Planner actions will hook into this preview in the next passes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayStyleChip extends StatelessWidget {
  const _PlayStyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.18 : 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.75 : 0.34),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.neonPink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.84),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
