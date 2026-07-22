// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../models/arc_profile_social_models.dart';
import '../models/arc_trader_profile.dart';
import '../repositories/arc_trader_profile_repository.dart';
import '../widgets/arc_social_links_editor.dart';

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

  bool _visibleInSearch = true;
  bool _micOk = true;
  bool _crossRegionOk = false;
  bool _crossplayEnabled = true;
  bool _affiliateEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _createdAt;
  final Set<String> _archetypes = {'Balanced Raider'};
  final Set<String> _playStyles = {'PvE defensive'};
  String _communicationStyle = 'Flexible';
  String _squadIntent = 'Flexible';
  String _socialEnergy = 'Depends on the day';
  String _sessionIntent = ArcPlayerSessionCatalog.defaultIntent;
  String _currentPriority = ArcPlayerSessionCatalog.defaultPriority;
  String _serverPreference = 'Automatic';
  String _payoutMethod = 'Bank Transfer';
  String _subscriptionStatus = 'inactive';
  List<ArcProfileSocialLink> _socialLinks = const <ArcProfileSocialLink>[];

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
    _socialLinks = profile.socialLinks;
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
          subscriptionStatus: _subscriptionStatus,
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget heroCard() {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          radius: 24,
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    Icons.manage_accounts_rounded,
                    color: AppTheme.neonCyan,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trader Identity + Reputation',
                        style: AppTheme.tradingHeading(
                          fontSize: 24,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep your profile focused on reputation, badges, archetypes and squad fit.',
                        style: TextStyle(color: Colors.white70, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
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
                Icon(icon, color: AppTheme.neonPink, size: 22),
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
        title: const Text('Edit Your Hub Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
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
                        helperText: 'Auto-assigned numeric trader ID',
                        enabled: false,
                      ),
                      _field(
                        _uagNameController,
                        'UAG Name',
                        validator: (v) => _required(v, 'UAG Name'),
                      ),
                      _field(_embarkIdController, 'Embark ID'),
                    ],
                  ),
                  sectionCard(
                    title: 'Platform & Server',
                    icon: Icons.travel_explore_rounded,
                    children: [
                      _field(
                        _regionController,
                        'Region',
                        validator: (v) => _required(v, 'Region'),
                      ),
                      _dropdown(
                        label: 'Server Preference',
                        value: _serverPreference,
                        values: _serverPreferences,
                        onChanged: (value) => setState(
                          () => _serverPreference = value ?? 'Automatic',
                        ),
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
                    title: 'Trading Preferences',
                    icon: Icons.tune_rounded,
                    children: [
                      _switchTile(
                        value: _visibleInSearch,
                        onChanged: (value) =>
                            setState(() => _visibleInSearch = value),
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
                        onChanged: (value) =>
                            setState(() => _crossRegionOk = value),
                        title: 'Cross-region okay',
                        subtitle:
                            'Open to switching region for raids, trades and event windows.',
                      ),
                      _switchTile(
                        value: _crossplayEnabled,
                        onChanged: (value) =>
                            setState(() => _crossplayEnabled = value),
                        title: 'Crossplay enabled',
                        subtitle:
                            'Used for cross-platform matching and trade planning.',
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
                  sectionCard(
                    title: 'Account',
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      _dropdown(
                        label: 'Preferred payout method',
                        value: _payoutMethod,
                        values: _payoutMethods,
                        onChanged: (value) => setState(
                          () => _payoutMethod = value ?? 'Bank Transfer',
                        ),
                      ),
                      _dropdown(
                        label: 'Subscription status',
                        value: _subscriptionStatus,
                        values: _subscriptionOptions,
                        onChanged: (value) => setState(
                          () => _subscriptionStatus = value ?? 'inactive',
                        ),
                      ),
                      _switchTile(
                        value: _affiliateEnabled,
                        onChanged: (value) =>
                            setState(() => _affiliateEnabled = value),
                        title: 'Affiliate programme enabled',
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
