import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagDrawerNavTile extends StatelessWidget {
  const UagDrawerNavTile({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
      ),
      title: Text(
        title,
        style: AppTheme.bodyTextStyle(
          fontSize: 15,
          color: selected ? AppTheme.neonPink : Colors.white,
          isBold: selected,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0) ...[
            _DrawerBadge(count: badgeCount, selected: selected),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: selected ? AppTheme.neonPink : Colors.white54,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _DrawerBadge extends StatelessWidget {
  const _DrawerBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppTheme.neonPink : AppTheme.neonCyan;
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.bodyTextStyle(
          fontSize: 11,
          color: accent,
          isBold: true,
        ),
      ),
    );
  }
}
