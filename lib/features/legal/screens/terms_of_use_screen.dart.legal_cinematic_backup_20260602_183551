import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Terms of Use')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
            ),
            child: const Text(
              'Use of the app means you agree to the community and trading rules.\n\n'
              'This platform is for blueprint-for-blueprint and in-game trade coordination only. Real-money selling of blueprints, accounts, or in-game items is not allowed.\n\n'
              'Users must not harass, threaten, impersonate, bully, scam, or abuse others. Racism, sexism, hate speech, and targeted abuse are prohibited.\n\n'
              'Unite A Gamer acts only as a platform connecting users. We are not a party to any trade or agreement between users. All trades are completed at the users\' own risk.\n\n'
              'Accounts may be suspended or permanently removed for rule breaches. Bans for misconduct may result in loss of access without refund where legally permitted.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
