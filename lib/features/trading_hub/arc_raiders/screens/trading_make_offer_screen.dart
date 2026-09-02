import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_cosmetic_identity_strip.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_seed_bundle_picker.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingMakeOfferScreen extends StatefulWidget {
  const TradingMakeOfferScreen({super.key, required this.listing});

  final TradingListing listing;

  @override
  State<TradingMakeOfferScreen> createState() => _TradingMakeOfferScreenState();
}

class _TradingMakeOfferScreenState extends State<TradingMakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TradingRepository _repository = TradingRepository();
  final ArcTradeIntelligenceEngine _tradeIntelligenceEngine =
      const ArcTradeIntelligenceEngine();

  final TextEditingController _blueprintController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _includesResources = false;
  bool _isSaving = false;
  bool _isLoadingMatches = true;
  List<String> _matchingDupes = <String>[];
  Set<String> _selectedDupes = <String>{};
  final List<ArcTradeItem> _selectedTradeItems = <ArcTradeItem>[];
  String _selectedAcceptedBundleId = '';
  bool _preparingExactBundle = false;
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
    final activeBundles = widget.listing.acceptedBundles
        .where((bundle) => bundle.active)
        .toList(growable: false);
    if (activeBundles.isNotEmpty) {
      _selectedAcceptedBundleId = activeBundles.first.id;
    }
    _blueprintController.addListener(_onOfferInputChanged);
    _resourcesController.addListener(_onOfferInputChanged);
    _loadMatchingDupes();
  }

  void _onOfferInputChanged() {
    if (mounted) setState(() {});
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
    _blueprintController.removeListener(_onOfferInputChanged);
    _resourcesController.removeListener(_onOfferInputChanged);
    _blueprintController.dispose();
    _resourcesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return TradingCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArcUiTokens.sectionTitle(
              fontSize: 21,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
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
      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
      decoration: ArcUiTokens.inputDecoration(labelText: label),
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
        style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: AppTheme.pillPadding,
              decoration: ArcUiTokens.chipDecoration(
                color: ArcUiTokens.secondaryAccent,
              ),
              child: Text(
                item,
                style: ArcUiTokens.bodySmall(
                  color: ArcUiTokens.secondaryAccent,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<String> _manualBlueprintOfferItems() {
    return _blueprintController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Widget _offerIntelligenceCard() {
    final score = _tradeIntelligenceEngine.scoreOfferForListing(
      listing: widget.listing,
      offeredBlueprintNames: _manualBlueprintOfferItems(),
      offeredTradeItemNames: _selectedTradeItems
          .map((item) => item.name)
          .toList(growable: false),
      seedTotal: _seedTotal,
      includesResources: _includesResources,
      resourceText: _resourcesController.text,
      exactBundleOffer: _buildExactBundleOffer(),
    );

    return _sectionCard(
      title: 'Offer Intelligence',
      child: _offerScoreContent(score),
    );
  }

  Widget _offerScoreContent(ArcOfferValueScore score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _scorePill(score.label, AppTheme.neonPink),
            _scorePill('Score ${score.score}%', AppTheme.neonCyan),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        Text(
          score.summary,
          style: ArcUiTokens.body(
            fontSize: 13,
            color: ArcUiTokens.textSecondary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        for (final hint in score.hints) ...[
          Text(
            '- $hint',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _scorePill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(
        label,
        style: ArcUiTokens.bodySmall(
          color: color,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
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
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 22,
                          color: ArcUiTokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: controller,
                        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                        onChanged: (_) => updateFilter(),
                        decoration: ArcUiTokens.inputDecoration(
                          labelText:
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
                                    selectedColor: ArcUiTokens.secondaryAccent
                                        .withValues(alpha: 0.25),
                                    checkmarkColor: ArcUiTokens.secondaryAccent,
                                    label: Text(category),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? ArcUiTokens.secondaryAccent
                                          : ArcUiTokens.primaryAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    backgroundColor:
                                        ArcUiTokens.surfaceInteractive,
                                    side: BorderSide(
                                      color: selected
                                          ? ArcUiTokens.secondaryAccent
                                                .withValues(alpha: 0.7)
                                          : ArcUiTokens.primaryAccent
                                                .withValues(alpha: 0.25),
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
                        style: ArcUiTokens.bodySmall(
                          color: ArcUiTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching trade items.',
                                  style: ArcUiTokens.bodySmall(
                                    color: ArcUiTokens.textTertiary,
                                  ),
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
                                    activeColor: ArcUiTokens.secondaryAccent,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      item.name,
                                      style: ArcUiTokens.body(
                                        color: ArcUiTokens.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.categoryLabel} - ${item.rarityLabel} - ${item.tradeValueLabel} value',
                                      style: ArcUiTokens.bodySmall(
                                        color: ArcUiTokens.textTertiary,
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
                          style: ArcUiTokens.textButtonStyle(
                            accent: ArcUiTokens.secondaryAccent,
                            primary: true,
                          ),
                          onPressed: () {
                            final selected = _tradeItems
                                .where((item) => selectedIds.contains(item.id))
                                .toList(growable: false);
                            Navigator.of(context).pop(selected);
                          },
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

  ArcTradeBundleTemplate? get _selectedAcceptedBundle {
    for (final bundle in widget.listing.acceptedBundles) {
      if (bundle.active && bundle.id == _selectedAcceptedBundleId) {
        return bundle;
      }
    }
    return null;
  }

  ArcExactTradeBundleOffer? _buildExactBundleOffer() {
    final bundle = _selectedAcceptedBundle;
    if (bundle == null) {
      return null;
    }
    return ArcExactTradeBundleOffer(
      templateId: bundle.id,
      components: bundle.components,
      preparing: _preparingExactBundle,
      preparationNote: _preparingExactBundle ? _noteController.text.trim() : '',
      completionConfirmed: !_preparingExactBundle,
    );
  }

  String _bundleComponentSummary(ArcTradeBundleComponent component) {
    final config = component.fittedWeapon;
    if (config == null) {
      return '${component.quantity}x ${component.itemName}';
    }
    final slots = config.attachmentsBySlot.entries
        .map((entry) {
          final value =
              entry.value ==
                  ArcFittedWeaponConfiguration.anyCompatibleAttachment
              ? 'Any compatible'
              : entry.value;
          return '${entry.key}: $value';
        })
        .join(', ');
    return '${component.quantity}x ${component.itemName}${slots.isEmpty ? '' : ' ($slots)'}';
  }

  Widget _buildAcceptedBundlePicker() {
    final bundles = widget.listing.acceptedBundles
        .where((bundle) => bundle.active)
        .toList(growable: false);
    if (bundles.isEmpty) {
      return const SizedBox.shrink();
    }
    return _sectionCard(
      title: 'Accepted Exact Bundles',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose one seller-approved bundle. The offer is validated before submission.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 12),
          ...bundles.map((bundle) {
            final selected = bundle.id == _selectedAcceptedBundleId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                selected: selected,
                label: 'Select accepted bundle ${bundle.name}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
                  onTap: () {
                    setState(() {
                      _selectedAcceptedBundleId = bundle.id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: ArcUiTokens.surfaceDecoration(
                      role: ArcSurfaceRole.interactive,
                      accent: ArcUiTokens.primaryAccent,
                      radius: ArcUiTokens.radiusXL,
                      selected: selected,
                      backgroundColor: selected
                          ? ArcUiTokens.primaryAccent.withValues(alpha: 0.10)
                          : ArcUiTokens.surfaceInteractive.withValues(
                              alpha: 0.74,
                            ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? ArcUiTokens.primaryAccent
                              : ArcUiTokens.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bundle.name,
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bundle.components
                                    .map(_bundleComponentSummary)
                                    .join(' - '),
                                style: ArcUiTokens.bodySmall(
                                  color: ArcUiTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          SwitchListTile.adaptive(
            value: _preparingExactBundle,
            activeThumbColor: ArcUiTokens.primaryAccent,
            activeTrackColor: ArcUiTokens.primaryAccent.withValues(alpha: 0.45),
            title: Text(
              'I am preparing this bundle',
              style: ArcUiTokens.body(
                color: ArcUiTokens.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'The seller can see that you intend to farm or assemble the requested items.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
            onChanged: (value) => setState(() => _preparingExactBundle = value),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOffer() async {
    if (!widget.listing.wantsNothing && !_formKey.currentState!.validate()) {
      return;
    }

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
        exactBundleOffer: _buildExactBundleOffer(),
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
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Make Offer', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.pageMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
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
                          TradingCosmeticIdentityStrip(
                            repository: _repository,
                            uid: listing.ownerUid,
                            displayName: listing.traderName,
                            subtitle: [
                              if (listing.gamerTag.isNotEmpty) listing.gamerTag,
                              if (listing.preferredPlatform.isNotEmpty)
                                listing.preferredPlatform,
                              listing.reputationSummary,
                            ].join(' - '),
                            compact: true,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Offering: ${listing.offeredSummary}',
                            style: TextStyle(color: AppTheme.tradingMutedText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wants: ${listing.wantedSummary}',
                            style: TextStyle(color: AppTheme.tradingMutedText),
                          ),
                        ],
                      ),
                    ),
                    _buildAcceptedBundlePicker(),
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
                    if (!listing.wantsNothing) _offerIntelligenceCard(),
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
                                    final picked = await _showTradeItemPicker();
                                    if (!mounted || picked == null) return;
                                    setState(() {
                                      _selectedTradeItems
                                        ..clear()
                                        ..addAll(picked);
                                    });
                                  },
                            borderRadius: BorderRadius.circular(
                              ArcUiTokens.radiusL,
                            ),
                            child: InputDecorator(
                              decoration: ArcUiTokens.inputDecoration(
                                labelText: 'Trade Items You Are Offering',
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
                                      style: ArcUiTokens.body(
                                        color: ArcUiTokens.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: ArcUiTokens.textSecondary,
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
                            activeThumbColor: ArcUiTokens.secondaryAccent,
                            title: Text(
                              'Include Resources',
                              style: ArcUiTokens.body(
                                color: ArcUiTokens.textPrimary,
                              ),
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
                          TradingSeedBundlePicker(
                            smallBundles: _smallBundles,
                            mediumBundles: _mediumBundles,
                            largeBundles: _largeBundles,
                            onSmallChanged: (value) =>
                                setState(() => _smallBundles = value),
                            onMediumChanged: (value) =>
                                setState(() => _mediumBundles = value),
                            onLargeChanged: (value) =>
                                setState(() => _largeBundles = value),
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
      ),
    );
  }
}
