import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';

enum UagSessionScheduleKind {
  trade('trade', 'Trade'),
  matchmaking('matchmaking', 'Matchmaking'),
  raid('raid', 'Raid');

  const UagSessionScheduleKind(this.wireName, this.label);

  final String wireName;
  final String label;

  static UagSessionScheduleKind fromWire(String value) {
    final normalized = value.trim().toLowerCase();
    return UagSessionScheduleKind.values.firstWhere(
      (kind) => kind.wireName == normalized || kind.name == normalized,
      orElse: () => UagSessionScheduleKind.trade,
    );
  }
}

enum UagSessionSchedulePhase {
  preSession('pre_session'),
  postSessionFeedback('post_session_feedback');

  const UagSessionSchedulePhase(this.wireName);

  final String wireName;
}

class UagSessionParticipant {
  const UagSessionParticipant({
    required this.uid,
    required this.displayName,
    this.embarkId = '',
  });

  final String uid;
  final String displayName;
  final String embarkId;
}

class UagSessionCalendarPayload {
  const UagSessionCalendarPayload({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.route,
    required this.deepLink,
    required this.reminderMinutesBefore,
    this.participants = const <UagSessionParticipant>[],
  });

  final String id;
  final UagSessionScheduleKind kind;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String route;
  final String deepLink;
  final int reminderMinutesBefore;
  final List<UagSessionParticipant> participants;

  String get googleCalendarUrl {
    final details = StringBuffer(description);
    if (deepLink.trim().isNotEmpty) {
      details
        ..writeln()
        ..writeln()
        ..writeln('Open in UAG: $deepLink');
    }

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_formatUtc(startAt)}/${_formatUtc(endAt)}',
      'details': details.toString().trim(),
      'location': location,
    }).toString();
  }

  String get icsText {
    final alarmDescription = '$title starts in $reminderMinutesBefore minutes.';
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//UniteAGamer//UAG ARC Raiders Hub//EN',
      'BEGIN:VEVENT',
      'UID:${_escapeIcs(id)}@uag-arc-raiders-hub',
      'DTSTAMP:${_formatUtc(DateTime.now())}',
      'DTSTART:${_formatUtc(startAt)}',
      'DTEND:${_formatUtc(endAt)}',
      'SUMMARY:${_escapeIcs(title)}',
      'DESCRIPTION:${_escapeIcs(description)}',
      'LOCATION:${_escapeIcs(location)}',
      'URL:${_escapeIcs(deepLink)}',
      'BEGIN:VALARM',
      'TRIGGER:-PT${reminderMinutesBefore}M',
      'ACTION:DISPLAY',
      'DESCRIPTION:${_escapeIcs(alarmDescription)}',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');
  }
}

class UagSessionNotificationPlan {
  const UagSessionNotificationPlan({
    required this.sessionId,
    required this.kind,
    required this.targetUid,
    required this.preSession,
    required this.postSessionFeedback,
  });

  final String sessionId;
  final UagSessionScheduleKind kind;
  final String targetUid;
  final UagScheduledNotification preSession;
  final UagScheduledNotification postSessionFeedback;

  List<UagScheduledNotification> get schedules => [
    preSession,
    postSessionFeedback,
  ];
}

class UagSessionSchedulePlanner {
  const UagSessionSchedulePlanner();

  static const Duration preSessionOffset = Duration(minutes: 15);
  static const Duration postSessionFeedbackOffset = Duration(minutes: 15);
  static const Duration defaultSessionDuration = Duration(hours: 1);
  static const int defaultReminderMinutesBefore = 15;

  UagSessionCalendarPayload calendarPayload({
    required String sessionId,
    required UagSessionScheduleKind kind,
    required DateTime startAt,
    required String route,
    String deepLink = '',
    Duration duration = defaultSessionDuration,
    String location = 'ARC Raiders',
    String notes = '',
    List<UagSessionParticipant> participants = const <UagSessionParticipant>[],
    int reminderMinutesBefore = defaultReminderMinutesBefore,
  }) {
    final title = _titleFor(kind, participants);
    final description = _descriptionFor(
      kind: kind,
      participants: participants,
      notes: notes,
      route: route,
    );

    return UagSessionCalendarPayload(
      id: sessionId,
      kind: kind,
      title: title,
      description: description,
      startAt: startAt,
      endAt: startAt.add(duration),
      location: location.trim().isEmpty ? 'ARC Raiders' : location.trim(),
      route: route,
      deepLink: deepLink.trim().isEmpty ? route : deepLink.trim(),
      reminderMinutesBefore: reminderMinutesBefore,
      participants: participants,
    );
  }

