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

class ArcProfileCompletionSummary {
  const ArcProfileCompletionSummary({
    required this.percent,
    required this.completed,
    required this.total,
  });

  final int percent;
  final int completed;
  final int total;

  static Future<ArcProfileCompletionSummary> load() async {
    final prefs = await SharedPreferences.getInstance();
    final checks = <bool>[
      (prefs.getString('displayName') ?? '').trim().isNotEmpty,
      (prefs.getString('region') ?? '').trim().isNotEmpty,
      (prefs.getStringList('platforms') ?? const <String>[]).isNotEmpty,
      (prefs.getString('communicationStyle') ?? '').trim().isNotEmpty,
      (prefs.getStringList('playstyles') ?? const <String>[]).isNotEmpty,
      (prefs.getStringList('topFiveBlueprints') ?? const <String>[]).isNotEmpty,
    ];
    final completed = checks.where((item) => item).length;
    final percent = ((completed / checks.length) * 100).round();
    return ArcProfileCompletionSummary(
      percent: percent,
      completed: completed,
      total: checks.length,
    );
  }
}

class ArcDeveloperToolsCard extends StatefulWidget {
  const ArcDeveloperToolsCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<ArcDeveloperToolsCard> createState() => _ArcDeveloperToolsCardState();
}

class _ArcDeveloperToolsCardState extends State<ArcDeveloperToolsCard> {
  String _status = 'Ready';

  Future<void> _run(String label, Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    setState(() => _status = label);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), backgroundColor: AppTheme.darkBackground),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.tradingCardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPink.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode_rounded,
                color: AppTheme.neonPink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Developer Tools',
                  style: AppTheme.tradingHeading(
                    fontSize: widget.compact ? 15 : 18,
                    color: AppTheme.neonPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Closed beta reset controls: $_status',
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DevButton(
                label: 'Reset onboarding',
                onPressed: () =>
                    _run('Onboarding reset', ArcBetaFirstRun.resetOnboarding),
              ),
              _DevButton(
                label: 'Force onboarding',
                onPressed: () => _run(
                  'Onboarding forced',
                  () => ArcBetaFirstRun.setFlag(
                    ArcBetaFirstRunKeys.forceOnboarding,
                    true,
                  ),
                ),
              ),
              _DevButton(
                label: 'Complete onboarding',
                onPressed: () => _run(
                  'Onboarding complete',
                  ArcBetaFirstRun.markOnboardingComplete,
                ),
              ),
              _DevButton(
                label: 'Reset tutorials',
                onPressed: () =>
                    _run('Tutorials reset', ArcBetaFirstRun.resetTutorials),
              ),
              _DevButton(
                label: 'Reset all',
                onPressed: () => _run(
                  'Beta progress reset',
                  ArcBetaFirstRun.resetAllBetaProgress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class ArcProfileCompletionCard extends StatefulWidget {
  const ArcProfileCompletionCard({super.key});

  @override
  State<ArcProfileCompletionCard> createState() =>
      _ArcProfileCompletionCardState();
}

class _ArcProfileCompletionCardState extends State<ArcProfileCompletionCard> {
  ArcProfileCompletionSummary? _summary;

  @override
  void initState() {
    super.initState();
    ArcProfileCompletionSummary.load().then((value) {
      if (mounted) setState(() => _summary = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.tradingCardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, color: AppTheme.neonCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profile Completion',
                  style: AppTheme.tradingHeading(
                    fontSize: 17,
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
            '${summary.completed}/${summary.total} beta essentials complete',
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
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
