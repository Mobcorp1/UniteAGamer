import 'package:flutter/material.dart';

import '../models/arc_trader_search_result.dart';
import '../repositories/arc_trader_search_repository.dart';

class ArcTraderSearchScreen extends StatefulWidget {
  const ArcTraderSearchScreen({super.key});

  static const routeName = '/arc-trader-search';

  @override
  State<ArcTraderSearchScreen> createState() => _ArcTraderSearchScreenState();
}

class _ArcTraderSearchScreenState extends State<ArcTraderSearchScreen> {
  final ArcTraderSearchRepository _repository = ArcTraderSearchRepository();

  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _wantedBlueprintController = TextEditingController();

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
    return Card(
      child: ListTile(
        title: Text(item.uagName.isEmpty ? item.uagId : item.uagName),
        subtitle: Text(
          '${item.region} • ${item.platform}\n'
          'Open listings: ${item.openListingsCount} • Matching offers: ${item.matchingOfferCount}\n'
          '${item.isAway ? 'Away' : 'Available'} • ${item.availabilitySummary}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