  UagSessionNotificationPlan notificationPlan({
    required String sessionId,
    required UagSessionScheduleKind kind,
    required String targetUid,
    required DateTime startAt,
    required String route,
    String deepLink = '',
    Duration duration = defaultSessionDuration,
    String otherParticipantName = '',
    String listingId = '',
    String offerId = '',
    String location = 'ARC Raiders',
  }) {
    final endAt = startAt.add(duration);
    final cleanDeepLink = deepLink.trim().isEmpty ? route : deepLink.trim();
    final cleanOther = otherParticipantName.trim();
    final sharedMetadata = <String, String>{
      'sessionId': sessionId,
      'sessionKind': kind.wireName,
      'otherParticipantName': cleanOther,
      'locationPlatform': location.trim(),
      'startsAt': startAt.toUtc().toIso8601String(),
      'endsAt': endAt.toUtc().toIso8601String(),
    };

    return UagSessionNotificationPlan(
      sessionId: sessionId,
      kind: kind,
      targetUid: targetUid,
      preSession: UagScheduledNotification(
        id: scheduleId(
          sessionId: sessionId,
          kind: kind,
          targetUid: targetUid,
          phase: UagSessionSchedulePhase.preSession,
        ),
        targetUid: targetUid,
        type: UagNotificationType.reminder,
        title: _preSessionTitle(kind),
        body: _preSessionBody(kind, cleanOther),
        dueAt: startAt.subtract(preSessionOffset),
        route: route,
        deepLink: cleanDeepLink,
        entityId: sessionId,
        status: 'queued',
        sessionId: sessionId,
        listingId: listingId,
        offerId: offerId,
        priority: UagNotificationPriority.high,
        metadata: {
          ...sharedMetadata,
          'phase': UagSessionSchedulePhase.preSession.wireName,
        },
      ),
      postSessionFeedback: UagScheduledNotification(
        id: scheduleId(
          sessionId: sessionId,
          kind: kind,
          targetUid: targetUid,
          phase: UagSessionSchedulePhase.postSessionFeedback,
        ),
        targetUid: targetUid,
        type: UagNotificationType.postSessionFeedback,
        title: _feedbackTitle(kind),
        body: _feedbackBody(kind),
        dueAt: endAt.add(postSessionFeedbackOffset),
        route: route,
        deepLink: cleanDeepLink,
        entityId: sessionId,
        status: 'queued',
        sessionId: sessionId,
        listingId: listingId,
        offerId: offerId,
        priority: UagNotificationPriority.normal,
        metadata: {
          ...sharedMetadata,
          'phase': UagSessionSchedulePhase.postSessionFeedback.wireName,
          'recommendedAction': _feedbackAction(kind),
        },
      ),
    );
  }

  String scheduleId({
    required String sessionId,
    required UagSessionScheduleKind kind,
    required String targetUid,
    required UagSessionSchedulePhase phase,
  }) {
    return [
      'uag',
      kind.wireName,
      _safeIdComponent(sessionId),
      _safeIdComponent(targetUid),
      phase.wireName,
    ].join('_');
  }

  String _titleFor(
    UagSessionScheduleKind kind,
    List<UagSessionParticipant> participants,
  ) {
    final names = participants
        .map((participant) => participant.displayName.trim())
        .where((name) => name.isNotEmpty)
        .join(' + ');
    if (names.isEmpty) return 'UAG ${kind.label}';
    return 'UAG ${kind.label}: $names';
  }

  String _descriptionFor({
    required UagSessionScheduleKind kind,
    required List<UagSessionParticipant> participants,
    required String notes,
    required String route,
  }) {
    final buffer = StringBuffer()
      ..writeln('Game: ARC Raiders')
      ..writeln('Session type: ${kind.label}');

    for (final participant in participants) {
      final name = participant.displayName.trim();
      final embarkId = participant.embarkId.trim();
      if (name.isEmpty && embarkId.isEmpty) continue;
      buffer.write('Participant: ');
      buffer.write(name.isEmpty ? 'Raider' : name);
      if (embarkId.isNotEmpty) buffer.write(' ($embarkId)');
      buffer.writeln();
    }

    if (notes.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Notes: ${notes.trim()}');
    }

    if (route.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Open in UAG: ${route.trim()}');
    }

    return buffer.toString().trim();
  }

  String _preSessionTitle(UagSessionScheduleKind kind) {
    return '${kind.label} starts in 15 minutes';
  }

  String _preSessionBody(UagSessionScheduleKind kind, String otherName) {
    final withText = otherName.isEmpty ? '' : ' with $otherName';
    switch (kind) {
      case UagSessionScheduleKind.trade:
        return 'Your ARC Raiders trade$withText starts in 15 minutes. Open the session to confirm or rearrange.';
      case UagSessionScheduleKind.matchmaking:
        return 'Your Match Rider squad-up$withText starts in 15 minutes. Open the session to get ready.';
      case UagSessionScheduleKind.raid:
        return 'Your planned ARC Raiders run$withText starts in 15 minutes. Open the planner to get ready.';
    }
  }

  String _feedbackTitle(UagSessionScheduleKind kind) {
    switch (kind) {
      case UagSessionScheduleKind.trade:
        return 'How did the trade go?';
      case UagSessionScheduleKind.matchmaking:
        return 'How did the squad-up go?';
      case UagSessionScheduleKind.raid:
        return 'How did the raid go?';
    }
  }

  String _feedbackBody(UagSessionScheduleKind kind) {
    switch (kind) {
      case UagSessionScheduleKind.trade:
        return 'Confirm completed, no-show or issues so UAG can protect session quality.';
      case UagSessionScheduleKind.matchmaking:
        return 'Share a quick rating, no-show or issue report so Match Rider learns from the session.';
      case UagSessionScheduleKind.raid:
        return 'Log the result, no-show or support issue so your planned run history stays accurate.';
    }
  }

  String _feedbackAction(UagSessionScheduleKind kind) {
    switch (kind) {
      case UagSessionScheduleKind.trade:
        return 'confirm_trade_outcome';
      case UagSessionScheduleKind.matchmaking:
        return 'submit_match_feedback';
      case UagSessionScheduleKind.raid:
        return 'submit_raid_feedback';
    }
  }
}

String _safeIdComponent(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'unknown';
  final buffer = StringBuffer();
  for (final codeUnit in normalized.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isLetter) {
      buffer.writeCharCode(codeUnit);
    } else {
      buffer.write('_');
    }
  }
  return buffer.toString().replaceAll(RegExp('_+'), '_');
}

String _formatUtc(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

String _escapeIcs(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');
}
