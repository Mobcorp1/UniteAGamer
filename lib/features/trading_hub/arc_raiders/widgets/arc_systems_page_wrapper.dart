import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSystemsPageWrapper extends StatelessWidget {
  const ArcSystemsPageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF050816),
            AppTheme.neonCyan.withValues(alpha: 0.08),
            const Color(0xFF04050C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
