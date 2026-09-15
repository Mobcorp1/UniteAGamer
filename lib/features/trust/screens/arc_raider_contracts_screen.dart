import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_text_sanitizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
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
    tabs = TabController(length: 4, vsync: this);
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
    bottomNavigationBar: const UagEntitledAdAwareBottomDock(
      child: ArcCompanionBottomDock(activeLabel: 'Report a Rat'),
    ),
    body: ArcRaidersScreenShell(
      showAdBanner: false,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(
                ArcUiTokens.gapM,
                ArcUiTokens.gapS,
                ArcUiTokens.gapM,
                ArcUiTokens.gapS,
              ),
              padding: const EdgeInsets.all(ArcUiTokens.gapXS),
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.panel,
                accent: ArcUiTokens.secondaryAccent,
                borderOpacity: 0.34,
                glow: true,
              ),
              child: TabBar(
                controller: tabs,
                isScrollable: false,
                labelColor: ArcUiTokens.secondaryAccent,
                unselectedLabelColor: ArcUiTokens.textSecondary,
                indicatorColor: ArcUiTokens.secondaryAccent,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.flag_outlined), text: 'REPORT'),
                  Tab(icon: Icon(Icons.gps_fixed_rounded), text: 'CONTRACTS'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'ACTIVITY'),
                  Tab(
                    icon: Icon(Icons.workspace_premium_outlined),
                    text: 'REWARDS',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [
                  _ProgressiveReport(repo: repo),
                  _Contracts(repo: repo, live: true),
                  _MyActivity(repo: repo),
                  _BlueprintRewards(repo: repo),
                ],
              ),
            ),
          ],
        ),
      ),
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
  bool blueprintDupesReward = false;
  int blueprintRewardCount = 1;
  int maxBlueprintRewards = 0;
  bool loadingBlueprintRewards = false;
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
        if (wantsContract && rewards.isEmpty && !blueprintDupesReward) {
          message =
              'Add at least one reward item, offer Blueprint dupes, or choose report only.';
        } else if (wantsContract &&
            blueprintDupesReward &&
            blueprintRewardCount > maxBlueprintRewards) {
          message =
              'Reduce the Blueprint reward count to your currently available duplicates.';
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
        blueprintRewardCount: blueprintDupesReward ? blueprintRewardCount : 0,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rat report submitted privately for moderator review.'),
        ),
      );
      _reset();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit report. Try again.')),
        );
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
      (!wantsContract || rewards.isNotEmpty || blueprintDupesReward);

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
      incidentAt = DateTime.now();
      wantsContract = false;
      rewards.clear();
      rewardSearch.clear();
      rewardSearchQuery = '';
      selectedRewardItemId = null;
      rewardQuantity = 1;
      blueprintDupesReward = false;
      blueprintRewardCount = 1;
      maxBlueprintRewards = 0;
      loadingBlueprintRewards = false;
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
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
    children: [
      const _ReportRatHero(),
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
    const labels = ['TARGET', 'INCIDENT', 'LOCATION', 'CONTRACT', 'REVIEW'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: stage.isEven
            ? ArcUiTokens.primaryAccent
            : ArcUiTokens.secondaryAccent,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '0${stage + 1}',
                style: ArcUiTokens.display(
                  fontSize: 30,
                  color: ArcUiTokens.secondaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  labels[stage],
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 21,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
              ),
              Text(
                '${stage + 1}/$_stageCount',
                style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_stageCount, (index) {
              final active = index <= stage;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(
                    right: index == _stageCount - 1 ? 0 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? (index.isEven
                              ? ArcUiTokens.primaryAccent
                              : ArcUiTokens.secondaryAccent)
                        : ArcUiTokens.borderSubtle.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
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
        if (!value) {
          rewards.clear();
          blueprintDupesReward = false;
          blueprintRewardCount = 1;
          maxBlueprintRewards = 0;
        }
        validationMessage = '';
      }),
    ),
    if (wantsContract) ...[
      SwitchListTile.adaptive(
        key: const Key('rat-contract-blueprint-dupes'),
        contentPadding: EdgeInsets.zero,
        title: const Text('My Blueprint Dupes'),
        subtitle: const Text(
          'Offer a number of duplicate Blueprints. The claimant will only see matches they are missing.',
        ),
        value: blueprintDupesReward,
        onChanged: loadingBlueprintRewards
            ? null
            : (enabled) async {
                if (!enabled) {
                  setState(() {
                    blueprintDupesReward = false;
                    blueprintRewardCount = 1;
                    validationMessage = '';
                  });
                  return;
                }
                setState(() {
                  loadingBlueprintRewards = true;
                  wantsContract = true;
                });
                try {
                  final max = await widget.repo.maxBlueprintRewardsIcanOffer();
                  if (!mounted) return;
                  setState(() {
                    maxBlueprintRewards = max;
                    blueprintDupesReward = max > 0;
                    blueprintRewardCount = max > 0 ? 1 : 0;
                    validationMessage = max > 0
                        ? ''
                        : 'Your Blueprint Tracker currently has no duplicates available to offer.';
                  });
                } finally {
                  if (mounted) setState(() => loadingBlueprintRewards = false);
                }
              },
      ),
      if (blueprintDupesReward) ...[
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: const Key('rat-contract-blueprint-reward-count'),
          initialValue: blueprintRewardCount,
          decoration: const InputDecoration(
            labelText: 'Blueprint rewards offered',
            border: OutlineInputBorder(),
          ),
          items: [
            for (var i = 1; i <= maxBlueprintRewards; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: (value) => setState(() {
            blueprintRewardCount = value ?? 1;
            validationMessage = '';
          }),
        ),
        const SizedBox(height: 12),
      ],
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
              subtitle: Text(
                '${entry.value} ${ArcTextSanitizer.multiplication} ${item.category}',
              ),
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
        ..._rewardMatches
            .take(8)
            .map(
              (item) => ListTile(
                dense: true,
                selected: selectedRewardItemId == item.id,
                title: Text(item.name),
                subtitle: Text(
                  ArcTextSanitizer.metadataLine([item.category, item.group]),
                ),
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
      label: Text(busy ? 'Submitting...' : 'Submit privately for review'),
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
                  return '${e.value}${ArcTextSanitizer.multiplication} ${item.name}';
                })
                .join(ArcTextSanitizer.separator()),
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
    ArcRaiderReportCategory.shotInBack,
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
          child: Text(
            atExtraction == true ? '${ArcTextSanitizer.check} Yes' : 'Yes',
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton(
          onPressed: () => onChanged(false),
          child: Text(
            atExtraction == false ? '${ArcTextSanitizer.check} No' : 'No',
          ),
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
    ArcRaiderReportCategory.shotInBack => 'Shot in the back',
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

class _TrustLoadProblem extends StatelessWidget {
  const _TrustLoadProblem({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.pagePadding,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.panel,
            accent: ArcUiTokens.warning,
            borderOpacity: 0.34,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: ArcUiTokens.warning,
              ),
              const SizedBox(height: 10),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTheme.tradingHeading(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _ReportRatHero extends StatelessWidget {
  const _ReportRatHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF07111A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.38),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/arc_raiders/hub/arc_hub_hunt_a_rat.webp'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xD807111A), BlendMode.srcOver),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REPORT A RAT', style: AppTheme.tradingHeading(fontSize: 24)),
          const SizedBox(height: 8),
          const Text(
            'Private report. Moderator reviewed. No public accusation is created.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approved reports can contribute to anonymous Rat Activity intelligence and, where requested, a moderated Raider Contract.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Contracts extends StatelessWidget {
  const _Contracts({
    required this.repo,
    required this.live,
    this.embedded = false,
  });
  final ArcRaiderContractsRepository repo;
  final bool live;
  final bool embedded;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ArcRaiderContract>>(
    stream: live ? repo.watchLiveContracts() : repo.watchMyContracts(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _TrustLoadProblem(
          title: 'Contracts unavailable',
          message:
              'We could not load Raider Contracts. Reopen this section to try again.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      if (items.isEmpty) {
        return const Padding(
          padding: ArcUiTokens.panelPadding,
          child: Text('No Raider Contracts here yet.'),
        );
      }
      return ListView.separated(
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        padding: embedded ? EdgeInsets.zero : AppTheme.pagePadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: ArcUiTokens.gapM),
        itemBuilder: (context, index) {
          final contract = items[index];
          return ArcHunterContractCard(
            contract: contract,
            onAccept: live ? () => repo.acceptContract(contract.id) : null,
            onStart: live ? null : () => repo.startContract(contract.id),
            onSubmit: live
                ? null
                : () => _evidenceDialog(context, repo, contract),
            onOpenEvidence: () => _openContractVideo(contract),
            onDispute: live
                ? null
                : () => repo.disputeContract(
                    contract.id,
                    'Participant requested moderator review.',
                  ),
          );
        },
      );
    },
  );
}

/// Private contract detail presentation; callbacks keep verification authority
/// in the repository/server and allow the actual review UX to be widget tested.
class ArcHunterContractCard extends StatefulWidget {
  const ArcHunterContractCard({
    super.key,
    required this.contract,
    this.issuer = false,
    this.onAccept,
    this.onStart,
    this.onSubmit,
    this.onOpenEvidence,
    this.onReview,
    this.onDispute,
  });

  final ArcRaiderContract contract;
  final bool issuer;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onStart;
  final Future<void> Function()? onSubmit;
  final Future<void> Function()? onOpenEvidence;
  final Future<void> Function()? onDispute;
  final Future<void> Function(bool confirmed, String reason)? onReview;

  @override
  State<ArcHunterContractCard> createState() => _ArcHunterContractCardState();
}

class _ArcHunterContractCardState extends State<ArcHunterContractCard> {
  bool _busy = false;
  String? _error;
  String? _notice;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'That action could not be completed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(bool confirmed) async {
    if (_busy || widget.onReview == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IssuerReviewDialog(
        confirmed: confirmed,
        onSubmit: (reason) => widget.onReview!(confirmed, reason),
      ),
    );
    if (result == true && mounted) {
      setState(
        () => _notice = confirmed
            ? 'Completion confirmed. Your contract is updating.'
            : 'Evidence rejected. The hunter can submit a new clip.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contract = widget.contract;
    final rejected = contract.verificationStatus == 'rejected';
    final hasVideo = contract.evidence.any(
      (item) => item.kind == 'video' && item.storagePath.isNotEmpty,
    );
    final status = contract.isVerifiedComplete
        ? 'VERIFIED COMPLETE'
        : contract.isAwaitingIssuerReview
        ? 'AWAITING ISSUER REVIEW'
        : rejected
        ? 'EVIDENCE REJECTED'
        : contract.status == ArcRaiderContractStatus.completed
        ? 'COMPLETED · NOT ISSUER VERIFIED'
        : switch (contract.status) {
            ArcRaiderContractStatus.available => 'AVAILABLE',
            ArcRaiderContractStatus.accepted => 'ACCEPTED',
            ArcRaiderContractStatus.inProgress => 'HUNT IN PROGRESS',
            ArcRaiderContractStatus.evidenceSubmitted =>
              'EVIDENCE SUBMITTED · NOT VERIFIED',
            ArcRaiderContractStatus.rejected => 'CONTRACT REJECTED',
            ArcRaiderContractStatus.disputed => 'UNDER REVIEW',
            ArcRaiderContractStatus.expired => 'EXPIRED',
            ArcRaiderContractStatus.cancelled => 'CANCELLED',
            ArcRaiderContractStatus.completed => 'COMPLETED',
          };
    return ArcTacticalPanel(
      icon: contract.isVerifiedComplete
          ? Icons.verified_outlined
          : Icons.radar_rounded,
      title: contract.targetDisplayName,
      subtitle: status,
      accent: contract.isVerifiedComplete
          ? ArcUiTokens.success
          : rejected
          ? ArcUiTokens.warning
          : ArcUiTokens.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contract.rewardSummary.isNotEmpty) ...[
            Text(
              'Reward: ${contract.rewardSummary}',
              style: ArcUiTokens.body(),
            ),
            const SizedBox(height: ArcUiTokens.gapS),
          ],
          Text(contract.evidenceRequirements, style: ArcUiTokens.bodySmall()),
          if (contract.evidenceSubmittedAt != null) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            Text(
              'Clip submitted: ${MaterialLocalizations.of(context).formatShortDate(contract.evidenceSubmittedAt!.toLocal())}',
              style: ArcUiTokens.metadata(),
            ),
          ],
          if (rejected) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            Text(
              contract.rejectionReason.isEmpty
                  ? 'The issuer requested a new evidence clip.'
                  : contract.rejectionReason,
              style: ArcUiTokens.body(color: ArcUiTokens.warning),
            ),
            if (!widget.issuer && contract.canSubmitVideoEvidence)
              Text(
                'Submit a new MP4 clip to request another review. Rejected evidence does not count as a verified completion.',
                style: ArcUiTokens.bodySmall(),
              ),
          ],
          if (contract.isAwaitingIssuerReview && !widget.issuer) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            Text(
              'Your clip is submitted. Only confirmation from the contract issuer makes this a verified completion.',
              style: ArcUiTokens.bodySmall(),
            ),
          ],
          if (contract.isVerifiedComplete) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            Text(
              'The contract issuer confirmed this completion. The submitted evidence is locked.',
              style: ArcUiTokens.bodySmall(),
            ),
          ],
          const SizedBox(height: ArcUiTokens.gapM),
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              if (hasVideo && widget.onOpenEvidence != null)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(widget.onOpenEvidence!),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('OPEN SUBMITTED VIDEO'),
                ),
              if (!widget.issuer && widget.onAccept != null)
                FilledButton(
                  onPressed: _busy ? null : () => _run(widget.onAccept!),
                  child: const Text('ACCEPT CONTRACT'),
                ),
              if (!widget.issuer &&
                  contract.status == ArcRaiderContractStatus.accepted &&
                  widget.onStart != null)
                FilledButton(
                  onPressed: _busy ? null : () => _run(widget.onStart!),
                  child: const Text('START HUNT'),
                ),
              if (!widget.issuer &&
                  contract.canSubmitVideoEvidence &&
                  widget.onSubmit != null)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(widget.onSubmit!),
                  icon: const Icon(Icons.video_file_outlined),
                  label: Text(
                    rejected ? 'SUBMIT NEW VIDEO' : 'SUBMIT VIDEO EVIDENCE',
                  ),
                ),
              if (!widget.issuer &&
                  contract.status ==
                      ArcRaiderContractStatus.evidenceSubmitted &&
                  widget.onDispute != null)
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(widget.onDispute!),
                  child: const Text('REQUEST MODERATOR REVIEW'),
                ),
              if (widget.issuer &&
                  contract.isAwaitingIssuerReview &&
                  widget.onReview != null) ...[
                FilledButton.icon(
                  onPressed: _busy || !hasVideo || _notice != null
                      ? null
                      : () => _review(true),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('CONFIRM COMPLETION'),
                ),
                OutlinedButton(
                  onPressed: _busy || _notice != null
                      ? null
                      : () => _review(false),
                  child: const Text('REJECT EVIDENCE'),
                ),
              ],
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: ArcUiTokens.gapS),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: ArcUiTokens.gapS),
              child: Text(
                _error!,
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.danger),
              ),
            ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: ArcUiTokens.gapS),
              child: Text(
                _notice!,
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.success),
              ),
            ),
        ],
      ),
    );
  }
}

