import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';

class ArcProfileEditScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile/edit';

  const ArcProfileEditScreen({super.key});

  @override
  State<ArcProfileEditScreen> createState() => _ArcProfileEditScreenState();
}

class _ArcProfileEditScreenState extends State<ArcProfileEditScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _uagIdController = TextEditingController();
  final TextEditingController _uagNameController = TextEditingController();
  final TextEditingController _embarkIdController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  final TextEditingController _referredByController = TextEditingController();

  bool _visibleInSearch = true;
  bool _micOk = true;
  bool _crossRegionOk = false;
  bool _crossPlatformOk = true;
  bool _affiliateEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _createdAt;
  String _payoutMethod = 'Bank Transfer';
  String _subscriptionStatus = 'inactive';

  static const List<String> _payoutMethods = <String>[
    'Bank Transfer',
    'PayPal',
    'Stripe Connect',
    'Not Set',
  ];

  static const List<String> _subscriptionOptions = <String>[
    'inactive',
    'trial',
    'active',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _uagIdController.dispose();
    _uagNameController.dispose();
    _embarkIdController.dispose();
    _regionController.dispose();
    _platformController.dispose();
    _timezoneController.dispose();
    _referralCodeController.dispose();
    _referredByController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ArcTraderProfile profile = await _repository.getProfile();

    _uagIdController.text = profile.uagId;
    _uagNameController.text = profile.uagName;
    _embarkIdController.text = profile.embarkId;
    _regionController.text = profile.region;
    _platformController.text = profile.platform;
    _timezoneController.text = profile.timezone;
    _referralCodeController.text = profile.referralCode;
    _referredByController.text = profile.referredByCode;
    _visibleInSearch = profile.visibleInSearch;
    _micOk = profile.micOk;
    _crossRegionOk = profile.crossRegionOk;
    _crossPlatformOk = profile.crossPlatformOk;
    _affiliateEnabled = profile.affiliateEnabled;
    _payoutMethod = profile.payoutMethod.isEmpty
        ? 'Not Set'
        : profile.payoutMethod;
    _subscriptionStatus = profile.subscriptionStatus;
    _createdAt = profile.createdAt;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ArcTraderProfile current = await _repository.getProfile();

    setState(() => _isSaving = true);
    try {
      await _repository.saveProfile(
        current.copyWith(
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
          subscriptionStatus: _subscriptionStatus,
          referredByCode: _referredByController.text.trim(),
          createdAt: _createdAt,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Edit Trader Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            children: [
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
              _field(_referralCodeController, 'Referral Code', enabled: false),
              _field(_referredByController, 'Referred By Code'),
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
              DropdownButtonFormField<String>(
                initialValue: _subscriptionStatus,
                items: _subscriptionOptions
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _subscriptionStatus = value ?? 'inactive';
                }),
                decoration: const InputDecoration(
                  labelText: 'Subscription status',
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
                title: const Text('Affiliate programme enabled'),
              ),
              const SizedBox(height: AppTheme.spaceL),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: TextFormField(
        controller: controller,
        validator: validator,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
