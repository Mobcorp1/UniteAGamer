import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../data/arc_profile_completion_evaluator.dart';
import '../models/arc_operations_models.dart';
import '../models/arc_profile_social_models.dart';
import '../models/arc_trader_profile.dart';
import '../repositories/arc_operations_repository.dart';
import '../repositories/arc_trader_profile_repository.dart';
import '../screens/arc_availability_screen.dart';
import '../screens/arc_away_screen.dart';
import '../screens/arc_profile_edit_screen.dart';
import '../screens/arc_profile_setup_screen.dart';
import '../screens/wall_of_legends_screen.dart';
import '../widgets/arc_raiders_screen_shell.dart';

class TradingProfileScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile';

  const TradingProfileScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingProfileScreen> createState() => _TradingProfileScreenState();
}

class _TradingProfileScreenState extends State<TradingProfileScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();
  final ArcOperationsRepository _operationsRepository =
      ArcOperationsRepository();
  late final Stream<ArcProfileCompletionResult> _profileCompletionStream =
      _repository.watchProfileCompletion();

  bool _isInitialising = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _repository.ensureDocsExist().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _initError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('TradingProfileScreen._init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _initError = 'Trader profile init failed: $error';
      });
    }
  }

  Future<void> _openSetupIfNeeded() async {
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;

      if (!profile.hasCoreDetails) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ArcProfileSetupScreen()),
        );
        if (!mounted) return;
        setState(() {});
      }
    } catch (error, stackTrace) {
      debugPrint('TradingProfileScreen._openSetupIfNeeded failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _initError = 'Could not open profile setup: $error';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isInitialising = true;
      _initError = null;
    });
    await _init();
  }

  Future<void> _openProfileEditor() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ArcProfileEditScreen()));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return const Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: ArcRaidersScreenShell(
          showAdBanner: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: widget.showAppBar
            ? const UagAppBar(
                title: 'Your Hub Profile',
                subtitle:
                    'Identity, reputation, availability and match readiness.',
              )
            : null,
        body: ArcRaidersScreenShell(
          showAdBanner: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spaceL),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceS,
                AppTheme.spaceM,
                AppTheme.spaceL,
              ),
              decoration: AppTheme.tradingCardDecoration(
                borderColor: Colors.redAccent.withValues(alpha: 0.28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 34,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? const UagAppBar(
              title: 'Your Hub Profile',
              subtitle:
                  'Identity, reputation, availability and match readiness.',
            )
          : null,
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: StreamBuilder<ArcTraderProfile>(
            stream: _repository.watchProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.spaceL),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceM,
                      AppTheme.spaceS,
                      AppTheme.spaceM,
                      AppTheme.spaceL,
                    ),
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: Colors.redAccent.withValues(alpha: 0.28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load Your Hub Profile data: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        ElevatedButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final profile = snapshot.data;
              if (profile == null) {
                return Center(
                  child: ElevatedButton(
                    onPressed: _openSetupIfNeeded,
                    child: const Text('Set Up Profile'),
                  ),
                );
              }

              return StreamBuilder<ArcProfileCompletionResult>(
                stream: _profileCompletionStream,
                initialData: ArcProfileCompletionResult.completeResult,
                builder: (context, completionSnapshot) {
                  final profileCompletion =
                      completionSnapshot.data ??
                      ArcProfileCompletionResult.completeResult;
                  return StreamBuilder<ArcOperationsUserState>(
                    stream: _operationsRepository.watchUserState(),
                    builder: (context, operationsSnapshot) {
                      final operationsState =
                          operationsSnapshot.data ??
                          ArcOperationsUserState.empty;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final contentWidth = constraints.maxWidth > 1440
                              ? 1360.0
                              : constraints.maxWidth;
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spaceM,
                              AppTheme.spaceS,
                              AppTheme.spaceM,
                              AppTheme.spaceL,
                            ),
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: contentWidth,
                                  child: _profileDashboard(
                                    profile,
                                    operationsState,
                                    constraints.maxWidth,
                                    profileCompletion,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileDashboard(
    ArcTraderProfile profile,
    ArcOperationsUserState operationsState,
    double viewportWidth,
    ArcProfileCompletionResult profileCompletion,
  ) {
    final isWide = viewportWidth >= 1040;
    final gap = isWide ? AppTheme.spaceM : AppTheme.spaceS;

    final identityColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _profileCommandHero(profile, operationsState),
        SizedBox(height: gap),
        _identityProgressPanel(profile, profileCompletion),
        SizedBox(height: gap),
        _raiderIdentityPanel(profile),
        SizedBox(height: gap),
        _sessionProfilePanel(profile),
        SizedBox(height: gap),
        _publicDetailsPanel(profile),
        SizedBox(height: gap),
        _socialLinksPanel(profile),
        SizedBox(height: gap),
        _profileActionsPanel(),
      ],
    );

    final reputationColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _reputationCommandPanel(profile, operationsState),
        SizedBox(height: gap),
        _rewardShowcasePanel(operationsState),
        SizedBox(height: gap),
        _badgeGallery(),
        SizedBox(height: gap),
        _creatorProgrammePanel(profile),
        SizedBox(height: gap),
        _communityContributionPanel(operationsState),
        SizedBox(height: gap),
        _guardianCommunitySystemPanel(profile, operationsState),
        SizedBox(height: gap),
        _loadoutPreview(),
      ],
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identityColumn,
          SizedBox(height: gap),
          reputationColumn,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 11, child: identityColumn),
        SizedBox(width: gap),
        Expanded(flex: 9, child: reputationColumn),
      ],
    );
  }

  Widget _identityProgressPanel(
    ArcTraderProfile profile,
    ArcProfileCompletionResult profileCompletion,
  ) {
    final missing = profileCompletion.missingFieldIds.toSet();
    final sections = <({String label, bool complete})>[
      (label: 'Identity', complete: profile.hasCoreDetails),
      (label: 'Embark ID', complete: !missing.contains('embarkId')),
      (label: 'Archetypes', complete: !missing.contains('archetypes')),
      (
        label: 'Communication',
        complete: !missing.contains('communicationStyle'),
      ),
      (
        label: 'Session intent',
        complete:
            !missing.contains('squadIntent') &&
            !missing.contains('socialSessionState'),
      ),
      (label: 'Availability', complete: !missing.contains('availability')),
      (label: 'Onboarding', complete: !missing.contains('onboarding')),
      (label: 'Legal', complete: !missing.contains('legal')),
    ];
    final completed = sections.where((section) => section.complete).length;
    final progress = completed / sections.length;

    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Raider Identity',
      icon: Icons.radar_rounded,
      onEdit: _openProfileEditor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      color: AppTheme.neonCyan,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Text(
                  completed == sections.length
                      ? 'Your identity is match-ready.'
                      : '${sections.length - completed} profile areas still need attention.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: sections
                .map(
                  (section) => _profileChip(
                    icon: section.complete
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    label: section.label,
                    accent: section.complete
                        ? AppTheme.neonCyan
                        : Colors.white54,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _raiderIdentityPanel(ArcTraderProfile profile) {
    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Playstyle & Archetypes',
      icon: Icons.groups_rounded,
      onEdit: _openProfileEditor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _identityLabel('Archetypes'),
          const SizedBox(height: AppTheme.spaceS),
          if (profile.archetypes.isEmpty)
            _profileEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No archetypes selected',
              copy: 'Add the roles that best describe how you play.',
            )
          else
            Wrap(
              spacing: AppTheme.spaceS,
              runSpacing: AppTheme.spaceS,
              children: profile.archetypes
                  .map(
                    (value) => _archetypeBadge(
                      icon: _archetypeIcon(value),
                      label: value,
                      copy: _archetypeCopy(value),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: AppTheme.spaceM),
          _identityLabel('Playstyle'),
          const SizedBox(height: AppTheme.spaceS),
          if (profile.playStyles.isEmpty)
            _profileEmptyState(
              icon: Icons.route_rounded,
              title: 'No playstyle selected',
              copy: 'Choose one or more playstyles to improve squad matching.',
            )
          else
            Wrap(
              spacing: AppTheme.spaceS,
              runSpacing: AppTheme.spaceS,
              children: profile.playStyles
                  .map(
                    (value) => _profileChip(
                      icon: _playStyleIcon(value),
                      label: value,
                      accent: AppTheme.neonCyan,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _sessionProfilePanel(ArcTraderProfile profile) {
    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Match Readiness',
      icon: Icons.hub_rounded,
      onEdit: _openProfileEditor,
      child: Column(
        children: [
          _sessionStatusTile(
            icon: Icons.record_voice_over_rounded,
            title: 'Communication',
            value: profile.communicationStyle,
            copy: _communicationCopy(profile.communicationStyle),
          ),
          const SizedBox(height: AppTheme.spaceS),
          _sessionStatusTile(
            icon: Icons.flag_rounded,
            title: "Today's goal",
            value: profile.squadIntent,
            copy: _squadIntentCopy(profile.squadIntent),
          ),
          const SizedBox(height: AppTheme.spaceS),
          _sessionStatusTile(
            icon: ArcPlayerSessionCatalog.iconFor(profile.sessionIntent),
            title: 'This session',
            value: profile.sessionIntent,
            copy: ArcPlayerSessionCatalog.intentDescription(
              profile.sessionIntent,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          _sessionStatusTile(
            icon: ArcPlayerSessionCatalog.iconFor(profile.currentPriority),
            title: 'Current priority',
            value: profile.currentPriority,
            copy: ArcPlayerSessionCatalog.priorityDescription(
              profile.currentPriority,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          _sessionStatusTile(
            icon: Icons.bolt_rounded,
            title: 'Social energy',
            value: profile.socialEnergy,
            copy: _socialEnergyCopy(profile.socialEnergy),
          ),
        ],
      ),
    );
  }

  Widget _sessionStatusTile({
    required IconData icon,
    required String title,
    required String value,
    required String copy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 20),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _publicDetailsPanel(ArcTraderProfile profile) {
    return _detailCard(
      title: 'Public Profile Details',
      children: [
        _detailRow('UAG ID', profile.uagId),
        _detailRow('UAG Name', profile.uagName),
        _detailRow('Region', profile.region),
        _detailRow('Preferred Platform', profile.platform),
        _detailRow(
          'Embark ID',
          profile.embarkId.isEmpty
              ? 'Private until trade confirmed'
              : profile.embarkId,
        ),
        _detailRow('Timezone', profile.timezone),
        _detailRow(
          'Visibility',
          profile.visibleInSearch
              ? 'Visible in player and trader discovery'
              : 'Hidden from player and trader discovery',
        ),
      ],
    );
  }

  Widget _socialLinksPanel(ArcTraderProfile profile) {
    final publicLinks = profile.publicSocialLinks;
    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Public Social Links',
      icon: Icons.link_rounded,
      onEdit: _openProfileEditor,
      child: publicLinks.isEmpty
          ? _profileEmptyState(
              icon: Icons.link_off_rounded,
              title: 'No public social links',
              copy:
                  'Add TikTok, YouTube, Twitch, Kick, Discord, Steam or platform links when you want other Raiders to find you.',
            )
          : Wrap(
              spacing: AppTheme.spaceS,
              runSpacing: AppTheme.spaceS,
              children: publicLinks.map(_socialLinkTile).toList(),
            ),
    );
  }

  Widget _socialLinkTile(ArcProfileSocialLink link) {
    final destination = link.destinationUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: destination.isEmpty ? null : () => _copySocialLink(link),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(AppTheme.spaceS),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(
              _socialPlatformIcon(link.platform),
              color: AppTheme.neonCyan,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.platform.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    link.displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _copySocialLink(ArcProfileSocialLink link) async {
    final destination = link.destinationUrl;
    if (destination.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: destination));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${link.platform.label} link copied.')),
    );
  }

  IconData _socialPlatformIcon(ArcSocialPlatform platform) {
    return switch (platform) {
      ArcSocialPlatform.tiktok => Icons.music_note_rounded,
      ArcSocialPlatform.youtube => Icons.play_circle_fill_rounded,
      ArcSocialPlatform.twitch => Icons.live_tv_rounded,
      ArcSocialPlatform.kick => Icons.sports_esports_rounded,
      ArcSocialPlatform.discord => Icons.forum_rounded,
      ArcSocialPlatform.steam => Icons.gamepad_rounded,
      ArcSocialPlatform.xbox => Icons.sports_esports_rounded,
      ArcSocialPlatform.playStation => Icons.videogame_asset_rounded,
      ArcSocialPlatform.epicGames => Icons.extension_rounded,
    };
  }

  Widget _profileActionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _actionTile(
          icon: Icons.edit_outlined,
          title: 'Edit Raider Identity',
          subtitle: 'Update identity, playstyle, communication and visibility.',
          onTap: _openProfileEditor,
        ),
        const SizedBox(height: AppTheme.spaceS),
        _actionTile(
          icon: Icons.schedule_outlined,
          title: 'Availability',
          subtitle: 'Set weekly, rotation or flexible squad availability.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ArcAvailabilityScreen()),
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        _actionTile(
          icon: Icons.beach_access_outlined,
          title: 'Away Mode',
          subtitle: 'Temporarily hide from squad and trade discovery.',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ArcAwayScreen())),
        ),
      ],
    );
  }

  Widget _identityLabel(String value) {
    return Text(
      value.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  IconData _archetypeIcon(String value) {
    final catalogIcon = ArcPlayerArchetypeCatalog.iconFor(value);
    if (catalogIcon != Icons.person_pin_circle_rounded) return catalogIcon;

    final normalized = value.toLowerCase();
    if (normalized.contains('quest')) return Icons.assignment_turned_in_rounded;
    if (normalized.contains('blueprint') || normalized.contains('collector')) {
      return Icons.grid_view_rounded;
    }
    if (normalized.contains('trade')) return Icons.handshake_rounded;
    if (normalized.contains('help') || normalized.contains('mentor')) {
      return Icons.volunteer_activism_rounded;
    }
    if (normalized.contains('leader')) return Icons.flag_rounded;
    if (normalized.contains('pvp')) return Icons.local_fire_department_rounded;
    if (normalized.contains('support')) return Icons.health_and_safety_rounded;
    return Icons.explore_rounded;
  }

  IconData _playStyleIcon(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('pvp')) return Icons.gps_fixed_rounded;
    if (normalized.contains('aggressive')) return Icons.bolt_rounded;
    if (normalized.contains('defensive')) return Icons.shield_rounded;
    return Icons.route_rounded;
  }

  String _archetypeCopy(String value) {
    final catalogCopy = ArcPlayerArchetypeCatalog.descriptionFor(value);
    if (catalogCopy != 'Custom raider identity') return catalogCopy;

    final normalized = value.toLowerCase();
    if (normalized.contains('quest')) return 'Objectives first';
    if (normalized.contains('blueprint')) return 'Blueprint focused';
    if (normalized.contains('trade')) return 'Trade ready';
    if (normalized.contains('help') || normalized.contains('mentor')) {
      return 'Supports others';
    }
    if (normalized.contains('leader')) return 'Squad direction';
    if (normalized.contains('pvp')) return 'Combat focused';
    return 'Raider identity';
  }

  String _communicationCopy(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('ping')) {
      return 'Prefers concise ping-based coordination.';
    }
    if (normalized.contains('quiet')) {
      return 'Low-comms, focused squad experience.';
    }
    if (normalized.contains('voice') || normalized.contains('mic')) {
      return 'Comfortable coordinating over voice.';
    }
    if (normalized.contains('chat')) return 'Social and conversation friendly.';
    return 'Adapts communication to the squad.';
  }

  String _squadIntentCopy(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('solo')) return 'Open to running independently.';
    if (normalized.contains('help')) return 'Looking to support other raiders.';
    if (normalized.contains('quest')) return 'Prioritising quest progression.';
    if (normalized.contains('blueprint')) {
      return 'Farming blueprint opportunities.';
    }
    if (normalized.contains('squad')) return 'Actively looking for squadmates.';
    return 'Flexible about the next operation.';
  }

  String _socialEnergyCopy(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('quiet')) {
      return 'Prefers a calm, low-pressure session.';
    }
    if (normalized.contains('chat') || normalized.contains('social')) {
      return 'Ready for an outgoing squad session.';
    }
    if (normalized.contains('lead')) {
      return 'Comfortable taking squad direction.';
    }
    if (normalized.contains('grind') || normalized.contains('focus')) {
      return 'Focused on efficient progression.';
    }
    return 'Energy can adapt to the squad.';
  }

  Widget _profileCommandHero(
    ArcTraderProfile profile,
    ArcOperationsUserState operationsState,
  ) {
    final equipped = operationsState.equippedCosmetics;
    final equippedBadge = operationsState.equippedBadge();
    final equippedTitle = operationsState.equippedTitle();
    final equippedFrame = operationsState.equippedProfileFrame();
    final equippedBanner = operationsState.equippedProfileBanner();
    final title = _cosmeticLabelOrFallback(
      item: equippedTitle,
      persistedLabel: equipped.titleLabel,
      persistedId: equipped.titleId,
      fallback: 'Raider Profile',
    );
    final badgeAsset = _cosmeticAssetPath(
      equippedBadge,
      equipped.badgeAssetPath,
    );
    final frameAsset = _cosmeticAssetPath(
      equippedFrame,
      equipped.profileFrameAssetPath,
    );
    final bannerAsset = _cosmeticAssetPath(
      equippedBanner,
      equipped.profileBannerAssetPath,
    );
    final hasFrame = equippedFrame != null || equipped.hasFrame;
    final hasBanner = equippedBanner != null || equipped.hasBanner;
    final frameAccent = equippedFrame == null
        ? AppTheme.neonCyan
        : _rarityAccent(equippedFrame.rarity);
    final bannerAccent = equippedBanner == null
        ? AppTheme.neonCyan
        : _rarityAccent(equippedBanner.rarity);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration:
          AppTheme.tradingCardDecoration(
            borderColor: bannerAccent.withValues(alpha: 0.28),
          ).copyWith(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bannerAccent.withValues(alpha: 0.12),
                AppTheme.cardBackground.withValues(alpha: 0.94),
                AppTheme.neonPink.withValues(alpha: 0.08),
              ],
            ),
          ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _profileBannerBackdrop(
              assetPath: bannerAsset,
              accent: bannerAccent,
              isEquipped: hasBanner,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final avatar = _profileAvatarShowcase(
                  profile: profile,
                  badgeAsset: badgeAsset,
                  frameAsset: frameAsset,
                  frameAccent: frameAccent,
                  hasFrame: hasFrame,
                );
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: compact ? 22 : 30,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.uagName.isEmpty
                          ? 'Unnamed Raider'
                          : profile.uagName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Wrap(
                      spacing: AppTheme.spaceS,
                      runSpacing: AppTheme.spaceS,
                      children: [
                        _profileChip(
                          icon: Icons.military_tech_rounded,
                          label: 'Ops Lv ${operationsState.operationLevel}',
                          accent: AppTheme.neonCyan,
                        ),
                        _profileChip(
                          icon: Icons.auto_awesome_rounded,
                          label: '${operationsState.completedCount} trophies',
                          accent: AppTheme.neonPink,
                        ),
                        _profileChip(
                          icon: Icons.bolt_rounded,
                          label: '${operationsState.intelXp} Intel XP',
                          accent: Colors.amberAccent,
                        ),
                      ],
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(height: AppTheme.spaceM),
                      content,
                    ],
                  );
                }

                return Row(
                  children: [
                    avatar,
                    const SizedBox(width: AppTheme.spaceL),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileBannerBackdrop({
    required String? assetPath,
    required Color accent,
    required bool isEquipped,
  }) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Opacity(
        opacity: 0.34,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) =>
              _profileBannerFallback(accent: accent, isEquipped: isEquipped),
        ),
      );
    }

    return _profileBannerFallback(accent: accent, isEquipped: isEquipped);
  }

  Widget _profileBannerFallback({
    required Color accent,
    required bool isEquipped,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isEquipped ? 0.18 : 0.08),
            Colors.transparent,
            AppTheme.neonPink.withValues(alpha: isEquipped ? 0.12 : 0.06),
          ],
        ),
      ),
    );
  }

  Widget _profileAvatarShowcase({
    required ArcTraderProfile profile,
    required String? badgeAsset,
    required String? frameAsset,
    required Color frameAccent,
    required bool hasFrame,
  }) {
    final accent = hasFrame ? frameAccent : AppTheme.neonCyan;
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.72), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (frameAsset != null && frameAsset.isNotEmpty)
            Positioned.fill(
              child: ClipOval(
                child: Image.asset(
                  frameAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(hasFrame ? 8 : 0),
              child: CircleAvatar(
                backgroundColor: AppTheme.cardBackgroundAlt,
                child: Text(
                  (profile.uagName.isNotEmpty ? profile.uagName[0] : 'U')
                      .toUpperCase(),
                  style: AppTheme.tradingHeading(
                    fontSize: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: _cosmeticBadgeOrb(badgeAsset),
          ),
        ],
      ),
    );
  }

  Widget _cosmeticBadgeOrb(String? badgeAsset) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardBackground.withValues(alpha: 0.92),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.72),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.24),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: badgeAsset != null && badgeAsset.isNotEmpty
            ? Image.asset(
                badgeAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.military_tech_rounded,
                  color: AppTheme.neonCyan,
                  size: 18,
                ),
              )
            : Icon(
                Icons.military_tech_rounded,
                color: AppTheme.neonCyan,
                size: 18,
              ),
      ),
    );
  }

  String? _cosmeticAssetPath(
    ArcRewardInventoryItem? item,
    String? persistedAssetPath,
  ) {
    final itemAsset = item?.assetPath;
    if (itemAsset != null && itemAsset.isNotEmpty) return itemAsset;
    if (persistedAssetPath != null && persistedAssetPath.isNotEmpty) {
      return persistedAssetPath;
    }
    return null;
  }

  String _cosmeticLabelOrFallback({
    required ArcRewardInventoryItem? item,
    required String? persistedLabel,
    required String? persistedId,
    required String fallback,
  }) {
    if (item != null && item.label.isNotEmpty) return item.label;
    if (persistedLabel != null && persistedLabel.isNotEmpty) {
      return persistedLabel;
    }
    if (persistedId != null && persistedId.isNotEmpty) return persistedId;
    return fallback;
  }

  Color _rarityAccent(ArcCosmeticRarity rarity) {
    return switch (rarity) {
      ArcCosmeticRarity.common => AppTheme.neonCyan,
      ArcCosmeticRarity.uncommon => Colors.lightGreenAccent,
      ArcCosmeticRarity.rare => Colors.lightBlueAccent,
      ArcCosmeticRarity.epic => AppTheme.neonPink,
      ArcCosmeticRarity.legendary => Colors.amberAccent,
      ArcCosmeticRarity.founder => Colors.amberAccent,
      ArcCosmeticRarity.closedBeta => AppTheme.neonCyan,
      ArcCosmeticRarity.community => Colors.lightGreenAccent,
      ArcCosmeticRarity.creator => AppTheme.neonPink,
    };
  }

  Widget _reputationCommandPanel(
    ArcTraderProfile profile,
    ArcOperationsUserState operationsState,
  ) {
    final ready = profile.isProfileComplete;
    final trustedScore = ready ? 82 : 28;
    final traderScore = (operationsState.completedCount * 8).clamp(12, 96);
    final guardianScore =
        operationsState.inventory
            .where((item) => item.label.toLowerCase().contains('guardian'))
            .length
            .clamp(0, 5) *
        18;
    final intelScore = (operationsState.intelXp / 10).round().clamp(0, 99);

    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Reputation Command',
      icon: Icons.verified_user_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;
          final items = [
            _reputationMeter('Trusted Raider', trustedScore, AppTheme.neonCyan),
            _reputationMeter('Trader Rep', traderScore, AppTheme.neonPink),
            _reputationMeter(
              'Guardian Rep',
              guardianScore,
              Colors.lightGreenAccent,
            ),
            _reputationMeter('Intel Rep', intelScore, Colors.amberAccent),
          ];
          if (narrow) {
            return Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                      child: item,
                    ),
                  )
                  .toList(),
            );
          }
          return Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: items
                .map((item) => SizedBox(width: 250, child: item))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _reputationMeter(String label, int value, Color accent) {
    final clamped = value.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$clamped%',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: clamped / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardShowcasePanel(ArcOperationsUserState operationsState) {
    final equipped = operationsState.equippedCosmetics;
    final inventory = operationsState.inventory.take(8).toList();

    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Reward Showcase',
      icon: Icons.workspace_premium_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _rewardStatusTile(
                title: 'Equipped Badge',
                value: equipped.badgeId ?? 'None equipped',
                assetPath: equipped.badgeAssetPath,
                accent: AppTheme.neonCyan,
              ),
              _rewardStatusTile(
                title: 'Equipped Title',
                value: equipped.titleLabel ?? 'No title equipped',
                icon: Icons.title_rounded,
                accent: AppTheme.neonPink,
              ),
              _rewardStatusTile(
                title: 'Profile Frame',
                value: equipped.profileFrameId ?? 'Default frame',
                assetPath: equipped.profileFrameAssetPath,
                icon: Icons.crop_square_rounded,
                accent: Colors.amberAccent,
              ),
              _rewardStatusTile(
                title: 'Profile Banner',
                value: equipped.profileBannerId ?? 'Default banner',
                assetPath: equipped.profileBannerAssetPath,
                icon: Icons.crop_16_9_rounded,
                accent: Colors.lightBlueAccent,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Earned Trophies',
            style: AppTheme.tradingHeading(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: AppTheme.spaceS),
          if (inventory.isEmpty)
            const Text(
              'Claim rewards from Operations Command to populate your public trophy case.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            )
          else
            Wrap(
              spacing: AppTheme.spaceS,
              runSpacing: AppTheme.spaceS,
              children: inventory
                  .map(
                    (item) => _rewardThumb(
                      label: item.label,
                      assetPath: item.assetPath,
                      betaExclusive: item.betaExclusive,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _rewardStatusTile({
    required String title,
    required String value,
    required Color accent,
    String? assetPath,
    IconData icon = Icons.military_tech_rounded,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: assetPath != null && assetPath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(icon, color: accent),
                    ),
                  )
                : Icon(icon, color: accent),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardThumb({
    required String label,
    required String? assetPath,
    required bool betaExclusive,
  }) {
    return Container(
      width: 86,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (betaExclusive ? AppTheme.neonPink : AppTheme.neonCyan)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: assetPath != null && assetPath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  )
                : Icon(
                    betaExclusive
                        ? Icons.auto_awesome_rounded
                        : Icons.workspace_premium_rounded,
                    color: betaExclusive
                        ? AppTheme.neonPink
                        : AppTheme.neonCyan,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityContributionPanel(ArcOperationsUserState operationsState) {
    final cards = <({IconData icon, String label, String value, Color accent})>[
      (
        icon: Icons.military_tech_rounded,
        label: 'Lifetime Trophies',
        value: operationsState.completedCount.toString(),
        accent: AppTheme.neonCyan,
      ),
      (
        icon: Icons.handshake_rounded,
        label: 'Bonus Trade Slots',
        value: '+${operationsState.extraTradeSlots}',
        accent: AppTheme.neonPink,
      ),
      (
        icon: Icons.groups_rounded,
        label: 'Bonus Matchmaking',
        value: '+${operationsState.extraMatchmakingSlots}',
        accent: Colors.lightGreenAccent,
      ),
      (
        icon: Icons.bolt_rounded,
        label: 'Operation Credits',
        value: operationsState.operationCredits.toString(),
        accent: Colors.amberAccent,
      ),
    ];

    return _profilePanel(
      accent: Colors.amberAccent,
      title: 'Community Contribution',
      icon: Icons.hub_rounded,
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: cards
            .map(
              (card) => _contributionStat(
                icon: card.icon,
                label: card.label,
                value: card.value,
                accent: card.accent,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _creatorProgrammePanel(ArcTraderProfile profile) {
    final creator = profile.creatorProgramme.normalised(
      referralCode: profile.referralCode,
      affiliateRequested: profile.affiliateEnabled,
    );
    final accent = creator.hasPublicRecognition
        ? AppTheme.neonPink
        : Colors.white54;

    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Creator & Ambassador',
      icon: Icons.campaign_rounded,
      onEdit: _openProfileEditor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _profileChip(
                icon: Icons.workspace_premium_rounded,
                label: creator.displayBadgeLabel,
                accent: accent,
              ),
              _profileChip(
                icon: creator.adminApproved
                    ? Icons.verified_rounded
                    : Icons.hourglass_bottom_rounded,
                label: creator.adminApproved
                    ? 'Admin approved'
                    : profile.affiliateEnabled
                    ? 'Review requested'
                    : 'Not requested',
                accent: creator.adminApproved
                    ? Colors.lightGreenAccent
                    : Colors.white54,
              ),
              if (creator.rewardEligible)
                _profileChip(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Reward eligible',
                  accent: Colors.amberAccent,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            creator.hasPublicRecognition
                ? '${creator.displayTitle} is visible on public community surfaces.'
                : 'Creator, partner and ambassador recognition is admin-approved before it becomes public.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          if (profile.referralCode.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceM),
            _detailRow('Referral Code', profile.referralCode),
          ],
          const SizedBox(height: AppTheme.spaceS),
          _actionTile(
            icon: Icons.emoji_events_rounded,
            title: 'Wall of Legends',
            subtitle:
                'View admin-curated founders, beta raiders, creators and community heroes.',
            onTap: () =>
                Navigator.of(context).pushNamed(WallOfLegendsScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _guardianCommunitySystemPanel(
    ArcTraderProfile profile,
    ArcOperationsUserState operationsState,
  ) {
    final contributionScore = _communityContributionScore(
      profile,
      operationsState,
    );
    final guardianTier = _reputationTier(contributionScore, [
      'Recruit',
      'Guardian I',
      'Guardian II',
      'Guardian III',
      'Guardian V',
    ]);
    final traderTier = _reputationTier(
      operationsState.completedCount * 14 + operationsState.extraTradeSlots * 8,
      ['New Trader', 'Trusted Trader', 'Trade Veteran', 'Trade Master'],
    );
    final intelTier = _reputationTier(operationsState.intelXp, [
      'Intel Recruit',
      'Intel Specialist',
      'Blueprint Sage',
      'Intel Commander',
    ]);
    final generosityTier = _reputationTier(
      operationsState.operationCredits * 8 +
          operationsState.extraMatchmakingSlots * 12,
      [
        'Helpful Raider',
        'Helping Hand',
        'Community Hero',
        'Saint of the Rust Belt',
      ],
    );

    final contributionItems =
        <({IconData icon, String title, String value, Color accent})>[
          (
            icon: Icons.health_and_safety_rounded,
            title: 'Guardian Standing',
            value: guardianTier,
            accent: Colors.lightGreenAccent,
          ),
          (
            icon: Icons.handshake_rounded,
            title: 'Trading Standing',
            value: traderTier,
            accent: AppTheme.neonPink,
          ),
          (
            icon: Icons.radar_rounded,
            title: 'Intel Standing',
            value: intelTier,
            accent: Colors.amberAccent,
          ),
          (
            icon: Icons.volunteer_activism_rounded,
            title: 'Goodwill Standing',
            value: generosityTier,
            accent: AppTheme.neonCyan,
          ),
        ];

    return _profilePanel(
      accent: Colors.lightGreenAccent,
      title: 'Guardian & Community Reputation',
      icon: Icons.shield_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Public proof of helping other Raiders, keeping trades healthy, sharing useful intel and building trust across the Hub.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: contributionItems
                .map(
                  (item) => _standingTile(
                    icon: item.icon,
                    title: item.title,
                    value: item.value,
                    accent: item.accent,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppTheme.spaceM),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final children = [
                _communityMilestoneColumn(
                  title: 'Guardian Track',
                  accent: Colors.lightGreenAccent,
                  milestones: const [
                    'Match with new Raiders',
                    'Help complete trials',
                    'Guide first blueprint runs',
                    'Earn positive session ratings',
                  ],
                ),
                _communityMilestoneColumn(
                  title: 'Goodwill Track',
                  accent: AppTheme.neonCyan,
                  milestones: const [
                    'Complete gift trades',
                    'Offer basic blueprints free',
                    'Support squad recovery runs',
                    'Act as backup during objectives',
                  ],
                ),
              ];

              if (compact) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spaceS,
                          ),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children.first),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(child: children.last),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceM),
          _communityScoreBar(contributionScore),
        ],
      ),
    );
  }

  int _communityContributionScore(
    ArcTraderProfile profile,
    ArcOperationsUserState operationsState,
  ) {
    var score = 0;
    if (profile.isProfileComplete) score += 18;
    if (profile.visibleInSearch) score += 8;
    if (profile.micOk) score += 6;
    if (profile.crossPlatformOk) score += 6;
    score += operationsState.completedCount * 9;
    score += operationsState.extraTradeSlots * 6;
    score += operationsState.extraMatchmakingSlots * 8;
    score += operationsState.operationCredits * 4;
    score += (operationsState.intelXp / 10).floor();
    return score.clamp(0, 100);
  }

  String _reputationTier(int score, List<String> tiers) {
    if (tiers.isEmpty) return 'Unranked';
    if (score >= 80 && tiers.length >= 4) return tiers[3];
    if (score >= 55 && tiers.length >= 3) return tiers[2];
    if (score >= 25 && tiers.length >= 2) return tiers[1];
    return tiers.first;
  }

  Widget _standingTile({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityMilestoneColumn({
    required String title,
    required Color accent,
    required List<String> milestones,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 15, color: accent),
          ),
          const SizedBox(height: AppTheme.spaceS),
          ...milestones.map(
            (milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, color: accent, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      milestone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
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

  Widget _communityScoreBar(int contributionScore) {
    final score = contributionScore.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.lightGreenAccent.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Community Contribution Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: score / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.lightGreenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contributionStat({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.tradingHeading(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeGallery() {
    const badges = <({IconData icon, String label})>[
      (icon: Icons.military_tech_rounded, label: 'Beta Access'),
      (icon: Icons.route_rounded, label: 'Pathfinder'),
      (icon: Icons.local_fire_department_rounded, label: 'Trailblazer'),
      (icon: Icons.diamond_rounded, label: 'Supporter'),
      (icon: Icons.workspace_premium_rounded, label: 'Trusted'),
      (icon: Icons.verified_rounded, label: 'Verified Trader'),
      (icon: Icons.handshake_rounded, label: 'Good Trade'),
      (icon: Icons.groups_rounded, label: 'Squad Ready'),
      (icon: Icons.radar_rounded, label: 'Intel Dropper'),
      (icon: Icons.auto_awesome_rounded, label: 'Collector'),
    ];

    return _profilePanel(
      accent: AppTheme.neonCyan,
      title: 'Badges',
      icon: Icons.auto_awesome_rounded,
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: badges
            .map((badge) => _badgeThumb(icon: badge.icon, label: badge.label))
            .toList(growable: false),
      ),
    );
  }

  Widget _loadoutPreview() {
    return _profilePanel(
      accent: AppTheme.neonPink,
      title: 'Favourite Loadout',
      icon: Icons.inventory_2_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Public preview of primary, secondary, shield, augment and five favourite equipment slots.',
            style: TextStyle(color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            children: [
              Expanded(child: _loadoutSlot('Primary', Icons.gps_fixed_rounded)),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: _loadoutSlot('Secondary', Icons.flash_on_rounded),
              ),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: _loadoutSlot('Utility', Icons.blur_circular_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profilePanel({
    required Color accent,
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: accent.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: accent, size: 18),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );
  }

  Widget _profileEmptyState({
    required IconData icon,
    required String title,
    required String copy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: _openProfileEditor, child: const Text('Add')),
        ],
      ),
    );
  }

  Widget _profileChip({
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppTheme.tradingPillDecoration(color: accent),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _archetypeBadge({
    required IconData icon,
    required String label,
    required String copy,
  }) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.neonPink, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            copy,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _badgeThumb({required IconData icon, required String label}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(label, style: const TextStyle(color: Colors.white)),
          content: Icon(icon, size: 72, color: AppTheme.neonCyan),
        ),
      ),
      child: Container(
        width: 64,
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.neonCyan, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadoutSlot(String label, IconData icon) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        AppTheme.spaceS,
        AppTheme.spaceM,
        AppTheme.spaceL,
      ),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'Not set' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceM,
          AppTheme.spaceS,
          AppTheme.spaceM,
          AppTheme.spaceL,
        ),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: Colors.white.withValues(alpha: 0.10),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, color: AppTheme.neonPink),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.tradingHeading(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
