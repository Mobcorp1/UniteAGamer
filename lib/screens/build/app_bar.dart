import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';

class UagAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double toolbarHeight = 60;

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
    final compact =
        MediaQuery.sizeOf(context).width < ArcLayoutTokens.compactBreakpoint;
    final fullBrandTitle = title.trim().toUpperCase() == 'UAG ARC RAIDERS HUB';
    final baseActions = <Widget>[
      IconButton(
        tooltip: 'Communications',
        icon: const Icon(Icons.notifications_none_rounded, size: 19),
        onPressed: () => Navigator.of(
          context,
        ).pushNamed(TradingNotificationsScreen.routeName),
      ),
      if (!compact)
        IconButton(
          tooltip: 'Help Centre',
          icon: const Icon(Icons.help_outline_rounded, size: 19),
          onPressed: () =>
              Navigator.of(context).pushNamed(ArcHelpCentreScreen.routeName),
        ),
      ...(actions ?? const <Widget>[]),
      if (showLogout)
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded, size: 19),
          onPressed: () => _logout(context),
        ),
    ];

    return AppBar(
      toolbarHeight: toolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: compact ? 6 : 10,
      centerTitle: centerTitle,
      backgroundColor: ArcUiTokens.background.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(
        color: ArcUiTokens.primaryAccent,
        size: 21,
      ),
      actionsIconTheme: const IconThemeData(
        color: ArcUiTokens.textSecondary,
        size: 20,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.14),
        ),
      ),
      title: fullBrandTitle && compact
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'UAG ARC',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: ArcUiTokens.pageTitle(
                    fontSize: 13.5,
                    color: ArcUiTokens.primaryAccent,
                  ).copyWith(height: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  'RAIDERS HUB',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: ArcUiTokens.pageTitle(
                    fontSize: 13.5,
                    color: ArcUiTokens.textPrimary,
                  ).copyWith(height: 1.0),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullBrandTitle ? 'UAG ARC RAIDERS HUB' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.pageTitle(
                    fontSize: compact ? 17 : 19,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty && !compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.body(
                        fontSize: 10.5,
                        color: ArcUiTokens.textTertiary,
                        weight: FontWeight.w500,
                      ).copyWith(height: 1.05),
                    ),
                  ),
              ],
            ),
      actions: baseActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(61);
}