class _IssuerReviewDialog extends StatefulWidget {
  const _IssuerReviewDialog({required this.confirmed, required this.onSubmit});
  final bool confirmed;
  final Future<void> Function(String reason) onSubmit;
  @override
  State<_IssuerReviewDialog> createState() => _IssuerReviewDialogState();
}

class _IssuerReviewDialogState extends State<_IssuerReviewDialog> {
  final _reason = TextEditingController();
  bool _busy = false;
  bool _acknowledged = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!widget.confirmed && _reason.text.trim().isEmpty) {
      setState(
        () => _error = 'Explain why this clip does not confirm completion.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_reason.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Review could not be saved. Your feedback is still here. Try again or reopen the contract if it has changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: ArcUiTokens.surfaceOverlay,
      scrollable: true,
      title: Text(
        widget.confirmed ? 'Confirm this completion?' : 'Reject this evidence?',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.confirmed
                ? 'Confirm only after reviewing the submitted video against this contract. Confirmation locks the evidence and records a verified completion.'
                : 'Tell the hunter what is missing so they can submit a new clip. Rejected evidence does not count towards verified results.',
            style: ArcUiTokens.bodySmall(),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          if (widget.confirmed)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acknowledged,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _acknowledged = value ?? false),
              title: const Text(
                'I reviewed the video and confirm the contract was completed.',
              ),
            )
          else
            TextField(
              controller: _reason,
              enabled: !_busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: ArcUiTokens.inputDecoration(
                labelText: 'Rejection reason (required)',
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.danger),
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _busy || (widget.confirmed && !_acknowledged)
              ? null
              : _submit,
          child: Text(
            widget.confirmed ? 'YES, CONFIRM COMPLETION' : 'SEND REJECTION',
          ),
        ),
      ],
    ),
  );
}

