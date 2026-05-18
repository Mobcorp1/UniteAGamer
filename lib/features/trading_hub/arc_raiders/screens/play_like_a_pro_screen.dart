import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/play_like_a_pro_repository.dart';
import 'package:uag_traders_hub/widgets/dose_action_button.dart';
import 'package:uag_traders_hub/widgets/dose_section_card.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class PlayLikeAProScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/play-like-a-pro';

  const PlayLikeAProScreen({super.key});

  @override
  State<PlayLikeAProScreen> createState() => _PlayLikeAProScreenState();
}

class _PlayLikeAProScreenState extends State<PlayLikeAProScreen> {
  final PlayLikeAProRepository _repository = PlayLikeAProRepository();

  final TextEditingController _preferredGameController =
      TextEditingController();
  final TextEditingController _musicTriggerController = TextEditingController();
  final TextEditingController _preNotesController = TextEditingController();
  final TextEditingController _midNotesController = TextEditingController();
  final TextEditingController _postNotesController = TextEditingController();

  bool _hydrated = false;
  bool _savingPreferences = false;
  bool _savingPre = false;
  bool _savingMid = false;
  bool _savingPost = false;

  int _preferredSessionMinutes = 90;
  PlayLikeAProResetStyle _preferredResetStyle = PlayLikeAProResetStyle.hydrate;
  PlayLikeAProGoal _goal = PlayLikeAProGoal.blueprintFarm;

  int _energy = 3;
  int _focus = 3;
  int _calm = 3;
  int _confidence = 3;
  int _tiltRisk = 3;

  int _tiltLevel = 3;
  int _fatigue = 3;
  int _frustration = 3;
  int _focusDrop = 3;
  bool _needsBreak = false;

  int _performance = 3;
  int _enjoyment = 3;
  int _discipline = 3;
  int _tiltControl = 3;

  @override
  void initState() {
    super.initState();
    _repository.ensureDocExists();
  }

  @override
  void dispose() {
    _preferredGameController.dispose();
    _musicTriggerController.dispose();
    _preNotesController.dispose();
    _midNotesController.dispose();
    _postNotesController.dispose();
    super.dispose();
  }

  void _hydrateFromState(PlayLikeAProState state) {
    if (_hydrated) return;
    _preferredGameController.text = state.preferredGame;
    _musicTriggerController.text = state.musicTrigger;
    _preNotesController.text = state.preNotes;
    _midNotesController.text = state.midNotes;
    _postNotesController.text = state.postNotes;

    _preferredSessionMinutes = state.preferredSessionMinutes;
    _preferredResetStyle = state.preferredResetStyle;
    _goal = state.preGoal;
    _energy = state.preEnergy;
    _focus = state.preFocus;
    _calm = state.preCalm;
    _confidence = state.preConfidence;
    _tiltRisk = state.preTiltRisk;
    _tiltLevel = state.midTiltLevel;
    _fatigue = state.midFatigue;
    _frustration = state.midFrustration;
    _focusDrop = state.midFocusDrop;
    _needsBreak = state.midNeedsBreak;
    _performance = state.postPerformance;
    _enjoyment = state.postEnjoyment;
    _discipline = state.postDiscipline;
    _tiltControl = state.postTiltControl;
    _hydrated = true;
  }

  Future<void> _savePreferences() async {
    setState(() => _savingPreferences = true);
    try {
      await _repository.savePreferences(
        preferredGame: _preferredGameController.text,
        preferredSessionMinutes: _preferredSessionMinutes,
        preferredResetStyle: _preferredResetStyle,
        musicTrigger: _musicTriggerController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play Like a Pro preferences saved.')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPreferences = false);
      }
    }
  }

