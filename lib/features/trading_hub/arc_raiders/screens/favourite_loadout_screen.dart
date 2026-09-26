import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_loadout_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_unlock_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_layout_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_repair_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_build_mission_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_smart_build_mission_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_smart_build_trade_draft_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_placement_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FavouriteLoadoutScreen extends StatefulWidget {
  const FavouriteLoadoutScreen({super.key});

  static const routeName = '/favourite-loadout';

  @override
  State<FavouriteLoadoutScreen> createState() => _FavouriteLoadoutScreenState();
}

class _BlankFavouriteBuildChoice {
  const _BlankFavouriteBuildChoice();
}

const _blankFavouriteBuildChoice = _BlankFavouriteBuildChoice();

class _FavouriteLoadoutScreenState extends State<FavouriteLoadoutScreen> {
  bool _webFirstLayoutComplete = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _webFirstLayoutComplete) return;

        _webFirstLayoutComplete = true;

        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {});
          }
        });
      });
    }
  }

  final ArcSavedLoadoutRepository _savedLoadoutRepository =
      ArcSavedLoadoutRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();

  String _buildName = 'Favourite Raider Build';
  ArcPlayerPlayStyle _playStyle = ArcPlayerPlayStyle.balanced;
  String _augment = 'Survivor';
  String _shield = 'Medium Shield';
  String _primaryWeapon = 'Anvil';
  String _secondaryWeapon = 'Stitcher';
  final List<String> _primaryAttachments = <String>['Empty Slot', 'Empty Slot'];
  final List<String> _secondaryAttachments = <String>[
    'Empty Slot',
    'Empty Slot',
    'Empty Slot',
    'Empty Slot',
  ];
  final List<String> _quickSlots = <String>[
    'Survivor',
    'Snap Hook',
    'Vita Shot',
    'Lure Grenade',
    'Empty Slot',
    'Empty Slot',
  ];

  bool _loadedSavedState = false;
  ArcGeneratedLoadoutPlan? _activeSmartPlan;

  String _normalise(String value) => value.trim().toLowerCase();

  ArcBlueprint? _blueprintForName(String name) {
    final normalised = _normalise(name);
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (_normalise(blueprint.name) == normalised) return blueprint;
    }
    return null;
  }

  ArcBlueprintState _stateFor(
    String itemName,
    Map<String, ArcBlueprintState> states,
  ) {
    final blueprint = _blueprintForName(itemName);
    if (blueprint == null) return ArcBlueprintState.empty(itemName);
    return states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
  }

  bool _isOwnedOrNotBlueprint({
    required String itemName,
    required bool blueprintBased,
    required Map<String, ArcBlueprintState> states,
  }) {
    if (!blueprintBased) return true;
    return _stateFor(itemName, states).owned;
  }

  ArcLoadoutWeaponSpec _weaponSpec(String name) {
    return ArcLoadoutSeedData.weapons.firstWhere(
      (weapon) => weapon.name == name,
      orElse: () => ArcLoadoutSeedData.weapons.first,
    );
  }

  String? _assetForLoadoutItem(
    String name,
    ArcLoadoutAssetKind kind, {
    String? explicitAssetPath,
  }) {
    return ArcLoadoutAssetRegistry.assetFor(
      itemName: name,
      kind: kind,
      explicitAssetPath: explicitAssetPath,
      blueprintAssetPath: _blueprintForName(name)?.imageAssetPath,
    );
  }

  ArcLoadoutAssetKind _weaponAssetKind(bool primary) {
    return primary
        ? ArcLoadoutAssetKind.primaryWeapon
        : ArcLoadoutAssetKind.secondaryWeapon;
  }

  ArcLoadoutAssetKind _assetKindForOption(ArcLoadoutOption option) {
    return option.type == ArcLoadoutSlotType.augment
        ? ArcLoadoutAssetKind.augment
        : ArcLoadoutAssetKind.equipment;
  }

  ArcAttachmentSlotType _slotTypeForLabel(String label) {
    return ArcLoadoutCompatibilityRegistry.slotTypeForLabel(label);
  }

  ArcLoadoutAttachmentSpec? _attachmentSpecForName(String name) {
    return ArcLoadoutCompatibilityRegistry.attachmentSpecForName(name);
  }

  List<ArcLoadoutAttachmentSpec> _attachmentsForSlot({
    required String weaponName,
    required String slotLabel,
  }) {
    return ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
      weaponName: weaponName,
      slotLabel: slotLabel,
    );
  }

  String _attachmentCompatibilityStatus({
    required String weaponName,
    required String slotLabel,
    required String attachmentName,
  }) {
    if (attachmentName == slotLabel || attachmentName == 'Empty Slot') {
      final count =
          ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
            weaponName: weaponName,
            slotLabel: slotLabel,
          ).length;
      return count == 0
          ? 'No option'
          : count == 1
          ? '1 option'
          : '$count options';
    }

    final valid = ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
      weaponName: weaponName,
      slotLabel: slotLabel,
      attachmentName: attachmentName,
    );

    return valid ? 'Compatible' : 'Review compatibility';
  }

  ArcLoadoutOption? _optionForName(String name) {
    final quickUseOption = ArcLoadoutLayoutEngine.quickUseOptionForName(name);
    if (quickUseOption != null) return quickUseOption;

    final allOptions = <ArcLoadoutOption>[
      ...ArcLoadoutSeedData.augments,
      ...ArcLoadoutSeedData.equipment,
      ...ArcLoadoutSeedData.consumables,
    ];
    for (final option in allOptions) {
      if (_normalise(option.name) == _normalise(name)) return option;
    }
    return null;
  }

  List<String> _normalisedAttachmentList({
    required String weaponName,
    required List<String> savedAttachments,
  }) {
    return ArcLoadoutLayoutEngine.normalisedAttachmentList(
      weaponName: weaponName,
      savedAttachments: savedAttachments,
    );
  }

  void _normaliseQuickSlots() {
    final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
      savedItems: _quickSlots,
    );
    _quickSlots
      ..clear()
      ..addAll(migration.quickUse);
    _augment = migration.augment;
  }

  ArcSavedLoadout _draftLoadout({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final quickUse = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
      savedItems: _quickSlots,
      legacyAugment: _augment,
    ).quickUse;
    final equipment = quickUse
        .where((slot) {
          final option = ArcLoadoutLayoutEngine.quickUseOptionForName(slot);
          return option?.type == ArcLoadoutSlotType.equipment;
        })
        .where((slot) => slot != ArcLoadoutLayoutEngine.emptySlot)
        .toList(growable: false);
    final consumables = quickUse
        .where((slot) {
          final option = ArcLoadoutLayoutEngine.quickUseOptionForName(slot);
          return option?.type == ArcLoadoutSlotType.consumables;
        })
        .where((slot) => slot != ArcLoadoutLayoutEngine.emptySlot)
        .toList(growable: false);
    final augment = quickUse
        .map(ArcLoadoutLayoutEngine.quickUseOptionForName)
        .whereType<ArcLoadoutOption>()
        .firstWhere(
          (option) => option.type == ArcLoadoutSlotType.augment,
          orElse: () => const ArcLoadoutOption(
            name: '',
            type: ArcLoadoutSlotType.augment,
            description: '',
          ),
        )
        .name;

    return ArcSavedLoadout(
      id: 'favourite-loadout',
      name: _buildName,
      category: ArcLoadoutCategory.saved,
      playStyle: _playStyle,
      augment: augment,
      shield: _shield,
      primaryWeapon: _primaryWeapon,
      primaryAttachments: _normalisedAttachmentList(
        weaponName: _primaryWeapon,
        savedAttachments: _primaryAttachments,
      ),
      secondaryWeapon: _secondaryWeapon,
      secondaryAttachments: _normalisedAttachmentList(
        weaponName: _secondaryWeapon,
        savedAttachments: _secondaryAttachments,
      ),
      equipment: equipment,
      consumables: consumables,
      quickUse: List<String>.unmodifiable(quickUse),
      smartBuildData: _activeSmartPlan?.toMap(),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  void _applySavedLoadout(ArcSavedLoadout loadout) {
    setState(() {
      _buildName = loadout.name;
      _playStyle = loadout.playStyle;
      _augment = loadout.augment;
      _shield = ArcLoadoutRepairCatalog.migrateLegacyShield(loadout.shield);
      _primaryWeapon = loadout.primaryWeapon;
      _secondaryWeapon = loadout.secondaryWeapon;
      _primaryAttachments
        ..clear()
        ..addAll(
          _normalisedAttachmentList(
            weaponName: loadout.primaryWeapon,
            savedAttachments: loadout.primaryAttachments,
          ),
        );
      _secondaryAttachments
        ..clear()
        ..addAll(
          _normalisedAttachmentList(
            weaponName: loadout.secondaryWeapon,
            savedAttachments: loadout.secondaryAttachments,
          ),
        );
      final savedQuickUse = loadout.quickUse.isNotEmpty
          ? loadout.quickUse
          : <String>[...loadout.equipment, ...loadout.consumables];
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: savedQuickUse,
        legacyAugment: loadout.augment,
      );
      _quickSlots
        ..clear()
        ..addAll(migration.quickUse);
      _augment = migration.augment;
      _activeSmartPlan = ArcGeneratedLoadoutPlan.fromMap(
        loadout.smartBuildData,
      );
    });
  }

  Future<void> _saveLoadout() async {
    final now = DateTime.now();
    _normaliseQuickSlots();
    final loadout = _draftLoadout(now: now);

    try {
      await _savedLoadoutRepository.saveLoadout(loadout);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Favourite loadout saved.')));
      await UagAdService.instance.showNaturalBreakInterstitial(
        UagAdPlacementPolicy.favouriteLoadoutSaved,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save loadout. Try again.')),
      );
    }
  }

  Future<void> _startNewBuild() async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.overlay,
              accent: AppTheme.neonCyan,
              radius: ArcUiTokens.radiusXXL,
              borderOpacity: 0.28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.neonCyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NEW FAVOURITE BUILD',
                        style: AppTheme.tradingHeading(
                          fontSize: 17,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _newBuildOptionTile(
                  title: 'Blank Favourite',
                  subtitle: 'Reset this editor to a clean balanced draft.',
                  icon: Icons.note_add_outlined,
                  accent: AppTheme.neonCyan,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_blankFavouriteBuildChoice),
                ),
                const SizedBox(height: 8),
                for (final seed in ArcLoadoutSeedData.starterLoadouts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _newBuildOptionTile(
                      title: seed.name,
                      subtitle:
                          '${seed.primaryWeapon}${_separator()}${seed.secondaryWeapon}',
                      icon: Icons.inventory_2_outlined,
                      accent: seed.category == ArcLoadoutCategory.pvp
                          ? AppTheme.neonPink
                          : seed.category == ArcLoadoutCategory.pve
                          ? Colors.lightGreenAccent
                          : Colors.amberAccent,
                      onTap: () => Navigator.of(sheetContext).pop(seed),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;
    setState(() {
      if (selected == _blankFavouriteBuildChoice) {
        _buildName = 'New Favourite Build';
        _playStyle = ArcPlayerPlayStyle.balanced;
        _augment = 'Survivor';
        _shield = 'Medium Shield';
        _primaryWeapon = 'Anvil';
        _secondaryWeapon = 'Stitcher';
        _primaryAttachments
          ..clear()
          ..addAll(
            _normalisedAttachmentList(
              weaponName: _primaryWeapon,
              savedAttachments: const <String>[],
            ),
          );
        _secondaryAttachments
          ..clear()
          ..addAll(
            _normalisedAttachmentList(
              weaponName: _secondaryWeapon,
              savedAttachments: const <String>[],
            ),
          );
        _quickSlots
          ..clear()
          ..addAll(const <String>[
            'Survivor',
            'Empty Slot',
            'Empty Slot',
            'Empty Slot',
            'Empty Slot',
            'Empty Slot',
          ]);
      } else if (selected is ArcSavedLoadoutSeed) {
        _buildName = selected.name;
        _playStyle = switch (selected.category) {
          ArcLoadoutCategory.pvp => ArcPlayerPlayStyle.pvp,
          ArcLoadoutCategory.pve => ArcPlayerPlayStyle.pve,
          ArcLoadoutCategory.meta => ArcPlayerPlayStyle.balanced,
          _ => ArcPlayerPlayStyle.balanced,
        };
        _augment = selected.augment;
        _shield = selected.shield ?? 'Medium Shield';
        _primaryWeapon = selected.primaryWeapon;
        _secondaryWeapon = selected.secondaryWeapon;
        _primaryAttachments
          ..clear()
          ..addAll(
            _normalisedAttachmentList(
              weaponName: _primaryWeapon,
              savedAttachments: const <String>[],
            ),
          );
        _secondaryAttachments
          ..clear()
          ..addAll(
            _normalisedAttachmentList(
              weaponName: _secondaryWeapon,
              savedAttachments: const <String>[],
            ),
          );
        _quickSlots
          ..clear()
          ..addAll(
            ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
              savedItems: <String>[
                selected.augment,
                ...selected.equipment,
                ...selected.consumables,
              ],
              legacyAugment: selected.augment,
            ).quickUse,
          );
      }
      _activeSmartPlan = null;
      _normaliseQuickSlots();
    });
  }

  Future<void> _showSmartBuildGenerator(
    Map<String, ArcBlueprintState> states,
  ) async {
    var weaponName = _primaryWeapon;
    var focus =
        _activeSmartPlan?.focus ??
        switch (_playStyle) {
          ArcPlayerPlayStyle.pvp => ArcLoadoutCombatFocus.pvp,
          ArcPlayerPlayStyle.pve => ArcLoadoutCombatFocus.pve,
          _ => ArcLoadoutCombatFocus.balanced,
        };
    var tier = _activeSmartPlan?.tier ?? ArcLoadoutBuildTier.value;
    String? selectedSecondary = _activeSmartPlan?.secondaryWeapon;

    final plan = await showModalBottomSheet<ArcGeneratedLoadoutPlan>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final secondaryOptions =
                ArcLoadoutIntelligenceEngine.secondaryOptionsFor(
                  primaryWeapon: weaponName,
                  focus: focus,
                  tier: tier,
                );
            if (!secondaryOptions.contains(selectedSecondary)) {
              selectedSecondary = secondaryOptions.first;
            }
            final preview = ArcLoadoutIntelligenceEngine.generate(
              primaryWeapon: weaponName,
              focus: focus,
              tier: tier,
              secondaryWeaponOverride: selectedSecondary,
            );
            final previewIntegration = ArcLoadoutIntegrationEngine.evaluate(
              plan: preview,
              blueprintStates: states,
            );
            final missingBlueprints =
                previewIntegration.missingBlueprints.length;
            final totalBlueprints = previewIntegration.blueprints.length;
            final resourceUnits = preview.resourceNeeds.fold<int>(
              0,
              (total, item) => total + item.quantity,
            );

            Widget sectionLabel(String label) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label.toUpperCase(),
                  style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
                ),
              );
            }

            Widget selectionChip({
              required String label,
              required bool selected,
              required VoidCallback onSelected,
              IconData? icon,
            }) {
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => onSelected(),
                avatar: icon == null ? null : Icon(icon, size: 17),
                label: Text(label),
                selectedColor: ArcUiTokens.primaryAccent.withValues(
                  alpha: 0.22,
                ),
                backgroundColor: ArcUiTokens.surfaceInteractive,
                side: BorderSide(
                  color: selected
                      ? ArcUiTokens.primaryAccent
                      : ArcUiTokens.borderMedium,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? ArcUiTokens.primaryAccent
                      : ArcUiTokens.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }

            Widget previewMetric(String value, String label) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.interactive,
                    accent: ArcUiTokens.primaryAccent,
                    radius: ArcUiTokens.radiusM,
                    borderOpacity: 0.12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: ArcUiTokens.numeric(
                          fontSize: 20,
                          color: ArcUiTokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: ArcUiTokens.metadata(
                          color: ArcUiTokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.94,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    18 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SMART LOADOUT BUILDER',
                                  style: ArcUiTokens.sectionTitle(
                                    fontSize: 24,
                                    color: ArcUiTokens.primaryAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pick your weapon and intent. Preview the complete pairing before applying it.',
                                  style: ArcUiTokens.body(
                                    color: ArcUiTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionLabel('Primary weapon'),
                              DropdownButtonFormField<String>(
                                initialValue: weaponName,
                                dropdownColor: ArcUiTokens.surfaceOverlay,
                                decoration: ArcUiTokens.inputDecoration(
                                  prefixIcon: Icons.gps_fixed_rounded,
                                  labelText: 'Build around',
                                ),
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                ),
                                items: ArcLoadoutSeedData.weapons
                                    .map(
                                      (weapon) => DropdownMenuItem<String>(
                                        value: weapon.name,
                                        child: Text(weapon.name),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    weaponName = value;
                                    selectedSecondary = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              sectionLabel('Combat focus'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ArcLoadoutCombatFocus.values
                                    .map(
                                      (value) => selectionChip(
                                        label: value.label,
                                        icon: switch (value) {
                                          ArcLoadoutCombatFocus.pvp =>
                                            Icons.flash_on_rounded,
                                          ArcLoadoutCombatFocus.balanced =>
                                            Icons.balance_rounded,
                                          ArcLoadoutCombatFocus.pve =>
                                            Icons.smart_toy_rounded,
                                        },
                                        selected: focus == value,
                                        onSelected: () {
                                          setSheetState(() {
                                            focus = value;
                                            selectedSecondary = null;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 18),
                              sectionLabel('Build level'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ArcLoadoutBuildTier.values
                                    .map(
                                      (value) => selectionChip(
                                        label: value.label,
                                        icon: value == ArcLoadoutBuildTier.meta
                                            ? Icons.military_tech_rounded
                                            : Icons.savings_outlined,
                                        selected: tier == value,
                                        onSelected: () {
                                          setSheetState(() {
                                            tier = value;
                                            selectedSecondary = null;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 18),
                              sectionLabel('Recommended secondary'),
                              Text(
                                "UAG ranks these weapons to cover the primary weapon's range, sustain or target weakness.",
                                style: ArcUiTokens.bodySmall(
                                  color: ArcUiTokens.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: secondaryOptions
                                    .map(
                                      (weapon) => selectionChip(
                                        label: weapon,
                                        selected: selectedSecondary == weapon,
                                        onSelected: () => setSheetState(
                                          () => selectedSecondary = weapon,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: ArcUiTokens.surfaceDecoration(
                                  role: ArcSurfaceRole.raised,
                                  accent: ArcUiTokens.primaryAccent,
                                  radius: ArcUiTokens.radiusXL,
                                  borderOpacity: 0.28,
                                  glow: true,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          color: ArcUiTokens.primaryAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            preview.displayName,
                                            style: ArcUiTokens.sectionTitle(
                                              fontSize: 19,
                                              color: ArcUiTokens.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${preview.primaryWeapon} + ${preview.secondaryWeapon}',
                                      style: ArcUiTokens.body(
                                        color: ArcUiTokens.textSecondary,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        previewMetric(
                                          '${previewIntegration.completionPercent}%',
                                          'Ready now',
                                        ),
                                        const SizedBox(width: 8),
                                        previewMetric(
                                          '$missingBlueprints/$totalBlueprints',
                                          'Blueprints missing',
                                        ),
                                        const SizedBox(width: 8),
                                        previewMetric(
                                          '$resourceUnits',
                                          'Material units',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Primary: ${preview.primaryAttachments.where((item) => item != 'Empty Slot').join(' - ')}',
                                      style: ArcUiTokens.bodySmall(
                                        color: ArcUiTokens.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Secondary: ${preview.secondaryAttachments.where((item) => item != 'Empty Slot').join(' - ')}',
                                      style: ArcUiTokens.bodySmall(
                                        color: ArcUiTokens.textTertiary,
                                      ),
                                    ),
                                    if (preview.rationale.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        preview.rationale.first,
                                        style: ArcUiTokens.bodySmall(
                                          color: ArcUiTokens.textTertiary,
                                        ).copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: ArcUiTokens.textButtonStyle(
                            accent: ArcUiTokens.primaryAccent,
                            primary: true,
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(preview),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Apply Smart Build'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (plan == null || !mounted) return;

    setState(() {
      _activeSmartPlan = plan;
      _buildName = plan.displayName;
      _playStyle = plan.focus.playStyle;
      _primaryWeapon = plan.primaryWeapon;
      _secondaryWeapon = plan.secondaryWeapon;
      _primaryAttachments
        ..clear()
        ..addAll(plan.primaryAttachments);
      _secondaryAttachments
        ..clear()
        ..addAll(plan.secondaryAttachments);
    });

    final integration = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: states,
    );
    try {
      await _blueprintRepository.saveBlueprintStates(
        integration.blueprints.map((need) {
          final current =
              states[need.blueprintId] ??
              ArcBlueprintState.empty(need.blueprintId);
          final priority = current.priorityRank > need.priorityRank
              ? current.priorityRank
              : need.priorityRank;
          return current.copyWith(priorityRank: priority);
        }),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loadout generated, but priorities could not sync.'),
          ),
        );
      }
    }

    try {
      await _savedLoadoutRepository.saveLoadout(_draftLoadout());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Smart Build is active, but could not be saved.'),
          ),
        );
      }
    }

    if (!mounted) return;

    final resourceSummary = plan.resourceNeeds.isEmpty
        ? 'No mapped attachment materials required.'
        : plan.resourceNeeds
              .take(3)
              .map((entry) => '${entry.quantity}x ${entry.itemName}')
              .join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${plan.displayName} generated with ${plan.secondaryWeapon}. $resourceSummary',
        ),
      ),
    );
  }

  Future<void> _pickWeapon({
    required bool primary,
    required Map<String, ArcBlueprintState> states,
  }) async {
    final selected = await _showPicker<ArcLoadoutWeaponSpec>(
      title: primary ? 'Select Primary Weapon' : 'Select Secondary Weapon',
      items: ArcLoadoutSeedData.weapons,
      labelBuilder: (weapon) => weapon.name,
      subtitleBuilder: (weapon) {
        final owned = _isOwnedOrNotBlueprint(
          itemName: weapon.name,
          blueprintBased: weapon.blueprintBased,
          states: states,
        );
        final availability = weapon.blueprintBased
            ? owned
                  ? 'Blueprint owned'
                  : 'Missing blueprint - selectable for planning'
            : weapon.craftable
            ? weapon.gunsmithLevel == null
                  ? 'Bench craftable'
                  : 'Gunsmith Level ${weapon.gunsmithLevel}'
            : 'Available / bench source';
        return '$availability - ${weapon.category} - ${weapon.role}';
      },
      leadingBuilder: (weapon) {
        final owned = _isOwnedOrNotBlueprint(
          itemName: weapon.name,
          blueprintBased: weapon.blueprintBased,
          states: states,
        );
        return _itemImage(
          imageAsset: _assetForLoadoutItem(
            weapon.name,
            _weaponAssetKind(primary),
          ),
          accent: owned ? AppTheme.neonCyan : AppTheme.neonPink,
          owned: owned,
          icon: weapon.blueprintBased && !owned
              ? Icons.lock_rounded
              : Icons.gps_fixed_rounded,
        );
      },
      selectedBuilder: (weapon) =>
          weapon.name == (primary ? _primaryWeapon : _secondaryWeapon),
      footerText:
          'Changing weapon resets its attachment slots so incompatible attachments cannot carry over.',
    );

    if (selected == null) return;

    setState(() {
      if (primary) {
        final nextAttachments =
            ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
              previousWeaponName: _primaryWeapon,
              nextWeaponName: selected.name,
              previousAttachments: _primaryAttachments,
            );
        _primaryWeapon = selected.name;
        _primaryAttachments
          ..clear()
          ..addAll(nextAttachments);
      } else {
        final nextAttachments =
            ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
              previousWeaponName: _secondaryWeapon,
              nextWeaponName: selected.name,
              previousAttachments: _secondaryAttachments,
            );
        _secondaryWeapon = selected.name;
        _secondaryAttachments
          ..clear()
          ..addAll(nextAttachments);
      }
    });
  }

  Future<void> _pickShield() async {
    final options = ArcLoadoutSeedData.equipment
        .where((option) => option.name.toLowerCase().endsWith('shield'))
        .toList(growable: false);

    final selected = await _showPicker<ArcLoadoutOption>(
      title: 'Select Shield',
      items: options,
      labelBuilder: (option) => option.name,
      subtitleBuilder: (option) => option.description,
      leadingBuilder: (option) => _itemImage(
        imageAsset: _assetForLoadoutItem(
          option.name,
          ArcLoadoutAssetKind.equipment,
        ),
        accent: Colors.lightGreenAccent,
        owned: true,
        icon: Icons.shield_rounded,
      ),
      selectedBuilder: (option) => option.name == _shield,
      footerText:
          'Shield artwork stays icon-only until genuine Light, Medium and Heavy Shield assets are supplied.',
    );
    if (selected == null) return;
    setState(() => _shield = selected.name);
  }

  Future<void> _pickQuickSlot(int index) async {
    while (_quickSlots.length < ArcLoadoutLayoutEngine.quickUseSlotCount) {
      _quickSlots.add(ArcLoadoutLayoutEngine.emptySlot);
    }
    final currentOption = ArcLoadoutLayoutEngine.quickUseOptionForName(
      _quickSlots[index],
    );
    final augmentAlreadySelected = _quickSlots.indexed.any((entry) {
      if (entry.$1 == index) return false;
      return ArcLoadoutLayoutEngine.quickUseOptionForName(entry.$2)?.type ==
          ArcLoadoutSlotType.augment;
    });
    final options = <ArcLoadoutOption>[
      ...ArcLoadoutLayoutEngine.quickUseOptions().where((option) {
        if (option.type != ArcLoadoutSlotType.augment) return true;
        return !augmentAlreadySelected ||
            currentOption?.type == ArcLoadoutSlotType.augment;
      }),
      ArcLoadoutOption(
        name: ArcLoadoutLayoutEngine.emptySlot,
        type: currentOption?.type ?? ArcLoadoutSlotType.equipment,
        description: 'Leave this slot empty for now.',
      ),
    ];
    final selected = await _showPicker<ArcLoadoutOption>(
      title: 'Select Quick Use Slot ${index + 1}',
      items: options,
      labelBuilder: (option) => option.name,
      subtitleBuilder: (option) => option.description,
      leadingBuilder: (option) {
        final empty = option.name == ArcLoadoutLayoutEngine.emptySlot;
        return _itemImage(
          imageAsset: _assetForLoadoutItem(
            option.name,
            _assetKindForOption(option),
          ),
          accent: empty ? Colors.white70 : Colors.amberAccent,
          owned: true,
          icon: empty
              ? Icons.remove_circle_outline_rounded
              : option.type == ArcLoadoutSlotType.consumables
              ? Icons.medical_services_rounded
              : option.type == ArcLoadoutSlotType.augment
              ? Icons.health_and_safety_rounded
              : Icons.inventory_2_rounded,
        );
      },
      selectedBuilder: (option) => option.name == _quickSlots[index],
      footerText:
          'Six fixed Quick Use slots accept gadgets, utility, healing, throwables and one augment. Weapons, attachments and shield stay out of this picker.',
    );
    if (selected == null) return;
    setState(() {
      _quickSlots[index] = selected.name;
      _normaliseQuickSlots();
    });
  }

  IconData _quickUseIcon(ArcLoadoutOption? option) {
    if (option == null) return Icons.remove_circle_outline_rounded;
    switch (option.type) {
      case ArcLoadoutSlotType.augment:
        return Icons.health_and_safety_rounded;
      case ArcLoadoutSlotType.consumables:
        return Icons.medical_services_rounded;
      case ArcLoadoutSlotType.equipment:
      case ArcLoadoutSlotType.primaryWeapon:
      case ArcLoadoutSlotType.primaryAttachments:
      case ArcLoadoutSlotType.secondaryWeapon:
      case ArcLoadoutSlotType.secondaryAttachments:
        return Icons.inventory_2_rounded;
    }
  }

  Future<void> _pickAttachment({
    required bool primary,
    required int index,
  }) async {
    final weapon = _weaponSpec(primary ? _primaryWeapon : _secondaryWeapon);
    final currentList = primary ? _primaryAttachments : _secondaryAttachments;
    final slots = weapon.slots;
    if (slots.isEmpty || index < 0 || index >= slots.length) return;
    final slotLabel = slots[index];
    final currentAttachment = index < currentList.length
        ? currentList[index]
        : 'Empty Slot';
    final options = _attachmentsForSlot(
      weaponName: weapon.name,
      slotLabel: slotLabel,
    );
    final empty = ArcLoadoutAttachmentSpec(
      id: 'empty-${slotLabel.toLowerCase().replaceAll(' ', '-')}',
      name: 'Empty Slot',
      slotType: _slotTypeForLabel(slotLabel),
      benchLevel: 0,
      materials: const <String>[],
      effect: 'Clear this $slotLabel attachment slot.',
      compatibleWeapons: <String>[weapon.name],
    );

    final selected = await _showPicker<ArcLoadoutAttachmentSpec>(
      title: '$slotLabel for ${weapon.name}',
      items: <ArcLoadoutAttachmentSpec>[empty, ...options],
      labelBuilder: (attachment) => attachment.name,
      subtitleBuilder: (attachment) {
        if (attachment.name == 'Empty Slot') return attachment.effect;
        return '${attachment.benchLabel} / ${attachment.effectSummary} / ${attachment.materialSummary}';
      },
      leadingBuilder: (attachment) {
        return _itemImage(
          imageAsset: _assetForLoadoutItem(
            attachment.name,
            ArcLoadoutAssetKind.attachment,
            explicitAssetPath: attachment.imageAssetPath,
          ),
          accent: attachment.name == 'Empty Slot'
              ? Colors.white70
              : Colors.amberAccent,
          owned: true,
          icon: attachment.name == 'Empty Slot'
              ? Icons.remove_circle_outline_rounded
              : Icons.construction_rounded,
        );
      },
      selectedBuilder: (attachment) => attachment.name == currentAttachment,
      footerText: options.isEmpty
          ? 'No mapped attachments for this weapon slot yet. Keep it empty safely.'
          : '${options.length} compatible options. Incompatible attachments are hidden automatically.',
    );
    if (selected == null) return;

    setState(() {
      while (currentList.length <= index) {
        currentList.add('Empty Slot');
      }
      currentList[index] = selected.name;
    });
  }

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelBuilder,
    required String Function(T item) subtitleBuilder,
    Widget Function(T item)? leadingBuilder,
    bool Function(T item)? selectedBuilder,
    String? footerText,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: ElectricChargeBorder(
            active: true,
            radius: ArcUiTokens.radiusXL,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
              ),
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.overlay,
                accent: ArcUiTokens.primaryAccent,
                radius: ArcUiTokens.radiusXL,
                borderOpacity: 0.32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: ArcUiTokens.sectionTitle(
                              fontSize: 20,
                              color: ArcUiTokens.primaryAccent,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: ArcUiTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (footerText != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: ArcUiTokens.surfaceDecoration(
                          role: ArcSurfaceRole.interactive,
                          accent: ArcUiTokens.primaryAccent,
                          radius: ArcUiTokens.radiusM,
                          borderOpacity: 0.20,
                        ),
                        child: Text(
                          footerText,
                          style: ArcUiTokens.bodySmall(
                            color: ArcUiTokens.textSecondary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: ArcUiTokens.borderSubtle),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = selectedBuilder?.call(item) ?? false;
                        return ListTile(
                          selected: selected,
                          selectedTileColor: ArcUiTokens.primaryAccent
                              .withValues(alpha: 0.08),
                          leading: leadingBuilder?.call(item),
                          title: Text(
                            labelBuilder(item),
                            style: TextStyle(
                              color: selected
                                  ? ArcUiTokens.primaryAccent
                                  : ArcUiTokens.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            subtitleBuilder(item),
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textTertiary,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: selected
                                ? ArcUiTokens.success
                                : ArcUiTokens.primaryAccent,
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compactMobileLandscape =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        media.orientation == Orientation.landscape &&
        media.size.height <= 720;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Loadout'),
      body: ArcRaidersScreenShell(
        useSafeArea: false,
        showAdBanner: true,
        child: SafeArea(
          child: StreamBuilder<ArcSavedLoadout?>(
            stream: _savedLoadoutRepository.watchFavouriteLoadout(),
            builder: (context, savedSnapshot) {
              final savedLoadout = savedSnapshot.data;
              if (!_loadedSavedState && savedLoadout != null) {
                _loadedSavedState = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _applySavedLoadout(savedLoadout);
                });
              }

              return StreamBuilder<ArcBlueprintStateSnapshot>(
                stream: _blueprintRepository.watchMyBlueprintStateSnapshot(),
                builder: (context, stateSnapshot) {
                  final hydration = stateSnapshot.data;
                  final blueprintStates =
                      hydration?.states ?? const <String, ArcBlueprintState>{};
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final media = MediaQuery.of(context);
                      final portrait =
                          media.orientation == Orientation.portrait &&
                          constraints.maxWidth < 900;

                      if (portrait) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 150),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if ((hydration?.isLoading ?? false) &&
                                  blueprintStates.isEmpty) ...[
                                _buildBlueprintStateNotice(),
                                const SizedBox(height: 6),
                              ],
                              _buildCompactLoadoutHeader(blueprintStates),
                              const SizedBox(height: 6),
                              const ArcBlueprintWorkspaceBar(
                                current: ArcBlueprintWorkspace.loadout,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 6),
                              _buildPortraitInGameBoard(blueprintStates),
                              const SizedBox(height: 6),
                              _buildMobileQuickUseTray(blueprintStates),
                              const SizedBox(height: 6),
                              _buildLevelFourMaterialPlan(),
                              const SizedBox(height: 6),
                              _buildEquipmentMaintenancePlan(),
                              const SizedBox(height: 6),
                              _buildMissingBlueprints(blueprintStates),
                            ],
                          ),
                        );
                      }

                      if (compactMobileLandscape) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 72),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if ((hydration?.isLoading ?? false) &&
                                  blueprintStates.isEmpty) ...[
                                _buildBlueprintStateNotice(),
                                const SizedBox(height: 6),
                              ],
                              _buildCompactLoadoutHeader(blueprintStates),
                              const SizedBox(height: 6),
                              const ArcBlueprintWorkspaceBar(
                                current: ArcBlueprintWorkspace.loadout,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 6),
                              _buildCompactMobileBoard(blueprintStates),
                              const SizedBox(height: 6),
                              _buildMobileQuickUseTray(blueprintStates),
                              const SizedBox(height: 6),
                              _buildLevelFourMaterialPlan(),
                              const SizedBox(height: 6),
                              _buildEquipmentMaintenancePlan(),
                              const SizedBox(height: 6),
                              _buildMissingBlueprints(blueprintStates),
                            ],
                          ),
                        );
                      }

                      return ArcRaidersPageList(
                        maxWidth: 1280,
                        bottomPadding: 150,
                        children: [
                          if ((hydration?.isLoading ?? false) &&
                              blueprintStates.isEmpty) ...[
                            _buildBlueprintStateNotice(),
                            const SizedBox(height: 10),
                          ],
                          _buildHero(blueprintStates),
                          const SizedBox(height: 8),
                          const ArcBlueprintWorkspaceBar(
                            current: ArcBlueprintWorkspace.loadout,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 10),
                          _buildLoadoutBoard(blueprintStates),
                          const SizedBox(height: 10),
                          _buildEquipmentMaintenancePlan(),
                          const SizedBox(height: 10),
                          _buildIntelligenceStrip(blueprintStates),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLoadoutHeader(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: AppTheme.neonCyan,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FAVOURITE LOADOUT',
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: AppTheme.neonCyan,
                  ),
                ),
                Text(
                  _buildName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          _planningPill(
            missing == 0 ? 'BP READY' : '$missing BP MISSING',
            missing == 0 ? Colors.lightGreenAccent : AppTheme.neonPink,
          ),
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Blueprint Tracker',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
            icon: const Icon(Icons.grid_view_rounded, color: AppTheme.neonCyan),
          ),
          IconButton(
            tooltip: 'Smart Build',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showSmartBuildGenerator(states),
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amberAccent,
            ),
          ),
          IconButton(
            tooltip: 'Save Favourite Loadout',
            visualDensity: VisualDensity.compact,
            onPressed: _saveLoadout,
            icon: const Icon(Icons.save_rounded, color: AppTheme.neonPink),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMobileBoard(Map<String, ArcBlueprintState> states) {
    return Container(
      key: const Key('favourite-loadout-landscape-board'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                child: Column(
                  children: [
                    _buildCompactAugment(states),
                    const SizedBox(height: 6),
                    _buildCompactShield(states),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _buildCompactWeaponRow(true, states),
                    const SizedBox(height: 6),
                    _buildCompactWeaponRow(false, states),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWantedBlueprintGrid(
            states,
            crossAxisCount: 5,
            childAspectRatio: 1.72,
            gridKey: const Key('favourite-loadout-wanted-landscape'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWeaponRow(
    bool primary,
    Map<String, ArcBlueprintState> states,
  ) {
    final weapon = _weaponSpec(primary ? _primaryWeapon : _secondaryWeapon);
    final attachments = primary ? _primaryAttachments : _secondaryAttachments;
    final accent = primary ? AppTheme.neonCyan : AppTheme.neonPink;
    final owned = _isOwnedOrNotBlueprint(
      itemName: weapon.name,
      blueprintBased: weapon.blueprintBased,
      states: states,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        final imageSize = narrow ? 52.0 : 64.0;
        final attachmentSize = narrow ? 40.0 : 46.0;

        final lead = Row(
          children: [
            InkWell(
              onTap: () => _pickWeapon(primary: primary, states: states),
              child: _itemImage(
                imageAsset: _assetForLoadoutItem(
                  weapon.name,
                  _weaponAssetKind(primary),
                ),
                accent: accent,
                owned: owned,
                icon: owned ? Icons.inventory_2_rounded : Icons.lock_rounded,
                size: imageSize,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primary ? 'WEAPON 1' : 'WEAPON 2',
                    style: ArcUiTokens.label(
                      color: accent,
                    ).copyWith(fontSize: 8),
                  ),
                  Text(
                    weapon.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(
                      fontSize: narrow ? 13 : 16,
                      color: owned ? Colors.white : Colors.white38,
                    ),
                  ),
                  Text(
                    weapon.blueprintBased && !owned
                        ? 'MISSING BLUEPRINT'
                        : _weaponSubtitle(weapon),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned ? Colors.white54 : AppTheme.neonPink,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final attachmentStrip = Wrap(
          spacing: 5,
          runSpacing: 5,
          children: List.generate(weapon.slots.length, (index) {
            final slotLabel = weapon.slots[index];
            final label =
                index < attachments.length && attachments[index] != 'Empty Slot'
                ? attachments[index]
                : slotLabel;
            final attachment = _attachmentSpecForName(label);
            final assigned = label != slotLabel && label != 'Empty Slot';
            final attachmentOwned =
                !assigned ||
                _isOwnedOrNotBlueprint(
                  itemName: label,
                  blueprintBased: _blueprintForName(label) != null,
                  states: states,
                );
            return Tooltip(
              message: assigned ? '$slotLabel: $label' : '$slotLabel: Empty',
              child: InkWell(
                onTap: () => _pickAttachment(primary: primary, index: index),
                child: Container(
                  width: attachmentSize,
                  height: attachmentSize,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withValues(alpha: assigned ? 0.40 : 0.18),
                    ),
                  ),
                  child: _itemImage(
                    imageAsset: _assetForLoadoutItem(
                      label,
                      ArcLoadoutAssetKind.attachment,
                      explicitAssetPath: attachment?.imageAssetPath,
                    ),
                    accent: accent,
                    owned: attachmentOwned,
                    icon: assigned
                        ? Icons.construction_rounded
                        : Icons.add_rounded,
                    size: attachmentSize - 4,
                  ),
                ),
              ),
            );
          }),
        );

        return Container(
          key: Key(
            primary
                ? 'favourite-loadout-weapon-1'
                : 'favourite-loadout-weapon-2',
          ),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    lead,
                    if (weapon.slots.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      attachmentStrip,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 5, child: lead),
                    if (weapon.slots.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(flex: 6, child: attachmentStrip),
                    ],
                  ],
                ),
        );
      },
    );
  }

  int _augmentQuickSlotIndex() {
    for (var index = 0; index < _quickSlots.length; index++) {
      final option = ArcLoadoutLayoutEngine.quickUseOptionForName(
        _quickSlots[index],
      );
      if (option?.type == ArcLoadoutSlotType.augment) return index;
    }
    return 0;
  }

  Widget _buildCompactAugment(Map<String, ArcBlueprintState> states) {
    final augmentName = _augment.trim().isEmpty ? 'Select Augment' : _augment;
    final option = _optionForName(_augment);
    final owned = _augment.trim().isEmpty
        ? true
        : _isOwnedOrNotBlueprint(
            itemName: _augment,
            blueprintBased: option?.blueprintBased ?? false,
            states: states,
          );
    return _buildCompactAuxiliarySlot(
      key: const Key('favourite-loadout-augment'),
      slotLabel: 'AUGMENT',
      itemName: augmentName,
      imageAsset: _assetForLoadoutItem(_augment, ArcLoadoutAssetKind.augment),
      accent: AppTheme.neonPink,
      owned: owned,
      icon: Icons.health_and_safety_rounded,
      onTap: () => _pickQuickSlot(_augmentQuickSlotIndex()),
    );
  }

  Widget _buildCompactShield(Map<String, ArcBlueprintState> states) {
    final shieldOption = _optionForName(_shield);
    final owned = _isOwnedOrNotBlueprint(
      itemName: _shield,
      blueprintBased: shieldOption?.blueprintBased ?? false,
      states: states,
    );
    return _buildCompactAuxiliarySlot(
      key: const Key('favourite-loadout-shield'),
      slotLabel: 'SHIELD',
      itemName: _shield,
      imageAsset: _assetForLoadoutItem(_shield, ArcLoadoutAssetKind.equipment),
      accent: Colors.lightGreenAccent,
      owned: owned,
      icon: Icons.shield_outlined,
      onTap: _pickShield,
    );
  }

  Widget _buildCompactAuxiliarySlot({
    required Key key,
    required String slotLabel,
    required String itemName,
    required String? imageAsset,
    required Color accent,
    required bool owned,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
      onTap: onTap,
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _itemImage(
              imageAsset: imageAsset,
              accent: accent,
              owned: owned,
              icon: icon,
              size: 48,
            ),
            const SizedBox(height: 4),
            Text(
              slotLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.label(color: accent).copyWith(fontSize: 8),
            ),
            Text(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.buttonTextStyle(
                color: owned ? Colors.white : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuickSlots(Map<String, ArcBlueprintState> states) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: ArcLoadoutLayoutEngine.quickUseSlotCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1.75,
          ),
          itemBuilder: (context, index) {
            final item = index < _quickSlots.length
                ? _quickSlots[index]
                : ArcLoadoutLayoutEngine.emptySlot;
            final option = ArcLoadoutLayoutEngine.quickUseOptionForName(item);
            final owned =
                item == ArcLoadoutLayoutEngine.emptySlot ||
                _isOwnedOrNotBlueprint(
                  itemName: item,
                  blueprintBased: option?.blueprintBased ?? false,
                  states: states,
                );
            return _quickUseCard(
              index: index + 1,
              label: item,
              subtitle: option?.type.label ?? 'Open slot',
              imageAsset: _assetForLoadoutItem(
                item,
                option == null
                    ? ArcLoadoutAssetKind.equipment
                    : _assetKindForOption(option),
              ),
              icon: _quickUseIcon(option),
              owned: owned,
              onTap: () => _pickQuickSlot(index),
            );
          },
        );
      },
    );
  }

  Widget _buildLevelFourMaterialPlan() {
    final primaryPlan = ArcItemIntelligenceEngine.planForItem(_primaryWeapon);
    final secondaryPlan = ArcItemIntelligenceEngine.planForItem(
      _secondaryWeapon,
    );
    final plans = <ArcCraftingPlan>[primaryPlan, secondaryPlan];
    final raw = <String, int>{};
    final craft = <String, int>{};

    for (final plan in plans) {
      for (final entry in plan.rawMaterials.entries) {
        raw.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      for (final step in plan.craftSteps) {
        craft.update(
          step.itemId,
          (value) => value + step.quantity,
          ifAbsent: () => step.quantity,
        );
      }
    }

    final rawEntries = raw.entries.toList()
      ..sort(
        (a, b) => ArcItemIntelligenceEngine.itemName(
          a.key,
        ).compareTo(ArcItemIntelligenceEngine.itemName(b.key)),
      );
    final craftEntries = craft.entries.toList()
      ..sort(
        (a, b) => ArcItemIntelligenceEngine.itemName(
          a.key,
        ).compareTo(ArcItemIntelligenceEngine.itemName(b.key)),
      );

    return _arcPanel(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(9),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minTileHeight: 40,
          title: Text(
            'LEVEL IV BUILD COST',
            style: AppTheme.tradingHeading(
              fontSize: 14,
              color: Colors.amberAccent,
            ),
          ),
          subtitle: Text(
            '${primaryPlan.targetName} + ${secondaryPlan.targetName} • '
            'combined from-scratch base materials',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 9.5),
          ),
          children: [
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in rawEntries)
                  _planningPill(
                    '${ArcItemIntelligenceEngine.itemName(entry.key)} x${entry.value}',
                    Colors.amberAccent,
                  ),
              ],
            ),
            if (craftEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CRAFT / UPGRADE CHAIN',
                  style: ArcUiTokens.label(color: AppTheme.neonCyan),
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in craftEntries)
                    _planningPill(
                      '${ArcItemIntelligenceEngine.itemName(entry.key)} x${entry.value}',
                      AppTheme.neonCyan,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitInGameBoard(Map<String, ArcBlueprintState> states) {
    return Container(
      key: const Key('favourite-loadout-portrait-board'),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCompactAugment(states)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildCompactShield(states)),
                  ],
                ),
                const SizedBox(height: 6),
                _buildCompactWeaponRow(true, states),
                const SizedBox(height: 6),
                _buildCompactWeaponRow(false, states),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: _buildWantedBlueprintGrid(
              states,
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              gridKey: const Key('favourite-loadout-wanted-portrait'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickUseTray(Map<String, ArcBlueprintState> states) {
    return _arcPanel(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 6),
          visualDensity: VisualDensity.compact,
          minTileHeight: 38,
          title: Text(
            'QUICK USE',
            style: AppTheme.tradingHeading(
              fontSize: 13,
              color: Colors.amberAccent,
            ),
          ),
          subtitle: const Text(
            '6 supporting slots - kept outside the main equipment board',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white54, fontSize: 9),
          ),
          children: [_buildCompactQuickSlots(states)],
        ),
      ),
    );
  }

  Widget _buildWantedBlueprintGrid(
    Map<String, ArcBlueprintState> states, {
    required int crossAxisCount,
    required double childAspectRatio,
    required Key gridKey,
  }) {
    final targets = ArcLoadoutLayoutEngine.wantedBlueprintTargets(states);
    return Column(
      key: gridKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'WANTED BLUEPRINTS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: 12,
                  color: AppTheme.neonCyan,
                ),
              ),
            ),
            Text(
              '${targets.length}/10',
              style: ArcUiTokens.label(color: AppTheme.neonPink),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GridView.builder(
          itemCount: ArcLoadoutLayoutEngine.wantedBlueprintSlotCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final blueprint = index < targets.length ? targets[index] : null;
            return _wantedBlueprintTile(
              index: index,
              blueprint: blueprint,
              states: states,
            );
          },
        ),
      ],
    );
  }

  Widget _wantedBlueprintTile({
    required int index,
    required ArcBlueprint? blueprint,
    required Map<String, ArcBlueprintState> states,
  }) {
    final accent = blueprint == null
        ? Colors.white38
        : index < 3
        ? AppTheme.neonPink
        : AppTheme.neonCyan;
    final unlockPlan = blueprint == null
        ? null
        : ArcBlueprintUnlockEngine.planForBlueprint(blueprint.name);
    final state = blueprint == null
        ? null
        : states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

    return InkWell(
      key: Key('wanted-blueprint-slot-${index + 1}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () =>
          Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: blueprint == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white30, size: 22),
                  const SizedBox(height: 3),
                  Text(
                    'SET TARGET',
                    textAlign: TextAlign.center,
                    style: ArcUiTokens.label(
                      color: Colors.white38,
                    ).copyWith(fontSize: 7.5),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 34,
                    child: _itemImage(
                      imageAsset: blueprint.imageAssetPath,
                      accent: accent,
                      owned: state?.owned ?? false,
                      icon: blueprint.icon,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    blueprint.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTheme.buttonTextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                    ),
                  ),
                  if (unlockPlan != null)
                    Icon(
                      Icons.account_tree_rounded,
                      color: Colors.lightGreenAccent,
                      size: 11,
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildBlueprintStateNotice() {
    return _arcPanel(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Syncing Blueprint Grid ownership before checking this loadout.',
              style: TextStyle(color: Colors.white70, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states);
    return _arcPanel(
      accent: AppTheme.neonCyan,
      electric: true,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAVOURITE LOADOUT',
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 22 : 27,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _buildName,
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  isBold: true,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _pill(_playStyle.shortLabel, AppTheme.neonPink),
              _pill(
                missing.isEmpty ? 'Blueprints ready' : '${missing.length} BP',
                missing.isEmpty ? Colors.lightGreenAccent : Colors.amberAccent,
              ),
              _smallAction(
                label: 'New Build',
                icon: Icons.add_circle_outline_rounded,
                color: AppTheme.neonPink,
                onTap: _startNewBuild,
              ),
              _smallAction(
                label: 'Smart Build',
                icon: Icons.auto_awesome_rounded,
                color: Colors.amberAccent,
                onTap: () => _showSmartBuildGenerator(states),
              ),
              _smallAction(
                label: 'Save',
                icon: Icons.save_rounded,
                color: AppTheme.neonCyan,
                onTap: _saveLoadout,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 12), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              Flexible(child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadoutBoard(Map<String, ArcBlueprintState> states) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 700;

        if (twoColumn) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildWeaponSlot(true, states),
                    const SizedBox(height: 10),
                    _buildWeaponSlot(false, states),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildShieldBlock(states),
                    const SizedBox(height: 10),
                    _buildQuickSlots(states),
                    const SizedBox(height: 10),
                    _buildLoadoutPlanningDetails(states),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildShieldBlock(states),
            const SizedBox(height: 10),
            _buildWeaponSlot(true, states),
            const SizedBox(height: 10),
            _buildWeaponSlot(false, states),
            const SizedBox(height: 10),
            _buildQuickSlots(states),
            const SizedBox(height: 10),
            _buildLoadoutPlanningDetails(states),
          ],
        );
      },
    );
  }

  Widget _buildLoadoutPlanningDetails(Map<String, ArcBlueprintState> states) {
    final missingCount = _missingBlueprintItems(states).length;
    final emptyAttachments =
        _emptyAttachmentCount(
          weaponName: _primaryWeapon,
          attachments: _primaryAttachments,
        ) +
        _emptyAttachmentCount(
          weaponName: _secondaryWeapon,
          attachments: _secondaryAttachments,
        );
    final emptyQuickSlots = _quickSlots
        .where((slot) => slot == 'Empty Slot' || slot.trim().isEmpty)
        .length;

    return _arcPanel(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minTileHeight: 42,
          iconColor: AppTheme.neonCyan,
          collapsedIconColor: Colors.white54,
          title: Text(
            'PLANNING',
            style: AppTheme.tradingHeading(
              fontSize: 14,
              color: AppTheme.neonCyan,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _planningPill('$missingCount BP', AppTheme.neonPink),
                _planningPill('$emptyAttachments ATTACH', Colors.amberAccent),
                _planningPill(
                  '$emptyQuickSlots QUICK',
                  Colors.lightGreenAccent,
                ),
              ],
            ),
          ),
          children: [
            const SizedBox(height: 10),
            if (_activeSmartPlan != null) ...[
              _buildSmartBuildIntegrationPanel(states),
              const SizedBox(height: 10),
            ],
            _buildMissingBlueprints(states),
            const SizedBox(height: 10),
            _buildTradeBenchPanel(states),
            const SizedBox(height: 10),
            _buildBetaReadinessPanel(states),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponSlot(bool primary, Map<String, ArcBlueprintState> states) {
    final weapon = _weaponSpec(primary ? _primaryWeapon : _secondaryWeapon);
    final attachments = primary ? _primaryAttachments : _secondaryAttachments;
    final accent = primary ? AppTheme.neonCyan : AppTheme.neonPink;
    final owned = _isOwnedOrNotBlueprint(
      itemName: weapon.name,
      blueprintBased: weapon.blueprintBased,
      states: states,
    );

    return _arcPanel(
      accent: accent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            primary ? 'PRIMARY WEAPON' : 'SECONDARY WEAPON',
            accent,
          ),
          const SizedBox(height: 10),
          _itemTile(
            label: weapon.name,
            subtitle: _weaponSubtitle(weapon),
            imageAsset: _assetForLoadoutItem(
              weapon.name,
              _weaponAssetKind(primary),
            ),
            accent: accent,
            owned: owned,
            lockedLabel: weapon.blueprintBased && !owned
                ? 'MISSING BLUEPRINT'
                : null,
            onTap: () => _pickWeapon(primary: primary, states: states),
            imageSize: 62,
          ),
          if (weapon.slots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: List.generate(weapon.slots.length.clamp(0, 6).toInt(), (
                index,
              ) {
                final slotLabel = index < weapon.slots.length
                    ? weapon.slots[index]
                    : 'Attachment';
                final label =
                    index < attachments.length &&
                        attachments[index] != 'Empty Slot'
                    ? attachments[index]
                    : slotLabel;
                final attachment = _attachmentSpecForName(label);
                final assigned = label != slotLabel && label != 'Empty Slot';
                final attachmentOwned =
                    !assigned ||
                    _isOwnedOrNotBlueprint(
                      itemName: label,
                      blueprintBased: _blueprintForName(label) != null,
                      states: states,
                    );
                return _attachmentChip(
                  label: label,
                  slotLabel: slotLabel,
                  imageAsset: _assetForLoadoutItem(
                    label,
                    ArcLoadoutAssetKind.attachment,
                    explicitAssetPath: attachment?.imageAssetPath,
                  ),
                  accent: accent,
                  owned: attachmentOwned,
                  compatibilityLabel: _attachmentCompatibilityStatus(
                    weaponName: weapon.name,
                    slotLabel: slotLabel,
                    attachmentName: label,
                  ),
                  onTap: () => _pickAttachment(primary: primary, index: index),
                );
              }),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _pill('No attachment slots', Colors.white70),
          ],
        ],
      ),
    );
  }

  Widget _buildShieldBlock(Map<String, ArcBlueprintState> states) {
    final shieldOption = _optionForName(_shield);
    final shieldOwned = _isOwnedOrNotBlueprint(
      itemName: _shield,
      blueprintBased: shieldOption?.blueprintBased ?? false,
      states: states,
    );

    return _arcPanel(
      accent: Colors.lightGreenAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SHIELD', Colors.lightGreenAccent),
          const SizedBox(height: 10),
          _itemTile(
            label: _shield,
            subtitle: shieldOption?.blueprintBased == true && !shieldOwned
                ? 'Blueprint required'
                : 'Shield${_separator()}Ready',
            imageAsset: _assetForLoadoutItem(
              _shield,
              ArcLoadoutAssetKind.equipment,
            ),
            accent: Colors.amberAccent,
            owned: shieldOwned,
            onTap: _pickShield,
            imageSize: 58,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSlots(Map<String, ArcBlueprintState> states) {
    return _arcPanel(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionHeader('QUICK USE', Colors.amberAccent)),
              _planningPill('6 SLOTS', Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 330
                  ? 3
                  : constraints.maxWidth >= 220
                  ? 2
                  : 1;

              return GridView.builder(
                itemCount: ArcLoadoutLayoutEngine.quickUseSlotCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: columns == 1 ? 3.8 : 1.82,
                ),
                itemBuilder: (context, index) {
                  final item = index < _quickSlots.length
                      ? _quickSlots[index]
                      : ArcLoadoutLayoutEngine.emptySlot;
                  final option = ArcLoadoutLayoutEngine.quickUseOptionForName(
                    item,
                  );
                  final owned =
                      item == ArcLoadoutLayoutEngine.emptySlot ||
                      _isOwnedOrNotBlueprint(
                        itemName: item,
                        blueprintBased: option?.blueprintBased ?? false,
                        states: states,
                      );
                  return _quickUseCard(
                    index: index + 1,
                    label: item,
                    subtitle: option?.type.label ?? 'Open slot',
                    imageAsset: _assetForLoadoutItem(
                      item,
                      option == null
                          ? ArcLoadoutAssetKind.equipment
                          : _assetKindForOption(option),
                    ),
                    icon: _quickUseIcon(option),
                    owned: owned,
                    onTap: () => _pickQuickSlot(index),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartBuildIntegrationPanel(
    Map<String, ArcBlueprintState> states,
  ) {
    final plan = _activeSmartPlan!;
    final integration = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: states,
    );
    final missionSnapshot = ArcSmartBuildMissionEngine.build(
      plan: plan,
      blueprintStates: states,
    )!;
    final accent = integration.complete
        ? Colors.lightGreenAccent
        : Colors.amberAccent;

    return _arcPanel(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SMART BUILD PROGRESS', accent),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: integration.completionPercent / 100,
                      strokeWidth: 6,
                      color: accent,
                      backgroundColor: Colors.white12,
                    ),
                    Text(
                      '${integration.completionPercent}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      integration.nextMove,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                '${integration.missingBlueprints.length} Blueprint priorities',
                integration.missingBlueprints.isEmpty
                    ? Colors.lightGreenAccent
                    : AppTheme.neonPink,
              ),
              _pill(
                '${integration.missingResources.length} resource gaps',
                integration.missingResources.isEmpty
                    ? Colors.lightGreenAccent
                    : Colors.amberAccent,
              ),
              _pill(
                '${integration.tradeTemplate.components.length} trade requirements',
                AppTheme.neonCyan,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionHeader('MISSION BOARD', AppTheme.neonCyan),
          const SizedBox(height: 8),
          for (
            var index = 0;
            index < missionSnapshot.missions.take(5).length;
            index++
          )
            Builder(
              builder: (context) {
                final mission = missionSnapshot.missions[index];
                final missionColor = mission.completed
                    ? Colors.lightGreenAccent
                    : switch (mission.type) {
                        ArcSmartBuildMissionType.blueprintHunt =>
                          AppTheme.neonPink,
                        ArcSmartBuildMissionType.resourceGather =>
                          Colors.amberAccent,
                        ArcSmartBuildMissionType.tradeBundle =>
                          AppTheme.neonCyan,
                        ArcSmartBuildMissionType.craftAndEquip =>
                          Colors.lightGreenAccent,
                      };
                final missionIcon = switch (mission.type) {
                  ArcSmartBuildMissionType.blueprintHunt =>
                    Icons.my_location_rounded,
                  ArcSmartBuildMissionType.resourceGather =>
                    Icons.inventory_2_rounded,
                  ArcSmartBuildMissionType.tradeBundle =>
                    Icons.swap_horiz_rounded,
                  ArcSmartBuildMissionType.craftAndEquip =>
                    Icons.construction_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _statusLine(
                    icon: mission.completed
                        ? Icons.check_circle_rounded
                        : missionIcon,
                    label: '${index + 1}. ${mission.title}',
                    value: mission.detail,
                    color: missionColor,
                  ),
                );
              },
            ),
          if (missionSnapshot.missions.length > 5)
            Text(
              '+${missionSnapshot.missions.length - 5} more mission steps',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallAction(
                label: 'Regenerate',
                icon: Icons.refresh_rounded,
                color: Colors.amberAccent,
                onTap: () => _showSmartBuildGenerator(states),
              ),
              _smallAction(
                label: 'Blueprint Priorities',
                icon: Icons.grid_view_rounded,
                color: AppTheme.neonPink,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(BlueprintGridScreen.routeName),
              ),
              _smallAction(
                label: 'Open Trading',
                icon: Icons.swap_horiz_rounded,
                color: AppTheme.neonCyan,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(ArcSmartBuildTradeDraftScreen.routeName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentMaintenancePlan() {
    final shield = ArcLoadoutRepairCatalog.shieldFor(_shield);
    final primaryRepair = ArcLoadoutRepairCatalog.repairForWeapon(
      _primaryWeapon,
      tier: 4,
    );
    final secondaryRepair = ArcLoadoutRepairCatalog.repairForWeapon(
      _secondaryWeapon,
      tier: 4,
    );

    return _arcPanel(
      accent: Colors.lightGreenAccent,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 7),
          visualDensity: VisualDensity.compact,
          minTileHeight: 40,
          title: Text(
            'CRAFT + REPAIR INTELLIGENCE',
            style: AppTheme.tradingHeading(
              fontSize: 14,
              color: Colors.lightGreenAccent,
            ),
          ),
          subtitle: Text(
            '$_shield + Level IV weapon maintenance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 9.5),
          ),
          children: [
            const SizedBox(height: 7),
            if (shield != null) _buildShieldMaintenance(shield),
            if (shield != null) const SizedBox(height: 9),
            _buildWeaponRepairMaintenance(_primaryWeapon, primaryRepair),
            const SizedBox(height: 9),
            _buildWeaponRepairMaintenance(_secondaryWeapon, secondaryRepair),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldMaintenance(ArcShieldIntelligence shield) {
    final craftPlan = ArcItemIntelligenceEngine.planForItem(shield.name);
    final repairPlan = ArcItemIntelligenceEngine.planForRequirements(
      targetName: '${shield.name} repair',
      requirements: shield.repairRecipe,
    );
    final movement = shield.movementPenaltyPercent == 0
        ? 'no movement penalty'
        : '${shield.movementPenaltyPercent}% movement penalty';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.lightGreenAccent.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        border: Border.all(
          color: Colors.lightGreenAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shield.name.toUpperCase(),
            style: ArcUiTokens.label(color: Colors.lightGreenAccent),
          ),
          const SizedBox(height: 3),
          Text(
            '${shield.charge} charge - ${shield.damageReductionPercent}% damage reduction - $movement',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 7),
          _maintenanceLabel('CRAFT', Colors.lightGreenAccent),
          const SizedBox(height: 4),
          _materialPills(shield.craftRecipe, Colors.lightGreenAccent),
          const SizedBox(height: 6),
          _maintenanceLabel('CRAFT FROM SCRATCH', AppTheme.neonCyan),
          const SizedBox(height: 4),
          _materialPills(craftPlan.rawMaterials, AppTheme.neonCyan),
          const SizedBox(height: 7),
          _maintenanceLabel(
            'REPAIR +${shield.repairDurability}',
            Colors.amberAccent,
          ),
          const SizedBox(height: 4),
          _materialPills(shield.repairRecipe, Colors.amberAccent),
          const SizedBox(height: 6),
          _maintenanceLabel('REPAIR FROM SCRATCH', AppTheme.neonPink),
          const SizedBox(height: 4),
          _materialPills(repairPlan.rawMaterials, AppTheme.neonPink),
        ],
      ),
    );
  }

  Widget _buildWeaponRepairMaintenance(
    String weaponName,
    ArcVerifiedRepairRecipe? repair,
  ) {
    if (repair == null) {
      return _statusLine(
        icon: Icons.fact_check_outlined,
        label: '$weaponName IV Repair',
        value:
            'Repair recipe not yet verified. No material cost is being guessed.',
        color: Colors.amberAccent,
      );
    }

    final rollup = ArcItemIntelligenceEngine.planForRequirements(
      targetName: '$weaponName IV repair',
      requirements: repair.materials,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$weaponName IV REPAIR +${repair.durabilityRestored}',
            style: ArcUiTokens.label(color: Colors.amberAccent),
          ),
          const SizedBox(height: 5),
          _materialPills(repair.materials, Colors.amberAccent),
          const SizedBox(height: 6),
          _maintenanceLabel('FROM SCRATCH', AppTheme.neonCyan),
          const SizedBox(height: 4),
          _materialPills(rollup.rawMaterials, AppTheme.neonCyan),
        ],
      ),
    );
  }

  Widget _materialPills(Map<String, int> materials, Color color) {
    if (materials.isEmpty) {
      return Text(
        'No material recipe available.',
        style: TextStyle(color: color.withValues(alpha: 0.72), fontSize: 10),
      );
    }
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final entry in materials.entries)
          _planningPill(
            '${ArcItemIntelligenceEngine.itemName(entry.key)} x${entry.value}',
            color,
          ),
      ],
    );
  }

  Widget _maintenanceLabel(String label, Color color) {
    return Text(
      label,
      style: ArcUiTokens.label(color: color).copyWith(fontSize: 8.5),
    );
  }

  Widget _buildMissingBlueprints(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states);
    return _arcPanel(
      accent: AppTheme.neonPink,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 6),
          visualDensity: VisualDensity.compact,
          minTileHeight: 40,
          title: Text(
            'MISSING BLUEPRINTS',
            style: AppTheme.tradingHeading(
              fontSize: 14,
              color: AppTheme.neonPink,
            ),
          ),
          subtitle: Text(
            missing.isEmpty
                ? 'Loadout Blueprint requirements are ready'
                : '${missing.length} loadout Blueprint target${missing.length == 1 ? '' : 's'} missing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 9.5),
          ),
          children: [
            const SizedBox(height: 6),
            if (missing.isEmpty)
              _statusLine(
                icon: Icons.check_circle_rounded,
                label: 'Loadout ready',
                value:
                    'No blueprint-gated loadout items are currently missing.',
                color: Colors.lightGreenAccent,
              )
            else
              ...missing.map((item) {
                final unlockPlan = ArcBlueprintUnlockEngine.planForBlueprint(
                  item,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _statusLine(
                    icon: unlockPlan == null
                        ? Icons.lock_rounded
                        : Icons.account_tree_rounded,
                    label: item,
                    value: unlockPlan == null
                        ? 'Missing blueprint. Hunt, trade, Trial or source intel required.'
                        : 'Guaranteed quest reward: ${unlockPlan.shortSummary}',
                    color: unlockPlan == null
                        ? AppTheme.neonPink
                        : Colors.lightGreenAccent,
                  ),
                );
              }),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (missing
                    .map(ArcBlueprintUnlockEngine.planForBlueprint)
                    .whereType<ArcBlueprintUnlockPlan>()
                    .isNotEmpty)
                  _smallAction(
                    label: 'Quest Unlock Path',
                    icon: Icons.account_tree_rounded,
                    color: Colors.lightGreenAccent,
                    onTap: () {
                      final plan = missing
                          .map(ArcBlueprintUnlockEngine.planForBlueprint)
                          .whereType<ArcBlueprintUnlockPlan>()
                          .first;
                      Navigator.of(context).pushNamed(
                        ScrappyGridScreen.questRouteName,
                        arguments: <String, Object?>{
                          'questFocusId': plan.quest.id,
                          'sourceBlueprintName': plan.reward.blueprintName,
                        },
                      );
                    },
                  ),
                _smallAction(
                  label: 'Blueprint Grid',
                  icon: Icons.grid_view_rounded,
                  color: AppTheme.neonCyan,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(BlueprintGridScreen.routeName),
                ),
                _smallAction(
                  label: 'Community Intel',
                  icon: Icons.radar_rounded,
                  color: AppTheme.neonPink,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(ArcMarketIntelligenceScreen.routeName),
                ),
                _smallAction(
                  label: 'Find Components',
                  icon: Icons.route_rounded,
                  color: Colors.amberAccent,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(ArcRaidIntelligenceScreen.routeName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeBenchPanel(Map<String, ArcBlueprintState> states) {
    final primary = _weaponSpec(_primaryWeapon);
    final secondary = _weaponSpec(_secondaryWeapon);
    final craftable = [primary, secondary]
        .where((weapon) => weapon.craftable)
        .map(
          (weapon) => weapon.gunsmithLevel == null
              ? '${weapon.name}: craftable at Gunsmith bench'
              : '${weapon.name}: Gunsmith Level ${weapon.gunsmithLevel}',
        )
        .toList(growable: false);

    return _arcPanel(
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('TRADE + BENCH READINESS', AppTheme.neonCyan),
          const SizedBox(height: 10),
          _statusLine(
            icon: Icons.swap_horiz_rounded,
            label: 'Trade Assist',
            value: _missingBlueprintItems(states).isEmpty
                ? 'No missing blueprint targets from this loadout.'
                : 'Missing blueprint targets can feed Smart Trade Assist.',
            color: AppTheme.neonPink,
          ),
          const SizedBox(height: 8),
          _statusLine(
            icon: Icons.construction_rounded,
            label: 'Bench',
            value: craftable.isEmpty
                ? 'No bench-gated weapons selected.'
                : craftable.join(_separator()),
            color: Colors.amberAccent,
          ),
          const SizedBox(height: 8),
          _smallAction(
            label: 'Open Trading',
            icon: Icons.storefront_rounded,
            color: AppTheme.neonCyan,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ArcSmartBuildTradeDraftScreen.routeName),
          ),
        ],
      ),
    );
  }

  int _emptyAttachmentCount({
    required String weaponName,
    required List<String> attachments,
  }) {
    final slots = _weaponSpec(weaponName).slots;
    final slotCount = slots.length.clamp(0, 6).toInt();
    var empty = 0;
    for (var index = 0; index < slotCount; index++) {
      final value = index < attachments.length
          ? attachments[index]
          : 'Empty Slot';
      if (value == 'Empty Slot' || value.trim().isEmpty) {
        empty++;
      }
    }
    return empty;
  }

  Widget _buildBetaReadinessPanel(Map<String, ArcBlueprintState> states) {
    final missingBlueprints = _missingBlueprintItems(states).length;
    final emptyAttachments =
        _emptyAttachmentCount(
          weaponName: _primaryWeapon,
          attachments: _primaryAttachments,
        ) +
        _emptyAttachmentCount(
          weaponName: _secondaryWeapon,
          attachments: _secondaryAttachments,
        );
    final emptyQuickSlots = _quickSlots
        .where((slot) => slot == 'Empty Slot' || slot.trim().isEmpty)
        .length;
    final complete =
        missingBlueprints == 0 &&
        emptyAttachments == 0 &&
        emptyQuickSlots == 0 &&
        _augment.trim().isNotEmpty &&
        _shield.trim().isNotEmpty;
    final accent = complete ? Colors.lightGreenAccent : Colors.amberAccent;

    return _arcPanel(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('BETA READINESS CHECK', accent),
          const SizedBox(height: 10),
          _statusLine(
            icon: complete ? Icons.verified_rounded : Icons.fact_check_rounded,
            label: 'Loadout State',
            value: complete
                ? 'Complete and ready to save, test, and take into Closed Beta.'
                : 'Still safe to save, but has open planning slots or missing blueprints.',
            color: accent,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                missingBlueprints == 0
                    ? 'Blueprints ready'
                    : '$missingBlueprints missing blueprints',
                missingBlueprints == 0
                    ? Colors.lightGreenAccent
                    : AppTheme.neonPink,
              ),
              _pill(
                emptyAttachments == 0
                    ? 'Attachments filled'
                    : '$emptyAttachments attachment slots open',
                emptyAttachments == 0
                    ? Colors.lightGreenAccent
                    : Colors.amberAccent,
              ),
              _pill(
                emptyQuickSlots == 0
                    ? 'Quick slots filled'
                    : '$emptyQuickSlots quick slots open',
                emptyQuickSlots == 0
                    ? Colors.lightGreenAccent
                    : Colors.amberAccent,
              ),
              _pill(
                _augment.trim().isEmpty ? 'Augment open' : 'Augment: $_augment',
                _augment.trim().isEmpty
                    ? Colors.amberAccent
                    : Colors.lightGreenAccent,
              ),
              _pill('Shield: $_shield', Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceStrip(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states).length;
    final craftableCount = [
      _weaponSpec(_primaryWeapon),
      _weaponSpec(_secondaryWeapon),
    ].where((weapon) => weapon.craftable).length;

    return _arcPanel(
      accent: Colors.white70,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _pill(
            'Missing: $missing',
            missing == 0 ? Colors.lightGreenAccent : AppTheme.neonPink,
          ),
          _pill('Craftable: $craftableCount', Colors.amberAccent),
          _pill('Primary: $_primaryWeapon', AppTheme.neonCyan),
          _pill('Secondary: $_secondaryWeapon', AppTheme.neonPink),
          _pill('Style: ${_playStyle.shortLabel}', Colors.white70),
        ],
      ),
    );
  }

  List<String> _missingBlueprintItems(Map<String, ArcBlueprintState> states) {
    return ArcBlueprintLoadoutBridge.blueprintRequirementsFor(_draftLoadout())
        .where((item) => states[item.blueprintId]?.owned != true)
        .map((item) => item.itemName)
        .toSet()
        .toList(growable: false);
  }

  String _weaponSubtitle(ArcLoadoutWeaponSpec weapon) {
    final parts = <String>[weapon.category];
    if (weapon.craftable) {
      parts.add(
        weapon.gunsmithLevel == null
            ? 'Bench craftable'
            : 'Gunsmith L${weapon.gunsmithLevel}',
      );
    }
    return parts.join(_separator());
  }

  String _separator() => ' ${String.fromCharCode(0x2022)} ';

  Widget _planningPill(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ArcUiTokens.label(color: accent).copyWith(fontSize: 8.5),
      ),
    );
  }

  Widget _newBuildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.raised,
          accent: accent,
          radius: ArcUiTokens.radiusM,
          borderOpacity: 0.20,
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10.5,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accent.withValues(alpha: 0.78),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _arcPanel({
    required Color accent,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    bool electric = false,
  }) {
    return ElectricChargeBorder(
      active: electric,
      radius: 16,
      child: Container(
        padding: padding,
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.raised,
          accent: accent,
          radius: 16,
          borderOpacity: electric ? 0.34 : 0.20,
          glow: electric,
        ),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(String label, Color accent) {
    return Text(
      label,
      style: AppTheme.tradingHeading(fontSize: 16, color: accent),
    );
  }

  Widget _itemTile({
    required String label,
    required String subtitle,
    required String? imageAsset,
    required Color accent,
    required bool owned,
    required VoidCallback onTap,
    String? lockedLabel,
    double imageSize = 70,
  }) {
    final image = _itemImage(
      imageAsset: imageAsset,
      accent: accent,
      owned: owned,
      icon: owned ? Icons.inventory_2_rounded : Icons.lock_rounded,
      size: imageSize,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          border: Border.all(
            color: accent.withValues(alpha: owned ? 0.36 : 0.16),
          ),
        ),
        child: Row(
          children: [
            image,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(
                      fontSize: 16,
                      color: owned ? accent : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lockedLabel ?? subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned
                          ? Colors.white60
                          : AppTheme.neonPink.withValues(alpha: 0.86),
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: accent.withValues(alpha: 0.78),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickUseCard({
    required int index,
    required String label,
    required String subtitle,
    required String? imageAsset,
    required IconData icon,
    required bool owned,
    required VoidCallback onTap,
  }) {
    final empty = label == ArcLoadoutLayoutEngine.emptySlot;
    final accent = empty ? Colors.white70 : Colors.amberAccent;

    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: empty ? 0.16 : 0.22),
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          border: Border.all(
            color: accent.withValues(alpha: owned ? 0.26 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _itemImage(
                  imageAsset: imageAsset,
                  accent: accent,
                  owned: empty ? true : owned,
                  icon: empty ? Icons.add_rounded : icon,
                  size: 34,
                ),
                Positioned(
                  left: -2,
                  top: -2,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ArcUiTokens.background.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusXS),
                      border: Border.all(color: accent.withValues(alpha: 0.36)),
                    ),
                    child: Text(
                      '$index',
                      style: AppTheme.tradingHeading(
                        fontSize: 9,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empty ? 'OPEN' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: empty
                          ? Colors.white60
                          : owned
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 11,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empty
                        ? 'Slot'
                        : owned
                        ? subtitle
                        : 'Missing BP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned ? Colors.white54 : AppTheme.neonPink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentChip({
    required String label,
    required String slotLabel,
    required String? imageAsset,
    required Color accent,
    required bool owned,
    required String compatibilityLabel,
    required VoidCallback onTap,
  }) {
    final assigned = label != slotLabel && label != 'Empty Slot';
    final displayOwned = !assigned || owned;
    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: assigned ? 0.28 : 0.18),
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          border: Border.all(
            color: accent.withValues(alpha: assigned ? 0.40 : 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: _itemImage(
                imageAsset: imageAsset,
                accent: accent,
                owned: displayOwned,
                icon: assigned && !owned
                    ? Icons.lock_rounded
                    : assigned
                    ? Icons.construction_rounded
                    : Icons.add_circle_outline_rounded,
                size: 34,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slotLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.label(
                      color: accent.withValues(alpha: 0.78),
                    ).copyWith(fontSize: 8),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assigned ? label : 'Empty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.buttonTextStyle(
                      color: assigned
                          ? displayOwned
                                ? Colors.white
                                : Colors.white38
                          : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    compatibilityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: assigned && !owned
                          ? AppTheme.neonPink
                          : accent.withValues(alpha: 0.66),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemImage({
    required String? imageAsset,
    required Color accent,
    required bool owned,
    required IconData icon,
    double size = 70,
  }) {
    final child = imageAsset == null
        ? Icon(icon, color: owned ? accent : Colors.white30, size: 34)
        : Image.asset(
            imageAsset,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) =>
                Icon(icon, color: owned ? accent : Colors.white30, size: 34),
          );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(size <= 36 ? 9 : 12),
        border: Border.all(
          color: accent.withValues(alpha: owned ? 0.34 : 0.12),
        ),
      ),
      child: ColorFiltered(
        colorFilter: owned
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
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
                0.42,
                0,
              ]),
        child: child,
      ),
    );
  }

  Widget _statusLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.28,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(
        label,
        style: AppTheme.buttonTextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _smallAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ArcUiTokens.chipDecoration(color: color, selected: true),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.buttonTextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
