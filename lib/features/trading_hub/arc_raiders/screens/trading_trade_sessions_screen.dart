import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingTradeSessionsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/sessions';

  const TradingTradeSessionsScreen({super.key});

  @override
  State<TradingTradeSessionsScreen> createState() =>
      _TradingTradeSessionsScreenState();
}

class _TradingTradeSessionsScreenState
    extends State<TradingTradeSessionsScreen> {
  final TradingRepository _repository = TradingRepository();

  Color _statusColor(TradingSessionStatus status) {
    switch (status) {
      case TradingSessionStatus.pending:
        return AppTheme.tradingWarning;
      case TradingSessionStatus.scheduled:
        return AppTheme.neonCyan;
      case TradingSessionStatus.ready:
        return AppTheme.neonPink;
      case TradingSessionStatus.completed:
        return AppTheme.tradingSuccess;
      case TradingSessionStatus.noShow:
        return AppTheme.tradingDanger;
      case TradingSessionStatus.cancelled:
        return AppTheme.tradingWarning;
      case TradingSessionStatus.betrayal:
        return AppTheme.tradingDanger;
    }
  }

  String _formatScheduled(DateTime? value) {
    if (value == null) return 'Not scheduled yet';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppTheme.tradingMutedText,
            fontSize: 14,
            fontFamily: AppTheme.bodyFontFamily,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppTheme.neonPink,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _checkItem(String text, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: complete
                ? AppTheme.tradingSuccess
                : AppTheme.tradingFaintText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.tradingMutedText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSchedule(BuildContext context, TradingSession session) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: session.scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (selectedDate == null || !context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(session.scheduledAt ?? now),
    );
    if (selectedTime == null || !context.mounted) return;

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      await _repository.updateSessionSchedule(
        session: session,
        scheduledAt: scheduledAt,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade time updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update schedule: $error')),
      );
    }
  }

  Future<void> _shareEmbarkId(BuildContext context, TradingSession session) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.tradingCardBackground,
          title: const Text('Share Embark ID', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.tradingInputDecoration(label: 'Embark ID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.shareMyEmbarkId(session, controller.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Embark ID shared.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share Embark ID: $error')),
      );
    }
  }

  Future<void> _pickDropOrder(BuildContext context, TradingSession session) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.tradingCardBackground,
          title: const Text('First Drop', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(session.traderOneName, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(dialogContext).pop(session.traderOneUid),
              ),
              ListTile(
                title: Text(session.traderTwoName, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(dialogContext).pop(session.traderTwoUid),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;

    try {
      await _repository.assignFirstDrop(session: session, firstDropUid: selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First drop updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update first drop: $error')),
      );
    }
  }

  Future<void> _shareInvite(TradingSession session) async {
    await Share.share(_repository.buildSessionInviteText(session));
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildSessionCard(TradingSession session) {
    final statusColor = _statusColor(session.status);
    final sharedBoth =
        session.traderOneSharedEmbarkId && session.traderTwoSharedEmbarkId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.tradingCardDecoration(),
      child: Padding(
        padding: AppTheme.sectionCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.traderOneName} ↔ ${session.traderTwoName}',
              style: AppTheme.tradingHeading(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(session.statusLabel, statusColor),
                _chip(session.protocolLabel, AppTheme.neonCyan),
                _chip(session.timezone, AppTheme.neonPink),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('Scheduled', _formatScheduled(session.scheduledAt)),
            _infoRow(
              'Drop Order',
              session.dropOrderAssigned ? 'Assigned' : 'Not assigned yet',
            ),
            _infoRow(
              'First Drop UID',
              session.firstDropUid.isEmpty ? 'Not set' : session.firstDropUid,
            ),
            _infoRow(
              'Embark IDs',
              sharedBoth ? 'Both traders shared' : 'Still waiting on one or both traders',
            ),
            const SizedBox(height: 10),
            Divider(color: AppTheme.tradingDivider),
            const SizedBox(height: 10),
            Text(
              'Trade Checklist',
              style: AppTheme.tradingHeading(
                fontSize: 20,
                color: AppTheme.neonPink,
              ),
            ),
            const SizedBox(height: 10),
            _checkItem('Embark IDs shared', sharedBoth),
            _checkItem('Drop order assigned', session.dropOrderAssigned),
            _checkItem('Both traders marked ready', session.bothReady),
            _checkItem(
              'Safe Pocket protocol selected',
              session.protocolType ==
                  TradingProtocolType.sequentialSafePocketSwap,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(
                  label: 'Book Time',
                  icon: Icons.calendar_month_rounded,
                  onPressed: () => _pickSchedule(context, session),
                ),
                _actionButton(
                  label: 'Share Invite',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => _shareInvite(session),
                ),
                _actionButton(
                  label: 'Share Embark ID',
                  icon: Icons.badge_outlined,
                  onPressed: () => _shareEmbarkId(context, session),
                ),
                _actionButton(
                  label: 'Assign First Drop',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: () => _pickDropOrder(context, session),
                ),
                _actionButton(
                  label: 'I am Ready',
                  icon: Icons.check_circle_outline,
                  onPressed: () async {
                    try {
                      await _repository.setMyReadyState(session, true);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ready status updated.')),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not update readiness: $error')),
                      );
                    }
                  },
                ),
                _actionButton(
                  label: 'Mark Complete',
                  icon: Icons.task_alt_rounded,
                  onPressed: () async {
                    try {
                      await _repository.markMySessionOutcome(
                        session: session,
                        outcome: TradingSessionStatus.completed,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completion marked.')),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not mark complete: $error')),
                      );
                    }
                  },
                ),
                _actionButton(
                  label: 'Mark No-Show',
                  icon: Icons.person_off_outlined,
                  onPressed: () async {
                    try {
                      await _repository.markMySessionOutcome(
                        session: session,
                        outcome: TradingSessionStatus.noShow,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No-show recorded.')),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not record no-show: $error')),
                      );
                    }
                  },
                ),
                _actionButton(
                  label: 'Flag Betrayal',
                  icon: Icons.gpp_bad_outlined,
                  onPressed: () async {
                    try {
                      await _repository.markMySessionOutcome(
                        session: session,
                        outcome: TradingSessionStatus.betrayal,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Betrayal flagged.')),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not flag betrayal: $error')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: AppTheme.tradingDivider),
            const SizedBox(height: 10),
            Text(
              'Use Book Time to lock the trade window like a calendar invite. Share Invite copies the session details to send on chat apps, and the notification system now alerts the other trader when booking changes land.',
              style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'No trade sessions found yet.',
        style: TextStyle(color: AppTheme.tradingMutedText, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Trade Sessions',
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: StreamBuilder<List<TradingSession>>(
                  stream: _repository.watchMySessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.neonCyan,
                        ),
                      );
                    }

                    final sessions = snapshot.data ?? const <TradingSession>[];

                    if (sessions.isEmpty) {
                      return _emptyState();
                    }

                    return ListView.builder(
                      padding: AppTheme.pagePadding,
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return _buildSessionCard(sessions[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
