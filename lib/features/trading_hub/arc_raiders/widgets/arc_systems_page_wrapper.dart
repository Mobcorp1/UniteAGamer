import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';

class ArcSystemsPageWrapper extends StatelessWidget {
  const ArcSystemsPageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ArcBlueprintGridBackground(),
        SafeArea(
          child: ArcPageViewport(width: ArcPageWidth.wide, child: child),
        ),
      ],
    );
  }
}
