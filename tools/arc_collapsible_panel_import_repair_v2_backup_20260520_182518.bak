import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class ArcCollapsiblePanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final EdgeInsetsGeometry margin;

  const ArcCollapsiblePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.subtitle,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: expanded
                ? AppTheme.neonCyan.withOpacity(0.65)
                : AppTheme.neonCyan.withOpacity(0.25),
          ),
          boxShadow: expanded
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withOpacity(0.16),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: expanded ? AppTheme.neonCyan : AppTheme.neonPink,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: expanded
                  ? Padding(
                      key: const ValueKey('expanded'),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: child,
                    )
                  : const SizedBox.shrink(key: ValueKey('collapsed')),
            ),
          ],
        ),
      ),
    );
  }
}
