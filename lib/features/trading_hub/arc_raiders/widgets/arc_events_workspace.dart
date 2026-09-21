import 'dart:async';
import 'package:flutter/material.dart';
import '../data/arc_event_relevance.dart';
import '../raid_planner/data/arc_regional_map_conditions.dart';
import '../raid_planner/data/raid_planner_event_schedule.dart';
import '../raid_planner/models/raid_planner_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

const arcEventsRoute = '/trading-hub/arc-raiders/events';

/// Shared scan-first view. Compact mode is deliberately capped at two events.
class ArcEventsWorkspace extends StatefulWidget {
  const ArcEventsWorkspace({
    super.key,
    required this.relevance,
    this.compact = false,
    this.nowUtc,
    this.conditionsSource,
    this.slots = RaidPlannerEventSchedule.slots,
    this.contextNotice,
  });
  final ArcEventRelevance relevance;
  final bool compact;
  final DateTime? nowUtc;
  final Future<ArcRegionalMapConditionsSnapshot> Function()? conditionsSource;
  final List<RaidPlannerEventSlot> slots;
  final String? contextNotice;

  @override
  State<ArcEventsWorkspace> createState() => _ArcEventsWorkspaceState();
}

class _ArcEventsWorkspaceState extends State<ArcEventsWorkspace> {
  Timer? _timer;
  bool _showAll = false;
  String _query = '';
  ArcServerRegion _region = ArcServerRegion.europe;
  ArcRegionalMapConditionsSnapshot? _conditions;
  bool _loading = false;
  bool _failed = false;
  int _request = 0;
  DateTime get _now => widget.nowUtc ?? DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    if (!widget.compact) _refresh();
    if (widget.nowUtc == null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _refresh() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result =
          await (widget.conditionsSource?.call() ??
              ArcRegionalMapConditionsService.load(forceRefresh: true));
      if (!mounted || request != _request) return;
      setState(() {
        // Keep the last live result if a refresh returns the captured fallback.
        if (_conditions?.isOfficialLive != true || result.isOfficialLive) {
          _conditions = result;
        }
        _failed = !result.isOfficialLive;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} local';
  }

  @override
  Widget build(BuildContext context) {
    final ranked = widget.relevance.rank(
      nowUtc: _now,
      slots: widget.slots,
      showAll: _showAll,
    );
    final filtered = ranked
        .where(
          (event) => '${event.slot.eventName} ${event.slot.mapName}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    final events = widget.compact ? filtered.take(2).toList() : filtered;
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 13, height: 1.25),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  widget.compact ? 'EVENTS' : 'OPERATIONS SCHEDULE',
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: AppTheme.neonCyan,
                  ),
                ),
                if (widget.compact)
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(arcEventsRoute),
                    child: const Text(
                      'SHOW ALL EVENTS',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (widget.contextNotice != null)
              Text(
                widget.contextNotice!,
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            if (!widget.compact) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Relevant to me'),
                    selected: !_showAll,
                    onSelected: (_) => setState(() => _showAll = false),
                  ),
                  ChoiceChip(
                    label: const Text('Show all'),
                    selected: _showAll,
                    onSelected: (_) => setState(() => _showAll = true),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/trading-hub/arc-raiders/raid-planner'),
                    child: const Text('RAID PLANNER'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/trading-hub/arc-raiders/market'),
                    child: const Text('COMMUNITY INTEL'),
                  ),
                ],
              ),
              Text(
                _showAll || widget.relevance.showEverything
                    ? 'All events in time order. Times are local.'
                    : 'Active first, then goal relevance. Unmatched events remain available.',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const Text(
                'Community reports are separate from schedule and official conditions.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  labelText: 'Find event or map',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              _regionalSection(),
              const SizedBox(height: 12),
            ],
            Text(
              widget.compact
                  ? 'MetaForge seed · 27 Apr 2026 · Not live verified'
                  : 'STANDARD SCHEDULE · MetaForge baseline · 27 Apr 2026 · Not live verified',
              style: const TextStyle(fontSize: 11, color: Colors.amber),
            ),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.slots.isEmpty
                      ? 'No standard schedule available.'
                      : 'No events match this search.',
                ),
              ),
            if (widget.compact) ...[
              for (final event in events) _event(event),
            ] else ...[
              _heading('ACTIVE / CURRENT'),
              if (!events.any((event) => event.isActive(_now)))
                const Text('No active standard events.'),
              for (final event in events.where((event) => event.isActive(_now)))
                _event(event),
              _heading('UPCOMING · NEXT 24 HOURS'),
              for (final event in events.where(
                (event) => !event.isActive(_now),
              ))
                _event(event),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
    ),
  );

  Widget _event(ArcEventMatch event) => Container(
    key: ValueKey(
      'event-${event.slot.mapName}-${event.slot.eventName}-${event.startUtc}',
    ),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${event.isActive(_now) ? 'ACTIVE' : 'NEXT'} · ${event.slot.eventName} · ${event.slot.mapName}',
          maxLines: widget.compact ? 2 : null,
          overflow: widget.compact ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_time(event.startUtc)} – ${_time(event.endUtc)}',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Text(
          event.reason,
          maxLines: widget.compact ? 2 : null,
          overflow: widget.compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 12,
            color: event.score > 0 ? AppTheme.neonCyan : Colors.white60,
          ),
        ),
      ],
    ),
  );

  Widget _regionalSection() {
    final snapshot = _conditions;
    final stale =
        snapshot != null &&
        (_failed ||
            !snapshot.isOfficialLive ||
            _now.difference(snapshot.loadedAtUtc) >
                const Duration(minutes: 10));
    final entries =
        snapshot?.entries.where((entry) {
          final window = entry.windowFor(_region);
          return window != null &&
              window.endUtc.isAfter(_now) &&
              '${entry.conditionName} ${entry.mapDisplayName}'
                  .toLowerCase()
                  .contains(_query.toLowerCase());
        }).toList() ??
        [];
    entries.sort((a, b) {
      final aw = a.windowFor(_region)!;
      final bw = b.windowFor(_region)!;
      if (aw.isActiveAt(_now) != bw.isActiveAt(_now)) {
        return aw.isActiveAt(_now) ? -1 : 1;
      }
      if (!_showAll && !widget.relevance.showEverything) {
        int score(ArcRegionalMapConditionEntry item) => widget.relevance
            .reasonsFor(item.conditionName, item.mapDisplayName)
            .values
            .fold(0, (a, b) => a > b ? a : b);
        final relevance = score(b).compareTo(score(a));
        if (relevance != 0) return relevance;
      }
      return aw.startUtc.compareTo(bw.startUtc);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('OFFICIAL REGIONAL CONDITIONS'),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButton<ArcServerRegion>(
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                value: _region,
                items: [
                  for (final region in ArcServerRegion.values)
                    DropdownMenuItem(value: region, child: Text(region.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _region = value);
                },
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _refresh,
              child: const Text('REFRESH CONDITIONS'),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_failed)
          Text(
            snapshot == null
                ? 'Official source unavailable. Retry conditions.'
                : 'Official refresh failed. Retained / captured data may be stale.',
            style: const TextStyle(color: Colors.amber),
          ),
        if (snapshot != null)
          Text(
            '${snapshot.sourceLabel} · ${stale ? 'STALE' : 'Loaded'} · ${_time(snapshot.loadedAtUtc)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        if (!_loading && snapshot != null && entries.isEmpty)
          Text(
            stale
                ? 'No unexpired conditions in retained data.'
                : 'No current or upcoming conditions for this region / search.',
          ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.windowFor(_region)!.isActiveAt(_now) ? 'CURRENT' : 'UPCOMING'}${stale ? ' · UNVERIFIED' : ''} · ${entry.conditionName} · ${entry.mapDisplayName}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_time(entry.windowFor(_region)!.startUtc)} – ${_time(entry.windowFor(_region)!.endUtc)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  _regionalReason(entry),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _regionalReason(ArcRegionalMapConditionEntry entry) {
    final reasons =
        widget.relevance
            .reasonsFor(entry.conditionName, entry.mapDisplayName)
            .entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return reasons.isEmpty
        ? 'No confirmed link to your goals'
        : reasons.first.key;
  }
}
