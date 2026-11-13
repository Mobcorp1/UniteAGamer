import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class AdminBusinessMetricsPanel extends StatelessWidget {
  const AdminBusinessMetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('monetisation_events')
              .orderBy('createdAt', descending: true)
              .limit(500)
              .snapshots(),
          builder: (context, revenueSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection('arc_operation_telemetry')
                  .snapshots(),
              builder: (context, telemetrySnapshot) {
                if (userSnapshot.hasError ||
                    revenueSnapshot.hasError ||
                    telemetrySnapshot.hasError) {
                  return _messageCard(
                    'Could not load business metrics.',
                    ArcUiTokens.danger,
                  );
                }

                if (!userSnapshot.hasData &&
                    !revenueSnapshot.hasData &&
                    !telemetrySnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ArcUiTokens.primaryAccent,
                    ),
                  );
                }

                final users = _docsWithIds(userSnapshot.data?.docs);
                final revenueEvents = _docsWithIds(revenueSnapshot.data?.docs);
                final telemetrySummaries = _docsWithIds(
                  telemetrySnapshot.data?.docs,
                );
                final metrics = AdminBusinessMetricsCalculator.fromRaw(
                  users: users,
                  revenueEvents: revenueEvents,
                  telemetrySummaries: telemetrySummaries,
                  now: DateTime.now(),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 980
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Monthly Active Users',
                          value: '${metrics.monthlyActiveUsers}',
                          caption: 'Active in the last 30 days',
                          icon: Icons.groups_rounded,
                          color: ArcUiTokens.primaryAccent,
                        ),
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Ad Revenue',
                          value: _money(metrics.adRevenuePence),
                          caption: 'Logged ad events',
                          icon: Icons.ads_click_rounded,
                          color: ArcUiTokens.success,
                        ),
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Revenue Per Active User',
                          value: _money(metrics.revenuePerActiveUserPence),
                          caption: 'Gross revenue / active users',
                          icon: Icons.account_balance_wallet_outlined,
                          color: ArcUiTokens.warning,
                        ),
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Lifetime Value',
                          value: _money(metrics.lifetimeValuePence),
                          caption: 'Gross revenue / total users',
                          icon: Icons.timeline_rounded,
                          color: ArcUiTokens.secondaryAccent,
                        ),
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Average Session Time',
                          value: _duration(metrics.averageSessionTime),
                          caption: 'Fills as sessions are tracked',
                          icon: Icons.timer_outlined,
                          color: ArcUiTokens.primaryAccent,
                        ),
                        _BusinessMetricCard(
                          width: cardWidth,
                          label: 'Sessions Per User',
                          value: metrics.sessionsPerActiveUser.toStringAsFixed(
                            1,
                          ),
                          caption: '${metrics.totalSessions} tracked sessions',
                          icon: Icons.repeat_rounded,
                          color: ArcUiTokens.textSecondary,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  static List<Map<String, dynamic>> _docsWithIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
  ) {
    return [
      for (final doc
          in docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
        <String, dynamic>{'uid': doc.id, ...doc.data()},
    ];
  }

  static Widget _messageCard(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.warning,
        accent: color,
        borderOpacity: 0.35,
      ),
      child: Text(
        text,
        style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
      ),
    );
  }

  static String _money(int pence) {
    return 'GBP ${(pence / 100).toStringAsFixed(2)}';
  }

  static String _duration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= 0) return 'Tracking now';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }
}

class AdminBusinessMetrics {
  const AdminBusinessMetrics({
    required this.totalUsers,
    required this.monthlyActiveUsers,
    required this.adRevenuePence,
    required this.grossRevenuePence,
    required this.revenuePerActiveUserPence,
    required this.lifetimeValuePence,
    required this.averageSessionTime,
    required this.totalSessions,
    required this.sessionsPerActiveUser,
  });

  final int totalUsers;
  final int monthlyActiveUsers;
  final int adRevenuePence;
  final int grossRevenuePence;
  final int revenuePerActiveUserPence;
  final int lifetimeValuePence;
  final Duration averageSessionTime;
  final int totalSessions;
  final double sessionsPerActiveUser;
}

class AdminBusinessMetricsCalculator {
  const AdminBusinessMetricsCalculator._();

