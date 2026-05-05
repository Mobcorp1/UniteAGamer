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
  bool _crossplayEnabled = true;
  bool _affiliateEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _createdAt;
  String _serverPreference = 'Automatic';
  String _payoutMethod = 'Bank Transfer';
  String _subscriptionStatus = 'inactive';

  static const List<String> _serverPreferences = <String>[
    'Automatic',
    'Europe',
    'North America',
    'Asia',
    'South America',
    'Oceania',
  ];

  static const List<String> _payoutMethods = <String>[
    'Bank Transfer',
    'PayPal',
    'Stripe Connect',
    'Not Set',
  ];

  static const List<String> _subscriptionOptions = <String>[
    'inactive',
    'trial',
    'essential',
    'premium',
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
    _serverPreference = _serverPreferences.contains(profile.serverPreference)
        ? profile.serverPreference
        : 'Automatic';
    _visibleInSearch = profile.visibleInSearch;
    _micOk = profile.micOk;
    _crossRegionOk = profile.crossRegionOk;
    _crossplayEnabled = profile.crossPlatformOk;
    _affiliateEnabled = profile.affiliateEnabled;
    _payoutMethod = profile.payoutMethod.isEmpty
        ? 'Not Set'
        : profile.payoutMethod;
    _subscriptionStatus = profile.subscriptionStatus;
    _createdAt = profile.createdAt;

    if (mounted) setState(() => _isLoading = false);
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
          serverPreference: _serverPreference,
          platform: _platformController.text.trim(),
          timezone: _timezoneController.text.trim(),
          visibleInSearch: _visibleInSearch,
          micOk: _micOk,
          crossRegionOk: _crossRegionOk,
          crossPlatformOk: _crossplayEnabled,
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  InputDecoration _inputDecoration(String label, {String? helperText}) {
    return AppTheme.tradingInputDecoration(label: label).copyWith(
      helperText: helperText,
      helperStyle: AppTheme.bodyTextStyle(
        fontSize: 12,
        color: AppTheme.tradingMutedText,
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spaceM,
        bottom: AppTheme.spaceS,
      ),
      child: Text(
        label,
        style: AppTheme.tradingHeading(fontSize: 18, color: AppTheme.neonCyan),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helperText,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: TextFormField(
        controller: controller,
        validator: validator,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, helperText: helperText),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        dropdownColor: AppTheme.cardBackground,
        style: const TextStyle(color: Colors.white),
        iconEnabledColor: AppTheme.neonCyan,
        decoration: _inputDecoration(label),
        items: values
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }

  Widget _switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.tradingSoftBorder,
        radius: 14,
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.neonCyan,
        title: Text(
          title,
          style: AppTheme.bodyTextStyle(
            fontSize: 14,
            color: Colors.white,
            isBold: true,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: AppTheme.tradingMutedText,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Edit Trader Profile'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            children: [
              _sectionTitle('Identity'),
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
              _field(_referralCodeController, 'Referral Code', enabled: false),
              _field(_referredByController, 'Referred By Code'),
              _sectionTitle('Platform & Server'),
              _field(
                _regionController,
                'Region',
                validator: (v) => _required(v, 'Region'),
              ),
              _dropdown(
                label: 'Server Preference',
                value: _serverPreference,
                values: _serverPreferences,
                onChanged: (value) =>
                    setState(() => _serverPreference = value ?? 'Automatic'),
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
              _sectionTitle('Preferences'),
              _switchTile(
                value: _visibleInSearch,
                onChanged: (value) => setState(() => _visibleInSearch = value),
                title: 'Visible in search',
                subtitle: 'Allow other traders to find your profile.',
              ),
              _switchTile(
                value: _micOk,
                onChanged: (value) => setState(() => _micOk = value),
                title: 'Mic okay',
                subtitle: 'Show voice chat availability.',
              ),
              _switchTile(
                value: _crossRegionOk,
                onChanged: (value) => setState(() => _crossRegionOk = value),
                title: 'Cross-region okay',
                subtitle:
                    'Open to switching region for raids, trades and event windows.',
              ),
              _switchTile(
                value: _crossplayEnabled,
                onChanged: (value) => setState(() => _crossplayEnabled = value),
                title: 'Crossplay enabled',
                subtitle:
                    'Used for cross-platform matching and trade planning.',
              ),
              _sectionTitle('Account'),
              _dropdown(
                label: 'Preferred payout method',
                value: _payoutMethod,
                values: _payoutMethods,
                onChanged: (value) =>
                    setState(() => _payoutMethod = value ?? 'Bank Transfer'),
              ),
              _dropdown(
                label: 'Subscription status',
                value: _subscriptionStatus,
                values: _subscriptionOptions,
                onChanged: (value) =>
                    setState(() => _subscriptionStatus = value ?? 'inactive'),
              ),
              _switchTile(
                value: _affiliateEnabled,
                onChanged: (value) => setState(() => _affiliateEnabled = value),
                title: 'Affiliate programme enabled',
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
}
