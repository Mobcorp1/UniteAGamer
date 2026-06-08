import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ProfileSettingsScreen extends StatefulWidget {
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
      fillColor: Colors.black.withValues(alpha: 0.42),
      labelStyle: AppTheme.bodyTextStyle(
        fontSize: 14,
        color: Colors.white70,
        isBold: true,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.neonCyan.withValues(alpha: 0.34),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.8),
      ),
    );
  }

  Widget _background() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppTheme.darkBackground),
        ),
        Container(color: Colors.black.withValues(alpha: 0.62)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.88),
                AppTheme.darkBackground.withValues(alpha: 0.52),
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 16),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.86),
              isBold: true,
            ).copyWith(letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _sectionShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.08),
            blurRadius: 26,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _crossplayCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => crossplay = !crossplay),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: crossplay
                ? AppTheme.neonCyan.withValues(alpha: 0.58)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.44),
                ),
              ),
              child: const Icon(
                Icons.sync_alt_rounded,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crossplay Enabled'.toUpperCase(),
                    style: AppTheme.neonTextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      isBold: true,
                    ).copyWith(letterSpacing: 0.9),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Allow matches and trading preferences across supported platforms.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ).copyWith(height: 1.28),
                  ),
                ],
              ),
            ),
            Switch(
              value: crossplay,
              activeThumbColor: AppTheme.neonCyan,
              activeTrackColor: AppTheme.neonCyan.withValues(alpha: 0.28),
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
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.62),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Profile Settings',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _background()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 700 ? 18 : 28,
                    22,
                    constraints.maxWidth < 700 ? 18 : 28,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _chip('Account Preferences', Icons.tune_rounded),
                              _chip('Matchmaking', Icons.group_work_rounded),
                              _chip('Trading Ready', Icons.handshake_rounded),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'COMMAND PROFILE',
                            style: AppTheme.heroTextStyle(
                              fontSize: constraints.maxWidth < 700 ? 34 : 46,
                              color: Colors.white,
                            ).copyWith(letterSpacing: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tune your trader preferences before you enter the hub.',
                            style: AppTheme.bodyTextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              isBold: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _sectionShell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGION ROUTING',
                                  style: AppTheme.neonTextStyle(
                                    fontSize: 18,
                                    color: AppTheme.neonCyan,
                                    isBold: true,
                                  ).copyWith(letterSpacing: 1.1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose the closest server preference for smoother sessions, listings and squad matching.',
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ).copyWith(height: 1.28),
                                ),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<String>(
                                  initialValue: server,
                                  dropdownColor: AppTheme.cardBackgroundAlt,
                                  decoration: _input('Server Preference'),
                                  iconEnabledColor: AppTheme.neonCyan,
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    isBold: true,
                                  ),
                                  items: servers
                                      .map(
                                        (s) => DropdownMenuItem<String>(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => server = v);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _crossplayCard(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.36),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.neonPink.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.neonPink,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'More profile controls will unlock as the wider UAG systems go live.',
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      isBold: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
