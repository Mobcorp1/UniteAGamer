import 'package:flutter/material.dart';

/// Legacy compatibility widget.
///
/// Static repeated UAG watermarking is intentionally disabled across the app.
/// Screens may continue to reference this widget during migration without
/// reintroducing the old tiled-logo treatment over cinematic imagery.
class StaticWatermark extends StatelessWidget {
  const StaticWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
