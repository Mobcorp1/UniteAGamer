import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_away_status.dart';
import '../repositories/arc_trader_profile_repository.dart';

class ArcAwayScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/profile/away';

  const ArcAwayScreen({super.key});

  @override
  State<ArcAwayScreen> createState() => _ArcAwayScreenState();
}

class _ArcAwayScreenState extends State<ArcAwayScreen> {
  final ArcTraderProfileRepository _repository = ArcTraderProfileRepository();
  final TextEditingController _noteController = TextEditingController();

  ArcAwayStatus _awayStatus = ArcAwayStatus.initial();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final status = await _repository.getAwayStatus();
    _noteController.text = status.note;
    if (mounted) {
      setState(() {
        _awayStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_awayStatus.from ?? now)
        : (_awayStatus.to ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _awayStatus = isFrom
          ? _awayStatus.copyWith(from: dateTime)
          : _awayStatus.copyWith(to: dateTime);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _repository.saveAwayStatus(
        _awayStatus.copyWith(note: _noteController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _format(DateTime? value) {
    if (value == null) return 'Not set';
    return '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget heroCard() {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          radius: 24,
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.do_not_disturb_on_outlined,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Away Mode',
                    style: AppTheme.tradingHeading(
                      fontSize: 24,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pause trade requests while you are away, working, travelling or taking a break.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget actionCard({required List<Widget> children}) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(radius: 22),
        child: Column(children: children),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Away Mode')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    children: [
                      heroCard(),
                      const SizedBox(height: AppTheme.spaceM),
                      actionCard(
                        children: [
                          SwitchListTile(
                            value: _awayStatus.isAway,
                            onChanged: (value) {
                              setState(() {
                                _awayStatus = _awayStatus.copyWith(
                                  isAway: value,
                                );
                              });
                            },
                            activeThumbColor: AppTheme.neonPink,
                            title: const Text('Set yourself away'),
                            subtitle: const Text(
                              'Hide from search and pause new trade requests while away.',
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Away from'),
                            subtitle: Text(_format(_awayStatus.from)),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () => _pickDateTime(isFrom: true),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Away to'),
                            subtitle: Text(_format(_awayStatus.to)),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () => _pickDateTime(isFrom: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: _noteController,
                        decoration: AppTheme.tradingInputDecoration(
                          label: 'Note',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Away Status',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
