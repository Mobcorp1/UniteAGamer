import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_listing_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingListingQueuesScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/listing-queues';

  const TradingListingQueuesScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingListingQueuesScreen> createState() =>
      _TradingListingQueuesScreenState();
}

class _TradingListingQueuesScreenState
    extends State<TradingListingQueuesScreen> {
  final TradingRepository _repository = TradingRepository();
  bool _busy = false;

  TradingListing? _activeListingForQueue(
    ArcTradeListingQueueItem queue,
    List<TradingListing> listings,
  ) {
    final activeId = queue.activeListingId.trim().isEmpty
        ? queue.sourceListingId
        : queue.activeListingId.trim();
    for (final listing in listings) {
      if (listing.id == activeId) return listing;
    }
    return null;
  }

  ArcBlueprintState _stateForQueue(
    ArcTradeListingQueueItem queue,
    Map<String, ArcBlueprintState> states,
  ) {
    return states[queue.blueprintId] ??
        ArcBlueprintState.empty(queue.blueprintId);
  }

  bool _activeListingStillLive(TradingListing? listing) {
    return listing != null &&
        listing.active &&
        listing.expiresAt.isAfter(DateTime.now());
  }

  bool _canRelease({
    required ArcTradeListingQueueItem queue,
    required TradingListing? activeListing,
    required ArcBlueprintState state,
  }) {
    if (!queue.canManuallyRelease) return false;
    if (_activeListingStillLive(activeListing)) return false;
    return state.dupesOwned >= queue.releasedQuantity + 1;
  }

  String _queueReason({
    required ArcTradeListingQueueItem queue,
    required TradingListing? activeListing,
    required ArcBlueprintState state,
  }) {
    if (queue.status == ArcTradeListingQueueStatus.cancelled) {
      return 'Future queued releases are cancelled.';
    }
    if (queue.status == ArcTradeListingQueueStatus.completed) {
      return 'All queued releases have been used.';
    }
    if (queue.isPaused) return 'Queue is paused.';
    if (_activeListingStillLive(activeListing)) {
      return 'Waiting for the current queue-linked listing to close or expire.';
    }
    if (!queue.hasRemaining) return 'No queued duplicate remains.';
    if (state.dupesOwned < queue.releasedQuantity + 1) {
      return 'Duplicate ownership no longer supports this queue.';
    }
    if (queue.blockedReason.trim().isNotEmpty) return queue.blockedReason;
    return 'Ready to release the next queued copy.';
  }

  Color _statusColor(ArcTradeListingQueueItem queue, bool canRelease) {
    if (canRelease) return AppTheme.tradingSuccess;
    switch (queue.status) {
      case ArcTradeListingQueueStatus.active:
        return AppTheme.neonCyan;
      case ArcTradeListingQueueStatus.paused:
        return AppTheme.warningAmber;
      case ArcTradeListingQueueStatus.blocked:
        return AppTheme.tradingDanger;
      case ArcTradeListingQueueStatus.completed:
        return Colors.white54;
      case ArcTradeListingQueueStatus.cancelled:
        return AppTheme.tradingDanger;
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _releaseNext(ArcTradeListingQueueItem queue) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final listing = await _repository.releaseNextQueuedListing(queue.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            listing == null
                ? 'Queue was not released. Check the queue reason.'
                : 'Next queued listing released.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not release queue: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pauseResume(ArcTradeListingQueueItem queue) async {
    try {
      if (queue.isPaused) {
        await _repository.resumeListingQueue(queue.id);
      } else {
        await _repository.pauseListingQueue(queue.id);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update queue: $error')));
    }
  }

  Future<void> _cancel(ArcTradeListingQueueItem queue) async {
    try {
      await _repository.cancelListingQueue(queue.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Queue cancelled.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not cancel queue: $error')));
    }
  }

  Widget _queueCard({
    required ArcTradeListingQueueItem queue,
    required TradingListing? activeListing,
    required ArcBlueprintState state,
  }) {
    final canRelease = _canRelease(
      queue: queue,
      activeListing: activeListing,
      state: state,
    );
    final statusColor = _statusColor(queue, canRelease);
    final reason = _queueReason(
      queue: queue,
      activeListing: activeListing,
      state: state,
    );
    final card = Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: canRelease
            ? AppTheme.tradingSuccess.withValues(alpha: 0.4)
            : AppTheme.tradingSoftBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  queue.blueprintName,
                  style: AppTheme.tradingHeading(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              _pill(canRelease ? 'Ready' : queue.statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(reason, style: TextStyle(color: AppTheme.tradingMutedText)),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Remaining ${queue.remainingQuantity}', AppTheme.neonCyan),
              _pill('Released ${queue.releasedQuantity}', AppTheme.neonPink),
              _pill('Public ${queue.publicQuantity}', AppTheme.warningAmber),
              _pill(queue.releasePolicyLabel, Colors.white70),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            activeListing == null
                ? 'Active listing: Not found'
                : 'Active listing: ${activeListing.expiryLabel()}',
            style: TextStyle(color: AppTheme.tradingFaintText),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (activeListing != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TradingListingDetailScreen(listing: activeListing),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Listing'),
                ),
              ElevatedButton.icon(
                onPressed: canRelease && !_busy
                    ? () => _releaseNext(queue)
                    : null,
                icon: const Icon(Icons.publish_rounded),
                label: Text(_busy ? 'Releasing...' : 'Release Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: queue.isTerminal ? null : () => _pauseResume(queue),
                icon: Icon(
                  queue.isPaused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                ),
                label: Text(queue.isPaused ? 'Resume' : 'Pause'),
              ),
              TextButton.icon(
                onPressed: queue.isTerminal ? null : () => _cancel(queue),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Future'),
              ),
            ],
          ),
        ],
      ),
    );

    if (activeListing == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TradingListingDetailScreen(listing: activeListing),
          ),
        );
      },
      child: card,
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
              Icons.dynamic_feed_outlined,
              color: AppTheme.neonCyan.withValues(alpha: 0.72),
              size: 42,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              'NO LISTING QUEUES',
              style: AppTheme.tradingHeading(
                fontSize: 22,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Enable queued release when creating a duplicate blueprint listing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        const Positioned.fill(child: ArcRaidersScreenBackdrop()),
        SafeArea(
          child: StreamBuilder<List<ArcTradeListingQueueItem>>(
            stream: _repository.watchListingQueues(),
            builder: (context, queueSnapshot) {
              return StreamBuilder<List<TradingListing>>(
                stream: _repository.watchMyListings(),
                builder: (context, listingSnapshot) {
                  return StreamBuilder<Map<String, ArcBlueprintState>>(
                    stream: _repository.watchBlueprintStates(),
                    builder: (context, stateSnapshot) {
                      final queues =
                          queueSnapshot.data ??
                          const <ArcTradeListingQueueItem>[];
                      final listings =
                          listingSnapshot.data ?? const <TradingListing>[];
                      final states =
                          stateSnapshot.data ??
                          const <String, ArcBlueprintState>{};

                      if (queueSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          queueSnapshot.data == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.neonCyan,
                          ),
                        );
                      }
                      if (queues.isEmpty) return _emptyState();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                        children: [
                          Text(
                            'Listing Queues',
                            style: AppTheme.tradingHeading(
                              fontSize: 22,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceM),
                          for (final queue in queues)
                            _queueCard(
                              queue: queue,
                              activeListing: _activeListingForQueue(
                                queue,
                                listings,
                              ),
                              state: _stateForQueue(queue, states),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) return _buildBody();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Listing Queues',
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
      ),
      body: _buildBody(),
    );
  }
}
