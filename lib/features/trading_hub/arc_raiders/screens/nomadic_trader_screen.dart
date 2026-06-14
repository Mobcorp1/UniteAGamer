import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
      target: 25000,
      icon: Icons.star_border_rounded,
    ),
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

  final PageController _cardController = PageController(viewportFraction: 0.88);
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _customTargetController = TextEditingController();

  String _goalName = 'Stash Expansion';
  bool _highTier = true;
  int _targetValue = 200000;
  int _activeCard = 0;
  bool _loaded = false;

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

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsPrefix}goal_name', _goalName);
    await prefs.setBool('${_prefsPrefix}high_tier', _highTier);
    await prefs.setInt('${_prefsPrefix}target_value', _targetValue);

    for (final resource in [..._highTierResources, ..._lowTierResources]) {
      final qty =
          int.tryParse(_controllers[resource.id]?.text.trim() ?? '') ?? 0;
      await prefs.setInt('${_prefsPrefix}qty_${resource.id}', qty);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nomadic Trader goal saved')));
  }

  void _setGoal(_NomadicGoal goal) {
    setState(() {
      _goalName = goal.name;
      _targetValue = goal.target;
      _customTargetController.text = goal.target.toString();
    });
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
            aspectRatio: 16 / 7.2,
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
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOMADIC TRADER', style: _valueStyle(size: 30)),
                const SizedBox(height: 2),
                Text(
                  'ERMAL PROGRESS TRACKER',
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
              _iconBadge(Icons.inventory_2_outlined, _accent),
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

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _carousel() {
    final cards = <Widget>[
      _inventoryPreviewCard(),
      _equivalentsCard(),
      _savedGoalsCard(),
    ];

    return Column(
      children: [
        SizedBox(
          height: 390,
          child: PageView.builder(
            controller: _cardController,
            onPageChanged: (index) => setState(() => _activeCard = index),
            itemCount: cards.length,
            itemBuilder: (context, index) => AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.fromLTRB(
                index == 0 ? 0 : 6,
                index == _activeCard ? 0 : 14,
                index == cards.length - 1 ? 0 : 6,
                index == _activeCard ? 0 : 14,
              ),
              child: cards[index],
            ),
          ),
        ),
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

  Widget _inventoryPreviewCard() {
    final visible = _resources.take(5).toList();

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
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
              itemBuilder: (context, index) =>
                  _compactResourceRow(visible[index]),
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
        _iconBadge(
          resource.icon,
          resource.highTier ? _accent : AppTheme.neonCyan,
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
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: equivalents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => equivalents[index],
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
          _iconBadge(icon, color),
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
          _sectionTitle(
            Icons.star_rounded,
            'Saved Goals',
            'Your top 3 priorities',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _defaultGoals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = _defaultGoals[index];
                final selected = goal.name == _goalName;
                final progress = goal.target == 0
                    ? 0.0
                    : (_currentValue / goal.target).clamp(0.0, 1.0);
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
                        _iconBadge(goal.icon, _accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target ${_format(goal.target)}',
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
                                  color: _accent,
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

  Widget _tradeCompleteCard() {
    return _frostedPanel(
      padding: const EdgeInsets.all(16),
      border: _accent,
      child: Row(
        children: [
          _iconBadge(Icons.handshake_outlined, _accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRADE COMPLETE',
                  style: _labelStyle(color: _accent, size: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deduction flow comes next. Current resources are preserved.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              _sectionTitle(
                Icons.star_rounded,
                'Manage Goals',
                'Pick this week’s top priority',
              ),
              const SizedBox(height: 18),
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
                    leading: Icon(goal.icon, color: _accent),
                    title: Text(
                      goal.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      'Target ${_format(goal.target)}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
              TextField(
                controller: _customTargetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Custom target value',
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _goalName = 'Custom Goal';
                      _targetValue = parsed;
                    });
                    setSheetState(() {});
                  }
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _saveGoal();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Goal'),
                ),
              ),
            ],
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
                    icon: const Icon(Icons.save_outlined),
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
      appBar: AppBar(
        title: const Text('Nomadic Trader'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 980 : 520),
                  child: Column(
                    children: [
                      _hero(),
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: [
                              _goalPanel(),
                              const SizedBox(height: 18),
                              _carousel(),
                              const SizedBox(height: 18),
                              _tradeCompleteCard(),
                              const SizedBox(height: 24),
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
      ),
    );
  }
}
