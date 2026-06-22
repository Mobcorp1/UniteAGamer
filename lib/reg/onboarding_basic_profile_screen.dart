import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
  bool _acceptedTraderCode = false;
  int _stepIndex = 0;

  String _selectedCountry = 'United Kingdom';
  String _selectedPlatform = 'PC';
  String _selectedTimeZone = 'Europe/London';

  static const int _stepCount = 3;

  static const List<String> _countries = [
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

  static const List<String> _platforms = ['PC', 'PlayStation', 'Xbox', 'Steam'];

  static const List<String> _timeZones = [
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
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};
    final basicProfile = data['basicProfile'] is Map
        ? data['basicProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final traderProfile = data['traderProfile'] is Map
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _stepIndex = 3);
      return;
    }

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
          'platforms': [_selectedPlatform],
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
      setState(() => _stepIndex = 1);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _next() {
    if (_stepIndex == 2 && !_acceptedTraderCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accept the Trader Code to continue.')),
      );
      return;
    }

    if (_stepIndex == 3) {
      _saveProfile();
      return;
    }

    if (_stepIndex == 4) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
      return;
    }

    setState(() => _stepIndex = (_stepIndex + 1).clamp(0, _stepCount - 1));
  }

  void _back() {
    if (_stepIndex <= 0 || _isSaving) return;
    setState(() => _stepIndex--);
  }

  InputDecoration _input(String label) {
    return AppTheme.inputDecoration(label).copyWith(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.36),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.neonCyan.withValues(alpha: 0.34),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.8),
      ),
    );
  }

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
      style: AppTheme.bodyTextStyle(
        fontSize: 16,
        color: Colors.white,
        isBold: true,
      ),
      iconEnabledColor: AppTheme.neonCyan,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _background() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            'assets/images/auth_bg_landscape.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const StaticWatermark(),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.54)),
        const StaticWatermark(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.84),
                AppTheme.darkBackground.withValues(alpha: 0.46),
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoMark({double size = 82}) {
    return Image.asset(
      'assets/icon/uag_traders_icon_transparent.webp',
      height: size,
      errorBuilder: (_, _, _) => Icon(
        Icons.swap_horiz_rounded,
        size: size * 0.8,
        color: AppTheme.neonCyan,
      ),
    );
  }

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_stepCount, (index) {
        final active = index == _stepIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.28),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.65),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _primaryButton(String label, {IconData? icon}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _next,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(_isSaving ? 'SAVING...' : label),
      ),
    );
  }

  Widget _screenTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTheme.neonTextStyle(
            fontSize: 26,
            color: Colors.white,
            isBold: true,
          ).copyWith(letterSpacing: 1.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _contentShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.12),
            blurRadius: 30,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String body,
    bool selected = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: selected ? 0.58 : 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.16),
          width: selected ? 1.8 : 1.1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? AppTheme.neonCyan : Colors.white60,
            size: 31,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: selected ? AppTheme.neonCyan : Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _leftHeroPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _logoMark(size: 112),
          const SizedBox(height: 22),
          Text(
            'UAG',
            textAlign: TextAlign.center,
            style: AppTheme.heroTextStyle(fontSize: 58, color: Colors.white),
          ),
          Text(
            'TRADERS HUB',
            textAlign: TextAlign.center,
            style: AppTheme.neonTextStyle(
              fontSize: 16,
              color: AppTheme.neonCyan,
              isBold: true,
            ).copyWith(letterSpacing: 4),
          ),
          const SizedBox(height: 38),
          Text(
            _stepIndex == 0
                ? 'BUILD YOUR RAIDER PROFILE'
                : _stepIndex == 2
                ? 'READY TO LAUNCH'
                : 'TRUSTED TRADING',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _stepIndex == 0
                ? 'Three quick steps, then the rest can be completed inside My Hub.'
                : 'Your ARC command centre is ready.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _welcomeStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Welcome',
            subtitle:
                'Your account unlocks tracking, trading, intel and trusted raider tools.',
          ),
          const SizedBox(height: 24),
          _infoTile(
            icon: Icons.track_changes_rounded,
            title: 'Blueprint Tracking',
            body: 'Track what you own, what you need and what you can trade.',
            selected: false,
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.handshake_rounded,
            title: 'Trading',
            body: 'Create listings, find offers and plan safer swaps.',
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.radar_rounded,
            title: 'Intel',
            body: 'Use reports to make better raid decisions.',
          ),
          const SizedBox(height: 22),
          _primaryButton('GET STARTED'),
        ],
      ),
    );
  }

  Widget _featuresStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Built for Arc Raiders',
            subtitle:
                'Tracking, trading and trust are enabled for your account.',
          ),
          const SizedBox(height: 24),
          _infoTile(
            icon: Icons.inventory_2_outlined,
            title: 'Track',
            body: 'Blueprints, resources, duplicates and what you need.',
            selected: false,
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Trade',
            body: 'Find traders, create listings and make offers.',
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.verified_user_outlined,
            title: 'Trust',
            body: 'Build a profile that helps people trade with confidence.',
          ),
          const SizedBox(height: 22),
          _primaryButton('NEXT'),
        ],
      ),
    );
  }

  Widget _traderCodeStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Step 2 of 3 - Trader Code',
            subtitle:
                'UAG operates on trust. Accept the basics before entering the hub.',
          ),
          const SizedBox(height: 26),
          _codeLine(
            Icons.shield_outlined,
            'Be respectful and fair',
            'Treat all traders with respect.',
          ),
          _codeLine(
            Icons.gpp_bad_outlined,
            'No scamming or exploits',
            'Zero tolerance for cheating.',
          ),
          _codeLine(
            Icons.balance_rounded,
            'Honour your trades',
            'Follow through on commitments.',
          ),
          _codeLine(
            Icons.groups_2_outlined,
            'Help the community grow',
            'Share intel and support others.',
          ),
          const Spacer(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedTraderCode,
            activeColor: AppTheme.neonCyan,
            checkColor: Colors.black,
            onChanged: (value) {
              setState(() => _acceptedTraderCode = value ?? false);
            },
            title: const Text(
              'I have read and agree to the UAG Trader Code',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          _primaryButton('I ACCEPT'),
        ],
      ),
    );
  }

  Widget _codeLine(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStep() {
    return _contentShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _screenTitle(
              'Step 1 of 3 - Raider Profile',
              subtitle:
                  'Add the essentials now. Everything advanced moves into Complete Your Profile after launch.',
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _displayNameController,
              style: AppTheme.bodyTextStyle(
                fontSize: 16,
                color: Colors.white,
                isBold: true,
              ),
              decoration: _input('Display Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your display name'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildDropdown(
              label: 'Country',
              value: _selectedCountry,
              items: _countries,
              onChanged: (v) {
                if (v != null) setState(() => _selectedCountry = v);
              },
            ),
            const SizedBox(height: 14),
            _buildDropdown(
              label: 'Preferred Platform',
              value: _selectedPlatform,
              items: _platforms,
              onChanged: (v) {
                if (v != null) setState(() => _selectedPlatform = v);
              },
            ),
            const SizedBox(height: 14),
            _buildDropdown(
              label: 'Time Zone',
              value: _selectedTimeZone,
              items: _timeZones,
              onChanged: (v) {
                if (v != null) setState(() => _selectedTimeZone = v);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bioController,
              minLines: 2,
              maxLines: 4,
              style: AppTheme.bodyTextStyle(
                fontSize: 15,
                color: Colors.white,
                isBold: true,
              ),
              decoration: _input('Short Bio (optional)'),
            ),
            const SizedBox(height: 22),
            _primaryButton('NEXT'),
          ],
        ),
      ),
    );
  }

  Widget _completeStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.check_circle_outline_rounded,
            size: 120,
            color: AppTheme.neonCyan,
            shadows: [
              Shadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.72),
                blurRadius: 22,
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            "YOU'RE ALL SET!",
            textAlign: TextAlign.center,
            style: AppTheme.neonTextStyle(
              fontSize: 31,
              color: Colors.white,
              isBold: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Welcome to the UAG network.\\nAdvanced setup now lives in Complete Your Profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.38),
          ),
          const SizedBox(height: 22),
          _primaryButton('LAUNCH HUB', icon: Icons.rocket_launch_rounded),
        ],
      ),
    );
  }

  Widget _currentStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey<int>(_stepIndex),
        child: switch (_stepIndex) {
          0 => _welcomeStep(),
          1 => _featuresStep(),
          2 => _traderCodeStep(),
          3 => _profileStep(),
          _ => _completeStep(),
        },
      ),
    );
  }

  Widget _mainLayout(BoxConstraints constraints) {
    final compact = constraints.maxWidth < 900;

    final stepPanel = SizedBox(
      height: compact ? null : 650,
      child: _currentStep(),
    );

    if (compact) {
      return Column(
        children: [
          _leftHeroPanel(),
          const SizedBox(height: 18),
          SizedBox(height: 680, child: stepPanel),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 9, child: _leftHeroPanel()),
        const SizedBox(width: 24),
        Expanded(flex: 13, child: stepPanel),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            Positioned.fill(child: StaticWatermark()),
            Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          Positioned.fill(child: _background()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1260),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (_stepIndex > 0 && _stepIndex < 2)
                                IconButton(
                                  tooltip: 'Back',
                                  onPressed: _back,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              const Spacer(),
                              _stepDots(),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: constraints.maxWidth < 900 ? null : 650,
                            child: _mainLayout(constraints),
                          ),
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
}
