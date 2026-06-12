import 'package:flutter/material.dart';
import '../widgets/arc_loadout_category_banner.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_loadout_cards.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_loadout_intelligence_summary.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FavouriteLoadoutScreen extends StatefulWidget {
  const FavouriteLoadoutScreen({super.key});

  static const routeName = '/favourite-loadout';

  @override
  State<FavouriteLoadoutScreen> createState() => _FavouriteLoadoutScreenState();
}

class _FavouriteLoadoutScreenState extends State<FavouriteLoadoutScreen> {
  final ArcSavedLoadoutRepository _savedLoadoutRepository =
      ArcSavedLoadoutRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  ArcLoadoutCategory _selectedCategory = ArcLoadoutCategory.saved;
  ArcPlayerPlayStyle _selectedPlayStyle = ArcPlayerPlayStyle.balanced;
  int _builderStepIndex = 0;
  final String _selectedAugment = 'Survivor';
  final String _selectedPrimaryWeapon = 'Anvil';
  final String _selectedSecondaryWeapon = 'Stitcher';
  final List<String> _selectedPrimaryAttachments = <String>[
    'Muzzle',
    'Tech Mod',
  ];
  final List<String> _selectedSecondaryAttachments = <String>[
    'Muzzle',
    'Underbarrel',
    'Stock',
  ];
  final List<String> _selectedEquipment = <String>[
    'Shield Level 2',
    'Snap Hook',
  ];
  final List<String> _selectedConsumables = <String>[
    'Vita Shot',
    'Lure Grenade',
  ];

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

