import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcMatchRiderScreen extends StatefulWidget {
  const ArcMatchRiderScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/match-a-raider';

  @override
  State<ArcMatchRiderScreen> createState() => _ArcMatchRiderScreenState();
}

class _ArcMatchRiderScreenState extends State<ArcMatchRiderScreen> {
  static const List<String> _playstyleOptions = [
    'PvE',
    'PvP',
    'PvE + PvP Aggressive',
    'PvE + PvP Defensive',
  ];

  static const List<String> _mapOptions = [
    'Buried City',
    'The Blue Gate',
    'Spaceport',
    'Dam Battlegrounds',
    'Stella Montis',
    'Riven Tides',
  ];

  static const List<String> _modeOptions = [
    'Casual runs',
    'Ranked mindset',
    'Night raids',
    'High-risk loot routes',
    'Objective-focused raids',
  ];

  static const List<String> _goalOptions = [
    'PvP',
    'PvE',
    'Blueprint farming',
    'Trading',
    'Event hunting',
    'Resource farming',
    'General looting',
    'Trials',
    'Quests',
  ];

  static const List<String> _commsOptions = [
    'Mic',
    'Ping',
    'Chat while gaming',
  ];

  static const List<String> _squadOptions = [
    'Solo company only',
    'Duos',
    'Trios',
    'Solo vs squads',
  ];

  final ArcMatchRiderRepository _repository = ArcMatchRiderRepository();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _inviteNoteController = TextEditingController();

  ArcMatchRiderProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.loadMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _notesController.text = profile.notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _inviteNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      final updated = profile.copyWith(notes: _notesController.text.trim());
      await _repository.saveMyProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match-a-Raider profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  Future<void> _showInviteDialog(ArcMatchCandidate candidate) async {
    _inviteNoteController.text = 'Looking for a ${candidate.profile.squadPreferences.isNotEmpty ? candidate.profile.squadPreferences.first.toLowerCase() : 'solid run'} with ${candidate.profile.goals.isNotEmpty ? candidate.profile.goals.first.toLowerCase() : 'good comms'}.';
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackgroundAlt,
        title: Text(
          'Invite ${candidate.profile.title}',
          style: AppTheme.titleTextStyle(fontSize: 22, color: AppTheme.neonCyan, isBold: true),
        ),
        content: TextField(
          controller: _inviteNoteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Quick note',
            hintText: 'Say what run you want to do.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send invite')),
        ],
      ),
    );

    if (shouldSend != true || !mounted || _profile == null) return;

    try {
      await _repository.sendInvite(
        sender: _profile!,
        recipient: candidate.profile,
        note: _inviteNoteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite sent to ${candidate.profile.title}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send invite: $e')),
      );
    }
  }

  Future<void> _respondToInvite(ArcMatchRiderInvite invite, String status) async {
    try {
      await _repository.respondToInvite(invite, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite ${status == 'accepted' ? 'accepted' : status == 'declined' ? 'declined' : 'updated'}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update invite: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Match-a-Raider',
          style: AppTheme.neonTextStyle(fontSize: 25, color: AppTheme.neonCyan, isBold: true),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null || profile == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: Text(
                  _error ?? 'Could not load Match-a-Raider.',
                  style: AppTheme.bodyTextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    children: [
                      _buildHeroCard(profile),
                      const SizedBox(height: AppTheme.spaceL),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 900;
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 11, child: _buildProfileEditor(profile)),
                                const SizedBox(width: AppTheme.spaceL),
                                Expanded(flex: 12, child: _buildFeedAndInvites(profile)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildProfileEditor(profile),
                              const SizedBox(height: AppTheme.spaceL),
                              _buildFeedAndInvites(profile),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ArcMatchRiderProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find the right raider for the right run.',
            style: AppTheme.neonTextStyle(fontSize: 28, color: AppTheme.neonCyan, isBold: true),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Set your current ARC Raiders vibe, filter by shared goals, and send quick squad-up requests without bolting on a giant social layer.',
            style: AppTheme.bodyTextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatusPill(profile.lookingNow ? 'Looking now' : 'Available later', profile.lookingNow ? AppTheme.neonCyan : AppTheme.warningAmber),
              _buildStatusPill(profile.visibleInSearch ? 'Visible in search' : 'Hidden', profile.visibleInSearch ? AppTheme.neonPink : Colors.white54),
              if (profile.platform.isNotEmpty) _buildStatusPill(profile.platform, Colors.white70),
              if (profile.region.isNotEmpty) _buildStatusPill(profile.region, Colors.white70),
              _buildStatusPill('Server: ${profile.serverPreference}', Colors.white70),
              _buildStatusPill(profile.crossplayEnabled ? 'Crossplay ON' : 'Crossplay OFF', profile.crossplayEnabled ? AppTheme.neonCyan : AppTheme.warningAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileEditor(ArcMatchRiderProfile profile) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(radius: 20),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Match Profile',
            style: AppTheme.neonTextStyle(fontSize: 24, color: AppTheme.neonCyan, isBold: true),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Choose the kind of run you want so the feed can surface raiders that actually fit what you are trying to do.',
            style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceL),
          _buildSection('Playstyle', _playstyleOptions, profile.playstyles, (values) => _setProfile(profile.copyWith(playstyles: values))),
          _buildSection('Preferred maps', _mapOptions, profile.preferredMaps, (values) => _setProfile(profile.copyWith(preferredMaps: values))),
          _buildSection('Preferred modes', _modeOptions, profile.preferredModes, (values) => _setProfile(profile.copyWith(preferredModes: values))),
          _buildSection('Goals', _goalOptions, profile.goals, (values) => _setProfile(profile.copyWith(goals: values))),
          _buildSection('Comms', _commsOptions, profile.comms, (values) => _setProfile(profile.copyWith(comms: values))),
          _buildSection('Squad / run preference', _squadOptions, profile.squadPreferences, (values) => _setProfile(profile.copyWith(squadPreferences: values))),
          const SizedBox(height: AppTheme.spaceM),
          SwitchListTile.adaptive(
            value: profile.lookingNow,
            onChanged: (value) => _setProfile(profile.copyWith(lookingNow: value)),
            activeThumbColor: AppTheme.neonPink,
            contentPadding: EdgeInsets.zero,
            title: Text('Looking now', style: AppTheme.titleTextStyle(fontSize: 18, color: AppTheme.neonCyan, isBold: true)),
            subtitle: Text('Turn this on when you want to surface near the top of the feed.', style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70)),
          ),
          SwitchListTile.adaptive(
            value: profile.visibleInSearch,
            onChanged: (value) => _setProfile(profile.copyWith(visibleInSearch: value)),
            activeThumbColor: AppTheme.neonPink,
            contentPadding: EdgeInsets.zero,
            title: Text('Visible in search', style: AppTheme.titleTextStyle(fontSize: 18, color: AppTheme.neonCyan, isBold: true)),
            subtitle: Text('Hide yourself when you do not want fresh invites.', style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70)),
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Quick note',
              hintText: 'Example: After blueprint farming, chill comms, not hard sweating.',
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Match Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedAndInvites(ArcMatchRiderProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMatchesFeed(profile),
        const SizedBox(height: AppTheme.spaceL),
        _buildInvitesPanels(),
      ],
    );
  }

  Widget _buildMatchesFeed(ArcMatchRiderProfile profile) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(radius: 20),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: AppTheme.neonPink),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Live Match Feed', style: AppTheme.neonTextStyle(fontSize: 24, color: AppTheme.neonCyan, isBold: true)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Sorted by shared intent, squad fit, comms, and whether the other raider is looking right now.',
            style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          StreamBuilder<List<ArcMatchCandidate>>(
            stream: _repository.watchCandidates(profile),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Could not load feed: ${snapshot.error}', style: AppTheme.bodyTextStyle(fontSize: 14, color: AppTheme.dangerRed));
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceL),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final matches = snapshot.data!;
              if (matches.isEmpty) {
                return Text(
                  'No raiders match yet. Save your profile and check back after more players opt in.',
                  style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
                );
              }

              return Column(
                children: [
                  for (final candidate in matches.take(10)) ...[
                    _buildMatchCard(candidate),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ArcMatchCandidate candidate) {
    final profile = candidate.profile;
    return ElectricChargeBorder(
      active: profile.lookingNow,
      radius: 18,
      child: Container(
        decoration: AppTheme.tradingCardDecoration(radius: 18),
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.title, style: AppTheme.neonTextStyle(fontSize: 22, color: AppTheme.neonCyan, isBold: true)),
                      const SizedBox(height: 4),
                      Text(
                        [if (profile.platform.isNotEmpty) profile.platform, if (profile.region.isNotEmpty) profile.region, 'Server: ${profile.serverPreference}', profile.crossplayEnabled ? 'Crossplay' : 'No crossplay', if (profile.lookingNow) 'Looking now'].join(' • '),
                        style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill('${candidate.score} match', AppTheme.neonPink),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidate.reasons.map((reason) => _buildStatusPill(reason, Colors.white70)).toList(growable: false),
            ),
            if (profile.notes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceM),
              Text(profile.notes, style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70)),
            ],
            const SizedBox(height: AppTheme.spaceM),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showInviteDialog(candidate),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Invite to team up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesPanels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final incoming = _buildInvitePanel(
          title: 'Incoming Requests',
          stream: _repository.watchIncomingInvites(),
          incoming: true,
        );
        final outgoing = _buildInvitePanel(
          title: 'Outgoing Requests',
          stream: _repository.watchOutgoingInvites(),
          incoming: false,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: incoming), const SizedBox(width: AppTheme.spaceL), Expanded(child: outgoing)],
          );
        }
        return Column(children: [incoming, const SizedBox(height: AppTheme.spaceL), outgoing]);
      },
    );
  }

  Widget _buildInvitePanel({required String title, required Stream<List<ArcMatchRiderInvite>> stream, required bool incoming}) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(radius: 20),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.neonTextStyle(fontSize: 22, color: AppTheme.neonCyan, isBold: true)),
          const SizedBox(height: AppTheme.spaceS),
          StreamBuilder<List<ArcMatchRiderInvite>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Could not load requests: ${snapshot.error}', style: AppTheme.bodyTextStyle(fontSize: 14, color: AppTheme.dangerRed));
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceL),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final invites = snapshot.data!;
              if (invites.isEmpty) {
                return Text('No ${incoming ? 'incoming' : 'outgoing'} requests yet.', style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70));
              }
              return Column(
                children: [
                  for (final invite in invites.take(8)) ...[
                    _buildInviteCard(invite, incoming: incoming),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(ArcMatchRiderInvite invite, {required bool incoming}) {
    final active = invite.status == 'pending';
    return ElectricChargeBorder(
      active: active,
      radius: 16,
      child: Container(
        decoration: AppTheme.tradingCardDecoration(radius: 16),
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incoming ? invite.senderName : invite.recipientName,
                    style: AppTheme.titleTextStyle(fontSize: 18, color: AppTheme.neonCyan, isBold: true),
                  ),
                ),
                _buildStatusPill(invite.status.toUpperCase(), invite.status == 'accepted' ? AppTheme.neonCyan : invite.status == 'declined' ? AppTheme.dangerRed : invite.status == 'cancelled' ? Colors.white54 : AppTheme.warningAmber),
              ],
            ),
            if (invite.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(invite.note, style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70)),
            ],
            if (invite.status == 'pending') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: incoming
                    ? [
                        ElevatedButton(onPressed: () => _respondToInvite(invite, 'accepted'), child: const Text('Accept')),
                        OutlinedButton(onPressed: () => _respondToInvite(invite, 'declined'), child: const Text('Decline')),
                      ]
                    : [
                        OutlinedButton(onPressed: () => _respondToInvite(invite, 'cancelled'), child: const Text('Cancel request')),
                      ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> options, List<String> selected, ValueChanged<List<String>> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleTextStyle(fontSize: 18, color: AppTheme.neonPink, isBold: true)),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  selected: selected.contains(option),
                  label: Text(option),
                  selectedColor: AppTheme.neonPink.withValues(alpha: 0.18),
                  checkmarkColor: AppTheme.neonCyan,
                  labelStyle: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: selected.contains(option) ? AppTheme.neonCyan : Colors.white70,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: (selected.contains(option) ? AppTheme.neonPink : AppTheme.neonCyan).withValues(alpha: 0.55)),
                  ),
                  onSelected: (isSelected) {
                    final values = [...selected];
                    if (isSelected) {
                      if (!values.contains(option)) values.add(option);
                    } else {
                      values.remove(option);
                    }
                    onChanged(values);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        text,
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
      ),
    );
  }

  void _setProfile(ArcMatchRiderProfile value) {
    setState(() => _profile = value);
  }
}
