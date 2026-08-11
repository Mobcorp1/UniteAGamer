import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_mixtape_library.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_routine_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_mixtape.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_routine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_mixtape_player_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class PlayLikeAProRoutineScreen extends StatefulWidget {
  const PlayLikeAProRoutineScreen({super.key, this.onOpenSessionCoach});

  final VoidCallback? onOpenSessionCoach;

  @override
  State<PlayLikeAProRoutineScreen> createState() =>
      _PlayLikeAProRoutineScreenState();
}

class _PlayLikeAProRoutineScreenState extends State<PlayLikeAProRoutineScreen> {
  final PlayLikeAProRoutineEngine _engine = const PlayLikeAProRoutineEngine();
  final Set<String> _completed = <String>{};

  late DateTime _sessionStart;
  int _targetMinutes = 90;
  int _energy = 3;
  double _sleepHours = 7;
  bool _hydrated = false;
  bool _ateRecently = false;
  bool _mechanicalWarmup = true;
  PlayLikeAProPerformanceState _state = PlayLikeAProPerformanceState.ready;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _sessionStart = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  PlayLikeAProRoutinePlan get _plan => _engine.build(
    PlayLikeAProRoutineInputs(
      sessionStart: _sessionStart,
      targetSessionMinutes: _targetMinutes,
      performanceState: _state,
      energy: _energy,
      hydrated: _hydrated,
      ateRecently: _ateRecently,
      sleepHours: _sleepHours,
      mechanicalWarmup: _mechanicalWarmup,
    ),
  );

