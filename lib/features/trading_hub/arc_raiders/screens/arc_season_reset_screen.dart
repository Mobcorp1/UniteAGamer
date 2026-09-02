import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_expedition_state_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSeasonResetScreen extends StatefulWidget {
  const ArcSeasonResetScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/season-reset';

  @override
  State<ArcSeasonResetScreen> createState() => _ArcSeasonResetScreenState();
}

class _ArcSeasonResetScreenState extends State<ArcSeasonResetScreen> {
  final ArcExpeditionStateManager _expeditionStateManager =
      ArcExpeditionStateManager.instance;
  late final Future<_ResetScreenData> _future = _load();
  bool _confirmed = false;
  bool _applying = false;
  ArcSeasonResetApplyResult? _result;

  Future<_ResetScreenData> _load() async {
    final snapshot = await _expeditionStateManager.refresh(
      reason: ArcExpeditionRefreshReason.initialLoad,
    );
    final preview = await _expeditionStateManager.createResetPreview();
    return _ResetScreenData(state: snapshot.seasonState, preview: preview);
  }

  Future<void> _apply(ArcSeasonResetPreview preview) async {
    if (_applying || !_confirmed) return;
    setState(() => _applying = true);
    try {
      final result = await _expeditionStateManager.beginReset(preview);
      if (!mounted) return;
      setState(() {
        _result = result;
        _confirmed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expedition reset complete.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset failed safely: $error')));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _returnToCommandCentre() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      ArcCommandCentreScreen.routeName,
      (route) => route.settings.name == ArcCommandCentreScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Command'),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: true,
        child: FutureBuilder<_ResetScreenData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ArcUiTokens.primaryAccent,
                ),
              );
            }
            if (snapshot.hasError) {
              return ArcRaidersPageList(
                maxWidth: 840,
                bottomPadding: 120,
                children: [
                  ArcRaidersPageHeader(
                    title: 'EXPEDITION RESET',
                    subtitle: 'Preview unavailable',
                    icon: Icons.warning_amber_rounded,
                    accent: ArcUiTokens.danger,
                  ),
                  ArcRaidersSectionCard(
                    accent: ArcUiTokens.danger,
                    child: Text(
                      'Reset preview could not load: ${snapshot.error}',
                      style: ArcUiTokens.body(
                        fontSize: 14,
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            }
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();
            if (_result != null) {
              return _completionView(_result!);
            }
            return _previewView(data);
          },
        ),
      ),
    );
  }

  Widget _previewView(_ResetScreenData data) {
    final state = data.state;
    final preview = data.preview;
    final blocked = state.resetStatus == ArcSeasonResetStatus.inProgress;
    return ArcRaidersPageList(
      maxWidth: 920,
      bottomPadding: 120,
      children: [
        ArcRaidersPageHeader(
          title: 'START EXPEDITION RESET',
          subtitle:
              'Archive the current season and begin ${preview.nextSeasonId}. No changes happen until you confirm.',
          icon: Icons.restart_alt_rounded,
          accent: ArcUiTokens.secondaryAccent,
        ),
        _statusCard(state, preview),
        _impactSection(
          title: 'WHAT RESETS',
          impacts: preview.impactsFor(ArcSeasonResetClassification.reset),
          accent: ArcUiTokens.secondaryAccent,
        ),
        _staticPolicySection(
          title: 'WHAT PERSISTS',
          items: ArcSeasonResetPolicy.persistentSystems,
          accent: ArcUiTokens.primaryAccent,
        ),
        _impactSection(
          title: 'WHAT RECALCULATES',
          impacts: preview.impactsFor(
            ArcSeasonResetClassification.recalculated,
          ),
          accent: ArcUiTokens.warning,
        ),
        _staticPolicySection(
          title: 'MANUAL RECONFIRMATION',
          items: ArcSeasonResetPolicy.manualReconfirmSystems,
          accent: ArcUiTokens.attentionAccent,
        ),
        ArcRaidersSectionCard(
          accent: ArcUiTokens.secondaryAccent,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: _confirmed,
                onChanged: blocked
                    ? null
                    : (value) => setState(() => _confirmed = value == true),
                activeColor: ArcUiTokens.secondaryAccent,
                checkColor: ArcUiTokens.background,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I understand this archives blueprint, tracker and current-season Operation progress. Profile, reputation, legal consent and permanent rewards remain.',
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textSecondary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: ArcUiTokens.textButtonStyle(
                        accent: ArcUiTokens.primaryAccent,
                      ),
                      onPressed: _applying
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ArcUiTokens.textButtonStyle(
                        accent: ArcUiTokens.secondaryAccent,
                        primary: true,
                      ),
                      onPressed: blocked || !_confirmed || _applying
                          ? null
                          : () => _apply(preview),
                      icon: _applying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ArcUiTokens.background,
                              ),
                            )
                          : const Icon(Icons.restart_alt_rounded),
                      label: Text(
                        blocked ? 'Reset In Progress' : 'Confirm Reset',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _completionView(ArcSeasonResetApplyResult result) {
    return ArcRaidersPageList(
      maxWidth: 860,
      bottomPadding: 120,
      children: [
        ArcRaidersPageHeader(
          title: 'EXPEDITION RESET COMPLETE',
          subtitle:
              '${result.archivedSeasonId} archived. ${result.currentSeasonId} is now active.',
          icon: Icons.task_alt_rounded,
          accent: ArcUiTokens.primaryAccent,
        ),
        ArcRaidersSectionCard(
          accent: ArcUiTokens.primaryAccent,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricRow('New season', result.currentSeasonId),
              _metricRow('Archived season', result.archivedSeasonId),
              _metricRow('Reset ID', result.resetId),
              _metricRow('Reset version', result.resetVersion.toString()),
              _metricRow(
                'Blueprints reset',
                result.resetBlueprintIds.length.toString(),
              ),
              _metricRow(
                'Tracker docs reset',
                result.resetStateIds.length.toString(),
              ),
              _metricRow(
                'Operations archived',
                result.archivedOperationIds.length.toString(),
              ),
              _metricRow(
                'Rewards preserved',
                result.archivedRewardCount.toString(),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                'Next: rebuild early-season quest, Scrappy, bench and Operation progress from Command Centre.',
                style: ArcUiTokens.body(
                  fontSize: 13,
                  color: ArcUiTokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              ElevatedButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                  primary: true,
                ),
                onPressed: _returnToCommandCentre,
                icon: const Icon(Icons.dashboard_customize_rounded),
                label: const Text('Return To Command Centre'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCard(ArcSeasonState state, ArcSeasonResetPreview preview) {
    return ArcRaidersSectionCard(
      accent: ArcUiTokens.primaryAccent,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: AppTheme.spaceM,
        runSpacing: AppTheme.spaceM,
        children: [
          _metricTile('Current season', preview.currentSeasonId),
          _metricTile('Next season', preview.nextSeasonId),
          _metricTile('Reset version', preview.resetVersion.toString()),
          _metricTile('Reset status', state.resetStatus.name),
          _metricTile('Blueprints', preview.blueprintStateCount.toString()),
          _metricTile('Scrappy docs', preview.scrappyStateCount.toString()),
          _metricTile('Quest docs', preview.questStateCount.toString()),
          _metricTile('Bench docs', preview.benchStateCount.toString()),
          _metricTile('Operations', preview.operationProgressCount.toString()),
          _metricTile('Vault rewards', preview.rewardCount.toString()),
        ],
      ),
    );
  }

  Widget _impactSection({
    required String title,
    required List<ArcSeasonResetSystemImpact> impacts,
    required Color accent,
  }) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 20, color: accent),
          ),
          const SizedBox(height: AppTheme.spaceM),
          for (final impact in impacts) _impactRow(impact, accent),
        ],
      ),
    );
  }

  Widget _staticPolicySection({
    required String title,
    required List<String> items,
    required Color accent,
  }) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 20, color: accent),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(
                  label: Text(item),
                  backgroundColor: ArcUiTokens.surfaceInteractive,
                  side: BorderSide(color: accent.withValues(alpha: 0.28)),
                  labelStyle: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactRow(ArcSeasonResetSystemImpact impact, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hexagon_outlined, size: 16, color: accent),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impact.itemCount > 0
                      ? '${impact.label} (${impact.itemCount})'
                      : impact.label,
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  impact.reason,
                  style: ArcUiTokens.body(
                    fontSize: 12,
                    color: ArcUiTokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.interactive,
          accent: ArcUiTokens.primaryAccent,
          borderOpacity: 0.16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.cardTitle(
                fontSize: 16,
                color: ArcUiTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ArcUiTokens.body(
                fontSize: 13,
                color: ArcUiTokens.textTertiary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.body(
                fontSize: 13,
                color: ArcUiTokens.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetScreenData {
  const _ResetScreenData({required this.state, required this.preview});

  final ArcSeasonState state;
  final ArcSeasonResetPreview preview;
}