  String _normaliseBlueprintName(String name) {
    return name.trim().toLowerCase();
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
          'Loadout Command Centre',
          style: AppTheme.tradingHeading(
            fontSize: 22,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: Column(
              children: const [
                ArcLoadoutCategoryBanner(
                  title: 'PvP Operator Builds',
                  subtitle:
                      'Close-range aggression, survival pressure and fast engagement loadouts.',
                  color: AppTheme.neonPink,
                  icon: Icons.flash_on_rounded,
                ),
                ArcLoadoutCategoryBanner(
                  title: 'PvE Raid Builds',
                  subtitle:
                      'ARC clearing, sustain, ammo efficiency and long-session preparation.',
                  color: AppTheme.neonCyan,
                  icon: Icons.shield_rounded,
                ),
              ],
            ),
          ),
          SafeArea(
            child: ArcRaidersPageList(
              children: [
                _buildCinematicLoadoutHero(),
                const SizedBox(height: 12),
                _buildExpeditionResetFocusCard(),
                const SizedBox(height: 12),
                _buildLoadoutCommandCards(),
                const SizedBox(height: 12),
                _buildPlayStyleSelector(),
                const SizedBox(height: 12),
                _buildRecommendedSection(),
                const SizedBox(height: 12),
                _buildCategoryChips(),
                const SizedBox(height: 12),
                _buildSavedLoadoutsSection(),
                const SizedBox(height: 12),
                if (loadouts.isEmpty)
                  _buildEmptyState()
                else
                  for (final loadout in loadouts) ...[
                    ArcSavedLoadoutCard(
                      loadout: loadout,
                      onTap: () => _openLoadoutPreview(loadout),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 12),
                _buildGuidedBuilder(),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicLoadoutHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
            const Color(0xFF101827).withValues(alpha: 0.96),
            const Color(0xFF07111B).withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TACTICAL LOADOUT COMMAND',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cinematic ARC Raiders build intelligence system',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpeditionResetFocusCard() {
    final focusItems = <_ResetFocusItem>[
      const _ResetFocusItem(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Push quests first',
        body:
            'Quest chains move progression forward and can award blueprints, items and XP without extra tracking.',
        color: AppTheme.neonCyan,
      ),
      const _ResetFocusItem(
        icon: Icons.inventory_2_rounded,
        title: 'Secure your favourite loadout',
        body:
            'Build one reliable kit before chasing PvP, PvE, balanced or meta variants.',
        color: AppTheme.neonPink,
      ),
      const _ResetFocusItem(
        icon: Icons.precision_manufacturing_rounded,
        title: 'Upgrade benches early',
        body:
            'Loot consistently so resources feed bench upgrades, future crafts and stronger raid options.',
        color: Colors.amberAccent,
      ),
      const _ResetFocusItem(
        icon: Icons.radar_rounded,
        title: 'Loot first, fight when ready',
        body:
            'Kill ARC when the weapons support it. If not, extract value and keep the raids efficient.',
        color: Colors.lightGreenAccent,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.30)),
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonCyan.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.38),
                  ),
                ),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPEDITION RESET FOCUS',
                      style: AppTheme.tradingHeading(
                        fontSize: 18,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'After a wipe, avoid admin. Follow the route that gets raids efficient fastest.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 680;
              if (useGrid) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in focusItems)
                      SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: _ResetFocusTile(item: item),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  for (final item in focusItems) ...[
                    _ResetFocusTile(item: item),
                    if (item != focusItems.last) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadoutCommandCards() {
    final buildCards = <_BuildCommandCardData>[
      _BuildCommandCardData(
        title: 'My Favourite Loadout',
        subtitle: 'Primary personal build',
        body:
            'Finish this first. Extra PvP, PvE, balanced and meta cards make more sense once your core kit is set.',
        icon: Icons.star_rounded,
        accent: AppTheme.neonCyan,
        complete: true,
        onTap: () =>
            setState(() => _selectedCategory = ArcLoadoutCategory.saved),
      ),
      _BuildCommandCardData(
        title: 'Add PvP Build',
        subtitle: 'Raider pressure setup',
        body: 'Create after your favourite loadout is ready.',
        icon: Icons.flash_on_rounded,
        accent: AppTheme.neonPink,
        onTap: () => setState(() => _selectedCategory = ArcLoadoutCategory.pvp),
      ),
      _BuildCommandCardData(
        title: 'Add PvE Build',
        subtitle: 'ARC clearing setup',
        body: 'Focus sustain, ARC damage and extraction safety.',
        icon: Icons.shield_rounded,
        accent: Colors.lightGreenAccent,
        onTap: () => setState(() => _selectedCategory = ArcLoadoutCategory.pve),
      ),
      _BuildCommandCardData(
        title: 'Add Balanced Build',
        subtitle: 'PvP/PvE hybrid',
        body: 'Good for mixed raids where raiders and ARC are both likely.',
        icon: Icons.balance_rounded,
        accent: Colors.cyanAccent,
        onTap: () =>
            setState(() => _selectedCategory = ArcLoadoutCategory.balanced),
      ),
      _BuildCommandCardData(
        title: 'Add Meta Build',
        subtitle: 'Community-proven kit',
        body:
            'Use later for high-confidence setups and creator/community builds.',
        icon: Icons.workspace_premium_rounded,
        accent: Colors.amberAccent,
        onTap: () =>
            setState(() => _selectedCategory = ArcLoadoutCategory.meta),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUILD SLOTS',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start with your favourite loadout. Add specialist cards once the main build is complete.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: buildCards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 238,
                  child: _BuildCommandCard(data: buildCards[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
        borderRadius: BorderRadius.circular(22),
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
              fontSize: 17,
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
            fontSize: 17,
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(height: 10),
        for (final loadout in loadouts) ...[
          ArcSavedLoadoutCard(
            loadout: loadout,
            onTap: () => _openLoadoutPreview(loadout),
          ),
          const SizedBox(height: 10),
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

  Widget _buildGuidedBuilder() {
    final steps = <_BuilderStep>[
      _BuilderStep(
        title: 'Augment',
        value: _selectedAugment,
        description:
            'Sets the identity of the build before weapons and equipment.',
        icon: Icons.health_and_safety_rounded,
        accent: AppTheme.neonPink,
      ),
      _BuilderStep(
        title: 'Primary Weapon',
        value: _selectedPrimaryWeapon,
        description: _weapon(_selectedPrimaryWeapon).role,
        icon: Icons.flash_on_rounded,
        accent: AppTheme.neonCyan,
        blueprintBased: _weapon(_selectedPrimaryWeapon).blueprintBased,
        craftable: _weapon(_selectedPrimaryWeapon).craftable,
        gunsmithLevel: _weapon(_selectedPrimaryWeapon).gunsmithLevel,
      ),
      _BuilderStep(
        title: 'Primary Attachments',
        value: _selectedPrimaryAttachments.join(', '),
        description:
            'Attachment slots will connect to Blueprint Intel and missing blueprint tracking.',
        icon: Icons.tune_rounded,
        accent: Colors.amberAccent,
        blueprintBased: true,
      ),
      _BuilderStep(
        title: 'Secondary Weapon',
        value: _selectedSecondaryWeapon,
        description: _weapon(_selectedSecondaryWeapon).role,
        icon: Icons.bolt_rounded,
        accent: AppTheme.neonPink,
        blueprintBased: _weapon(_selectedSecondaryWeapon).blueprintBased,
        craftable: _weapon(_selectedSecondaryWeapon).craftable,
        gunsmithLevel: _weapon(_selectedSecondaryWeapon).gunsmithLevel,
      ),
      _BuilderStep(
        title: 'Secondary Attachments',
        value: _selectedSecondaryAttachments.join(', '),
        description:
            'Secondary attachment slots mirror primary Blueprint Intel behaviour.',
        icon: Icons.settings_suggest_rounded,
        accent: Colors.lightGreenAccent,
        blueprintBased: true,
      ),
      _BuilderStep(
        title: 'Equipment',
        value: _selectedEquipment.join(', '),
        description:
            'Equipment checks craftable and missing states without ammo or safe-pocket clutter.',
        icon: Icons.shield_rounded,
        accent: Colors.cyanAccent,
        craftable: true,
      ),
      _BuilderStep(
        title: 'Consumables',
        value: _selectedConsumables.join(', '),
        description:
            'Lightweight combat-readiness choices for the finished build.',
        icon: Icons.medical_services_rounded,
        accent: Colors.lightGreenAccent,
      ),
      const _BuilderStep(
        title: 'Final Preview',
        value: 'Ready to Review',
        description: 'Review the full ARC-style loadout summary before saving.',
        icon: Icons.dashboard_customize_rounded,
        accent: AppTheme.neonCyan,
      ),
    ];

    final active = steps[_builderStepIndex.clamp(0, steps.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GUIDED BUILDER',
          style: AppTheme.tradingHeading(
            fontSize: 19,
            color: AppTheme.neonPink,
          ),
        ),
        const SizedBox(height: 10),
        _buildBuilderProgress(steps),
        const SizedBox(height: 10),
        SizedBox(
          height: 272,
          child: PageView.builder(
            controller: PageController(
              initialPage: _builderStepIndex,
              viewportFraction: 0.86,
            ),
            itemCount: steps.length,
            onPageChanged: (index) => setState(() => _builderStepIndex = index),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ArcLoadoutSlotCard(
                  title: step.title,
                  value: step.value,
                  description: step.description,
                  icon: step.icon,
                  accent: step.accent,
                  blueprintBased: step.blueprintBased,
                  craftable: step.craftable,
                  gunsmithLevel: step.gunsmithLevel,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildBuilderActions(steps, active),
        const SizedBox(height: 12),
        _buildCinematicPreviewDial(),
        const SizedBox(height: 12),
        _buildFinalLoadoutPanel(),
        const SizedBox(height: 12),
        _buildSaveCurrentLoadoutButton(),
        const SizedBox(height: 12),
        _buildIntelligencePanel(),
        const SizedBox(height: 12),
        _buildRealIntelligenceState(),
      ],
    );
  }

  Widget _buildBuilderProgress(List<_BuilderStep> steps) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: AppTheme.fastAnimation,
                height: 7,
                decoration: BoxDecoration(
                  color: index <= _builderStepIndex
                      ? AppTheme.neonPink
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: index <= _builderStepIndex
                      ? [
                          BoxShadow(
                            color: AppTheme.neonPink.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            if (index != steps.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildBuilderActions(List<_BuilderStep> steps, _BuilderStep active) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _builderStepIndex == 0
                ? null
                : () => setState(() => _builderStepIndex--),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonCyan,
              side: BorderSide(
                color: AppTheme.neonCyan.withValues(alpha: 0.44),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _builderStepIndex >= steps.length - 1
                ? () => _showCurrentBuildPreview()
                : () => setState(() => _builderStepIndex++),
            icon: Icon(
              _builderStepIndex >= steps.length - 1
                  ? Icons.visibility_rounded
                  : Icons.chevron_right_rounded,
            ),
            label: Text(
              _builderStepIndex >= steps.length - 1 ? 'Preview' : 'Next',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonPink,
              side: BorderSide(
                color: AppTheme.neonPink.withValues(alpha: 0.52),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCinematicPreviewDial() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.95),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Text(
            'LIVE BUILD RADAR',
            style: AppTheme.tradingHeading(
              fontSize: 17,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  child: _DialNode(
                    label: _selectedPrimaryWeapon,
                    color: AppTheme.neonCyan,
                  ),
                ),
                Positioned(
                  bottom: 24,
                  child: _DialNode(
                    label: _selectedSecondaryWeapon,
                    color: AppTheme.neonPink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalLoadoutPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
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
            'LIVE LOADOUT PREVIEW',
            style: AppTheme.tradingHeading(
              fontSize: 17,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 12),
          _PreviewRow(label: 'Augment', value: _selectedAugment),
          _PreviewRow(label: 'Primary', value: _selectedPrimaryWeapon),
          _PreviewRow(
            label: 'Primary Mods',
            value: _selectedPrimaryAttachments.join(', '),
          ),
          _PreviewRow(label: 'Secondary', value: _selectedSecondaryWeapon),
          _PreviewRow(
            label: 'Secondary Mods',
            value: _selectedSecondaryAttachments.join(', '),
          ),
          _PreviewRow(label: 'Equipment', value: _selectedEquipment.join(', ')),
          _PreviewRow(
            label: 'Consumables',
            value: _selectedConsumables.join(', '),
          ),
          const SizedBox(height: 10),
          Text(
            'Next pass wires Blueprint Intel, bench readiness, trade hooks and raid planner actions into this preview.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveCurrentLoadoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saveCurrentLoadout,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Save Current Loadout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.neonCyan,
          side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.46)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Future<void> _saveCurrentLoadout() async {
    final now = DateTime.now();
    final loadout = ArcSavedLoadout(
      id: 'loadout_',
      name: ' Custom Build',
      category: ArcLoadoutCategory.saved,
      playStyle: _selectedPlayStyle,
      augment: _selectedAugment,
      primaryWeapon: _selectedPrimaryWeapon,
      primaryAttachments: _selectedPrimaryAttachments,
      secondaryWeapon: _selectedSecondaryWeapon,
      secondaryAttachments: _selectedSecondaryAttachments,
      equipment: _selectedEquipment,
      consumables: _selectedConsumables,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _savedLoadoutRepository.saveLoadout(loadout);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loadout saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save loadout: ')));
    }
  }

  void _showCurrentBuildPreview() {
    final loadout = ArcSavedLoadoutSeed(
      name: ' Custom Build',
      category: ArcLoadoutSeedData.recommendedForPlayStyle(_selectedPlayStyle),
      description: 'Custom build generated around .',
      augment: _selectedAugment,
      primaryWeapon: _selectedPrimaryWeapon,
      secondaryWeapon: _selectedSecondaryWeapon,
      equipment: _selectedEquipment,
      consumables: _selectedConsumables,
    );

    _openLoadoutPreview(loadout);
  }

  Widget _buildIntelligencePanel() {
    final primary = _weapon(_selectedPrimaryWeapon);
    final secondary = _weapon(_selectedSecondaryWeapon);
    final blueprintItems = <String>[
      if (primary.blueprintBased) primary.name,
      if (secondary.blueprintBased) secondary.name,
      ..._selectedPrimaryAttachments,
      ..._selectedSecondaryAttachments,
    ];

    final craftableItems = <ArcLoadoutWeaponSpec>[
      if (primary.craftable) primary,
      if (secondary.craftable) secondary,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.34)),
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
            'BUILD INTELLIGENCE',
            style: AppTheme.tradingHeading(
              fontSize: 17,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This build now links into Blueprint Intel, Trade Assist, Raid Planner and bench readiness.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _LoadoutIntelRow(
            icon: Icons.grid_view_rounded,
            title: 'Blueprint Intel',
            value: blueprintItems.isEmpty
                ? 'No blueprint-based picks detected yet'
                : ' blueprint-linked picks',
            color: AppTheme.neonCyan,
            onTap: () =>
                Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
          ),
          _LoadoutIntelRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Trade Assist',
            value:
                'Surface missing blueprint and duplicate trade opportunities',
            color: AppTheme.neonPink,
            onTap: () =>
                Navigator.of(context).pushNamed(TraderHubScreen.routeName),
          ),
          _LoadoutIntelRow(
            icon: Icons.route_rounded,
            title: 'Raid Planner',
            value: 'Add missing build pieces as raid objectives',
            color: Colors.amberAccent,
            onTap: () =>
                Navigator.of(context).pushNamed(RaidPlannerScreen.routeName),
          ),
          _LoadoutIntelRow(
            icon: Icons.radar_rounded,
            title: 'Community Intel',
            value: 'Check where build items are being found',
            color: Colors.lightGreenAccent,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ArcMarketIntelligenceScreen.routeName),
          ),
          if (craftableItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'CRAFTING READINESS',
              style: AppTheme.tradingHeading(
                fontSize: 15,
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(height: 8),
            for (final weapon in craftableItems)
              _CraftingReadinessCard(weapon: weapon),
          ],
        ],
      ),
    );
  }

  Widget _buildRealIntelligenceState() {
    return StreamBuilder(
      stream: _blueprintRepository.watchMyBlueprintStates(),
      builder: (context, snapshot) {
        final states = snapshot.data ?? const {};

        final ownedNames = <String>{};
        final duplicateNames = <String>{};

        for (final entry in states.entries) {
          final state = entry.value;
          final key = _normaliseBlueprintName(entry.key);
          if (state.owned) {
            ownedNames.add(key);
          }
          if (state.hasDuplicates) {
            duplicateNames.add(key);
          }
        }

        return ArcLoadoutIntelligenceSummary(
          primaryWeapon: _weapon(_selectedPrimaryWeapon),
          secondaryWeapon: _weapon(_selectedSecondaryWeapon),
          primaryAttachments: _selectedPrimaryAttachments,
          secondaryAttachments: _selectedSecondaryAttachments,
          equipment: _selectedEquipment,
          consumables: _selectedConsumables,
          ownedBlueprintNames: ownedNames,
          duplicateBlueprintNames: duplicateNames,
          onOpenBlueprintIntel: () =>
              Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
          onOpenTradeAssist: () =>
              Navigator.of(context).pushNamed(TraderHubScreen.routeName),
          onOpenRaidPlanner: () =>
              Navigator.of(context).pushNamed(RaidPlannerScreen.routeName),
          onOpenCommunityIntel: () => Navigator.of(
            context,
          ).pushNamed(ArcMarketIntelligenceScreen.routeName),
        );
      },
    );
  }

  Widget _buildSavedLoadoutsSection() {
    return StreamBuilder<List<ArcSavedLoadout>>(
      stream: _savedLoadoutRepository.watchSavedLoadouts(),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? const <ArcSavedLoadout>[];

        if (saved.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED LOADOUTS',
                  style: AppTheme.tradingHeading(
                    fontSize: 17,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No custom loadouts saved yet. Build one below, then save it here.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAVED LOADOUTS',
              style: AppTheme.tradingHeading(
                fontSize: 17,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: 10),
            for (final loadout in saved) ...[
              _SavedLoadoutManagementCard(
                loadout: loadout,
                onOpen: () => _openSavedLoadoutPreview(loadout),
                onDelete: () => _deleteSavedLoadout(loadout),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Future<void> _deleteSavedLoadout(ArcSavedLoadout loadout) async {
    try {
      await _savedLoadoutRepository.deleteLoadout(loadout.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(' deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete loadout: ')));
    }
  }

  void _openSavedLoadoutPreview(ArcSavedLoadout saved) {
    final loadout = ArcSavedLoadoutSeed(
      name: saved.name,
      category: saved.category,
      description: 'Saved custom build for .',
      augment: saved.augment,
      primaryWeapon: saved.primaryWeapon,
      secondaryWeapon: saved.secondaryWeapon,
      equipment: saved.equipment,
      consumables: saved.consumables,
    );

    _openLoadoutPreview(loadout);
  }

  // ignore: unused_element
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                  fontSize: 22,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 10),
              _PreviewRow(label: 'Augment', value: loadout.augment),
              _PreviewRow(
                label: 'Primary',
                value: '${primary.name} Ã¢â‚¬â€ ${primary.category}',
              ),
              _PreviewRow(
                label: 'Secondary',
                value: '${secondary.name} Ã¢â‚¬â€ ${secondary.category}',
              ),
              _PreviewRow(
                label: 'Equipment',
                value: loadout.equipment.join(', '),
              ),
              _PreviewRow(
                label: 'Consumables',
                value: loadout.consumables.join(', '),
              ),
              const SizedBox(height: 10),
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

class _ResetFocusItem {
  const _ResetFocusItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class _ResetFocusTile extends StatelessWidget {
  const _ResetFocusTile({required this.item});

  final _ResetFocusItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: TextStyle(
                    color: item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 11.5,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildCommandCardData {
  const _BuildCommandCardData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.complete = false,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool complete;
}

class _BuildCommandCard extends StatelessWidget {
  const _BuildCommandCard({required this.data});

  final _BuildCommandCardData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: data.accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: data.accent.withValues(alpha: 0.10),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: data.accent.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Icon(data.icon, color: data.accent, size: 21),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: data.complete
                        ? AppTheme.neonCyan.withValues(alpha: 0.12)
                        : data.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: data.complete
                          ? AppTheme.neonCyan.withValues(alpha: 0.32)
                          : data.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    data.complete ? 'ACTIVE' : '+ ADD',
                    style: TextStyle(
                      color: data.complete ? AppTheme.neonCyan : data.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedLoadoutManagementCard extends StatelessWidget {
  const _SavedLoadoutManagementCard({
    required this.loadout,
    required this.onOpen,
    required this.onDelete,
  });

  final ArcSavedLoadout loadout;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (loadout.category) {
      ArcLoadoutCategory.meta => Colors.amberAccent,
      ArcLoadoutCategory.pvp => AppTheme.neonPink,
      ArcLoadoutCategory.pve => Colors.lightGreenAccent,
      ArcLoadoutCategory.balanced => Colors.cyanAccent,
      ArcLoadoutCategory.saved => AppTheme.neonCyan,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 18),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loadout.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' Ã¢â‚¬Â¢  / ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open',
            onPressed: onOpen,
            icon: Icon(Icons.visibility_rounded, color: AppTheme.neonCyan),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadoutIntelRow extends StatelessWidget {
  const _LoadoutIntelRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _CraftingReadinessCard extends StatelessWidget {
  const _CraftingReadinessCard({required this.weapon});

  final ArcLoadoutWeaponSpec weapon;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final level = weapon.gunsmithLevel == null
        ? 'Bench level to verify'
        : 'Gunsmith Level ';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_rounded, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ' Ã¢â‚¬â€ . Track bench resources or try your luck through free loadout / loot until verified.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 11.5,
                height: 1.30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialNode extends StatelessWidget {
  const _DialNode({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.84),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BuilderStep {
  const _BuilderStep({
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