  Future<void> _pickStart() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sessionStart),
    );
    if (selected == null || !mounted) return;
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      selected.hour,
      selected.minute,
    );
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    setState(() => _sessionStart = next);
  }

  void _openMixtape(String id) {
    final mix = PlayLikeAProMixtapeLibrary.byId(id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayLikeAProMixtapePlayerScreen(mixtape: mix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final preMix = PlayLikeAProMixtapeLibrary.byId(plan.preGameMixtapeId);
    return ArcRaidersPageScaffold(
      maxWidth: 1180,
      child: ListView(
        children: [
          _hero(preMix),
          const SizedBox(height: AppTheme.spaceM),
          _setupCard(),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'YOUR PRO ROUTINE',
            style: AppTheme.tradingHeading(fontSize: 24),
          ),
          const SizedBox(height: AppTheme.spaceS),
          const Text(
            'Prepare deliberately, play inside a planned window, then come back down instead of carrying the session into the rest of the day.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...PlayLikeAProRoutinePhase.values.map((phase) {
            final tasks = plan.forPhase(phase);
            if (tasks.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
              child: _phaseCard(phase, tasks),
            );
          }),
          const SizedBox(height: AppTheme.spaceL),
          _mixtapes(plan),
          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _hero(PlayLikeAProMixtape preMix) {
    final completed = _completed.length;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.34),
        radius: 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAY LIKE A PRO',
                style: AppTheme.tradingHeading(
                  fontSize: 30,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'PREPARE • PERFORM • RECOVER',
                style: AppTheme.tradingHeading(
                  fontSize: 17,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Build the kind of repeatable pre-game and post-game routine used around serious performance: readiness, hydration, food, movement, warm-up, focus cues, session discipline and recovery.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  _pill(
                    'START ${DateFormat('HH:mm').format(_sessionStart)}',
                    AppTheme.neonCyan,
                  ),
                  _pill('$_targetMinutes MIN', AppTheme.neonPink),
                  _pill('$completed DONE', AppTheme.tradingSuccess),
                ],
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: () => _openMixtape(preMix.id),
            icon: const Icon(Icons.headphones_rounded),
            label: Text('Start ${preMix.title}'),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppTheme.spaceL),
                action,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppTheme.spaceL),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _setupCard() => Container(
    padding: const EdgeInsets.all(AppTheme.spaceL),
    decoration: AppTheme.tradingCardDecoration(
      borderColor: AppTheme.tradingSoftBorder,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUILD TODAY\'S ROUTINE',
          style: AppTheme.tradingHeading(fontSize: 21),
        ),
        const SizedBox(height: AppTheme.spaceM),
        Wrap(
          spacing: AppTheme.spaceS,
          runSpacing: AppTheme.spaceS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Start ${DateFormat('HH:mm').format(_sessionStart)}'),
            ),
            for (final state in PlayLikeAProPerformanceState.values)
              ChoiceChip(
                label: Text(state.label),
                selected: _state == state,
                onSelected: (_) => setState(() => _state = state),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        Text(
          'Target session: $_targetMinutes minutes',
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: _targetMinutes.toDouble(),
          min: 30,
          max: 180,
          divisions: 10,
          label: '$_targetMinutes min',
          onChanged: (value) => setState(() => _targetMinutes = value.round()),
        ),
        Text(
          'Energy: $_energy / 5',
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: _energy.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_energy',
          onChanged: (value) => setState(() => _energy = value.round()),
        ),
        Text(
          'Sleep: ${_sleepHours.toStringAsFixed(1)} hours',
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: _sleepHours,
          min: 4,
          max: 10,
          divisions: 12,
          label: _sleepHours.toStringAsFixed(1),
          onChanged: (value) => setState(() => _sleepHours = value),
        ),
        Wrap(
          spacing: AppTheme.spaceS,
          runSpacing: AppTheme.spaceS,
          children: [
            FilterChip(
              avatar: const Icon(Icons.water_drop_outlined, size: 18),
              label: const Text('Already hydrated'),
              selected: _hydrated,
              onSelected: (value) => setState(() => _hydrated = value),
            ),
            FilterChip(
              avatar: const Icon(Icons.restaurant_rounded, size: 18),
              label: const Text('Eaten recently'),
              selected: _ateRecently,
              onSelected: (value) => setState(() => _ateRecently = value),
            ),
            FilterChip(
              avatar: const Icon(Icons.sports_esports_rounded, size: 18),
              label: const Text('Mechanical warm-up'),
              selected: _mechanicalWarmup,
              onSelected: (value) => setState(() => _mechanicalWarmup = value),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _phaseCard(
    PlayLikeAProRoutinePhase phase,
    List<PlayLikeAProRoutineTask> tasks,
  ) => Container(
    padding: const EdgeInsets.all(AppTheme.spaceM),
    decoration: AppTheme.tradingCardDecoration(
      borderColor: phase == PlayLikeAProRoutinePhase.recovery
          ? AppTheme.neonPink.withValues(alpha: 0.25)
          : AppTheme.neonCyan.withValues(alpha: 0.22),
      radius: 18,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(phase.icon, color: AppTheme.neonCyan),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                phase.label.toUpperCase(),
                style: AppTheme.tradingHeading(fontSize: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceS),
        ...tasks.map(_taskTile),
      ],
    ),
  );

  Widget _taskTile(PlayLikeAProRoutineTask task) {
    final done = _completed.contains(task.id);
    final timeLabel = task.minutesBeforeStart > 0
        ? 'T-${task.minutesBeforeStart}'
        : task.minutesBeforeStart == 0
        ? 'IN SESSION'
        : 'POST';
    return CheckboxListTile(
      value: done,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) => setState(() {
        if (value == true) {
          _completed.add(task.id);
        } else {
          _completed.remove(task.id);
        }
      }),
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.emphasis ? AppTheme.warningAmber : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            timeLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.detail,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
            if (task.mixtapeId != null) ...[
              const SizedBox(height: AppTheme.spaceS),
              TextButton.icon(
                onPressed: () => _openMixtape(task.mixtapeId!),
                icon: const Icon(Icons.headphones_rounded),
                label: Text(
                  'Open ${PlayLikeAProMixtapeLibrary.byId(task.mixtapeId!).title}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mixtapes(PlayLikeAProRoutinePlan plan) => Container(
    padding: const EdgeInsets.all(AppTheme.spaceL),
    decoration: AppTheme.tradingCardDecoration(
      borderColor: AppTheme.neonPink.withValues(alpha: 0.28),
      radius: 22,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.album_rounded, color: AppTheme.neonPink),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                'UAG MIXTAPES',
                style: AppTheme.tradingHeading(
                  fontSize: 22,
                  color: AppTheme.neonPink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceS),
        const Text(
          'Use music as a deliberate performance cue: activate, focus, reset or come down after the session.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: AppTheme.spaceM),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900
                ? (constraints.maxWidth - AppTheme.spaceM * 2) / 3
                : constraints.maxWidth >= 600
                ? (constraints.maxWidth - AppTheme.spaceM) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppTheme.spaceM,
              runSpacing: AppTheme.spaceM,
              children: PlayLikeAProMixtapeLibrary.mixtapes
                  .map((mix) {
                    final recommended =
                        mix.id == plan.preGameMixtapeId ||
                        mix.id == plan.recoveryMixtapeId;
                    return SizedBox(
                      width: width,
                      child: _mixtapeCard(mix, recommended: recommended),
                    );
                  })
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceM),
        OutlinedButton.icon(
          onPressed: widget.onOpenSessionCoach,
          icon: const Icon(Icons.insights_rounded),
          label: const Text('Open Session Coach & History'),
        ),
      ],
    ),
  );

  Widget _mixtapeCard(PlayLikeAProMixtape mix, {required bool recommended}) =>
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openMixtape(mix.id),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          decoration: AppTheme.tradingCardDecoration(
            borderColor: recommended
                ? AppTheme.neonCyan.withValues(alpha: 0.55)
                : AppTheme.tradingSoftBorder,
            radius: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonPink),
                ),
                child: Icon(mix.icon, color: AppTheme.neonCyan),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mix.purpose,
                      style: const TextStyle(
                        color: AppTheme.neonPink,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mix.subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline_rounded,
                color: AppTheme.neonCyan,
              ),
            ],
          ),
        ),
      );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: AppTheme.tradingPillDecoration(color: color),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
