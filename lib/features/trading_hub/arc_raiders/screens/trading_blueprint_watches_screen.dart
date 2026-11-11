import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_canonical_blueprint_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingBlueprintWatchesScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/blueprint-watches';

  const TradingBlueprintWatchesScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingBlueprintWatchesScreen> createState() =>
      _TradingBlueprintWatchesScreenState();
}

class _TradingBlueprintWatchesScreenState
    extends State<TradingBlueprintWatchesScreen> {
  final TradingRepository _repository = TradingRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();


  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  List<TradingListing> _matchesForWatch(
    ArcBlueprintWatch watch,
    List<TradingListing> listings,
  ) {
    final blueprintId = _normalize(watch.blueprintId);
    final blueprintName = _normalize(watch.displayName);
    return listings
        .where((listing) => listing.isLive)
        .where(
          (listing) => listing.offeredBlueprintNames.any((name) {
            final normalized = _normalize(name);
            return normalized == blueprintId || normalized == blueprintName;
          }),
        )
        .toList(growable: false);
  }

  Future<void> _createWatch(ArcBlueprint blueprint) async {
    try {
      final states = await _blueprintRepository.loadMyBlueprintStates();
      if (_blueprintRepository.currentUid == null) return;
      if (states[blueprint.id]?.owned == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already owned in Collections; watch not created.')),
        );
        return;
      }
      await _repository.createOrReactivateBlueprintWatch(
        blueprintId: blueprint.id,
        blueprintDisplayName: blueprint.name,
        preferredAcquisitionMethods: const <String>['Trade listings'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${blueprint.name} watch is active.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create watch. Try again.')),
      );
    }
  }

  Future<void> _showCreateSheet() async {
    final openingUid = _blueprintRepository.currentUid;
    if (openingUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to manage blueprint watches.')),
      );
      return;
    }

    // A broadcast stream does not replay its last event to a new sheet.
    // Each sheet opening must obtain its own canonical, confirmed state.
    final ownershipFuture = _blueprintRepository.loadMyBlueprintStates();
    var searchQuery = '';
    var savingAll = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ArcUiTokens.radiusXL)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spaceL,
              right: AppTheme.spaceL,
              top: AppTheme.spaceL,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Missing Blueprint Watch', style: ArcUiTokens.sectionTitle(
                    fontSize: 22, color: ArcUiTokens.primaryAccent)),
                  const SizedBox(height: AppTheme.spaceM),
                  TextField(
                    enabled: !savingAll,
                    onChanged: (value) => setModalState(() => searchQuery = value),
                    style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                    decoration: ArcUiTokens.inputDecoration(labelText: 'Search missing blueprints'),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Expanded(
                    child: FutureBuilder<Map<String, ArcBlueprintState>>(
                      future: ownershipFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Center(child: Text(
                            'Synchronising Collections ownership...',
                            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                          ));
                        }
                        if (snapshot.hasError || !snapshot.hasData ||
                            _blueprintRepository.currentUid != openingUid) {
                          return Center(child: Text(
                            'Collections ownership unavailable. Close and retry.',
                            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                          ));
                        }
                        final query = searchQuery.trim().toLowerCase();
                        final filtered = ArcCanonicalBlueprintCatalogue.missing(snapshot.requireData)
                            .where((bp) => bp.name.toLowerCase().contains(query) ||
                                bp.category.toLowerCase().contains(query))
                            .toList()..sort((a,b) => a.name.compareTo(b.name));
                        if (filtered.isEmpty) return Center(child: Text(
                          query.isEmpty ? 'All catalogue blueprints are owned.' : 'No missing blueprints match your search.',
                          style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                        ));
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('${filtered.length} missing ${query.isEmpty ? 'blueprints' : 'matches'}',
                                    style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary)),
                                ),
                                TextButton.icon(
                                  onPressed: savingAll ? null : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: sheetContext,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Watch all missing blueprints?'),
                                        content: Text('Create or reactivate watches for all ${filtered.length} ${query.isEmpty ? 'missing blueprints' : 'matching missing blueprints'}? Existing watches will be reused.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Add all')),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !sheetContext.mounted ||
                                        _blueprintRepository.currentUid != openingUid) return;
                                    setModalState(() => savingAll = true);
                                    var saved = 0;
                                    for (final blueprint in filtered) {
                                      if (_blueprintRepository.currentUid != openingUid) break;
                                      try {
                                        await _repository.createOrReactivateBlueprintWatch(
                                          blueprintId: blueprint.id,
                                          blueprintDisplayName: blueprint.name,
                                          preferredAcquisitionMethods: const <String>['Trade listings'],
                                        );
                                        saved++;
                                      } catch (_) {
                                        // Preserve successfully created watches; report partial success.
                                      }
                                    }
                                    if (!sheetContext.mounted) return;
                                    Navigator.of(sheetContext).pop();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(content: Text('$saved of ${filtered.length} blueprint watches saved.')),
                                    );
                                  },
                                  icon: const Icon(Icons.playlist_add_check_rounded),
                                  label: Text(savingAll ? 'Saving...' : 'Watch all ${filtered.length}'),
                                ),
                              ],
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final bp = filtered[index];
                                  return ListTile(
                                    enabled: !savingAll,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(bp.name, style: ArcUiTokens.body(color: ArcUiTokens.textPrimary)),
                                    subtitle: Text(bp.category, style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary)),
                                    trailing: const Icon(Icons.add_alert_outlined, color: ArcUiTokens.secondaryAccent),
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await _createWatch(bp);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editWatch(ArcBlueprintWatch watch) async {
    var notificationPreference = watch.notificationPreference;
    var notificationsEnabled = watch.notificationsEnabled;
    var favouriteRidersOnly = watch.favouriteRidersOnly;
    var minimumMatchScore = watch.minimumMatchScore.toDouble();

    final updated = await showModalBottomSheet<ArcBlueprintWatch>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArcUiTokens.radiusXL),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spaceL,
                  AppTheme.spaceL,
                  AppTheme.spaceL,
                  MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      watch.displayName,
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 22,
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: notificationsEnabled,
                      activeThumbColor: ArcUiTokens.secondaryAccent,
                      title: Text(
                        'Notifications enabled',
                        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                      ),
                      onChanged: (value) =>
                          setModalState(() => notificationsEnabled = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: favouriteRidersOnly,
                      activeThumbColor: ArcUiTokens.secondaryAccent,
                      title: Text(
                        'Favourite Raiders only',
                        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                      ),
                      onChanged: (value) =>
                          setModalState(() => favouriteRidersOnly = value),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    DropdownButtonFormField<
                      ArcBlueprintWatchNotificationPreference
                    >(
                      initialValue: notificationPreference,
                      dropdownColor: ArcUiTokens.surfaceOverlay,
                      decoration: ArcUiTokens.inputDecoration(
                        labelText: 'Notification preference',
                      ),
                      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                      items: ArcBlueprintWatchNotificationPreference.values
                          .map(
                            (preference) => DropdownMenuItem(
                              value: preference,
                              child: Text(preference.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setModalState(
                        () => notificationPreference =
                            value ?? notificationPreference,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Minimum match score: ${minimumMatchScore.round()}',
                      style: ArcUiTokens.bodySmall(
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                    Slider(
                      value: minimumMatchScore,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: ArcUiTokens.secondaryAccent,
                      onChanged: (value) =>
                          setModalState(() => minimumMatchScore = value),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ArcUiTokens.textButtonStyle(
                          accent: ArcUiTokens.secondaryAccent,
                          primary: true,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(
                            watch.copyWith(
                              notificationsEnabled: notificationsEnabled,
                              favouriteRidersOnly: favouriteRidersOnly,
                              notificationPreference: notificationsEnabled
                                  ? notificationPreference
                                  : ArcBlueprintWatchNotificationPreference
                                        .muted,
                              minimumMatchScore: minimumMatchScore.round(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Watch'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == null) return;
    try {
      await _repository.saveBlueprintWatch(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Watch updated.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update watch. Try again.')),
      );
    }
  }

  Future<void> _toggleActive(ArcBlueprintWatch watch) async {
    try {
      if (watch.active) {
        await _repository.pauseBlueprintWatch(watch.id);
      } else {
        await _repository.resumeBlueprintWatch(watch.id);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update watch. Try again.')),
      );
    }
  }

  Future<void> _removeWatch(ArcBlueprintWatch watch) async {
    try {
      await _repository.removeBlueprintWatch(watch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Watch removed.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove watch. Try again.')),
      );
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(
        label,
        style: ArcUiTokens.bodySmall(
          color: color,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _watchCard(
    ArcBlueprintWatch watch,
    List<TradingListing> activeListings,
  ) {
    final matches = _matchesForWatch(watch, activeListings);
    final topMatch = matches.isEmpty ? null : matches.first;
    final statusColor = !watch.active
        ? ArcUiTokens.textDisabled
        : matches.isNotEmpty
        ? ArcUiTokens.success
        : ArcUiTokens.primaryAccent;
    return TradingCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      accent: matches.isNotEmpty
          ? ArcUiTokens.success
          : ArcUiTokens.primaryAccent,
      onTap: topMatch == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TradingListingDetailScreen(listing: topMatch),
                ),
              );
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  watch.displayName,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 20,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              _pill(
                matches.isNotEmpty ? 'Match found' : watch.stateLabel,
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            matches.isNotEmpty
                ? '${matches.length} live ${matches.length == 1 ? 'listing matches' : 'listings match'} this watch.'
                : watch.active
                ? 'No current live listing match. This watch remains active.'
                : 'Paused watches do not trigger match alerts.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                'Min ${watch.minimumMatchScore}',
                ArcUiTokens.primaryAccent,
              ),
              if (watch.favouriteRidersOnly)
                _pill('Favourite Raiders', ArcUiTokens.secondaryAccent),
              _pill(
                watch.shouldNotify ? 'Notify' : 'Muted',
                watch.shouldNotify
                    ? ArcUiTokens.secondaryAccent
                    : ArcUiTokens.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (topMatch != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TradingListingDetailScreen(listing: topMatch),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Match'),
                ),
              TextButton.icon(
                onPressed: () => _editWatch(watch),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _toggleActive(watch),
                icon: Icon(
                  watch.active
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                label: Text(watch.active ? 'Pause' : 'Reactivate'),
              ),
              TextButton.icon(
                onPressed: () => _removeWatch(watch),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 144),
      children: [
        ArcRaidersStatePanel(
          title: 'No active watches',
          message:
              'Add a blueprint watch to surface matching traders and listings.',
          icon: Icons.add_alert_outlined,
          accent: ArcUiTokens.primaryAccent,
          action: ElevatedButton.icon(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Watch'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ArcRaidersScreenShell(
      showAdBanner: false,
      child: SafeArea(
        child: StreamBuilder<List<ArcBlueprintWatch>>(
          stream: _repository.watchBlueprintWatches(),
          builder: (context, watchSnapshot) {
            return StreamBuilder<List<TradingListing>>(
              stream: _repository.watchActiveListings(),
              builder: (context, listingSnapshot) {
                final watches =
                    watchSnapshot.data ?? const <ArcBlueprintWatch>[];
                final listings =
                    listingSnapshot.data ?? const <TradingListing>[];

                if (watchSnapshot.connectionState == ConnectionState.waiting &&
                    watchSnapshot.data == null) {
                  return const Center(
                    child: ArcRaidersStatePanel(
                      title: 'Loading watches',
                      message: 'Checking watched blueprints and live matches.',
                      icon: Icons.sync_rounded,
                      accent: ArcUiTokens.primaryAccent,
                    ),
                  );
                }
                if (watches.isEmpty) return _emptyState();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 144),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ArcRaidersPageHeader(
                            title: 'BLUEPRINT WATCHES',
                            subtitle:
                                '${watches.length} watched blueprints. ${listings.length} live market listings.',
                            icon: Icons.add_alert_outlined,
                            accent: ArcUiTokens.primaryAccent,
                          ),
                        ),
                        OutlinedButton.icon(
                          style: ArcUiTokens.textButtonStyle(
                            accent: ArcUiTokens.primaryAccent,
                          ),
                          onPressed: _showCreateSheet,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    for (final watch in watches) _watchCard(watch, listings),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) return _buildBody();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Blueprint Watches',
          style: ArcUiTokens.sectionTitle(
            fontSize: 25,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.watches),
          ArcCompanionBottomDock(activeLabel: 'Track'),
        ],
      ),
      body: _buildBody(),
    );
  }
}
