import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_mixtape.dart';

class PlayLikeAProMixtapeLibrary {
  const PlayLikeAProMixtapeLibrary._();

  static const List<PlayLikeAProMixtape> mixtapes = [
    PlayLikeAProMixtape(
      id: 'uag_activation',
      title: 'UAG Activation',
      subtitle: 'Pre-game energy and momentum.',
      purpose: 'ACTIVATE',
      youtubePlaylistId: 'PLR-rqCCVCzbNfhIf2DukP8P43jTL1Wuz0',
      icon: Icons.flash_on_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_focus',
      title: 'UAG Focus',
      subtitle: 'Lower-distraction focus before a demanding session.',
      purpose: 'LOCK IN',
      youtubePlaylistId: 'PLR-rqCCVCzbPbpCh61nluEMW-p5DxL2qw',
      icon: Icons.center_focus_strong_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_flow',
      title: 'UAG Flow',
      subtitle: 'Long-session rhythm and sustained momentum.',
      purpose: 'FLOW',
      youtubePlaylistId: 'PLR-rqCCVCzbMcMvyg_inJUKzXKvMwPF0B',
      icon: Icons.waves_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_dominate',
      title: 'UAG Dominate',
      subtitle: 'Competitive confidence and pressure energy.',
      purpose: 'COMPETE',
      youtubePlaylistId: 'PLR-rqCCVCzbPpWWWQkvU21_UuXMWzs_lT',
      icon: Icons.emoji_events_outlined,
    ),
    PlayLikeAProMixtape(
      id: 'uag_rage',
      title: 'UAG Rage',
      subtitle: 'High-energy action and FPS intensity.',
      purpose: 'HYPE',
      youtubePlaylistId: 'PLR-rqCCVCzbPG4nqEtaRls8_ORnm333lE',
      icon: Icons.whatshot_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_gaming',
      title: 'UAG Gaming',
      subtitle: 'Gaming-first soundtrack energy.',
      purpose: 'GAME',
      youtubePlaylistId: 'PLR-rqCCVCzbPvao0OELMnRHhAeAiy3oln',
      icon: Icons.sports_esports_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_reset',
      title: 'UAG Reset',
      subtitle: 'Bring nerves, frustration and stimulation down.',
      purpose: 'RESET',
      youtubePlaylistId: 'PLR-rqCCVCzbP3bTVfBoqXkaBE78XtW8K-',
      icon: Icons.self_improvement_rounded,
    ),
    PlayLikeAProMixtape(
      id: 'uag_wind_down',
      title: 'UAG Wind Down',
      subtitle: 'Post-session decompression and lower stimulation.',
      purpose: 'RECOVER',
      youtubePlaylistId: 'PLR-rqCCVCzbNXkNyJvHhinmVrVlSU81f4',
      icon: Icons.nights_stay_outlined,
    ),
    PlayLikeAProMixtape(
      id: 'uag_nostalgia',
      title: 'UAG Nostalgia',
      subtitle: 'Old-school gaming memory and comfort tracks.',
      purpose: 'NOSTALGIA',
      youtubePlaylistId: 'PLR-rqCCVCzbNjdBi-y5ZeanEMSXNv2hgG',
      icon: Icons.videogame_asset_outlined,
    ),
  ];

  static PlayLikeAProMixtape byId(String id) => mixtapes.firstWhere(
    (mixtape) => mixtape.id == id,
    orElse: () => mixtapes.first,
  );
}
