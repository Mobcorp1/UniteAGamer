import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../data/arc_game_platform_catalog.dart';
import '../data/uag_avatar_catalog.dart';
import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../models/arc_profile_social_models.dart';
import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';
import '../widgets/arc_account_journey_bar.dart';
import '../widgets/arc_game_platform_selector.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/arc_social_links_editor.dart';
import '../widgets/uag_avatar_locker_sheet.dart';
import '../widgets/uag_raider_avatar.dart';
import '../widgets/foundation/arc_form_surface.dart';
import '../widgets/foundation/arc_ui_tokens.dart';

class ArcProfileSetupScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile/setup';

  const ArcProfileSetupScreen({super.key, this.firstRunFlow = false});

  final bool firstRunFlow;

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
  late final TextEditingController _timezoneController;
  late final TextEditingController _referredByController;

  String _avatarId = UagAvatarCatalog.defaultId;
  bool _visibleInSearch = true;
  bool _micOk = true;
  bool _crossRegionOk = false;
  bool _crossPlatformOk = true;
  bool _affiliateEnabled = false;
  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _platformError;
  final Set<String> _platforms = <String>{};
  final Set<String> _archetypes = {'Balanced Raider'};
  final Set<String> _playStyles = {'PvE defensive'};
  String _communicationStyle = 'Flexible';
  String _squadIntent = 'Flexible';
  String _socialEnergy = 'Depends on the day';
  String _sessionIntent = ArcPlayerSessionCatalog.defaultIntent;
  String _currentPriority = ArcPlayerSessionCatalog.defaultPriority;
  String _payoutMethod = 'Bank Transfer';
  List<ArcProfileSocialLink> _socialLinks = const <ArcProfileSocialLink>[];

  static final List<String> _archetypeOptions =
      ArcPlayerArchetypeCatalog.labels;

  static const List<String> _playStyleOptions = <String>[
    'PvE defensive',
    'PvE aggressive',
    'PvP focused',
    'Quest-focused',
    'Blueprint farming',
    'Resource running',
    'Squad support',
  ];

  static const List<String> _communicationOptions = <String>[
    'Flexible',
    'Mic preferred',
    'Ping only',
    'Quiet / low-comms',
    'Chatty / social',
  ];

  static const List<String> _squadIntentOptions = <String>[
    'Flexible',
    'Squad up',
    'Quest team',
    'Blueprint runs',
    'Trade focused',
    'Trials',
    'Solo for now',
  ];

  static const List<String> _socialEnergyOptions = <String>[
    'Depends on the day',
    'Chatty and outgoing',
    'Quiet but cooperative',
    'High energy',
    'Low energy today',
    'Prefer pings over voice',
  ];

  @override
  void initState() {
    super.initState();
    _uagIdController = TextEditingController();
    _uagNameController = TextEditingController();
    _embarkIdController = TextEditingController();
    _regionController = TextEditingController(text: 'UK');
    _timezoneController = TextEditingController(text: 'Europe/London');
    _referredByController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _uagIdController.dispose();
    _uagNameController.dispose();
    _embarkIdController.dispose();
    _regionController.dispose();
    _timezoneController.dispose();
    _referredByController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;

      _uagIdController.text = profile.uagId;
      _uagNameController.text = profile.uagName;
      _avatarId = UagAvatarCatalog.byId(profile.avatarId).id;
      _embarkIdController.text = profile.embarkId;
      _regionController.text = profile.region.isEmpty ? 'UK' : profile.region;
      _platforms
        ..clear()
        ..addAll(profile.normalisedPlatforms);
      _timezoneController.text = profile.timezone.isEmpty
          ? 'Europe/London'
          : profile.timezone;
      _referredByController.text = profile.referredByCode;
      _visibleInSearch = profile.visibleInSearch;
      _micOk = profile.micOk;
      _crossRegionOk = profile.crossRegionOk;
      _crossPlatformOk = profile.crossPlatformOk;
      _affiliateEnabled = profile.affiliateEnabled;
      _archetypes
        ..clear()
        ..addAll(
          profile.archetypes.isEmpty
              ? const ['Balanced Raider']
              : profile.archetypes,
        );
      _playStyles
        ..clear()
        ..addAll(
          profile.playStyles.isEmpty
              ? const ['PvE defensive']
              : profile.playStyles,
        );
      _communicationStyle =
          _communicationOptions.contains(profile.communicationStyle)
          ? profile.communicationStyle
          : 'Flexible';
      _squadIntent = _squadIntentOptions.contains(profile.squadIntent)
          ? profile.squadIntent
          : 'Flexible';
      _socialEnergy = _socialEnergyOptions.contains(profile.socialEnergy)
          ? profile.socialEnergy
          : 'Depends on the day';
      _sessionIntent = ArcPlayerSessionCatalog.normalizeIntent(
        profile.sessionIntent,
      );
      _currentPriority = ArcPlayerSessionCatalog.normalizePriority(
        profile.currentPriority,
      );
      _payoutMethod = profile.payoutMethod.isEmpty
          ? 'Bank Transfer'
          : profile.payoutMethod;
      _socialLinks = profile.socialLinks;

      setState(() => _isLoadingProfile = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final platformValid = _platforms.isNotEmpty;
    setState(() {
      _platformError = platformValid ? null : 'Choose at least one platform.';
    });
    if (!formValid || !platformValid) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final ArcTraderProfile current = await _repository.getProfile();
    final ArcTraderProfile profile = current.copyWith(
      uid: uid,
      uagId: _uagIdController.text.trim(),
      uagName: _uagNameController.text.trim(),
      avatarId: _avatarId,
      avatarType: 'preset',
      embarkId: _embarkIdController.text.trim(),
      region: _regionController.text.trim(),
      platform: ArcGamePlatformCatalog.primary(_platforms),
      platforms: _platforms.toList(growable: false),
      timezone: _timezoneController.text.trim(),
      visibleInSearch: _visibleInSearch,
      micOk: _micOk,
      crossRegionOk: _crossRegionOk,
      crossPlatformOk: _crossPlatformOk,
      archetypes: _archetypes.toList(growable: false),
      playStyles: _playStyles.toList(growable: false),
      communicationStyle: _communicationStyle,
      squadIntent: _squadIntent,
      socialEnergy: _socialEnergy,
      sessionIntent: _sessionIntent,
      currentPriority: _currentPriority,
      socialLinks: _socialLinks,
      affiliateEnabled: _affiliateEnabled,
      payoutMethod: _payoutMethod == 'Not Set' ? '' : _payoutMethod,
      referredByCode: _referredByController.text.trim(),
      isProfileComplete: true,
      createdAt: current.createdAt ?? DateTime.now(),
    );

    try {
      await _repository.saveProfile(profile);
      if (!mounted) return;

      if (!widget.firstRunFlow) {
        Navigator.of(context).pop(true);
        return;
      }

      await Navigator.of(
        context,
      ).pushNamed('/trading-hub/arc-raiders/profile/availability');
      if (!mounted) return;

      final completion = await _repository.refreshProfileCompletion();
      if (!mounted) return;

      if (!completion.complete) {
        final missing = completion.missingFieldLabels.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              missing.isEmpty
                  ? 'Complete the required Raider profile fields first.'
                  : 'Still required: $missing',
            ),
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedProfileSetup', true);
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/app-entry-gate', (_) => false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final selected = await UagAvatarLockerSheet.show(
      context,
      currentAvatarId: _avatarId,
    );
    if (!mounted || selected == null) return;
    setState(() => _avatarId = UagAvatarCatalog.byId(selected).id);
  }

  Widget _identityPreview() {
    return AnimatedBuilder(
      animation: _uagNameController,
      builder: (context, _) => UagRaiderIdentityStrip(
        avatarId: _avatarId,
        displayName: _uagNameController.text,
        uagId: _uagIdController.text,
        onChangeAvatar: _chooseAvatar,
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Widget _multiSelectChips({
    required List<String> items,
    required Set<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final active = selected.contains(item);
        return FilterChip(
          selected: active,
          label: Text(item),
          selectedColor: ArcUiTokens.primaryAccent.withValues(alpha: 0.18),
          backgroundColor: ArcUiTokens.surfaceInteractive.withValues(
            alpha: 0.74,
          ),
          checkmarkColor: ArcUiTokens.primaryAccent,
          side: BorderSide(
            color:
                (active ? ArcUiTokens.primaryAccent : ArcUiTokens.borderSubtle)
                    .withValues(alpha: 0.62),
          ),
          labelStyle: ArcUiTokens.label(
            color: active
                ? ArcUiTokens.primaryAccent
                : ArcUiTokens.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          ),
          onSelected: (_) => setState(() {
            if (active) {
              if (selected.length > 1) selected.remove(item);
            } else {
              selected.add(item);
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _singleSelectChips({
    required List<String> items,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final active = selected == item;
        return ChoiceChip(
          selected: active,
          label: Text(item),
          selectedColor: ArcUiTokens.secondaryAccent.withValues(alpha: 0.18),
          backgroundColor: ArcUiTokens.surfaceInteractive.withValues(
            alpha: 0.74,
          ),
          side: BorderSide(
            color:
                (active
                        ? ArcUiTokens.secondaryAccent
                        : ArcUiTokens.borderSubtle)
                    .withValues(alpha: 0.62),
          ),
          labelStyle: ArcUiTokens.label(
            color: active
                ? ArcUiTokens.secondaryAccent
                : ArcUiTokens.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          ),
          onSelected: (_) => onChanged(item),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: UagAppBar(
        title: widget.firstRunFlow
            ? 'Complete Raider Profile'
            : 'Set Up Raider Profile',
        subtitle: widget.firstRunFlow
            ? 'Profile & Reputation is required before entering the Hub.'
            : 'Create the identity UAG uses across matching and community.',
        showLogout: false,
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: true,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ArcFormScrollView(
              children: [
                const ArcAccountJourneyBar(
                  stage: ArcAccountJourneyStage.profile,
                ),
                const SizedBox(height: 12),
                ArcFormPageLead(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Build Your Raider Identity',
                  subtitle:
                      'Set the essentials now. You can refine everything later.',
                ),
                const SizedBox(height: 12),
                ArcExpandableFormSection(
                  initiallyExpanded: true,
                  summary: 'Core UAG identity and account details',
                  title: 'Identity',
                  icon: Icons.badge_outlined,
                  accent: ArcUiTokens.primaryAccent,
                  children: [
                    _identityPreview(),
                    const SizedBox(height: AppTheme.spaceM),
                    _field(
                      _uagIdController,
                      'UAG ID',
                      helperText: _isLoadingProfile
                          ? 'Loading reserved UAG ID...'
                          : 'Auto-assigned reserved trader ID',
                      enabled: false,
                    ),
                    _field(
                      _uagNameController,
                      'UAG Name',
                      validator: (v) => _required(v, 'UAG Name'),
                    ),
                    _field(
                      _embarkIdController,
                      'Embark ID',
                      validator: widget.firstRunFlow
                          ? (v) => _required(v, 'Embark ID')
                          : null,
                    ),
                    _field(
                      _regionController,
                      'Region',
                      validator: (v) => _required(v, 'Region'),
                    ),
                    ArcGamePlatformSelector(
                      selected: _platforms,
                      errorText: _platformError,
                      onChanged: (platforms) => setState(() {
                        _platforms
                          ..clear()
                          ..addAll(platforms);
                        _platformError = null;
                      }),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    _field(
                      _timezoneController,
                      'Timezone',
                      validator: (v) => _required(v, 'Timezone'),
                    ),
                    _field(
                      _referredByController,
                      'Referral Code Used (optional)',
                    ),
                  ],
                ),
                ArcExpandableFormSection(
                  title: 'Archetypes & Match Fit',
                  summary:
                      'Playstyle, communication, squad intent and session focus',
                  icon: Icons.hub_rounded,
                  accent: ArcUiTokens.secondaryAccent,
                  children: [
                    Text(
                      'Choose the tags that best describe how you play.',
                      style: ArcUiTokens.body(),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Player archetypes',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _multiSelectChips(
                      items: _archetypeOptions,
                      selected: _archetypes,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Play style',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _multiSelectChips(
                      items: _playStyleOptions,
                      selected: _playStyles,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Communication style',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _singleSelectChips(
                      items: _communicationOptions,
                      selected: _communicationStyle,
                      onChanged: (value) =>
                          setState(() => _communicationStyle = value),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Squad intent',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _singleSelectChips(
                      items: _squadIntentOptions,
                      selected: _squadIntent,
                      onChanged: (value) =>
                          setState(() => _squadIntent = value),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'What are you doing this session?',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _singleSelectChips(
                      items: ArcPlayerSessionCatalog.sessionIntents,
                      selected: _sessionIntent,
                      onChanged: (value) =>
                          setState(() => _sessionIntent = value),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Current priority',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _singleSelectChips(
                      items: ArcPlayerSessionCatalog.priorities,
                      selected: _currentPriority,
                      onChanged: (value) =>
                          setState(() => _currentPriority = value),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Current energy',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 15,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    _singleSelectChips(
                      items: _socialEnergyOptions,
                      selected: _socialEnergy,
                      onChanged: (value) =>
                          setState(() => _socialEnergy = value),
                    ),
                  ],
                ),
                ArcExpandableFormSection(
                  title: 'Preferences',
                  summary: 'Discovery, voice, region and crossplay controls',
                  icon: Icons.tune_rounded,
                  accent: ArcUiTokens.success,
                  children: [
                    SwitchListTile(
                      value: _visibleInSearch,
                      onChanged: (value) =>
                          setState(() => _visibleInSearch = value),
                      title: const Text('Visible in search'),
                    ),
                    SwitchListTile(
                      value: _micOk,
                      onChanged: (value) => setState(() => _micOk = value),
                      title: const Text('Mic okay'),
                    ),
                    SwitchListTile(
                      value: _crossRegionOk,
                      onChanged: (value) =>
                          setState(() => _crossRegionOk = value),
                      title: const Text('Cross-region okay'),
                    ),
                    SwitchListTile(
                      value: _crossPlatformOk,
                      onChanged: (value) =>
                          setState(() => _crossPlatformOk = value),
                      title: const Text('Cross-platform okay'),
                    ),
                    SwitchListTile(
                      value: _affiliateEnabled,
                      onChanged: (value) =>
                          setState(() => _affiliateEnabled = value),
                      title: const Text('Apply for affiliate programme'),
                    ),
                  ],
                ),
                ArcExpandableFormSection(
                  title: 'Gaming IDs & Social Links',
                  summary: 'Creator, community and platform profiles',
                  icon: Icons.link_rounded,
                  accent: ArcUiTokens.secondaryAccent,
                  children: [
                    ArcSocialLinksEditor(
                      initialLinks: _socialLinks,
                      selectedGamePlatforms: _platforms,
                      onChanged: (links) => _socialLinks = links,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ArcUiTokens.textButtonStyle(primary: true),
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : widget.firstRunFlow
                        ? 'Save & Set Availability'
                        : 'Save Profile',
                  ),
                ),
              ],
            ),
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
        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
        decoration: ArcUiTokens.inputDecoration(labelText: label).copyWith(
          helperText: helperText,
          helperStyle: ArcUiTokens.bodySmall(),
        ),
      ),
    );
  }
}
