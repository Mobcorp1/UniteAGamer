import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBetaFirstRunKeys {
  static const hasCompletedOnboarding = 'hasCompletedOnboarding';
  static const forceOnboarding = 'forceOnboarding';
  static const hasCompletedProfileSetup = 'hasCompletedProfileSetup';
  static const hasSeenBlueprintTutorial = 'hasSeenBlueprintTutorial';
  static const hasSeenTradingTutorial = 'hasSeenTradingTutorial';
}

class ArcBetaFirstRun {
  const ArcBetaFirstRun._();

  static Future<bool> hasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ArcBetaFirstRunKeys.hasCompletedOnboarding, false);
    await prefs.setBool(ArcBetaFirstRunKeys.forceOnboarding, true);
    await prefs.setBool(ArcBetaFirstRunKeys.hasCompletedProfileSetup, false);
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ArcBetaFirstRunKeys.hasCompletedOnboarding, true);
    await prefs.setBool(ArcBetaFirstRunKeys.forceOnboarding, false);
  }

  static Future<void> resetTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ArcBetaFirstRunKeys.hasSeenBlueprintTutorial, false);
    await prefs.setBool(ArcBetaFirstRunKeys.hasSeenTradingTutorial, false);
  }

  static Future<void> resetAllBetaProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ArcBetaFirstRunKeys.hasCompletedOnboarding, false);
    await prefs.setBool(ArcBetaFirstRunKeys.forceOnboarding, true);
    await prefs.setBool(ArcBetaFirstRunKeys.hasCompletedProfileSetup, false);
    await prefs.setBool(ArcBetaFirstRunKeys.hasSeenBlueprintTutorial, false);
    await prefs.setBool(ArcBetaFirstRunKeys.hasSeenTradingTutorial, false);
  }

  static Future<void> showOnce({
    required BuildContext context,
    required String key,
    required String title,
    required List<String> steps,
    required Color accent,
  }) async {
    if (await hasSeen(key)) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ArcFirstRunDialog(
        title: title,
        steps: steps,
        accent: accent,
        onDone: () async {
          await setFlag(key, true);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}

class ArcProfileCompletionTask {
  const ArcProfileCompletionTask({
    required this.label,
    required this.complete,
    required this.weight,
    required this.action,
  });

  final String label;
  final bool complete;
  final int weight;
  final String action;
}

class ArcProfileCompletionSummary {
  const ArcProfileCompletionSummary({
    required this.percent,
    required this.completed,
    required this.total,
    required this.tasks,
  });

  final int percent;
  final int completed;
  final int total;
  final List<ArcProfileCompletionTask> tasks;

  ArcProfileCompletionTask? get nextTask {
    for (final task in tasks) {
      if (!task.complete) return task;
    }
    return null;
  }

  String get strengthLabel {
    if (percent >= 90) return 'Elite';
    if (percent >= 70) return 'Strong';
    if (percent >= 40) return 'Good';
    return 'Weak';
  }

  static Future<ArcProfileCompletionSummary> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = <ArcProfileCompletionTask>[
      ArcProfileCompletionTask(
        label: 'Add display name',
        complete: (prefs.getString('displayName') ?? '').trim().isNotEmpty,
        weight: 10,
        action: 'Finish your basic profile',
      ),
      ArcProfileCompletionTask(
        label: 'Add region',
        complete: (prefs.getString('region') ?? '').trim().isNotEmpty,
        weight: 15,
        action: 'Add your region for better squad and trade matching',
      ),
      ArcProfileCompletionTask(
        label: 'Add platforms',
        complete:
            (prefs.getStringList('platforms') ?? const <String>[]).isNotEmpty,
        weight: 15,
        action: 'Choose your gaming platforms',
      ),
      ArcProfileCompletionTask(
        label: 'Add communication style',
        complete: (prefs.getString('communicationStyle') ?? '')
            .trim()
            .isNotEmpty,
        weight: 15,
        action: 'Set voice, text, pings or no preference',
      ),
      ArcProfileCompletionTask(
        label: 'Add playstyles',
        complete:
            (prefs.getStringList('playstyles') ?? const <String>[]).isNotEmpty,
        weight: 15,
        action: 'Pick the kind of raider you are',
      ),
      ArcProfileCompletionTask(
        label: 'Add Top 5 blueprints',
        complete:
            (prefs.getStringList('topFiveBlueprints') ?? const <String>[])
                .length >=
            5,
        weight: 15,
        action: 'Choose your Top 5 wanted blueprints',
      ),
      ArcProfileCompletionTask(
        label: 'Create first listing',
        complete: prefs.getBool('hasCreatedFirstTradeListing') ?? false,
        weight: 10,
        action: 'Create your first duplicate-for-wanted trade listing',
      ),
      ArcProfileCompletionTask(
        label: 'Save favourite loadout',
        complete: prefs.getBool('hasSavedFavouriteLoadout') ?? false,
        weight: 5,
        action: 'Save one personal go-to ARC loadout',
      ),
    ];

    final completed = tasks.where((task) => task.complete).length;
    final totalWeight = tasks.fold<int>(0, (sum, task) => sum + task.weight);
    final completeWeight = tasks
        .where((task) => task.complete)
        .fold<int>(0, (sum, task) => sum + task.weight);
    final percent = totalWeight == 0
        ? 0
        : ((completeWeight / totalWeight) * 100).round();

    return ArcProfileCompletionSummary(
      percent: percent,
      completed: completed,
      total: tasks.length,
      tasks: tasks,
    );
  }
}

class ArcProfileCompletionCard extends StatefulWidget {
  const ArcProfileCompletionCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<ArcProfileCompletionCard> createState() =>
      _ArcProfileCompletionCardState();
}

class _ArcProfileCompletionCardState extends State<ArcProfileCompletionCard> {
  ArcProfileCompletionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ArcProfileCompletionSummary.load();
    if (mounted) setState(() => _summary = value);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();
    final nextTask = summary.nextTask;
    final visibleTasks = summary.tasks
        .take(widget.compact ? 4 : summary.tasks.length)
        .toList();

    return Container(
      padding: EdgeInsets.all(widget.compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.tradingCardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppTheme.neonCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete Your Profile',
                  style: AppTheme.tradingHeading(
                    fontSize: widget.compact ? 15 : 18,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              Text(
                '${summary.percent}%',
                style: AppTheme.tradingHeading(
                  fontSize: 18,
                  color: AppTheme.neonPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.percent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile Strength: ${summary.strengthLabel} • ${summary.completed}/${summary.total} essentials complete',
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white70),
          ),
          if (nextTask != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.neonPink,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next: ${nextTask.action}',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        isBold: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final task in visibleTasks) _CompletionChip(task: task),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  const _CompletionChip({required this.task});

  final ArcProfileCompletionTask task;

  @override
  Widget build(BuildContext context) {
    final color = task.complete ? AppTheme.neonCyan : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: task.complete ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: task.complete ? 0.42 : 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task.complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            task.label,
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: color,
              isBold: task.complete,
            ),
          ),
        ],
      ),
    );
  }
}

