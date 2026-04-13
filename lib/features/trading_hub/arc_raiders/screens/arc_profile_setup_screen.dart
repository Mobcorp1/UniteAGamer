import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';

class ArcProfileSetupScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile/setup';

  const ArcProfileSetupScreen({super.key});

  @override
  State<ArcProfileSetupScreen> createState() => _ArcProfileSetupScreenState();
}

class _ArcProfileSetupScreenState extends State<ArcProfileSetupScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _uagIdController;
  late final TextEditingController _uagNameController;
  late final TextEditingController _embarkIdController;
  late final TextEditingController _regionController;
  late final TextEditingController _platformController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _referredByController;

  bool _visibleInSearch = true;
  bool _micOk = true;
  bool _crossRegionOk = false;
  bool _crossPlatformOk = true;
  bool _affiliateEnabled = false;
  bool _isSaving = false;
  String _payoutMethod = 'Bank Transfer';

  static const List<String> _payoutMethods = <String>[
    'Bank Transfer',
    'PayPal',
    'Stripe Connect',
    'Not Set',
  ];

  @override
  void initState() {
    super.initState();
    _uagIdController = TextEditingController();
    _uagNameController = TextEditingController();
    _embarkIdController = TextEditingController();
    _regionController = TextEditingController(text: 'UK');
    _platformController = TextEditingController();
    _timezoneController = TextEditingController(text: 'Europe/London');
    _referredByController = TextEditingController();
  }

  @override
  void dispose() {
    _uagIdController.dispose();
    _uagNameController.dispose();
    _embarkIdController.dispose();
    _regionController.dispose();
    _platformController.dispose();
    _timezoneController.dispose();
    _referredByController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final ArcTraderProfile current = await _repository.getProfile();
    final ArcTraderProfile profile = current.copyWith(
      uid: uid,
      uagId: _uagIdController.text.trim(),
      uagName: _uagNameController.text.trim(),
      embarkId: _embarkIdController.text.trim(),
      region: _regionController.text.trim(),
      platform: _platformController.text.trim(),
      timezone: _timezoneController.text.trim(),
      visibleInSearch: _visibleInSearch,
      micOk: _micOk,
      crossRegionOk: _crossRegionOk,
      crossPlatformOk: _crossPlatformOk,
      affiliateEnabled: _affiliateEnabled,
      payoutMethod: _payoutMethod == 'Not Set' ? '' : _payoutMethod,
      referredByCode: _referredByController.text.trim(),
      isProfileComplete: true,
      createdAt: current.createdAt ?? DateTime.now(),
    );

    try {
      await _repository.saveProfile(profile);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Set Up Trader Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            children: [
              Text(
                'Set up the public ARC Raiders profile that can later carry into the wider UAG ecosystem.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppTheme.spaceL),
              _field(
                _uagIdController,
                'UAG ID',
                helperText: 'Auto-assigned numeric trader ID',
                enabled: false,
              ),
              _field(
                _uagNameController,
                'UAG Name',
                validator: (v) => _required(v, 'UAG Name'),
              ),
              _field(_embarkIdController, 'Embark ID'),
              _field(
                _regionController,
                'Region',
                validator: (v) => _required(v, 'Region'),
              ),
              _field(
                _platformController,
                'Preferred Platform',
                validator: (v) => _required(v, 'Preferred Platform'),
              ),
              _field(
                _timezoneController,
                'Timezone',
                validator: (v) => _required(v, 'Timezone'),
              ),
              _field(_referredByController, 'Referral Code Used (optional)'),
              DropdownButtonFormField<String>(
                initialValue: _payoutMethod,
                items: _payoutMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _payoutMethod = value ?? 'Bank Transfer';
                }),
                decoration: const InputDecoration(
                  labelText: 'Preferred payout method',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              SwitchListTile(
                value: _visibleInSearch,
                onChanged: (value) => setState(() => _visibleInSearch = value),
                title: const Text('Visible in search'),
              ),
              SwitchListTile(
                value: _micOk,
                onChanged: (value) => setState(() => _micOk = value),
                title: const Text('Mic okay'),
              ),
              SwitchListTile(
                value: _crossRegionOk,
                onChanged: (value) => setState(() => _crossRegionOk = value),
                title: const Text('Cross-region okay'),
              ),
              SwitchListTile(
                value: _crossPlatformOk,
                onChanged: (value) => setState(() => _crossPlatformOk = value),
                title: const Text('Cross-platform okay'),
              ),
              SwitchListTile(
                value: _affiliateEnabled,
                onChanged: (value) => setState(() => _affiliateEnabled = value),
                title: const Text('Apply for affiliate programme'),
              ),
              const SizedBox(height: AppTheme.spaceL),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool enabled = true,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(labelText: label, helperText: helperText),
      ),
    );
  }
}
