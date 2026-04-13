import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Availability')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _availability.scheduleType,
                    decoration: const InputDecoration(
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
                  const SizedBox(height: AppTheme.spaceL),
                  ...List.generate(_availability.weeks.length, (weekIndex) {
                    final week = _availability.weeks[weekIndex];
                    return _weekCard(week, weekIndex);
                  }),
                  const SizedBox(height: AppTheme.spaceL),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: Text(_isSaving ? 'Saving...' : 'Save Availability'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _weekCard(ArcAvailabilityWeek week, int weekIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            week.label,
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...List.generate(week.slots.length, (slotIndex) {
            final slot = week.slots[slotIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      _dayLabels[slot.dayKey] ?? slot.dayKey.toUpperCase(),
                    ),
                  ),
                  Switch(
                    value: slot.enabled,
                    onChanged: (value) {
                      _updateWeekSlot(
                        weekIndex,
                        slotIndex,
                        slot.copyWith(enabled: value),
                      );
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: slot.fromTime,
                      decoration: const InputDecoration(labelText: 'From'),
                      onChanged: (value) {
                        _updateWeekSlot(
                          weekIndex,
                          slotIndex,
                          slot.copyWith(fromTime: value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: TextFormField(
                      initialValue: slot.toTime,
                      decoration: const InputDecoration(labelText: 'To'),
                      onChanged: (value) {
                        _updateWeekSlot(
                          weekIndex,
                          slotIndex,
                          slot.copyWith(toTime: value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
