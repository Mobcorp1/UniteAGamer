import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/build/auth/uag_auth_autofill.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/features/onboarding/screens/uag_raider_agreement_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_legal_acceptance.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_personalisation_builder.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_setup.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_journey_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_game_platform_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum _BlueprintSetupChoice { importScreenshots, manual, later }

class ArcMandatoryOnboardingScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/onboarding';

  const ArcMandatoryOnboardingScreen({
    super.key,
    this.adminPreview = false,
    this.previewAccountCreation = false,
    this.initialStep = 0,
  });

  final bool adminPreview;
  final bool previewAccountCreation;
  final int initialStep;

  static ArcMandatoryOnboardingScreen fromRouteSettings(
    RouteSettings settings,
  ) {
    final args = settings.arguments;
    final adminPreview = args is Map && args['adminPreview'] == true;
    final explicitPreview =
        args is Map && args['previewAccountCreation'] == true;
    final freshPreview =
        args is Map && args['playerState']?.toString() == 'fresh';
    final requestedStep = args is Map && args['step'] is int
        ? args['step'] as int
        : 0;

    return ArcMandatoryOnboardingScreen(
      adminPreview: adminPreview,
      previewAccountCreation: adminPreview && (explicitPreview || freshPreview),
      initialStep: requestedStep.clamp(0, 3),
    );
  }

  @override
  State<ArcMandatoryOnboardingScreen> createState() =>
      _ArcMandatoryOnboardingScreenState();
}

