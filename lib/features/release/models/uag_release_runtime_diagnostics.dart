import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum UagReleaseDiagnosticLevel { ready, warning, blocked, info }

class UagReleaseDiagnosticEntry {
  const UagReleaseDiagnosticEntry({
    required this.label,
    required this.value,
    required this.level,
    this.detail = '',
  });

  final String label;
  final String value;
  final UagReleaseDiagnosticLevel level;
  final String detail;
}

class UagReleaseRuntimeDiagnosticsSnapshot {
  const UagReleaseRuntimeDiagnosticsSnapshot({
    required this.generatedAt,
    required this.entries,
    this.lastFirestoreError = '',
  });

  static const blueprintPathTemplate = 'users/{uid}/arc_blueprints';
  static const notificationInboxQuery =
      'trading_notifications where targetUid == {uid} orderBy createdAt desc';
  static const featureAccessPath = 'config/feature_access';
  static const releaseReadinessPath = 'config/release_readiness';
  static const mapIntelPath = 'arc_admin_map_markers';
  static const directInboxSource = 'admin_direct_inbox_test';

  static const appVersion = String.fromEnvironment(
    'UAG_APP_VERSION',
    defaultValue: 'not supplied',
  );
  static const buildNumber = String.fromEnvironment(
    'UAG_BUILD_NUMBER',
    defaultValue: 'not supplied',
  );
  static const gitCommit = String.fromEnvironment(
    'UAG_GIT_COMMIT',
    defaultValue: 'not supplied',
  );
  static const buildTimestamp = String.fromEnvironment(
    'UAG_BUILD_TIMESTAMP',
    defaultValue: 'not supplied',
  );
  static const hostingEnvironment = String.fromEnvironment(
    'UAG_HOSTING_ENVIRONMENT',
    defaultValue: 'not supplied',
  );
  static const serviceWorkerVersion = String.fromEnvironment(
    'UAG_SERVICE_WORKER_VERSION',
    defaultValue: 'not supplied',
  );
  static const webPushVapidKey = String.fromEnvironment(
    'UAG_WEB_PUSH_VAPID_KEY',
    defaultValue: '',
  );

  final DateTime generatedAt;
  final List<UagReleaseDiagnosticEntry> entries;
  final String lastFirestoreError;

  bool get hasBlocked =>
      entries.any((entry) => entry.level == UagReleaseDiagnosticLevel.blocked);

