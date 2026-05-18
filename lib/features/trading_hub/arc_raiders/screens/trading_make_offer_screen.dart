import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingMakeOfferScreen extends StatefulWidget {
  const TradingMakeOfferScreen({super.key, required this.listing});

  final TradingListing listing;

  @override
  State<TradingMakeOfferScreen> createState() => _TradingMakeOfferScreenState();
}

class _TradingMakeOfferScreenState extends State<TradingMakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TradingRepository _repository = TradingRepository();

  final TextEditingController _blueprintController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _includesResources = false;
  bool _isSaving = false;
  bool _isLoadingMatches = true;
  List<String> _matchingDupes = <String>[];
  Set<String> _selectedDupes = <String>{};
  final List<ArcTradeItem> _selectedTradeItems = <ArcTradeItem>[];
  late final List<ArcTradeItem> _tradeItems;

  int _smallBundles = 0;
  int _mediumBundles = 0;
  int _largeBundles = 0;

  int get _seedTotal =>
      (_smallBundles * 10) + (_mediumBundles * 50) + (_largeBundles * 100);

  @override
  void initState() {
    super.initState();
    _tradeItems =
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
    _loadMatchingDupes();
  }

  Future<void> _loadMatchingDupes() async {
    try {
      final matches = await _repository.getMatchingDuplicateBlueprintNames(
        widget.listing,
      );
      if (!mounted) return;
      setState(() {
        _matchingDupes = matches;
        _selectedDupes = matches.toSet();
        _blueprintController.text = matches.join(', ');
        _isLoadingMatches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMatches = false;
      });
    }
  }

  void _syncBlueprintTextFromSelection() {
    final values = _selectedDupes.toList()..sort();
    _blueprintController.text = values.join(', ');
  }

  @override
  void dispose() {
    _blueprintController.dispose();
    _resourcesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _sectionCard({required String title, required Widget child}) {
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
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.tradingInputDecoration(label: label),
    );
  }

  String _selectionSummary(int count, String noun) {
    if (count == 0) return 'Nothing selected';
    if (count == 1) return '1 $noun selected';
    return '$count ${noun}s selected';
  }

  Widget _chipWrap(List<String> items) {
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
                color: AppTheme.neonPink,
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: AppTheme.neonPink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<ArcTradeItem>?> _showTradeItemPicker() async {
    final controller = TextEditingController();
    final selectedIds = _selectedTradeItems.map((item) => item.id).toSet();
    var filtered = List<ArcTradeItem>.from(_tradeItems);
    String categoryFilter = 'All';
    final categories = <String>[
      'All',
      ...{for (final item in _tradeItems) item.categoryLabel},
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
                filtered = _tradeItems
                    .where((item) {
                      final matchesCategory =
                          categoryFilter == 'All' ||
                          item.categoryLabel == categoryFilter;
                      final matchesQuery =
                          query.isEmpty ||
                          item.name.toLowerCase().contains(query) ||
                          item.id.toLowerCase().contains(query) ||
                          item.categoryLabel.toLowerCase().contains(query) ||
                          item.rarityLabel.toLowerCase().contains(query) ||
                          item.tradeValueLabel.toLowerCase().contains(query) ||
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
                        'Select trade items',
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
                          label:
                              'Search weapons, ammo, attachments, materials, trinkets',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories
                              .map((category) {
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
                                    backgroundColor:
                                        AppTheme.tradingCardBackground,
                                    side: BorderSide(
                                      color: selected
                                          ? AppTheme.neonPink.withValues(
                                              alpha: 0.7,
                                            )
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
                              })
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        _selectionSummary(selectedIds.length, 'item'),
                        style: TextStyle(color: AppTheme.tradingMutedText),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching trade items.',
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
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
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
                            final selected = _tradeItems
                                .where((item) => selectedIds.contains(item.id))
                                .toList(growable: false);
                            Navigator.of(context).pop(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            foregroundColor: Colors.black,
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

  Future<void> _submitOffer() async {
    if (!widget.listing.wantsNothing && !_formKey.currentState!.validate())
      return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.createOffer(
        listing: widget.listing,
        offeredBlueprintText: widget.listing.wantsNothing
            ? ''
            : _blueprintController.text,
        smallBundles: widget.listing.wantsNothing ? 0 : _smallBundles,
        mediumBundles: widget.listing.wantsNothing ? 0 : _mediumBundles,
        largeBundles: widget.listing.wantsNothing ? 0 : _largeBundles,
        includesResources: widget.listing.wantsNothing
            ? false
            : _includesResources,
        resourcesText: widget.listing.wantsNothing
            ? ''
            : _resourcesController.text,
        note: _noteController.text,
        offeredTradeItemIds: widget.listing.wantsNothing
            ? const <String>[]
            : _selectedTradeItems
                  .map((item) => item.id)
                  .toList(growable: false),
        offeredTradeItemNames: widget.listing.wantsNothing
            ? const <String>[]
            : _selectedTradeItems
                  .map((item) => item.name)
                  .toList(growable: false),
        isGiveawayClaim: widget.listing.wantsNothing,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.listing.wantsNothing
                ? 'Giveaway claim sent successfully.'
                : 'Offer sent successfully.',
          ),
          backgroundColor: AppTheme.neonPink,
        ),
      );

      navigator.pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not send offer: $error'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Make Offer', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppTheme.pagePadding,
                    children: [
                      _sectionCard(
                        title: 'Listing Summary',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: AppTheme.tradingHeading(fontSize: 22),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Offering: ${listing.offeredSummary}',
                              style: TextStyle(
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Wants: ${listing.wantedSummary}',
                              style: TextStyle(
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Auto Matches',
                        child: _isLoadingMatches
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.neonCyan,
                                ),
                              )
                            : _matchingDupes.isEmpty
                            ? Text(
                                'No matching dupes found in your collection yet. You can still type a manual offer below.',
                                style: TextStyle(
                                  color: AppTheme.tradingMutedText,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _matchingDupes
                                    .map((name) {
                                      final selected = _selectedDupes.contains(
                                        name,
                                      );
                                      return FilterChip(
                                        selected: selected,
                                        label: Text(name),
                                        labelStyle: TextStyle(
                                          color: selected
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        selectedColor: AppTheme.neonCyan,
                                        checkmarkColor: Colors.black,
                                        backgroundColor:
                                            AppTheme.tradingCardBackground,
                                        side: BorderSide(
                                          color: selected
                                              ? AppTheme.neonCyan
                                              : AppTheme.tradingSoftBorder,
                                        ),
                                        onSelected: (value) {
                                          setState(() {
                                            if (value) {
                                              _selectedDupes.add(name);
                                            } else {
                                              _selectedDupes.remove(name);
                                            }
                                            _syncBlueprintTextFromSelection();
                                          });
                                        },
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                      ),
                      _sectionCard(
                        title: 'Your Offer',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _blueprintController,
                              label: 'Blueprints You Are Offering',
                              enabled: !listing.wantsNothing,
                              validator: (value) {
                                final hasBlueprint =
                                    value != null && value.trim().isNotEmpty;
                                final hasSeeds = _seedTotal > 0;
                                final hasResources =
                                    _includesResources &&
                                    _resourcesController.text.trim().isNotEmpty;
                                final hasTradeItems =
                                    _selectedTradeItems.isNotEmpty;

                                if (!hasBlueprint &&
                                    !hasSeeds &&
                                    !hasResources &&
                                    !hasTradeItems) {
                                  return 'Add at least one blueprint, item, seed bundle or resource.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: listing.wantsNothing
                                  ? null
                                  : () async {
                                      final picked =
                                          await _showTradeItemPicker();
                                      if (!mounted || picked == null) return;
                                      setState(() {
                                        _selectedTradeItems
                                          ..clear()
                                          ..addAll(picked);
                                      });
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: InputDecorator(
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'Trade Items You Are Offering',
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        listing.wantsNothing
                                            ? 'No return needed for giveaway claim'
                                            : _selectionSummary(
                                                _selectedTradeItems.length,
                                                'item',
                                              ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            _chipWrap(
                              _selectedTradeItems
                                  .map((item) => item.name)
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              value: listing.wantsNothing
                                  ? false
                                  : _includesResources,
                              activeThumbColor: AppTheme.neonPink,
                              title: const Text(
                                'Include Resources',
                                style: TextStyle(color: Colors.white),
                              ),
                              onChanged: listing.wantsNothing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _includesResources = value;
                                      });
                                    },
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            _buildTextField(
                              controller: _resourcesController,
                              label: 'Resource Summary',
                              maxLines: 3,
                              enabled:
                                  !listing.wantsNothing && _includesResources,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Seed Bundles',
                                style: AppTheme.tradingHeading(
                                  fontSize: 18,
                                  color: AppTheme.neonCyan,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _bundleRow(
                              label: '10 Seed Bundles',
                              value: _smallBundles,
                              onMinus: () {
                                if (_smallBundles == 0) return;
                                setState(() => _smallBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _smallBundles += 1);
                              },
                            ),
                            _bundleRow(
                              label: '50 Seed Bundles',
                              value: _mediumBundles,
                              onMinus: () {
                                if (_mediumBundles == 0) return;
                                setState(() => _mediumBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _mediumBundles += 1);
                              },
                            ),
                            _bundleRow(
                              label: '100 Seed Bundles',
                              value: _largeBundles,
                              onMinus: () {
                                if (_largeBundles == 0) return;
                                setState(() => _largeBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _largeBundles += 1);
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Seed Total: $_seedTotal',
                                style: AppTheme.tradingHeading(
                                  fontSize: 18,
                                  color: AppTheme.neonPink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _noteController,
                              label: 'Message To Trader',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submitOffer,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSaving
                                ? (listing.wantsNothing
                                      ? 'Claiming...'
                                      : 'Sending Offer...')
                                : (listing.wantsNothing
                                      ? 'Claim Giveaway'
                                      : 'Send Offer'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
        ],
      ),
    );
  }
}
