import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_form_surface.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
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
  bool _loadFailed = false;

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
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final status = await _repository.getAwayStatus();
      _noteController.text = status.note;
      if (mounted) {
        setState(() {
          _awayStatus = status;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save away mode. Try again.')),
      );
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
    Widget actionCard({required List<Widget> children}) {
      return Container(
        padding: ArcUiTokens.compactPanelPadding,
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.panel,
          accent: ArcUiTokens.secondaryAccent,
          borderOpacity: 0.18,
          radius: ArcUiTokens.radiusL,
        ),
        child: Column(children: children),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Away Mode',
        subtitle: 'Temporarily pause discovery and new trade requests.',
        showLogout: false,
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ArcUiTokens.primaryAccent,
                ),
              )
            : _loadFailed
            ? SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: ArcUiTokens.compactPanelPadding,
                      child: ArcRaidersStatePanel(
                        title: 'Away status unavailable',
                        message: 'Your away settings could not load right now.',
                        icon: Icons.cloud_off_rounded,
                        accent: ArcUiTokens.warning,
                        action: TextButton.icon(
                          style: ArcUiTokens.textButtonStyle(
                            accent: ArcUiTokens.primaryAccent,
                          ),
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView(
                      padding: ArcUiTokens.compactPanelPadding,
                      children: [
                        const ArcFormPageLead(
                          icon: Icons.do_not_disturb_on_outlined,
                          title: 'Away Mode',
                          subtitle:
                              'Pause discovery while you are unavailable.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ArcTacticalStatTile(
                              label: 'Status',
                              value: _awayStatus.isAway ? 'Away' : 'Available',
                              icon: _awayStatus.isAway
                                  ? Icons.do_not_disturb_on_outlined
                                  : Icons.verified_rounded,
                              accent: _awayStatus.isAway
                                  ? ArcUiTokens.warning
                                  : ArcUiTokens.success,
                            ),
                            ArcTacticalStatTile(
                              label: 'From',
                              value: _format(_awayStatus.from),
                              icon: Icons.login_rounded,
                              accent: ArcUiTokens.primaryAccent,
                            ),
                            ArcTacticalStatTile(
                              label: 'To',
                              value: _format(_awayStatus.to),
                              icon: Icons.logout_rounded,
                              accent: ArcUiTokens.secondaryAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                              activeThumbColor: ArcUiTokens.secondaryAccent,
                              title: Text(
                                'Set yourself away',
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Hide from discovery and pause new trade requests.',
                                style: ArcUiTokens.bodySmall(),
                              ),
                            ),
                            Divider(color: ArcUiTokens.borderSubtle),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Away from',
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                _format(_awayStatus.from),
                                style: ArcUiTokens.bodySmall(),
                              ),
                              trailing: const Icon(
                                Icons.calendar_month,
                                color: ArcUiTokens.primaryAccent,
                              ),
                              onTap: () => _pickDateTime(isFrom: true),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Away to',
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                _format(_awayStatus.to),
                                style: ArcUiTokens.bodySmall(),
                              ),
                              trailing: const Icon(
                                Icons.calendar_month,
                                color: ArcUiTokens.primaryAccent,
                              ),
                              onTap: () => _pickDateTime(isFrom: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        TextField(
                          controller: _noteController,
                          style: ArcUiTokens.body(
                            color: ArcUiTokens.textPrimary,
                          ),
                          decoration: ArcUiTokens.inputDecoration(
                            labelText: 'Note',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        ElevatedButton.icon(
                          style: ArcUiTokens.textButtonStyle(primary: true),
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
      ),
    );
  }
}
