import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_raider_contract_models.dart';
import '../repositories/arc_raider_contracts_repository.dart';

class ArcRaiderContractsScreen extends StatefulWidget {
  const ArcRaiderContractsScreen({super.key});
  static const routeName = '/raider-contracts';

  @override
  State<ArcRaiderContractsScreen> createState() => _State();
}

class _State extends State<ArcRaiderContractsScreen>
    with SingleTickerProviderStateMixin {
  final repo = ArcRaiderContractsRepository();
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: const UagAppBar(
      title: 'Report a Rat',
      subtitle:
          'Private reports, Rat Activity intelligence and moderated contracts.',
    ),
    drawer: const AppDrawer(),
    body: Stack(
      children: [
        const Positioned.fill(child: StaticWatermark()),
        SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: tabs,
                tabs: const [
                  Tab(text: 'REPORT'),
                  Tab(text: 'LIVE CONTRACTS'),
                  Tab(text: 'MY ACTIVITY'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [
                    _ProgressiveReport(repo: repo),
                    _Contracts(repo: repo, live: true),
                    _MyActivity(repo: repo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProgressiveReport extends StatefulWidget {
  const _ProgressiveReport({required this.repo});
  final ArcRaiderContractsRepository repo;

  @override
  State<_ProgressiveReport> createState() => _ProgressiveReportState();
}

class _ProgressiveReportState extends State<_ProgressiveReport> {
  final target = TextEditingController();
  final identity = TextEditingController();
  final details = TextEditingController();
  final encounterContextController = TextEditingController();
  final event = TextEditingController();
  final evidence = TextEditingController();
  final social = TextEditingController();
  final repeatCount = TextEditingController(text: '2');
  final mapController = TransformationController();

  int step = 0;
  ArcRaiderReportCategory? category;
  String rattingSubtype = '';
  String mapId = '';
  ArcNormalizedPoint? point;
  String nearestPoiId = '';
  String nearestPoiName = '';
  bool? atExtraction;
  String extractionId = '';
  String extractionName = '';
  String serverRegion = '';
  DateTime? incidentAt;
  ArcRaiderRepeatBehaviour? repeatBehaviour;
  bool? wantsContract;
  final Map<String, int> rewards = {};
  bool busy = false;

  static const servers = [
    'Europe',
    'North America',
    'South America',
    'Asia',
    'Oceania',
    'Other / unknown',
  ];

  static const ratTypes = [
    'Waiting at extraction',
    'Hiding near extraction',
    'Camping a doorway / entrance',
    'Camping high ground',
    'Waiting behind cover',
    'Camping a loot location',
    'Camping an objective',
    'Following then ambushing',
    'Repeatedly returning to the same position',
    'Other',
  ];

  ArcRaidMap? get selectedMap =>
      mapId.isEmpty ? null : ArcRaidIntelligenceSeedData.mapById(mapId);

  @override
  void dispose() {
    for (final c in [
      target,
      identity,
      details,
      encounterContextController,
      event,
      evidence,
      social,
      repeatCount,
    ]) {
      c.dispose();
    }
    mapController.dispose();
    super.dispose();
  }

  void next() => setState(() => step++);
  void back() => setState(() => step = math.max(0, step - 1));

  Future<void> pickIncidentTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: incidentAt ?? now,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(incidentAt ?? now),
    );
    if (time == null) return;
    setState(() {
      incidentAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void setPoint(ArcNormalizedPoint value) {
    final map = selectedMap!;
    ArcRaidMapPoi? nearest;
    var distance = double.infinity;
    for (final poi in map.pois) {
      final d = poi.point.distanceTo(value);
      if (d < distance) {
        distance = d;
        nearest = poi;
      }
    }
    setState(() {
      point = value;
      if (nearest != null && distance <= .09) {
        nearestPoiId = nearest.id;
        nearestPoiName = nearest.name;
      } else {
        nearestPoiId = '';
        nearestPoiName = '';
      }
    });
  }

  Future<void> submit() async {
    final p = point;
    final map = selectedMap;
    if (p == null ||
        map == null ||
        category == null ||
        incidentAt == null ||
        repeatBehaviour == null ||
        atExtraction == null ||
        wantsContract == null) {
      return;
    }
    setState(() => busy = true);
    try {
      final rewardItems = rewards.entries
          .map((entry) {
            final item = ArcTradeCatalog.items.firstWhere(
              (x) => x.id == entry.key,
            );
            return ArcRaiderRewardItem(
              itemId: item.id,
              name: item.name,
              category: item.category,
              quantity: entry.value,
            );
          })
          .toList(growable: false);

      final evidenceItems = evidence.text.trim().isEmpty
          ? const <ArcRaiderEvidence>[]
          : [
              ArcRaiderEvidence(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                submittedByUid: widget.repo.uid,
                kind: 'link',
                url: evidence.text.trim(),
                caption: 'Reporter evidence',
                createdAt: DateTime.now(),
              ),
            ];

      await widget.repo.createReport(
        targetDisplayName: target.text,
        targetGameIdentity: identity.text,
        category: category!,
        description: details.text,
        encounterContext: encounterContextController.text,
        mapId: map.id,
        mapDisplayName: map.displayName,
        locationX: p.x,
        locationY: p.y,
        locationLabel: nearestPoiName.isEmpty
            ? 'Pinned map location'
            : nearestPoiName,
        nearestPoiId: nearestPoiId,
        nearestPoiName: nearestPoiName,
        atExtraction: atExtraction!,
        extractionId: extractionId,
        extractionName: extractionName,
        rattingSubtype: rattingSubtype,
        serverRegion: serverRegion,
        incidentAt: incidentAt!,
        repeatBehaviour: repeatBehaviour!,
        repeatCount: int.tryParse(repeatCount.text) ?? 1,
        eventContext: event.text,
        socialContentUrl: social.text,
        evidence: evidenceItems,
        requestContract: wantsContract!,
        rewardItems: rewardItems,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted privately for moderator review.'),
        ),
      );
      setState(() {
        step = 0;
        category = null;
        rattingSubtype = '';
        mapId = '';
        point = null;
        nearestPoiId = '';
        nearestPoiName = '';
        atExtraction = null;
        extractionId = '';
        extractionName = '';
        serverRegion = '';
        incidentAt = null;
        repeatBehaviour = null;
        wantsContract = null;
        rewards.clear();
        for (final c in [
          target,
          identity,
          details,
          encounterContextController,
          event,
          evidence,
          social,
        ]) {
          c.clear();
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppTheme.pagePadding,
    children: [
      _notice(
        'Reports stay private until moderator review. Public Rat Activity uses aggregated approved incident data, never public accusations.',
      ),
      const SizedBox(height: 14),
      LinearProgressIndicator(value: (step + 1) / 13),
      const SizedBox(height: 8),
      Text(
        'QUESTION ${step + 1} OF 13',
        style: const TextStyle(color: AppTheme.neonCyan),
      ),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(step), child: _question()),
      ),
      if (step > 0) ...[
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: back,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous question'),
        ),
      ],
    ],
  );

  Widget _question() {
    switch (step) {
      case 0:
        return _card('Who are you reporting?', [
          _field(target, 'Rat display name *'),
          _field(identity, 'Game identity / platform ID'),
          _continue(() => target.text.trim().length >= 2),
        ]);
      case 1:
        return _card('What are you reporting?', [
          _choices(ArcRaiderReportCategory.values, category, (v) {
            setState(() => category = v);
            next();
          }, (v) => _categoryLabel(v)),
        ]);
      case 2:
        return _card('What were they doing?', [
          _stringChoices(ratTypes, rattingSubtype, (v) {
            setState(() => rattingSubtype = v);
            next();
          }),
        ]);
      case 3:
        return _card('Which map?', [
          _stringChoices(
            ArcRaidIntelligenceSeedData.supportedMapIds,
            mapId,
            (v) {
              setState(() {
                mapId = v;
                point = null;
                nearestPoiId = '';
                nearestPoiName = '';
                extractionId = '';
                extractionName = '';
              });
              next();
            },
            label: ArcRaidIntelligenceSeedData.displayNameForMapId,
          ),
        ]);
      case 4:
        return _mapQuestion();
      case 5:
        return _card('Was this at an extraction?', [
          _yesNo((v) {
            setState(() => atExtraction = v);
            if (!v) {
              extractionId = '';
              extractionName = '';
              next();
            } else {
              next();
            }
          }),
        ]);
      case 6:
        if (atExtraction == true) {
          return _card('Which extraction point?', [
            _stringChoices(
              selectedMap!.extractions.map((e) => e.id).toList(),
              extractionId,
              (v) {
                final extraction = selectedMap!.extractions.firstWhere(
                  (e) => e.id == v,
                );
                setState(() {
                  extractionId = extraction.id;
                  extractionName = extraction.name;
                });
                next();
              },
              label: (id) =>
                  selectedMap!.extractions.firstWhere((e) => e.id == id).name,
            ),
          ]);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && step == 6) next();
        });
        return const SizedBox.shrink();
      case 7:
        return _card('Which server / region?', [
          _stringChoices(servers, serverRegion, (v) {
            setState(() => serverRegion = v);
            next();
          }),
        ]);
      case 8:
        return _card('When did it happen?', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              incidentAt == null
                  ? 'Select date and time'
                  : incidentAt.toString(),
            ),
            trailing: const Icon(Icons.schedule),
            onTap: pickIncidentTime,
          ),
          _continue(() => incidentAt != null),
        ]);
      case 9:
        return _card('Did they repeat the behaviour?', [
          _choices(
            ArcRaiderRepeatBehaviour.values,
            repeatBehaviour,
            (v) {
              setState(() => repeatBehaviour = v);
              next();
            },
            (v) => switch (v) {
              ArcRaiderRepeatBehaviour.no => 'No',
              ArcRaiderRepeatBehaviour.sameRaid =>
                'Yes — multiple times in this raid',
              ArcRaiderRepeatBehaviour.previousEncounter =>
                'Yes — I have seen them do this before',
              ArcRaiderRepeatBehaviour.notSure => 'Not sure',
            },
          ),
          if (repeatBehaviour == ArcRaiderRepeatBehaviour.sameRaid)
            _field(repeatCount, 'How many times?'),
        ]);
      case 10:
        return _card('What happened?', [
          _field(details, 'Describe the encounter *', lines: 5),
          _field(
            encounterContextController,
            'Extra encounter context',
            lines: 2,
          ),
          _field(event, 'Event / activity'),
          _field(evidence, 'Evidence URL — screenshot, clip or document'),
          _field(social, 'Optional TikTok / social post URL'),
          _continue(() => details.text.trim().length >= 20),
        ]);
      case 11:
        return _card('Create a Rat Contract if approved?', [
          const Text(
            'A contract is optional. The report can still contribute to moderated Rat Activity intelligence without one.',
          ),
          const SizedBox(height: 12),
          _yesNo(
            (v) {
              setState(() => wantsContract = v);
              next();
            },
            yes: 'Yes — offer an in-game reward',
            no: 'No — report only',
          ),
        ]);
      case 12:
        if (wantsContract == true) return _rewardAndReview();
        return _review();
      default:
        return _review();
    }
  }

  Widget _mapQuestion() {
    final state = const ArcRaidIntelligenceEngine().build(mapId: mapId);
    return _card('Where did it happen?', [
      const Text(
        'Tap the exact location. Nearby named POIs are linked automatically.',
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 430,
        child: ArcRaidIntelligenceMapRenderer(
          state: state,
          controller: mapController,
          onMapTapped: setPoint,
        ),
      ),
      if (point != null) ...[
        const SizedBox(height: 8),
        Text(
          nearestPoiName.isEmpty
              ? 'Pinned: ${(point!.x * 100).toStringAsFixed(1)}%, ${(point!.y * 100).toStringAsFixed(1)}%'
              : 'Nearest POI: $nearestPoiName',
        ),
      ],
      _continue(() => point != null),
    ]);
  }

  Widget _rewardAndReview() => _card('Choose the contract reward', [
    const Text(
      'Rewards are player-promised in-game items. UAG does not hold them in escrow.',
    ),
    const SizedBox(height: 10),
    ...ArcTradeCatalog.items.map((item) {
      final qty = rewards[item.id] ?? 0;
      return ListTile(
        dense: true,
        title: Text(item.name),
        subtitle: Text('${item.category} • ${item.group}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: qty == 0
                  ? null
                  : () => setState(() {
                      if (qty <= 1) {
                        rewards.remove(item.id);
                      } else {
                        rewards[item.id] = qty - 1;
                      }
                    }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$qty'),
            IconButton(
              onPressed: () => setState(() => rewards[item.id] = qty + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      );
    }),
    const Divider(),
    _reviewBody(),
    FilledButton.icon(
      onPressed: rewards.isEmpty || busy ? null : submit,
      icon: const Icon(Icons.gavel),
      label: Text(busy ? 'Submitting…' : 'Submit privately for review'),
    ),
  ]);

  Widget _review() => _card('Review & submit', [
    _reviewBody(),
    FilledButton.icon(
      onPressed: busy ? null : submit,
      icon: const Icon(Icons.gavel),
      label: Text(busy ? 'Submitting…' : 'Submit privately for review'),
    ),
  ]);

  Widget _reviewBody() {
    final map = selectedMap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summary('Target', target.text),
        _summary('Type', category == null ? '' : _categoryLabel(category!)),
        _summary('Behaviour', rattingSubtype),
        _summary('Map', map?.displayName ?? ''),
        _summary(
          'Location',
          nearestPoiName.isEmpty ? 'Pinned map location' : nearestPoiName,
        ),
        _summary('Extraction', atExtraction == true ? extractionName : 'No'),
        _summary('Server', serverRegion),
        _summary('Time', incidentAt?.toString() ?? ''),
        _summary('Repeat', repeatBehaviour?.name ?? ''),
        _summary('Contract', wantsContract == true ? 'Requested' : 'No'),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _summary(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text('$label: ${value.isEmpty ? '—' : value}'),
  );

  Widget _continue(bool Function() enabled) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: FilledButton(
      onPressed: enabled() ? next : null,
      child: const Text('Continue'),
    ),
  );

  Widget _yesNo(
    ValueChanged<bool> onChanged, {
    String yes = 'Yes',
    String no = 'No',
  }) => Row(
    children: [
      Expanded(
        child: FilledButton(onPressed: () => onChanged(true), child: Text(yes)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton(
          onPressed: () => onChanged(false),
          child: Text(no),
        ),
      ),
    ],
  );

  Widget _choices<T>(
    List<T> values,
    T? selected,
    ValueChanged<T> onChanged,
    String Function(T) label,
  ) => Column(
    children: values
        .map(
          (v) => ListTile(
            title: Text(label(v)),
            leading: Icon(
              v == selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: v == selected ? AppTheme.neonCyan : Colors.white54,
            ),
            onTap: () => onChanged(v),
          ),
        )
        .toList(),
  );

  Widget _stringChoices(
    List<String> values,
    String selected,
    ValueChanged<String> onChanged, {
    String Function(String)? label,
  }) => Column(
    children: values
        .map(
          (v) => ListTile(
            title: Text(label?.call(v) ?? v),
            leading: Icon(
              v == selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: v == selected ? AppTheme.neonCyan : Colors.white54,
            ),
            onTap: () => onChanged(v),
          ),
        )
        .toList(),
  );

  String _categoryLabel(ArcRaiderReportCategory value) => switch (value) {
    ArcRaiderReportCategory.extractionRatting => 'Extraction ratting',
    ArcRaiderReportCategory.ambushRatting => 'Camping / ambush ratting',
    ArcRaiderReportCategory.spawnRatting => 'Spawn ratting',
    ArcRaiderReportCategory.lootCamping => 'Loot / location camping',
    ArcRaiderReportCategory.objectiveCamping => 'Quest / objective camping',
    ArcRaiderReportCategory.doorwayCamping => 'Doorway / building camping',
    ArcRaiderReportCategory.traversalCamping => 'Zipline / traversal camping',
    ArcRaiderReportCategory.repeatedTargeting => 'Repeated targeting',
    ArcRaiderReportCategory.griefing => 'Griefing',
    ArcRaiderReportCategory.harassment => 'Harassment',
    ArcRaiderReportCategory.scam => 'Scam / trade misconduct',
    ArcRaiderReportCategory.other => 'Other',
  };
}

Widget _field(
  TextEditingController controller,
  String label, {
  int lines = 1,
}) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: TextField(
    controller: controller,
    maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  ),
);

Widget _notice(String text) => Container(
  padding: AppTheme.sectionCardPadding,
  decoration: AppTheme.tradingCardDecoration(
    borderColor: AppTheme.neonCyan.withValues(alpha: .3),
  ),
  child: Text(
    text,
    style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
  ),
);

Widget _card(String title, List<Widget> children) => Container(
  padding: AppTheme.sectionCardPadding,
  decoration: AppTheme.tradingCardDecoration(
    borderColor: AppTheme.neonCyan.withValues(alpha: .22),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTheme.tradingHeading(fontSize: 24)),
      const SizedBox(height: 12),
      ...children,
    ],
  ),
);

class _Contracts extends StatelessWidget {
  const _Contracts({required this.repo, required this.live});
  final ArcRaiderContractsRepository repo;
  final bool live;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ArcRaiderContract>>(
    stream: live ? repo.watchLiveContracts() : repo.watchMyContracts(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('Could not load contracts: ${snapshot.error}'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      if (items.isEmpty) {
        return const Center(child: Text('No Rat Contracts here yet.'));
      }
      return ListView(
        padding: AppTheme.pagePadding,
        children: items
            .map(
              (contract) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.targetDisplayName,
                        style: AppTheme.tradingHeading(fontSize: 22),
                      ),
                      Text(
                        contract.status.name,
                        style: const TextStyle(color: AppTheme.neonCyan),
                      ),
                      if (contract.rewardSummary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'REWARD: ${contract.rewardSummary}',
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        contract.evidenceRequirements,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      if (live)
                        FilledButton(
                          onPressed: () => repo.acceptContract(contract.id),
                          child: const Text('Accept contract'),
                        )
                      else ...[
                        if (contract.status == ArcRaiderContractStatus.accepted)
                          FilledButton(
                            onPressed: () => repo.startContract(contract.id),
                            child: const Text('Start hunt'),
                          ),
                        if (contract.status ==
                            ArcRaiderContractStatus.inProgress)
                          OutlinedButton(
                            onPressed: () =>
                                _evidenceDialog(context, repo, contract),
                            child: const Text('Submit evidence'),
                          ),
                        if (contract.status ==
                            ArcRaiderContractStatus.evidenceSubmitted)
                          OutlinedButton(
                            onPressed: () => repo.disputeContract(
                              contract.id,
                              'Participant requested moderator review.',
                            ),
                            child: const Text('Request review'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

Future<void> _evidenceDialog(
  BuildContext context,
  ArcRaiderContractsRepository repo,
  ArcRaiderContract contract,
) async {
  final url = TextEditingController();
  final social = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Submit contract evidence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Evidence URL *'),
          ),
          TextField(
            controller: social,
            decoration: const InputDecoration(
              labelText: 'Optional TikTok / social URL',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (url.text.trim().isEmpty) {
              return;
            }
            await repo.submitEvidence(
              contract.id,
              evidence: [
                ArcRaiderEvidence(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  submittedByUid: repo.uid,
                  kind: 'link',
                  url: url.text.trim(),
                  caption: 'Contract completion evidence',
                  createdAt: DateTime.now(),
                ),
              ],
              socialContentUrl: social.text,
            );
            if (d.mounted) {
              Navigator.pop(d);
            }
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  url.dispose();
  social.dispose();
}

class _MyActivity extends StatelessWidget {
  const _MyActivity({required this.repo});
  final ArcRaiderContractsRepository repo;

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppTheme.pagePadding,
    children: [
      Text('MY REPORTS', style: AppTheme.tradingHeading(fontSize: 20)),
      StreamBuilder<List<ArcRaiderReport>>(
        stream: repo.watchMyReports(),
        builder: (context, snapshot) => Column(
          children: (snapshot.data ?? const <ArcRaiderReport>[])
              .map(
                (r) => ListTile(
                  title: Text(r.targetDisplayName),
                  subtitle: Text(
                    '${r.category.name} • ${r.status.name} • ${r.mapDisplayName}',
                  ),
                  trailing: r.canWithdraw
                      ? TextButton(
                          onPressed: () => repo.withdrawReport(r.id),
                          child: const Text('Withdraw'),
                        )
                      : null,
                ),
              )
              .toList(),
        ),
      ),
      const Divider(),
      Text('MY CONTRACTS', style: AppTheme.tradingHeading(fontSize: 20)),
      SizedBox(height: 500, child: _Contracts(repo: repo, live: false)),
    ],
  );
}
