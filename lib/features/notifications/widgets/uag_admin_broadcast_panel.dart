import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_delivery_engine.dart';
import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_repository.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagAdminBroadcastPanel extends StatefulWidget {
  const UagAdminBroadcastPanel({super.key});

  @override
  State<UagAdminBroadcastPanel> createState() => _UagAdminBroadcastPanelState();
}

class _UagAdminBroadcastPanelState extends State<UagAdminBroadcastPanel> {
  final UagNotificationRepository _repository = UagNotificationRepository();
  final UagNotificationDeliveryEngine _engine =
      const UagNotificationDeliveryEngine();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _deepLinkController = TextEditingController(
    text: ArcCommandCentreScreen.routeName,
  );
  final TextEditingController _targetUidController = TextEditingController();

  UagNotificationType _type = UagNotificationType.openBeta;
  UagNotificationAudience _audience = UagNotificationAudience.allEligible;
  UagNotificationPriority _priority = UagNotificationPriority.high;
  bool _sendPush = true;
  bool _createInApp = true;
  int _expiryHours = 72;
  bool _busy = false;
  String _message = '';
  String _lastInboxPath = '';
  String _lastInboxTargetUid = '';
  bool? _lastInboxReadable;
  UagNotificationAudienceEstimate? _estimate;

  @override
  void initState() {
    super.initState();
    _applyOpenBetaPreset();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    _deepLinkController.dispose();
    _targetUidController.dispose();
    super.dispose();
  }

  void _applyOpenBetaPreset() {
    _type = UagNotificationType.openBeta;
    _audience = UagNotificationAudience.allEligible;
    _priority = UagNotificationPriority.high;
    _titleController.text = 'UAG ARC Raiders Hub Open Beta Is Live';
    _bodyController.text =
        'The open beta is now live. Update or open the UAG ARC Raiders Hub and join the community.';
    _deepLinkController.text = ArcCommandCentreScreen.routeName;
  }

  UagNotificationPayload _payload(String senderUid) {
    final route = _deepLinkController.text.trim().isEmpty
        ? ArcCommandCentreScreen.routeName
        : _deepLinkController.text.trim();
    return UagNotificationPayload(
      id: 'preview',
      type: _type,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      imageUrl: _imageController.text.trim(),
      deepLink: route,
      route: route.startsWith('/') ? route : ArcCommandCentreScreen.routeName,
      audience: _audience,
      senderUid: senderUid,
      expiresAt: _expiryHours <= 0
          ? null
          : DateTime.now().add(Duration(hours: _expiryHours)),
      priority: _priority,
      deliveryChannels: [
        if (_sendPush) UagNotificationDeliveryChannel.push,
        if (_createInApp) UagNotificationDeliveryChannel.inApp,
      ],
    );
  }

