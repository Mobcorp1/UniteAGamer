import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

class ArcSystemsPageWrapper extends StatelessWidget {
  const ArcSystemsPageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const UagCinematicBackground(),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
