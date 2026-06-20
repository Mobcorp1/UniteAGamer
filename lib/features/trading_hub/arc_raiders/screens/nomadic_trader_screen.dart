import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import '../widgets/foundation/arc_bottom_action_dock.dart';
import '../widgets/arc_ad_banner_card.dart';
import '../widgets/arc_asset_thumbnail.dart';

class NomadicTraderScreen extends StatefulWidget {
  const NomadicTraderScreen({super.key});

  @override
  State<NomadicTraderScreen> createState() => _NomadicTraderScreenState();
}

class _NomadicTraderResource {
  const _NomadicTraderResource({
    required this.id,
    required this.name,
    required this.value,
    required this.highTier,
    required this.icon,
  });

  final String id;
  final String name;
  final int value;
  final bool highTier;
  final IconData icon;
}

class _NomadicGoal {
  const _NomadicGoal({
    required this.name,
    required this.target,
    required this.icon,
  });

  final String name;
  final int target;
  final IconData icon;
}

class _NomadicPurchaseRequirement {
  const _NomadicPurchaseRequirement({
    required this.id,
    required this.name,
    required this.requiredQty,
    required this.ownedQty,
    required this.isCustom,
  });

  final String id;
  final String name;
  final int requiredQty;
  final int ownedQty;
  final bool isCustom;

  int get remainingQty => math.max(0, requiredQty - ownedQty);
  double get progress =>
      requiredQty <= 0 ? 0 : (ownedQty / requiredQty).clamp(0, 1);

  _NomadicPurchaseRequirement copyWith({
    String? id,
    String? name,
    int? requiredQty,
    int? ownedQty,
    bool? isCustom,
  }) {
    return _NomadicPurchaseRequirement(
      id: id ?? this.id,
      name: name ?? this.name,
      requiredQty: requiredQty ?? this.requiredQty,
      ownedQty: ownedQty ?? this.ownedQty,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredQty': requiredQty,
      'ownedQty': ownedQty,
      'isCustom': isCustom,
    };
  }

  factory _NomadicPurchaseRequirement.fromJson(Map<String, dynamic> json) {
    return _NomadicPurchaseRequirement(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Custom Resource',
      requiredQty: (json['requiredQty'] as num?)?.toInt() ?? 1,
      ownedQty: (json['ownedQty'] as num?)?.toInt() ?? 0,
      isCustom: (json['isCustom'] as bool?) ?? true,
    );
  }
}

class _NomadicPurchase {
  const _NomadicPurchase({
    required this.id,
    required this.name,
    required this.requiredQty,
    required this.ownedQty,
    required this.isGalleryProject,
    required this.isCustom,
    this.requirements = const [],
  });

  final String id;
  final String name;
  final int requiredQty;
  final int ownedQty;
  final bool isGalleryProject;
  final bool isCustom;
  final List<_NomadicPurchaseRequirement> requirements;

  int get remainingQty => math.max(0, requiredQty - ownedQty);
  double get progress =>
      requiredQty <= 0 ? 0 : (ownedQty / requiredQty).clamp(0, 1);

  _NomadicPurchase copyWith({
    String? id,
    String? name,
    int? requiredQty,
    int? ownedQty,
    bool? isGalleryProject,
    bool? isCustom,
    List<_NomadicPurchaseRequirement>? requirements,
  }) {
    return _NomadicPurchase(
      id: id ?? this.id,
      name: name ?? this.name,
      requiredQty: requiredQty ?? this.requiredQty,
      ownedQty: ownedQty ?? this.ownedQty,
      isGalleryProject: isGalleryProject ?? this.isGalleryProject,
      isCustom: isCustom ?? this.isCustom,
      requirements: requirements ?? this.requirements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredQty': requiredQty,
      'ownedQty': ownedQty,
      'isGalleryProject': isGalleryProject,
      'isCustom': isCustom,
      'requirements': requirements
          .map((requirement) => requirement.toJson())
          .toList(),
    };
  }