class _ArcMandatoryOnboardingScreenState
    extends State<ArcMandatoryOnboardingScreen> {
  PageController _pageController = PageController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _riderNameController = TextEditingController();
  final _profileRepository = ArcTraderProfileRepository();
  final _personalisationRepository = ArcUserPersonalisationRepository();

  int _step = 0;
  String? _emailError;
  String? _passwordError;
  String? _riderNameError;
  String? _platformError;
  final Set<String> _selectedPlatforms = <String>{};
  ArcPersonalisationGoal? _primaryGoal;
  _BlueprintSetupChoice _blueprintSetupChoice =
      _BlueprintSetupChoice.importScreenshots;
  bool _acceptedTraderCode = false;
  bool _acceptedTermsOfService = false;
  bool _acceptedDataSecurity = false;
  bool _acceptedAgeConfirmation = false;
  bool _accountCreatedDuringOnboarding = false;
  bool _showPassword = false;
  bool _rememberEmail = true;
  bool _keepSignedIn = true;
  bool _saving = false;

  static const _goalOptions = <_GoalOption>[
    _GoalOption(
      ArcPersonalisationGoal.completeBlueprints,
      'Blueprints & map intel',
      Icons.grid_view_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.progressQuests,
      'Track quests & upgrades',
      Icons.flag_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.planRaids,
      'Plan my raids',
      Icons.map_outlined,
    ),
    _GoalOption(
      ArcPersonalisationGoal.tradeBlueprints,
      'Trade with other Raiders',
      Icons.swap_horiz_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.buildFavouriteLoadout,
      'Build my ideal loadout',
      Icons.construction_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.findSquads,
      'Find Raiders to play with',
      Icons.groups_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.exploreEverything,
      'Show me everything',
      Icons.explore_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _step = widget.adminPreview ? widget.initialStep.clamp(0, 3) : 0;
    if (_step > 0) {
      _pageController.dispose();
      _pageController = PageController(initialPage: _step);
    }
    final user = FirebaseAuth.instance.currentUser;
    final existing = user?.displayName?.trim() ?? '';
    if (existing.isNotEmpty) _riderNameController.text = existing;
    if (user != null) unawaited(_loadExistingPlatforms());
  }

  Future<void> _loadExistingPlatforms() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted || profile.normalisedPlatforms.isEmpty) return;
      setState(() {
        _selectedPlatforms
          ..clear()
          ..addAll(profile.normalisedPlatforms);
        _platformError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Onboarding platform preload skipped safely: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _riderNameController.dispose();
    super.dispose();
  }

  bool get _showsAccountCreationStep => shouldShowArcOnboardingAccountCreation(
    adminPreview: widget.adminPreview,
    previewAccountCreation: widget.previewAccountCreation,
    accountCreatedDuringOnboarding: _accountCreatedDuringOnboarding,
    hasCurrentUser: FirebaseAuth.instance.currentUser != null,
  );

  bool get _legalComplete =>
      _acceptedTraderCode &&
      _acceptedTermsOfService &&
      _acceptedDataSecurity &&
      _acceptedAgeConfirmation;

  String get _completionRouteName => ArcRaidersHubScreen.routeName;

  Future<void> _next() async {
    FocusScope.of(context).unfocus();

    // Admin Console preview is view-only: allow an administrator to inspect
    // every onboarding page without satisfying player validation or writing
    // onboarding/account data. The real player journey below remains strict.
    if (widget.adminPreview) {
      if (_step >= 3) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      setState(() => _step += 1);
      await _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_step == 0) {
      if (widget.adminPreview && widget.previewAccountCreation) {
        if (!_validateAccountStep()) return;
      } else if (_showsAccountCreationStep) {
        final created = await _createOnboardingAccount();
        if (!created || !mounted) return;
      } else {
        final error = validateArcRiderName(_riderNameController.text);
        final platformError = _selectedPlatforms.isEmpty
            ? 'Choose at least one platform.'
            : null;
        setState(() {
          _riderNameError = error;
          _platformError = platformError;
        });
        if (error != null || platformError != null) return;
      }
    }
    if (_step == 1 && !_legalComplete) {
      _showMessage('Accept all required agreements to continue.');
      return;
    }
    if (_step == 2 && _primaryGoal == null) {
      _showMessage('Choose one main goal.');
      return;
    }
    if (_step >= 3) {
      _completeSetup();
      return;
    }
    setState(() => _step += 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool _validateAccountStep() {
    final email = _emailController.text;
    final password = _passwordController.text;
    final riderName = _riderNameController.text;

    final emailError = validateArcOnboardingEmail(email);
    final passwordError = validateArcOnboardingPassword(password);
    final riderNameError = validateArcRiderName(riderName);
    final platformError = _selectedPlatforms.isEmpty
        ? 'Choose at least one platform.'
        : null;

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _riderNameError = riderNameError;
      _platformError = platformError;
    });

    return emailError == null &&
        passwordError == null &&
        riderNameError == null &&
        platformError == null;
  }

  Future<User> _waitForSignedInUser(UserCredential credential) async {
    final user = credential.user ?? FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .where((next) => next != null)
          .map((next) => next!)
          .first
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Account created but the signed-in session was not available.',
      );
    }
  }

  Future<User?> _currentSignedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .where((next) => next != null)
          .map((next) => next!)
          .first
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      return null;
    }
  }

  String _accountCreationErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' =>
        'That email already has an account. Log in instead.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password.',
      'network-request-failed' =>
        'Network connection failed. Check your connection and try again.',
      _ => error.message ?? 'Account creation failed. Try again.',
    };
  }

  Future<bool> _createOnboardingAccount() async {
    if (!_validateAccountStep()) return false;

    final email = normalizeArcOnboardingEmail(_emailController.text);
    final password = _passwordController.text.trim();
    final riderName = _riderNameController.text.trim();

    TextInput.finishAutofillContext();
    UagSessionGateController.markOnboardingAuthHandshakeStarted();
    setState(() => _saving = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = await _waitForSignedInUser(credential);

      await _completeAccountCreationHandoff(
        user: user,
        email: email,
        riderName: riderName,
      );

      if (!mounted) return false;
      setState(() {
        _accountCreatedDuringOnboarding = true;
        _emailError = null;
        _passwordError = null;
        _riderNameError = null;
        _platformError = null;
        _saving = false;
      });
      return true;
    } on FirebaseAuthException catch (error) {
      UagSessionGateController.clearOnboardingAuthHandshake();
      if (!mounted) return false;
      setState(() => _saving = false);
      _showMessage(_accountCreationErrorMessage(error));
      return false;
    } catch (error) {
      UagSessionGateController.clearOnboardingAuthHandshake();
      if (!mounted) return false;
      setState(() => _saving = false);
      _showMessage('Could not create your account. Try again.');
      debugPrint('Onboarding account creation failed: $error');
      return false;
    }
  }

  Future<void> _completeAccountCreationHandoff({
    required User user,
    required String email,
    required String riderName,
  }) async {
    await Future.wait<void>([
      UagSessionGateController.markAuthenticated(
        uid: user.uid,
        keepSignedIn: _keepSignedIn,
      ),
      _persistOnboardingDevicePrefs(email: email, riderName: riderName),
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            buildArcOnboardingAccountCreationPayload(
              email: email,
              riderName: riderName,
              platforms: _selectedPlatforms,
            ),
            SetOptions(merge: true),
          ),
      if (user.displayName != riderName) user.updateDisplayName(riderName),
    ]).timeout(const Duration(seconds: 12));

    unawaited(
      user.sendEmailVerification().catchError((Object error, StackTrace st) {
        debugPrint('Onboarding verification email failed safely: $error');
        debugPrintStack(stackTrace: st);
      }),
    );
  }

  Future<void> _persistOnboardingDevicePrefs({
    required String email,
    required String riderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('uag_remember_email', _rememberEmail);
    if (_rememberEmail) {
      await prefs.setString('uag_last_login_email', email);
    } else {
      await prefs.remove('uag_last_login_email');
    }
    await prefs.setBool('hasCompletedOnboarding', false);
    await prefs.setBool('hasCompletedProfileSetup', false);
    await prefs.setBool('forceOnboarding', false);
    await prefs.setString('displayName', riderName);
  }

  void _back() {
    if (_saving || _step == 0) return;
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openRaiderAgreement() async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const UagRaiderAgreementScreen(),
        fullscreenDialog: true,
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _acceptedTraderCode = true;
      _acceptedTermsOfService = true;
      _acceptedDataSecurity = true;
    });
  }

  Future<void> _openLegalDocument(Widget screen) {
    return Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _completeSetup() async {
    if (_saving) return;
    if (widget.adminPreview) {
      Navigator.of(context).pop();
      return;
    }

    final user = await _currentSignedInUser();
    final primaryGoal = _primaryGoal;
    final riderName = _riderNameController.text.trim();
    final nameError = validateArcRiderName(riderName);

    if (user == null) {
      setState(() => _step = 0);
      _pageController.jumpToPage(0);
      _showMessage('Create your account first.');
      return;
    }
    if (nameError != null ||
        _selectedPlatforms.isEmpty ||
        primaryGoal == null ||
        !_legalComplete) {
      setState(() {
        _riderNameError = nameError;
        _platformError = _selectedPlatforms.isEmpty
            ? 'Choose at least one platform.'
            : null;
      });
      _showMessage('Complete the required setup first.');
      return;
    }

    setState(() => _saving = true);

    final legalAccepted = buildOnboardingLegalAcceptedMap(
      traderCodeAccepted: _acceptedTraderCode,
      termsOfServiceAccepted: _acceptedTermsOfService,
      dataSecurityAccepted: _acceptedDataSecurity,
      ageConfirmationAccepted: _acceptedAgeConfirmation,
      userId: user.uid,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      appVersion: 'closed-beta',
    );
    final payload = buildArcOnboardingCompletionPayload(
      riderName: riderName,
      primaryGoal: primaryGoal.name,
      blueprintSetupMode: _blueprintSetupChoice.name,
      recommendedFirstSystem: arcOnboardingRecommendedSystem(primaryGoal),
      legalAccepted: legalAccepted,
      platforms: _selectedPlatforms,
      accountCreatedDuringOnboarding: _accountCreatedDuringOnboarding,
    );
    final accountProfilePayload = _accountCreatedDuringOnboarding
        ? buildArcOnboardingAccountProfilePayload(
            email: normalizeArcOnboardingEmail(
              user.email ?? _emailController.text,
            ),
            riderName: riderName,
            platforms: _selectedPlatforms,
          )
        : const <String, dynamic>{};

    try {
      final personalisation = buildArcOnboardingPersonalisation(
        primaryGoal: primaryGoal,
      );

      // These writes are part of successful onboarding. Do not navigate into
      // the app with a default "show everything" profile if they fail.
      await Future.wait<void>([
        _personalisationRepository.markComplete(personalisation),
        _profileRepository.savePlatformSelection(_selectedPlatforms),
        if (user.displayName != riderName) user.updateDisplayName(riderName),
      ]).timeout(const Duration(seconds: 12));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...accountProfilePayload,
        ...payload,
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
      await prefs.setBool('hasCompletedProfileSetup', false);
      await prefs.setBool('forceOnboarding', false);
      await prefs.setString('displayName', riderName);

      if (_accountCreatedDuringOnboarding) {
        await UagSessionGateController.markAuthenticated(
          uid: user.uid,
          keepSignedIn: _keepSignedIn,
        );
      } else {
        await UagSessionGateController.markAuthenticatedWithStoredPreference(
          uid: user.uid,
        );
      }

      unawaited(_profileRepository.refreshProfileCompletion());

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(_completionRouteName, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('ARC Systems activation failed. Try again.');
      debugPrint('Onboarding completion failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showsAccountCreationStep = _showsAccountCreationStep;
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'Signed-in account';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
                  10,
                  MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
                  12,
                ),
                child: Column(
                  children: [
                    if (widget.adminPreview) const _PreviewBanner(),
                    const ArcAccountJourneyBar(
                      stage: ArcAccountJourneyStage.onboarding,
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    _TopBar(step: _step, onBack: _back),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          showsAccountCreationStep
                              ? _AccountCreationStep(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  riderNameController: _riderNameController,
                                  emailError: _emailError,
                                  passwordError: _passwordError,
                                  riderNameError: _riderNameError,
                                  selectedPlatforms: _selectedPlatforms,
                                  platformError: _platformError,
                                  onPlatformsChanged: (platforms) =>
                                      setState(() {
                                        _selectedPlatforms
                                          ..clear()
                                          ..addAll(platforms);
                                        _platformError = null;
                                      }),
                                  showPassword: _showPassword,
                                  rememberEmail: _rememberEmail,
                                  keepSignedIn: _keepSignedIn,
                                  onChanged: () {
                                    if (_emailError != null ||
                                        _passwordError != null ||
                                        _riderNameError != null) {
                                      setState(() {
                                        _emailError = null;
                                        _passwordError = null;
                                        _riderNameError = null;
                                      });
                                    }
                                  },
                                  onTogglePassword: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  onRememberEmailChanged: (value) =>
                                      setState(() => _rememberEmail = value),
                                  onKeepSignedInChanged: (value) =>
                                      setState(() => _keepSignedIn = value),
                                )
                              : _IdentityStep(
                                  email: email,
                                  controller: _riderNameController,
                                  errorText: _riderNameError,
                                  selectedPlatforms: _selectedPlatforms,
                                  platformError: _platformError,
                                  onPlatformsChanged: (platforms) =>
                                      setState(() {
                                        _selectedPlatforms
                                          ..clear()
                                          ..addAll(platforms);
                                        _platformError = null;
                                      }),
                                  onChanged: (_) {
                                    if (_riderNameError != null) {
                                      setState(() => _riderNameError = null);
                                    }
                                  },
                                ),
                          _LegalStep(
                            traderCode: _acceptedTraderCode,
                            terms: _acceptedTermsOfService,
                            dataSecurity: _acceptedDataSecurity,
                            ageConfirmation: _acceptedAgeConfirmation,
                            onTraderCodeChanged: (value) =>
                                setState(() => _acceptedTraderCode = value),
                            onTermsChanged: (value) =>
                                setState(() => _acceptedTermsOfService = value),
                            onDataChanged: (value) =>
                                setState(() => _acceptedDataSecurity = value),
                            onAgeConfirmationChanged: (value) => setState(
                              () => _acceptedAgeConfirmation = value,
                            ),
                            openTraderCode: _openRaiderAgreement,
                            openTerms: () =>
                                _openLegalDocument(const TermsOfUseScreen()),
                            openPrivacy: () =>
                                _openLegalDocument(const PrivacyPolicyScreen()),
                          ),
                          _GoalStep(
                            selected: _primaryGoal,
                            options: _goalOptions,
                            onSelected: (goal) =>
                                setState(() => _primaryGoal = goal),
                          ),
                          _BlueprintStep(
                            selected: _blueprintSetupChoice,
                            onSelected: (choice) =>
                                setState(() => _blueprintSetupChoice = choice),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.16),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _next,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _step == 3
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                          label: Text(
                            _saving
                                ? (_step == 0 && showsAccountCreationStep
                                      ? 'CREATING ACCOUNT...'
                                      : 'INITIALISING ARC SYSTEMS...')
                                : _step == 3
                                ? (widget.adminPreview
                                      ? 'CLOSE PREVIEW'
                                      : 'ENTER UAG')
                                : 'CONTINUE',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  static const _labels = <String>[
    'IDENTITY',
    'AGREEMENTS',
    'OBJECTIVE',
    'BLUEPRINTS',
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 16,
        10,
        compact ? 10 : 16,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE70A1016),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 42,
                child: step > 0
                    ? IconButton(
                        tooltip: 'Previous step',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    : const Icon(
                        Icons.hub_outlined,
                        color: AppTheme.neonCyan,
                        size: 20,
                      ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'RAIDER INITIALIZATION',
                      style: AppTheme.tradingHeading(
                        fontSize: compact ? 18 : 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UAG // ARC NETWORK  •  ${step + 1} OF 4',
                      style: TextStyle(
                        color: AppTheme.neonCyan.withValues(alpha: 0.82),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 42,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${((step + 1) * 25)}%',
                    style: const TextStyle(
                      color: AppTheme.neonPink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (index) {
              final active = index <= step;
              final current = index == step;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: current ? 4 : 3,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.neonCyan : Colors.white12,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: current
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 5),
                        Text(
                          _labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: current ? Colors.white : Colors.white38,
                            fontSize: 9,
                            fontWeight: current
                                ? FontWeight.w800
                                : FontWeight.w600,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final wide = width >= 760;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF20A0F15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _artwork(compact: false, wide: true),
                    ),
                    Expanded(flex: 6, child: _content(compact: false)),
                  ],
                ),
              )
            : Column(
                children: [
                  _artwork(compact: compact, wide: false),
                  _content(compact: compact),
                ],
              ),
      ),
    );
  }

  Widget _artwork({required bool compact, required bool wide}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: wide ? 430 : (compact ? 132 : 158),
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/arc_raiders/hub/auth_bg_landscape.webp'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          compact ? 18 : 24,
          compact ? 16 : 24,
          compact ? 16 : 22,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: wide ? Alignment.topLeft : Alignment.topCenter,
            end: wide ? Alignment.bottomRight : Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: wide ? 0.18 : 0.28),
              const Color(0xF20A0F15),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: wide
              ? MainAxisAlignment.center
              : MainAxisAlignment.end,
          children: [
            Container(
              width: compact ? 44 : 50,
              height: compact ? 44 : 50,
              decoration: BoxDecoration(
                color: const Color(0xD90A1118),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.20),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: compact ? 25 : 29,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.tradingHeading(
                fontSize: compact ? 22 : 27,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: compact ? 12 : 13,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 22,
        compact ? 14 : 20,
        compact ? 14 : 22,
        compact ? 16 : 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.035),
            Colors.transparent,
            AppTheme.neonPink.withValues(alpha: 0.025),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _AccountCreationStep extends StatelessWidget {
  const _AccountCreationStep({
    required this.emailController,
    required this.passwordController,
    required this.riderNameController,
    required this.emailError,
    required this.passwordError,
    required this.riderNameError,
    required this.selectedPlatforms,
    required this.platformError,
    required this.onPlatformsChanged,
    required this.showPassword,
    required this.rememberEmail,
    required this.keepSignedIn,
    required this.onChanged,
    required this.onTogglePassword,
    required this.onRememberEmailChanged,
    required this.onKeepSignedInChanged,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController riderNameController;
  final String? emailError;
  final String? passwordError;
  final String? riderNameError;
  final Set<String> selectedPlatforms;
  final String? platformError;
  final ValueChanged<Set<String>> onPlatformsChanged;
  final bool showPassword;
  final bool rememberEmail;
  final bool keepSignedIn;
  final VoidCallback onChanged;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberEmailChanged;
  final ValueChanged<bool> onKeepSignedInChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.person_add_alt_1_rounded,
      title: 'CREATE YOUR RAIDER ACCOUNT',
      subtitle:
          'Choose your Raider identity and platforms, then secure your account.',
      child: AutofillGroup(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RAIDER IDENTITY',
                    style: AppTheme.tradingHeading(
                      fontSize: 12,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: riderNameController,
                    autofillHints: UagAuthAutofill.displayName,
                    textInputAction: TextInputAction.next,
                    maxLength: 24,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: 'Raider name',
                      hintText: 'Choose your callsign',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: riderNameError,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ArcGamePlatformSelector(
                    selected: selectedPlatforms,
                    errorText: platformError,
                    compact: true,
                    onChanged: onPlatformsChanged,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: UagAuthAutofill.registrationEmail,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: true,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: emailError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              autofillHints: UagAuthAutofill.newPassword,
              textInputAction: TextInputAction.done,
              obscureText: !showPassword,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: passwordError,
                helperText: '6+ characters - 1 capital - 1 number',
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: showPassword ? 'Hide password' : 'Show password',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.security_rounded,
                          size: 18,
                          color: AppTheme.neonCyan.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THIS DEVICE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Choose what this device remembers after setup.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: keepSignedIn,
                    onChanged: onKeepSignedInChanged,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    activeThumbColor: AppTheme.neonCyan,
                    title: const Text(
                      'Keep me signed in',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Recommended on your own device.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: CheckboxListTile(
                      value: rememberEmail,
                      onChanged: (value) =>
                          onRememberEmailChanged(value ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      activeColor: AppTheme.neonCyan,
                      title: const Text(
                        'Remember my email',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: keepSignedIn
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),
                  if (!keepSignedIn)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4, right: 4, bottom: 2),
                        child: Text(
                          'On a shared device, leave both options off.',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
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
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.email,
    required this.controller,
    required this.errorText,
    required this.selectedPlatforms,
    required this.platformError,
    required this.onPlatformsChanged,
    required this.onChanged,
  });
  final String email;
  final TextEditingController controller;
  final String? errorText;
  final Set<String> selectedPlatforms;
  final String? platformError;
  final ValueChanged<Set<String>> onPlatformsChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.badge_outlined,
      title: 'IDENTIFY YOUR RAIDER',
      subtitle:
          'Your account is ready. Confirm your Raider name and platforms.',
      child: Column(
        children: [
          TextField(
            enabled: false,
            controller: TextEditingController(text: email),
            decoration: const InputDecoration(
              labelText: 'Account email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            decoration: InputDecoration(
              labelText: 'Raider name',
              hintText: 'Enter your display name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: errorText,
            ),
          ),
          const SizedBox(height: 12),
          ArcGamePlatformSelector(
            selected: selectedPlatforms,
            errorText: platformError,
            onChanged: onPlatformsChanged,
          ),
        ],
      ),
    );
  }
}

class _LegalStep extends StatelessWidget {
  const _LegalStep({
    required this.traderCode,
    required this.terms,
    required this.dataSecurity,
    required this.ageConfirmation,
    required this.onTraderCodeChanged,
    required this.onTermsChanged,
    required this.onDataChanged,
    required this.onAgeConfirmationChanged,
    required this.openTraderCode,
    required this.openTerms,
    required this.openPrivacy,
  });

  final bool traderCode;
  final bool terms;
  final bool dataSecurity;
  final bool ageConfirmation;
  final ValueChanged<bool> onTraderCodeChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onDataChanged;
  final ValueChanged<bool> onAgeConfirmationChanged;
  final VoidCallback openTraderCode;
  final VoidCallback openTerms;
  final VoidCallback openPrivacy;

  bool get agreementAccepted => traderCode && terms && dataSecurity;

  @override
  Widget build(BuildContext context) {
    // Keep the legacy callbacks referenced so older route wiring stays valid
    // while the user-facing experience is one consolidated agreement.
    final _ = (
      onTraderCodeChanged,
      onTermsChanged,
      onDataChanged,
      openTerms,
      openPrivacy,
    );
    return _StepFrame(
      icon: Icons.verified_user_outlined,
      title: 'COMMAND PROTOCOLS',
      subtitle: 'Read the Raider Agreement and confirm adult eligibility.',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF07111A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: agreementAccepted
                    ? Colors.greenAccent.withValues(alpha: 0.48)
                    : AppTheme.neonCyan.withValues(alpha: 0.34),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAIDER AGREEMENT',
                  style: AppTheme.neonTextStyle(
                    fontSize: 18,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Community Code, Terms, Privacy & Data, trading, payments, advertising, referrals, moderation, safety and UAG fan-project status are combined into one agreement.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: openTraderCode,
                    icon: Icon(
                      agreementAccepted
                          ? Icons.verified_user_rounded
                          : Icons.article_outlined,
                    ),
                    label: Text(
                      agreementAccepted
                          ? 'AGREEMENT READ & ACCEPTED'
                          : 'READ RAIDER AGREEMENT',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF07111A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.28),
              ),
            ),
            child: CheckboxListTile(
              value: ageConfirmation,
              onChanged: (value) => onAgeConfirmationChanged(value == true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.neonPink,
              title: const Text('18+ AGE CONFIRMATION'),
              subtitle: const Text(
                'I confirm I am 18 years of age or older and eligible to create a UAG account.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption(this.goal, this.title, this.icon);
  final ArcPersonalisationGoal goal;
  final String title;
  final IconData icon;
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.options,
    required this.onSelected,
  });
  final ArcPersonalisationGoal? selected;
  final List<_GoalOption> options;
  final ValueChanged<ArcPersonalisationGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.track_changes_rounded,
      title: 'YOUR FIRST OBJECTIVE',
      subtitle: 'Pick one. The Command Centre will adapt around it.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useGrid = constraints.maxWidth >= 620;
          final tiles = options
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected == option.goal
                            ? AppTheme.neonCyan
                            : Colors.white12,
                      ),
                    ),
                    tileColor: selected == option.goal
                        ? AppTheme.neonCyan.withValues(alpha: 0.10)
                        : Colors.black26,
                    leading: Icon(option.icon, color: AppTheme.neonCyan),
                    title: Text(option.title),
                    trailing: Icon(
                      selected == option.goal
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected == option.goal
                          ? AppTheme.neonCyan
                          : Colors.white38,
                    ),
                    onTap: () => onSelected(option.goal),
                  ),
                ),
              )
              .toList(growable: false);

          if (!useGrid) return Column(children: tiles);

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 2,
            children: tiles,
          );
        },
      ),
    );
  }
}

class _BlueprintStep extends StatelessWidget {
  const _BlueprintStep({required this.selected, required this.onSelected});
  final _BlueprintSetupChoice selected;
  final ValueChanged<_BlueprintSetupChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.grid_on_rounded,
      title: 'BLUEPRINT SETUP',
      subtitle: 'Choose how you want to build your tracker.',
      child: Column(
        children: [
          _ChoiceTile(
            icon: Icons.camera_alt_outlined,
            title: 'Import screenshots',
            badge: 'RECOMMENDED',
            selected: selected == _BlueprintSetupChoice.importScreenshots,
            onTap: () => onSelected(_BlueprintSetupChoice.importScreenshots),
          ),
          _ChoiceTile(
            icon: Icons.touch_app_rounded,
            title: 'Set up manually',
            selected: selected == _BlueprintSetupChoice.manual,
            onTap: () => onSelected(_BlueprintSetupChoice.manual),
          ),
          _ChoiceTile(
            icon: Icons.schedule_rounded,
            title: 'Skip for now',
            selected: selected == _BlueprintSetupChoice.later,
            onTap: () => onSelected(_BlueprintSetupChoice.later),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String title;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppTheme.neonPink : Colors.white12,
          ),
        ),
        tileColor: selected
            ? AppTheme.neonPink.withValues(alpha: 0.10)
            : Colors.black26,
        leading: Icon(
          icon,
          color: selected ? AppTheme.neonPink : Colors.white70,
        ),
        title: Text(title),
        subtitle: badge == null
            ? null
            : Text(
                badge!,
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: selected ? AppTheme.neonPink : Colors.white38,
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink,
      ),
      child: const Text(
        'ADMIN PREVIEW - no live onboarding data will be changed.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.neonPink),
      ),
    );
  }
}
