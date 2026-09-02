import 'dart:async';

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcPersonalisationPreferencesPanel extends StatefulWidget {
  const ArcPersonalisationPreferencesPanel({super.key});

  @override
  State<ArcPersonalisationPreferencesPanel> createState() =>
      _ArcPersonalisationPreferencesPanelState();
}

class _ArcPersonalisationPreferencesPanelState
    extends State<ArcPersonalisationPreferencesPanel> {
  final ArcUserPersonalisationRepository _repository =
      ArcUserPersonalisationRepository();

  ArcUserPersonalisationProfile? _draft;
  bool _saving = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    unawaited(_repository.migrateLegacyIfNeeded());
  }

  Future<void> _save(ArcUserPersonalisationProfile profile) async {
    setState(() {
      _saving = true;
      _message = '';
    });
    try {
      await _repository.markComplete(
        profile.copyWith(source: 'profile_settings'),
      );
      if (!mounted) return;
      setState(() {
        _draft = null;
        _message = 'Command Centre preferences saved.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not save preferences: $error';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ArcUserPersonalisationProfile>(
      stream: _repository.watchProfile(),
      builder: (context, snapshot) {
        final profile =
            _draft ?? snapshot.data ?? ArcUserPersonalisationProfile.defaults;
        return Container(
          width: double.infinity,
          padding: AppTheme.sectionCardPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.panel,
            accent: ArcUiTokens.secondaryAccent,
            borderOpacity: 0.18,
            radius: ArcUiTokens.radiusL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Command Centre Personalisation',
                      style: ArcUiTokens.sectionTitle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'These preferences rank your home priorities, drawer shortcuts and alert categories. Access gates still control locked beta features.',
                style: ArcUiTokens.body(),
              ),
              const SizedBox(height: AppTheme.spaceL),
              _sectionLabel('Primary goals'),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  for (final goal in ArcPersonalisationGoal.values)
                    FilterChip(
                      selected: profile.goals.contains(goal),
                      label: Text(goal.label),
                      selectedColor: ArcUiTokens.primaryAccent.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: ArcUiTokens.surfaceInteractive
                          .withValues(alpha: 0.74),
                      checkmarkColor: ArcUiTokens.primaryAccent,
                      side: _preferenceChipSide(
                        profile.goals.contains(goal),
                        ArcUiTokens.primaryAccent,
                      ),
                      labelStyle: _preferenceChipLabel(
                        profile.goals.contains(goal),
                        ArcUiTokens.primaryAccent,
                      ),
                      shape: _preferenceChipShape,
                      onSelected: (selected) {
                        _updateDraft(
                          profile.copyWith(
                            goals: _toggleGoal(profile.goals, goal, selected),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceL),
              _sectionLabel('Command Centre detail'),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  for (final density in ArcCommandCentreDensity.values)
                    ChoiceChip(
                      selected: profile.commandCentre.density == density,
                      label: Text(_densityLabel(density)),
                      selectedColor: ArcUiTokens.secondaryAccent.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: ArcUiTokens.surfaceInteractive
                          .withValues(alpha: 0.74),
                      side: _preferenceChipSide(
                        profile.commandCentre.density == density,
                        ArcUiTokens.secondaryAccent,
                      ),
                      labelStyle: _preferenceChipLabel(
                        profile.commandCentre.density == density,
                        ArcUiTokens.secondaryAccent,
                      ),
                      shape: _preferenceChipShape,
                      onSelected: (_) {
                        _updateDraft(
                          profile.copyWith(
                            commandCentre: profile.commandCentre.copyWith(
                              density: density,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceL),
              _sectionLabel('Squad preference'),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  for (final preference in ArcSoloSquadPreference.values)
                    ChoiceChip(
                      selected: profile.squadPreference == preference,
                      label: Text(_squadLabel(preference)),
                      selectedColor: ArcUiTokens.secondaryAccent.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: ArcUiTokens.surfaceInteractive
                          .withValues(alpha: 0.74),
                      side: _preferenceChipSide(
                        profile.squadPreference == preference,
                        ArcUiTokens.secondaryAccent,
                      ),
                      labelStyle: _preferenceChipLabel(
                        profile.squadPreference == preference,
                        ArcUiTokens.secondaryAccent,
                      ),
                      shape: _preferenceChipShape,
                      onSelected: (_) {
                        _updateDraft(
                          profile.copyWith(squadPreference: preference),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceL),
              _sectionLabel('Notification relevance'),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  for (final category in _visibleNotificationCategories)
                    FilterChip(
                      selected: profile.notificationCategories.contains(
                        category,
                      ),
                      label: Text(_notificationLabel(category)),
                      selectedColor: ArcUiTokens.primaryAccent.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: ArcUiTokens.surfaceInteractive
                          .withValues(alpha: 0.74),
                      checkmarkColor: ArcUiTokens.primaryAccent,
                      side: _preferenceChipSide(
                        profile.notificationCategories.contains(category),
                        ArcUiTokens.primaryAccent,
                      ),
                      labelStyle: _preferenceChipLabel(
                        profile.notificationCategories.contains(category),
                        ArcUiTokens.primaryAccent,
                      ),
                      shape: _preferenceChipShape,
                      onSelected: (selected) {
                        _updateDraft(
                          profile.copyWith(
                            notificationCategories: _toggleNotification(
                              profile.notificationCategories,
                              category,
                              selected,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceL),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ArcUiTokens.textButtonStyle(primary: true),
                    onPressed: _saving || _draft == null
                        ? null
                        : () => _save(profile),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArcUiTokens.background,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Personalisation'),
                  ),
                  if (_draft != null)
                    TextButton(
                      style: ArcUiTokens.textButtonStyle(
                        accent: ArcUiTokens.secondaryAccent,
                      ),
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _draft = null;
                              _message = '';
                            }),
                      child: const Text('Discard Changes'),
                    ),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceS),
                Text(_message, style: ArcUiTokens.metadata()),
              ],
            ],
          ),
        );
      },
    );
  }

  void _updateDraft(ArcUserPersonalisationProfile next) {
    setState(() {
      _draft = next;
      _message = '';
    });
  }

  Set<ArcPersonalisationGoal> _toggleGoal(
    Set<ArcPersonalisationGoal> current,
    ArcPersonalisationGoal goal,
    bool selected,
  ) {
    final next = {...current};
    if (selected) {
      if (goal == ArcPersonalisationGoal.exploreEverything) {
        next
          ..clear()
          ..add(goal);
      } else {
        next
          ..remove(ArcPersonalisationGoal.exploreEverything)
          ..add(goal);
      }
    } else {
      next.remove(goal);
      if (next.isEmpty) next.add(ArcPersonalisationGoal.exploreEverything);
    }
    return next;
  }

  Set<ArcPersonalisationNotificationCategory> _toggleNotification(
    Set<ArcPersonalisationNotificationCategory> current,
    ArcPersonalisationNotificationCategory category,
    bool selected,
  ) {
    final next = {...current};
    if (selected) {
      next.add(category);
    } else {
      next.remove(category);
    }
    return next;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Text(
        label.toUpperCase(),
        style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
      ),
    );
  }

  BorderSide _preferenceChipSide(bool selected, Color accent) {
    return BorderSide(
      color: (selected ? accent : ArcUiTokens.borderSubtle).withValues(
        alpha: 0.62,
      ),
    );
  }

  TextStyle _preferenceChipLabel(bool selected, Color accent) {
    return ArcUiTokens.label(
      color: selected ? accent : ArcUiTokens.textSecondary,
    );
  }

  OutlinedBorder get _preferenceChipShape {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
    );
  }

  String _densityLabel(ArcCommandCentreDensity value) {
    switch (value) {
      case ArcCommandCentreDensity.compact:
        return 'Compact';
      case ArcCommandCentreDensity.balanced:
        return 'Balanced';
      case ArcCommandCentreDensity.detailed:
        return 'Detailed';
    }
  }

  String _squadLabel(ArcSoloSquadPreference value) {
    switch (value) {
      case ArcSoloSquadPreference.solo:
        return 'Solo';
      case ArcSoloSquadPreference.duo:
        return 'Duo';
      case ArcSoloSquadPreference.squad:
        return 'Squad';
      case ArcSoloSquadPreference.flexible:
        return 'Flexible';
    }
  }

  String _notificationLabel(ArcPersonalisationNotificationCategory category) {
    switch (category) {
      case ArcPersonalisationNotificationCategory.tradeActivity:
        return 'Trades';
      case ArcPersonalisationNotificationCategory.listingMatches:
        return 'Listing Matches';
      case ArcPersonalisationNotificationCategory.blueprintWatches:
        return 'Blueprint Watches';
      case ArcPersonalisationNotificationCategory.favouriteRiderActivity:
        return 'Favourite Raiders';
      case ArcPersonalisationNotificationCategory.matchRiderActivity:
        return 'Match Raider';
      case ArcPersonalisationNotificationCategory.availabilityReminders:
        return 'Availability';
      case ArcPersonalisationNotificationCategory.questProgress:
        return 'Quests';
      case ArcPersonalisationNotificationCategory.benchProgress:
        return 'Bench';
      case ArcPersonalisationNotificationCategory.scrappyProgress:
        return 'Scrappy';
      case ArcPersonalisationNotificationCategory.raidIntelligence:
        return 'Raid Intel';
      case ArcPersonalisationNotificationCategory.systemAnnouncements:
        return 'System';
      case ArcPersonalisationNotificationCategory.futureBountyActivity:
        return 'Future Bounty';
      case ArcPersonalisationNotificationCategory.futureRatRiskWarnings:
        return 'Future Rat Risk';
    }
  }

  static const _visibleNotificationCategories =
      <ArcPersonalisationNotificationCategory>[
        ArcPersonalisationNotificationCategory.tradeActivity,
        ArcPersonalisationNotificationCategory.listingMatches,
        ArcPersonalisationNotificationCategory.blueprintWatches,
        ArcPersonalisationNotificationCategory.favouriteRiderActivity,
        ArcPersonalisationNotificationCategory.matchRiderActivity,
        ArcPersonalisationNotificationCategory.availabilityReminders,
        ArcPersonalisationNotificationCategory.questProgress,
        ArcPersonalisationNotificationCategory.benchProgress,
        ArcPersonalisationNotificationCategory.scrappyProgress,
        ArcPersonalisationNotificationCategory.raidIntelligence,
        ArcPersonalisationNotificationCategory.systemAnnouncements,
      ];
}