  factory _NomadicPurchase.fromJson(Map<String, dynamic> json) {
    final decodedRequirements = json['requirements'];
    return _NomadicPurchase(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Custom Resource',
      requiredQty: (json['requiredQty'] as num?)?.toInt() ?? 1,
      ownedQty: (json['ownedQty'] as num?)?.toInt() ?? 0,
      isGalleryProject: (json['isGalleryProject'] as bool?) ?? false,
      isCustom: (json['isCustom'] as bool?) ?? true,
      requirements: decodedRequirements is List
          ? decodedRequirements
                .whereType<Map>()
                .map(
                  (item) => _NomadicPurchaseRequirement.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class _NomadicTraderScreenState extends State<NomadicTraderScreen> {
  static const _prefsPrefix = 'arc_nomadic_trader_';
  static const _heroAsset =
      'assets/arc_raiders/hero_cards/arc_nomadic_trader_hero.webp';

  static const _defaultGoals = <_NomadicGoal>[
    _NomadicGoal(
      name: 'Stash Expansion',
      target: 200000,
      icon: Icons.inventory_2_outlined,
    ),
    _NomadicGoal(
      name: 'Expedition Vault',
      target: 200000,
      icon: Icons.door_back_door_outlined,
    ),
    _NomadicGoal(
      name: 'Backpack Charm',
      target: 100000,
      icon: Icons.star_border_rounded,
    ),
    _NomadicGoal(
      name: 'Raider Tokens',
      target: 150000,
      icon: Icons.toll_outlined,
    ),
    _NomadicGoal(
      name: 'Cosmetic',
      target: 100000,
      icon: Icons.checkroom_outlined,
    ),
    _NomadicGoal(
      name: 'Emote',
      target: 100000,
      icon: Icons.emoji_emotions_outlined,
    ),
    _NomadicGoal(name: 'Quick Use', target: 100000, icon: Icons.bolt_outlined),
    _NomadicGoal(
      name: 'Recyclable',
      target: 100000,
      icon: Icons.recycling_rounded,
    ),
    _NomadicGoal(
      name: 'Blueprint',
      target: 100000,
      icon: Icons.article_outlined,
    ),
    _NomadicGoal(name: 'Weapon', target: 100000, icon: Icons.gps_fixed_rounded),
  ];

  static const _highTierResources = <_NomadicTraderResource>[
    _NomadicTraderResource(
      id: 'queen_reactor',
      name: 'Queen Reactor',
      value: 11000,
      highTier: true,
      icon: Icons.battery_charging_full_rounded,
    ),
    _NomadicTraderResource(
      id: 'matriarch_reactor',
      name: 'Matriarch Reactor',
      value: 11000,
      highTier: true,
      icon: Icons.battery_charging_full_rounded,
    ),
    _NomadicTraderResource(
      id: 'vaporizer_regulator',
      name: 'Vaporizer Regulator',
      value: 6000,
      highTier: true,
      icon: Icons.settings_input_component_rounded,
    ),
    _NomadicTraderResource(
      id: 'turbine_compressor',
      name: 'Turbine Compressor',
      value: 5000,
      highTier: true,
      icon: Icons.settings_applications_rounded,
    ),
    _NomadicTraderResource(
      id: 'assessor_matrix',
      name: 'Assessor Matrix',
      value: 5000,
      highTier: true,
      icon: Icons.grid_view_rounded,
    ),
    _NomadicTraderResource(
      id: 'rocketeer_driver',
      name: 'Rocketeer Driver',
      value: 3000,
      highTier: true,
      icon: Icons.rocket_launch_outlined,
    ),
    _NomadicTraderResource(
      id: 'bastion_cell',
      name: 'Bastion Cell',
      value: 3000,
      highTier: true,
      icon: Icons.inventory_2_rounded,
    ),
    _NomadicTraderResource(
      id: 'bombardier_cell',
      name: 'Bombardier Cell',
      value: 3000,
      highTier: true,
      icon: Icons.blur_circular_rounded,
    ),
    _NomadicTraderResource(
      id: 'leaper_pulse_unit',
      name: 'Leaper Pulse Unit',
      value: 3000,
      highTier: true,
      icon: Icons.sensors_rounded,
    ),
    _NomadicTraderResource(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: true,
      icon: Icons.article_outlined,
    ),
  ];

  static const _lowTierResources = <_NomadicTraderResource>[
    _NomadicTraderResource(
      id: 'shredder_gyro',
      name: 'Shredder Gyro',
      value: 2000,
      highTier: false,
      icon: Icons.track_changes_rounded,
    ),
    _NomadicTraderResource(
      id: 'sentinel_firing_core',
      name: 'Sentinel Firing Core',
      value: 2000,
      highTier: false,
      icon: Icons.adjust_rounded,
    ),
    _NomadicTraderResource(
      id: 'surveyor_vault',
      name: 'Surveyor Vault',
      value: 1000,
      highTier: false,
      icon: Icons.inventory_2_outlined,
    ),
    _NomadicTraderResource(
      id: 'snitch_scanner',
      name: 'Snitch Scanner',
      value: 1000,
      highTier: false,
      icon: Icons.radar_rounded,
    ),
    _NomadicTraderResource(
      id: 'hornet_driver',
      name: 'Hornet Driver',
      value: 1000,
      highTier: false,
      icon: Icons.bug_report_outlined,
    ),
    _NomadicTraderResource(
      id: 'firefly_burner',
      name: 'Firefly Burner',
      value: 1000,
      highTier: false,
      icon: Icons.local_fire_department_outlined,
    ),
    _NomadicTraderResource(
      id: 'damaged_leaper_pulse_unit',
      name: 'Damaged Leaper Pulse Unit',
      value: 1000,
      highTier: false,
      icon: Icons.sensors_off_rounded,
    ),
    _NomadicTraderResource(
      id: 'damaged_rocketeer_driver',
      name: 'Damaged Rocketeer Driver',
      value: 1000,
      highTier: false,
      icon: Icons.rocket_launch_outlined,
    ),
    _NomadicTraderResource(
      id: 'fireball_burner',
      name: 'Fireball Burner',
      value: 640,
      highTier: false,
      icon: Icons.local_fire_department_rounded,
    ),
    _NomadicTraderResource(
      id: 'damaged_hornet_driver',
      name: 'Damaged Hornet Driver',
      value: 640,
      highTier: false,
      icon: Icons.bug_report_rounded,
    ),
    _NomadicTraderResource(
      id: 'tick_pod',
      name: 'Tick Pod',
      value: 640,
      highTier: false,
      icon: Icons.trip_origin_rounded,
    ),
    _NomadicTraderResource(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: false,
      icon: Icons.article_outlined,
    ),
  ];

  static const _nomadicPurchaseSuggestions = <String>[
    'Industrial Magnet',
    'Number Plate',
    'Air Freshener',
    'ARC Thermal Lining',
    'Train Model',
    'Vintage Steering Wheel',
    'Spectrum Analyser',
    'Silver Tunic',
    'Teaspoon Set',
    'Vinyl Wristwatch',
    'Sextant',
    'Equatorial Sundial',
    'Metal Bracket',
    'ARC Performance Steel',
    'Teleron',
    'Elephant Obelisk',
    'Light Bulb',
    'ARC Coolant',
    'Colourful Shoes',
    'ARC Synthetic Resin',
    'Queen Reactor',
    'Matriarch Reactor',
    'Vaporizer Regulator',
    'Electrocore',
  ];
  final PageController _cardController = PageController(
    initialPage: 400,
    viewportFraction: 0.78,
  );
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _customTargetController = TextEditingController();
  final Map<String, int> _goalTargetOverrides = {};
  final List<_NomadicPurchase> _nomadicPurchases = [];

  String _goalName = 'Stash Expansion';
  bool _highTier = true;
  int _targetValue = 200000;
  int _activeCard = 0;
  bool _loaded = false;

  int _targetForGoal(_NomadicGoal goal) =>
      _goalTargetOverrides[goal.name] ?? goal.target;

  List<_NomadicTraderResource> get _resources =>
      _highTier ? _highTierResources : _lowTierResources;

  int get _currentValue {
    var total = 0;
    for (final resource in _resources) {
      final qty =
          int.tryParse(_controllers[resource.id]?.text.trim() ?? '') ?? 0;
      total += qty * resource.value;
    }
    return total;
  }

  int get _remainingValue => math.max(0, _targetValue - _currentValue);

  double get _progress =>
      _targetValue <= 0 ? 0 : (_currentValue / _targetValue).clamp(0, 1);

  @override
  void initState() {
    super.initState();
    for (final resource in [..._highTierResources, ..._lowTierResources]) {
      _controllers.putIfAbsent(resource.id, () => TextEditingController());
    }
    _loadSavedGoal();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _customTargetController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _goalName = prefs.getString('${_prefsPrefix}goal_name') ?? _goalName;
    _highTier = prefs.getBool('${_prefsPrefix}high_tier') ?? _highTier;
    _targetValue = prefs.getInt('${_prefsPrefix}target_value') ?? _targetValue;
    _customTargetController.text = _targetValue.toString();

    for (final resource in [..._highTierResources, ..._lowTierResources]) {
      final value = prefs.getInt('${_prefsPrefix}qty_${resource.id}') ?? 0;
      _controllers[resource.id]?.text = value == 0 ? '' : value.toString();
    }

    for (final goal in _defaultGoals) {
      final savedTarget = prefs.getInt(
        '${_prefsPrefix}goal_target_${goal.name}',
      );
      if (savedTarget != null && savedTarget > 0) {
        _goalTargetOverrides[goal.name] = savedTarget;
      }
    }

    final purchasesJson = prefs.getString('${_prefsPrefix}nomadic_purchases');
    _nomadicPurchases
      ..clear()
      ..addAll(_decodeNomadicPurchases(purchasesJson));
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsPrefix}goal_name', _goalName);
    await prefs.setBool('${_prefsPrefix}high_tier', _highTier);
    await prefs.setInt('${_prefsPrefix}target_value', _targetValue);
    await prefs.setInt('${_prefsPrefix}goal_target_$_goalName', _targetValue);

    for (final resource in [..._highTierResources, ..._lowTierResources]) {
      final qty =
          int.tryParse(_controllers[resource.id]?.text.trim() ?? '') ?? 0;
      await prefs.setInt('${_prefsPrefix}qty_${resource.id}', qty);
    }

    await prefs.setString(
      '${_prefsPrefix}nomadic_purchases',
      jsonEncode(
        _nomadicPurchases.map((purchase) => purchase.toJson()).toList(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nomadic Trader goal saved')));
  }

  void _setGoal(_NomadicGoal goal) {
    setState(() {
      _goalName = goal.name;
      final target = _targetForGoal(goal);
      _targetValue = target;
      _customTargetController.text = target.toString();
    });
  }

  List<_NomadicPurchase> _decodeNomadicPurchases(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                _NomadicPurchase.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveNomadicPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_prefsPrefix}nomadic_purchases',
      jsonEncode(
        _nomadicPurchases.map((purchase) => purchase.toJson()).toList(),
      ),
    );
  }

  Future<void> _upsertNomadicPurchase(_NomadicPurchase purchase) async {
    setState(() {
      final index = _nomadicPurchases.indexWhere(
        (item) => item.id == purchase.id,
      );
      if (index == -1) {
        _nomadicPurchases.add(purchase);
      } else {
        _nomadicPurchases[index] = purchase;
      }
    });
    await _saveNomadicPurchases();
  }

  Future<void> _deleteNomadicPurchase(String id) async {
    setState(() => _nomadicPurchases.removeWhere((item) => item.id == id));
    await _saveNomadicPurchases();
  }

  String _format(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  Color get _accent => const Color(0xFFFF8A00);

  TextStyle _labelStyle({Color? color, double size = 12}) {
    return TextStyle(
      color: color ?? Colors.white.withValues(alpha: 0.62),
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
  }

  TextStyle _valueStyle({Color? color, double size = 24}) {
    return TextStyle(
      color: color ?? Colors.white,
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
    );
  }

  Widget _frostedPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color? border,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (border ?? _accent).withValues(alpha: 0.48),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: (border ?? _accent).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _hero() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 5.25,
            child: Image.asset(
              _heroAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      _accent.withValues(alpha: 0.24),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.48),
                    AppTheme.darkBackground.withValues(alpha: 0.96),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Ermal goals, accepted ARC parts and trader progress.',
                  style: _labelStyle(color: _accent, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalPanel() {
    final percent = (_progress * 100).round();

    return _frostedPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _itemThumbnail(
                _goalName,
                fallbackIcon: Icons.inventory_2_outlined,
                color: _accent,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT GOAL', style: _labelStyle(color: _accent)),
                    const SizedBox(height: 4),
                    Text(_goalName.toUpperCase(), style: _valueStyle(size: 22)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _openGoalSheet,
                icon: Icon(Icons.swap_horiz_rounded, color: _accent),
                label: const Text('Change'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _metric('TARGET', _format(_targetValue), _accent),
              ),
              Expanded(
                child: _metric(
                  'COLLECTED',
                  _format(_currentValue),
                  AppTheme.neonCyan,
                ),
              ),
              Expanded(
                child: _metric(
                  'REMAINING',
                  _format(_remainingValue),
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 11,
              color: _accent,
              backgroundColor: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$percent% COMPLETE', style: _labelStyle(color: _accent)),
              const Spacer(),
              Text(
                '${_format(_remainingValue)} TO GO',
                style: _labelStyle(color: _accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(size: 11)),
        const SizedBox(height: 6),
        Text(value, style: _valueStyle(color: color, size: 20)),
      ],
    );
  }

  Widget _itemThumbnail(
    String itemName, {
    required IconData fallbackIcon,
    required Color color,
    double size = 42,
  }) {
    return ArcAssetThumbnail(
      assetPath: _itemAssetPathFromName(itemName),
      fallbackIcon: fallbackIcon,
      color: color,
      size: size,
      fit: BoxFit.cover,
    );
  }

  String _itemAssetPathFromName(String itemName) {
    return 'assets/arc_raiders/items/${_itemAssetSlug(itemName)}.webp';
  }

  String _itemAssetSlug(String itemName) => ArcItemAssetResolver.slug(itemName);

  Widget _carousel() {
    final cards = <Widget>[
      _inventoryPreviewCard(),
      _equivalentsCard(),
      _savedGoalsCard(),
      _nomadicPurchasesCard(),
    ];

    void goToCard(int delta) {
      final currentPage = _cardController.hasClients
          ? (_cardController.page ?? 400.0 + _activeCard).round()
          : 400 + _activeCard;
      _cardController.animateToPage(
        currentPage + delta,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    Widget arrowButton({required IconData icon, required VoidCallback? onTap}) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? 0.28 : 1,
        child: Material(
          color: Colors.black.withValues(alpha: 0.38),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: AppTheme.neonPink, size: 34),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showArrows = constraints.maxWidth >= 720;
        final carouselWidth = constraints.maxWidth >= 1180
            ? 880.0
            : math.max(320.0, constraints.maxWidth);
        final carouselHeight = constraints.maxWidth >= 720 ? 390.0 : 372.0;

        final pager = SizedBox(
          width: carouselWidth,
          height: carouselHeight,
          child: PageView.builder(
            controller: _cardController,
            clipBehavior: Clip.none,
            padEnds: true,
            onPageChanged: (index) =>
                setState(() => _activeCard = index % cards.length),

            itemBuilder: (context, index) {
              final logicalIndex = index % cards.length;
              final selected = logicalIndex == _activeCard;
              return AnimatedScale(
                duration: const Duration(milliseconds: 220),
                scale: selected ? 1 : 0.92,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: selected ? 1 : 0.72,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.fromLTRB(
                      logicalIndex == 0 ? 0 : 8,
                      selected ? 0 : 18,
                      logicalIndex == cards.length - 1 ? 0 : 8,
                      selected ? 0 : 18,
                    ),
                    child: cards[logicalIndex],
                  ),
                ),
              );
            },
          ),
        );

        return Column(
          children: [
            if (showArrows)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  arrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => goToCard(-1),
                  ),
                  const SizedBox(width: 12),
                  pager,
                  const SizedBox(width: 12),
                  arrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => goToCard(1),
                  ),
                ],
              )
            else
              pager,
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < cards.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _activeCard == i ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _activeCard == i
                          ? _accent
                          : Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _valueStyle(size: 19)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalBarrel<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    double itemExtent = 86,
    double height = 210,
    String emptyLabel = 'No items tracked yet',
    Color? accent,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: _labelStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    final wheelAccent = accent ?? _accent;
    final controller = FixedExtentScrollController();
    var activeIndex = 0;

    return StatefulBuilder(
      builder: (context, setBarrelState) {
        void move(int delta) {
          final currentItem = controller.hasClients
              ? controller.selectedItem
              : items.length * 200 + activeIndex;
          final target = currentItem + delta;
          controller.animateToItem(
            target,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
          setBarrelState(() => activeIndex = target % items.length);
        }

        Widget verticalArrow(IconData icon, int delta) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: 1,
            child: Material(
              color: Colors.black.withValues(alpha: 0.34),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: items.length <= 1 ? null : () => move(delta),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: AppTheme.neonPink, size: 28),
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final showArrows = constraints.maxWidth >= 640 && items.length > 1;
            final wheel = SizedBox(
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.34),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.34),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: itemExtent + 8,
                      decoration: BoxDecoration(
                        color: wheelAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: wheelAccent.withValues(alpha: 0.34),
                        ),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: itemExtent,
                    diameterRatio: 1.55,
                    perspective: 0.0035,
                    physics: const FixedExtentScrollPhysics(),
                    overAndUnderCenterOpacity: 0.42,
                    onSelectedItemChanged: (index) {
                      setBarrelState(() => activeIndex = index % items.length);
                    },
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          Builder(
                            builder: (context) {
                              final selected = index == activeIndex;
                              return AnimatedScale(
                                duration: const Duration(milliseconds: 160),
                                scale: selected ? 1 : 0.92,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 160),
                                  opacity: selected ? 1 : 0.68,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: itemBuilder(items[index], index),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (!showArrows) return wheel;

            return Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    verticalArrow(Icons.keyboard_arrow_up_rounded, -1),
                    const SizedBox(height: 10),
                    verticalArrow(Icons.keyboard_arrow_down_rounded, 1),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(child: wheel),
              ],
            );
          },
        );
      },
    );
  }

  Widget _inventoryPreviewCard() {
    final visible = _resources;

    return _frostedPanel(
      border: _activeCard == 0 ? _accent : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            Icons.inventory_2_outlined,
            'Inventory',
            _highTier ? 'High Tier ARC Parts' : 'Low / Mid Tier ARC Parts',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _tierButton(
                  'High Tier',
                  _highTier,
                  () => setState(() => _highTier = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tierButton(
                  'Low / Mid',
                  !_highTier,
                  () => setState(() => _highTier = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _verticalBarrel<_NomadicTraderResource>(
              items: visible,
              itemExtent: 78,
              height: 205,
              emptyLabel: 'No inventory resources available',
              itemBuilder: (resource, index) => _compactResourceRow(resource),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openInventorySheet,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Manage Inventory'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _labelStyle(color: selected ? _accent : Colors.white70),
        ),
      ),
    );
  }

  Widget _compactResourceRow(_NomadicTraderResource resource) {
    final controller = _controllers[resource.id]!;

    return Row(
      children: [
        _itemThumbnail(
          resource.name,
          fallbackIcon: resource.icon,
          color: resource.highTier ? _accent : AppTheme.neonCyan,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Value ${_format(resource.value)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 68,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: _valueStyle(size: 18, color: _accent),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _equivalentsCard() {
    final remaining = _remainingValue;
    final equivalents = [
      _equivalentTile(
        Icons.battery_charging_full_rounded,
        'Queen Reactors',
        11000,
        remaining,
        _accent,
      ),
      _equivalentTile(
        Icons.article_outlined,
        'Blueprints',
        5000,
        remaining,
        AppTheme.neonCyan,
      ),
      _equivalentTile(
        Icons.blur_circular_rounded,
        'Bombardier Cells',
        3000,
        remaining,
        Colors.lightGreenAccent,
      ),
      _equivalentTile(
        Icons.track_changes_rounded,
        'Shredder Gyros',
        2000,
        remaining,
        _accent,
      ),
    ];

    return _frostedPanel(
      border: _activeCard == 1 ? _accent : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            Icons.balance_rounded,
            'Equivalents',
            'See what your remaining value equals',
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text('REMAINING VALUE', style: _labelStyle()),
                const SizedBox(height: 6),
                Text(
                  _format(remaining),
                  style: _valueStyle(color: _accent, size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _verticalBarrel<Widget>(
              items: equivalents,
              itemExtent: 74,
              height: 220,
              emptyLabel: 'No equivalent values available',
              itemBuilder: (item, index) => item,
            ),
          ),
        ],
      ),
    );
  }

  Widget _equivalentTile(
    IconData icon,
    String label,
    int value,
    int remaining,
    Color color,
  ) {
    final count = remaining == 0 ? 0 : (remaining / value).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          _itemThumbnail(label, fallbackIcon: icon, color: color),
          const SizedBox(width: 12),
          Text('$count', style: _valueStyle(size: 25)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedGoalsCard() {
    return _frostedPanel(
      border: _activeCard == 2 ? _accent : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _sectionTitle(
                  Icons.star_rounded,
                  'Saved Goals',
                  'Priority progress only',
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _saveGoal,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Complete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(color: _accent.withValues(alpha: 0.75)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _verticalBarrel<_NomadicGoal>(
              items: _defaultGoals,
              itemExtent: 104,
              height: 238,
              emptyLabel: 'No saved goals available',
              itemBuilder: (goal, index) {
                final selected = goal.name == _goalName;
                final target = _targetForGoal(goal);
                final progress = selected && target > 0
                    ? (_currentValue / target).clamp(0.0, 1.0)
                    : 0.0;
                return InkWell(
                  onTap: () => _setGoal(goal),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accent.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? _accent.withValues(alpha: 0.72)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: _accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: _labelStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _itemThumbnail(
                          goal.name,
                          fallbackIcon: goal.icon,
                          color: selected ? _accent : Colors.white54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                goal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selected
                                    ? 'Target ${_format(target)}'
                                    : 'Waiting for priority slot',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  color: selected ? _accent : Colors.white54,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _openGoalSheet,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Manage Goals'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nomadicPurchasesCard() {
    final totalRequired = _nomadicPurchases.fold<int>(
      0,
      (total, item) => total + item.requiredQty,
    );
    final totalOwned = _nomadicPurchases.fold<int>(
      0,
      (total, item) => total + item.ownedQty,
    );

    return _frostedPanel(
      border: _activeCard == 3 ? _accent : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            Icons.shopping_bag_outlined,
            'Nomadic Purchases',
            'Gallery and personal progress',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStatTile('OWNED', '$totalOwned', AppTheme.neonCyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatTile('REQUIRED', '$totalRequired', _accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatTile(
                  'GALLERY',
                  '${_nomadicPurchases.where((item) => item.isGalleryProject).length}',
                  AppTheme.neonPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _nomadicPurchases.isEmpty
                ? _emptyNomadicPurchases()
                : _verticalBarrel<_NomadicPurchase>(
                    items: _nomadicPurchases,
                    itemExtent: 148,
                    height: 225,
                    emptyLabel: 'No purchases tracked yet',
                    itemBuilder: (purchase, index) =>
                        _nomadicPurchaseRow(purchase),
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openNomadicPurchaseSheet(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Purchase Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: [
          Text(label, style: _labelStyle(size: 10, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value, style: _valueStyle(size: 18, color: color)),
        ],
      ),
    );
  }

  Widget _emptyNomadicPurchases() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SELECTED PURCHASE',
            style: _labelStyle(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'No purchase selected',
            style: _valueStyle(size: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _nomadicPurchaseRow(_NomadicPurchase purchase) {
    return InkWell(
      onTap: () => _openNomadicPurchaseSheet(existing: purchase),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _itemThumbnail(
                  purchase.name,
                  fallbackIcon: purchase.isGalleryProject
                      ? Icons.collections_bookmark_outlined
                      : Icons.shopping_bag_outlined,
                  color: purchase.isGalleryProject
                      ? AppTheme.neonPink
                      : _accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purchase.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${purchase.ownedQty}/${purchase.requiredQty}',
                  style: _valueStyle(size: 18, color: _accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: purchase.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  purchase.isGalleryProject ? AppTheme.neonPink : _accent,
                ),
              ),
            ),
            if (purchase.requirements.isNotEmpty) ...[
              const SizedBox(height: 8),
              _purchaseRequirementsPreview(purchase),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (purchase.isCustom) _tagPill('Custom', AppTheme.neonCyan),
                if (purchase.isGalleryProject) ...[
                  if (purchase.isCustom) const SizedBox(width: 8),
                  _tagPill('Gallery Project', AppTheme.neonPink),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Decrease owned',
                  onPressed: purchase.ownedQty <= 0
                      ? null
                      : () => _upsertNomadicPurchase(
                          purchase.copyWith(
                            ownedQty: math.max(0, purchase.ownedQty - 1),
                          ),
                        ),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: Colors.white70,
                ),
                IconButton(
                  tooltip: 'Increase owned',
                  onPressed: () => _upsertNomadicPurchase(
                    purchase.copyWith(ownedQty: purchase.ownedQty + 1),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: _accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _requirementStatusLabel(_NomadicPurchaseRequirement requirement) {
    if (requirement.remainingQty > 0) {
      return 'Hunt Target Ready';
    }
    if (requirement.ownedQty > requirement.requiredQty) {
      return 'Trade Assist Ready';
    }
    return 'Complete';
  }

  Color _requirementStatusColor(_NomadicPurchaseRequirement requirement) {
    if (requirement.remainingQty > 0) {
      return AppTheme.neonCyan;
    }
    if (requirement.ownedQty > requirement.requiredQty) {
      return AppTheme.neonPink;
    }
    return Colors.lightGreenAccent;
  }

  Widget _purchaseRequirementsPreview(_NomadicPurchase purchase) {
    final visible = purchase.requirements.take(2).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchase Requirements', style: _labelStyle(size: 10)),
          const SizedBox(height: 6),
          for (final requirement in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  _itemThumbnail(
                    requirement.name,
                    fallbackIcon: Icons.construction_rounded,
                    color: _requirementStatusColor(requirement),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requirement.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('/', style: _labelStyle(color: _accent, size: 12)),
                      Text(
                        _requirementStatusLabel(requirement),
                        style: _labelStyle(
                          color: _requirementStatusColor(requirement),
                          size: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (purchase.requirements.length > visible.length)
            Text(
              '+${purchase.requirements.length - visible.length} more',
              style: _labelStyle(color: AppTheme.neonCyan, size: 11),
            ),
        ],
      ),
    );
  }

  Widget _tagPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(label, style: _labelStyle(size: 10, color: color)),
    );
  }

  Future<void> _openNomadicPurchaseSheet({_NomadicPurchase? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final requiredController = TextEditingController(
      text: (existing?.requiredQty ?? 1).toString(),
    );
    final ownedController = TextEditingController(
      text: (existing?.ownedQty ?? 0).toString(),
    );
    final requirementNameController = TextEditingController();
    final requirementRequiredController = TextEditingController(text: '1');
    final requirementOwnedController = TextEditingController(text: '0');

    var isGalleryProject = existing?.isGalleryProject ?? false;
    var isCustom = existing?.isCustom ?? true;
    var requirementIsCustom = true;
    var selectedSuggestion =
        _nomadicPurchaseSuggestions.contains(existing?.name)
        ? existing?.name
        : null;
    String? selectedRequirementSuggestion;
    final requirements = <_NomadicPurchaseRequirement>[
      ...?existing?.requirements,
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          void addRequirement() {
            final name = requirementNameController.text.trim();
            final requiredQty =
                int.tryParse(requirementRequiredController.text.trim()) ?? 0;
            final ownedQty =
                int.tryParse(requirementOwnedController.text.trim()) ?? 0;

            if (name.isEmpty || requiredQty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add requirement name and required quantity'),
                ),
              );
              return;
            }

            setSheetState(() {
              requirements.add(
                _NomadicPurchaseRequirement(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  requiredQty: requiredQty,
                  ownedQty: math.max(0, ownedQty),
                  isCustom: requirementIsCustom,
                ),
              );
              requirementNameController.clear();
              requirementRequiredController.text = '1';
              requirementOwnedController.text = '0';
              selectedRequirementSuggestion = null;
              requirementIsCustom = true;
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 14),
                  _sectionTitle(
                    Icons.shopping_bag_outlined,
                    existing == null
                        ? 'Add Nomadic Purchase'
                        : 'Edit Nomadic Purchase',
                    'Track items bought from the Nomadic Trader',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _tierButton('Existing Item', !isCustom, () {
                          setSheetState(() => isCustom = false);
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tierButton('Custom Item', isCustom, () {
                          setSheetState(() => isCustom = true);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isCustom)
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Purchase item name',
                        hintText: 'Train Model, Vintage Steering Wheel...',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedSuggestion,
                      dropdownColor: AppTheme.cardBackground,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Purchase item',
                      ),
                      items: [
                        for (final item in _nomadicPurchaseSuggestions)
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedSuggestion = value;
                          nameController.text = value;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: requiredController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Required qty',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ownedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Owned qty',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    Icons.construction_rounded,
                    'Purchase Requirements',
                    'Add each required resource, quantity needed, and owned amount',
                  ),
                  const SizedBox(height: 12),
                  for (final requirement in requirements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.045),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                requirement.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${requirement.ownedQty}/${requirement.requiredQty}',
                              style: _labelStyle(color: _accent),
                            ),
                            IconButton(
                              onPressed: () {
                                setSheetState(() {
                                  requirements.removeWhere(
                                    (item) => item.id == requirement.id,
                                  );
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _tierButton(
                          'Existing Req',
                          !requirementIsCustom,
                          () {
                            setSheetState(() => requirementIsCustom = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tierButton(
                          'Custom Req',
                          requirementIsCustom,
                          () {
                            setSheetState(() => requirementIsCustom = true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (requirementIsCustom)
                    TextField(
                      controller: requirementNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Requirement name',
                        hintText: 'Industrial Magnet, Number Plate...',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedRequirementSuggestion,
                      dropdownColor: AppTheme.cardBackground,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Requirement item',
                      ),
                      items: [
                        for (final item in _nomadicPurchaseSuggestions)
                          DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedRequirementSuggestion = value;
                          requirementNameController.text = value;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: requirementRequiredController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Required qty',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: requirementOwnedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Owned qty',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: addRequirement,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Requirement'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonCyan,
                      side: BorderSide(
                        color: AppTheme.neonCyan.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isGalleryProject,
                    onChanged: (value) =>
                        setSheetState(() => isGalleryProject = value),
                    activeThumbColor: AppTheme.neonPink,
                    title: const Text(
                      'Required for Gallery Project',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      'Can later feed the Projects/Gallery tracker.',
                      style: _labelStyle(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (existing != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteNomadicPurchase(existing.id);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      if (existing != null) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final requiredQty =
                                int.tryParse(requiredController.text.trim()) ??
                                0;
                            final ownedQty =
                                int.tryParse(ownedController.text.trim()) ?? 0;

                            if (name.isEmpty || requiredQty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Add an item name and required quantity',
                                  ),
                                ),
                              );
                              return;
                            }

                            final purchase = _NomadicPurchase(
                              id:
                                  existing?.id ??
                                  DateTime.now().microsecondsSinceEpoch
                                      .toString(),
                              name: name,
                              requiredQty: requiredQty,
                              ownedQty: math.max(0, ownedQty),
                              isGalleryProject: isGalleryProject,
                              isCustom: isCustom,
                              requirements: requirements,
                            );

                            Navigator.pop(context);
                            _upsertNomadicPurchase(purchase);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Item'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    requiredController.dispose();
    ownedController.dispose();
    requirementNameController.dispose();
    requirementRequiredController.dispose();
    requirementOwnedController.dispose();
  }

  Future<void> _openGoalSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.48,
          maxChildSize: 0.94,
          builder: (context, scrollController) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                _sectionTitle(
                  Icons.star_rounded,
                  'Manage Goals',
                  'Pick this weeks top priority',
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final goal in _defaultGoals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              _setGoal(goal);
                              Navigator.pop(context);
                            },
                            tileColor: goal.name == _goalName
                                ? _accent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: goal.name == _goalName
                                    ? _accent.withValues(alpha: 0.72)
                                    : Colors.white.withValues(alpha: 0.09),
                              ),
                            ),
                            leading: _itemThumbnail(
                              goal.name,
                              fallbackIcon: goal.icon,
                              color: goal.name == _goalName
                                  ? _accent
                                  : Colors.white54,
                            ),
                            title: Text(
                              goal.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              'Target ${_format(_targetForGoal(goal))}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                        ),
                      TextField(
                        controller: _customTargetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Custom target value',
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              _targetValue = parsed;
                              _goalTargetOverrides[_goalName] = parsed;
                            });
                            setSheetState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _saveGoal();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Save Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInventorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                _sectionTitle(
                  Icons.inventory_2_outlined,
                  'Manage Inventory',
                  'Update accepted resource quantities',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _tierButton('High Tier', _highTier, () {
                        setState(() => _highTier = true);
                        setSheetState(() {});
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tierButton('Low / Mid', !_highTier, () {
                        setState(() => _highTier = false);
                        setSheetState(() {});
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _resources.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _sheetResourceRow(_resources[index]),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _saveGoal();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Save Inventory'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetResourceRow(_NomadicTraderResource resource) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: _compactResourceRow(resource),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  void _openFeedbackSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 14),
            _sectionTitle(
              Icons.feedback_outlined,
              'Beta Feedback',
              'Send quick notes while testing Nomadic Trader',
            ),
            const SizedBox(height: 14),
            _feedbackTile(Icons.bug_report_outlined, 'Bug Report'),
            _feedbackTile(Icons.lightbulb_outline_rounded, 'Suggestion'),
            _feedbackTile(Icons.extension_outlined, 'Missing Feature'),
            _feedbackTile(Icons.balance_rounded, 'Balance Feedback'),
            _feedbackTile(Icons.swap_horiz_rounded, 'Trading Feedback'),
          ],
        ),
      ),
    );
  }

  Widget _feedbackTile(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label captured for beta feedback')),
          );
        },
        tileColor: Colors.white.withValues(alpha: 0.045),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        leading: Icon(icon, color: _accent),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.white.withValues(alpha: 0.52),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide
                            ? math.min(constraints.maxWidth - 24, 1280.0)
                            : math.min(constraints.maxWidth - 16, 520.0),
                      ),
                      child: Column(
                        children: [
                          _hero(),
                          Transform.translate(
                            offset: const Offset(0, -8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Column(
                                children: [
                                  _goalPanel(),
                                  const SizedBox(height: 18),
                                  _carousel(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.48),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.neonPink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: ArcAdBannerCard(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: ArcBottomActionDock(
                accent: _accent,
                actions: [
                  ArcDockAction(
                    label: 'Goals',
                    icon: Icons.flag_rounded,
                    accent: _accent,
                    onTap: _openGoalSheet,
                  ),
                  ArcDockAction(
                    label: 'Inventory',
                    icon: Icons.inventory_2_outlined,
                    accent: AppTheme.neonCyan,
                    onTap: _openInventorySheet,
                  ),
                  ArcDockAction(
                    label: 'My Hub',
                    icon: Icons.home_rounded,
                    accent: AppTheme.neonPink,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  ArcDockAction(
                    label: 'Feedback',
                    icon: Icons.feedback_outlined,
                    accent: Colors.lightGreenAccent,
                    onTap: _openFeedbackSheet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
