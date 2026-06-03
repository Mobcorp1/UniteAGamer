import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FavouriteLoadoutScreen extends StatefulWidget {
  const FavouriteLoadoutScreen({super.key});

  static const routeName = '/favourite-loadout';

  @override
  State<FavouriteLoadoutScreen> createState() => _FavouriteLoadoutScreenState();
}

class _FavouriteLoadoutScreenState extends State<FavouriteLoadoutScreen> {
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _saving = false;
  final Set<String> _ownedBlueprintNames = <String>{};

  String _primaryWeapon = 'Anvil';
  String _secondaryWeapon = 'Stitcher';
  String _fibreAugment = 'Safekeeper';
  String _quickUseOne = 'Wolfpack';
  String _quickUseTwo = 'Vita Shot';
  String _quickUseThree = 'Snap Hook';
  String _quickUseFour = 'Pulse Mine';

  double _primaryPriority = 10;
  double _secondaryPriority = 7;
  double _augmentPriority = 8;
  double _quickUsePriority = 5;

  final Map<String, String> _primaryMods = {};
  final Map<String, String> _secondaryMods = {};

  static const List<_WeaponSpec> _weapons = [
    _WeaponSpec(
      name: 'Kettle',
      category: 'Assault Rifle',
      ammo: 'Light Ammo',
      firingMode: 'Semi-Automatic',
      damage: '8.5',
      fireRate: '30',
      range: '42.8',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Rattler',
      category: 'Assault Rifle',
      ammo: 'Medium Ammo',
      firingMode: 'Fully-Automatic',
      damage: '9',
      fireRate: '33.3',
      range: '56.2',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Arpeggio',
      category: 'Assault Rifle',
      ammo: 'Medium Ammo',
      firingMode: '3-Round Burst',
      damage: '9.5',
      fireRate: '18.3',
      range: '55.9',
      slots: ['Muzzle', 'Underbarrel', 'Medium Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Tempest',
      category: 'Assault Rifle',
      ammo: 'Medium Ammo',
      firingMode: 'Fully-Automatic',
      damage: '10',
      fireRate: '36.7',
      range: '55.9',
      slots: ['Muzzle', 'Underbarrel', 'Medium Magazine'],
    ),
    _WeaponSpec(
      name: 'Bettina',
      category: 'Assault Rifle',
      ammo: 'Heavy Ammo',
      firingMode: 'Fully-Automatic',
      damage: '16',
      fireRate: '28.7',
      range: '52.3',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Ferro',
      category: 'Battle Rifle',
      ammo: 'Heavy Ammo',
      firingMode: 'Break-Action',
      damage: '40',
      fireRate: '6.6',
      range: '53.1',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Renegade',
      category: 'Battle Rifle',
      ammo: 'Medium Ammo',
      firingMode: 'Lever-Action',
      damage: '35',
      fireRate: '21',
      range: '68.8',
      slots: ['Muzzle', 'Medium Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Aphelion',
      category: 'Battle Rifle',
      ammo: 'Energy Clip',
      firingMode: '2-Round Burst',
      damage: '25',
      fireRate: '9',
      range: '76',
      slots: ['Underbarrel', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Stitcher',
      category: 'SMG',
      ammo: 'Light Ammo',
      firingMode: 'Fully-Automatic',
      damage: '6.5',
      fireRate: '45.3',
      range: '42.1',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Canto',
      category: 'SMG',
      ammo: 'Medium Ammo',
      firingMode: 'Fully-Automatic',
      damage: '6.5',
      fireRate: '56.7',
      range: '51',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Bobcat',
      category: 'SMG',
      ammo: 'Light Ammo',
      firingMode: 'Fully-Automatic',
      damage: '6',
      fireRate: '66.7',
      range: '44',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Il Toro',
      category: 'Shotgun',
      ammo: 'Shotgun Ammo',
      firingMode: 'Pump-Action',
      damage: '67.5',
      fireRate: '14',
      range: '20',
      slots: ['Shotgun Muzzle', 'Underbarrel', 'Shotgun Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Vulcano',
      category: 'Shotgun',
      ammo: 'Shotgun Ammo',
      firingMode: 'Semi-Automatic',
      damage: '49.5',
      fireRate: '26.3',
      range: '26',
      slots: ['Shotgun Muzzle', 'Underbarrel', 'Shotgun Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Dolabra',
      category: 'Shotgun',
      ammo: 'Energy Clip',
      firingMode: 'Semi-Automatic',
      damage: '50 / 40',
      fireRate: '?',
      range: '?',
      slots: [],
    ),
    _WeaponSpec(
      name: 'Hairpin',
      category: 'Pistol',
      ammo: 'Light Ammo',
      firingMode: 'Slide-Action',
      damage: '20',
      fireRate: '9',
      range: '38.6',
      slots: ['Light Magazine'],
    ),
    _WeaponSpec(
      name: 'Burletta',
      category: 'Pistol',
      ammo: 'Light Ammo',
      firingMode: 'Semi-Automatic',
      damage: '10',
      fireRate: '28',
      range: '41.7',
      slots: ['Muzzle', 'Light Magazine'],
    ),
    _WeaponSpec(
      name: 'Venator',
      category: 'Pistol',
      ammo: 'Medium Ammo',
      firingMode: 'Semi-Automatic',
      damage: '16',
      fireRate: '36.7',
      range: '48.4',
      slots: ['Underbarrel', 'Medium Magazine'],
    ),
    _WeaponSpec(
      name: 'Anvil',
      category: 'Hand Cannon',
      ammo: 'Heavy Ammo',
      firingMode: 'Single-Action',
      damage: '40',
      fireRate: '16.3',
      range: '50.2',
      slots: ['Muzzle', 'Tech Mod'],
    ),
    _WeaponSpec(
      name: 'Torrente',
      category: 'LMG',
      ammo: 'Medium Ammo',
      firingMode: 'Fully-Automatic',
      damage: '8',
      fireRate: '58.3',
      range: '49.9',
      slots: ['Muzzle', 'Medium Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Osprey',
      category: 'Sniper Rifle',
      ammo: 'Medium Ammo',
      firingMode: 'Bolt-Action',
      damage: '45',
      fireRate: '17.7',
      range: '80.3',
      slots: ['Muzzle', 'Underbarrel', 'Medium Magazine', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Jupiter',
      category: 'Sniper Rifle',
      ammo: 'Energy Clip',
      firingMode: 'Bolt-Action',
      damage: '60',
      fireRate: '7.7',
      range: '71.7',
      slots: [],
    ),
    _WeaponSpec(
      name: 'Rascal',
      category: 'Special',
      ammo: 'Launcher Ammo',
      firingMode: 'Break-Action',
      damage: '75',
      fireRate: '13.7',
      range: '28.3',
      slots: [],
    ),
    _WeaponSpec(
      name: 'Hullcracker',
      category: 'Special',
      ammo: 'Launcher Ammo',
      firingMode: 'Pump-Action',
      damage: '100',
      fireRate: '20.3',
      range: '38.9',
      slots: ['Underbarrel', 'Stock'],
    ),
    _WeaponSpec(
      name: 'Equalizer',
      category: 'Special',
      ammo: 'Energy Clip',
      firingMode: 'Fully-Automatic',
      damage: '8',
      fireRate: '33.3',
      range: '68.6',
      slots: [],
    ),
  ];

  static const Map<String, List<String>> _slotOptions = {
    'Muzzle': [
      'None',
      'Muzzle Brake',
      'Suppressor',
      'Heavy Suppressor',
      'Compensator',
    ],
    'Shotgun Muzzle': ['None', 'Shotgun Choke', 'Shotgun Compensator'],
    'Underbarrel': [
      'None',
      'Angled Grip',
      'Vertical Grip',
      'Tactical Grip',
      'Laser Pointer',
    ],
    'Light Magazine': [
      'None',
      'Light Extended Magazine',
      'Light Quickdraw Magazine',
    ],
    'Medium Magazine': [
      'None',
      'Medium Extended Magazine',
      'Medium Quickdraw Magazine',
    ],
    'Shotgun Magazine': [
      'None',
      'Shotgun Extended Magazine',
      'Shotgun Quickload Magazine',
    ],
    'Stock': ['None', 'Light Stock', 'Heavy Stock', 'Tactical Stock'],
    'Tech Mod': ['None', 'Tech Mod', 'Precision Tech Mod'],
  };

  static const List<String> _fibreAugments = [
    'None',
    'Safekeeper',
    'Survivor',
    'Mobility Augment',
    'Combat Augment',
    'Utility Augment',
  ];

  static const List<String> _quickUseItems = [
    'None',
    'Pulse Mine',
    'Crash Map',
    'White Flag',
    'Showstopper',
    'Vita Shot',
    'Seeker Grenade',
    'Wolfpack',
    'Vita Spray',
    'Light Stick - Blue',
    'Light Stick - Green',
    'Light Stick - Red',
    'Trailblazer',
    'Lure Grenade',
    'Fireworks Box',
    'Triggernade',
    'Blaze Grenade',
    'Snap Hook',
    'Light Gun Parts',
  ];

  _WeaponSpec get _primarySpec =>
      _weapons.firstWhere((weapon) => weapon.name == _primaryWeapon);

  _WeaponSpec get _secondarySpec =>
      _weapons.firstWhere((weapon) => weapon.name == _secondaryWeapon);

  @override
  void initState() {
    super.initState();
    _loadLoadout();
  }

  String _normaliseBlueprintName(String value) {
    return value.trim().toLowerCase();
  }

  bool _isOwned(String value) {
    if (value.trim().isEmpty || value == 'None') return true;
    return _ownedBlueprintNames.contains(_normaliseBlueprintName(value));
  }

  void _collectOwnedBlueprints(dynamic value) {
    if (value == null) return;

    if (value is String && value.trim().isNotEmpty) {
      _ownedBlueprintNames.add(_normaliseBlueprintName(value));
      return;
    }

    if (value is Iterable) {
      for (final item in value) {
        _collectOwnedBlueprints(item);
      }
      return;
    }

    if (value is Map) {
      final ownedFlag =
          value['owned'] == true ||
          value['isOwned'] == true ||
          value['unlocked'] == true ||
          value['found'] == true;

      final nameCandidate =
          value['name'] ??
          value['blueprintName'] ??
          value['displayName'] ??
          value['itemName'];

      if (ownedFlag &&
          nameCandidate is String &&
          nameCandidate.trim().isNotEmpty) {
        _ownedBlueprintNames.add(_normaliseBlueprintName(nameCandidate));
      }

      for (final entry in value.entries) {
        final key = entry.key?.toString() ?? '';
        final entryValue = entry.value;

        if (entryValue == true && key.trim().isNotEmpty) {
          _ownedBlueprintNames.add(_normaliseBlueprintName(key));
        } else {
          _collectOwnedBlueprints(entryValue);
        }
      }
    }
  }

  Future<void> _loadOwnedBlueprints(
    String uid,
    Map<String, dynamic>? userData,
  ) async {
    _ownedBlueprintNames.clear();

    _collectOwnedBlueprints(userData?['ownedBlueprints']);
    _collectOwnedBlueprints(userData?['blueprintOwnership']);
    _collectOwnedBlueprints(userData?['owned']);

    try {
      final ownershipDoc = await FirebaseFirestore.instance
          .collection('arc_blueprint_ownership')
          .doc(uid)
          .get();

      _collectOwnedBlueprints(ownershipDoc.data());
    } catch (_) {
      // Ownership sync remains non-blocking.
    }

    try {
      final ownershipRows = await FirebaseFirestore.instance
          .collection('arc_blueprint_ownership')
          .where('uid', isEqualTo: uid)
          .limit(250)
          .get();

      for (final row in ownershipRows.docs) {
        _collectOwnedBlueprints(row.data());
      }
    } catch (_) {
      // Some projects use doc(uid), some use row docs. Keep both safe.
    }
  }

  Future<void> _loadLoadout() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    await _loadOwnedBlueprints(user.uid, snapshot.data());
    final data = snapshot.data()?['favouriteLoadout'];

    if (data is Map<String, dynamic>) {
      final primary = data['primaryWeapon'];
      final secondary = data['secondaryWeapon'];
      final augment = data['fibreAugment'];
      final quickUse = data['quickUse'];
      final priorities = data['priorities'];
      final primaryMods = data['primaryMods'];
      final secondaryMods = data['secondaryMods'];

      setState(() {
        if (primary is String && _weaponNames.contains(primary)) {
          _primaryWeapon = primary;
        }
        if (secondary is String && _weaponNames.contains(secondary)) {
          _secondaryWeapon = secondary;
        }
        if (augment is String && _fibreAugments.contains(augment)) {
          _fibreAugment = augment;
        }
        if (quickUse is List) {
          final values = quickUse.whereType<String>().toList();
          if (values.isNotEmpty && _quickUseItems.contains(values[0])) {
            _quickUseOne = values[0];
          }
          if (values.length > 1 && _quickUseItems.contains(values[1])) {
            _quickUseTwo = values[1];
          }
          if (values.length > 2 && _quickUseItems.contains(values[2])) {
            _quickUseThree = values[2];
          }
          if (values.length > 3 && _quickUseItems.contains(values[3])) {
            _quickUseFour = values[3];
          }
        }
        if (priorities is Map<String, dynamic>) {
          _primaryPriority = _asDouble(priorities['primary'], _primaryPriority);
          _secondaryPriority = _asDouble(
            priorities['secondary'],
            _secondaryPriority,
          );
          _augmentPriority = _asDouble(priorities['augment'], _augmentPriority);
          _quickUsePriority = _asDouble(
            priorities['quickUse'],
            _quickUsePriority,
          );
        }
        if (primaryMods is Map) {
          _primaryMods
            ..clear()
            ..addAll(
              primaryMods.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
        }
        if (secondaryMods is Map) {
          _secondaryMods
            ..clear()
            ..addAll(
              secondaryMods.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
        }
        _loading = false;
      });
      return;
    }

    setState(() => _loading = false);
  }

  double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble().clamp(1, 10);
    return fallback;
  }

  List<String> get _weaponNames =>
      _weapons.map((weapon) => weapon.name).toList();

  List<Map<String, dynamic>> _buildBlueprintPriorityPayload(
    List<String> selectedBlueprints,
    List<String> wantedBlueprints,
  ) {
    final priorityMap = <String, int>{};

    void addPriority(String value, double priority) {
      if (value.trim().isEmpty || value == 'None') return;
      final current = priorityMap[value];
      final next = priority.round().clamp(1, 10);
      if (current == null || next > current) {
        priorityMap[value] = next;
      }
    }

    addPriority(_primaryWeapon, _primaryPriority);
    addPriority(_secondaryWeapon, _secondaryPriority);
    addPriority(_fibreAugment, _augmentPriority);

    for (final item in [
      _quickUseOne,
      _quickUseTwo,
      _quickUseThree,
      _quickUseFour,
    ]) {
      addPriority(item, _quickUsePriority);
    }

    for (final item in _primaryMods.values) {
      addPriority(item, _primaryPriority);
    }

    for (final item in _secondaryMods.values) {
      addPriority(item, _secondaryPriority);
    }

    final wantedSet = wantedBlueprints.toSet();

    return selectedBlueprints
        .where((value) => value.trim().isNotEmpty && value != 'None')
        .map(
          (value) => {
            'name': value,
            'priority': priorityMap[value] ?? 5,
            'owned': !wantedSet.contains(value),
            'wanted': wantedSet.contains(value),
            'source': 'favouriteLoadout',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        )
        .toList()
      ..sort((a, b) {
        final bPriority = (b['priority'] as int?) ?? 0;
        final aPriority = (a['priority'] as int?) ?? 0;
        return bPriority.compareTo(aPriority);
      });
  }

  List<Map<String, dynamic>> _buildTradeAssistPayload(
    List<Map<String, dynamic>> priorityPayload,
  ) {
    return priorityPayload
        .where((item) => item['wanted'] == true)
        .map(
          (item) => {
            'targetName': item['name'],
            'priority': item['priority'] ?? 5,
            'source': 'favouriteLoadout',
            'reason': 'Missing from favourite loadout',
            'suggestionType': 'wantedBlueprint',
            'status': 'open',
            'createdAt': FieldValue.serverTimestamp(),
          },
        )
        .toList();
  }

  Future<void> _saveLoadout() async {
    final user = _auth.currentUser;
    if (user == null || _saving) return;

    setState(() => _saving = true);

    final selectedBlueprints = <String>{
      _primaryWeapon,
      _secondaryWeapon,
      _fibreAugment,
      _quickUseOne,
      _quickUseTwo,
      _quickUseThree,
      _quickUseFour,
      ..._primaryMods.values.where((value) => value != 'None'),
      ..._secondaryMods.values.where((value) => value != 'None'),
    }.where((value) => value.trim().isNotEmpty && value != 'None').toList();

    final wantedBlueprints = selectedBlueprints
        .where((value) => !_isOwned(value))
        .toList();

    final blueprintPriorityPayload = _buildBlueprintPriorityPayload(
      selectedBlueprints,
      wantedBlueprints,
    );

    final tradeAssistPayload = _buildTradeAssistPayload(
      blueprintPriorityPayload,
    );

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'favouriteLoadout': {
        'primaryWeapon': _primaryWeapon,
        'secondaryWeapon': _secondaryWeapon,
        'primaryMods': _primaryMods,
        'secondaryMods': _secondaryMods,
        'fibreAugment': _fibreAugment,
        'quickUse': [_quickUseOne, _quickUseTwo, _quickUseThree, _quickUseFour],
        'priorities': {
          'primary': _primaryPriority.round(),
          'secondary': _secondaryPriority.round(),
          'augment': _augmentPriority.round(),
          'quickUse': _quickUsePriority.round(),
        },
        'selectedBlueprints': selectedBlueprints,
        'wantedBlueprints': wantedBlueprints,
        'missingBlueprints': wantedBlueprints,
        'syncToBlueprintTracker': true,
        'syncToTradeAssist': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'loadoutWantedBlueprints': wantedBlueprints,
      'loadoutBlueprintPriorities': blueprintPriorityPayload,
      'blueprintHuntPriorities': blueprintPriorityPayload,
      'tradeAssistWantedBlueprints': wantedBlueprints,
      'loadoutTradeAssistSuggestions': tradeAssistPayload,
      'smartTradeAssist': {
        'wantedBlueprints': wantedBlueprints,
        'suggestions': tradeAssistPayload,
        'source': 'favouriteLoadout',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wantedBlueprints.isEmpty
              ? 'Favourite loadout saved. All selected items appear owned.'
              : 'Favourite loadout saved. Missing items added to Trade Assist hooks.',
        ),
      ),
    );
  }

  void _resetModsForPrimary(String weapon) {
    _primaryMods.removeWhere((key, value) => !_primarySpec.slots.contains(key));
  }

  void _resetModsForSecondary(String weapon) {
    _secondaryMods.removeWhere(
      (key, value) => !_secondarySpec.slots.contains(key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.86),
        elevation: 0,
        title: Text(
          'Favourite Loadout',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoadoutBackdrop(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 14 : 24,
                          compact ? 16 : 24,
                          compact ? 14 : 24,
                          30,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeroIntro(
                                  onSave: _saveLoadout,
                                  saving: _saving,
                                ),
                                const SizedBox(height: 16),
                                if (compact)
                                  Column(
                                    children: [
                                      _weaponPanel(
                                        title: 'Primary Weapon',
                                        spec: _primarySpec,
                                        selected: _primaryWeapon,
                                        mods: _primaryMods,
                                        priority: _primaryPriority,
                                        onPriorityChanged: (value) => setState(
                                          () => _primaryPriority = value,
                                        ),
                                        onWeaponChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _primaryWeapon = value;
                                            _resetModsForPrimary(value);
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _weaponPanel(
                                        title: 'Secondary Weapon',
                                        spec: _secondarySpec,
                                        selected: _secondaryWeapon,
                                        mods: _secondaryMods,
                                        priority: _secondaryPriority,
                                        onPriorityChanged: (value) => setState(
                                          () => _secondaryPriority = value,
                                        ),
                                        onWeaponChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _secondaryWeapon = value;
                                            _resetModsForSecondary(value);
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _weaponPanel(
                                          title: 'Primary Weapon',
                                          spec: _primarySpec,
                                          selected: _primaryWeapon,
                                          mods: _primaryMods,
                                          priority: _primaryPriority,
                                          onPriorityChanged: (value) =>
                                              setState(
                                                () => _primaryPriority = value,
                                              ),
                                          onWeaponChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _primaryWeapon = value;
                                              _resetModsForPrimary(value);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _weaponPanel(
                                          title: 'Secondary Weapon',
                                          spec: _secondarySpec,
                                          selected: _secondaryWeapon,
                                          mods: _secondaryMods,
                                          priority: _secondaryPriority,
                                          onPriorityChanged: (value) =>
                                              setState(
                                                () =>
                                                    _secondaryPriority = value,
                                              ),
                                          onWeaponChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _secondaryWeapon = value;
                                              _resetModsForSecondary(value);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 14),
                                _supportPanel(compact),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _weaponPanel({
    required String title,
    required _WeaponSpec spec,
    required String selected,
    required Map<String, String> mods,
    required double priority,
    required ValueChanged<double> onPriorityChanged,
    required ValueChanged<String?> onWeaponChanged,
  }) {
    return _GlassPanel(
      title: title,
      icon: Icons.gps_fixed,
      accent: title.contains('Primary') ? AppTheme.neonPink : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown(
            label: 'Weapon',
            value: selected,
            items: _weaponNames,
            onChanged: onWeaponChanged,
          ),
          const SizedBox(height: 12),
          _WeaponStatStrip(spec: spec),
          const SizedBox(height: 14),
          if (spec.slots.isEmpty)
            _EmptySlotCard(text: '${spec.name} has no attachment slots.')
          else
            for (final slot in spec.slots) ...[
              _dropdown(
                label: slot,
                value: mods[slot] ?? 'None',
                items: _slotOptions[slot] ?? const ['None'],
                onChanged: (value) => setState(() {
                  mods[slot] = value ?? 'None';
                }),
              ),
              const SizedBox(height: 10),
            ],
          _prioritySlider(
            label: 'Hunt priority',
            value: priority,
            onChanged: onPriorityChanged,
          ),
        ],
      ),
    );
  }

  Widget _supportPanel(bool compact) {
    final augmentPanel = _GlassPanel(
      title: 'Fibre Augment',
      icon: Icons.all_inclusive_rounded,
      accent: Colors.lightGreenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown(
            label: 'Augment',
            value: _fibreAugment,
            items: _fibreAugments,
            onChanged: (value) => setState(() {
              _fibreAugment = value ?? _fibreAugment;
            }),
          ),
          const SizedBox(height: 12),
          _prioritySlider(
            label: 'Augment priority',
            value: _augmentPriority,
            onChanged: (value) => setState(() => _augmentPriority = value),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this for key rebuild targets like Safekeeper or Survivor after wipe/reset.',
            style: TextStyle(color: Colors.white60, height: 1.3),
          ),
        ],
      ),
    );

    final quickUsePanel = _GlassPanel(
      title: 'Quick Use / Utility',
      icon: Icons.bolt_rounded,
      accent: Colors.amberAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown(
            label: 'Quick Use 1',
            value: _quickUseOne,
            items: _quickUseItems,
            onChanged: (value) => setState(() {
              _quickUseOne = value ?? _quickUseOne;
            }),
          ),
          const SizedBox(height: 10),
          _dropdown(
            label: 'Quick Use 2',
            value: _quickUseTwo,
            items: _quickUseItems,
            onChanged: (value) => setState(() {
              _quickUseTwo = value ?? _quickUseTwo;
            }),
          ),
          const SizedBox(height: 10),
          _dropdown(
            label: 'Quick Use 3',
            value: _quickUseThree,
            items: _quickUseItems,
            onChanged: (value) => setState(() {
              _quickUseThree = value ?? _quickUseThree;
            }),
          ),
          const SizedBox(height: 10),
          _dropdown(
            label: 'Quick Use 4',
            value: _quickUseFour,
            items: _quickUseItems,
            onChanged: (value) => setState(() {
              _quickUseFour = value ?? _quickUseFour;
            }),
          ),
          const SizedBox(height: 12),
          _prioritySlider(
            label: 'Quick use priority',
            value: _quickUsePriority,
            onChanged: (value) => setState(() => _quickUsePriority = value),
          ),
        ],
      ),
    );

    if (compact) {
      return Column(
        children: [augmentPanel, const SizedBox(height: 14), quickUsePanel],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: augmentPanel),
        const SizedBox(width: 14),
        Expanded(child: quickUsePanel),
      ],
    );
  }

  Widget _ownedMissingChip(String item) {
    if (item == 'None') {
      return const SizedBox.shrink();
    }

    final owned = _isOwned(item);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (owned ? Colors.lightGreenAccent : AppTheme.neonPink).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (owned ? Colors.lightGreenAccent : AppTheme.neonPink)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            owned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: owned ? Colors.lightGreenAccent : AppTheme.neonPink,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              owned
                  ? ' appears owned in Blueprint Tracker.'
                  : ' appears missing and will be included in wanted hooks.',
              style: const TextStyle(color: Colors.white70, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          dropdownColor: AppTheme.cardBackgroundDeep,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppTheme.neonCyan.withValues(alpha: 0.34),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.neonPink,
                width: 1.5,
              ),
            ),
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
        _ownedMissingChip(safeValue),
      ],
    );
  }

  Widget _prioritySlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.round()}/10',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppTheme.neonPink,
            inactiveColor: Colors.white.withValues(alpha: 0.18),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.onSave, required this.saving});

  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      title: 'Loadout Intelligence',
      icon: Icons.inventory_2_outlined,
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set your favourite primary, secondary, fibre augment and quick-use tools. Owned items are marked, missing items are saved for Blueprint Tracker, Trade Assist and future wipe recovery planning.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sync_alt_rounded,
                  color: AppTheme.neonCyan,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Blueprint priority sync: saved loadout items feed hunt priorities, missing-item hooks and Trade Assist prep suggestions.',
                    style: TextStyle(color: Colors.white70, height: 1.28),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving...' : 'Save Favourite Loadout'),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.09), blurRadius: 22),
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
                  title,
                  style: AppTheme.tradingHeading(fontSize: 22, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WeaponStatStrip extends StatelessWidget {
  const _WeaponStatStrip({required this.spec});

  final _WeaponSpec spec;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Type', spec.category),
      ('Ammo', spec.ammo),
      ('Mode', spec.firingMode),
      ('DMG', spec.damage),
      ('Rate', spec.fireRate),
      ('Range', spec.range),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats
          .map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                '${entry.$1}: ${entry.$2}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white60)),
    );
  }
}

class _LoadoutBackdrop extends StatelessWidget {
  const _LoadoutBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const StaticWatermark(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.66)),
        const StaticWatermark(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.86),
                AppTheme.darkBackground.withValues(alpha: 0.26),
                Colors.black.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeaponSpec {
  const _WeaponSpec({
    required this.name,
    required this.category,
    required this.ammo,
    required this.firingMode,
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.slots,
  });

  final String name;
  final String category;
  final String ammo;
  final String firingMode;
  final String damage;
  final String fireRate;
  final String range;
  final List<String> slots;
}
