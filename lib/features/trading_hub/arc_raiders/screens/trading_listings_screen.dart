import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingListingsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/listings';

  const TradingListingsScreen({
    super.key,
    this.showAppBar = true,
    this.embedProfileSummary = false,
  });

  final bool showAppBar;
  final bool embedProfileSummary;

  @override
  State<TradingListingsScreen> createState() => _TradingListingsScreenState();
}

class _TradingListingsScreenState extends State<TradingListingsScreen> {
  final TradingRepository _repository = TradingRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _showOpenToOffersOnly = false;
  bool _showLowRiskOnly = false;
  bool _showSeedsOnly = false;
  bool _showBundleOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> _buildMissingBlueprintNames(
    Map<String, ArcBlueprintState> states,
  ) {
    final ownedBlueprintIds = states.values
        .where((state) => state.owned)
        .map((state) => state.blueprintId)
        .toSet();

    return ArcBlueprintSeedData.blueprints
        .where((blueprint) => !ownedBlueprintIds.contains(blueprint.id))
        .map((blueprint) => blueprint.name.toLowerCase())
        .toSet();
  }

  List<TradingListing> _applyFilters(
    List<TradingListing> listings,
    Set<String> missingBlueprintNames,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return listings
        .where((listing) {
          final hasOfferedMatch = missingBlueprintNames.isEmpty
              ? true
              : listing.offeredBlueprintNames
                    .map((name) => name.toLowerCase())
                    .any(missingBlueprintNames.contains);

          if (!hasOfferedMatch) {
            return false;
          }

          if (_showOpenToOffersOnly &&
              listing.listingType != TradingListingType.openToOffers) {
            return false;
          }

          if (_showLowRiskOnly && listing.riskLevel != TradingRiskLevel.low) {
            return false;
          }

          if (_showSeedsOnly &&
              listing.seedTotalOffered <= 0 &&
              !listing.acceptsSeeds) {
            return false;
          }

          if (_showBundleOnly && !listing.tradeAsBundle) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final searchableText = [
            listing.title,
            listing.offeredSummary,
            listing.wantedSummary,
            listing.traderName,
            listing.region,
            listing.playWindow,
            ...listing.offeredBlueprintNames,
            ...listing.wantedBlueprintNames,
            ...listing.offeredAssetNames,
            ...listing.wantedAssetNames,
          ].join(' ').toLowerCase();

          return searchableText.contains(query);
        })
        .toList(growable: false);
  }

