import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/embark_id_card.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_creation_sheet.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_model.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SessionPlannerScreen extends StatefulWidget {
  const SessionPlannerScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/session-planner';

  @override
  State<SessionPlannerScreen> createState() => _SessionPlannerScreenState();
}

class _SessionPlannerScreenState extends State<SessionPlannerScreen> {
  final UagSessionRepository _repository = UagSessionRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<UagSession> _sessionsForDay(List<UagSession> sessions, DateTime day) {
    return sessions
        .where((session) => isSameDay(session.scheduledAt, day))
        .toList(growable: false);
  }

  Future<void> _addToCalendar(UagSession session) async {
    final description = StringBuffer()
      ..writeln('Game: ARC Raiders')
      ..writeln('Embark ID: ${session.participantTwoEmbarkId}')
      ..writeln('Notes: ${session.notes ?? ''}');

    final event = Event(
      title:
          'UAG ${session.type == 'trade' ? 'Trade' : 'Match'}: ${session.participantTwoDisplayName}',
      description: description.toString().trim(),
      startDate: session.scheduledAt,
      endDate: session.scheduledAt.add(const Duration(hours: 1)),
    );

    await Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _share(UagSession session) async {
    final text = StringBuffer()
      ..writeln('UAG ${session.type} session for ARC Raiders')
      ..writeln('When: ${session.scheduledAt}')
      ..writeln('With: ${session.participantTwoDisplayName}')
      ..writeln('Embark ID: ${session.participantTwoEmbarkId}');

    if (session.notes?.isNotEmpty == true) {
      text.writeln('Notes: ${session.notes}');
    }

    await Share.share(text.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Session Planner'),
        actions: [
          IconButton(
            tooltip: 'Ask UAG Raider',
            onPressed: () => UagVoiceAssistantSheet.show(context),
            icon: const Icon(Icons.mic_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.neonPink.withValues(alpha: 0.92),
        foregroundColor: AppTheme.darkBackground,
        onPressed: () => SessionCreationSheet.show(context, _repository),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Session'),
      ),
      body: Stack(
        children: [
          const StaticWatermark(),
          StreamBuilder<List<UagSession>>(
            stream: _repository.streamMySessions(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load sessions: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final sessions = snapshot.data ?? const <UagSession>[];
              final selected = _sessionsForDay(
                sessions,
                _selectedDay ?? _focusedDay,
              );

              return ListView(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                children: [
                  Container(
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: AppTheme.neonCyan.withValues(alpha: 0.26),
                    ),
                    child: TableCalendar<UagSession>(
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: (day) => _sessionsForDay(sessions, day),
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(
                          color: AppTheme.neonPink,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.neonCyan.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.neonPink,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.white70),
                      ),
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white70),
                        weekendStyle: TextStyle(color: Colors.white54),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  Text(
                    'Sessions',
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: AppTheme.neonPink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  if (selected.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceL),
                      decoration: AppTheme.tradingCardDecoration(),
                      child: Text(
                        'No sessions on this day.',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  else
                    ...selected.map(_buildSessionCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(UagSession session) {
    final color = session.type == 'trade' ? AppTheme.neonCyan : AppTheme.neonPink;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: color.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.type == 'trade'
                    ? Icons.swap_horiz_rounded
                    : Icons.groups_rounded,
                color: color,
              ),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  '${session.type.toUpperCase()} • ${session.status}',
                  style: AppTheme.tradingHeading(fontSize: 16, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            session.scheduledAt.toString(),
            style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          EmbarkIdCard(
            label: session.participantTwoDisplayName,
            embarkId: session.participantTwoEmbarkId,
          ),
          if (session.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              session.notes!,
              style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              OutlinedButton.icon(
                onPressed: () => _repository.toggleReady(session),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Ready'),
              ),
              OutlinedButton.icon(
                onPressed: () => _repository.markComplete(session),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Complete'),
              ),
              OutlinedButton.icon(
                onPressed: () => _repository.markNoShow(session),
                icon: const Icon(Icons.report_gmailerrorred_rounded),
                label: const Text('No-show'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addToCalendar(session),
                icon: const Icon(Icons.event_rounded),
                label: const Text('Calendar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _share(session),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
