# PASS 272 Calendar, Reminders And Feedback

PASS 272 adds a persisted scheduling path for ARC Raiders trade, matchmaking and planned raid sessions.

## Scheduling Flow

- Confirmed `trading_sessions` and `uag_sessions` are watched by Firebase Functions.
- Each active scheduled session writes deterministic documents to `uag_notification_schedules`.
- Each participant receives one pre-session reminder schedule and one post-session feedback schedule.
- Pre-session reminders are due 15 minutes before the confirmed start.
- Post-session feedback prompts are due 15 minutes after the default one-hour session window.
- Rescheduling rewrites the same deterministic schedule IDs, which prevents duplicates.
- Completed, no-show, betrayal or cancelled sessions mark outstanding schedules as `cancelled`.

## Delivery Flow

- `processUagNotificationSchedules` runs every 5 minutes with Cloud Scheduler.
- Due queued schedules are claimed transactionally as `processing`.
- User notification preferences are checked before a trading notification is created.
- Allowed schedules create a `trading_notifications` document.
- The existing PASS 264 `sendTradingNotificationPush` trigger sends push to registered devices.
- Notification route/deep-link data points back to the relevant session or feedback surface.

## Calendar Export

- Calendar writes remain explicit user actions.
- Manual sessions and confirmed trade sessions build a shared calendar payload with title, start, end, participants, location/platform, notes and UAG deep link.
- Android continues to use the existing `add_2_calendar` plugin.
- Share payloads include Google Calendar and iCalendar text for web/manual fallback.

## Firebase Configuration

The scheduled processor requires Firebase Functions plus Cloud Scheduler support for the deployed project. This can require the project billing plan/configuration that permits scheduled Cloud Functions. Do not claim live reminder delivery until functions are deployed successfully and the scheduler job is visible in the Firebase/Google Cloud console.

## Manual QA

- Confirm a trade slot and verify two queued reminder schedules plus two queued feedback schedules.
- Reschedule the same trade and verify the same schedule IDs update rather than duplicate.
- Mark a session completed/no-show/cancelled and verify outstanding schedules become `cancelled`.
- Disable reminders or post-session feedback in Notification Settings and verify due schedules are skipped by preference.
- Open a reminder/feedback notification and verify it routes to the session/feedback surface.
