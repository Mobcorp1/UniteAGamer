import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_position_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';

typedef ArcQuestTrackedChanged = Future<void> Function(Set<String> questIds);
typedef ArcQuestComplete = Future<bool> Function(String questId);

class ArcQuestTrackerWorkspace extends StatefulWidget {
  const ArcQuestTrackerWorkspace({
    super.key,
    required this.snapshot,
    required this.onJustStarting,
    required this.onTrackedChanged,
    required this.onCompleteQuest,
  });

  final ArcQuestProgressionSnapshot snapshot;
  final Future<void> Function() onJustStarting;
  final ArcQuestTrackedChanged onTrackedChanged;
  final ArcQuestComplete onCompleteQuest;

  @override
  State<ArcQuestTrackerWorkspace> createState() =>
      _ArcQuestTrackerWorkspaceState();
}

class _ArcQuestTrackerWorkspaceState extends State<ArcQuestTrackerWorkspace> {
  static const _engine = ArcQuestPositionEngine();
  final TextEditingController _searchController = TextEditingController();

  bool _showFinder = false;
  bool _showCompleted = false;
  bool _showFullTree = false;
  bool _busy = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, ArcQuestProgressionEntry> get _entries =>
      <String, ArcQuestProgressionEntry>{
        for (final entry in widget.snapshot.entries) entry.questId: entry,
      };

  Set<String> get _tracked => widget.snapshot.trackedQuestIds
      .where((id) => !widget.snapshot.completedQuestIds.contains(id))
      .toSet();

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleTracked(String questId) async {
    final next = Set<String>.from(_tracked);
    if (!next.add(questId)) {
      next.remove(questId);
    }
    await _run(() => widget.onTrackedChanged(next));
  }