  Future<void> _savePreGame() async {
    setState(() => _savingPre = true);
    try {
      await _repository.savePreGame(
        goal: _goal,
        energy: _energy,
        focus: _focus,
        calm: _calm,
        confidence: _confidence,
        tiltRisk: _tiltRisk,
        notes: _preNotesController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pre-session check saved.')));
    } finally {
      if (mounted) {
        setState(() => _savingPre = false);
      }
    }
  }

  Future<void> _saveMidSession() async {
    setState(() => _savingMid = true);
    try {
      await _repository.saveMidSession(
        tiltLevel: _tiltLevel,
        fatigue: _fatigue,
        frustration: _frustration,
        focusDrop: _focusDrop,
        needsBreak: _needsBreak,
        notes: _midNotesController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tilt check saved.')));
    } finally {
      if (mounted) {
        setState(() => _savingMid = false);
      }
    }
  }

  Future<void> _savePostSession(PlayLikeAProState currentState) async {
    setState(() => _savingPost = true);
    try {
      await _repository.savePostSession(
        currentState: currentState.copyWith(
          preGoal: _goal,
          preEnergy: _energy,
          preFocus: _focus,
          preCalm: _calm,
          preConfidence: _confidence,
          preTiltRisk: _tiltRisk,
          midTiltLevel: _tiltLevel,
          midFatigue: _fatigue,
          midFrustration: _frustration,
          midFocusDrop: _focusDrop,
        ),
        performance: _performance,
        enjoyment: _enjoyment,
        discipline: _discipline,
        tiltControl: _tiltControl,
        notes: _postNotesController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post-session review saved.')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPost = false);
      }
    }
  }

  List<String> _buildPreRoutine() {
    final steps = <String>[];

    if (_energy <= 2) {
      steps.add('Go in lighter: water first, shorter run, no ego queueing.');
    }
    if (_focus <= 2 || _calm <= 2) {
      steps.add('Do a 60-second breathing reset before you load in.');
    }
    if (_confidence <= 2) {
      steps.add(
        'Start with one low-pressure warm-up raid before chasing value.',
      );
    }
    if (_tiltRisk >= 4) {
      steps.add(
        'Avoid pressure stacking. Skip arguments, lower the stakes, protect your head.',
      );
    }
    if (_musicTriggerController.text.trim().isNotEmpty) {
      steps.add('Use your trigger track to lock your pace before queueing.');
    }
    if (steps.isEmpty) {
      steps.add(
        'You are in a solid state. Hydrate, set a clear objective, and queue with intent.',
      );
    }
    return steps;
  }

  List<String> _buildMidRoutine() {
    final steps = <String>[];
    if (_tiltLevel >= 4 || _frustration >= 4) {
      steps.add(
        'Stop spiral queueing. Stand up, breathe, and reset before the next run.',
      );
    }
    if (_fatigue >= 4) {
      steps.add(
        'Fatigue is dragging decision speed. Take a short break or end on the next extraction.',
      );
    }
    if (_focusDrop >= 4) {
      steps.add(
        'Strip the plan back to one objective. Less multitasking, cleaner calls.',
      );
    }
    if (_needsBreak) {
      steps.add(
        'Take 3-5 minutes away from the screen. No "just one more" autopilot.',
      );
    }
    switch (_preferredResetStyle) {
      case PlayLikeAProResetStyle.breathing:
        steps.add(
          'Use your default reset: 4 slow breaths before the next queue.',
        );
        break;
      case PlayLikeAProResetStyle.hydrate:
        steps.add('Use your default reset: hydrate before the next run.');
        break;
      case PlayLikeAProResetStyle.music:
        steps.add(
          'Use your default reset: one music trigger before re-engaging.',
        );
        break;
      case PlayLikeAProResetStyle.shortBreak:
        steps.add(
          'Use your default reset: step off the game for a couple of minutes.',
        );
        break;
      case PlayLikeAProResetStyle.lowerPressure:
        steps.add(
          'Use your default reset: switch to a lower-pressure objective for one raid.',
        );
        break;
    }
    if (steps.isEmpty) {
      steps.add(
        'You look stable. Keep comms clean, stick to the plan, and don't overstay a good session.',
      );
    }
    return steps;
  }

  List<String> _buildInsightBullets(PlayLikeAProState state) {
    if (state.history.isEmpty) {
      return const <String>[
        'Run a few sessions through this flow and your patterns will start showing up here.',
        'The goal is simple: fewer tilt queues, cleaner prep, and more sessions you actually enjoy.',
      ];
    }

    double average(Iterable<int> values) {
      final list = values.toList(growable: false);
      if (list.isEmpty) return 0;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final history = state.history;
    final avgPerformance = average(history.map((entry) => entry.performance));
    final avgTiltControl = average(history.map((entry) => entry.tiltControl));
    final avgFocus = average(history.map((entry) => entry.focus));
    final avgEnergy = average(history.map((entry) => entry.energy));
    final rankedHistory = history.where(
      (entry) => entry.goal == PlayLikeAProGoal.rankedPush,
    );
    final farmingHistory = history.where(
      (entry) =>
          entry.goal == PlayLikeAProGoal.blueprintFarm ||
          entry.goal == PlayLikeAProGoal.resourceRun,
    );

    final bullets = <String>[
      'Across your last ${history.length} logged sessions, performance averages ${avgPerformance.toStringAsFixed(1)}/5 and tilt control averages ${avgTiltControl.toStringAsFixed(1)}/5.',
      'Your current baseline reads ${avgEnergy.toStringAsFixed(1)}/5 energy and ${avgFocus.toStringAsFixed(1)}/5 focus going in.',
    ];

    if (rankedHistory.isNotEmpty) {
      final rankedAvg = average(
        rankedHistory.map((entry) => entry.performance),
      );
      bullets.add(
        'Ranked-style sessions are averaging ${rankedAvg.toStringAsFixed(1)}/5 performance. Queue those when your head is clean, not when you are forcing it.',
      );
    }

    if (farmingHistory.isNotEmpty) {
      final farmEnjoyment = average(
        farmingHistory.map((entry) => entry.enjoyment),
      );
      bullets.add(
        'Farm and loot sessions are landing at ${farmEnjoyment.toStringAsFixed(1)}/5 enjoyment. That is your safer fallback when you want progress without pressure.',
      );
    }

    final latest = history.first;
    if (latest.energy <= 2 && latest.performance >= 4) {
      bullets.add(
        'One positive signal: you can still perform while tired when the plan is simple and disciplined.',
      );
    } else if (latest.tiltLevel >= 4 && latest.tiltControl <= 2) {
      bullets.add(
        'Latest session says your reset needs to happen earlier. Do not wait for full tilt before pulling out.',
      );
    }

    return bullets;
  }

  String _goalLabel(PlayLikeAProGoal goal) {
    switch (goal) {
      case PlayLikeAProGoal.rankedPush:
        return 'Ranked Push';
      case PlayLikeAProGoal.blueprintFarm:
        return 'Blueprint Farming';
      case PlayLikeAProGoal.resourceRun:
        return 'Resource Run';
      case PlayLikeAProGoal.chillLoot:
        return 'Chill Loot';
      case PlayLikeAProGoal.questsTrials:
        return 'Quests / Trials';
      case PlayLikeAProGoal.teamChemistry:
        return 'Team Chemistry';
    }
  }

  String _resetLabel(PlayLikeAProResetStyle style) {
    switch (style) {
      case PlayLikeAProResetStyle.breathing:
        return 'Breathing Reset';
      case PlayLikeAProResetStyle.hydrate:
        return 'Hydrate';
      case PlayLikeAProResetStyle.music:
        return 'Music Trigger';
      case PlayLikeAProResetStyle.shortBreak:
        return 'Short Break';
      case PlayLikeAProResetStyle.lowerPressure:
        return 'Lower Pressure';
    }
  }

  Widget _choiceWrap<T>({
    required T value,
    required List<T> values,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: AppTheme.spaceS,
      runSpacing: AppTheme.spaceS,
      children: values
          .map((option) {
            final selected = option == value;
            final chip = ChoiceChip(
              label: Text(label(option)),
              selected: selected,
              labelStyle: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: selected ? AppTheme.darkBackground : AppTheme.neonCyan,
                isBold: true,
              ),
              selectedColor: AppTheme.neonCyan,
              backgroundColor: AppTheme.cardBackgroundAlt,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? AppTheme.neonCyan
                      : AppTheme.neonCyan.withValues(alpha: 0.28),
                ),
              ),
              onSelected: (_) => setState(() => onChanged(option)),
            );

            return selected
                ? ElectricChargeBorder(active: true, radius: 999, child: chip)
                : chip;
          })
          .toList(growable: false),
    );
  }

