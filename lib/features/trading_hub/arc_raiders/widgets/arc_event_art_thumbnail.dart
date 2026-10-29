import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/arc_event_artwork.dart';

/// Bounded card illustration with graceful fallback on missing assets.
class ArcEventArtThumbnail extends StatelessWidget {
  const ArcEventArtThumbnail({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: assetPath.endsWith('.svg')
          ? SvgPicture.asset(
              assetPath,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => _fallback(),
              errorBuilder: (_, _, _) => _fallback(),
            )
          : Image.asset(
              assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _fallback(),
            ),
    ),
  );

  Widget _fallback() => Image.asset(
    ArcEventArtwork.fallback,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: Color(0xFF171C35),
      child: Center(
        child: Icon(Icons.radar_rounded, color: Color(0xFF6FDDE4)),
      ),
    ),
  );
}
