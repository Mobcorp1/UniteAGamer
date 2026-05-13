import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_traders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_traders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_traders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/widgets/uag_form_dropdown_field.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth';

  final bool initialIsLogin;

  const AuthScreen({super.key, this.initialIsLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  late bool _isLogin;

  String _email = '';
  String _password = '';

  bool _isLoading = false;
  bool _applyForAffiliate = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberEmail = true;
  bool _biometricsAvailable = false;
  bool _biometricLoginEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  final TextEditingController _emailFieldController = TextEditingController();
  final TextEditingController _passwordFieldController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  String _selectedCountry = 'United Kingdom';
  String _selectedPlatform = 'PC';
  String _selectedTimeZone = 'Europe/London';
  String _selectedPayoutMethod = 'Bank Transfer';

  Color _borderColor = AppTheme.neonCyan;

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

  static const List<String> _payoutMethods = <String>[
    'Bank Transfer',
    'PayPal',
    'Stripe Connect',
  ];

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _loadSavedLoginPreferences();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return false;

      setState(() {
        _borderColor = _borderColor == AppTheme.neonCyan
            ? AppTheme.neonPink
            : AppTheme.neonCyan;
      });

      return true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _resetEmailController.dispose();
    _emailFieldController.dispose();
    _passwordFieldController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLoginPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('uag_last_login_email') ?? '';
      final rememberEmail = prefs.getBool('uag_remember_email') ?? true;
      final biometricEnabled =
          prefs.getBool('uag_biometric_login_enabled') ?? false;
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!mounted) return;
      setState(() {
        _rememberEmail = rememberEmail;
        _biometricLoginEnabled = biometricEnabled;
        _biometricsAvailable = supported && canCheck;
        if (savedEmail.isNotEmpty) {
          _emailFieldController.text = savedEmail;
          _email = savedEmail;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricsAvailable = false;
        _biometricLoginEnabled = false;
      });
    }
  }

  Future<void> _persistLoginPreferences(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('uag_remember_email', _rememberEmail);
    if (_rememberEmail) {
      await prefs.setString('uag_last_login_email', email.trim());
    } else {
      await prefs.remove('uag_last_login_email');
    }
    await prefs.setBool('uag_biometric_login_enabled', _biometricLoginEnabled);
  }

  Future<void> _tryBiometricUnlock() async {
    if (!_biometricsAvailable || !_biometricLoginEnabled) return;

    final currentUser = _firebase.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric unlock is available after you log in once on this device.',
          ),
        ),
      );
      return;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock UAG ARC Raiders Hub',
        biometricOnly: true,
      );

      if (!authenticated || !mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric unlock failed: $error')),
      );
    }
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.length < 6) return 'Minimum 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one capital letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Add at least one number';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!_isLogin && (!_termsAccepted || !_privacyAccepted)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms of Use and Privacy Policy.'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    TextInput.finishAutofillContext();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );
        await _persistLoginPreferences(_email.trim());

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: Text(
              'Thanks for joining the beta',
              style: AppTheme.neonTextStyle(
                fontSize: 24,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
            content: const Text(
              'This beta build does not reflect the full finished app yet. Thanks for testing and helping shape the final launch version.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
      } else {
        final cred = await _firebase.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );

        final user = cred.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-null',
            message: 'Account created but user session not available.',
          );
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _email.trim(),
          'displayName': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'onboardingComplete': false,
          'modules': {'trader': true},
          'region': _selectedCountry == 'United Kingdom'
              ? 'UK'
              : _selectedCountry,
          'uagName': _nameController.text.trim(),
          'visibleInSearch': true,
          'affiliateApplied': _applyForAffiliate,
          'preferredPayoutMethod': _selectedPayoutMethod,
          'referredByCode': _referralCodeController.text.trim(),
          'subscriptionStatus': 'inactive',
          'basicProfile': {
            'displayName': _nameController.text.trim(),
            'email': _email.trim(),
            'country': _selectedCountry,
            'platform': _selectedPlatform,
            'timeZone': _selectedTimeZone,
            'bio': '',
            'games': <String>[],
            'platforms': <String>[_selectedPlatform],
          },
          'traderProfile': {
            'uagName': _nameController.text.trim(),
            'region': _selectedCountry == 'United Kingdom'
                ? 'UK'
                : _selectedCountry,
            'platform': _selectedPlatform,
            'timeZone': _selectedTimeZone,
            'embarkId': '',
            'uagId': '',
          },
          'legalAccepted': {
            'termsAccepted': true,
            'termsVersion': 1,
            'termsAcceptedAt': FieldValue.serverTimestamp(),
            'privacyAccepted': true,
            'privacyVersion': 1,
            'privacyAcceptedAt': FieldValue.serverTimestamp(),
            'fanDisclaimerAccepted': false,
            'fanDisclaimerVersion': 1,
          },
        }, SetOptions(merge: true));

        await _persistLoginPreferences(_email.trim());

        if (!mounted) return;

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppEntryGate.routeName, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not complete sign in: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final currentTypedEmail = _emailFieldController.text.trim();
    _resetEmailController.text = currentTypedEmail.isNotEmpty
        ? currentTypedEmail
        : _email.trim();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Reset password',
            style: AppTheme.neonTextStyle(
              fontSize: 26,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          content: TextField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = _resetEmailController.text.trim();
                if (email.isEmpty) return;

                await _firebase.sendPasswordResetEmail(email: email);

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent')),
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.neonPink),
      ),
    );
  }

  Future<void> _openTerms() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
  }

  Future<void> _openPrivacy() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    FormFieldSetter<String>? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: _inputDecoration(
        label,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildSignupFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration('Display name'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Display name is required'
              : null,
        ),
        const SizedBox(height: AppTheme.spaceM),
        UagFormDropdownField(
          value: _selectedCountry,
          label: 'Country',
          items: _countries,
          decoration: _inputDecoration('Country'),
          onChanged: (value) => setState(() {
            _selectedCountry = value ?? _selectedCountry;
          }),
        ),
        const SizedBox(height: AppTheme.spaceM),
        UagFormDropdownField(
          value: _selectedPlatform,
          label: 'Platform',
          items: _platforms,
          decoration: _inputDecoration('Platform'),
          onChanged: (value) => setState(() {
            _selectedPlatform = value ?? _selectedPlatform;
          }),
        ),
        const SizedBox(height: AppTheme.spaceM),
        UagFormDropdownField(
          value: _selectedTimeZone,
          label: 'Timezone',
          items: _timeZones,
          decoration: _inputDecoration('Timezone'),
          onChanged: (value) => setState(() {
            _selectedTimeZone = value ?? _selectedTimeZone;
          }),
        ),
        const SizedBox(height: AppTheme.spaceM),
        TextFormField(
          controller: _referralCodeController,
          decoration: _inputDecoration('Referral Code (optional)'),
        ),
        const SizedBox(height: AppTheme.spaceM),
        UagFormDropdownField(
          value: _selectedPayoutMethod,
          label: 'Preferred payout method',
          items: _payoutMethods,
          decoration: _inputDecoration('Preferred payout method'),
          onChanged: (value) => setState(() {
            _selectedPayoutMethod = value ?? _selectedPayoutMethod;
          }),
        ),
        SwitchListTile(
          value: _applyForAffiliate,
          onChanged: (value) => setState(() => _applyForAffiliate = value),
          title: const Text('Apply for affiliate programme'),
        ),
        CheckboxListTile(
          value: _termsAccepted,
          onChanged: (value) => setState(() => _termsAccepted = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I agree to the Terms of Use'),
          subtitle: TextButton(
            onPressed: _openTerms,
            child: const Text('Read Terms of Use'),
          ),
        ),
        CheckboxListTile(
          value: _privacyAccepted,
          onChanged: (value) =>
              setState(() => _privacyAccepted = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I agree to the Privacy Policy'),
          subtitle: TextButton(
            onPressed: _openPrivacy,
            child: const Text('Read Privacy Policy'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                decoration: AppTheme.tradingCardDecoration(
                  borderColor: _borderColor.withValues(alpha: 0.32),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            _isLogin ? 'Welcome Back' : 'Join Traders Hub',
                            textStyle: AppTheme.tradingHeading(
                              fontSize: 28,
                              color: AppTheme.neonPink,
                            ),
                            speed: const Duration(milliseconds: 70),
                          ),
                        ],
                        totalRepeatCount: 1,
                        displayFullTextOnTap: true,
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      if (!_isLogin) _buildSignupFields(),
                      TextFormField(
                        controller: _emailFieldController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Email'),
                        onSaved: (value) => _email = value?.trim() ?? '',
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      CheckboxListTile(
                        value: _rememberEmail,
                        onChanged: (value) =>
                            setState(() => _rememberEmail = value ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remember my email on this device'),
                      ),
                      if (_isLogin && _biometricsAvailable) ...[
                        SwitchListTile(
                          value: _biometricLoginEnabled,
                          onChanged: (value) =>
                              setState(() => _biometricLoginEnabled = value),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Enable biometric unlock after login',
                          ),
                          subtitle: const Text(
                            'Uses your device fingerprint/face unlock when an account session is already saved.',
                          ),
                        ),
                        if (_biometricLoginEnabled)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _tryBiometricUnlock,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Unlock with biometrics'),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppTheme.spaceM),
                      _buildPasswordField(
                        controller: _passwordFieldController,
                        label: 'Password',
                        isVisible: _showPassword,
                        onToggle: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        onSaved: (value) => _password = value?.trim() ?? '',
                        validator: _validatePassword,
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: AppTheme.spaceM),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          isVisible: _showConfirmPassword,
                          onToggle: () {
                            setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            );
                          },
                          validator: (value) =>
                              value != _passwordFieldController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                      ],
                      const SizedBox(height: AppTheme.spaceL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: Text(
                            _isLoading
                                ? 'Please wait...'
                                : (_isLogin ? 'Log In' : 'Create Account'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      if (_isLogin)
                        TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: const Text('Forgot password?'),
                        ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Need an account? Sign up'
                              : 'Already have an account? Log in',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
