import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_session_schedule_models.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_cosmetic_identity_strip.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingTradeSessionsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/sessions';

  const TradingTradeSessionsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingTradeSessionsScreen> createState() =>
      _TradingTradeSessionsScreenState();
}

class _TradingTradeSessionsScreenState
    extends State<TradingTradeSessionsScreen> {
  final TradingRepository _repository = TradingRepository();

  String? get _currentUid => _repository.currentUid;

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
      case TradingSessionStatus.betrayal:
        return AppTheme.tradingDanger;
      case TradingSessionStatus.cancelled:
        return AppTheme.warningAmber;
    }
  }

  bool _isTraderOne(TradingSession session) =>
      _currentUid == session.traderOneUid;

  bool _isProposer(TradingSession session) =>
      session.bookingProposedByUid.isNotEmpty &&
      session.bookingProposedByUid == _currentUid;

  bool _needsBookingChoice(TradingSession session) =>
      session.hasBookingOptions &&
      !session.hasConfirmedBooking &&
      !_isProposer(session);

  String _otherTraderName(TradingSession session) =>
      _isTraderOne(session) ? session.traderTwoName : session.traderOneName;

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Not confirmed yet';
    return '${_formatDate(value)} - ${_formatTime(value)}';
  }

  bool _isStartingSoon(TradingSession session) {
    final when = session.selectedBooking ?? session.scheduledAt;
    if (when == null) return false;
    final diff = when.difference(DateTime.now());
    return !diff.isNegative && diff <= const Duration(minutes: 30);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSessionReadinessPanel(TradingSession session) async {
    final confirmedBooking = session.selectedBooking ?? session.scheduledAt;
    final isReady = _isTraderOne(session)
        ? session.traderOneReady
        : session.traderTwoReady;
    final myEmbarkShared = _isTraderOne(session)
        ? session.traderOneSharedEmbarkId
        : session.traderTwoSharedEmbarkId;
    final bothEmbarkIdsShared =
        session.traderOneSharedEmbarkId && session.traderTwoSharedEmbarkId;
    final myEmbarkId = _isTraderOne(session)
        ? session.traderOneEmbarkId
        : session.traderTwoEmbarkId;
    final otherEmbarkId = _isTraderOne(session)
        ? session.traderTwoEmbarkId
        : session.traderOneEmbarkId;
    final firstDropLabel = session.dropOrderAssigned
        ? (session.firstDropUid == session.traderOneUid
              ? session.traderOneName
              : session.traderTwoName)
        : 'Not assigned yet';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(AppTheme.spaceM),
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.overlay,
            accent: ArcUiTokens.secondaryAccent,
            borderOpacity: 0.32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session readiness',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 18,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${session.traderOneName} vs ${session.traderTwoName}',
                  style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _sessionReadinessRow(
                  'Confirmed slot',
                  _formatDateTime(confirmedBooking),
                  confirmedBooking != null,
                ),
                _sessionReadinessRow(
                  'My Embark ID',
                  myEmbarkId.trim().isEmpty
                      ? 'Not shared yet'
                      : myEmbarkId.trim(),
                  myEmbarkShared,
                ),
                _sessionReadinessRow(
                  '${_otherTraderName(session)} Embark ID',
                  otherEmbarkId.trim().isEmpty
                      ? 'Waiting for trader'
                      : otherEmbarkId.trim(),
                  bothEmbarkIdsShared,
                ),
                _sessionReadinessRow(
                  'First drop',
                  firstDropLabel,
                  session.dropOrderAssigned,
                ),
                _sessionReadinessRow(
                  'Ready check',
                  session.bothReady
                      ? 'Both traders ready'
                      : isReady
                      ? 'Waiting for trader'
                      : 'Mark yourself ready',
                  session.bothReady,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _actionButton(
                      label: 'Share invite',
                      icon: Icons.ios_share_rounded,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _shareInvite(session);
                      },
                    ),
                    _actionButton(
                      label: session.hasBookingOptions
                          ? 'Update proposals'
                          : 'Propose times',
                      icon: Icons.calendar_month_rounded,
                      highlighted: confirmedBooking == null,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openBookingComposer(session);
                      },
                    ),
                    _actionButton(
                      label: myEmbarkShared
                          ? 'Update Embark ID'
                          : 'Share Embark ID',
                      icon: Icons.badge_outlined,
                      highlighted: !myEmbarkShared,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _shareEmbarkId(session);
                      },
                    ),
                    _actionButton(
                      label: isReady ? 'Unready' : 'I am ready',
                      icon: isReady
                          ? Icons.remove_circle_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      highlighted: confirmedBooking != null && !isReady,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _runAction(
                          () => _repository.setMyReadyState(session, !isReady),
                          successMessage: isReady
                              ? 'Ready status removed.'
                              : 'Ready status updated.',
                          errorPrefix: 'Could not update readiness: ',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
    required String errorPrefix,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$errorPrefix$error')));
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
            side: BorderSide(color: confirmColor.withValues(alpha: 0.30)),
          ),
          title: Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 18, color: confirmColor),
          ),
          content: Text(
            message,
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(accent: confirmColor),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back'),
            ),
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: confirmColor,
                primary: true,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _shareEmbarkId(TradingSession session) async {
    final initialValue = await _repository.getPreferredEmbarkIdForSession(
      session,
    );
    final controller = TextEditingController(text: initialValue);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
            side: BorderSide(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.30),
            ),
          ),
          title: Text(
            'Share Embark ID',
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(labelText: 'Embark ID'),
              ),
              const SizedBox(height: 10),
              Text(
                'Loaded from Your Hub Profile if saved there already.',
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
                primary: true,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      () => _repository.shareMyEmbarkId(session, controller.text),
      successMessage: 'Embark ID shared.',
      errorPrefix: 'Could not share Embark ID: ',
    );
  }

  Future<void> _pickDropOrder(TradingSession session) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final options = <MapEntry<String, String>>[
          MapEntry(session.traderOneUid, session.traderOneName),
          MapEntry(session.traderTwoUid, session.traderTwoName),
        ];

        return AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
            side: BorderSide(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.30),
            ),
          ),
          title: Text(
            'Assign First Drop',
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (entry) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                    ),
                    title: Text(
                      entry.value,
                      style: ArcUiTokens.body(
                        color: ArcUiTokens.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      entry.key,
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.textTertiary,
                      ),
                    ),
                    onTap: () => Navigator.of(dialogContext).pop(entry.key),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (selected == null) return;

    await _runAction(
      () =>
          _repository.assignFirstDrop(session: session, firstDropUid: selected),
      successMessage: 'First drop updated.',
      errorPrefix: 'Could not update first drop: ',
    );
  }

  Future<void> _shareInvite(TradingSession session) async {
    await SharePlus.instance.share(
      ShareParams(text: _repository.buildSessionInviteText(session)),
    );
  }

  UagSessionCalendarPayload? _calendarPayload(TradingSession session) {
    final scheduledAt = session.effectiveScheduledAt;
    if (scheduledAt == null) return null;

    return const UagSessionSchedulePlanner().calendarPayload(
      sessionId: session.id,
      kind: UagSessionScheduleKind.trade,
      startAt: scheduledAt,
      route: TradingTradeSessionsScreen.routeName,
      deepLink: TradingTradeSessionsScreen.routeName,
      location: 'ARC Raiders trade session',
      notes:
          'Protocol: ${session.protocolLabel}\nListing ID: ${session.listingId}',
      participants: [
        UagSessionParticipant(
          uid: session.traderOneUid,
          displayName: session.traderOneName,
          embarkId: session.traderOneEmbarkId,
        ),
        UagSessionParticipant(
          uid: session.traderTwoUid,
          displayName: session.traderTwoName,
          embarkId: session.traderTwoEmbarkId,
        ),
      ],
    );
  }

  Future<void> _addToCalendar(TradingSession session) async {
    final payload = _calendarPayload(session);
    if (payload == null) {
      _showSnack('Confirm a booking slot before adding it to your calendar.');
      return;
    }

    await Add2Calendar.addEvent2Cal(
      Event(
        title: payload.title,
        description: payload.description,
        location: payload.location,
        startDate: payload.startAt,
        endDate: payload.endAt,
      ),
    );
  }

  Future<void> _openBookingComposer(TradingSession session) async {
    final now = DateTime.now();
    final optionCount = 3;
    final timeCount = 3;

    final existing = session.bookingOptions;
    final dayValues = List<DateTime?>.generate(optionCount, (index) {
      if (index < existing.length) {
        final value = existing[index].day;
        return DateTime(value.year, value.month, value.day);
      }
      final value = now.add(Duration(days: index + 1));
      return DateTime(value.year, value.month, value.day);
    });

    final timeValues = List<List<TimeOfDay?>>.generate(optionCount, (dayIndex) {
      if (dayIndex < existing.length &&
          existing[dayIndex].times.length == timeCount) {
        return existing[dayIndex].times
            .map(TimeOfDay.fromDateTime)
            .toList(growable: false);
      }
      return <TimeOfDay?>[
        const TimeOfDay(hour: 19, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
        const TimeOfDay(hour: 21, minute: 0),
      ];
    });

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> chooseDay(int index) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dayValues[index] ?? now,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 90)),
              );
              if (picked == null) return;
              setModalState(() {
                dayValues[index] = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                );
              });
            }

            Future<void> chooseTime(int dayIndex, int timeIndex) async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    timeValues[dayIndex][timeIndex] ??
                    const TimeOfDay(hour: 19, minute: 0),
              );
              if (picked == null) return;
              setModalState(() {
                timeValues[dayIndex][timeIndex] = picked;
              });
            }

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppTheme.tradingCardBorder),
              ),
              padding: EdgeInsets.only(
                left: AppTheme.spaceL,
                right: AppTheme.spaceL,
                top: AppTheme.spaceL,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Propose 3 days ‚ 3 times',
                      style: AppTheme.tradingHeading(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build one clean set of nine options for ${_otherTraderName(session)} to choose from.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: AppTheme.tradingMutedText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (
                      var dayIndex = 0;
                      dayIndex < optionCount;
                      dayIndex++
                    ) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: AppTheme.sectionCardPadding,
                        decoration: AppTheme.tradingCardDecoration(
                          backgroundColor: AppTheme.tradingCardBackground,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Day ${dayIndex + 1}',
                              style: AppTheme.tradingHeading(
                                fontSize: 20,
                                color: AppTheme.neonPink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => chooseDay(dayIndex),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: AppTheme.tradingCardDecoration(
                                  borderColor: AppTheme.tradingSoftBorder,
                                  backgroundColor: AppTheme.cardBackground,
                                  radius: 14,
                                ),
                                child: Text(
                                  dayValues[dayIndex] == null
                                      ? 'Choose a day'
                                      : _formatDate(dayValues[dayIndex]!),
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    isBold: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (
                              var timeIndex = 0;
                              timeIndex < timeCount;
                              timeIndex++
                            ) ...[
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => chooseTime(dayIndex, timeIndex),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: timeIndex == timeCount - 1 ? 0 : 10,
                                  ),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: AppTheme.tradingCardDecoration(
                                    borderColor: AppTheme.tradingSoftBorder,
                                    backgroundColor: AppTheme.cardBackground,
                                    radius: 14,
                                  ),
                                  child: Text(
                                    timeValues[dayIndex][timeIndex] == null
                                        ? 'Choose a time'
                                        : timeValues[dayIndex][timeIndex]!
                                              .format(context),
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final bookingOptions =
                                List<TradingBookingOption>.generate(
                                  optionCount,
                                  (dayIndex) {
                                    final day = dayValues[dayIndex];
                                    if (day == null) {
                                      throw Exception(
                                        'Choose all 3 days before saving.',
                                      );
                                    }

                                    final slots = List<DateTime>.generate(
                                      timeCount,
                                      (timeIndex) {
                                        final time =
                                            timeValues[dayIndex][timeIndex];
                                        if (time == null) {
                                          throw Exception(
                                            'Choose all 9 times before saving.',
                                          );
                                        }
                                        return DateTime(
                                          day.year,
                                          day.month,
                                          day.day,
                                          time.hour,
                                          time.minute,
                                        );
                                      },
                                    );

                                    return TradingBookingOption(
                                      day: day,
                                      times: slots,
                                    );
                                  },
                                );

                            await _repository.submitBookingOptions(
                              session: session,
                              bookingOptions: bookingOptions,
                            );

                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop(true);
                          } catch (error) {
                            _showSnack(
                              'Could not save booking options: $error',
                            );
                          }
                        },
                        icon: const Icon(Icons.bolt_rounded),
                        label: const Text('Send proposals'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted == true) {
      _showSnack('Booking options sent.');
    }
  }

  Future<void> _confirmBookingChoice(
    TradingSession session,
    DateTime selected,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Confirm this trade slot?',
      message:
          'This locks the session to ${_formatDate(selected)} at ${_formatTime(selected)}. Both traders will see the confirmed time instantly.',
      confirmText: 'Confirm slot',
      confirmColor: AppTheme.neonPink,
    );
    if (!confirmed) return;

    await _runAction(
      () =>
          _repository.selectBookingOption(session: session, selected: selected),
      successMessage: 'Booking confirmed.',
      errorPrefix: 'Could not confirm booking: ',
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: AppTheme.bodyTextStyle(
            fontSize: 14,
            color: AppTheme.tradingMutedText,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.neonPink,
                isBold: true,
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
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionReadinessRow(String label, String value, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: AppTheme.tradingMutedText,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 14,
                      color: AppTheme.neonCyan,
                      isBold: true,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool highlighted = false,
  }) {
    final borderColor = highlighted
        ? AppTheme.neonPink
        : AppTheme.tradingSoftBorder;
    final child = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppTheme.tradingCardDecoration(
          radius: 16,
          borderColor: borderColor,
          backgroundColor: AppTheme.cardBackground,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: highlighted ? AppTheme.neonPink : AppTheme.neonCyan,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );

    return ElectricChargeBorder(active: highlighted, radius: 16, child: child);
  }

  Widget _bookingPanel(TradingSession session) {
    final confirmedBooking = session.selectedBooking ?? session.scheduledAt;
    final needsChoice = _needsBookingChoice(session);
    final isProposer = _isProposer(session);

    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: needsChoice
            ? AppTheme.neonPink
            : AppTheme.tradingCardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 10),
          if (confirmedBooking != null) ...[
            Text(
              'Confirmed slot',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingFaintText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(confirmedBooking),
              style: AppTheme.bodyTextStyle(
                fontSize: 16,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ] else if (!session.hasBookingOptions) ...[
            Text(
              'No booking options sent yet. One trader needs to send 3 preferred days with 3 times on each day.',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ] else if (isProposer) ...[
            Text(
              'Waiting for ${_otherTraderName(session)} to choose one of your 9 proposed slots.',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ] else ...[
            Text(
              'Choose one slot below to lock this trade in.',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ],
          if (session.bookingProposedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Last proposal sent: ${_formatDateTime(session.bookingProposedAt)}',
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: AppTheme.tradingFaintText,
              ),
            ),
          ],
          if (session.hasBookingOptions) ...[
            const SizedBox(height: 14),
            for (final option in session.bookingOptions) ...[
              Text(
                _formatDate(option.day),
                style: AppTheme.bodyTextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: option.times
                    .map((time) {
                      final isSelected =
                          confirmedBooking?.millisecondsSinceEpoch ==
                          time.millisecondsSinceEpoch;
                      final canTap = needsChoice && !isSelected;
                      final color = isSelected
                          ? AppTheme.neonPink
                          : canTap
                          ? AppTheme.neonCyan
                          : AppTheme.tradingFaintText;

                      final chip = InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: canTap
                            ? () => _confirmBookingChoice(session, time)
                            : null,
                        child: Container(
                          padding: AppTheme.pillPadding,
                          decoration: AppTheme.tradingPillDecoration(
                            color: color,
                          ),
                          child: Text(
                            _formatTime(time),
                            style: AppTheme.bodyTextStyle(
                              fontSize: 12,
                              color: color,
                              isBold: true,
                            ),
                          ),
                        ),
                      );

                      return ElectricChargeBorder(
                        active: canTap,
                        radius: 999,
                        child: chip,
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sessionIdentityPair(TradingSession session) {
    final firstSubtitle = [
      session.traderOneReady ? 'Ready' : 'Not ready',
      session.traderOneSharedEmbarkId ? 'Embark shared' : 'Embark hidden',
    ].join(' - ');
    final secondSubtitle = [
      session.traderTwoReady ? 'Ready' : 'Not ready',
      session.traderTwoSharedEmbarkId ? 'Embark shared' : 'Embark hidden',
    ].join(' - ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final first = TradingCosmeticIdentityStrip(
          repository: _repository,
          uid: session.traderOneUid,
          displayName: session.traderOneName,
          subtitle: firstSubtitle,
          compact: true,
        );
        final second = TradingCosmeticIdentityStrip(
          repository: _repository,
          uid: session.traderTwoUid,
          displayName: session.traderTwoName,
          subtitle: secondSubtitle,
          compact: true,
        );

        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppTheme.spaceS),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(TradingSession session) {
    final confirmedBooking = session.selectedBooking ?? session.scheduledAt;
    final isReady = _isTraderOne(session)
        ? session.traderOneReady
        : session.traderTwoReady;
    final myEmbarkShared = _isTraderOne(session)
        ? session.traderOneSharedEmbarkId
        : session.traderTwoSharedEmbarkId;
    final bothEmbarkIdsShared =
        session.traderOneSharedEmbarkId && session.traderTwoSharedEmbarkId;
    final myEmbarkId = _isTraderOne(session)
        ? session.traderOneEmbarkId
        : session.traderTwoEmbarkId;
    final otherEmbarkId = _isTraderOne(session)
        ? session.traderTwoEmbarkId
        : session.traderOneEmbarkId;
    final needsChoice = _needsBookingChoice(session);

    return TradingCard(
      margin: const EdgeInsets.only(bottom: 16),
      accent: _statusColor(session.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.traderOneName} vs ${session.traderTwoName}',
            style: AppTheme.tradingHeading(fontSize: 22),
          ),
          const SizedBox(height: 10),
          _sessionIdentityPair(session),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(session.statusLabel, _statusColor(session.status)),
              _pill(session.protocolLabel, AppTheme.neonCyan),
              _pill(session.timezone, AppTheme.neonPink),
              if (needsChoice) _pill('Action needed', AppTheme.warningAmber),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Confirmed slot', _formatDateTime(confirmedBooking)),
          _infoRow(
            'My Embark ID',
            myEmbarkId.trim().isEmpty ? 'Not shared yet' : myEmbarkId.trim(),
          ),

          _infoRow(
            '${_otherTraderName(session)} Embark ID',
            otherEmbarkId.trim().isEmpty
                ? 'Waiting for trader to share'
                : otherEmbarkId.trim(),
          ),

          _infoRow(
            'Friend request',
            confirmedBooking == null
                ? 'Confirm a time first'
                : bothEmbarkIdsShared
                ? 'Send/add the in-game friend request before the trade'
                : 'Share both Embark IDs first',
          ),
          _infoRow(
            'First drop',
            session.dropOrderAssigned
                ? (session.firstDropUid == session.traderOneUid
                      ? session.traderOneName
                      : session.traderTwoName)
                : 'Not assigned yet',
          ),
          const SizedBox(height: 12),
          _bookingPanel(session),
          const SizedBox(height: 12),
          if (_isStartingSoon(session)) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.tradingCardDecoration(
                backgroundColor: AppTheme.cardBackgroundAlt,
                borderColor: AppTheme.warningAmber.withValues(alpha: 0.35),
                radius: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trade starting within 30 minutes',
                    style: AppTheme.tradingHeading(
                      fontSize: 18,
                      color: AppTheme.warningAmber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure your Embark ID is shared, the time still works, and both traders are ready.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: AppTheme.tradingMutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _actionButton(
                        label: 'Open session',
                        icon: Icons.open_in_new_rounded,
                        highlighted: true,
                        onPressed: () => _openSessionReadinessPanel(session),
                      ),
                      _actionButton(
                        label: 'Request rearrangement',
                        icon: Icons.update_rounded,
                        onPressed: () => _openBookingComposer(session),
                      ),
                      _actionButton(
                        label: 'Message trader',
                        icon: Icons.message_outlined,
                        onPressed: () => _shareInvite(session),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Divider(color: AppTheme.tradingDivider),
          const SizedBox(height: 12),
          Text(
            'Trade checklist',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 10),
          _checkItem('Booking slot confirmed', confirmedBooking != null),
          _checkItem('My Embark ID shared', myEmbarkShared),
          _checkItem('Both Embark IDs shared', bothEmbarkIdsShared),
          _checkItem('Drop order assigned', session.dropOrderAssigned),
          _checkItem('Both traders ready', session.bothReady),
          _checkItem(
            'Safe Pocket protocol selected',
            session.protocolType ==
                TradingProtocolType.sequentialSafePocketSwap,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionButton(
                label: session.hasBookingOptions
                    ? 'Update proposals'
                    : 'Propose times',
                icon: Icons.calendar_month_rounded,
                highlighted: !session.hasConfirmedBooking && !needsChoice,
                onPressed: () => _openBookingComposer(session),
              ),
              _actionButton(
                label: 'Share invite',
                icon: Icons.ios_share_rounded,
                onPressed: () => _shareInvite(session),
              ),
              if (confirmedBooking != null)
                _actionButton(
                  label: 'Calendar',
                  icon: Icons.event_rounded,
                  onPressed: () => _addToCalendar(session),
                ),
              _actionButton(
                label: myEmbarkShared ? 'Update Embark ID' : 'Share Embark ID',
                icon: Icons.badge_outlined,
                highlighted: confirmedBooking != null && !myEmbarkShared,
                onPressed: () => _shareEmbarkId(session),
              ),
              _actionButton(
                label: 'Assign first drop',
                icon: Icons.swap_horiz_rounded,
                highlighted:
                    confirmedBooking != null && !session.dropOrderAssigned,
                onPressed: () => _pickDropOrder(session),
              ),
              _actionButton(
                label: isReady ? 'Unready' : 'I am ready',
                icon: isReady
                    ? Icons.remove_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                highlighted: confirmedBooking != null && !isReady,
                onPressed: () => _runAction(
                  () => _repository.setMyReadyState(session, !isReady),
                  successMessage: isReady
                      ? 'Ready status removed.'
                      : 'Ready status updated.',
                  errorPrefix: 'Could not update readiness: ',
                ),
              ),
              _actionButton(
                label: 'Mark complete',
                icon: Icons.task_alt_rounded,
                onPressed: () => _runAction(
                  () => _repository.markMySessionOutcome(
                    session: session,
                    outcome: TradingSessionStatus.completed,
                  ),
                  successMessage: 'Completion marked.',
                  errorPrefix: 'Could not mark complete: ',
                ),
              ),
              _actionButton(
                label: 'Mark no-show',
                icon: Icons.person_off_outlined,
                onPressed: () async {
                  final ok = await _confirmAction(
                    title: 'Record a no-show?',
                    message:
                        'Only record this if the agreed session time passed and your trading partner did not turn up.',
                    confirmText: 'Record no-show',
                    confirmColor: AppTheme.tradingDanger,
                  );
                  if (!ok) return;
                  await _runAction(
                    () => _repository.markMySessionOutcome(
                      session: session,
                      outcome: TradingSessionStatus.noShow,
                    ),
                    successMessage: 'No-show recorded.',
                    errorPrefix: 'Could not record no-show: ',
                  );
                },
              ),
              _actionButton(
                label: 'Flag betrayal',
                icon: Icons.gpp_bad_outlined,
                onPressed: () async {
                  final ok = await _confirmAction(
                    title: 'Flag betrayal?',
                    message:
                        'Use this only if the trade went bad or the agreed protocol was broken.',
                    confirmText: 'Flag betrayal',
                    confirmColor: AppTheme.tradingDanger,
                  );
                  if (!ok) return;
                  await _runAction(
                    () => _repository.markMySessionOutcome(
                      session: session,
                      outcome: TradingSessionStatus.betrayal,
                    ),
                    successMessage: 'Betrayal flagged.',
                    errorPrefix: 'Could not flag betrayal: ',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.tradingDivider),
          const SizedBox(height: 10),
          Text(
            'Flow: accept offer -> propose 3 days x 3 -> other trader confirms one slot -> share Embark IDs -> assign first drop -> both mark ready.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Text(
          'No trade sessions yet. Once an offer is accepted, the live session will appear here for both traders.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyTextStyle(
            fontSize: 16,
            color: AppTheme.tradingMutedText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                'Trade Sessions',
                style: AppTheme.tradingHeading(fontSize: 25),
              ),
            )
          : null,
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.pageMaxWidth,
              ),
              child: StreamBuilder<List<TradingSession>>(
                stream: _repository.watchMySessions(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                        child: Text(
                          'Could not load trade sessions.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 15,
                            color: AppTheme.tradingDanger,
                          ),
                        ),
                      ),
                    );
                  }

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
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) =>
                        _buildSessionCard(sessions[index]),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
