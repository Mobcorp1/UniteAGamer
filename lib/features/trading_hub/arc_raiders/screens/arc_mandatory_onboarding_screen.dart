import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/build/auth/uag_auth_autofill.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/trader_code_of_conduct_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_legal_acceptance.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_personalisation_builder.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_setup.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum _BlueprintSetupChoice { importScreenshots, manual, later }

class ArcMandatoryOnboardingScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/onboarding';

  const ArcMandatoryOnboardingScreen({
    super.key,
    this.adminPreview = false,
    this.previewAccountCreation = false,
  });

  final bool adminPreview;
  final bool previewAccountCreation;

  static ArcMandatoryOnboardingScreen fromRouteSettings(
    RouteSettings settings,
  ) {
    final args = settings.arguments;
    final adminPreview = args is Map && args['adminPreview'] == true;
    final explicitPreview =
        args is Map && args['previewAccountCreation'] == true;
    final freshPreview =
        args is Map && args['playerState']?.toString() == 'fresh';

    return ArcMandatoryOnboardingScreen(
      adminPreview: adminPreview,
      previewAccountCreation: adminPreview && (explicitPreview || freshPreview),
    );
  }

  @override
  State<ArcMandatoryOnboardingScreen> createState() =>
      _ArcMandatoryOnboardingScreenState();
}

