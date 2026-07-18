import 'package:flutter/material.dart';

import '../models/arc_trader_search_result.dart';
import '../repositories/arc_trader_search_repository.dart';
import '../repositories/trading_repository.dart';
import '../widgets/trading_cosmetic_identity_strip.dart';

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
    final results = await _repository.searchTraders(
      region: _regionController.text.trim(),
      platform: _platformController.text.trim(),
      wantedBlueprintId: _wantedBlueprintController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: TradingCosmeticIdentityStrip(
          repository: _tradingRepository,
          uid: item.userId,
          displayName: item.uagName.isEmpty ? item.uagId : item.uagName,
          subtitle: subtitle,
          compact: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Search Traders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _regionController,
            decoration: const InputDecoration(labelText: 'Region'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _platformController,
            decoration: const InputDecoration(labelText: 'Platform'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wantedBlueprintController,
            decoration: const InputDecoration(labelText: 'Wanted Blueprint ID'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _search,
            child: Text(_loading ? 'Searching...' : 'Search'),
          ),
          const SizedBox(height: 16),
          if (_results.isEmpty && !_loading)
            const Text('No traders found yet.'),
          for (final result in _results) _buildResultCard(result),
        ],
      ),
    );
  }
}
