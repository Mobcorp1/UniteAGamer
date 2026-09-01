import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/notifications/widgets/uag_notification_preferences_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_personalisation_preferences_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ProfileSettingsScreen extends StatefulWidget {
  static const routeName = '/profile-settings';

  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String server = 'Automatic';
  bool crossplay = true;

  final servers = [
    'Automatic',
    'Europe',
    'North America',
    'Asia',
    'South America',
    'Oceania',
  ];

  InputDecoration _input(String label) {
    return AppTheme.inputDecoration(label).copyWith(
      filled: true,
      fillColor: ArcUiTokens.surfaceInteractive.withValues(alpha: 0.74),
      labelStyle: ArcUiTokens.body(
        fontSize: 14,
        color: ArcUiTokens.textSecondary,
        weight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        borderSide: BorderSide(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.34),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        borderSide: const BorderSide(
          color: ArcUiTokens.primaryAccent,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: ArcUiTokens.primaryAccent),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ArcUiTokens.primaryAccent, size: 16),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
          ),
        ],
      ),
    );
  }

  Widget _sectionShell({required Widget child}) {
    return ArcTacticalPanel(accent: ArcUiTokens.primaryAccent, child: child);
  }

  Widget _crossplayCard() {
    final activeColor = crossplay
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
      onTap: () => setState(() => crossplay = !crossplay),
      child: Container(
        padding: const EdgeInsets.all(ArcUiTokens.gapM),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.interactive,
          accent: activeColor,
          borderOpacity: crossplay ? 0.42 : 0.16,
          selected: crossplay,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.raised,
                accent: activeColor,
                radius: ArcUiTokens.radiusS,
                borderOpacity: 0.34,
              ),
              child: Icon(Icons.sync_alt_rounded, color: activeColor),
            ),
            const SizedBox(width: ArcUiTokens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crossplay Enabled'.toUpperCase(),
                    style: ArcUiTokens.cardTitle(fontSize: 15),
                  ),
                  const SizedBox(height: ArcUiTokens.gapXS),
                  Text(
                    'Allow matches and trading preferences across supported platforms.',
                    style: ArcUiTokens.bodySmall(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: crossplay,
              activeThumbColor: ArcUiTokens.primaryAccent,
              activeTrackColor: ArcUiTokens.primaryAccent.withValues(
                alpha: 0.28,
              ),
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white12,
              onChanged: (value) => setState(() => crossplay = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Profile Settings',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 920,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          ArcTacticalPanel(
            icon: Icons.manage_accounts_outlined,
            title: 'COMMAND PROFILE',
            subtitle: 'Tune your trader preferences before you enter the hub.',
            accent: ArcUiTokens.primaryAccent,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('Account Preferences', Icons.tune_rounded),
                _chip('Matchmaking', Icons.group_work_rounded),
                _chip('Trading Ready', Icons.handshake_rounded),
              ],
            ),
          ),
          _sectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGION ROUTING',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 16,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'Choose the closest server preference for smoother sessions, listings and squad matching.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapL),
                DropdownButtonFormField<String>(
                  initialValue: server,
                  dropdownColor: ArcUiTokens.surfaceOverlay,
                  decoration: _input('Server Preference'),
                  iconEnabledColor: ArcUiTokens.primaryAccent,
                  style: ArcUiTokens.body(
                    fontSize: 15,
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                  items: servers
                      .map(
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => server = v);
                  },
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                _crossplayCard(),
              ],
            ),
          ),
          const ArcPersonalisationPreferencesPanel(),
          const UagNotificationPreferencesPanel(),
          const ArcTacticalPanel(
            icon: Icons.info_outline_rounded,
            title: 'Profile Controls',
            subtitle:
                'More profile controls will unlock as the wider UAG systems go live.',
            accent: ArcUiTokens.secondaryAccent,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
