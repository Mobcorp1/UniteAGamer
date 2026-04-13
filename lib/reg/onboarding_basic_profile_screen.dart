import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class OnboardingBasicProfileScreen extends StatefulWidget {
  static const routeName = '/onboarding-basic-profile';

  const OnboardingBasicProfileScreen({super.key});

  @override
  State<OnboardingBasicProfileScreen> createState() =>
      _OnboardingBasicProfileScreenState();
}

class _OnboardingBasicProfileScreenState
    extends State<OnboardingBasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  String _selectedCountry = 'United Kingdom';
  String _selectedPlatform = 'PC';
  String _selectedTimeZone = 'Europe/London';

  static const List<String> _countries = <String>[
    'United Kingdom',
    'United States',
    'Canada',
    'Australia',
    'Ireland',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Poland',
    'Japan',
  ];

  static const List<String> _platforms = <String>[
    'PC',
    'PlayStation',
    'Xbox',
    'Steam',
  ];

  static const List<String> _timeZones = <String>[
    'Europe/London',
    'Europe/Berlin',
    'Europe/Paris',
    'Europe/Madrid',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Toronto',
    'Australia/Sydney',
    'Asia/Tokyo',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromFirestore();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final data = doc.data() ?? <String, dynamic>{};
    final basicProfile = data['basicProfile'] is Map<String, dynamic>
        ? data['basicProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final traderProfile = data['traderProfile'] is Map<String, dynamic>
        ? data['traderProfile'] as Map<String, dynamic>
        : <String, dynamic>{};

    String pickString(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is String && value.trim().isNotEmpty) return value;
      return fallback;
    }

    _displayNameController.text = pickString(
      basicProfile['displayName'],
      pickString(data['displayName'], ''),
    );
    _bioController.text = pickString(basicProfile['bio'], '');

    final countryValue = pickString(
      basicProfile['country'],
      pickString(data['region'], 'United Kingdom'),
    );
    final platformValue = pickString(
      basicProfile['platform'],
      pickString(traderProfile['platform'], 'PC'),
    );
    final timeZoneValue = pickString(
      basicProfile['timeZone'],
      pickString(traderProfile['timeZone'], 'Europe/London'),
    );

    if (_countries.contains(countryValue)) {
      _selectedCountry = countryValue;
    }
    if (_platforms.contains(platformValue)) {
      _selectedPlatform = platformValue;
    }
    if (_timeZones.contains(timeZoneValue)) {
      _selectedTimeZone = timeZoneValue;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _displayNameController.text.trim(),
        'onboardingComplete': true,
        'basicProfile': {
          'displayName': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
          'country': _selectedCountry,
          'platform': _selectedPlatform,
          'timeZone': _selectedTimeZone,
          'platforms': <String>[_selectedPlatform],
        },
        'traderProfile': {
          'uagName': _displayNameController.text.trim(),
          'region': _selectedCountry == 'United Kingdom'
              ? 'UK'
              : _selectedCountry,
          'platform': _selectedPlatform,
          'timeZone': _selectedTimeZone,
        },
        'modules': {'trader': true},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleTextStyle(
              fontSize: 20,
              color: AppTheme.neonPink,
              isBold: true,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );
  }

  InputDecoration _input(String label) => AppTheme.inputDecoration(label);

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppTheme.cardBackgroundAlt,
      decoration: _input(label),
      style: AppTheme.bodyTextStyle(fontSize: 16, color: AppTheme.neonCyan),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
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
        title: Text(
          'Basic Profile',
          style: AppTheme.neonTextStyle(
            fontSize: 24,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppTheme.pagePadding,
                    children: [
                      _sectionCard(
                        title: 'Trader Details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              style: AppTheme.bodyTextStyle(
                                  fontSize: 16, color: AppTheme.neonCyan),
                              decoration: _input('Display Name'),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Enter your display name'
                                      : null,
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _buildDropdown(
                              label: 'Country',
                              value: _selectedCountry,
                              items: _countries,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedCountry = v);
                                }
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _buildDropdown(
                              label: 'Preferred Platform',
                              value: _selectedPlatform,
                              items: _platforms,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedPlatform = v);
                                }
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _buildDropdown(
                              label: 'Time Zone',
                              value: _selectedTimeZone,
                              items: _timeZones,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedTimeZone = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      _sectionCard(
                        title: 'Bio',
                        child: TextFormField(
                          controller: _bioController,
                          minLines: 3,
                          maxLines: 5,
                          style: AppTheme.bodyTextStyle(
                              fontSize: 16, color: AppTheme.neonCyan),
                          decoration: _input('Short Bio (optional)'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: Text(_isSaving
                              ? 'Saving...'
                              : 'Continue to Traders Hub'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
