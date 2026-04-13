import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const UagAppBar({super.key, required this.title});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.neonTextStyle(
          fontSize: 24,
          color: AppTheme.neonCyan,
          isBold: true,
        ),
      ),
      backgroundColor: AppTheme.darkBackground,
      iconTheme: const IconThemeData(color: AppTheme.neonPink),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