Future<void> _openContractVideo(ArcRaiderContract contract) async {
  final video = contract.evidence.firstWhere(
    (item) => item.kind == 'video' && item.storagePath.isNotEmpty,
  );
  final expectedPrefix =
      'contract_evidence/${contract.id}/${contract.hunterUid}/';
  if (!video.storagePath.startsWith(expectedPrefix)) {
    throw StateError('Invalid evidence reference.');
  }
  final url = await FirebaseStorage.instance
      .ref(video.storagePath)
      .getDownloadURL();
  final uri = Uri.parse(url);
  if (uri.scheme != 'https' || !await launchUrl(uri)) {
    throw StateError('Could not open evidence.');
  }
}

Future<void> _evidenceDialog(
  BuildContext context,
  ArcRaiderContractsRepository repo,
  ArcRaiderContract contract,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ContractVideoDialog(repo: repo, contract: contract),
);

class _ContractVideoDialog extends StatefulWidget {
  const _ContractVideoDialog({required this.repo, required this.contract});
  final ArcRaiderContractsRepository repo;
  final ArcRaiderContract contract;
  @override
  State<_ContractVideoDialog> createState() => _ContractVideoDialogState();
}

class _ContractVideoDialogState extends State<_ContractVideoDialog> {
  XFile? _clip;
  ArcRaiderEvidence? _uploaded;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (file == null) return;
      final length = await file.length();
      if (!file.name.toLowerCase().endsWith('.mp4') ||
          length == 0 ||
          length > 25 * 1024 * 1024) {
        if (mounted) {
          setState(
            () => _error = 'Choose a nonempty MP4 clip, 25 MB or smaller.',
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _clip = file;
          _uploaded = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open that video. Please choose it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _clip == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _uploaded ??= await widget.repo.uploadContractVideoEvidence(
        contractId: widget.contract.id,
        file: _clip!,
      );
      await widget.repo.submitEvidence(
        widget.contract.id,
        evidence: [_uploaded!],
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'The clip could not be submitted. Retry with this clip, or reopen the contract if its status changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      title: const Text('Submit completion video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an MP4 clip, 25 MB or smaller. Show the encounter and outcome clearly. The contract issuer must confirm your evidence before it counts.',
            style: ArcUiTokens.bodySmall(),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(_clip == null ? 'CHOOSE VIDEO' : 'CHANGE VIDEO'),
          ),
          if (_clip != null) Text(_clip!.name, style: ArcUiTokens.bodySmall()),
          if (_error != null)
            Text(
              _error!,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.danger),
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _busy || _clip == null ? null : _submit,
          child: const Text('SUBMIT FOR ISSUER REVIEW'),
        ),
      ],
    ),
  );
}

