import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
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
          'Report ratting privately, add evidence and optionally request a moderated contract.',
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
                  Tab(text: 'REPORT A RAT'),
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
  static const _stageCount = 5;

  final screenUsername = TextEditingController();
  final mapController = TransformationController();

  int stage = 0;
  ArcRaiderReportCategory? category;
  String mapId = '';
  ArcNormalizedPoint? point;
  String nearestPoiId = '';
  String nearestPoiName = '';
  bool? atExtraction;
  String extractionId = '';
  String extractionName = '';
  String serverRegion = '';
  DateTime? incidentAt;
  bool wantsContract = false;
  String selectedEventId = 'none';
  XFile? evidenceClip;
  bool selectingClip = false;
  final Map<String, int> rewards = {};
  final rewardSearch = TextEditingController();
  String rewardSearchQuery = '';
  String? selectedRewardItemId;
  int rewardQuantity = 1;
  double mapZoom = 1;
  bool busy = false;
  String validationMessage = '';

  static const servers = [
    'Europe',
    'North America',
    'South America',
    'Asia',
    'Oceania',
    'Other / unknown',
  ];

  ArcRaidMap? get selectedMap =>
      mapId.isEmpty ? null : ArcRaidIntelligenceSeedData.mapById(mapId);

  @override
  void initState() {
    super.initState();
    // DateTime.now() is device-local, so the incident time opens prefilled
    // in the player's local timezone and remains editable.
    incidentAt = DateTime.now();
  }

  @override
  void dispose() {
    screenUsername.dispose();
    rewardSearch.dispose();
    mapController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (stage == 0) return;
    setState(() {
      validationMessage = '';
      stage -= 1;
    });
  }

  bool _validateStage() {
    String? message;
    switch (stage) {
      case 0:
        if (screenUsername.text.trim().length < 3) {
          message = 'Enter the Rat\'s screen username.';
        }
      case 1:
        if (category == null) {
          message = 'Choose what you are reporting.';
        }
      case 2:
        if (mapId.isEmpty) {
          message = 'Choose the map.';
        } else if (point == null) {
          message = 'Tap the map where the incident happened.';
        } else if (atExtraction == null) {
          message = 'Tell us whether this happened at an extraction.';
        } else if (atExtraction == true && extractionId.isEmpty) {
          message = 'Choose the extraction point.';
        } else if (serverRegion.isEmpty) {
          message = 'Choose the server region.';
        } else if (incidentAt == null) {
          message = 'Choose when the incident happened.';
        }
      case 3:
        if (wantsContract && rewards.isEmpty) {
          message = 'Add at least one reward item or choose report only.';
        }
      case 4:
        return true;
    }

    if (message != null) {
      setState(() => validationMessage = message!);
      return false;
    }
    setState(() => validationMessage = '');
    return true;
  }

  void _continue() {
    if (!_validateStage()) return;
    if (stage >= _stageCount - 1) return;
    setState(() => stage += 1);
  }

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
    if (time == null || !mounted) return;
    setState(() {
      incidentAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      validationMessage = '';
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
      validationMessage = '';
    });
  }

  Future<void> submit() async {
    if (stage != 4 || !_allRequiredDataPresent()) {
      setState(() {
        validationMessage =
            'Something required is missing. Go back and check the highlighted steps.';
      });
      return;
    }

    final p = point!;
    final map = selectedMap!;
    final reportedScreenUsername = screenUsername.text.trim();

    setState(() => busy = true);
    try {
      final reportId = widget.repo.newReportId();
      final evidenceItems = <ArcRaiderEvidence>[];
      if (evidenceClip != null) {
        evidenceItems.add(
          await widget.repo.uploadReportVideoEvidence(
            reportId: reportId,
            file: evidenceClip!,
          ),
        );
      }

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

      await widget.repo.createReport(
        reportId: reportId,
        targetDisplayName: reportedScreenUsername,
        targetGameIdentity: '',
        category: category!,
        description: '',
        encounterContext: '',
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
        rattingSubtype: '',
        serverRegion: serverRegion,
        incidentAt: incidentAt!,
        eventContext: _selectedEventLabel,
        socialContentUrl: '',
        evidence: evidenceItems,
        requestContract: wantsContract,
        rewardItems: rewardItems,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rat report submitted privately for moderator review.'),
        ),
      );
      _reset();
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

  bool _allRequiredDataPresent() =>
      screenUsername.text.trim().length >= 3 &&
      category != null &&
      mapId.isNotEmpty &&
      point != null &&
      atExtraction != null &&
      (atExtraction != true || extractionId.isNotEmpty) &&
      serverRegion.isNotEmpty &&
      incidentAt != null &&
      (!wantsContract || rewards.isNotEmpty);

  void _reset() {
    setState(() {
      stage = 0;
      category = null;
      mapId = '';
      point = null;
      nearestPoiId = '';
      nearestPoiName = '';
      atExtraction = null;
      extractionId = '';
      extractionName = '';
      serverRegion = '';
      incidentAt = null;
      wantsContract = false;
      rewards.clear();
      rewardSearch.clear();
      rewardSearchQuery = '';
      selectedRewardItemId = null;
      rewardQuantity = 1;
      mapZoom = 1;
      mapController.value = Matrix4.identity();
      validationMessage = '';
      screenUsername.clear();
      selectedEventId = 'none';
      evidenceClip = null;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppTheme.pagePadding,
    children: [
      _notice(
        'Reports stay private until moderator review. Approved reports can contribute to anonymous Rat Activity intelligence; UAG does not publish accusations.',
      ),
      const SizedBox(height: 14),
      _stageHeader(),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(key: ValueKey(stage), child: _stageBody()),
      ),
      if (validationMessage.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          validationMessage,
          style: const TextStyle(color: Colors.orangeAccent),
        ),
      ],
      if (stage < 4) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            if (stage > 0)
              OutlinedButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            const Spacer(),
            FilledButton.icon(
              key: const Key('report-rat-continue'),
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
            ),
          ],
        ),
      ] else ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    ],
  );

  Widget _stageHeader() {
    const labels = ['Rat', 'Incident', 'Where & when', 'Contract', 'Review'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels[stage], style: AppTheme.tradingHeading(fontSize: 18)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (stage + 1) / _stageCount),
      ],
    );
  }

  Widget _stageBody() {
    switch (stage) {
      case 0:
        return _card('Who are you reporting?', [
          const Text(
            'Enter the screen username exactly as it appears in ARC Raiders.',
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: screenUsername,
            builder: (context, value, _) => TextField(
              key: const Key('report-rat-screen-username'),
              controller: screenUsername,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Screen username *',
                hintText: 'Username shown in-game',
                border: const OutlineInputBorder(),
                helperText: value.text.trim().length < 3 ? 'Required' : 'Ready',
              ),
            ),
          ),
        ]);
      case 1:
        return _card('What happened?', [
          const Text(
            'Choose the report type that best describes the incident.',
          ),
          const SizedBox(height: 10),
          _choices(
            _reportCategories,
            category,
            (v) => setState(() {
              category = v;
              validationMessage = '';
            }),
            _categoryLabel,
          ),
          const Divider(height: 28),
          Text(
            'Evidence clip (optional)',
            style: AppTheme.tradingHeading(fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Attach one short MP4 clip (up to 30 seconds / 25 MB). '
            'This stays private and is visible only to you and moderators.',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('report-rat-attach-clip'),
            onPressed: selectingClip ? null : _pickEvidenceClip,
            icon: const Icon(Icons.video_file_outlined),
            label: Text(evidenceClip == null ? 'Attach clip' : 'Replace clip'),
          ),
          if (evidenceClip != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evidenceClip!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove clip',
                  onPressed: () => setState(() => evidenceClip = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ]);
      case 2:
        return _whereAndWhen();
      case 3:
        return _contractChoice();
      case 4:
        return _review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _whereAndWhen() => _card('Where and when?', [
    Text('Map', style: AppTheme.tradingHeading(fontSize: 16)),
    _stringChoices(
      ArcRaidIntelligenceSeedData.supportedMapIds,
      mapId,
      (v) {
        setState(() {
          mapId = v;
          selectedEventId = 'none';
          point = null;
          nearestPoiId = '';
          nearestPoiName = '';
          extractionId = '';
          extractionName = '';
          validationMessage = '';
        });
      },
      label: ArcRaidIntelligenceSeedData.displayNameForMapId,
    ),
    if (selectedMap != null) ...[
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const Key('report-rat-event-dropdown'),
        isExpanded: true,
        initialValue: _availableEvents.any((e) => e.id == selectedEventId)
            ? selectedEventId
            : 'none',
        decoration: const InputDecoration(
          labelText: 'Map condition / event (optional)',
          border: OutlineInputBorder(),
        ),
        items: _availableEvents
            .map(
              (condition) => DropdownMenuItem<String>(
                value: condition.id,
                child: Text(
                  condition.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (value) => setState(() {
          selectedEventId = value ?? 'none';
        }),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(child: Text('Tap the map where it happened.')),
          IconButton(
            key: const Key('report-rat-map-zoom-out'),
            tooltip: 'Zoom out',
            onPressed: () => _setMapZoom(mapZoom / 1.35),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            key: const Key('report-rat-map-reset-zoom'),
            tooltip: 'Reset map zoom',
            onPressed: () => _setMapZoom(1),
            icon: const Icon(Icons.center_focus_strong),
          ),
          IconButton(
            key: const Key('report-rat-map-zoom-in'),
            tooltip: 'Zoom in',
            onPressed: () => _setMapZoom(mapZoom * 1.35),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 390,
        child: ArcRaidIntelligenceMapRenderer(
          state: const ArcRaidIntelligenceEngine().build(mapId: mapId),
          controller: mapController,
          showBlueprintIntel: false,
          onMapTapped: setPoint,
        ),
      ),
      if (point != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            nearestPoiName.isEmpty
                ? 'Location pinned'
                : 'Nearest POI: $nearestPoiName',
          ),
        ),
      const Divider(height: 28),
      Text('At an extraction?', style: AppTheme.tradingHeading(fontSize: 16)),
      _yesNo(
        (value) => setState(() {
          atExtraction = value;
          if (!value) {
            extractionId = '';
            extractionName = '';
          }
          validationMessage = '';
        }),
      ),
      if (atExtraction == true) ...[
        const SizedBox(height: 8),
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
              validationMessage = '';
            });
          },
          label: (id) =>
              selectedMap!.extractions.firstWhere((e) => e.id == id).name,
        ),
      ],
    ],
    const Divider(height: 28),
    Text('Server region', style: AppTheme.tradingHeading(fontSize: 16)),
    _stringChoices(
      servers,
      serverRegion,
      (v) => setState(() {
        serverRegion = v;
        validationMessage = '';
      }),
    ),
    const Divider(height: 28),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('When did it happen?'),
      subtitle: Text(
        incidentAt == null
            ? 'Select date and time'
            : _formatDateTime(incidentAt!),
      ),
      trailing: const Icon(Icons.schedule),
      onTap: pickIncidentTime,
    ),
  ]);

  Widget _contractChoice() => _card('Optional Rat Contract', [
    const Text(
      'You can submit the report on its own, or request a moderated contract if the report is approved.',
    ),
    const SizedBox(height: 12),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: wantsContract,
      title: const Text('Request a contract if approved'),
      onChanged: (value) => setState(() {
        wantsContract = value;
        if (!value) rewards.clear();
        validationMessage = '';
      }),
    ),
    if (wantsContract) ...[
      const Text(
        'Search for an in-game item, choose the quantity, then add it to the contract. '
        'You can add as many different reward items as required.',
      ),
      const SizedBox(height: 12),
      if (rewards.isNotEmpty) ...[
        ...rewards.entries.map((entry) {
          final item = ArcTradeCatalog.items.firstWhere(
            (candidate) => candidate.id == entry.key,
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('${entry.value} × ${item.category}'),
              trailing: IconButton(
                tooltip: 'Remove reward',
                onPressed: () => setState(() => rewards.remove(entry.key)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        }),
        const Divider(height: 24),
      ],
      TextField(
        key: const Key('report-rat-reward-search'),
        controller: rewardSearch,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'Search reward item',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() {
          rewardSearchQuery = value.trim();
          selectedRewardItemId = null;
        }),
      ),
      if (rewardSearchQuery.length >= 2) ...[
        const SizedBox(height: 6),
        ..._rewardMatches.take(8).map(
          (item) => ListTile(
            dense: true,
            selected: selectedRewardItemId == item.id,
            title: Text(item.name),
            subtitle: Text('${item.category} • ${item.group}'),
            onTap: () => setState(() {
              selectedRewardItemId = item.id;
              rewardSearch.text = item.name;
              rewardSearchQuery = item.name;
            }),
          ),
        ),
      ],
      if (selectedRewardItemId != null) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Amount'),
            const SizedBox(width: 12),
            IconButton(
              onPressed: rewardQuantity <= 1
                  ? null
                  : () => setState(() => rewardQuantity -= 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$rewardQuantity',
              key: const Key('report-rat-reward-quantity'),
            ),
            IconButton(
              onPressed: () => setState(() => rewardQuantity += 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
            const Spacer(),
            FilledButton.icon(
              key: const Key('report-rat-add-reward'),
              onPressed: _addSelectedReward,
              icon: const Icon(Icons.add),
              label: const Text('Add reward'),
            ),
          ],
        ),
      ],
    ],
  ]);

  Widget _review() => _card('Review Rat report', [
    _reviewBody(),
    const SizedBox(height: 14),
    FilledButton.icon(
      key: const Key('report-rat-submit'),
      onPressed: busy ? null : submit,
      icon: const Icon(Icons.shield_outlined),
      label: Text(busy ? 'Submitting…' : 'Submit privately for review'),
    ),
  ]);

  Widget _reviewBody() {
    final map = selectedMap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summary('Screen username', screenUsername.text.trim()),
        _summary('Report', category == null ? '' : _categoryLabel(category!)),
        _summary('Map', map?.displayName ?? ''),
        _summary(
          'Location',
          nearestPoiName.isNotEmpty
              ? nearestPoiName
              : point == null
              ? ''
              : 'Pinned map location',
        ),
        _summary('Region', serverRegion),
        _summary('Event', _selectedEventLabel),
        _summary(
          'When',
          incidentAt == null ? '' : _formatDateTime(incidentAt!),
        ),
        _summary(
          'Evidence',
          evidenceClip == null ? 'No clip attached' : evidenceClip!.name,
        ),
        _summary(
          'Contract',
          wantsContract ? 'Requested if approved' : 'Report only',
        ),
        if (wantsContract)
          _summary(
            'Reward',
            rewards.entries
                .map((e) {
                  final item = ArcTradeCatalog.items.firstWhere(
                    (item) => item.id == e.key,
                  );
                  return '${e.value}× ${item.name}';
                })
                .join(' • '),
          ),
      ],
    );
  }

  Widget _summary(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }

  static const List<ArcRaiderReportCategory> _reportCategories = [
    ArcRaiderReportCategory.extractionRatting,
    ArcRaiderReportCategory.spawnRatting,
    ArcRaiderReportCategory.pvpThirdParty,
    ArcRaiderReportCategory.pveThirdParty,
    ArcRaiderReportCategory.falseFriendly,
    ArcRaiderReportCategory.scam,
    ArcRaiderReportCategory.other,
  ];

  Iterable<ArcTradeCatalogItem> get _rewardMatches {
    final query = rewardSearchQuery.toLowerCase();
    if (query.length < 2) return const <ArcTradeCatalogItem>[];
    return ArcTradeCatalog.items.where((item) {
      if (rewards.containsKey(item.id)) return false;
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.group.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
    });
  }

  void _addSelectedReward() {
    final itemId = selectedRewardItemId;
    if (itemId == null) return;
    setState(() {
      rewards[itemId] = rewardQuantity.clamp(1, 999);
      selectedRewardItemId = null;
      rewardQuantity = 1;
      rewardSearchQuery = '';
      rewardSearch.clear();
      validationMessage = '';
    });
  }

  void _setMapZoom(double value) {
    final next = value.clamp(1.0, 4.0);
    setState(() => mapZoom = next);
    mapController.value = Matrix4.diagonal3Values(next, next, 1);
  }

  List<ArcMapCondition> get _availableEvents {
    final map = selectedMap;
    if (map == null) return const [ArcMapConditions.noSpecialCondition];
    return ArcMapConditions.combinedOptionsForMap(map.displayName);
  }

  String get _selectedEventLabel {
    final match = _availableEvents.where((e) => e.id == selectedEventId);
    return match.isEmpty
        ? ArcMapConditions.noSpecialCondition.label
        : match.first.label;
  }

  Future<void> _pickEvidenceClip() async {
    if (selectingClip) return;
    setState(() => selectingClip = true);
    try {
      final clip = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (clip == null || !mounted) return;

      final name = clip.name.toLowerCase();
      if (!name.endsWith('.mp4')) {
        setState(
          () => validationMessage =
              'Evidence clips must be MP4 so moderators can review them reliably.',
        );
        return;
      }

      final bytes = await clip.length();
      if (bytes > 25 * 1024 * 1024) {
        setState(
          () => validationMessage =
              'That clip is larger than 25 MB. Trim it to 30 seconds or less and try again.',
        );
        return;
      }

      setState(() {
        evidenceClip = clip;
        validationMessage = '';
      });
    } finally {
      if (mounted) setState(() => selectingClip = false);
    }
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  Widget _yesNo(ValueChanged<bool> onChanged) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => onChanged(true),
          child: Text(atExtraction == true ? '✓ Yes' : 'Yes'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton(
          onPressed: () => onChanged(false),
          child: Text(atExtraction == false ? '✓ No' : 'No'),
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
            dense: true,
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
            dense: true,
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
    ArcRaiderReportCategory.extractionRatting => 'Extraction camping',
    ArcRaiderReportCategory.spawnRatting => 'Spawn camping',
    ArcRaiderReportCategory.ambushRatting => 'Camping / ambush',
    ArcRaiderReportCategory.objectiveCamping => 'Objective camping',
    ArcRaiderReportCategory.doorwayCamping => 'Doorway / building camping',
    ArcRaiderReportCategory.traversalCamping => 'Zipline / traversal camping',
    ArcRaiderReportCategory.lootRatting => 'Loot ratted',
    ArcRaiderReportCategory.pvpThirdParty => 'PvP third partying',
    ArcRaiderReportCategory.pveThirdParty => 'PvE third partying',
    ArcRaiderReportCategory.falseFriendly => 'False friendly',
    ArcRaiderReportCategory.scam => 'Scam / trade misconduct',
    ArcRaiderReportCategory.lootCamping => 'Loot / location camping',
    ArcRaiderReportCategory.repeatedTargeting => 'Repeated targeting',
    ArcRaiderReportCategory.griefing => 'Griefing',
    ArcRaiderReportCategory.harassment => 'Harassment',
    ArcRaiderReportCategory.other => 'Other',
  };
}

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
        return const Center(child: Text('No Raider Contracts here yet.'));
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