  String _expiryText(DateTime expiresAt) {
    final difference = expiresAt.difference(DateTime.now());

    if (difference.inHours < 24) {
      return '${difference.inHours.clamp(0, 999)}h left';
    }

    return '${difference.inDays.clamp(0, 999)}d left';
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.neonPink.withValues(alpha: 0.25),
      checkmarkColor: AppTheme.neonPink,
      labelStyle: TextStyle(
        color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppTheme.tradingCardBackground,
      side: BorderSide(
        color: selected
            ? AppTheme.neonPink.withValues(alpha: 0.75)
            : AppTheme.neonCyan.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.tradingCardBackground,
        border: Border.all(color: AppTheme.tradingSoftBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.tradingMutedText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _listingCard(BuildContext context, TradingListing listing) {
    final subtitleBits = [
      if (listing.tradeAsBundle) 'Bundle only' else 'Mix and match',
      if (listing.allowPartialOffers) 'Partial offers on',
      if (listing.seriousOffersOnly) 'Serious only',
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TradingListingDetailScreen(listing: listing),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(),
        child: Padding(
          padding: AppTheme.sectionCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: AppTheme.tradingHeading(
                  fontSize: 22,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(listing.riskLabel, listing.riskColor()),
                  _metaChip(listing.region),
                  _metaChip(listing.playWindow),
                  _metaChip(_expiryText(listing.expiresAt)),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                'Offering',
                style: AppTheme.tradingHeading(
                  fontSize: 17,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listing.offeredSummary,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                'Looking for',
                style: AppTheme.tradingHeading(
                  fontSize: 17,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listing.wantedSummary,
                style: const TextStyle(color: Colors.white),
              ),
              if (subtitleBits.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  subtitleBits.join(' • '),
                  style: TextStyle(color: AppTheme.tradingMutedText),
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
              Divider(color: AppTheme.tradingDivider),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                '${listing.traderName}'
                '${listing.gamerTag.isNotEmpty ? ' • ${listing.gamerTag}' : ''}'
                '${listing.preferredPlatform.isNotEmpty ? ' • ${listing.preferredPlatform}' : ''}',
                style: TextStyle(
                  color: AppTheme.tradingMutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSummaryCard(BuildContext context, ArcTraderProfile profile) {
    final statusColor = profile.isProfileComplete
        ? AppTheme.neonCyan
        : AppTheme.warningAmber;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: statusColor.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.uagName.trim().isEmpty
                          ? 'Trader Profile'
                          : profile.uagName,
                      style: AppTheme.tradingHeading(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.uagId.trim().isEmpty
                          ? 'Set up your trading identity and visibility.'
                          : profile.uagId,
                      style: TextStyle(color: AppTheme.tradingMutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: AppTheme.pillPadding,
                decoration: AppTheme.tradingPillDecoration(color: statusColor),
                child: Text(
                  profile.isProfileComplete ? 'Ready' : 'Needs setup',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(
                profile.region.isEmpty ? 'Region not set' : profile.region,
              ),
              _metaChip(
                profile.platform.isEmpty
                    ? 'Platform not set'
                    : profile.platform,
              ),
              _metaChip(
                profile.visibleInSearch
                    ? 'Visible in search'
                    : 'Hidden in search',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(TradingProfileScreen.routeName);
              },
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('Open Trader Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasMissingBlueprints) {
    return Center(
      child: Text(
        hasMissingBlueprints
            ? 'No active listings are currently offering the blueprints you are missing.'
            : 'No listings match your current filters.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.tradingMutedText, fontSize: 16),
      ),
    );
  }

  Widget _buildFilterPanel(int wantedCount) {
    return CollapsibleSectionCard(
      title: 'Listings Filters',
      initiallyExpanded: false,
      titleColor: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wantedCount > 0
                ? 'Showing listings offering blueprints you are still missing.'
                : 'No missing blueprints detected yet, so all active listings are visible.',
            style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceM,
            runSpacing: AppTheme.spaceM,
            children: [
              _buildFilterChip(
                label: 'Open to Offers',
                selected: _showOpenToOffersOnly,
                onTap: () => setState(
                  () => _showOpenToOffersOnly = !_showOpenToOffersOnly,
                ),
              ),
              _buildFilterChip(
                label: 'Low Risk',
                selected: _showLowRiskOnly,
                onTap: () =>
                    setState(() => _showLowRiskOnly = !_showLowRiskOnly),
              ),
              _buildFilterChip(
                label: 'Seed Trades',
                selected: _showSeedsOnly,
                onTap: () => setState(() => _showSeedsOnly = !_showSeedsOnly),
              ),
              _buildFilterChip(
                label: 'Bundle Only',
                selected: _showBundleOnly,
                onTap: () => setState(() => _showBundleOnly = !_showBundleOnly),
              ),
            ],
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
                'Market',
                style: AppTheme.tradingHeading(fontSize: 25),
              ),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: Padding(
                  padding: AppTheme.pagePadding,
                  child: StreamBuilder<Map<String, ArcBlueprintState>>(
                    stream: _blueprintRepository.watchMyBlueprintStates(),
                    builder: (context, statesSnapshot) {
                      final states = statesSnapshot.data ?? const {};
                      final missingBlueprintNames = _buildMissingBlueprintNames(
                        states,
                      );

                      return Column(
                        children: [
                          if (widget.embedProfileSummary)
                            StreamBuilder<ArcTraderProfile>(
                              stream: _profileRepository.watchProfile(),
                              builder: (context, profileSnapshot) {
                                final profile =
                                    profileSnapshot.data ??
                                    ArcTraderProfile.empty(
                                      _profileRepository.currentUid ?? '',
                                    );

                                return _profileSummaryCard(context, profile);
                              },
                            ),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white),
                            decoration: AppTheme.tradingInputDecoration(
                              label:
                                  'Search blueprints, keys, weapons, mods, traders',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceM),
                          _buildFilterPanel(missingBlueprintNames.length),
                          const SizedBox(height: AppTheme.spaceL),
                          Expanded(
                            child: StreamBuilder<List<TradingListing>>(
                              stream: _repository.watchActiveListings(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.neonCyan,
                                    ),
                                  );
                                }

                                final listings = _applyFilters(
                                  snapshot.data ?? const [],
                                  missingBlueprintNames,
                                );

                                if (listings.isEmpty) {
                                  return _buildEmptyState(
                                    missingBlueprintNames.isNotEmpty,
                                  );
                                }

                                return ListView.builder(
                                  itemCount: listings.length,
                                  itemBuilder: (context, index) =>
                                      _listingCard(context, listings[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