class _IssuedContracts extends StatelessWidget {
  const _IssuedContracts({required this.repo});
  final ArcRaiderContractsRepository repo;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ArcRaiderContract>>(
    stream: repo.watchIssuedContracts(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _TrustLoadProblem(
          title: 'Issuer review unavailable',
          message: 'Reopen Activity to reload your issued contracts.',
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final contracts = snapshot.requireData.toList()
        ..sort((a, b) {
          if (a.isAwaitingIssuerReview != b.isAwaitingIssuerReview) {
            return a.isAwaitingIssuerReview ? -1 : 1;
          }
          return (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          );
        });
      if (contracts.isEmpty) {
        return const Padding(
          padding: ArcUiTokens.panelPadding,
          child: Text(
            'No issued contracts yet. Evidence from your hunters will appear here for review.',
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final contract in contracts) ...[
            ArcHunterContractCard(
              key: ValueKey(
                '${contract.id}:${contract.evidenceSubmissionId}:${contract.verificationStatus}',
              ),
              contract: contract,
              issuer: true,
              onOpenEvidence: () => _openContractVideo(contract),
              onReview: (confirmed, reason) => repo.reviewEvidence(
                contractId: contract.id,
                submissionId: contract.evidenceSubmissionId,
                confirmed: confirmed,
                reason: reason,
              ),
            ),
            const SizedBox(height: ArcUiTokens.gapM),
          ],
        ],
      );
    },
  );
}

class _MyActivity extends StatelessWidget {
  const _MyActivity({required this.repo});
  final ArcRaiderContractsRepository repo;

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppTheme.pagePadding,
    children: [
      Text(
        'YOUR ISSUED CONTRACTS',
        style: AppTheme.tradingHeading(fontSize: 20),
      ),
      Text(
        'Evidence awaiting your review appears first.',
        style: ArcUiTokens.bodySmall(),
      ),
      const SizedBox(height: ArcUiTokens.gapM),
      _IssuedContracts(repo: repo),
      const Divider(),
      Text('YOUR HUNTS', style: AppTheme.tradingHeading(fontSize: 20)),
      const SizedBox(height: ArcUiTokens.gapM),
      _Contracts(repo: repo, live: false, embedded: true),
      const Divider(),
      Text('MY REPORTS', style: AppTheme.tradingHeading(fontSize: 20)),
      StreamBuilder<List<ArcRaiderReport>>(
        stream: repo.watchMyReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _TrustLoadProblem(
              title: 'Reports unavailable',
              message: 'Reopen Activity to reload your reports.',
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          return Column(
            children: snapshot.requireData
                .map(
                  (r) => ListTile(
                    title: Text(r.targetDisplayName),
                    subtitle: Text(
                      ArcTextSanitizer.metadataLine([
                        r.category.name,
                        r.status.name,
                        r.mapDisplayName,
                      ]),
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
          );
        },
      ),
    ],
  );
}

class _BlueprintRewards extends StatefulWidget {
  const _BlueprintRewards({required this.repo});
  final ArcRaiderContractsRepository repo;

  @override
  State<_BlueprintRewards> createState() => _BlueprintRewardsState();
}

class _BlueprintRewardsState extends State<_BlueprintRewards> {
  final Map<String, Set<String>> selections = <String, Set<String>>{};
  final Set<String> saving = <String>{};

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ArcRaiderContract>>(
    stream: widget.repo.watchMyContracts(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _TrustLoadProblem(
          title: 'Rewards unavailable',
          message:
              'We could not load your Blueprint rewards right now. Your Blueprint Tracker and duplicates have not been changed.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final contracts = snapshot.data!
          .where((contract) => contract.blueprintRewardCount > 0)
          .toList(growable: false);
      if (contracts.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No accepted Rat Contracts currently include Blueprint dupe rewards.',
            ),
          ),
        );
      }
      return ListView.separated(
        padding: AppTheme.pagePadding,
        itemCount: contracts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _contractRewardCard(contracts[index]),
      );
    },
  );

