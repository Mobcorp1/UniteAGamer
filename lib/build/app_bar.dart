import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UagAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showLogout = true,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
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
    final user = FirebaseAuth.instance.currentUser;

    final baseActions = <Widget>[
      ...(actions ?? const <Widget>[]),
      if (user != null)
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? <String, dynamic>{};
            final adminMode = data['isAdmin'] == true || data['isDev'] == true;

            if (!adminMode) return const SizedBox.shrink();

            return IconButton(
              tooltip: 'Admin Console',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed(AdminConsoleScreen.routeName);
              },
            );
          },
        ),
      if (showLogout)
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _logout(context),
        ),
    ];

    return AppBar(
      leading: leading,
      titleSpacing: 16,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
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