class _ArcMandatoryOnboardingScreenState
    extends State<ArcMandatoryOnboardingScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _riderNameController = TextEditingController();
  final _profileRepository = ArcTraderProfileRepository();
  final _personalisationRepository = ArcUserPersonalisationRepository();

  int _step = 0;
  String? _emailError;
  String? _confirmEmailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _riderNameError;
  ArcPersonalisationGoal? _primaryGoal;
  _BlueprintSetupChoice _blueprintSetupChoice =
      _BlueprintSetupChoice.importScreenshots;
  bool _acceptedTraderCode = false;
  bool _acceptedTermsOfService = false;
  bool _acceptedDataSecurity = false;
  bool _accountCreatedDuringOnboarding = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _saving = false;

  static const _goalOptions = <_GoalOption>[
    _GoalOption(
      ArcPersonalisationGoal.completeBlueprints,
      'Complete my Blueprint grid',
      Icons.grid_view_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.planRaids,
      'Find Blueprints and map intel',
      Icons.radar_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.findSquads,
      'Find Raiders to play with',
      Icons.groups_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.tradeBlueprints,
      'Trade with other Raiders',
      Icons.swap_horiz_rounded,
    ),
    _GoalOption(
      ArcPersonalisationGoal.exploreEverything,
      'Explore everything',
      Icons.explore_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final existing = user?.displayName?.trim() ?? '';
    if (existing.isNotEmpty) _riderNameController.text = existing;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      _acceptedTraderCode && _acceptedTermsOfService && _acceptedDataSecurity;

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (widget.adminPreview && widget.previewAccountCreation) {
        if (!_validateAccountStep()) return;
      } else if (_showsAccountCreationStep) {
        final created = await _createOnboardingAccount();
        if (!created || !mounted) return;
      } else {
        final error = validateArcRiderName(_riderNameController.text);
        setState(() => _riderNameError = error);
        if (error != null) return;
      }
    }
    if (_step == 1 && !_legalComplete) {
      _showMessage('Accept all three agreements to continue.');
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
    final confirmEmail = _confirmEmailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final riderName = _riderNameController.text;

    final emailError = validateArcOnboardingEmail(email);
    final confirmEmailError = validateArcOnboardingConfirmEmail(
      email: email,
      confirmEmail: confirmEmail,
    );
    final passwordError = validateArcOnboardingPassword(password);
    final confirmPasswordError = validateArcOnboardingConfirmPassword(
      password: password,
      confirmPassword: confirmPassword,
    );
    final riderNameError = validateArcRiderName(riderName);

    setState(() {
      _emailError = emailError;
      _confirmEmailError = confirmEmailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _riderNameError = riderNameError;
    });

    return emailError == null &&
        confirmEmailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        riderNameError == null;
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
    setState(() => _saving = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = await _waitForSignedInUser(credential);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            buildArcOnboardingAccountCreationPayload(
              email: email,
              riderName: riderName,
            ),
            SetOptions(merge: true),
          );

      if (user.displayName != riderName) {
        await user.updateDisplayName(riderName);
      }

      unawaited(
        user.sendEmailVerification().catchError((Object error, StackTrace st) {
          debugPrint('Onboarding verification email failed safely: $error');
          debugPrintStack(stackTrace: st);
        }),
      );

      await UagSessionGateController.markAuthenticated(
        uid: user.uid,
        keepSignedIn: true,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uag_last_login_email', email);
      await prefs.setBool('uag_remember_email', true);
      await prefs.setBool('hasCompletedOnboarding', false);
      await prefs.setBool('hasCompletedProfileSetup', false);
      await prefs.setBool('forceOnboarding', false);
      await prefs.setString('displayName', riderName);

      if (!mounted) return false;
      setState(() {
        _accountCreatedDuringOnboarding = true;
        _emailError = null;
        _confirmEmailError = null;
        _passwordError = null;
        _confirmPasswordError = null;
        _riderNameError = null;
        _saving = false;
      });
      return true;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return false;
      setState(() => _saving = false);
      _showMessage(_accountCreationErrorMessage(error));
      return false;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _saving = false);
      _showMessage('Could not create your account. Try again.');
      debugPrint('Onboarding account creation failed: $error');
      return false;
    }
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
    if (nameError != null || primaryGoal == null || !_legalComplete) {
      _showMessage('Complete the required setup first.');
      return;
    }

    setState(() => _saving = true);

    final legalAccepted = buildOnboardingLegalAcceptedMap(
      traderCodeAccepted: _acceptedTraderCode,
      termsOfServiceAccepted: _acceptedTermsOfService,
      dataSecurityAccepted: _acceptedDataSecurity,
    );
    final payload = buildArcOnboardingCompletionPayload(
      riderName: riderName,
      primaryGoal: primaryGoal.name,
      blueprintSetupMode: _blueprintSetupChoice.name,
      recommendedFirstSystem: arcOnboardingRecommendedSystem(primaryGoal),
      legalAccepted: legalAccepted,
      accountCreatedDuringOnboarding: _accountCreatedDuringOnboarding,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
      await prefs.setBool('hasCompletedProfileSetup', false);
      await prefs.setBool('forceOnboarding', false);
      await prefs.setString('displayName', riderName);

      await UagSessionGateController.markAuthenticated(
        uid: user.uid,
        keepSignedIn: true,
      );

      final personalisation = buildArcOnboardingPersonalisation(
        primaryGoal: primaryGoal,
      );
      unawaited(_runNonBlockingProfileSync(user, riderName, personalisation));

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(ArcCommandCentreScreen.routeName, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Command Centre activation failed. Try again.');
      debugPrint('Onboarding completion failed: $error');
    }
  }

  Future<void> _runNonBlockingProfileSync(
    User user,
    String riderName,
    ArcUserPersonalisationProfile personalisation,
  ) async {
    try {
      await Future.wait<void>([
        if (user.displayName != riderName) user.updateDisplayName(riderName),
        _personalisationRepository.markComplete(personalisation),
        _profileRepository.refreshProfileCompletion(),
      ]).timeout(const Duration(seconds: 12));
    } catch (error, stackTrace) {
      debugPrint('Deferred onboarding profile sync failed safely: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showsAccountCreationStep = _showsAccountCreationStep;
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'Signed-in account';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      if (widget.adminPreview) const _PreviewBanner(),
                      _TopBar(step: _step, onBack: _back),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            showsAccountCreationStep
                                ? _AccountCreationStep(
                                    emailController: _emailController,
                                    confirmEmailController:
                                        _confirmEmailController,
                                    passwordController: _passwordController,
                                    confirmPasswordController:
                                        _confirmPasswordController,
                                    riderNameController: _riderNameController,
                                    emailError: _emailError,
                                    confirmEmailError: _confirmEmailError,
                                    passwordError: _passwordError,
                                    confirmPasswordError: _confirmPasswordError,
                                    riderNameError: _riderNameError,
                                    showPassword: _showPassword,
                                    showConfirmPassword: _showConfirmPassword,
                                    onChanged: () {
                                      if (_emailError != null ||
                                          _confirmEmailError != null ||
                                          _passwordError != null ||
                                          _confirmPasswordError != null ||
                                          _riderNameError != null) {
                                        setState(() {
                                          _emailError = null;
                                          _confirmEmailError = null;
                                          _passwordError = null;
                                          _confirmPasswordError = null;
                                          _riderNameError = null;
                                        });
                                      }
                                    },
                                    onTogglePassword: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    onToggleConfirmPassword: () => setState(
                                      () => _showConfirmPassword =
                                          !_showConfirmPassword,
                                    ),
                                  )
                                : _IdentityStep(
                                    email: email,
                                    controller: _riderNameController,
                                    errorText: _riderNameError,
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
                              onTraderCodeChanged: (value) =>
                                  setState(() => _acceptedTraderCode = value),
                              onTermsChanged: (value) => setState(
                                () => _acceptedTermsOfService = value,
                              ),
                              onDataChanged: (value) =>
                                  setState(() => _acceptedDataSecurity = value),
                              openTraderCode: () => _openLegalDocument(
                                const TraderCodeOfConductScreen(),
                              ),
                              openTerms: () =>
                                  _openLegalDocument(const TermsOfUseScreen()),
                              openPrivacy: () => _openLegalDocument(
                                const PrivacyPolicyScreen(),
                              ),
                            ),
                            _GoalStep(
                              selected: _primaryGoal,
                              options: _goalOptions,
                              onSelected: (goal) =>
                                  setState(() => _primaryGoal = goal),
                            ),
                            _BlueprintStep(
                              selected: _blueprintSetupChoice,
                              onSelected: (choice) => setState(
                                () => _blueprintSetupChoice = choice,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                                      : 'INITIALISING COMMAND CENTRE...')
                                : _step == 3
                                ? (widget.adminPreview
                                      ? 'CLOSE PREVIEW'
                                      : 'ENTER COMMAND CENTRE')
                                : 'CONTINUE',
                          ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (step > 0)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                'RAIDER INITIALIZATION',
                style: AppTheme.tradingHeading(
                  fontSize: 20,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: index <= step ? AppTheme.neonCyan : Colors.white12,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.38),
        ),
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppTheme.neonCyan),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.tradingHeading(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _AccountCreationStep extends StatelessWidget {
  const _AccountCreationStep({
    required this.emailController,
    required this.confirmEmailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.riderNameController,
    required this.emailError,
    required this.confirmEmailError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.riderNameError,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  final TextEditingController emailController;
  final TextEditingController confirmEmailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController riderNameController;
  final String? emailError;
  final String? confirmEmailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? riderNameError;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.person_add_alt_1_rounded,
      title: 'CREATE YOUR RAIDER ACCOUNT',
      subtitle: 'Set the account and Raider name used for Command Centre.',
      child: AutofillGroup(
        child: Column(
          children: [
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
              controller: confirmEmailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: UagAuthAutofill.registrationEmail,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: true,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Confirm email address',
                prefixIcon: const Icon(Icons.mark_email_read_outlined),
                errorText: confirmEmailError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              autofillHints: UagAuthAutofill.newPassword,
              textInputAction: TextInputAction.next,
              obscureText: !showPassword,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: passwordError,
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
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              autofillHints: UagAuthAutofill.newPassword,
              textInputAction: TextInputAction.next,
              obscureText: !showConfirmPassword,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                errorText: confirmPasswordError,
                suffixIcon: IconButton(
                  tooltip: showConfirmPassword
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: onToggleConfirmPassword,
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: riderNameController,
              autofillHints: UagAuthAutofill.displayName,
              textInputAction: TextInputAction.done,
              maxLength: 24,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Raider name',
                hintText: 'Enter your display name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                errorText: riderNameError,
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
    required this.onChanged,
  });
  final String email;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.badge_outlined,
      title: 'IDENTIFY YOUR RAIDER',
      subtitle:
          'Your account is ready. Choose the name other Raiders will see.',
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
    required this.onTraderCodeChanged,
    required this.onTermsChanged,
    required this.onDataChanged,
    required this.openTraderCode,
    required this.openTerms,
    required this.openPrivacy,
  });
  final bool traderCode;
  final bool terms;
  final bool dataSecurity;
  final ValueChanged<bool> onTraderCodeChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onDataChanged;
  final VoidCallback openTraderCode;
  final VoidCallback openTerms;
  final VoidCallback openPrivacy;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      icon: Icons.verified_user_outlined,
      title: 'COMMAND PROTOCOLS',
      subtitle: 'Three required agreements. Read them at any time.',
      child: Column(
        children: [
          _AgreementTile(
            title: 'Community Code',
            value: traderCode,
            onChanged: onTraderCodeChanged,
            onOpen: openTraderCode,
          ),
          _AgreementTile(
            title: 'Terms of Service',
            value: terms,
            onChanged: onTermsChanged,
            onOpen: openTerms,
          ),
          _AgreementTile(
            title: 'Privacy & Data',
            value: dataSecurity,
            onChanged: onDataChanged,
            onOpen: openPrivacy,
          ),
        ],
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onOpen,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black26,
      child: CheckboxListTile(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        title: Text(title),
        secondary: IconButton(
          tooltip: 'Read document',
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded),
        ),
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
      child: Column(
        children: [
          for (final option in options)
            Padding(
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
        ],
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
        'ADMIN PREVIEW — no live onboarding data will be changed.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.neonPink),
      ),
    );
  }
}