  Widget _scorePicker({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String lowLabel = 'Low',
    String highLabel = 'High',
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.tradingSoftBorder,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceS,
                  vertical: 4,
                ),
                decoration: AppTheme.tradingPillDecoration(
                  color: AppTheme.neonPink,
                ),
                child: Text(
                  '$value / 5',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.neonPink,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$value',
            onChanged: (next) => setState(() => onChanged(next.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: const TextStyle(color: Colors.white54)),
              Text(highLabel, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routineCard({
    required String title,
    required IconData icon,
    required List<String> bullets,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: color.withValues(alpha: 0.32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.tradingHeading(fontSize: 18, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontSize: 18)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Play Like a Pro',
          style: AppTheme.neonTextStyle(
            fontSize: 25,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          StreamBuilder<PlayLikeAProState>(
            stream: _repository.watchState(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.spaceL),
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: Colors.redAccent.withValues(alpha: 0.30),
                    ),
                    child: Text(
                      'Could not load Play Like a Pro: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              final state = snapshot.data ?? PlayLikeAProState.initial();
              _hydrateFromState(state);

              final preRoutine = _buildPreRoutine();
              final midRoutine = _buildMidRoutine();
              final insights = _buildInsightBullets(state);
              final latestDate = state.history.isEmpty
                  ? null
                  : DateFormat(
                      'dd MMM • HH:mm',
                    ).format(state.history.first.createdAt);

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          decoration: AppTheme.tradingCardDecoration(
                            borderColor: AppTheme.neonCyan.withValues(
                              alpha: 0.26,
                            ),
                            radius: 22,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Esports-style session prep without the cringe.',
                                style: AppTheme.tradingHeading(
                                  fontSize: 22,
                                  color: AppTheme.neonCyan,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              const Text(
                                'Track how you feel before you queue, reset yourself when the session starts slipping, and log how you actually performed after the raid. The app then turns that into cleaner prep and fewer throwaway sessions.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              Wrap(
                                spacing: AppTheme.spaceS,
                                runSpacing: AppTheme.spaceS,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spaceM,
                                      vertical: AppTheme.spaceS,
                                    ),
                                    decoration: AppTheme.tradingPillDecoration(
                                      color: AppTheme.neonCyan,
                                    ),
                                    child: Text(
                                      'Goal: ${_goalLabel(_goal)}',
                                      style: AppTheme.bodyTextStyle(
                                        fontSize: 13,
                                        color: AppTheme.neonCyan,
                                        isBold: true,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spaceM,
                                      vertical: AppTheme.spaceS,
                                    ),
                                    decoration: AppTheme.tradingPillDecoration(
                                      color: AppTheme.neonPink,
                                    ),
                                    child: Text(
                                      'Default Reset: ${_resetLabel(_preferredResetStyle)}',
                                      style: AppTheme.bodyTextStyle(
                                        fontSize: 13,
                                        color: AppTheme.neonPink,
                                        isBold: true,
                                      ),
                                    ),
                                  ),
                                  if (latestDate != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceM,
                                        vertical: AppTheme.spaceS,
                                      ),
                                      decoration:
                                          AppTheme.tradingPillDecoration(
                                            color: AppTheme.tradingSuccess,
                                          ),
                                      child: Text(
                                        'Latest Review: $latestDate',
                                        style: AppTheme.bodyTextStyle(
                                          fontSize: 13,
                                          color: AppTheme.tradingSuccess,
                                          isBold: true,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        DoseSectionCard(
                          title: 'Setup & Personal Baseline',
                          icon: Icons.tune_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _preferredGameController,
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'Primary Game / Mode',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextField(
                                controller: _musicTriggerController,
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'Music Trigger (optional)',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Text(
                                'Preferred reset',
                                style: AppTheme.tradingHeading(fontSize: 18),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              _choiceWrap<PlayLikeAProResetStyle>(
                                value: _preferredResetStyle,
                                values: PlayLikeAProResetStyle.values,
                                label: _resetLabel,
                                onChanged: (value) =>
                                    _preferredResetStyle = value,
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Text(
                                'Target session length',
                                style: AppTheme.tradingHeading(fontSize: 18),
                              ),
                              Slider(
                                value: _preferredSessionMinutes.toDouble(),
                                min: 30,
                                max: 180,
                                divisions: 10,
                                label: '$_preferredSessionMinutes mins',
                                onChanged: (next) => setState(() {
                                  _preferredSessionMinutes = next.round();
                                }),
                              ),
                              Text(
                                '$_preferredSessionMinutes minutes',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: DoseActionButton(
                                  label: _savingPreferences
                                      ? 'Saving...'
                                      : 'Save Preferences',
                                  icon: Icons.save_outlined,
                                  onPressed: _savingPreferences
                                      ? null
                                      : _savePreferences,
                                  active: !_savingPreferences,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        DoseSectionCard(
                          title: 'Pre-Session Prep',
                          icon: Icons.bolt_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What are you queuing for?',
                                style: AppTheme.tradingHeading(fontSize: 18),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              _choiceWrap<PlayLikeAProGoal>(
                                value: _goal,
                                values: PlayLikeAProGoal.values,
                                label: _goalLabel,
                                onChanged: (value) => _goal = value,
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              _scorePicker(
                                label: 'Energy',
                                value: _energy,
                                onChanged: (value) => _energy = value,
                                lowLabel: 'Drained',
                                highLabel: 'Sharp',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Focus',
                                value: _focus,
                                onChanged: (value) => _focus = value,
                                lowLabel: 'Scattered',
                                highLabel: 'Locked in',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Calm',
                                value: _calm,
                                onChanged: (value) => _calm = value,
                                lowLabel: 'Wired',
                                highLabel: 'Settled',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Confidence',
                                value: _confidence,
                                onChanged: (value) => _confidence = value,
                                lowLabel: 'Shaky',
                                highLabel: 'Confident',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Tilt Risk',
                                value: _tiltRisk,
                                onChanged: (value) => _tiltRisk = value,
                                lowLabel: 'Steady',
                                highLabel: 'Likely to snap',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextField(
                                controller: _preNotesController,
                                maxLines: 3,
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'Pre-session notes',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              _routineCard(
                                title: 'Recommended Warm-Up',
                                icon: Icons.flag_rounded,
                                bullets: preRoutine,
                                color: AppTheme.neonCyan,
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              DoseActionButton(
                                label: _savingPre
                                    ? 'Saving...'
                                    : 'Save Pre-Session Check',
                                icon: Icons.playlist_add_check_circle_outlined,
                                onPressed: _savingPre ? null : _savePreGame,
                                active: !_savingPre,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        DoseSectionCard(
                          title: 'Mid-Session Reset',
                          icon: Icons.monitor_heart_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _scorePicker(
                                label: 'Tilt Level',
                                value: _tiltLevel,
                                onChanged: (value) => _tiltLevel = value,
                                lowLabel: 'Composed',
                                highLabel: 'Boiling',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Fatigue',
                                value: _fatigue,
                                onChanged: (value) => _fatigue = value,
                                lowLabel: 'Fresh',
                                highLabel: 'Spent',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Frustration',
                                value: _frustration,
                                onChanged: (value) => _frustration = value,
                                lowLabel: 'Fine',
                                highLabel: 'Irritated',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Focus Drop',
                                value: _focusDrop,
                                onChanged: (value) => _focusDrop = value,
                                lowLabel: 'Still dialled in',
                                highLabel: 'Autopilot',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _needsBreak,
                                onChanged: (value) =>
                                    setState(() => _needsBreak = value),
                                title: const Text(
                                  'I need a proper break before the next run.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Use this when you know you are forcing it.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextField(
                                controller: _midNotesController,
                                maxLines: 3,
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'What is going wrong?',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              _routineCard(
                                title: 'Reset Plan',
                                icon: Icons.health_and_safety_outlined,
                                bullets: midRoutine,
                                color: AppTheme.warningAmber,
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              DoseActionButton(
                                label: _savingMid
                                    ? 'Saving...'
                                    : 'Save Tilt Check',
                                icon: Icons.refresh_rounded,
                                onPressed: _savingMid ? null : _saveMidSession,
                                variant: DoseActionButtonVariant.secondary,
                                active: !_savingMid,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        DoseSectionCard(
                          title: 'Post-Session Review',
                          icon: Icons.analytics_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _scorePicker(
                                label: 'Performance',
                                value: _performance,
                                onChanged: (value) => _performance = value,
                                lowLabel: 'Poor',
                                highLabel: 'Strong',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Enjoyment',
                                value: _enjoyment,
                                onChanged: (value) => _enjoyment = value,
                                lowLabel: 'Drained',
                                highLabel: 'Buzzing',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Discipline',
                                value: _discipline,
                                onChanged: (value) => _discipline = value,
                                lowLabel: 'Messy',
                                highLabel: 'Controlled',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _scorePicker(
                                label: 'Tilt Control',
                                value: _tiltControl,
                                onChanged: (value) => _tiltControl = value,
                                lowLabel: 'Lost it',
                                highLabel: 'Handled it',
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextField(
                                controller: _postNotesController,
                                maxLines: 4,
                                decoration: AppTheme.tradingInputDecoration(
                                  label: 'Post-session notes',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              DoseActionButton(
                                label: _savingPost
                                    ? 'Saving...'
                                    : 'Save Session Review',
                                icon: Icons.done_all_rounded,
                                onPressed: _savingPost
                                    ? null
                                    : () => _savePostSession(state),
                                active: !_savingPost,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        DoseSectionCard(
                          title: 'Pattern Readout',
                          icon: Icons.insights_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...insights.map(
                                (bullet) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceM,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.fiber_manual_record,
                                          size: 12,
                                          color: AppTheme.neonPink,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                      Expanded(
                                        child: Text(
                                          bullet,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (state.history.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spaceS),
                                Text(
                                  'Recent Reviews',
                                  style: AppTheme.tradingHeading(fontSize: 18),
                                ),
                                const SizedBox(height: AppTheme.spaceS),
                                ...state.history.take(5).map((entry) {
                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: AppTheme.spaceS,
                                    ),
                                    padding: const EdgeInsets.all(
                                      AppTheme.spaceM,
                                    ),
                                    decoration: AppTheme.tradingCardDecoration(
                                      borderColor: AppTheme.tradingSoftBorder,
                                      radius: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${DateFormat('dd MMM').format(entry.createdAt)} • ${_goalLabel(entry.goal)}',
                                                style: AppTheme.bodyTextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.neonCyan,
                                                  isBold: true,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Perf ${entry.performance}/5 • Enjoyment ${entry.enjoyment}/5 • Tilt Control ${entry.tiltControl}/5',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

