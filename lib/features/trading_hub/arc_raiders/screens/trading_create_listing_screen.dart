import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_profile.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingCreateListingScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/create';

  const TradingCreateListingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingCreateListingScreen> createState() =>
      _TradingCreateListingScreenState();
}

class _TradingCreateListingScreenState
    extends State<TradingCreateListingScreen> {
  final TradingRepository _repository = TradingRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final TextEditingController _notesController = TextEditingController();

  late final List<ArcBlueprint> _blueprints;
  late final List<ArcTradeItem> _tradeCatalog;

  bool _isSaving = false;
  bool _openToOffers = false;
  bool _wantsNothing = false;
  bool _acceptsBlueprints = true;
  bool _acceptsSeeds = false;
  bool _acceptsResources = true;
  bool _seriousOffersOnly = false;
  bool _tradeAsBundle = true;
  bool _allowPartialOffers = false;

  String _selectedPlayWindow = 'Evenings';
  String _selectedExpiry = '72 Hours';

  int _smallBundles = 0;
  int _mediumBundles = 0;
  int _largeBundles = 0;

  final List<ArcBlueprint> _selectedOfferingBlueprints = <ArcBlueprint>[];
  final List<ArcBlueprint> _selectedWantedBlueprints = <ArcBlueprint>[];
  final List<ArcTradeItem> _selectedOfferingAssets = <ArcTradeItem>[];
  final List<ArcTradeItem> _selectedWantedAssets = <ArcTradeItem>[];

  Map<String, ArcBlueprintState> _states = const <String, ArcBlueprintState>{};

  @override
  void initState() {
    super.initState();
    _blueprints = List<ArcBlueprint>.from(ArcBlueprintSeedData.blueprints)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _tradeCatalog =
        List<ArcTradeItem>.from(
          ArcTradeItemsData.items.where(
            (item) => item.category != ArcTradeItemCategory.containerIntel,
          ),
        )..sort((a, b) {
          final valueCompare = b.tradeValue.index.compareTo(a.tradeValue.index);
          if (valueCompare != 0) return valueCompare;
          final categoryCompare = a.categoryLabel.toLowerCase().compareTo(
            b.categoryLabel.toLowerCase(),
          );
          if (categoryCompare != 0) return categoryCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<ArcBlueprint> get _dupeBlueprints => _blueprints
      .where((blueprint) {
        final state =
            _states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
        return state.hasDuplicates;
      })
      .toList(growable: false);

  List<ArcBlueprint> get _missingBlueprints => _blueprints
      .where((blueprint) {
        final state =
            _states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
        return !state.owned;
      })
      .toList(growable: false);

  int get _seedTotal =>
      (_smallBundles * 10) + (_mediumBundles * 50) + (_largeBundles * 100);

  bool get _hasAnyOfferedSelection =>
      _selectedOfferingBlueprints.isNotEmpty ||
      _selectedOfferingAssets.isNotEmpty ||
      _seedTotal > 0;

  bool get _hasAnyWantedSelection =>
      _selectedWantedBlueprints.isNotEmpty || _selectedWantedAssets.isNotEmpty;

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 21,
              color: AppTheme.neonPink,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: AppTheme.tradingMutedText, height: 1.3),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF111827),
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.tradingInputDecoration(label: label),
      items: options
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _bundleRow({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(
            Icons.remove_circle_outline,
            color: AppTheme.neonPink,
          ),
        ),
        Text(
          '$value',
          style: AppTheme.tradingHeading(
            fontSize: 22,
            color: AppTheme.neonCyan,
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonPink),
        ),
      ],
    );
  }

  Widget _selectorTile({
    required String label,
    required String value,
    required VoidCallback? onTap,
    String? helper,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: AppTheme.tradingInputDecoration(label: label),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.white70,
                ),
              ],
            ),
            if (helper != null && helper.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                helper,
                style: TextStyle(
                  color: AppTheme.tradingFaintText,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipWrap(List<String> items, {Color? color}) {
    if (items.isEmpty) {
      return Text(
        'Nothing selected yet.',
        style: TextStyle(color: AppTheme.tradingFaintText),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: AppTheme.pillPadding,
              decoration: AppTheme.tradingPillDecoration(
                color: color ?? AppTheme.neonCyan,
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: color ?? AppTheme.neonCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _selectionSummary(int count, String noun) {
    if (count == 0) return 'Nothing selected';
    if (count == 1) return '1 $noun selected';
    return '$count ${noun}s selected';
  }

  Future<List<ArcBlueprint>?> _showBlueprintMultiPicker({
    required String title,
    required List<ArcBlueprint> items,
    required List<ArcBlueprint> initiallySelected,
  }) async {
    final controller = TextEditingController();
    final selectedIds = initiallySelected.map((item) => item.id).toSet();
    var filtered = List<ArcBlueprint>.from(items);

    return showModalBottomSheet<List<ArcBlueprint>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter(String query) {
              final normalized = query.trim().toLowerCase();
              setModalState(() {
                filtered = items
                    .where((item) {
                      return item.name.toLowerCase().contains(normalized) ||
                          item.category.toLowerCase().contains(normalized) ||
                          item.group.toLowerCase().contains(normalized);
                    })
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
                    children: [
                      Text(
                        title,
                        style: AppTheme.tradingHeading(
                          fontSize: 22,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        onChanged: updateFilter,
                        decoration: AppTheme.tradingInputDecoration(
                          label: 'Search blueprints',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectionSummary(selectedIds.length, 'blueprint'),
                          style: TextStyle(color: AppTheme.tradingMutedText),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching blueprints.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final blueprint = filtered[index];
                                  final state =
                                      _states[blueprint.id] ??
                                      ArcBlueprintState.empty(blueprint.id);
                                  final isSelected = selectedIds.contains(
                                    blueprint.id,
                                  );
                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppTheme.neonPink,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      blueprint.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      state.hasDuplicates
                                          ? 'Dupes: ${state.dupesOwned} • ${blueprint.category}'
                                          : '${blueprint.rarityLabel} • ${blueprint.category}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    onChanged: (_) {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedIds.remove(blueprint.id);
                                        } else {
                                          selectedIds.add(blueprint.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final selected = items
                                .where((item) => selectedIds.contains(item.id))
                                .toList(growable: false);
                            Navigator.of(context).pop(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Done'),
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
  }

  Future<List<ArcTradeItem>?> _showAssetMultiPicker({
    required String title,
    required List<ArcTradeItem> initiallySelected,
  }) async {
    final controller = TextEditingController();
    final selectedIds = initiallySelected.map((item) => item.id).toSet();
    var filtered = List<ArcTradeItem>.from(_tradeCatalog);
    String categoryFilter = 'All';
    final categories = <String>[
      'All',
      ...{for (final item in _tradeCatalog) item.categoryLabel},
    ];

    return showModalBottomSheet<List<ArcTradeItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter() {
              final query = controller.text.trim().toLowerCase();
              setModalState(() {
                filtered = _tradeCatalog
                    .where((item) {
                      final matchesCategory =
                          categoryFilter == 'All' ||
                          item.categoryLabel == categoryFilter;
                      final matchesQuery =
                          query.isEmpty ||
                          item.name.toLowerCase().contains(query) ||
                          item.id.toLowerCase().contains(query) ||
                          item.categoryLabel.toLowerCase().contains(query) ||
                          item.tradeValueLabel.toLowerCase().contains(query) ||
                          item.rarityLabel.toLowerCase().contains(query) ||
                          item.sourceHints.any(
                            (hint) => hint.toLowerCase().contains(query),
                          );
                      return matchesCategory && matchesQuery;
                    })
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
                  height: MediaQuery.of(context).size.height * 0.82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.tradingHeading(
                          fontSize: 22,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => updateFilter(),
                        decoration: AppTheme.tradingInputDecoration(
                          label: 'Search weapons, keys, mods, materials',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
                            final selected = categoryFilter == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: selected,
                                selectedColor: AppTheme.neonPink.withValues(
                                  alpha: 0.25,
                                ),
                                checkmarkColor: AppTheme.neonPink,
                                label: Text(category),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? AppTheme.neonPink
                                      : AppTheme.neonCyan,
                                  fontWeight: FontWeight.w700,
                                ),
                                backgroundColor: AppTheme.tradingCardBackground,
                                side: BorderSide(
                                  color: selected
                                      ? AppTheme.neonPink.withValues(alpha: 0.7)
                                      : AppTheme.neonCyan.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                                onSelected: (_) {
                                  categoryFilter = category;
                                  updateFilter();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        _selectionSummary(selectedIds.length, 'asset'),
                        style: TextStyle(color: AppTheme.tradingMutedText),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching trade assets.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected = selectedIds.contains(
                                    item.id,
                                  );
                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppTheme.neonPink,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (item.tradeValue ==
                                                ArcTradeValueTier.elite ||
                                            item.rarity ==
                                                ArcTradeItemRarity.legendary)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration:
                                                AppTheme.tradingPillDecoration(
                                                  color: AppTheme.neonPink,
                                                ),
                                            child: const Text(
                                              'HOT',
                                              style: TextStyle(
                                                color: AppTheme.neonPink,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${item.categoryLabel} • ${item.rarityLabel} • ${item.tradeValueLabel} value',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    onChanged: (_) {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedIds.remove(item.id);
                                        } else {
                                          selectedIds.add(item.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final selected = _tradeCatalog
                                .where((item) => selectedIds.contains(item.id))
                                .toList(growable: false);
                            Navigator.of(context).pop(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Done'),
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
  }

  Duration _expiryDurationFromSelection() {
    switch (_selectedExpiry) {
      case '24 Hours':
        return const Duration(hours: 24);
      case '72 Hours':
        return const Duration(hours: 72);
      case '7 Days':
        return const Duration(days: 7);
      default:
        return const Duration(hours: 72);
    }
  }

  String _buildOfferSummary() {
    final pieces = <String>[
      ..._selectedOfferingBlueprints.map((item) => item.name),
      ..._selectedOfferingAssets.map((item) => item.name),
      if (_seedTotal > 0) '$_seedTotal Seeds',
    ];
    if (pieces.isEmpty) return '';
    if (pieces.length == 1) return pieces.first;
    if (pieces.length <= 3) return pieces.join(' • ');
    return '${pieces.take(3).join(' • ')} +${pieces.length - 3} more';
  }

  String _buildWantedSummary() {
    if (_wantsNothing) return 'Nothing wanted • free giveaway';
    if (_openToOffers) return 'Open to offers';
    final pieces = <String>[
      ..._selectedWantedBlueprints.map((item) => item.name),
      ..._selectedWantedAssets.map((item) => item.name),
    ];
    if (pieces.isEmpty) return '';
    if (pieces.length == 1) return pieces.first;
    if (pieces.length <= 3) return pieces.join(' • ');
    return '${pieces.take(3).join(' • ')} +${pieces.length - 3} more';
  }

  String _buildTitle() {
    final offeringNames = <String>[
      ..._selectedOfferingBlueprints.map((item) => item.name),
      ..._selectedOfferingAssets.map((item) => item.name),
      if (_seedTotal > 0) 'Seeds',
    ];

    if (offeringNames.isEmpty) return 'Trade Listing';

    final lead = offeringNames.first;
    if (_wantsNothing) return '$lead • Free Giveaway';
    if (_openToOffers) {
      return _tradeAsBundle
          ? '$lead bundle • Open Offer'
          : '$lead • Open Offer';
    }

    final wantedNames = <String>[
      ..._selectedWantedBlueprints.map((item) => item.name),
      ..._selectedWantedAssets.map((item) => item.name),
    ];

    if (wantedNames.isEmpty) return '$lead trade';
    return '$lead for ${wantedNames.first}';
  }

  Future<void> _saveListing() async {
    if (!_hasAnyOfferedSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one offered blueprint, item, or seed bundle.',
          ),
        ),
      );
      return;
    }
    if (!_openToOffers && !_wantsNothing && !_hasAnyWantedSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one wanted blueprint or trade asset.'),
        ),
      );
      return;
    }
    if (!_wantsNothing &&
        !_acceptsBlueprints &&
        !_acceptsSeeds &&
        !_acceptsResources) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one accepted trade type.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);

    try {
      await _repository.createListing(
        offeredItem: _buildOfferSummary(),
        wantedText: _buildWantedSummary(),
        listingType: (_openToOffers || _wantsNothing)
            ? TradingListingType.openToOffers
            : TradingListingType.specificWant,
        playWindow: _selectedPlayWindow,
        smallBundles: _smallBundles,
        mediumBundles: _mediumBundles,
        largeBundles: _largeBundles,
        acceptsBlueprints: _acceptsBlueprints,
        acceptsSeeds: _acceptsSeeds,
        acceptsResources: _acceptsResources,
        seriousOffersOnly: _seriousOffersOnly,
        notes: _notesController.text,
        expiryDuration: _expiryDurationFromSelection(),
        offeredBlueprintNames: _selectedOfferingBlueprints
            .map((item) => item.name)
            .toList(growable: false),
        wantedBlueprintNames: _selectedWantedBlueprints
            .map((item) => item.name)
            .toList(growable: false),
        offeredAssetNames: _selectedOfferingAssets
            .map((item) => item.name)
            .toList(growable: false),
        wantedAssetNames: _selectedWantedAssets
            .map((item) => item.name)
            .toList(growable: false),
        offeredTradeItemIds: _selectedOfferingAssets
            .map((item) => item.id)
            .toList(growable: false),
        wantedTradeItemIds: _selectedWantedAssets
            .map((item) => item.id)
            .toList(growable: false),
        offeredTradeItemNames: _selectedOfferingAssets
            .map((item) => item.name)
            .toList(growable: false),
        wantedTradeItemNames: _selectedWantedAssets
            .map((item) => item.name)
            .toList(growable: false),
        wantsNothing: _wantsNothing,
        tradeAsBundle: _tradeAsBundle,
        allowPartialOffers: _allowPartialOffers,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Listing created successfully.'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save listing: $error'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Widget _profilePrefillCard(TradingProfile profile) {
    return _sectionCard(
      title: 'Trader Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trader: ${profile.displayName}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Region: ${profile.region}',
            style: TextStyle(color: AppTheme.tradingMutedText),
          ),
          const SizedBox(height: 8),
          Text(
            'Gamertag: ${profile.gamerTag.isEmpty ? 'Not set' : profile.gamerTag}',
            style: TextStyle(color: AppTheme.tradingMutedText),
          ),
          const SizedBox(height: 8),
          Text(
            'Platform: ${profile.preferredPlatform.isEmpty ? 'Not set' : profile.preferredPlatform}',
            style: TextStyle(color: AppTheme.tradingMutedText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'Create Listing',
                style: AppTheme.tradingHeading(fontSize: 25),
              ),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _blueprintRepository.watchMyBlueprintStates(),
              builder: (context, stateSnapshot) {
                _states =
                    stateSnapshot.data ?? const <String, ArcBlueprintState>{};
                return FutureBuilder<TradingProfile>(
                  future: _repository.getTradingProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.neonCyan,
                        ),
                      );
                    }

                    final profile =
                        snapshot.data ??
                        TradingProfile.empty(_repository.currentUid ?? '');
                    final dupeBlueprints = _dupeBlueprints;
                    final missingBlueprints = _missingBlueprints;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.pageMaxWidth,
                        ),
                        child: ListView(
                          padding: AppTheme.pagePadding,
                          children: [
                            _profilePrefillCard(profile),
                            _sectionCard(
                              title: 'What You Are Offering',
                              subtitle:
                                  'Build a trade package with multiple blueprints, weapons, keys, mods, resources, and seeds.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _selectorTile(
                                    label: 'Offering Blueprints',
                                    value: _selectionSummary(
                                      _selectedOfferingBlueprints.length,
                                      'blueprint',
                                    ),
                                    helper: dupeBlueprints.isEmpty
                                        ? 'You need at least one blueprint with dupes before you can offer blueprints.'
                                        : '${dupeBlueprints.length} tradeable blueprints available',
                                    onTap: dupeBlueprints.isEmpty
                                        ? null
                                        : () async {
                                            final picked =
                                                await _showBlueprintMultiPicker(
                                                  title:
                                                      'Select offering blueprints',
                                                  items: dupeBlueprints,
                                                  initiallySelected:
                                                      _selectedOfferingBlueprints,
                                                );
                                            if (!mounted || picked == null)
                                              return;
                                            setState(() {
                                              _selectedOfferingBlueprints
                                                ..clear()
                                                ..addAll(picked);
                                            });
                                          },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _chipWrap(
                                    _selectedOfferingBlueprints
                                        .map((item) => item.name)
                                        .toList(growable: false),
                                  ),
                                  const SizedBox(height: AppTheme.spaceM),
                                  _selectorTile(
                                    label: 'Offering Trade Assets',
                                    value: _selectionSummary(
                                      _selectedOfferingAssets.length,
                                      'asset',
                                    ),
                                    helper:
                                        '${_tradeCatalog.length} tradeable weapons, ammo, attachments, ARC components, trinkets, materials, boss drops, and Riven Tides items loaded.',
                                    onTap: () async {
                                      final picked =
                                          await _showAssetMultiPicker(
                                            title:
                                                'Select offering trade assets',
                                            initiallySelected:
                                                _selectedOfferingAssets,
                                          );
                                      if (!mounted || picked == null) return;
                                      setState(() {
                                        _selectedOfferingAssets
                                          ..clear()
                                          ..addAll(picked);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _chipWrap(
                                    _selectedOfferingAssets
                                        .map((item) => item.name)
                                        .toList(growable: false),
                                    color: AppTheme.neonPink,
                                  ),
                                  const SizedBox(height: AppTheme.spaceM),
                                  Text(
                                    'Seed Bundles',
                                    style: AppTheme.tradingHeading(
                                      fontSize: 18,
                                      color: AppTheme.neonCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _bundleRow(
                                    label: '10 Seeds',
                                    value: _smallBundles,
                                    onMinus: () => setState(
                                      () => _smallBundles = (_smallBundles - 1)
                                          .clamp(0, 999),
                                    ),
                                    onPlus: () =>
                                        setState(() => _smallBundles += 1),
                                  ),
                                  _bundleRow(
                                    label: '50 Seeds',
                                    value: _mediumBundles,
                                    onMinus: () => setState(
                                      () => _mediumBundles =
                                          (_mediumBundles - 1).clamp(0, 999),
                                    ),
                                    onPlus: () =>
                                        setState(() => _mediumBundles += 1),
                                  ),
                                  _bundleRow(
                                    label: '100 Seeds',
                                    value: _largeBundles,
                                    onMinus: () => setState(
                                      () => _largeBundles = (_largeBundles - 1)
                                          .clamp(0, 999),
                                    ),
                                    onPlus: () =>
                                        setState(() => _largeBundles += 1),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total offered seed value: $_seedTotal',
                                    style: TextStyle(
                                      color: AppTheme.tradingMutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionCard(
                              title: 'What You Want Back',
                              subtitle:
                                  'Ask for specific blueprints and assets, or open the door to custom offers.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    value: _openToOffers,
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: AppTheme.neonPink,
                                    title: const Text(
                                      'Open to offers',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: const Text(
                                      'Turn this on if you want people to propose their own mix instead of matching a fixed request.',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _openToOffers = value;
                                        if (value) {
                                          _selectedWantedBlueprints.clear();
                                          _selectedWantedAssets.clear();
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  SwitchListTile(
                                    value: _wantsNothing,
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: AppTheme.neonCyan,
                                    title: const Text(
                                      'Free giveaway / nothing wanted back',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: const Text(
                                      'Use this when you are giving the offered items away and only need someone to claim them.',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _wantsNothing = value;
                                        if (value) {
                                          _openToOffers = true;
                                          _selectedWantedBlueprints.clear();
                                          _selectedWantedAssets.clear();
                                          _acceptsBlueprints = false;
                                          _acceptsSeeds = false;
                                          _acceptsResources = false;
                                        } else {
                                          _acceptsBlueprints = true;
                                          _acceptsResources = true;
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _selectorTile(
                                    label: 'Wanted Blueprints',
                                    value: _wantsNothing
                                        ? 'Giveaway enabled'
                                        : _openToOffers
                                        ? 'Open to offers enabled'
                                        : _selectionSummary(
                                            _selectedWantedBlueprints.length,
                                            'blueprint',
                                          ),
                                    helper: _openToOffers || _wantsNothing
                                        ? 'Disabled while open to offers or giveaway mode is on.'
                                        : '${missingBlueprints.length} missing blueprints available',
                                    onTap:
                                        _openToOffers ||
                                            _wantsNothing ||
                                            missingBlueprints.isEmpty
                                        ? null
                                        : () async {
                                            final picked =
                                                await _showBlueprintMultiPicker(
                                                  title:
                                                      'Select wanted blueprints',
                                                  items: missingBlueprints,
                                                  initiallySelected:
                                                      _selectedWantedBlueprints,
                                                );
                                            if (!mounted || picked == null)
                                              return;
                                            setState(() {
                                              _selectedWantedBlueprints
                                                ..clear()
                                                ..addAll(picked);
                                            });
                                          },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _chipWrap(
                                    _selectedWantedBlueprints
                                        .map((item) => item.name)
                                        .toList(growable: false),
                                  ),
                                  const SizedBox(height: AppTheme.spaceM),
                                  _selectorTile(
                                    label: 'Wanted Trade Assets',
                                    value: _wantsNothing
                                        ? 'Giveaway enabled'
                                        : _openToOffers
                                        ? 'Open to offers enabled'
                                        : _selectionSummary(
                                            _selectedWantedAssets.length,
                                            'asset',
                                          ),
                                    helper: _openToOffers || _wantsNothing
                                        ? 'Disabled while open to offers or giveaway mode is on.'
                                        : 'Use this for keys, KCs, reactors, guns, and other resources you want back.',
                                    onTap: _openToOffers || _wantsNothing
                                        ? null
                                        : () async {
                                            final picked =
                                                await _showAssetMultiPicker(
                                                  title:
                                                      'Select wanted trade assets',
                                                  initiallySelected:
                                                      _selectedWantedAssets,
                                                );
                                            if (!mounted || picked == null)
                                              return;
                                            setState(() {
                                              _selectedWantedAssets
                                                ..clear()
                                                ..addAll(picked);
                                            });
                                          },
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _chipWrap(
                                    _selectedWantedAssets
                                        .map((item) => item.name)
                                        .toList(growable: false),
                                    color: AppTheme.neonPink,
                                  ),
                                ],
                              ),
                            ),
                            _sectionCard(
                              title: 'Trade Structure',
                              subtitle:
                                  'Use both toggles if you want the listing to prefer a full batch while still allowing people to pitch custom or partial make-up offers.',
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    value: _tradeAsBundle,
                                    onChanged: (value) {
                                      setState(() {
                                        _tradeAsBundle = value;
                                      });
                                    },
                                    activeThumbColor: AppTheme.neonPink,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Trade as one batch / bundle',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: const Text(
                                      'Buyer should take the whole offer together instead of picking bits of it apart.',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  ),
                                  SwitchListTile(
                                    value: _allowPartialOffers,
                                    onChanged: (value) => setState(
                                      () => _allowPartialOffers = value,
                                    ),
                                    activeThumbColor: AppTheme.neonPink,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Allow partial / custom offers',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      _tradeAsBundle
                                          ? 'Keep this on as well if you want to prefer the full bundle but still allow make-up offers.'
                                          : 'Useful when someone only has part of what you want and wants to make up the rest another way.',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionCard(
                              title: 'Trade Preferences',
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    value: _acceptsBlueprints,
                                    onChanged: (value) => setState(
                                      () => _acceptsBlueprints = value ?? false,
                                    ),
                                    title: const Text(
                                      'Accept blueprints',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: AppTheme.neonPink,
                                  ),
                                  CheckboxListTile(
                                    value: _acceptsSeeds,
                                    onChanged: (value) => setState(
                                      () => _acceptsSeeds = value ?? false,
                                    ),
                                    title: const Text(
                                      'Accept seeds',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: AppTheme.neonPink,
                                  ),
                                  CheckboxListTile(
                                    value: _acceptsResources,
                                    onChanged: (value) => setState(
                                      () => _acceptsResources = value ?? false,
                                    ),
                                    title: const Text(
                                      'Accept resources / keys / weapons / mods',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: AppTheme.neonPink,
                                  ),
                                  SwitchListTile(
                                    value: _seriousOffersOnly,
                                    onChanged: (value) => setState(
                                      () => _seriousOffersOnly = value,
                                    ),
                                    activeThumbColor: AppTheme.neonPink,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Serious offers only',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  _buildDropdown(
                                    label: 'Best Play Window',
                                    value: _selectedPlayWindow,
                                    options: const [
                                      'Flexible',
                                      'Afternoons',
                                      'Evenings',
                                      'Late Night',
                                      'Weekends',
                                    ],
                                    onChanged: (value) => setState(
                                      () => _selectedPlayWindow =
                                          value ?? 'Evenings',
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceM),
                                  _buildDropdown(
                                    label: 'Listing Expiry',
                                    value: _selectedExpiry,
                                    options: const [
                                      '24 Hours',
                                      '72 Hours',
                                      '7 Days',
                                    ],
                                    onChanged: (value) => setState(
                                      () =>
                                          _selectedExpiry = value ?? '72 Hours',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionCard(
                              title: 'Preview',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Title: ${_buildTitle()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Offering: ${_buildOfferSummary().isEmpty ? 'Nothing selected yet' : _buildOfferSummary()}',
                                    style: TextStyle(
                                      color: AppTheme.tradingMutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Looking for: ${_buildWantedSummary().isEmpty ? 'Nothing selected yet' : _buildWantedSummary()}',
                                    style: TextStyle(
                                      color: AppTheme.tradingMutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Format: ${_tradeAsBundle ? 'Bundle preferred' : 'Mix and match'}'
                                    '${_allowPartialOffers ? ' • Partial/custom offers enabled' : ''}',
                                    style: TextStyle(
                                      color: AppTheme.tradingMutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionCard(
                              title: 'Notes',
                              child: TextFormField(
                                controller: _notesController,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: AppTheme.tradingInputDecoration(
                                  label:
                                      'Optional details, preferred swap setup, level 4 only, exact ratios, etc.',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveListing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonPink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _isSaving ? 'Saving...' : 'Create Listing',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
