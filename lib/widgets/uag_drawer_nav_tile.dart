import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class UagDrawerNavTile extends StatelessWidget {
  const UagDrawerNavTile({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

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
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: selected ? AppTheme.neonPink : Colors.white54,
      ),
      onTap: onTap,
    );
  }
}
