import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class BlueprintBottomDockLayout extends StatelessWidget {
  const BlueprintBottomDockLayout({
    super.key,
    required this.progress,
    required this.filters,
    required this.search,
    required this.menuBar,
  });

  final Widget progress;
  final Widget filters;
  final Widget search;
  final Widget menuBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        AppTheme.spaceM,
        AppTheme.spaceM,
        AppTheme.spaceL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
            Colors.black.withValues(alpha: 0.98),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.08),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            progress,
            const SizedBox(height: AppTheme.spaceS),
            filters,
            const SizedBox(height: AppTheme.spaceS),
            search,
            const SizedBox(height: AppTheme.spaceM),
            menuBar,
          ],
        ),
      ),
    );
  }
}
