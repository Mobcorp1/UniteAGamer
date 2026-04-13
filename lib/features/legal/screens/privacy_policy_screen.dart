import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
            ),
            child: const Text(
              'We collect account information, profile details, referral data, and app usage data needed to run the service.\n\n'
              'Information may include email, display name, public trader profile data, scheduling data, and moderation records.\n\n'
              'Data is stored using Firebase services and may later be linked to payment providers if subscriptions are enabled.\n\n'
              'Users can request corrections or deletion subject to legal and fraud-prevention requirements.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
