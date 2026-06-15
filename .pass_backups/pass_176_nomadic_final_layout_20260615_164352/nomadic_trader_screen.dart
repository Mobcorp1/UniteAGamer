import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
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

  final PageController _cardController = PageController(viewportFraction: 0.76);
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _customTargetController = TextEditingController();
  final Map<String, int> _goalTargetOverrides = {};

  String _goalName = 'Stash Expansion';
  bool _highTier = true;
  int _targetValue = 200000;
  int _activeCard = 0;
  bool _loaded = false;

  List<_NomadicTraderResource> get _resources =>
      _highTier ? _highTierResources : _lowTierResources;

  int _targetForGoal(_NomadicGoal goal) =>
      _goalTargetOverrides[goal.name] ?? goal.target;

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
    EdgeInsets padding = const EdgeInsets.all(14),
    Color? border,
  }) {
    final borderColor = border ?? _accent;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _heroImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 6.5,
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
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.18),
                    AppTheme.darkBackground.withValues(alpha: 0.46),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Ermal goals, accepted ARC parts and trader progress.',
            style: _labelStyle(color: _accent, size: 13),
          ),
        ],
      ),
    );
  }

  Widget _goalPanel() {
    final percent = (_progress * 100).round();

    return _frostedPanel(
      padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 3),
                    Text(_goalName.toUpperCase(), style: _valueStyle(size: 21)),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              color: _accent,
              backgroundColor: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          const SizedBox(height: 8),
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
        Text(label, style: _labelStyle(size: 10.5)),
        const SizedBox(height: 5),
        Text(value, style: _valueStyle(color: color, size: 18)),
      ],
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.70)),
      ),
      child: Icon(icon, color: color, size: 20),
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
          height: 310,
          child: PageView.builder(
            controller: _cardController,
            onPageChanged: (index) => setState(() => _activeCard = index),
            itemCount: cards.length,
            padEnds: false,
            itemBuilder: (context, index) => AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.fromLTRB(
                index == 0 ? 0 : 6,
                index == _activeCard ? 0 : 12,
                index == cards.length - 1 ? 0 : 6,
                index == _activeCard ? 0 : 12,
              ),
              child: cards[index],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _activeCard == i ? 26 : 8,
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
        Icon(icon, color: _accent, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _valueStyle(size: 18)),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inventoryPreviewCard() {
    final visible = _resources.take(3).toList();

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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tierButton(
                  'High',
                  _highTier,
                  () => setState(() => _highTier = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tierButton(
                  'Low/Mid',
                  !_highTier,
                  () => setState(() => _highTier = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openInventorySheet,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Manage Inventory'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.75)),
              visualDensity: VisualDensity.compact,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          style: _labelStyle(
            color: selected ? _accent : Colors.white70,
            size: 11,
          ),
        ),
      ),
    );
  }

  Widget _compactResourceRow(_NomadicTraderResource resource) {
    final controller = _controllers[resource.id]!;
    final qty = int.tryParse(controller.text.trim()) ?? 0;

    return Row(
      children: [
        _iconBadge(
          resource.icon,
          resource.highTier ? _accent : AppTheme.neonCyan,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Value ${_format(resource.value)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 58,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: _valueStyle(size: 16, color: _accent),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '= ${_format(qty * resource.value)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 10,
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
            'Remaining value context',
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text('REMAINING VALUE', style: _labelStyle(size: 10.5)),
                const SizedBox(height: 2),
                Text(
                  _format(remaining),
                  style: _valueStyle(color: _accent, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: equivalents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          _iconBadge(icon, color),
          const SizedBox(width: 10),
          Text('$count', style: _valueStyle(size: 23)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 12,
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
            'Priorities and custom targets',
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _defaultGoals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _goalCompactTile(_defaultGoals[index], index),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openGoalSheet,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Manage Goals'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.75)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCompactTile(_NomadicGoal goal, int index) {
    final selected = goal.name == _goalName;
    final target = _targetForGoal(goal);
    final progress = target == 0
        ? 0.0
        : (_currentValue / target).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => _setGoal(goal),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: _accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: _labelStyle(color: Colors.white, size: 10),
              ),
            ),
            const SizedBox(width: 8),
            Icon(goal.icon, color: _accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: _accent,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _format(target),
              style: _labelStyle(
                color: selected ? _accent : Colors.white70,
                size: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tradeCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.handshake_outlined),
        label: const Text('Trade Complete'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent.withValues(alpha: 0.22),
          foregroundColor: Colors.white,
          side: BorderSide(color: _accent.withValues(alpha: 0.72)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _adSlot() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: const ArcAdBannerCard(),
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
      builder: (sheetContext) => StatefulBuilder(
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
                const SizedBox(height: 12),
                _sectionTitle(
                  Icons.star_rounded,
                  'Manage Goals',
                  'Pick this week’s top priority',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _defaultGoals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final goal = _defaultGoals[index];
                      final selected = goal.name == _goalName;
                      return ListTile(
                        dense: true,
                        onTap: () {
                          _setGoal(goal);
                          setSheetState(() {});
                        },
                        tileColor: selected
                            ? _accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: selected
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
                          'Target ${_format(_targetForGoal(goal))}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customTargetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Custom target for selected goal',
                    helperText: 'Select a goal above, change value, then save.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                const SizedBox(height: 12),
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
      builder: (sheetContext) => StatefulBuilder(
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
                    physics: const BouncingScrollPhysics(),
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
      padding: const EdgeInsets.all(10),
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
      appBar: const UagAppBar(
        title: 'Nomadic Trader',
        subtitle: 'Ermal Progress Tracker',
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
                      _heroImage(),
                      _heroTitle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            _goalPanel(),
                            const SizedBox(height: 14),
                            _carousel(),
                            const SizedBox(height: 12),
                            _adSlot(),
                            const SizedBox(height: 12),
                            _tradeCompleteButton(),
                            const SizedBox(height: 22),
                          ],
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
