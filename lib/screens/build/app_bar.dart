import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UagAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogout = true,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogout;
  final bool centerTitle;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final baseActions = <Widget>[
      ...(actions ?? const <Widget>[]),
      if (showLogout)
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _logout(context),
        ),
    ];

    return AppBar(
      titleSpacing: 16,
      centerTitle: centerTitle,
      backgroundColor: AppTheme.darkBackground,
      iconTheme: const IconThemeData(color: AppTheme.neonPink),
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTheme.neonTextStyle(
              fontSize: 24,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: AppTheme.tradingMutedText,
                  isBold: false,
                ),
              ),
            ),
        ],
      ),
      actions: baseActions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        subtitle != null && subtitle!.trim().isNotEmpty
            ? kToolbarHeight + 6
            : kToolbarHeight,
      );
}