class ArcBetaDeveloperToolsCard extends StatefulWidget {
  const ArcBetaDeveloperToolsCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<ArcBetaDeveloperToolsCard> createState() =>
      _ArcBetaDeveloperToolsCardState();
}

class _ArcBetaDeveloperToolsCardState extends State<ArcBetaDeveloperToolsCard> {
  bool _busy = false;

  Future<void> _run(String message, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.darkBackground.withValues(alpha: 0.96),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_ArcBetaDevAction>[
      _ArcBetaDevAction(
        label: 'Reset onboarding',
        icon: Icons.restart_alt_rounded,
        onTap: () => _run(
          'Onboarding reset. Relaunch or return to onboarding to test.',
          ArcBetaFirstRun.resetOnboarding,
        ),
      ),
      _ArcBetaDevAction(
        label: 'Complete onboarding',
        icon: Icons.check_circle_outline_rounded,
        onTap: () => _run(
          'Onboarding marked complete.',
          ArcBetaFirstRun.markOnboardingComplete,
        ),
      ),
      _ArcBetaDevAction(
        label: 'Replay Blueprint guide',
        icon: Icons.grid_view_rounded,
        onTap: () => _run(
          'Blueprint tutorial will replay on next Blueprint Tracker visit.',
          () => ArcBetaFirstRun.setFlag(
            ArcBetaFirstRunKeys.hasSeenBlueprintTutorial,
            false,
          ),
        ),
      ),
      _ArcBetaDevAction(
        label: 'Replay Trading guide',
        icon: Icons.swap_horiz_rounded,
        onTap: () => _run(
          'Trading tutorial will replay on next Trading visit.',
          () => ArcBetaFirstRun.setFlag(
            ArcBetaFirstRunKeys.hasSeenTradingTutorial,
            false,
          ),
        ),
      ),
      _ArcBetaDevAction(
        label: 'Replay all tutorials',
        icon: Icons.replay_circle_filled_rounded,
        onTap: () => _run(
          'All tutorials reset for closed beta testing.',
          ArcBetaFirstRun.resetTutorials,
        ),
      ),
      _ArcBetaDevAction(
        label: 'Reset beta progress',
        icon: Icons.warning_amber_rounded,
        onTap: () => _run(
          'Closed beta progress reset.',
          ArcBetaFirstRun.resetAllBetaProgress,
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.tradingCardBackground.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPink.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.developer_mode_rounded,
                size: widget.compact ? 17 : 20,
                color: AppTheme.neonPink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Closed Beta Tools',
                  style: AppTheme.tradingHeading(
                    fontSize: widget.compact ? 14 : 17,
                    color: AppTheme.neonPink,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reset onboarding, replay tutorials and test first-run flows without reinstalling.',
            style: AppTheme.bodyTextStyle(
              fontSize: widget.compact ? 10 : 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                _ArcBetaDevChip(action: action, disabled: _busy),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcBetaDevAction {
  const _ArcBetaDevAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ArcBetaDevChip extends StatelessWidget {
  const _ArcBetaDevChip({required this.action, required this.disabled});

  final _ArcBetaDevAction action;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: disabled ? null : action.onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.neonPink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.neonPink.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: AppTheme.neonPink, size: 14),
              const SizedBox(width: 5),
              Text(
                action.label,
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.86),
                  isBold: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcFirstRunDialog extends StatelessWidget {
  const _ArcFirstRunDialog({
    required this.title,
    required this.steps,
    required this.accent,
    required this.onDone,
  });

  final String title;
  final List<String> steps;
  final Color accent;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.tradingHeading(fontSize: 23, color: accent),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 13,
                        color: accent,
                        isBold: true,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: AppTheme.bodyTextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDone, child: const Text('Skip')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onDone, child: const Text('Show Me')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
