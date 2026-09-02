import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
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
  late final List<ArcBlueprint> _blueprints = List<ArcBlueprint>.from(
    ArcBlueprintSeedData.blueprints,
  )..sort((a, b) => a.name.compareTo(b.name));

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
      await _repository.createOrReactivateBlueprintWatch(
        blueprintId: blueprint.id,
        blueprintDisplayName: blueprint.name,
        preferredAcquisitionMethods: const <String>['Trade listings'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${blueprint.name} watch is active.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create watch: $error')));
    }
  }

  Future<void> _showCreateSheet() async {
    final controller = TextEditingController();
    var filtered = List<ArcBlueprint>.from(_blueprints);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArcUiTokens.radiusXL),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter(String query) {
              final normalized = query.trim().toLowerCase();
              setModalState(() {
                filtered = _blueprints
                    .where(
                      (blueprint) =>
                          blueprint.name.toLowerCase().contains(normalized) ||
                          blueprint.category.toLowerCase().contains(normalized),
                    )
                    .toList(growable: false);
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppTheme.spaceL,
                  right: AppTheme.spaceL,
                  top: AppTheme.spaceL,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      AppTheme.spaceL,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Blueprint Watch',
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 22,
                          color: ArcUiTokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: controller,
                        onChanged: updateFilter,
                        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                        decoration: ArcUiTokens.inputDecoration(
                          labelText: 'Search blueprints',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final blueprint = filtered[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                blueprint.name,
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${blueprint.rarityLabel} - ${blueprint.category}',
                                style: ArcUiTokens.bodySmall(
                                  color: ArcUiTokens.textTertiary,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.add_alert_outlined,
                                color: ArcUiTokens.secondaryAccent,
                              ),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await _createWatch(blueprint);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update watch: $error')));
    }
  }

  Future<void> _toggleActive(ArcBlueprintWatch watch) async {
    try {
      if (watch.active) {
        await _repository.pauseBlueprintWatch(watch.id);
      } else {
        await _repository.resumeBlueprintWatch(watch.id);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update watch: $error')));
    }
  }

  Future<void> _removeWatch(ArcBlueprintWatch watch) async {
    try {
      await _repository.removeBlueprintWatch(watch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Watch removed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove watch: $error')));
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
                ? '${matches.length} live listing ${matches.length == 1 ? 'matches' : 'matches'} this watch.'
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_alert_outlined,
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.72),
              size: 42,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              'NO ACTIVE WATCHES',
              style: ArcUiTokens.sectionTitle(
                fontSize: 22,
                color: ArcUiTokens.primaryAccent,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Add a blueprint watch to surface matching traders, listings and Intel.',
              textAlign: TextAlign.center,
              style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceM),
            ElevatedButton.icon(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.secondaryAccent,
                primary: true,
              ),
              onPressed: _showCreateSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Watch'),
            ),
          ],
        ),
      ),
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
                    child: CircularProgressIndicator(
                      color: ArcUiTokens.primaryAccent,
                    ),
                  );
                }
                if (watches.isEmpty) return _emptyState();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Blueprint Watches',
                            style: ArcUiTokens.sectionTitle(
                              fontSize: 22,
                              color: ArcUiTokens.primaryAccent,
                            ),
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
      body: _buildBody(),
    );
  }
}
