import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_mixtape.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class PlayLikeAProMixtapePlayerScreen extends StatefulWidget {
  const PlayLikeAProMixtapePlayerScreen({super.key, required this.mixtape});

  final PlayLikeAProMixtape mixtape;

  @override
  State<PlayLikeAProMixtapePlayerScreen> createState() =>
      _PlayLikeAProMixtapePlayerScreenState();
}

class _PlayLikeAProMixtapePlayerScreenState
    extends State<PlayLikeAProMixtapePlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        privacyEnhancedMode: true,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cuePlaylist(
        list: <String>[widget.mixtape.youtubePlaylistId],
        listType: ListType.playlist,
      );
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openYouTube() async {
    await launchUrl(
      widget.mixtape.youtubeUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mix = widget.mixtape;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          mix.title,
          style: AppTheme.neonTextStyle(
            fontSize: 23,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open playlist in YouTube',
            onPressed: _openYouTube,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: ArcRaidersPageScaffold(
        maxWidth: 980,
        showAdBanner: false,
        child: ListView(
          children: [
            _MixtapeCover(mixtape: mix),
            const SizedBox(height: AppTheme.spaceL),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: AppTheme.tradingCardDecoration(
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.32),
                radius: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOW PLAYING',
                    style: AppTheme.tradingHeading(
                      fontSize: 16,
                      color: AppTheme.neonPink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  const Text(
                    'The UAG Mixtape interface frames the ritual; playback remains a visible YouTube embed so the artist video, YouTube controls and attribution are not obscured.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: YoutubePlayer(
                      controller: _controller,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }
}

class _MixtapeCover extends StatelessWidget {
  const _MixtapeCover({required this.mixtape});

  final PlayLikeAProMixtape mixtape;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.42),
        radius: 26,
      ),
      child: Column(
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.neonCyan, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.25),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Icon(mixtape.icon, color: AppTheme.neonCyan, size: 54),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'UAG MIXTAPES',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            mixtape.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.tradingHeading(
              fontSize: 30,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            mixtape.purpose,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            mixtape.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
