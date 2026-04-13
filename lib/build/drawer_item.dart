import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String routeName;
  final Color? iconColor;
  final Color? textColor;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    required this.routeName,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? AppTheme.neonPink;
    final resolvedTextColor = textColor ?? AppTheme.neonCyan;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      },
      splashColor: AppTheme.neonPink.withValues(alpha: 0.25),
      highlightColor: AppTheme.neonCyan.withValues(alpha: 0.20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spaceM,
          horizontal: AppTheme.spaceL,
        ),
        child: Row(
          children: [
            Icon(icon, color: resolvedIconColor),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      title,
                      textStyle: AppTheme.drawerItemTextStyle(
                        color: resolvedTextColor,
                      ),
                      speed: const Duration(milliseconds: 80),
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