  Future<void> _estimateAudience() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final estimate = await _repository.estimateAudience(
        payload: _payload(uid),
        specificTargetUid: _targetUidController.text,
      );
      if (!mounted) return;
      setState(() => _estimate = estimate);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not estimate audience: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testSend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _createInboxTest(
      targetUidOverride: uid,
      successPrefix: 'Admin test notification created for your inbox',
    );
  }

  Future<void> _createInboxTest({
    String? targetUidOverride,
    String successPrefix = 'Inbox test created',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final resolvedOverride = targetUidOverride?.trim() ?? '';
    final targetUid = resolvedOverride.isNotEmpty
        ? resolvedOverride
        : _targetUidController.text.trim().isEmpty
        ? uid
        : _targetUidController.text.trim();
    final payload = _payload(
      uid,
    ).copyForTarget(audience: UagNotificationAudience.specificUser);
    final validation = _engine.validateBroadcast(
      payload: payload,
      senderIsAdmin: true,
      sendPush: false,
      createInApp: true,
    );
    if (!validation.isValid) {
      setState(() => _message = validation.errors.join(' '));
      return;
    }

    setState(() {
      _busy = true;
      _message = '';
      _lastInboxPath = '';
      _lastInboxTargetUid = targetUid;
      _lastInboxReadable = null;
    });
    try {
      final notificationId = await _repository
          .createDirectInAppTestNotification(
            payload: payload,
            targetUid: targetUid,
          );
      final readable = await _repository.canReadDirectInAppNotification(
        notificationId,
      );
      final path = UagNotificationRepository.directInAppNotificationPath(
        notificationId,
      );
      if (!mounted) return;
      setState(() {
        _lastInboxPath = path;
        _lastInboxReadable = readable;
        _message = readable
            ? '$successPrefix and readable in Communications: $path'
            : '$successPrefix but could not be read back: $path';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not create inbox test: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openCommunications() {
    Navigator.of(context).pushNamed(TradingNotificationsScreen.routeName);
  }

  Future<void> _sendBroadcast() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.30),
          ),
        ),
        title: Text(
          'Send broadcast?',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        content: Text(
          'This queues the broadcast for secure Cloud Function delivery. It does not send from the app client.',
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Queue Broadcast'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _createBroadcast(
      testMode: false,
      targetUid: _audience == UagNotificationAudience.specificUser
          ? _targetUidController.text
          : '',
    );
  }

  Future<void> _createBroadcast({
    required bool testMode,
    required String targetUid,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final payload = testMode
        ? _payload(
            uid,
          ).copyForTarget(audience: UagNotificationAudience.specificUser)
        : _payload(uid);
    final validation = _engine.validateBroadcast(
      payload: payload,
      senderIsAdmin: true,
      sendPush: _sendPush,
      createInApp: _createInApp,
    );
    if (!validation.isValid) {
      setState(() => _message = validation.errors.join(' '));
      return;
    }

    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final broadcastId = await _repository.createBroadcastRequest(
        payload: payload,
        sendPush: _sendPush,
        createInApp: _createInApp,
        testMode: testMode,
        specificTargetUid: targetUid,
      );
      if (!mounted) return;
      setState(() {
        _message = testMode
            ? 'Admin test notification queued: $broadcastId'
            : 'Broadcast queued for Cloud Function delivery: $broadcastId';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not queue broadcast: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;

    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'Communications Centre Broadcast',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 16,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
              ),
              TextButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.secondaryAccent,
                ),
                onPressed: _busy
                    ? null
                    : () => setState(() => _applyOpenBetaPreset()),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Preset'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Send durable inbox messages and optional push alerts to all eligible users, platform audiences, or a selected user. Always test-send before the final broadcast.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceM),
          _textField(_titleController, 'Title'),
          const SizedBox(height: AppTheme.spaceS),
          _textField(_bodyController, 'Body', maxLines: 3),
          const SizedBox(height: AppTheme.spaceS),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              return Wrap(
                spacing: AppTheme.spaceS,
                runSpacing: AppTheme.spaceS,
                children: [
                  SizedBox(
                    width: wide
                        ? (constraints.maxWidth - AppTheme.spaceS) / 2
                        : constraints.maxWidth,
                    child: _enumDropdown<UagNotificationType>(
                      label: 'Type',
                      value: _type,
                      values: UagNotificationType.values,
                      labelFor: (value) => value.wireName,
                      onChanged: (value) => setState(() => _type = value),
                    ),
                  ),
                  SizedBox(
                    width: wide
                        ? (constraints.maxWidth - AppTheme.spaceS) / 2
                        : constraints.maxWidth,
                    child: _enumDropdown<UagNotificationAudience>(
                      label: 'Audience',
                      value: _audience,
                      values: UagNotificationAudience.values,
                      labelFor: (value) => value.wireName,
                      onChanged: (value) => setState(() => _audience = value),
                    ),
                  ),
                  SizedBox(
                    width: wide
                        ? (constraints.maxWidth - AppTheme.spaceS) / 2
                        : constraints.maxWidth,
                    child: _enumDropdown<UagNotificationPriority>(
                      label: 'Priority',
                      value: _priority,
                      values: UagNotificationPriority.values,
                      labelFor: (value) => value.wireName,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                  ),
                  SizedBox(
                    width: wide
                        ? (constraints.maxWidth - AppTheme.spaceS) / 2
                        : constraints.maxWidth,
                    child: DropdownButtonFormField<int>(
                      initialValue: _expiryHours,
                      decoration: AppTheme.inputDecoration('Expiry'),
                      dropdownColor: AppTheme.cardBackgroundDeep,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('No expiry')),
                        DropdownMenuItem(value: 24, child: Text('24 hours')),
                        DropdownMenuItem(value: 72, child: Text('72 hours')),
                        DropdownMenuItem(value: 168, child: Text('7 days')),
                      ],
                      onChanged: (value) =>
                          setState(() => _expiryHours = value ?? 72),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_audience == UagNotificationAudience.specificUser) ...[
            const SizedBox(height: AppTheme.spaceS),
            _textField(_targetUidController, 'Specific user UID'),
          ],
          const SizedBox(height: AppTheme.spaceS),
          _textField(_imageController, 'Optional image URL'),
          const SizedBox(height: AppTheme.spaceS),
          _textField(_deepLinkController, 'Route or deep link'),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: AppTheme.spaceM,
            runSpacing: AppTheme.spaceS,
            children: [
              FilterChip(
                selected: _sendPush,
                onSelected: (value) => setState(() => _sendPush = value),
                label: const Text('Send push'),
              ),
              FilterChip(
                selected: _createInApp,
                onSelected: (value) => setState(() => _createInApp = value),
                label: const Text('Create in-app record'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Container(
            width: double.infinity,
            padding: ArcUiTokens.panelPadding,
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.raised,
              accent: ArcUiTokens.primaryAccent,
              borderOpacity: 0.20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 15,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  _titleController.text.trim().isEmpty
                      ? 'No title yet.'
                      : _titleController.text.trim(),
                  style: ArcUiTokens.body(
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _bodyController.text.trim().isEmpty
                      ? 'No body yet.'
                      : _bodyController.text.trim(),
                  style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
                ),
                if (estimate != null) ...[
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    'Estimated eligible: ${estimate.eligibleUsers} users / ${estimate.eligibleDevices} devices${estimate.limited ? ' (sampled)' : ''}',
                    style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              TextButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                ),
                onPressed: _busy ? null : _estimateAudience,
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Estimate Audience'),
              ),
              TextButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                ),
                onPressed: _busy ? null : _testSend,
                icon: const Icon(Icons.send_to_mobile_outlined),
                label: const Text('Test Send To Me'),
              ),
              TextButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                ),
                onPressed: _busy ? null : _createInboxTest,
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: const Text('Inbox Test Target'),
              ),
              if (_lastInboxPath.isNotEmpty)
                TextButton.icon(
                  style: ArcUiTokens.textButtonStyle(
                    accent: ArcUiTokens.primaryAccent,
                  ),
                  onPressed: _busy ? null : _openCommunications,
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Open Communications'),
                ),
              if (_lastInboxPath.isNotEmpty)
                Chip(
                  avatar: Icon(
                    _lastInboxReadable == true
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 16,
                    color: _lastInboxReadable == true
                        ? ArcUiTokens.success
                        : ArcUiTokens.warning,
                  ),
                  label: Text(
                    'Target: ${_lastInboxTargetUid.isEmpty ? 'current user' : _lastInboxTargetUid}',
                  ),
                  backgroundColor: ArcUiTokens.surfaceRaised,
                  side: BorderSide(
                    color:
                        (_lastInboxReadable == true
                                ? ArcUiTokens.success
                                : ArcUiTokens.warning)
                            .withValues(alpha: 0.42),
                  ),
                ),
              TextButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.secondaryAccent,
                  primary: true,
                ),
                onPressed: _busy ? null : _sendBroadcast,
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Queue Broadcast'),
              ),
            ],
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              _message,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: AppTheme.inputDecoration(label),
    );
  }

  Widget _enumDropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: AppTheme.cardBackgroundDeep,
      decoration: AppTheme.inputDecoration(label),
      items: values
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

extension on UagNotificationPayload {
  UagNotificationPayload copyForTarget({
    required UagNotificationAudience audience,
  }) {
    return UagNotificationPayload(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      deepLink: deepLink,
      route: route,
      entityId: entityId,
      audience: audience,
      createdAt: createdAt,
      expiresAt: expiresAt,
      senderUid: senderUid,
      priority: priority,
      deliveryChannels: deliveryChannels,
      metadata: metadata,
    );
  }
}
