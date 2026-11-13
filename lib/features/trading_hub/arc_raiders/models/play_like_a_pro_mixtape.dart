import 'package:flutter/material.dart';

class PlayLikeAProMixtape {
  const PlayLikeAProMixtape({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.purpose,
    required this.youtubePlaylistId,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String purpose;
  final String youtubePlaylistId;
  final IconData icon;

  bool get isConfigured => youtubePlaylistId.trim().isNotEmpty;

  Uri get youtubeUri =>
      Uri.parse('https://www.youtube.com/playlist?list=$youtubePlaylistId');
}
