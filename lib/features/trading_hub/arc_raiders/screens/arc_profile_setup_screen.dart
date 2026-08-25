import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../models/arc_profile_social_models.dart';
import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/arc_social_links_editor.dart';

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
  bool _isLoadingProfile = true;
  final Set<String> _archetypes = {'Balanced Raider'};
  final Set<String> _playStyles = {'PvE defensive'};
  String _communicationStyle = 'Flexible';
  String _squadIntent = 'Flexible';
  String _socialEnergy = 'Depends on the day';
  String _sessionIntent = ArcPlayerSessionCatalog.defaultIntent;
  String _currentPriority = ArcPlayerSessionCatalog.defaultPriority;
  String _payoutMethod = 'Bank Transfer';
  List<ArcProfileSocialLink> _socialLinks = const <ArcProfileSocialLink>[];

  static const List<String> _payoutMethods = <String>[
    'Bank Transfer',
    'PayPal',
    'Stripe Connect',
    'Not Set',
  ];

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
    _platformController = TextEditingController();
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
    _platformController.dispose();
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
      _embarkIdController.text = profile.embarkId;
      _regionController.text = profile.region.isEmpty ? 'UK' : profile.region;
      _platformController.text = profile.platform;
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
          selectedColor: AppTheme.neonCyan.withValues(alpha: 0.18),
          checkmarkColor: AppTheme.neonCyan,
          side: BorderSide(
            color: (active ? AppTheme.neonCyan : Colors.white24).withValues(
              alpha: 0.62,
            ),
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
          selectedColor: AppTheme.neonPink.withValues(alpha: 0.18),
          side: BorderSide(
            color: (active ? AppTheme.neonPink : Colors.white24).withValues(
              alpha: 0.62,
            ),
          ),
          onSelected: (_) => onChanged(item),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget heroCard() {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          radius: 24,
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Up Your Hub Profile',
                    style: AppTheme.tradingHeading(
                      fontSize: 24,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Build the public ARC Raiders profile that carries into your UAG trader identity.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionCard({
      required String title,
      required IconData icon,
      required List<Widget> children,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.neonPink),
                const SizedBox(width: AppTheme.spaceS),
                Text(
                  title,
                  style: AppTheme.tradingHeading(
                    fontSize: 20,
                    color: AppTheme.neonPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            ...children,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Set Up Your Hub Profile'),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  children: [
                    heroCard(),
                    const SizedBox(height: AppTheme.spaceL),
                    sectionCard(
                      title: 'Identity',
                      icon: Icons.badge_outlined,
                      children: [
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
                        _field(
                          _referredByController,
                          'Referral Code Used (optional)',
                        ),
                      ],
                    ),
                    sectionCard(
                      title: 'Account',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _payoutMethod,
                          items: _payoutMethods
                              .map(
                                (method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _payoutMethod = value ?? 'Bank Transfer';
                          }),
                          decoration: AppTheme.tradingInputDecoration(
                            label: 'Preferred payout method',
                          ),
                        ),
                      ],
                    ),
                    sectionCard(
                      title: 'Archetypes & Match Fit',
                      icon: Icons.hub_rounded,
                      children: [
                        const Text(
                          'Select everything that applies. These tags drive matchmaking, squad recommendations and public profile fit.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        Text(
                          'Player archetypes',
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonCyan,
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
                    sectionCard(
                      title: 'Preferences',
                      icon: Icons.tune_rounded,
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
                    sectionCard(
                      title: 'Public Social Links',
                      icon: Icons.link_rounded,
                      children: [
                        ArcSocialLinksEditor(
                          initialLinks: _socialLinks,
                          onChanged: (links) => _socialLinks = links,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
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
