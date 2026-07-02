import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FavouriteLoadoutScreen extends StatefulWidget {
  const FavouriteLoadoutScreen({super.key});

  static const routeName = '/favourite-loadout';

  @override
  State<FavouriteLoadoutScreen> createState() => _FavouriteLoadoutScreenState();
}

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
  String _shield = 'Shield Level 2';
  String _primaryWeapon = 'Anvil';
  String _secondaryWeapon = 'Stitcher';
  final List<String> _primaryAttachments = <String>['Muzzle', 'Tech Mod'];
  final List<String> _secondaryAttachments = <String>[
    'Muzzle',
    'Underbarrel',
    'Stock',
  ];
  final List<String> _quickSlots = <String>[
    'Snap Hook',
    'Vita Shot',
    'Lure Grenade',
    'Empty Slot',
    'Empty Slot',
  ];

  bool _loadedSavedState = false;

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
    switch (label.trim().toLowerCase()) {
      case 'muzzle':
        return ArcAttachmentSlotType.muzzle;
      case 'shotgun muzzle':
      case 'shotgun choke':
        return ArcAttachmentSlotType.shotgunMuzzle;
      case 'underbarrel':
      case 'grip':
        return ArcAttachmentSlotType.underbarrel;
      case 'light magazine':
      case 'light mag':
        return ArcAttachmentSlotType.lightMagazine;
      case 'medium magazine':
      case 'medium mag':
      case 'magazine':
        return ArcAttachmentSlotType.mediumMagazine;
      case 'shotgun magazine':
      case 'shotgun mag':
        return ArcAttachmentSlotType.shotgunMagazine;
      case 'stock':
        return ArcAttachmentSlotType.stock;
      case 'barrel':
        return ArcAttachmentSlotType.barrel;
      case 'converter':
        return ArcAttachmentSlotType.converter;
      default:
        return ArcAttachmentSlotType.special;
    }
  }

  ArcLoadoutAttachmentSpec? _attachmentSpecForName(String name) {
    final normalised = _normalise(name);
    if (normalised.isEmpty || normalised == 'empty slot') return null;
    for (final attachment in ArcLoadoutSeedData.attachments) {
      if (_normalise(attachment.name) == normalised) return attachment;
    }
    return null;
  }

  List<ArcLoadoutAttachmentSpec> _attachmentsForSlot({
    required String weaponName,
    required String slotLabel,
  }) {
    final slotType = _slotTypeForLabel(slotLabel);
    return ArcLoadoutSeedData.attachments
        .where(
          (attachment) =>
              attachment.slotType == slotType &&
              attachment.supportsWeapon(weaponName),
        )
        .toList(growable: false);
  }

  ArcLoadoutOption? _optionForName(String name) {
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

  void _applySavedLoadout(ArcSavedLoadout loadout) {
    setState(() {
      _buildName = loadout.name;
      _playStyle = loadout.playStyle;
      _augment = loadout.augment;
      _primaryWeapon = loadout.primaryWeapon;
      _secondaryWeapon = loadout.secondaryWeapon;
      _primaryAttachments
        ..clear()
        ..addAll(loadout.primaryAttachments);
      _secondaryAttachments
        ..clear()
        ..addAll(loadout.secondaryAttachments);
      _quickSlots
        ..clear()
        ..addAll([...loadout.equipment, ...loadout.consumables]);
      while (_quickSlots.length < 5) {
        _quickSlots.add('Empty Slot');
      }
      if (_quickSlots.length > 5) {
        _quickSlots.removeRange(5, _quickSlots.length);
      }
    });
  }

  Future<void> _saveLoadout() async {
    final now = DateTime.now();
    final equipment = _quickSlots
        .where((slot) => slot != 'Empty Slot')
        .take(2)
        .toList(growable: false);
    final consumables = _quickSlots
        .where((slot) => slot != 'Empty Slot')
        .skip(2)
        .toList(growable: false);

    final loadout = ArcSavedLoadout(
      id: 'favourite-loadout',
      name: _buildName,
      category: ArcLoadoutCategory.saved,
      playStyle: _playStyle,
      augment: _augment,
      primaryWeapon: _primaryWeapon,
      primaryAttachments: List<String>.from(_primaryAttachments),
      secondaryWeapon: _secondaryWeapon,
      secondaryAttachments: List<String>.from(_secondaryAttachments),
      equipment: equipment,
      consumables: consumables,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _savedLoadoutRepository.saveLoadout(loadout);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Favourite loadout saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save loadout: $error')));
    }
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
        return '$availability • ${weapon.category} • ${weapon.role}';
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
    );

    if (selected == null) return;

    setState(() {
      final nextAttachments = List<String>.filled(
        selected.slots.length.clamp(1, 6).toInt(),
        'Empty Slot',
        growable: true,
      );
      if (primary) {
        _primaryWeapon = selected.name;
        _primaryAttachments
          ..clear()
          ..addAll(nextAttachments);
      } else {
        _secondaryWeapon = selected.name;
        _secondaryAttachments
          ..clear()
          ..addAll(nextAttachments);
      }
    });
  }

  Future<void> _pickAugment() async {
    final selected = await _showPicker<ArcLoadoutOption>(
      title: 'Select Augment',
      items: ArcLoadoutSeedData.augments,
      labelBuilder: (option) => option.name,
      subtitleBuilder: (option) => option.description,
      leadingBuilder: (option) => _itemImage(
        imageAsset: _assetForLoadoutItem(
          option.name,
          ArcLoadoutAssetKind.augment,
        ),
        accent: Colors.lightGreenAccent,
        owned: true,
        icon: Icons.health_and_safety_rounded,
      ),
    );
    if (selected == null) return;
    setState(() => _augment = selected.name);
  }

  Future<void> _pickShield() async {
    final options = ArcLoadoutSeedData.equipment
        .where((option) => option.name.toLowerCase().contains('shield'))
        .toList(growable: false);
    final fallback = options.isEmpty
        ? const <ArcLoadoutOption>[
            ArcLoadoutOption(
              name: 'Shield Level 1',
              type: ArcLoadoutSlotType.equipment,
              description: 'Starter shield target.',
              craftable: true,
            ),
            ArcLoadoutOption(
              name: 'Shield Level 2',
              type: ArcLoadoutSlotType.equipment,
              description: 'Balanced shield target.',
              craftable: true,
            ),
            ArcLoadoutOption(
              name: 'Shield Level 3',
              type: ArcLoadoutSlotType.equipment,
              description: 'High protection shield target.',
              craftable: true,
            ),
          ]
        : options;

    final selected = await _showPicker<ArcLoadoutOption>(
      title: 'Select Shield',
      items: fallback,
      labelBuilder: (option) => option.name,
      subtitleBuilder: (option) => option.description,
      leadingBuilder: (option) => _itemImage(
        imageAsset: _assetForLoadoutItem(
          option.name,
          ArcLoadoutAssetKind.equipment,
        ),
        accent: Colors.amberAccent,
        owned: true,
        icon: Icons.shield_rounded,
      ),
    );
    if (selected == null) return;
    setState(() => _shield = selected.name);
  }

  Future<void> _pickQuickSlot(int index) async {
    final options = <ArcLoadoutOption>[
      ...ArcLoadoutSeedData.equipment,
      ...ArcLoadoutSeedData.consumables,
      const ArcLoadoutOption(
        name: 'Empty Slot',
        type: ArcLoadoutSlotType.equipment,
        description: 'Leave this slot empty for now.',
      ),
    ];
    final selected = await _showPicker<ArcLoadoutOption>(
      title: 'Select Quick Slot ${index + 1}',
      items: options,
      labelBuilder: (option) => option.name,
      subtitleBuilder: (option) => option.description,
      leadingBuilder: (option) {
        final empty = option.name == 'Empty Slot';
        return _itemImage(
          imageAsset: _assetForLoadoutItem(
            option.name,
            _assetKindForOption(option),
          ),
          accent: empty ? Colors.white70 : Colors.amberAccent,
          owned: true,
          icon: empty
              ? Icons.remove_circle_outline_rounded
              : Icons.inventory_2_rounded,
        );
      },
    );
    if (selected == null) return;
    setState(() => _quickSlots[index] = selected.name);
  }

  Future<void> _pickAttachment({
    required bool primary,
    required int index,
  }) async {
    final weapon = _weaponSpec(primary ? _primaryWeapon : _secondaryWeapon);
    final currentList = primary ? _primaryAttachments : _secondaryAttachments;
    final slots = weapon.slots.isEmpty
        ? const <String>['Special']
        : weapon.slots;
    final slotLabel = index < slots.length ? slots[index] : slots.last;
    final options = _attachmentsForSlot(
      weaponName: weapon.name,
      slotLabel: slotLabel,
    );
    final empty = ArcLoadoutAttachmentSpec(
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
        return '${attachment.benchLabel} • ${attachment.effect} • ${attachment.materialSummary}';
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
            radius: 24,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.32),
                ),
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
                            style: AppTheme.tradingHeading(
                              fontSize: 20,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: leadingBuilder?.call(item),
                          title: Text(
                            labelBuilder(item),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            subtitleBuilder(item),
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.neonCyan,
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Loadout'),
      body: ArcRaidersScreenShell(
        useSafeArea: false,
        showAdBanner: true,
        child: SafeArea(
          child: StreamBuilder<List<ArcSavedLoadout>>(
            stream: _savedLoadoutRepository.watchSavedLoadouts(),
            builder: (context, savedSnapshot) {
              final saved = savedSnapshot.data ?? const <ArcSavedLoadout>[];
              if (!_loadedSavedState && saved.isNotEmpty) {
                _loadedSavedState = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _applySavedLoadout(saved.first);
                });
              }

              return StreamBuilder<Map<String, ArcBlueprintState>>(
                stream: _blueprintRepository.watchMyBlueprintStates(),
                builder: (context, stateSnapshot) {
                  final blueprintStates =
                      stateSnapshot.data ?? <String, ArcBlueprintState>{};
                  return ArcRaidersPageList(
                    maxWidth: 1180,
                    bottomPadding: 100,
                    children: [
                      _buildHero(blueprintStates),
                      const SizedBox(height: 10),
                      _buildLoadoutBoard(blueprintStates),
                      const SizedBox(height: 10),
                      _buildIntelligenceStrip(blueprintStates),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states);
    return _arcPanel(
      accent: AppTheme.neonCyan,
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
                  fontSize: compact ? 25 : 32,
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
              _pill('Balanced PvP/PvE', AppTheme.neonPink),
              _pill('${missing.length} missing', Colors.amberAccent),
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
        final desktop = constraints.maxWidth >= 900;
        final tablet = constraints.maxWidth >= 620;

        if (desktop) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWeaponSlot(true, states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShieldAugmentBlock(states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuickSlots(states)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWeaponSlot(false, states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMissingBlueprints(states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTradeBenchPanel(states)),
                ],
              ),
            ],
          );
        }

        if (tablet) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWeaponSlot(true, states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShieldAugmentBlock(states)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWeaponSlot(false, states)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuickSlots(states)),
                ],
              ),
              const SizedBox(height: 10),
              _buildMissingBlueprints(states),
              const SizedBox(height: 10),
              _buildTradeBenchPanel(states),
            ],
          );
        }

        return Column(
          children: [
            _buildShieldAugmentBlock(states),
            const SizedBox(height: 10),
            _buildWeaponSlot(true, states),
            const SizedBox(height: 10),
            _buildWeaponSlot(false, states),
            const SizedBox(height: 10),
            _buildQuickSlots(states),
            const SizedBox(height: 10),
            _buildMissingBlueprints(states),
            const SizedBox(height: 10),
            _buildTradeBenchPanel(states),
          ],
        );
      },
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
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(weapon.slots.length.clamp(1, 6).toInt(), (
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
              return _attachmentChip(
                label: label,
                slotLabel: slotLabel,
                imageAsset: _assetForLoadoutItem(
                  label,
                  ArcLoadoutAssetKind.attachment,
                  explicitAssetPath: attachment?.imageAssetPath,
                ),
                accent: accent,
                onTap: () => _pickAttachment(primary: primary, index: index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldAugmentBlock(Map<String, ArcBlueprintState> states) {
    final augmentOption = _optionForName(_augment);
    final shieldOption = _optionForName(_shield);
    final augmentOwned = _isOwnedOrNotBlueprint(
      itemName: _augment,
      blueprintBased: augmentOption?.blueprintBased ?? false,
      states: states,
    );
    final shieldOwned = _isOwnedOrNotBlueprint(
      itemName: _shield,
      blueprintBased: shieldOption?.blueprintBased ?? false,
      states: states,
    );

    return _arcPanel(
      accent: Colors.lightGreenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('AUGMENT + SHIELD', Colors.lightGreenAccent),
          const SizedBox(height: 10),
          _itemTile(
            label: _augment,
            subtitle: augmentOption?.description ?? 'Tap to choose augment.',
            imageAsset: _assetForLoadoutItem(
              _augment,
              ArcLoadoutAssetKind.augment,
            ),
            accent: Colors.lightGreenAccent,
            owned: augmentOwned,
            onTap: _pickAugment,
          ),
          const SizedBox(height: 8),
          _itemTile(
            label: _shield,
            subtitle: shieldOption?.description ?? 'Tap to choose shield.',
            imageAsset: _assetForLoadoutItem(
              _shield,
              ArcLoadoutAssetKind.equipment,
            ),
            accent: Colors.amberAccent,
            owned: shieldOwned,
            onTap: _pickShield,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSlots(Map<String, ArcBlueprintState> states) {
    return _arcPanel(
      accent: Colors.amberAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('QUICK SLOTS x5', Colors.amberAccent),
          const SizedBox(height: 10),
          ...List.generate(5, (index) {
            final item = _quickSlots[index];
            final option = _optionForName(item);
            final owned = _isOwnedOrNotBlueprint(
              itemName: item,
              blueprintBased: option?.blueprintBased ?? false,
              states: states,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
              child: _compactItemRow(
                index: index + 1,
                label: item,
                subtitle: option?.description ?? 'Tap to assign item.',
                imageAsset: _assetForLoadoutItem(
                  item,
                  option == null
                      ? ArcLoadoutAssetKind.equipment
                      : _assetKindForOption(option),
                ),
                accent: Colors.amberAccent,
                owned: item == 'Empty Slot' ? true : owned,
                onTap: () => _pickQuickSlot(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissingBlueprints(Map<String, ArcBlueprintState> states) {
    final missing = _missingBlueprintItems(states);
    return _arcPanel(
      accent: AppTheme.neonPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('MISSING BLUEPRINTS', AppTheme.neonPink),
          const SizedBox(height: 10),
          if (missing.isEmpty)
            _statusLine(
              icon: Icons.check_circle_rounded,
              label: 'Loadout ready',
              value: 'No blueprint-gated loadout items are currently missing.',
              color: Colors.lightGreenAccent,
            )
          else
            ...missing.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _statusLine(
                  icon: Icons.lock_rounded,
                  label: item,
                  value:
                      'Missing blueprint. Add to Hunt Targets or find trade.',
                  color: AppTheme.neonPink,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
            ],
          ),
        ],
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
                : craftable.join(' • '),
            color: Colors.amberAccent,
          ),
          const SizedBox(height: 8),
          _smallAction(
            label: 'Open Trading',
            icon: Icons.storefront_rounded,
            color: AppTheme.neonCyan,
            onTap: () =>
                Navigator.of(context).pushNamed(TraderHubScreen.routeName),
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
    final items = <String>[];
    void checkWeapon(String name) {
      final weapon = _weaponSpec(name);
      if (weapon.blueprintBased &&
          !_isOwnedOrNotBlueprint(
            itemName: name,
            blueprintBased: true,
            states: states,
          )) {
        items.add(name);
      }
    }

    void checkOption(String name) {
      final option = _optionForName(name);
      if ((option?.blueprintBased ?? false) &&
          !_isOwnedOrNotBlueprint(
            itemName: name,
            blueprintBased: true,
            states: states,
          )) {
        items.add(name);
      }
    }

    checkWeapon(_primaryWeapon);
    checkWeapon(_secondaryWeapon);
    checkOption(_augment);
    checkOption(_shield);
    for (final item in _quickSlots) {
      if (item != 'Empty Slot') checkOption(item);
    }
    return items.toSet().toList(growable: false);
  }

  String _weaponSubtitle(ArcLoadoutWeaponSpec weapon) {
    final parts = <String>[weapon.category, weapon.role];
    if (weapon.blueprintBased) parts.add('Blueprint required');
    if (weapon.craftable) {
      parts.add(
        weapon.gunsmithLevel == null
            ? 'Bench craftable'
            : 'Gunsmith L${weapon.gunsmithLevel}',
      );
    }
    return parts.join(' • ');
  }

  Widget _arcPanel({
    required Color accent,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return ElectricChargeBorder(
      active: true,
      radius: 22,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(String label, Color accent) {
    return Text(
      label,
      style: AppTheme.tradingHeading(fontSize: 18, color: accent),
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
  }) {
    final image = _itemImage(
      imageAsset: imageAsset,
      accent: accent,
      owned: owned,
      icon: owned ? Icons.inventory_2_rounded : Icons.lock_rounded,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(18),
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
                      fontSize: 18,
                      color: owned ? accent : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lockedLabel ?? subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned
                          ? Colors.white60
                          : AppTheme.neonPink.withValues(alpha: 0.86),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: accent.withValues(alpha: 0.78),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactItemRow({
    required int index,
    required String label,
    required String subtitle,
    required String? imageAsset,
    required Color accent,
    required bool owned,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: owned ? 0.26 : 0.12),
          ),
        ),
        child: Row(
          children: [
            _itemImage(
              imageAsset: imageAsset,
              accent: accent,
              owned: owned,
              icon: label == 'Empty Slot'
                  ? Icons.remove_circle_outline_rounded
                  : Icons.inventory_2_rounded,
              size: 42,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 18,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: AppTheme.tradingHeading(fontSize: 17, color: accent),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    owned ? subtitle : 'Missing blueprint',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: owned ? Colors.white54 : AppTheme.neonPink,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: accent.withValues(alpha: 0.72),
              size: 16,
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
    required VoidCallback onTap,
  }) {
    final assigned = label != slotLabel && label != 'Empty Slot';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: assigned ? 0.28 : 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: assigned ? 0.40 : 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: _itemImage(
                imageAsset: imageAsset,
                accent: accent,
                owned: assigned,
                icon: assigned
                    ? Icons.construction_rounded
                    : Icons.add_circle_outline_rounded,
                size: 44,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    assigned ? label : slotLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.buttonTextStyle(
                      color: assigned ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    assigned ? slotLabel : 'Tap to assign',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.78),
                      fontSize: 10,
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
        borderRadius: BorderRadius.circular(16),
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
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