  static AdminBusinessMetrics fromRaw({
    required Iterable<Map<String, dynamic>> users,
    required Iterable<Map<String, dynamic>> revenueEvents,
    required Iterable<Map<String, dynamic>> telemetrySummaries,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final activeSince = today.subtract(const Duration(days: 30));
    final userList = users.toList(growable: false);
    final activeUserIds = <String>{};

    for (final user in userList) {
      final uid = _string(user['uid'] ?? user['id'] ?? user['userId']);
      final lastActive = _latestDate(user, const [
        'lastActiveAt',
        'lastLoginAt',
        'updatedAt',
        'profileCompletion.updatedAt',
        'arcOnboarding.completedAt',
      ]);
      if (lastActive != null && !lastActive.isBefore(activeSince)) {
        activeUserIds.add(uid ?? 'user-${activeUserIds.length}');
      }
    }

    var totalSessions = 0;
    var totalSessionSeconds = 0;
    var sessionDurationSamples = 0;
    for (final telemetry in telemetrySummaries) {
      final uid = _string(
        telemetry['uid'] ?? telemetry['id'] ?? telemetry['userId'],
      );
      final lastSession = _latestDate(telemetry, const [
        'lastSessionStartedAt',
        'lastSessionEndedAt',
        'lastEventAt',
        'updatedAt',
      ]);
      if (lastSession != null && !lastSession.isBefore(activeSince)) {
        activeUserIds.add(uid ?? 'telemetry-${activeUserIds.length}');
      }
      final sessions = _firstInt(telemetry, const [
        'sessionsStarted',
        'sessionStarts',
      ]);
      totalSessions += sessions;
      totalSessionSeconds += _firstInt(telemetry, const [
        'totalSessionSeconds',
        'sessionSeconds',
      ]);
      sessionDurationSamples += _firstInt(telemetry, const [
        'sessionDurationSamples',
        'sessionSamples',
      ]);
    }
    if (totalSessions == 0) {
      for (final telemetry in telemetrySummaries) {
        totalSessions += _firstInt(telemetry, const ['loginEvents']);
      }
    }
    if (sessionDurationSamples == 0 && totalSessionSeconds > 0) {
      sessionDurationSamples = totalSessions > 0 ? totalSessions : 1;
    }

    var grossRevenuePence = 0;
    var adRevenuePence = 0;
    for (final event in revenueEvents) {
      final gross = _firstInt(event, const [
        'grossPence',
        'amountPence',
        'revenuePence',
        'totalPence',
      ]);
      grossRevenuePence += gross;

      final directAdRevenue = _firstInt(event, const [
        'adRevenuePence',
        'adPence',
        'estimatedAdRevenuePence',
      ]);
      adRevenuePence += directAdRevenue;
      if (directAdRevenue == 0 && _isAdEvent(event)) {
        adRevenuePence += gross;
      }
    }

    final monthlyActiveUsers = activeUserIds.length;
    final revenuePerActiveUserPence = monthlyActiveUsers == 0
        ? 0
        : (grossRevenuePence / monthlyActiveUsers).round();
    final lifetimeValuePence = userList.isEmpty
        ? 0
        : (grossRevenuePence / userList.length).round();
    final averageSessionTime = sessionDurationSamples == 0
        ? Duration.zero
        : Duration(
            seconds: (totalSessionSeconds / sessionDurationSamples).round(),
          );
    final sessionsPerActiveUser = monthlyActiveUsers == 0
        ? 0.0
        : totalSessions / monthlyActiveUsers;

    return AdminBusinessMetrics(
      totalUsers: userList.length,
      monthlyActiveUsers: monthlyActiveUsers,
      adRevenuePence: adRevenuePence,
      grossRevenuePence: grossRevenuePence,
      revenuePerActiveUserPence: revenuePerActiveUserPence,
      lifetimeValuePence: lifetimeValuePence,
      averageSessionTime: averageSessionTime,
      totalSessions: totalSessions,
      sessionsPerActiveUser: sessionsPerActiveUser,
    );
  }

  static bool _isAdEvent(Map<String, dynamic> data) {
    final text = [
      data['eventName'],
      data['type'],
      data['category'],
      data['source'],
      data['provider'],
    ].whereType<Object>().join(' ').toLowerCase();
    return text.contains('ad');
  }

  static int _firstInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _valueAt(data, key);
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static DateTime? _latestDate(Map<String, dynamic> data, List<String> keys) {
    DateTime? latest;
    for (final key in keys) {
      final date = _date(_valueAt(data, key));
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static dynamic _valueAt(Map<String, dynamic> data, String path) {
    dynamic current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class _BusinessMetricCard extends StatelessWidget {
  const _BusinessMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.interactive,
          accent: color,
          borderOpacity: 0.24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.numeric(
                fontSize: 25,
                color: ArcUiTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: ArcUiTokens.label(color: color)),
            const SizedBox(height: 3),
            Text(
              caption,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
