import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_availability.dart';
import '../repositories/arc_trader_profile_repository.dart';

class ArcAvailabilityScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile/availability';

  const ArcAvailabilityScreen({super.key});

  @override
  State<ArcAvailabilityScreen> createState() => _ArcAvailabilityScreenState();
}

class _ArcAvailabilityScreenState extends State<ArcAvailabilityScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();

  ArcAvailability _availability = ArcAvailability.initial();
  bool _isLoading = true;
  bool _isSaving = false;

  static const Map<String, String> _dayLabels = {
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repository.getAvailability();
    if (mounted) {
      setState(() {
        _availability = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _repository.saveAvailability(_availability);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateWeekSlot(int weekIndex, int slotIndex, ArcAvailabilitySlot slot) {
    final weeks = [..._availability.weeks];
    final slots = [...weeks[weekIndex].slots];
    slots[slotIndex] = slot;
    weeks[weekIndex] = weeks[weekIndex].copyWith(slots: slots);
    setState(() => _availability = _availability.copyWith(weeks: weeks));
  }

  void _setScheduleType(String value) {
    final needsTwoWeeks = value == 'rotation';
    final weeks = needsTwoWeeks
        ? [
            _availability.weeks.isNotEmpty
                ? _availability.weeks.first.copyWith(label: 'Week 1')
                : ArcAvailabilityWeek.empty('Week 1'),
            _availability.weeks.length > 1
                ? _availability.weeks[1].copyWith(label: 'Week 2')
                : ArcAvailabilityWeek.empty('Week 2'),
          ]
        : [
            _availability.weeks.isNotEmpty
                ? _availability.weeks.first.copyWith(label: 'Week 1')
                : ArcAvailabilityWeek.empty('Week 1'),
          ];
    setState(() {
      _availability = _availability.copyWith(
        scheduleType: value,
        useEveryWeek: value != 'rotation',
        weeks: weeks,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget heroCard() {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.raised,
          accent: ArcUiTokens.primaryAccent,
          borderOpacity: 0.24,
          radius: ArcUiTokens.radiusXL,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ArcUiTokens.primaryAccent.withValues(alpha: 0.10),
                border: Border.all(
                  color: ArcUiTokens.primaryAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: ArcUiTokens.primaryAccent,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Availability',
                    style: ArcUiTokens.pageTitle(
                      fontSize: 24,
                      color: ArcUiTokens.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let traders know your real raid windows without changing the data you already capture.',
                    style: ArcUiTokens.body(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Availability'),
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ArcUiTokens.primaryAccent,
                ),
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      children: [
                        heroCard(),
                        const SizedBox(height: AppTheme.spaceM),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          decoration: ArcUiTokens.surfaceDecoration(
                            role: ArcSurfaceRole.panel,
                            accent: ArcUiTokens.primaryAccent,
                            borderOpacity: 0.18,
                            radius: ArcUiTokens.radiusL,
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _availability.scheduleType,
                            dropdownColor: ArcUiTokens.surfaceOverlay,
                            style: ArcUiTokens.body(
                              color: ArcUiTokens.textPrimary,
                            ),
                            iconEnabledColor: ArcUiTokens.primaryAccent,
                            decoration: ArcUiTokens.inputDecoration(
                              labelText: 'Schedule Type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text('Same every week'),
                              ),
                              DropdownMenuItem(
                                value: 'rotation',
                                child: Text('Two-week rotation'),
                              ),
                              DropdownMenuItem(
                                value: 'flexible',
                                child: Text('Flexible / shift-based'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              _setScheduleType(value);
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        ...List.generate(_availability.weeks.length, (
                          weekIndex,
                        ) {
                          final week = _availability.weeks[weekIndex];
                          return _weekCard(week, weekIndex);
                        }),
                        ElevatedButton.icon(
                          style: ArcUiTokens.textButtonStyle(primary: true),
                          onPressed: _isSaving ? null : _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Availability',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _weekCard(ArcAvailabilityWeek week, int weekIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.18,
        radius: ArcUiTokens.radiusL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            week.label,
            style: ArcUiTokens.sectionTitle(
              fontSize: 20,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...List.generate(week.slots.length, (slotIndex) {
            final slot = week.slots[slotIndex];
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final dayLabel =
                    _dayLabels[slot.dayKey] ?? slot.dayKey.toUpperCase();
                final enabledSwitch = Switch(
                  value: slot.enabled,
                  activeThumbColor: ArcUiTokens.primaryAccent,
                  onChanged: (value) {
                    _updateWeekSlot(
                      weekIndex,
                      slotIndex,
                      slot.copyWith(enabled: value),
                    );
                  },
                );
                final fromField = TextFormField(
                  initialValue: slot.fromTime,
                  style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                  decoration: ArcUiTokens.inputDecoration(labelText: 'From'),
                  onChanged: (value) {
                    _updateWeekSlot(
                      weekIndex,
                      slotIndex,
                      slot.copyWith(fromTime: value),
                    );
                  },
                );
                final toField = TextFormField(
                  initialValue: slot.toTime,
                  style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                  decoration: ArcUiTokens.inputDecoration(labelText: 'To'),
                  onChanged: (value) {
                    _updateWeekSlot(
                      weekIndex,
                      slotIndex,
                      slot.copyWith(toTime: value),
                    );
                  },
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  padding: const EdgeInsets.all(AppTheme.spaceS),
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.interactive,
                    accent: slot.enabled
                        ? ArcUiTokens.primaryAccent
                        : ArcUiTokens.textTertiary,
                    borderOpacity: slot.enabled ? 0.22 : 0.10,
                    radius: ArcUiTokens.radiusM,
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dayLabel,
                                    style: ArcUiTokens.sectionTitle(
                                      fontSize: 15,
                                      color: ArcUiTokens.textPrimary,
                                    ),
                                  ),
                                ),
                                enabledSwitch,
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            Row(
                              children: [
                                Expanded(child: fromField),
                                const SizedBox(width: AppTheme.spaceS),
                                Expanded(child: toField),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                dayLabel,
                                style: ArcUiTokens.sectionTitle(
                                  fontSize: 15,
                                  color: ArcUiTokens.textPrimary,
                                ),
                              ),
                            ),
                            enabledSwitch,
                            Expanded(child: fromField),
                            const SizedBox(width: AppTheme.spaceS),
                            Expanded(child: toField),
                          ],
                        ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
