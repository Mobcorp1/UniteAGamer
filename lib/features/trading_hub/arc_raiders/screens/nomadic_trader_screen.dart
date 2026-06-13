import 'package:flutter/material.dart';
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
  });

  final String id;
  final String name;
  final int value;
  final bool highTier;
}

class _NomadicTraderScreenState extends State<NomadicTraderScreen> {
  static const _prefsPrefix = 'arc_nomadic_trader_';

  static const _highTierResources = <_NomadicTraderResource>[
    _NomadicTraderResource(
      id: 'queen_reactor',
      name: 'Queen Reactor',
      value: 11000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'matriarch_reactor',
      name: 'Matriarch Reactor',
      value: 11000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'vaporizer_regulator',
      name: 'Vaporizer Regulator',
      value: 6000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'turbine_compressor',
      name: 'Turbine Compressor',
      value: 5000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'assessor_matrix',
      name: 'Assessor Matrix',
      value: 5000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'rocketeer_driver',
      name: 'Rocketeer Driver',
      value: 3000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'bastion_cell',
      name: 'Bastion Cell',
      value: 3000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'bombardier_cell',
      name: 'Bombardier Cell',
      value: 3000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'leaper_pulse_unit',
      name: 'Leaper Pulse Unit',
      value: 3000,
      highTier: true,
    ),
    _NomadicTraderResource(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: true,
    ),
  ];

  static const _lowTierResources = <_NomadicTraderResource>[
    _NomadicTraderResource(
      id: 'shredder_gyro',
      name: 'Shredder Gyro',
      value: 2000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'sentinel_firing_core',
      name: 'Sentinel Firing Core',
      value: 2000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'surveyor_vault',
      name: 'Surveyor Vault',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'snitch_scanner',
      name: 'Snitch Scanner',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'hornet_driver',
      name: 'Hornet Driver',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'firefly_burner',
      name: 'Firefly Burner',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'damaged_leaper_pulse_unit',
      name: 'Damaged Leaper Pulse Unit',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'damaged_rocketeer_driver',
      name: 'Damaged Rocketeer Driver',
      value: 1000,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'fireball_burner',
      name: 'Fireball Burner',
      value: 640,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'damaged_hornet_driver',
      name: 'Damaged Hornet Driver',
      value: 640,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'tick_pod',
      name: 'Tick Pod',
      value: 640,
      highTier: false,
    ),
    _NomadicTraderResource(
      id: 'duplicate_blueprint',
      name: 'Duplicate Blueprint',
      value: 5000,
      highTier: false,
    ),
  ];

  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _customTargetController = TextEditingController();

  String _goalName = 'Stash Expansion';
  bool _highTier = true;
  int _targetValue = 200000;
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

  int get _remainingValue => (_targetValue - _currentValue).clamp(0, 999999999);

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

  String _format(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.26)),
      ),
      child: child,
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.neonCyan.withValues(alpha: 0.24),
      backgroundColor: Colors.black.withValues(alpha: 0.30),
      labelStyle: TextStyle(
        color: selected ? AppTheme.neonCyan : Colors.white70,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildGoalCard() {
    const targets = [100000, 150000, 200000, 250000, 300000];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal & Target',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in const [
                'Stash Expansion',
                'Expedition Vault',
                'Blueprint Completion',
                'Custom Goal',
              ])
                _chip(
                  goal,
                  _goalName == goal,
                  () => setState(() => _goalName = goal),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final target in targets)
                _chip(
                  _format(target),
                  _targetValue == target,
                  () => setState(() {
                    _targetValue = target;
                    _customTargetController.text = target.toString();
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextField(
            controller: _customTargetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Custom target value'),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed != null && parsed > 0) {
                setState(() => _targetValue = parsed);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accepted Resource Tier',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            children: [
              _chip(
                'High Tier ARC Parts',
                _highTier,
                () => setState(() => _highTier = true),
              ),
              _chip(
                'Low / Mid Tier ARC Parts',
                !_highTier,
                () => setState(() => _highTier = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final percent = (_progress * 100).round();
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            color: AppTheme.neonCyan,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _pill('Target', _format(_targetValue)),
              _pill('Current', _format(_currentValue)),
              _pill('Remaining', _format(_remainingValue)),
              _pill('Progress', '$percent%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquivalentCard() {
    final remaining = _remainingValue;
    final equivalents = [
      _equivalent('Queen Reactors', 11000, remaining),
      _equivalent('Duplicate Blueprints', 5000, remaining),
      _equivalent('Bombardier Cells', 3000, remaining),
      _equivalent('Shredder Gyros', 2000, remaining),
    ];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equivalent To',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          if (remaining == 0)
            const Text(
              'Target reached.',
              style: TextStyle(color: Colors.white70),
            )
          else
            for (final item in equivalents)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
        ],
      ),
    );
  }

  String _equivalent(String label, int value, int remaining) {
    final count = (remaining / value).ceil();
    return '$count $label';
  }

  Widget _buildResourcesCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource Inventory',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          const Text(
            'Enter quantities for the resource tier Ermal is accepting this week.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: AppTheme.spaceM),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 560
                  ? 2
                  : 1;
              return GridView.builder(
                itemCount: _resources.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 3.1 : 2.45,
                ),
                itemBuilder: (context, index) =>
                    _resourceTile(_resources[index]),
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveGoal,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Goal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceTile(_NomadicTraderResource resource) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            resource.highTier ? Icons.bolt_rounded : Icons.memory_rounded,
            color: resource.highTier ? AppTheme.neonPink : AppTheme.neonCyan,
          ),
          const SizedBox(width: AppTheme.spaceM),
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
                  ),
                ),
                Text(
                  'Value: ${_format(resource.value)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            child: TextField(
              controller: _controllers[resource.id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Qty',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NOMADIC TRADER',
                    style: AppTheme.tradingHeading(
                      fontSize: 34,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track target value, accepted resources and fastest route to Ermal trade completion.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  _buildGoalCard(),
                  _buildTierCard(),
                  _buildProgressCard(),
                  _buildEquivalentCard(),
                  _buildResourcesCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
