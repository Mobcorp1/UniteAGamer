import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              initialValue: server,
              items: servers.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (v) => setState(() => server = v as String),
              decoration: const InputDecoration(labelText: 'Server Preference'),
            ),
            SwitchListTile(
              value: crossplay,
              onChanged: (v) => setState(() => crossplay = v),
              title: const Text('Crossplay Enabled'),
            ),
          ],
        ),
      ),
    );
  }
}