  Future<void> _complete(String questId) async {
    await _run(() async {
      await widget.onCompleteQuest(questId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.snapshot.completedQuestIds;
    final tracked = _tracked;
    final available = _engine.availableQuestIds(completed)
      ..removeAll(tracked)
      ..removeAll(completed);
    final comingNext = _engine.comingNextQuestIds(
      trackedQuestIds: tracked,
      completedQuestIds: completed,
    )..removeAll(available);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSetupPanel(context, tracked),
        const SizedBox(height: 10),
        _buildRecommendationPanel(context),
        const SizedBox(height: 12),
        _section(
          context,
          title: 'TRACKING',
          subtitle: tracked.isEmpty
              ? 'Choose the quests currently on your in-game board.'
              : '${tracked.length} current quest${tracked.length == 1 ? '' : 's'}',
          accent: Colors.cyanAccent,
          child: tracked.isEmpty
              ? _emptyCopy('No current quests selected.')
              : _questList(
                  context,
                  _engine.ordered(tracked),
                  tracked: tracked,
                  showComplete: true,
                ),
        ),
        const SizedBox(height: 10),
        _section(
          context,
          title: 'AVAILABLE NOW',
          subtitle: 'Unlocked from confirmed prerequisite progress.',
          accent: Colors.lightGreenAccent,
          child: available.isEmpty
              ? _emptyCopy('No additional verified unlocks right now.')
              : _questList(
                  context,
                  _engine.ordered(available),
                  tracked: tracked,
                  allowTrack: true,
                ),
        ),
        const SizedBox(height: 10),
        _section(
          context,
          title: 'COMING NEXT',
          subtitle: 'Immediate children of the quests you are tracking.',
          accent: Colors.amberAccent,
          child: comingNext.isEmpty
              ? _emptyCopy(
                  'No immediate next quest is known from the current board.',
                )
              : _questList(
                  context,
                  _engine.ordered(comingNext),
                  tracked: tracked,
                ),
        ),
        const SizedBox(height: 10),
        _buildCompletedSection(context, completed, tracked),
        const SizedBox(height: 10),
        _buildFullTree(context, tracked, completed),
      ],
    );
  }

  Widget _buildSetupPanel(BuildContext context, Set<String> tracked) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(Colors.cyanAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('QUEST POSITION', style: _headingStyle(Colors.cyanAccent)),
          const SizedBox(height: 5),
          Text(
            tracked.isEmpty
                ? 'Tell UAG where you are in the live quest graph.'
                : 'Your current board drives quest availability, raid recommendations and Match Raider alignment.',
            style: const TextStyle(color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _run(widget.onJustStarting),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('I AM JUST STARTING'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() => _showFinder = !_showFinder),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('FIND MY CURRENT QUEST'),
              ),
            ],
          ),
          if (_showFinder) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search quest, trader or map',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final node in _engine.search(_query).take(25))
                    _finderRow(context, node, tracked.contains(node.id)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _finderRow(
    BuildContext context,
    ArcQuestCatalogueNode node,
    bool selected,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(node.displayName),
      subtitle: Text(
        [
          node.trader,
          if (node.mapNames.isNotEmpty) node.mapNames.join(', '),
        ].join(' • '),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent)
          : const Icon(Icons.add_circle_outline_rounded),
      onTap: _busy ? null : () => _toggleTracked(node.id),
    );
  }

  Widget _buildRecommendationPanel(BuildContext context) {
    final goals = ArcRaiderGoalBridge.questGoals(widget.snapshot);
    final recommendations = const ArcRaidRecommendationEngine().build(
      goals: goals,
      candidates: ArcRaiderGoalBridge.scheduleCandidates(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(Colors.pinkAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RAID RECOMMENDATION', style: _headingStyle(Colors.pinkAccent)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = <Widget>[
                _recommendationCard('BEST RAID NOW', recommendations.bestNow),
                _recommendationCard(
                  'BEST STANDARD MAP',
                  recommendations.bestStandard,
                ),
                _recommendationCard(
                  'BEST UPCOMING',
                  recommendations.bestUpcoming,
                ),
              ];
              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: cards[index]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    cards[index],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recommendationCard(
    String label,
    ArcRaidRecommendation? recommendation,
  ) {
    if (recommendation == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: _subPanelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _headingStyle(Colors.white54, size: 11)),
            const SizedBox(height: 5),
            const Text(
              'No verified route yet',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    final candidate = recommendation.candidate;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _subPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _headingStyle(Colors.pinkAccent, size: 11)),
          const SizedBox(height: 5),
          Text(
            candidate.mapName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          if (candidate.conditionName.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              candidate.conditionName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (recommendation.reasons.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              recommendation.reasons.first,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedSection(
    BuildContext context,
    Set<String> completed,
    Set<String> tracked,
  ) {
    return _section(
      context,
      title: 'COMPLETED',
      subtitle:
          '${completed.length} confirmed quest${completed.length == 1 ? '' : 's'}',
      accent: Colors.greenAccent,
      trailing: IconButton(
        tooltip: _showCompleted ? 'Collapse completed' : 'Show completed',
        onPressed: () => setState(() => _showCompleted = !_showCompleted),
        icon: Icon(
          _showCompleted
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          color: Colors.greenAccent,
        ),
      ),
      child: !_showCompleted
          ? _emptyCopy('Collapsed.')
          : completed.isEmpty
          ? _emptyCopy('No quests confirmed complete yet.')
          : _questList(
              context,
              _engine.ordered(completed),
              tracked: tracked,
              completed: true,
            ),
    );
  }

  Widget _buildFullTree(
    BuildContext context,
    Set<String> tracked,
    Set<String> completed,
  ) {
    return _section(
      context,
      title: 'VIEW FULL QUEST TREE',
      subtitle:
          '${ArcQuestCatalogue.nodes.length} Riven Tides quest nodes • ${ArcQuestCatalogue.version}',
      accent: Colors.white54,
      trailing: IconButton(
        tooltip: _showFullTree ? 'Hide full tree' : 'Show full tree',
        onPressed: () => setState(() => _showFullTree = !_showFullTree),
        icon: Icon(
          _showFullTree
              ? Icons.expand_less_rounded
              : Icons.account_tree_outlined,
          color: Colors.white70,
        ),
      ),
      child: !_showFullTree
          ? _emptyCopy('Full dependency tree hidden.')
          : Column(
              children: [
                for (final node in ArcQuestCatalogue.nodes)
                  _fullTreeRow(node, tracked, completed),
              ],
            ),
    );
  }

  Widget _fullTreeRow(
    ArcQuestCatalogueNode node,
    Set<String> tracked,
    Set<String> completed,
  ) {
    final isTracked = tracked.contains(node.id);
    final isCompleted = completed.contains(node.id);
    final color = isCompleted
        ? Colors.greenAccent
        : isTracked
        ? Colors.cyanAccent
        : Colors.white54;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 30,
        child: Text(
          '${node.canonicalOrder}',
          textAlign: TextAlign.right,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ),
      title: Text(
        node.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${node.trader}${node.mapNames.isEmpty ? '' : ' • ${node.mapNames.join(', ')}'}',
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      trailing: node.prerequisitePolicy == ArcQuestPrerequisitePolicy.unverified
          ? const Tooltip(
              message: 'Prerequisite relationship is unverified',
              child: Icon(
                Icons.help_outline_rounded,
                color: Colors.amberAccent,
                size: 18,
              ),
            )
          : null,
    );
  }

  Widget _questList(
    BuildContext context,
    List<ArcQuestCatalogueNode> nodes, {
    required Set<String> tracked,
    bool allowTrack = false,
    bool showComplete = false,
    bool completed = false,
  }) {
    return Column(
      children: [
        for (final node in nodes)
          _questCard(
            context,
            node,
            tracked: tracked,
            allowTrack: allowTrack,
            showComplete: showComplete,
            completed: completed,
          ),
      ],
    );
  }

  Widget _questCard(
    BuildContext context,
    ArcQuestCatalogueNode node, {
    required Set<String> tracked,
    required bool allowTrack,
    required bool showComplete,
    required bool completed,
  }) {
    final entry = _entries[node.id];
    final objectives = entry?.objectives ?? const <ArcProgressionObjective>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: _subPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        node.trader,
                        if (node.mapNames.isNotEmpty) node.mapNames.join(', '),
                        if (node.contentUpdate != 'Core') node.contentUpdate,
                      ].join(' • '),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (allowTrack)
                TextButton(
                  onPressed: _busy ? null : () => _toggleTracked(node.id),
                  child: const Text('TRACK'),
                ),
              if (showComplete)
                TextButton(
                  onPressed: _busy ? null : () => _complete(node.id),
                  child: const Text('COMPLETED IN GAME'),
                ),
              if (tracked.contains(node.id) && !showComplete)
                TextButton(
                  onPressed: _busy ? null : () => _toggleTracked(node.id),
                  child: const Text('REMOVE'),
                ),
              if (completed)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 19,
                ),
            ],
          ),
          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 7),
            for (final objective in objectives)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      objective.complete
                          ? Icons.check_circle_outline_rounded
                          : Icons.inventory_2_outlined,
                      size: 15,
                      color: objective.complete
                          ? Colors.greenAccent
                          : Colors.amberAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        objective.progressLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: _headingStyle(accent))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }

  Widget _emptyCopy(String text) =>
      Text(text, style: const TextStyle(color: Colors.white54, height: 1.3));

  BoxDecoration _panelDecoration(Color accent) => BoxDecoration(
    color: const Color(0xD910161D),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: accent.withValues(alpha: 0.28)),
    boxShadow: [
      BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 18),
    ],
  );

  BoxDecoration _subPanelDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
  );

  TextStyle _headingStyle(Color color, {double size = 12}) => TextStyle(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.7,
  );
}
