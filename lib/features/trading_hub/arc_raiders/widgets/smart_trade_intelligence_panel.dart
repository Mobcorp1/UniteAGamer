import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/services/smart_trade_intelligence_service.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SmartTradeIntelligencePanel extends StatefulWidget {
  const SmartTradeIntelligencePanel({
    super.key,
    required this.duplicateItemId,
    required this.priorityWantedItemIds,
    this.duplicateLabel,
    this.priorityWantedLabels = const <String>[],
    this.compact = false,
  });

  final String duplicateItemId;
  final List<String> priorityWantedItemIds;
  final String? duplicateLabel;
  final List<String> priorityWantedLabels;
  final bool compact;

  @override
  State<SmartTradeIntelligencePanel> createState() =>
      _SmartTradeIntelligencePanelState();
}

class _SmartTradeIntelligencePanelState
    extends State<SmartTradeIntelligencePanel> {
  final SmartTradeIntelligenceService _service =
      SmartTradeIntelligenceService();

  late Future<SmartTradeSuggestion> _future;
  bool _creatingListing = false;
  bool _creatingOffer = false;

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestion();
  }

  @override
  void didUpdateWidget(covariant SmartTradeIntelligencePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duplicateItemId != widget.duplicateItemId ||
        oldWidget.priorityWantedItemIds.join('|') !=
            widget.priorityWantedItemIds.join('|')) {
      _future = _loadSuggestion();
    }
  }

  Future<SmartTradeSuggestion> _loadSuggestion() {
    return _service.buildSuggestionForDuplicate(
      duplicateItemId: widget.duplicateItemId,
      priorityWantedItemIds: widget.priorityWantedItemIds,
      duplicateLabel: widget.duplicateLabel,
      priorityWantedLabels: widget.priorityWantedLabels,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadSuggestion();
    });
    await _future;
  }

  Future<void> _createListing(SmartTradeSuggestion suggestion) async {
    if (_creatingListing) return;

    setState(() => _creatingListing = true);

    try {
      await _service.createSmartListing(
        listingDraft: suggestion.readyListingDraft,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Smart listing created.')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create smart listing: $e')),
      );
    } finally {
      if (mounted) setState(() => _creatingListing = false);
    }
  }

  Future<void> _createOffer(SmartTradeMatch match) async {
    if (_creatingOffer) return;

    final offeredItemId = widget.duplicateItemId;
    final wantedItemId = _firstPriorityInMatch(match);

    if (wantedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This match is not offering one of your priorities.'),
        ),
      );
      return;
    }

    setState(() => _creatingOffer = true);

    try {
      await _service.createSmartOffer(
        match: match,
        offeredItemId: offeredItemId,
        wantedItemId: wantedItemId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Smart offer created.')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create smart offer: $e')),
      );
    } finally {
      if (mounted) setState(() => _creatingOffer = false);
    }
  }

  String? _firstPriorityInMatch(SmartTradeMatch match) {
    for (final priority in widget.priorityWantedItemIds) {
      final normalized = priority
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      if (match.offeredItemIds.contains(normalized)) {
        return priority;
      }
    }
    return match.offeredItemIds.isNotEmpty ? match.offeredItemIds.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SmartTradeSuggestion>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shell(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spaceL),
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _shell(
            child: Text(
              'Smart trading check failed: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.tradingDanger),
            ),
          );
        }

        final suggestion = snapshot.data;

        if (suggestion == null) {
          return _shell(
            child: const Text(
              'No smart trade data available yet.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return _shell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.neonPink,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Smart Trade Intelligence',
                      style: AppTheme.tradingHeading(
                        fontSize: 22,
                        color: AppTheme.neonPink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                suggestion.hasAnyMatch
                    ? suggestion.hasPerfectMatch
                          ? 'Perfect trade found. They want your duplicate and are offering one of your priority targets.'
                          : 'Possible trades found. Review the match reason before creating an offer.'
                    : 'No active matching listing yet. Create a smart listing for your highest priority target.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (suggestion.bestMatches.isEmpty)
                _emptySuggestion(suggestion)
              else
                ...suggestion.bestMatches.take(5).map(_matchCard),
            ],
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.24),
      ),
      child: child,
    );
  }

  Widget _emptySuggestion(SmartTradeSuggestion suggestion) {
    final wantedLabel = widget.priorityWantedLabels.isNotEmpty
        ? widget.priorityWantedLabels.first
        : suggestion.priorityWantedItemIds.isNotEmpty
        ? suggestion.priorityWantedItemIds.first
        : 'your top priority';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
        backgroundColor: AppTheme.cardBackgroundAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready listing suggestion',
            style: AppTheme.tradingHeading(fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Offer ${widget.duplicateLabel ?? widget.duplicateItemId} for $wantedLabel.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ElevatedButton.icon(
            onPressed: _creatingListing
                ? null
                : () => _createListing(suggestion),
            icon: const Icon(Icons.add_task_rounded),
            label: Text(_creatingListing ? 'Creating...' : 'Create Listing'),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(SmartTradeMatch match) {
    final offered = match.offeredLabels.isNotEmpty
        ? match.offeredLabels.join(', ')
        : match.offeredItemIds.join(', ');
    final wanted = match.wantedLabels.isNotEmpty
        ? match.wantedLabels.join(', ')
        : match.wantedItemIds.join(', ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppTheme.spaceM),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: match.isPerfect
            ? Colors.lightGreenAccent.withValues(alpha: 0.32)
            : AppTheme.neonCyan.withValues(alpha: 0.18),
        backgroundColor: AppTheme.cardBackgroundAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(match.scoreLabel, AppTheme.neonPink),
              _pill('Score ${match.score}', AppTheme.neonCyan),
              _pill(match.listingCollection, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(match.reason, style: AppTheme.tradingHeading(fontSize: 18)),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'They offer: $offered',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'They want: $wanted',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ElevatedButton.icon(
            onPressed: _creatingOffer ? null : () => _createOffer(match),
            icon: const Icon(Icons.outgoing_mail_rounded),
            label: Text(_creatingOffer ? 'Creating...' : 'Create Smart Offer'),
          ),
        ],
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
}
