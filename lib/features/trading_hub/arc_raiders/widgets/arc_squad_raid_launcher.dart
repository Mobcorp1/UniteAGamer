import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_squad_raid_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_squad_raid_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcSquadRaidLauncher extends StatefulWidget {
  const ArcSquadRaidLauncher({super.key, required this.myDisplayName});

  final String myDisplayName;

  @override
  State<ArcSquadRaidLauncher> createState() => _ArcSquadRaidLauncherState();
}

class _ArcSquadRaidLauncherState extends State<ArcSquadRaidLauncher> {
  final ArcMatchRiderRepository _matchRepository = ArcMatchRiderRepository();
  final ArcSquadRaidRepository _squadRepository = ArcSquadRaidRepository();
  final Set<String> _selectedPeerUids = <String>{};
  ArcSquadRaidFairnessMode _fairness = ArcSquadRaidFairnessMode.balancedSquad;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.secondaryAccent,
        radius: ArcUiTokens.radiusL,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SQUAD RAID INTELLIGENCE',
            style: ArcUiTokens.sectionTitle(
              fontSize: 19,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Accepted Raiders can combine safe progression goals into one shared map run. '
            'Free contributes 1 objective, Essential 5, Premium up to 24. '
            'Raw inventories are never published.',
            style: ArcUiTokens.bodySmall(),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ArcSquadRaidSession>>(
            stream: _squadRepository.watchMySessions(),
            builder: (context, sessionSnapshot) {
              final sessions =
                  sessionSnapshot.data ?? const <ArcSquadRaidSession>[];
              if (sessions.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active squad plans',
                    style: ArcUiTokens.body(
                      color: ArcUiTokens.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (final session in sessions.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${session.squadSize == 3 ? 'Trio' : 'Duo'} · '
                              '${session.fairnessMode.label}',
                              style: ArcUiTokens.bodySmall(),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openSession(session.id),
                            icon: const Icon(Icons.route_rounded, size: 17),
                            label: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                ],
              );
            },
          ),
          StreamBuilder<List<ArcMatchRiderInvite>>(
            stream: _matchRepository.watchIncomingInvites(),
            builder: (context, incomingSnapshot) {
              return StreamBuilder<List<ArcMatchRiderInvite>>(
                stream: _matchRepository.watchOutgoingInvites(),
                builder: (context, outgoingSnapshot) {
                  final peers = _acceptedPeers(
                    incomingSnapshot.data ?? const <ArcMatchRiderInvite>[],
                    outgoingSnapshot.data ?? const <ArcMatchRiderInvite>[],
                  );
                  if (peers.isEmpty) {
                    return Text(
                      'Accept a Match Raider invite to create a shared duo/trio run.',
                      style: ArcUiTokens.bodySmall(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build a squad run',
                        style: ArcUiTokens.body(
                          color: ArcUiTokens.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      for (final peer in peers)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: _selectedPeerUids.contains(peer.uid),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                if (_selectedPeerUids.length < 2) {
                                  _selectedPeerUids.add(peer.uid);
                                }
                              } else {
                                _selectedPeerUids.remove(peer.uid);
                              }
                            });
                          },
                          title: Text(
                            peer.name,
                            style: ArcUiTokens.body(
                              color: ArcUiTokens.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Accepted Match Raider',
                            style: ArcUiTokens.bodySmall(),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ArcSquadRaidFairnessMode>(
                        initialValue: _fairness,
                        decoration: ArcUiTokens.inputDecoration(
                          labelText: 'Squad optimisation',
                        ),
                        dropdownColor: ArcUiTokens.surfaceOverlay,
                        items: [
                          for (final mode in ArcSquadRaidFairnessMode.values)
                            DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _fairness = value);
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fairness.description,
                        style: ArcUiTokens.bodySmall(),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ArcUiTokens.textButtonStyle(primary: true),
                          onPressed: _selectedPeerUids.isEmpty || _creating
                              ? null
                              : () => _create(peers),
                          icon: const Icon(Icons.groups_rounded),
                          label: Text(
                            _creating
                                ? 'Creating squad plan...'
                                : 'Create Shared Raid Plan',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_AcceptedPeer> _acceptedPeers(
    List<ArcMatchRiderInvite> incoming,
    List<ArcMatchRiderInvite> outgoing,
  ) {
    final myUid = _squadRepository.currentUid;
    if (myUid == null) return const <_AcceptedPeer>[];

    final byUid = <String, _AcceptedPeer>{};
    for (final invite in <ArcMatchRiderInvite>[...incoming, ...outgoing]) {
      if (invite.status != 'accepted') continue;
      final isSender = invite.senderUid == myUid;
      final uid = isSender ? invite.recipientUid : invite.senderUid;
      final name = isSender ? invite.recipientName : invite.senderName;
      if (uid.isEmpty || uid == myUid) continue;
      byUid[uid] = _AcceptedPeer(
        uid: uid,
        name: name.trim().isEmpty ? 'Squad Raider' : name.trim(),
      );
    }
    final peers = byUid.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return peers;
  }

  Future<void> _create(List<_AcceptedPeer> peers) async {
    setState(() => _creating = true);
    try {
      final labels = <String, String>{
        for (final peer in peers)
          if (_selectedPeerUids.contains(peer.uid)) peer.uid: peer.name,
      };
      final session = await _squadRepository.createSession(
        leaderLabel: widget.myDisplayName,
        peerLabels: labels,
        fairnessMode: _fairness,
      );
      if (!mounted) return;
      _openSession(session.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create squad raid plan. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  void _openSession(String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArcRaidIntelligenceScreen(squadSessionId: sessionId),
      ),
    );
  }
}

class _AcceptedPeer {
  const _AcceptedPeer({required this.uid, required this.name});

  final String uid;
  final String name;
}