  Widget _contractRewardCard(ArcRaiderContract contract) {
    final locked = {
      ArcRaiderContractStatus.completed,
      ArcRaiderContractStatus.rejected,
      ArcRaiderContractStatus.cancelled,
      ArcRaiderContractStatus.expired,
    }.contains(contract.status);
    final selected = selections.putIfAbsent(
      contract.id,
      () => contract.blueprintRewardSelection.toSet(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ArcTextSanitizer.metadataLine([
                'Blueprint reward',
                contract.targetDisplayName,
              ]),
              style: AppTheme.tradingHeading(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose exactly ${contract.blueprintRewardCount} Blueprint${contract.blueprintRewardCount == 1 ? '' : 's'} from the creator\'s dupes that your tracker still shows as missing.',
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ArcRaiderBlueprintRewardCandidate>>(
              future: widget.repo.loadEligibleBlueprintRewards(contract),
              builder: (context, candidatesSnapshot) {
                if (candidatesSnapshot.hasError) {
                  return Text('Unable to refresh matches right now.');
                }
                if (!candidatesSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final candidates = candidatesSnapshot.data!;
                if (candidates.isEmpty) {
                  return const Text(
                    'There are currently no useful Blueprint overlaps. The creator inventory and your missing list are rechecked before settlement.',
                  );
                }
                return Column(
                  children: [
                    for (final candidate in candidates)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(candidate.name),
                        value: selected.contains(candidate.blueprintId),
                        onChanged: locked
                            ? null
                            : (checked) {
                                setState(() {
                                  if (checked == true) {
                                    if (selected.length <
                                        contract.blueprintRewardCount) {
                                      selected.add(candidate.blueprintId);
                                    }
                                  } else {
                                    selected.remove(candidate.blueprintId);
                                  }
                                });
                              },
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        key: Key('save-blueprint-rewards-${contract.id}'),
                        onPressed:
                            locked ||
                                saving.contains(contract.id) ||
                                selected.length != contract.blueprintRewardCount
                            ? null
                            : () => _save(contract, selected),
                        icon: saving.contains(contract.id)
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          locked
                              ? 'Selection locked'
                              : 'Save ${selected.length}/${contract.blueprintRewardCount}',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(ArcRaiderContract contract, Set<String> selected) async {
    setState(() => saving.add(contract.id));
    try {
      await widget.repo.saveBlueprintRewardSelection(contract.id, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Blueprint reward choices saved. They will be revalidated when the contract is completed.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Blueprint rewards. Try again.')),
      );
    } finally {
      if (mounted) setState(() => saving.remove(contract.id));
    }
  }
}
