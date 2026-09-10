import 'package:flutter/material.dart';

import '../models/arc_trader_search_result.dart';
import '../repositories/arc_trader_search_repository.dart';
import '../repositories/trading_repository.dart';
import '../widgets/arc_companion_bottom_dock.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/foundation/arc_ui_tokens.dart';
import '../widgets/trading_card.dart';
import '../widgets/trading_cosmetic_identity_strip.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcTraderSearchScreen extends StatefulWidget {
  const ArcTraderSearchScreen({super.key});

  static const routeName = '/arc-trader-search';

  @override
  State<ArcTraderSearchScreen> createState() => _ArcTraderSearchScreenState();
}

class _ArcTraderSearchScreenState extends State<ArcTraderSearchScreen> {
  final ArcTraderSearchRepository _repository = ArcTraderSearchRepository();
  final TradingRepository _tradingRepository = TradingRepository();

  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _wantedBlueprintController =
      TextEditingController();

  bool _loading = false;
  bool _hasSearched = false;
  List<ArcTraderSearchResult> _results = const [];

  @override
  void dispose() {
    _regionController.dispose();
    _platformController.dispose();
    _wantedBlueprintController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final results = await _repository.searchTraders(
        region: _regionController.text.trim(),
        platform: _platformController.text.trim(),
        wantedBlueprintId: _wantedBlueprintController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _hasSearched = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not search traders. Try again.')),
      );
    }
  }

  Widget _buildResultCard(ArcTraderSearchResult item) {
    final subtitle = [
      if (item.uagId.isNotEmpty) item.uagId,
      if (item.platform.isNotEmpty) item.platform,
      if (item.region.isNotEmpty) item.region,
      'Open listings: ${item.openListingsCount}',
      'Matching offers: ${item.matchingOfferCount}',
      item.isAway ? 'Away' : 'Available',
      if (item.availabilitySummary.isNotEmpty) item.availabilitySummary,
    ].join(' - ');

    return TradingCard(
      margin: const EdgeInsets.only(bottom: 12),
      accent: item.isAway ? AppTheme.warningAmber : AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TradingCosmeticIdentityStrip(
            repository: _tradingRepository,
            uid: item.userId,
            displayName: item.uagName.isEmpty ? item.uagId : item.uagName,
            subtitle: subtitle,
            compact: true,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ArcTacticalStatusPill(
                label: item.isAway ? 'Away' : 'Available',
                icon: item.isAway
                    ? Icons.do_not_disturb_on_outlined
                    : Icons.verified_rounded,
                accent: item.isAway ? ArcUiTokens.warning : ArcUiTokens.success,
              ),
              ArcTacticalStatusPill(
                label: '${item.openListingsCount} listings',
                icon: Icons.storefront_rounded,
                accent: ArcUiTokens.secondaryAccent,
              ),
              ArcTacticalStatusPill(
                label: '${item.matchingOfferCount} matches',
                icon: Icons.swap_horiz_rounded,
                accent: ArcUiTokens.primaryAccent,
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Trading'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Search Traders',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: ArcRaidersPageList(
            maxWidth: 980,
            bottomPadding: 112,
            children: [
              const ArcRaidersPageHeader(
                title: 'SEARCH TRADERS',
                subtitle: 'Find active Raiders by region, platform or need.',
                icon: Icons.manage_search_rounded,
                accent: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(height: AppTheme.spaceM),
              ArcRaidersSectionCard(
                accent: ArcUiTokens.secondaryAccent,
                padding: const EdgeInsets.all(ArcUiTokens.gapM),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final fields = [
                      TextField(
                        controller: _regionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: ArcUiTokens.inputDecoration(
                          labelText: 'Region',
                          prefixIcon: Icons.public_rounded,
                        ),
                      ),
                      TextField(
                        controller: _platformController,
                        style: const TextStyle(color: Colors.white),
                        decoration: ArcUiTokens.inputDecoration(
                          labelText: 'Platform',
                          prefixIcon: Icons.sports_esports_rounded,
                        ),
                      ),
                      TextField(
                        controller: _wantedBlueprintController,
                        style: const TextStyle(color: Colors.white),
                        decoration: ArcUiTokens.inputDecoration(
                          labelText: 'Wanted Blueprint ID',
                          prefixIcon: Icons.grid_view_rounded,
                        ),
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: [
                          for (final field in fields) ...[
                            field,
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ArcUiTokens.textButtonStyle(
                                accent: ArcUiTokens.secondaryAccent,
                                primary: true,
                              ),
                              onPressed: _loading ? null : _search,
                              icon: const Icon(Icons.search_rounded),
                              label: Text(_loading ? 'Searching...' : 'Search'),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final field in fields) ...[
                          Expanded(child: field),
                          const SizedBox(width: 10),
                        ],
                        ElevatedButton.icon(
                          style: ArcUiTokens.textButtonStyle(
                            accent: ArcUiTokens.secondaryAccent,
                            primary: true,
                          ),
                          onPressed: _loading ? null : _search,
                          icon: const Icon(Icons.search_rounded),
                          label: Text(_loading ? 'Searching...' : 'Search'),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const ArcRaidersStatePanel(
                  title: 'Searching trade network',
                  message: 'Checking matching trader profiles.',
                  icon: Icons.sync_rounded,
                  accent: ArcUiTokens.primaryAccent,
                  compact: true,
                )
              else if (_results.isEmpty)
                ArcRaidersStatePanel(
                  title: _hasSearched ? 'No traders found' : 'Ready to search',
                  message: _hasSearched
                      ? 'Try widening the region, platform or blueprint filter.'
                      : 'Enter the signals you care about and run a trader search.',
                  icon: _hasSearched
                      ? Icons.search_off_rounded
                      : Icons.radar_rounded,
                  accent: _hasSearched
                      ? ArcUiTokens.warning
                      : ArcUiTokens.primaryAccent,
                  compact: true,
                )
              else ...[
                ArcRaidersPageHeader(
                  title: 'MATCHING RAIDERS',
                  subtitle: '${_results.length} trader profiles returned.',
                  icon: Icons.groups_rounded,
                  accent: ArcUiTokens.primaryAccent,
                ),
                const SizedBox(height: AppTheme.spaceM),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 2 : 1;
                    const spacing = 10.0;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final result in _results)
                          SizedBox(
                            width: columns == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth - spacing) / 2,
                            child: _buildResultCard(result),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
