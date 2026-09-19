import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_game_platform_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcSocialLinksEditor extends StatefulWidget {
  const ArcSocialLinksEditor({
    super.key,
    required this.initialLinks,
    required this.onChanged,
    this.selectedGamePlatforms = const <String>{},
  });

  final List<ArcProfileSocialLink> initialLinks;
  final ValueChanged<List<ArcProfileSocialLink>> onChanged;
  final Set<String> selectedGamePlatforms;

  @override
  State<ArcSocialLinksEditor> createState() => _ArcSocialLinksEditorState();
}

class _ArcSocialLinksEditorState extends State<ArcSocialLinksEditor> {
  static const _communityPlatforms = <ArcSocialPlatform>[
    ArcSocialPlatform.discord,
    ArcSocialPlatform.tiktok,
    ArcSocialPlatform.twitch,
    ArcSocialPlatform.youtube,
    ArcSocialPlatform.kick,
  ];

  late final Map<ArcSocialPlatform, TextEditingController> _controllers;
  late Map<ArcSocialPlatform, bool> _hidden;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final platform in ArcSocialPlatform.values)
        platform: TextEditingController(),
    };
    _applyInitialLinks(widget.initialLinks);
  }

  @override
  void didUpdateWidget(covariant ArcSocialLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLinks != widget.initialLinks) {
      _applyInitialLinks(widget.initialLinks);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyInitialLinks(List<ArcProfileSocialLink> links) {
    final merged = {
      for (final link in ArcProfileSocialLinks.merge(links))
        link.platform: link,
    };
    _hidden = <ArcSocialPlatform, bool>{};
    for (final platform in ArcSocialPlatform.values) {
      final link = merged[platform];
      _controllers[platform]!.text = link?.value ?? '';
      _hidden[platform] = link?.hidden ?? false;
    }
  }

  ArcProfileSocialLink _linkFor(ArcSocialPlatform platform) {
    return ArcProfileSocialLink(
      platform: platform,
      value: _controllers[platform]!.text,
      hidden: _hidden[platform] ?? false,
    );
  }

  void _emitChanged() {
    widget.onChanged(
      ArcProfileSocialLinks.merge(ArcSocialPlatform.values.map(_linkFor)),
    );
  }

  List<ArcSocialPlatform> get _gamingIdentityPlatforms {
    final selected = ArcGamePlatformCatalog.normalize(
      widget.selectedGamePlatforms,
    ).toSet();
    final output = <ArcSocialPlatform>[];
    if (selected.contains(ArcGamePlatformCatalog.playStation)) {
      output.add(ArcSocialPlatform.playStation);
    }
    if (selected.contains(ArcGamePlatformCatalog.xbox)) {
      output.add(ArcSocialPlatform.xbox);
    }
    if (selected.contains(ArcGamePlatformCatalog.pc)) {
      output.addAll(const <ArcSocialPlatform>[
        ArcSocialPlatform.steam,
        ArcSocialPlatform.epicGames,
      ]);
    }
    return output;
  }

  IconData _platformIcon(ArcSocialPlatform platform) {
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

  @override
  Widget build(BuildContext context) {
    final links = ArcSocialPlatform.values
        .map(_linkFor)
        .toList(growable: false);
    final configured = links.where((link) => link.isConfigured).length;
    final public = links.where((link) => link.isPublic).length;
    final gamingPlatforms = _gamingIdentityPlatforms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            accent: ArcUiTokens.secondaryAccent,
            borderOpacity: 0.16,
            radius: ArcUiTokens.radiusM,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 18,
                color: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gaming IDs follow your selected platforms. Social and creator links stay optional.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$public/$configured public',
                style: ArcUiTokens.label(
                  color: configured == 0
                      ? ArcUiTokens.textTertiary
                      : ArcUiTokens.primaryAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'GAMING IDENTITIES',
          style: ArcUiTokens.sectionTitle(
            fontSize: 14,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          gamingPlatforms.isEmpty
              ? 'Choose PlayStation, Xbox or PC in Platform & Server to add the matching gaming IDs.'
              : 'Only IDs that match your active gaming platforms are shown here.',
          style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
        ),
        const SizedBox(height: 9),
        if (gamingPlatforms.isEmpty)
          _emptyGamingIdentityState()
        else
          _platformGrid(gamingPlatforms),
        const SizedBox(height: 16),
        Text(
          'SOCIAL & CREATOR LINKS',
          style: ArcUiTokens.sectionTitle(
            fontSize: 14,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'These are independent of the platform you play on.',
          style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
        ),
        const SizedBox(height: 9),
        _platformGrid(_communityPlatforms),
      ],
    );
  }

  Widget _emptyGamingIdentityState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.10,
        radius: ArcUiTokens.radiusM,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            color: ArcUiTokens.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No gaming platform selected yet.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformGrid(List<ArcSocialPlatform> platforms) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final tileWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final platform in platforms)
              SizedBox(width: tileWidth, child: _platformField(platform)),
          ],
        );
      },
    );
  }

  Widget _platformField(ArcSocialPlatform platform) {
    final link = _linkFor(platform);
    final hidden = _hidden[platform] ?? false;
    final configured = link.isConfigured;
    final accent = configured
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textTertiary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        borderOpacity: configured ? 0.22 : 0.10,
        radius: ArcUiTokens.radiusL,
        selected: configured && !hidden,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                ),
                child: Icon(_platformIcon(platform), color: accent, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      platform.label,
                      style: ArcUiTokens.cardTitle(
                        fontSize: 14,
                        color: ArcUiTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      configured
                          ? (hidden
                                ? 'Saved, hidden from profile'
                                : 'Visible on public profile')
                          : 'Optional',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.label(
                        color: hidden
                            ? ArcUiTokens.secondaryAccent
                            : configured
                            ? ArcUiTokens.primaryAccent
                            : ArcUiTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: hidden
                    ? 'Show ${platform.label} on public profile'
                    : 'Hide ${platform.label} from public profile',
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() => _hidden[platform] = !hidden);
                    _emitChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: ArcUiTokens.chipDecoration(
                      color: hidden
                          ? ArcUiTokens.secondaryAccent
                          : ArcUiTokens.primaryAccent,
                      selected: configured,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hidden
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 15,
                          color: hidden
                              ? ArcUiTokens.secondaryAccent
                              : ArcUiTokens.primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hidden ? 'HIDDEN' : 'PUBLIC',
                          style: ArcUiTokens.label(
                            color: hidden
                                ? ArcUiTokens.secondaryAccent
                                : ArcUiTokens.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[platform],
            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
            validator: (_) => _linkFor(platform).validationError,
            decoration: ArcUiTokens.inputDecoration(
              labelText: 'Username or profile URL',
              hintText: 'Optional',
            ),
            onChanged: (_) {
              setState(() {});
              _emitChanged();
            },
          ),
        ],
      ),
    );
  }
}
