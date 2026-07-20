import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_repository.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagNotificationPreferencesPanel extends StatefulWidget {
  const UagNotificationPreferencesPanel({super.key});

  @override
  State<UagNotificationPreferencesPanel> createState() =>
      _UagNotificationPreferencesPanelState();
}

class _UagNotificationPreferencesPanelState
    extends State<UagNotificationPreferencesPanel> {
  final UagNotificationRepository _repository = UagNotificationRepository();

  UagNotificationRuntimeStatus? _runtimeStatus;
  bool _busy = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await TradingPushService.instance.runtimeStatus();
    if (!mounted) return;
    setState(() => _runtimeStatus = status);
  }

  Future<void> _enableNotifications() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await TradingPushService.instance.enableNotificationsFromUserAction();
      await _refreshStatus();
      if (!mounted) return;
      setState(() => _message = 'Notification device registration updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not enable notifications: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendLocalTest() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final shown = await TradingPushService.instance
          .showLocalTestNotification();
      if (!mounted) return;
      setState(() {
        _message = shown
            ? 'Local Android test notification displayed.'
            : 'Use Admin Console test-send for Chrome/web delivery.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not send test notification: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(
    UagNotificationPreferences preferences,
    UagNotificationCategory category,
    bool value,
  ) async {
    await _repository.savePreferences(
      preferences.withCategory(category, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagNotificationPreferences>(
      stream: _repository.watchPreferences(),
      builder: (context, snapshot) {
        final preferences =
            snapshot.data ?? UagNotificationPreferences.defaults;
        final status = _runtimeStatus;
        final permission = status?.permissionStatus ?? 'checking';

        return Container(
          width: double.infinity,
          padding: AppTheme.sectionCardPadding,
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.neonCyan,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Notification Control',
                      style: AppTheme.tradingHeading(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Control this device and the alert categories UAG can send you.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  _statusPill('Platform', status?.platform ?? 'unknown'),
                  _statusPill('Permission', permission),
                  _statusPill(
                    'Device',
                    status?.lastTokenRegistered == true
                        ? 'Registered'
                        : 'Not Registered',
                  ),
                  if (status?.hasWebVapidKey == false)
                    _statusPill('Web Push Key', 'Missing'),
                ],
              ),
              if (status?.hasWebVapidKey == false) ...[
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  'Chrome push needs --dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_KEY before this browser can register.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.warningAmber,
                    isBold: true,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _enableNotifications,
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('Enable Notifications'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _sendLocalTest,
                    icon: const Icon(Icons.notification_add_outlined),
                    label: const Text('Test Notification'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _refreshStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh Status'),
                  ),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  _message,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.tradingMutedText,
                    isBold: true,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceL),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 720;
                  return Wrap(
                    spacing: AppTheme.spaceM,
                    runSpacing: AppTheme.spaceS,
                    children: [
                      for (final category in UagNotificationCategory.values)
                        SizedBox(
                          width: twoColumns
                              ? (constraints.maxWidth - AppTheme.spaceM) / 2
                              : constraints.maxWidth,
                          child: _categoryToggle(
                            preferences,
                            category,
                            preferences.valueFor(category),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPill(String label, String value) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: AppTheme.neonCyan),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }

  Widget _categoryToggle(
    UagNotificationPreferences preferences,
    UagNotificationCategory category,
    bool value,
  ) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: value
            ? AppTheme.neonCyan.withValues(alpha: 0.24)
            : Colors.white.withValues(alpha: 0.08),
        backgroundColor: Colors.black.withValues(alpha: 0.28),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        activeThumbColor: AppTheme.neonCyan,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          category.label,
          style: AppTheme.bodyTextStyle(
            fontSize: 13,
            color: Colors.white,
            isBold: true,
          ),
        ),
        onChanged: (next) => _toggle(preferences, category, next),
      ),
    );
  }
}