  static Future<UagReleaseRuntimeDiagnosticsSnapshot> load() async {
    final generatedAt = DateTime.now();
    final entries = <UagReleaseDiagnosticEntry>[
      UagReleaseDiagnosticEntry(
        label: 'App version',
        value: '$appVersion+$buildNumber',
        level: appVersion == 'not supplied'
            ? UagReleaseDiagnosticLevel.warning
            : UagReleaseDiagnosticLevel.ready,
        detail: 'Provided by --dart-define at build time.',
      ),
      UagReleaseDiagnosticEntry(
        label: 'Build commit',
        value: gitCommit,
        level: gitCommit == 'not supplied'
            ? UagReleaseDiagnosticLevel.warning
            : UagReleaseDiagnosticLevel.ready,
        detail: 'Expected to match the release-candidate Git commit.',
      ),
      UagReleaseDiagnosticEntry(
        label: 'Build timestamp',
        value: buildTimestamp,
        level: buildTimestamp == 'not supplied'
            ? UagReleaseDiagnosticLevel.warning
            : UagReleaseDiagnosticLevel.ready,
      ),
      UagReleaseDiagnosticEntry(
        label: 'Hosting environment',
        value: hostingEnvironment,
        level: hostingEnvironment == 'not supplied'
            ? UagReleaseDiagnosticLevel.info
            : UagReleaseDiagnosticLevel.ready,
      ),
      UagReleaseDiagnosticEntry(
        label: 'Service worker',
        value: serviceWorkerVersion,
        level: kIsWeb && serviceWorkerVersion == 'not supplied'
            ? UagReleaseDiagnosticLevel.warning
            : UagReleaseDiagnosticLevel.ready,
      ),
      UagReleaseDiagnosticEntry(
        label: 'Web VAPID key',
        value: kIsWeb
            ? (webPushVapidKey.trim().isEmpty ? 'missing' : 'configured')
            : 'not web',
        level: kIsWeb && webPushVapidKey.trim().isEmpty
            ? UagReleaseDiagnosticLevel.blocked
            : UagReleaseDiagnosticLevel.ready,
      ),
      const UagReleaseDiagnosticEntry(
        label: 'Blueprint store',
        value: blueprintPathTemplate,
        level: UagReleaseDiagnosticLevel.ready,
        detail: 'Canonical per-user persistence path.',
      ),
      const UagReleaseDiagnosticEntry(
        label: 'Communications inbox',
        value: notificationInboxQuery,
        level: UagReleaseDiagnosticLevel.ready,
      ),
      const UagReleaseDiagnosticEntry(
        label: 'Map Intel publish path',
        value: mapIntelPath,
        level: UagReleaseDiagnosticLevel.ready,
      ),
    ];

    String lastFirestoreError = '';
    if (Firebase.apps.isEmpty) {
      entries.add(
        const UagReleaseDiagnosticEntry(
          label: 'Firebase app',
          value: 'not initialized',
          level: UagReleaseDiagnosticLevel.blocked,
        ),
      );
      return UagReleaseRuntimeDiagnosticsSnapshot(
        generatedAt: generatedAt,
        entries: entries,
      );
    }

    try {
      final app = Firebase.app();
      entries.add(
        UagReleaseDiagnosticEntry(
          label: 'Firebase project',
          value: app.options.projectId,
          level: app.options.projectId.trim().isEmpty
              ? UagReleaseDiagnosticLevel.blocked
              : UagReleaseDiagnosticLevel.ready,
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        entries.add(
          const UagReleaseDiagnosticEntry(
            label: 'Signed-in UID',
            value: 'not signed in',
            level: UagReleaseDiagnosticLevel.warning,
          ),
        );
      } else {
        entries.add(
          UagReleaseDiagnosticEntry(
            label: 'Signed-in UID',
            value: user.uid,
            level: UagReleaseDiagnosticLevel.ready,
          ),
        );

        final token = await user.getIdTokenResult(true);
        final claims = token.claims ?? const <String, dynamic>{};
        final claimRoles = <String>[
          if (claims['admin'] == true || claims['isAdmin'] == true) 'admin',
          if (claims['dev'] == true || claims['isDev'] == true) 'dev',
        ];
        entries.add(
          UagReleaseDiagnosticEntry(
            label: 'Token claims',
            value: claimRoles.isEmpty
                ? 'no admin/dev claims'
                : claimRoles.join(', '),
            level: claimRoles.isEmpty
                ? UagReleaseDiagnosticLevel.warning
                : UagReleaseDiagnosticLevel.ready,
            detail: 'Client admin screens still also read user-doc flags.',
          ),
        );

        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? const <String, dynamic>{};
        final userDocRoles = <String>[
          if (userData['isAdmin'] == true) 'isAdmin',
          if (userData['isDev'] == true) 'isDev',
          if (userData['closedBetaAccess'] == true) 'closedBetaAccess',
          if (userData['openBetaAccess'] == true) 'openBetaAccess',
        ];
        entries.add(
          UagReleaseDiagnosticEntry(
            label: 'User document flags',
            value: userDocRoles.isEmpty
                ? 'none visible'
                : userDocRoles.join(', '),
            level: userDoc.exists
                ? UagReleaseDiagnosticLevel.ready
                : UagReleaseDiagnosticLevel.blocked,
          ),
        );

        final featureAccess = await firestore.doc(featureAccessPath).get();
        entries.add(
          UagReleaseDiagnosticEntry(
            label: 'Feature flags',
            value: featureAccess.exists ? featureAccessPath : 'missing',
            level: featureAccess.exists
                ? UagReleaseDiagnosticLevel.ready
                : UagReleaseDiagnosticLevel.warning,
          ),
        );
      }
    } catch (error) {
      lastFirestoreError = error.toString();
      entries.add(
        UagReleaseDiagnosticEntry(
          label: 'Firestore diagnostic read',
          value: 'failed',
          level: UagReleaseDiagnosticLevel.blocked,
          detail: lastFirestoreError,
        ),
      );
    }

    entries.add(
      UagReleaseDiagnosticEntry(
        label: 'Last diagnostic sync',
        value: generatedAt.toIso8601String(),
        level: lastFirestoreError.isEmpty
            ? UagReleaseDiagnosticLevel.ready
            : UagReleaseDiagnosticLevel.blocked,
      ),
    );

    return UagReleaseRuntimeDiagnosticsSnapshot(
      generatedAt: generatedAt,
      entries: entries,
      lastFirestoreError: lastFirestoreError,
    );
  }
}
