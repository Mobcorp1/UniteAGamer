import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';

/// Uses the single global cinematic backdrop owned by MaterialApp.builder.
class ArcSystemsPageWrapper extends StatelessWidget {
  const ArcSystemsPageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ArcPageViewport(width: ArcPageWidth.wide, child: child),
    );
  }
}
