import 'dart:ui' show PointerDeviceKind;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/trader_code_of_conduct_screen.dart';
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

enum _ArcPlayerStartState { fresh, active, postExpedition }

enum _ArcBlueprintSetupChoice { setupNow, skipForNow }

class _OnboardingBasicProfileScreenState
    extends State<OnboardingBasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _raiderLevelController = TextEditingController(text: '0');
  final _embarkIdController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  bool _acceptedTraderCode = false;
  bool _acceptedTermsOfService = false;
  bool _acceptedDataSecurity = false;
  bool _adminPreviewMode = false;
  late final PageController _stepController;
  int _stepIndex = 0;
  bool _hasAppliedRouteArguments = false;
  bool _reachedRaiderLevel25 = false;

  String _selectedPlayStyle = 'Balanced';
  String _selectedSquadIntent = 'Flexible';
  String _selectedSocialEnergy = 'Depends on the day';

  String _selectedCountry = 'United Kingdom';
  String _selectedPlatform = 'PC';
  String _selectedTimeZone = 'Europe/London';
  _ArcPlayerStartState _playerState = _ArcPlayerStartState.fresh;
  _ArcBlueprintSetupChoice _blueprintChoice =
      _ArcBlueprintSetupChoice.skipForNow;

  static const int _stepCount = 6;

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

  static const List<String> _playStyles = [
    'Balanced',
    'Quest focused',
    'Blueprint grinder',
    'Squad support',
    'PvP hunter',
    'Loot runner',
    'Casual explorer',
  ];

  static const List<String> _squadIntents = [
    'Flexible',
    'Squad up',
    'Quest team',
    'Blueprint runs',
    'Trade focused',
    'Solo for now',
  ];

  static const List<String> _socialEnergyOptions = [
    'Depends on the day',
    'Chatty and outgoing',
    'Quiet but cooperative',
    'High energy',
    'Low energy today',
    'Prefer pings over voice',
  ];

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
    _stepController = PageController(viewportFraction: 0.92);
    _prefillFromFirestore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAppliedRouteArguments) return;
    _hasAppliedRouteArguments = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _applySimulatorArguments(args);
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _raiderLevelController.dispose();
    _embarkIdController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    late final Map<String, dynamic> data;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 12));
      data = doc.data() ?? {};
    } catch (_) {
      data = <String, dynamic>{};
    }
    final basicProfile = data['basicProfile'] is Map
        ? data['basicProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final traderProfile = data['traderProfile'] is Map
        ? data['traderProfile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final arcOnboarding = data['arcOnboarding'] is Map
        ? data['arcOnboarding'] as Map<String, dynamic>
        : <String, dynamic>{};

    String pickString(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is String && value.trim().isNotEmpty) return value;
      return fallback;
    }

    int pickInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? fallback;
      return fallback;
    }

    _displayNameController.text = pickString(
      basicProfile['displayName'],
      pickString(data['displayName'], ''),
    );
    _bioController.text = pickString(basicProfile['bio'], '');
    _embarkIdController.text = pickString(
      basicProfile['embarkId'],
      pickString(traderProfile['embarkId'], ''),
    );

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

    if (_countries.contains(countryValue)) _selectedCountry = countryValue;
    if (_platforms.contains(platformValue)) _selectedPlatform = platformValue;
    if (_timeZones.contains(timeZoneValue)) _selectedTimeZone = timeZoneValue;

    final playStyleValue = pickString(
      basicProfile['playStyle'],
      pickString(traderProfile['playStyle'], 'Balanced'),
    );
    final squadIntentValue = pickString(
      basicProfile['squadIntent'],
      pickString(traderProfile['squadIntent'], 'Flexible'),
    );
    final socialEnergyValue = pickString(
      basicProfile['socialEnergy'],
      pickString(traderProfile['socialEnergy'], 'Depends on the day'),
    );
    if (_playStyles.contains(playStyleValue)) {
      _selectedPlayStyle = playStyleValue;
    }
    if (_squadIntents.contains(squadIntentValue)) {
      _selectedSquadIntent = squadIntentValue;
    }
    if (_socialEnergyOptions.contains(socialEnergyValue)) {
      _selectedSocialEnergy = socialEnergyValue;
    }

    final savedLevel = pickInt(
      arcOnboarding['raiderLevel'] ?? traderProfile['raiderLevel'],
      0,
    ).clamp(0, 999);
    _raiderLevelController.text = savedLevel.toString();
    _reachedRaiderLevel25 =
        savedLevel >= 25 || arcOnboarding['nomadicTraderUnlocked'] == true;

    final savedState = pickString(arcOnboarding['playerState'], 'fresh');
    _playerState = switch (savedState) {
      'active' => _ArcPlayerStartState.active,
      'postExpedition' => _ArcPlayerStartState.postExpedition,
      _ => _ArcPlayerStartState.fresh,
    };

    final blueprintSkipped = arcOnboarding['blueprintSetupSkipped'] == true;
    final blueprintConfigured =
        arcOnboarding['blueprintTrackerConfigured'] == true;
    _blueprintChoice = blueprintSkipped && !blueprintConfigured
        ? _ArcBlueprintSetupChoice.skipForNow
        : _ArcBlueprintSetupChoice.setupNow;

    if (mounted) setState(() => _isLoading = false);
  }

  bool get _isNomadicUnlocked => !_isFreshOrReset && _reachedRaiderLevel25;

  bool get _isFreshOrReset =>
      _playerState == _ArcPlayerStartState.fresh ||
      _playerState == _ArcPlayerStartState.postExpedition;

  String get _playerStateId => switch (_playerState) {
    _ArcPlayerStartState.active => 'active',
    _ArcPlayerStartState.postExpedition => 'postExpedition',
    _ => 'fresh',
  };

  Future<void> _saveOnboarding({required bool complete}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _stepIndex = 0);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final displayName = _displayNameController.text.trim();
    final nomadicUnlocked = _isNomadicUnlocked;
    final raiderLevel = nomadicUnlocked ? 25 : 0;
    final blueprintSetupSkipped =
        _blueprintChoice == _ArcBlueprintSetupChoice.skipForNow;
    final blueprintTrackerConfigured =
        _blueprintChoice == _ArcBlueprintSetupChoice.setupNow;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'displayName': displayName,
            'onboardingComplete': complete,
            'basicProfile': {
              'displayName': displayName,
              'bio': _bioController.text.trim(),
              'embarkId': _embarkIdController.text.trim(),
              'country': _selectedCountry,
              'platform': _selectedPlatform,
              'timeZone': _selectedTimeZone,
              'platforms': [_selectedPlatform],
              'playStyle': _selectedPlayStyle,
              'squadIntent': _selectedSquadIntent,
              'socialEnergy': _selectedSocialEnergy,
            },
            'traderProfile': {
              'uagName': displayName,
              'region': _selectedCountry == 'United Kingdom'
                  ? 'UK'
                  : _selectedCountry,
              'platform': _selectedPlatform,
              'timeZone': _selectedTimeZone,
              'embarkId': _embarkIdController.text.trim(),
              'playStyle': _selectedPlayStyle,
              'squadIntent': _selectedSquadIntent,
              'socialEnergy': _selectedSocialEnergy,
              'raiderLevel': raiderLevel,
            },
            'arcOnboarding': {
              'version': 2,
              'playerState': _playerStateId,
              'raiderLevel': raiderLevel,
              'nomadicTraderUnlocked': nomadicUnlocked,
              'embarkId': _embarkIdController.text.trim(),
              'playStyle': _selectedPlayStyle,
              'squadIntent': _selectedSquadIntent,
              'socialEnergy': _selectedSocialEnergy,
              'nomadicTraderLockedReason': nomadicUnlocked
                  ? null
                  : 'Nomadic Trader unlocks at Raider Level 25. Update your Raider Level in the app when you reach 25 to unlock Nomadic Trader planning.',
              'blueprintSetupSkipped': blueprintSetupSkipped,
              'blueprintTrackerConfigured': blueprintTrackerConfigured,
              'blueprintOwnershipReset': _isFreshOrReset,
              'questProgressReset': _isFreshOrReset,
              'benchProgressReset': _isFreshOrReset,
              'favouriteLoadoutsRetained': true,
              'completedSteps': {
                'profile': true,
                'playerType': true,
                'playerState': true,
                'blueprintTracker': blueprintTrackerConfigured,
                'blueprintTrackerSkipped': blueprintSetupSkipped,
                'nomadicTraderGate': true,
                'traderCode': _acceptedTraderCode,
                'termsOfService': _acceptedTermsOfService,
                'dataSecurity': _acceptedDataSecurity,
              },
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'modules': {
              'trader': true,
              'blueprintTracker': blueprintTrackerConfigured,
              'nomadicTrader': nomadicUnlocked,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 12));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _goToStep(int step) async {
    final nextStep = step.clamp(0, _stepCount - 1);
    setState(() => _stepIndex = nextStep);
    if (!_stepController.hasClients) return;
    await _stepController.animateToPage(
      nextStep,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_stepIndex == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      await _goToStep(1);
      return;
    }

    if (_stepIndex == 4 &&
        (!_acceptedTraderCode ||
            !_acceptedTermsOfService ||
            !_acceptedDataSecurity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Review and accept every command protocol to continue.',
          ),
        ),
      );
      return;
    }

    if (_stepIndex == _stepCount - 1) {
      if (_adminPreviewMode) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await _saveOnboarding(complete: true);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
      return;
    }

    await _goToStep(_stepIndex + 1);
  }

  Future<void> _back() async {
    if (_stepIndex <= 0 || _isSaving) return;
    await _goToStep(_stepIndex - 1);
  }

  void _applySimulatorArguments(Map args) {
    _adminPreviewMode = args['adminPreview'] == true;
    if (_adminPreviewMode && _displayNameController.text.trim().isEmpty) {
      _displayNameController.text = 'Closed Beta Preview';
    }
    final stateValue = args['playerState']?.toString();
    final blueprintValue = args['blueprintSetup']?.toString();
    final reachedLevel25 = args['reachedRaiderLevel25'] == true;
    setState(() {
      _playerState = switch (stateValue) {
        'active' => _ArcPlayerStartState.active,
        'postExpedition' => _ArcPlayerStartState.postExpedition,
        _ => _ArcPlayerStartState.fresh,
      };
      _reachedRaiderLevel25 = _playerState == _ArcPlayerStartState.active
          ? reachedLevel25
          : false;
      _raiderLevelController.text = _reachedRaiderLevel25 ? '25' : '0';
      _blueprintChoice = blueprintValue == 'setupNow'
          ? _ArcBlueprintSetupChoice.setupNow
          : _ArcBlueprintSetupChoice.skipForNow;
      if (_isFreshOrReset) {
        _blueprintChoice = _ArcBlueprintSetupChoice.skipForNow;
      }
      final step = args['step'];
      if (step is int) {
        _stepIndex = step.clamp(0, _stepCount - 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_stepController.hasClients) {
            _stepController.jumpToPage(_stepIndex);
          }
        });
      }
    });
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
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 18 : 28),
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
      child: SingleChildScrollView(child: child),
    );
  }

  Widget _leftHeroPanel() {
    final title = switch (_stepIndex) {
      0 => 'IDENTITY CHECK',
      1 => 'PLAYER TYPE',
      2 => 'WIPE STATE',
      3 => 'TRACKER SETUP',
      4 => 'COMMAND PROTOCOLS',
      _ => 'READY TO DEPLOY',
    };
    final subtitle = switch (_stepIndex) {
      0 =>
        'Set the core details the hub needs before it builds your command profile.',
      1 =>
        'Choose how you play so squads, trading and missions can fit around you.',
      2 => 'Tell the Command Centre where your wipe progress currently stands.',
      3 =>
        'Choose whether blueprint tracking should start now or wait until later.',
      4 =>
        'Review the trust, terms and data rules before entering the network.',
      _ =>
        'Your first command profile is ready. Finish onboarding to enter UAG.',
    };
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.18),
                blurRadius: 30,
              ),
            ],
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: compact ? 12 : 16,
            runSpacing: 10,
            children: [
              _logoMark(size: compact ? 42 : 52),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 300 : 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: compact
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          'UAG DEPLOYMENT BRIEFING',
                          style: AppTheme.neonTextStyle(
                            fontSize: compact ? 11 : 13,
                            color: AppTheme.neonCyan,
                            isBold: true,
                          ).copyWith(letterSpacing: 2.1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neonPink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.neonPink.withValues(alpha: 0.42),
                            ),
                          ),
                          child: Text(
                            '${_stepIndex + 1} / $_stepCount',
                            style: const TextStyle(
                              color: AppTheme.neonPink,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 22,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: compact ? 12.5 : 13.5,
                        height: 1.26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardBarrel({required List<Widget> cards, double height = 168}) {
    return _OnboardingCardCarousel(cards: cards, height: height);
  }

  bool get _identityNameComplete =>
      _displayNameController.text.trim().isNotEmpty;
  bool get _identityEmbarkComplete =>
      _embarkIdController.text.trim().isNotEmpty;

  Widget _missionInputCard({
    required String title,
    required String subtitle,
    required Widget child,
    required bool active,
    required bool complete,
  }) {
    final accent = complete ? AppTheme.neonCyan : AppTheme.neonPink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active || complete
              ? accent.withValues(alpha: active ? 0.92 : 0.50)
              : Colors.white.withValues(alpha: 0.12),
          width: active ? 1.7 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete ? Icons.check_circle_rounded : Icons.bolt_rounded,
                color: active || complete ? accent : Colors.white30,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _identityGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final spacing = constraints.maxWidth < 700 ? 12.0 : 14.0;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _actionFooter() {
    final canGoBack = _stepIndex > 0 && !_isSaving;
    final isLast = _stepIndex == _stepCount - 1;
    final label = _isSaving
        ? 'SAVING...'
        : isLast
        ? (_adminPreviewMode ? 'CLOSE PREVIEW' : 'LAUNCH COMMAND CENTRE')
        : _stepIndex == 4
        ? 'ACCEPT AND CONTINUE'
        : 'CONTINUE';

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 118,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: canGoBack ? () => _back() : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('BACK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_stepIndex + 1} / $_stepCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _next,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isLast
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                  label: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileStep() {
    final nameComplete = _identityNameComplete;
    final embarkComplete = _identityEmbarkComplete;
    return _contentShell(
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _screenTitle(
              'Identity',
              subtitle:
                  'Start with the basics. Keep this compact so you can get into the Command Centre quickly.',
            ),
            const SizedBox(height: 18),
            _identityGrid([
              _missionInputCard(
                title: 'Display name',
                subtitle: 'Shown across squads, trades and profiles.',
                active: !nameComplete,
                complete: nameComplete,
                child: TextFormField(
                  controller: _displayNameController,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    isBold: true,
                  ),
                  decoration: _input('Display Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your display name'
                      : null,
                ),
              ),
              _missionInputCard(
                title: 'Embark ID',
                subtitle: 'Used to help players find you outside the app.',
                active: nameComplete && !embarkComplete,
                complete: embarkComplete,
                child: TextFormField(
                  controller: _embarkIdController,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    isBold: true,
                  ),
                  decoration: _input('Embark ID'),
                ),
              ),
              _missionInputCard(
                title: 'Platform',
                subtitle: 'Where you usually raid from.',
                active: nameComplete && embarkComplete,
                complete: true,
                child: _buildDropdown(
                  label: 'Preferred Platform',
                  value: _selectedPlatform,
                  items: _platforms,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPlatform = v);
                  },
                ),
              ),
              _missionInputCard(
                title: 'Region',
                subtitle: 'Used for squad fit and better timing later.',
                active: false,
                complete: true,
                child: _buildDropdown(
                  label: 'Country',
                  value: _selectedCountry,
                  items: _countries,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCountry = v);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _missionInputCard(
              title: 'Optional bio',
              subtitle:
                  'A short line for your profile. This can be finished later.',
              active: false,
              complete: _bioController.text.trim().isNotEmpty,
              child: TextFormField(
                controller: _bioController,
                minLines: 2,
                maxLines: 3,
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  isBold: true,
                ),
                decoration: _input('Short Bio (optional)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerTypeStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Player Type',
            subtitle:
                'Choose the identity, squad goal and current energy that best fit this session.',
          ),
          const SizedBox(height: 16),
          Text('ARCHETYPE', style: _sectionLabelStyle()),
          const SizedBox(height: 8),
          _cardBarrel(
            height: 154,
            cards: _playStyles
                .map(
                  (style) => _choiceCard(
                    title: style,
                    body: _playStyleDescription(style),
                    icon: Icons.person_pin_circle_rounded,
                    selected: _selectedPlayStyle == style,
                    onTap: () => setState(() => _selectedPlayStyle = style),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('TODAY\'S GOAL', style: _sectionLabelStyle()),
          const SizedBox(height: 8),
          _cardBarrel(
            height: 154,
            cards: _squadIntents
                .map(
                  (intent) => _choiceCard(
                    title: intent,
                    body: _squadIntentDescription(intent),
                    icon: Icons.groups_rounded,
                    selected: _selectedSquadIntent == intent,
                    onTap: () => setState(() => _selectedSquadIntent = intent),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('SOCIAL ENERGY', style: _sectionLabelStyle()),
          const SizedBox(height: 8),
          _cardBarrel(
            height: 154,
            cards: _socialEnergyOptions
                .map(
                  (energy) => _choiceCard(
                    title: energy,
                    body: _socialEnergyDescription(energy),
                    icon: Icons.mood_rounded,
                    selected: _selectedSocialEnergy == energy,
                    onTap: () => setState(() => _selectedSocialEnergy = energy),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionLabelStyle() {
    return TextStyle(
      color: AppTheme.neonCyan.withValues(alpha: 0.88),
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.4,
    );
  }

  String _playStyleDescription(String style) => switch (style) {
    'Quest focused' => 'Prioritise quests, unlocks and guided progression.',
    'Blueprint grinder' =>
      'Prioritise blueprint collection, duplicates and trade value.',
    'Squad support' =>
      'Prioritise team utility, survival and helping the squad.',
    'PvP hunter' =>
      'Prioritise combat readiness, ambushes and confident raids.',
    'Loot runner' =>
      'Prioritise stash building, materials and safe extraction routes.',
    'Casual explorer' =>
      'Prioritise low-pressure play, discovery and flexible goals.',
    _ => 'Blend quests, blueprints, loot, trading and squad play.',
  };

  String _squadIntentDescription(String intent) => switch (intent) {
    'Squad up' => 'You actively want teammates and voice-ready sessions.',
    'Quest team' => 'Match with players chasing similar quests.',
    'Blueprint runs' => 'Match with players farming blueprints or duplicates.',
    'Trade focused' => 'Prioritise trade-ready players and inventory value.',
    'Solo for now' => 'Keep matchmaking light and avoid forced squad prompts.',
    _ => 'Keep recommendations flexible depending on your session.',
  };

  String _socialEnergyDescription(String energy) => switch (energy) {
    'Chatty and outgoing' => 'Good day for voice, squad calls and social runs.',
    'Quiet but cooperative' => 'Team-friendly without needing constant chat.',
    'High energy' => 'Good day for faster, more intense raids.',
    'Low energy today' =>
      'Prefer calmer routes, clear plans and less pressure.',
    'Prefer pings over voice' =>
      'Matchmaking should favour low-voice communication.',
    _ => 'Let your session mood change without locking your whole profile.',
  };

  Widget _progressionStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Step 3 of 6 - Wipe State',
            subtitle:
                'This controls what the Command Centre should prioritise after onboarding.',
          ),
          const SizedBox(height: 22),
          _cardBarrel(
            height: 214,
            cards: [
              _choiceCard(
                title: 'Fresh start / no current progress',
                body:
                    'Use this if you have just started ARC Raiders or have no useful tracker data yet.',
                icon: Icons.radio_button_checked_rounded,
                selected: _playerState == _ArcPlayerStartState.fresh,
                onTap: () => setState(() {
                  _playerState = _ArcPlayerStartState.fresh;
                  _raiderLevelController.text = '0';
                  _reachedRaiderLevel25 = false;
                  _blueprintChoice = _ArcBlueprintSetupChoice.skipForNow;
                }),
              ),
              _choiceCard(
                title: 'Existing profile / mid-wipe',
                body:
                    'Use this if you already have levels, blueprints, bench upgrades or quest progress.',
                icon: Icons.person_search_rounded,
                selected: _playerState == _ArcPlayerStartState.active,
                onTap: () =>
                    setState(() => _playerState = _ArcPlayerStartState.active),
              ),
              _choiceCard(
                title: 'After expedition reset',
                body:
                    'Raider Level, blueprints, quests and benches restart. Favourite Loadouts stay saved.',
                icon: Icons.restart_alt_rounded,
                selected: _playerState == _ArcPlayerStartState.postExpedition,
                onTap: () => setState(() {
                  _playerState = _ArcPlayerStartState.postExpedition;
                  _raiderLevelController.text = '0';
                  _reachedRaiderLevel25 = false;
                  _blueprintChoice = _ArcBlueprintSetupChoice.skipForNow;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _cardBarrel(
            height: 206,
            cards: [
              _choiceCard(
                title: 'Reached Raider Level 25? No',
                body:
                    'Nomadic Trader planning stays locked. Update this when you reach Level 25 in-game.',
                icon: Icons.lock_outline_rounded,
                selected: !_isNomadicUnlocked,
                onTap: _isFreshOrReset
                    ? null
                    : () => setState(() {
                        _reachedRaiderLevel25 = false;
                        _raiderLevelController.text = '0';
                      }),
              ),
              _choiceCard(
                title: 'Reached Raider Level 25? Yes',
                body:
                    'Enable Nomadic Trader, resource, stash upgrade and Safe Pocket planning.',
                icon: Icons.lock_open_rounded,
                selected: _isNomadicUnlocked,
                onTap: _isFreshOrReset
                    ? null
                    : () => setState(() {
                        _reachedRaiderLevel25 = true;
                        _raiderLevelController.text = '25';
                      }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusPanel(
            title: _isNomadicUnlocked
                ? 'Nomadic Trader planning unlocked'
                : 'Nomadic Trader locked',
            body: _isNomadicUnlocked
                ? 'Resource planning and Nomadic Trader goals can be enabled for this profile.'
                : 'Nomadic Trader unlocks at Raider Level 25. Update your Raider Level in the app when you reach 25 to unlock Nomadic Trader planning.',
            icon: _isNomadicUnlocked
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            accent: _isNomadicUnlocked ? AppTheme.neonCyan : Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  Widget _blueprintStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Step 4 of 6 - Blueprint Tracker',
            subtitle:
                'Skip this if you have no blueprints or duplicates yet. You can return from the Tool Deck later.',
          ),
          const SizedBox(height: 24),
          if (_isFreshOrReset)
            _statusPanel(
              title: 'Blueprint ownership starts empty',
              body:
                  'Fresh starts and expedition resets wipe blueprint ownership. Favourite Loadouts remain saved, but blueprint ownership should be rebuilt from the new wipe.',
              icon: Icons.cleaning_services_rounded,
              accent: AppTheme.neonPink,
            ),
          const SizedBox(height: 14),
          _cardBarrel(
            height: 210,
            cards: [
              _choiceCard(
                title: 'Set up Blueprint Tracker now',
                body:
                    'Choose this if you already have owned blueprints, missing targets or duplicates to enter.',
                icon: Icons.grid_view_rounded,
                selected: _blueprintChoice == _ArcBlueprintSetupChoice.setupNow,
                onTap: () => setState(
                  () => _blueprintChoice = _ArcBlueprintSetupChoice.setupNow,
                ),
              ),
              _choiceCard(
                title: 'Skip Blueprint Tracker for now',
                body:
                    'Best for fresh starts, zero blueprints or no duplicates. The Command Centre will remind you later.',
                icon: Icons.skip_next_rounded,
                selected:
                    _blueprintChoice == _ArcBlueprintSetupChoice.skipForNow,
                onTap: () => setState(
                  () => _blueprintChoice = _ArcBlueprintSetupChoice.skipForNow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statusPanel(
            title: _blueprintChoice == _ArcBlueprintSetupChoice.setupNow
                ? 'Blueprint Tracker will be enabled'
                : 'Blueprint Tracker setup will stay pending',
            body: _blueprintChoice == _ArcBlueprintSetupChoice.setupNow
                ? 'The tracker will be available from the Command Centre and Tool Deck.'
                : 'No grid setup is forced during onboarding. You can complete it when you have blueprint data worth tracking.',
            icon: _blueprintChoice == _ArcBlueprintSetupChoice.setupNow
                ? Icons.check_circle_outline_rounded
                : Icons.pending_actions_rounded,
            accent: _blueprintChoice == _ArcBlueprintSetupChoice.setupNow
                ? AppTheme.neonCyan
                : Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  Future<void> _openLegalDocument(Widget screen) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Widget _traderCodeStep() {
    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _screenTitle(
            'Command Protocols',
            subtitle:
                'Review the trust, terms and data basics. All three must be acknowledged before deployment.',
          ),
          const SizedBox(height: 18),
          _identityGrid([
            _policyCard(
              icon: Icons.shield_outlined,
              title: 'Trader Code of Conduct',
              body:
                  'Respect other players, honour agreed trades and keep the community fair.',
              value: _acceptedTraderCode,
              onView: () =>
                  _openLegalDocument(const TraderCodeOfConductScreen()),
              onChanged: (value) => setState(() => _acceptedTraderCode = value),
            ),
            _policyCard(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              body:
                  'Use the hub responsibly. Do not abuse beta tools, exploits or trading systems.',
              value: _acceptedTermsOfService,
              onView: () => _openLegalDocument(const TermsOfUseScreen()),
              onChanged: (value) =>
                  setState(() => _acceptedTermsOfService = value),
            ),
            _policyCard(
              icon: Icons.lock_person_outlined,
              title: 'Data & Security',
              body:
                  'UAG only needs profile and preference data for matching, recommendations and trading.',
              value: _acceptedDataSecurity,
              onView: () => _openLegalDocument(const PrivacyPolicyScreen()),
              onChanged: (value) =>
                  setState(() => _acceptedDataSecurity = value),
            ),
            _statusPanel(
              title: 'No private account access',
              body:
                  'Never share passwords or private Embark login details. Embark ID is only used so players can find you.',
              icon: Icons.gpp_good_outlined,
              accent: AppTheme.neonCyan,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _policyCard({
    required IconData icon,
    required String title,
    required String body,
    required bool value,
    required VoidCallback onView,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: value
            ? AppTheme.neonCyan.withValues(alpha: 0.11)
            : Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.14),
          width: value ? 1.5 : 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.20),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: value ? AppTheme.neonCyan : Colors.white60),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        height: 1.34,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Read document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  side: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.55),
                  ),
                ),
              ),
              FilterChip(
                selected: value,
                onSelected: onChanged,
                avatar: Icon(
                  value ? Icons.check_rounded : Icons.circle_outlined,
                  size: 17,
                  color: value ? Colors.black : Colors.white54,
                ),
                label: Text(value ? 'Acknowledged' : 'I acknowledge'),
                selectedColor: AppTheme.neonCyan,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: value ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(
                  color: value
                      ? AppTheme.neonCyan
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completeStep() {
    final summary = <String>[
      _isFreshOrReset
          ? 'Raider Level 25 reached: No after fresh start/reset'
          : 'Raider Level 25 reached: ${_isNomadicUnlocked ? 'Yes' : 'No'}',
      _isNomadicUnlocked
          ? 'Nomadic Trader: enabled'
          : 'Nomadic Trader: locked until Level 25',
      _blueprintChoice == _ArcBlueprintSetupChoice.setupNow
          ? 'Blueprint Tracker: enabled'
          : 'Blueprint Tracker: skipped for now',
      if (_isFreshOrReset) 'Blueprint ownership, quests and benches: reset',
      'Favourite Loadouts: retained',
    ];

    return _contentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.check_circle_outline_rounded,
            size: 100,
            color: AppTheme.neonCyan,
            shadows: [
              Shadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.72),
                blurRadius: 22,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Step 6 of 6 - Ready to Launch',
            textAlign: TextAlign.center,
            style: AppTheme.neonTextStyle(
              fontSize: 29,
              color: Colors.white,
              isBold: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your Command Centre will now prioritise the systems that matter for your current wipe state.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.38),
          ),
          const SizedBox(height: 18),
          _cardBarrel(
            height: 150,
            cards: summary.map((line) => _summaryCard(line)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required String body,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonCyan.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.14),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.18),
                    blurRadius: 22,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppTheme.neonCyan : Colors.white60,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      height: 1.08,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppTheme.neonCyan : Colors.white30,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.22,
                  fontSize: 12.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPanel({
    required String title,
    required String body,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String line) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppTheme.neonCyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
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
          0 => _profileStep(),
          1 => _playerTypeStep(),
          2 => _progressionStep(),
          3 => _blueprintStep(),
          4 => _traderCodeStep(),
          _ => _completeStep(),
        },
      ),
    );
  }

  Widget _mainLayout(BoxConstraints constraints) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _leftHeroPanel(),
        SizedBox(height: constraints.maxWidth < 700 ? 14 : 18),
        _currentStep(),
        _actionFooter(),
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
                  padding: EdgeInsets.all(constraints.maxWidth < 700 ? 14 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (_stepIndex > 0 && _stepIndex < _stepCount - 1)
                                IconButton(
                                  tooltip: 'Back',
                                  onPressed: () => _back(),
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
                          _mainLayout(constraints),
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

class _OnboardingCardCarousel extends StatefulWidget {
  const _OnboardingCardCarousel({required this.cards, required this.height});

  final List<Widget> cards;
  final double height;

  @override
  State<_OnboardingCardCarousel> createState() =>
      _OnboardingCardCarouselState();
}

class _OnboardingCardCarouselState extends State<_OnboardingCardCarousel> {
  PageController? _controller;
  int _activeIndex = 0;
  double? _viewportFraction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    final nextFraction = width < 700 ? 0.82 : (width < 1100 ? 0.48 : 0.34);
    if (_controller == null || _viewportFraction != nextFraction) {
      final initialPage = _activeIndex.clamp(0, widget.cards.length - 1);
      _controller?.dispose();
      _viewportFraction = nextFraction;
      _controller = PageController(
        viewportFraction: nextFraction,
        initialPage: initialPage,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.cards.length) {
      _activeIndex = widget.cards.isEmpty ? 0 : widget.cards.length - 1;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    if (widget.cards.isEmpty || _controller == null) return;
    final target = index.clamp(0, widget.cards.length - 1);
    await _controller!.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final compact = MediaQuery.sizeOf(context).width < 700;
    final resolvedHeight = compact ? widget.height + 12 : widget.height;
    final canGoBack = _activeIndex > 0;
    final canGoForward = _activeIndex < widget.cards.length - 1;

    return Column(
      children: [
        SizedBox(
          height: resolvedHeight,
          child: Row(
            children: [
              _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous card',
                enabled: canGoBack,
                onPressed: () => _goTo(_activeIndex - 1),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _OnboardingCarouselScrollBehavior(),
                  child: PageView.builder(
                    controller: _controller,
                    padEnds: true,
                    physics: const PageScrollPhysics(),
                    itemCount: widget.cards.length,
                    onPageChanged: (index) {
                      setState(() => _activeIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final selected = index == _activeIndex;
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: selected ? 1 : 0.96,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: selected ? 1 : 0.68,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: widget.cards[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next card',
                enabled: canGoForward,
                onPressed: () => _goTo(_activeIndex + 1),
              ),
            ],
          ),
        ),
        if (widget.cards.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cards.length, (index) {
              final selected = index == _activeIndex;
              return GestureDetector(
                onTap: () => _goTo(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.neonCyan
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.38),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            compact
                ? 'Swipe or use the arrows to review every card'
                : 'Drag, scroll or use the arrows to review every card',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? AppTheme.neonCyan.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        side: BorderSide(
          color: enabled
              ? AppTheme.neonCyan.withValues(alpha: 0.52)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      icon: Icon(
        icon,
        color: enabled ? AppTheme.neonCyan : Colors.white24,
        size: 30,
      ),
    );
  }
}

class _OnboardingCarouselScrollBehavior extends MaterialScrollBehavior {
  const _OnboardingCarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
