import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_session_schedule_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/embark_id_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/session_creation_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/session_model.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/session_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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

  UagSessionCalendarPayload _calendarPayload(UagSession session) {
    final kind = switch (session.type.trim().toLowerCase()) {
      'matchmaking' ||
      'match' ||
      'match_rider' => UagSessionScheduleKind.matchmaking,
      'raid' || 'planner' => UagSessionScheduleKind.raid,
      _ => UagSessionScheduleKind.trade,
    };

    return const UagSessionSchedulePlanner().calendarPayload(
      sessionId: session.id,
      kind: kind,
      startAt: session.scheduledAt,
      route: SessionPlannerScreen.routeName,
      deepLink: SessionPlannerScreen.routeName,
      location: 'ARC Raiders',
      notes: session.notes ?? '',
      participants: [
        UagSessionParticipant(
          uid: session.participantOneUid,
          displayName: session.participantOneDisplayName,
          embarkId: session.participantOneEmbarkId,
        ),
        UagSessionParticipant(
          uid: session.participantTwoUid,
          displayName: session.participantTwoDisplayName,
          embarkId: session.participantTwoEmbarkId,
        ),
      ],
    );
  }

  Future<void> _addToCalendar(UagSession session) async {
    final payload = _calendarPayload(session);

    final event = Event(
      title: payload.title,
      description: payload.description,
      location: payload.location,
      startDate: payload.startAt,
      endDate: payload.endAt,
    );

    await Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _share(UagSession session) async {
    final payload = _calendarPayload(session);
    final text = StringBuffer()
      ..writeln('UAG ${session.type} session for ARC Raiders')
      ..writeln('When: ${payload.startAt}')
      ..writeln('With: ${session.participantTwoDisplayName}')
      ..writeln('Embark ID: ${session.participantTwoEmbarkId}');

    if (session.notes?.isNotEmpty == true) {
      text.writeln('Notes: ${session.notes}');
    }
    text
      ..writeln()
      ..writeln('Calendar link: ${payload.googleCalendarUrl}')
      ..writeln()
      ..writeln(payload.icsText);

    await SharePlus.instance.share(ShareParams(text: text.toString().trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Session Planner'),
        actions: [
          IconButton(
            tooltip: 'Ask UAG Raider',
            onPressed: () => UagVoiceArcAssistantSheet.show(context),
            icon: const Icon(Icons.mic_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ArcUiTokens.secondaryAccent.withValues(alpha: 0.92),
        foregroundColor: ArcUiTokens.background,
        onPressed: () => SessionCreationSheet.show(context, _repository),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Session'),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: StreamBuilder<List<UagSession>>(
          stream: _repository.streamMySessions(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load sessions: ${snapshot.error}',
                  style: ArcUiTokens.body(),
                ),
              );
            }

            final sessions = snapshot.data ?? const <UagSession>[];
            final selected = _sessionsForDay(
              sessions,
              _selectedDay ?? _focusedDay,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceL,
                AppTheme.spaceL,
                AppTheme.spaceL,
                104,
              ),
              children: [
                TradingCard(
                  accent: AppTheme.neonCyan,
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
                      defaultTextStyle: const TextStyle(
                        color: ArcUiTokens.textPrimary,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        color: ArcUiTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: ArcUiTokens.textSecondary),
                      weekendStyle: TextStyle(color: ArcUiTokens.textTertiary),
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
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 22,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                if (selected.isEmpty)
                  TradingCard(
                    accent: AppTheme.neonCyan,
                    child: Text(
                      'No sessions on this day.',
                      style: ArcUiTokens.body(),
                    ),
                  )
                else
                  ...selected.map(_buildSessionCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionCard(UagSession session) {
    final color = session.type == 'trade'
        ? AppTheme.neonCyan
        : AppTheme.neonPink;

    return TradingCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      accent: color,
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
                  '${session.type.toUpperCase()} - ${session.status}',
                  style: AppTheme.tradingHeading(fontSize: 16, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            session.scheduledAt.toString(),
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
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
              style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(),
                onPressed: () => _repository.toggleReady(session),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Ready'),
              ),
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(),
                onPressed: () => _repository.markComplete(session),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Complete'),
              ),
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.attentionAccent,
                ),
                onPressed: () => _repository.markNoShow(session),
                icon: const Icon(Icons.report_gmailerrorred_rounded),
                label: const Text('No-show'),
              ),
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(),
                onPressed: () => _addToCalendar(session),
                icon: const Icon(Icons.event_rounded),
                label: const Text('Calendar'),
              ),
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(),
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
