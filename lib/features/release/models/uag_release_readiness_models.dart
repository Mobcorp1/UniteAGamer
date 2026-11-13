enum UagReleaseReadinessState {
  ready,
  configurationRequired,
  manualQaRequired,
  deferred,
  blocked,
  unknown,
}

extension UagReleaseReadinessStateX on UagReleaseReadinessState {
  String get label {
    switch (this) {
      case UagReleaseReadinessState.ready:
        return 'Ready';
      case UagReleaseReadinessState.configurationRequired:
        return 'Config required';
      case UagReleaseReadinessState.manualQaRequired:
        return 'Manual QA';
      case UagReleaseReadinessState.deferred:
        return 'Deferred';
      case UagReleaseReadinessState.blocked:
        return 'Blocked';
      case UagReleaseReadinessState.unknown:
        return 'Unknown';
    }
  }

  static UagReleaseReadinessState fromWire(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'ready':
        return UagReleaseReadinessState.ready;
      case 'configuration_required':
      case 'configurationrequired':
      case 'config_required':
      case 'config required':
        return UagReleaseReadinessState.configurationRequired;
      case 'manual_qa_required':
      case 'manualqarequired':
      case 'manual qa':
        return UagReleaseReadinessState.manualQaRequired;
      case 'deferred':
      case 'defer':
      case 'later':
        return UagReleaseReadinessState.deferred;
      case 'blocked':
        return UagReleaseReadinessState.blocked;
      case 'unknown':
      default:
        return UagReleaseReadinessState.unknown;
    }
  }
}

class UagReleaseReadinessCheck {
  const UagReleaseReadinessCheck({
    required this.id,
    required this.label,
    required this.state,
    required this.owner,
    required this.detail,
    this.lastCheckedIso = '',
  });

  final String id;
  final String label;
  final UagReleaseReadinessState state;
  final String owner;
  final String detail;
  final String lastCheckedIso;

  bool get blocksRelease => state == UagReleaseReadinessState.blocked;
  bool get needsExternalAction =>
      state == UagReleaseReadinessState.configurationRequired ||
      state == UagReleaseReadinessState.manualQaRequired;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'state': state.name,
      'owner': owner,
      'detail': detail,
      'lastCheckedIso': lastCheckedIso,
    };
  }

  factory UagReleaseReadinessCheck.fromMap(Map<String, dynamic> map) {
    return UagReleaseReadinessCheck(
      id: _readString(map['id']),
      label: _readString(map['label']),
      state: UagReleaseReadinessStateX.fromWire(_readString(map['state'])),
      owner: _readString(map['owner'], fallback: 'Mike'),
      detail: _readString(map['detail']),
      lastCheckedIso: _readString(map['lastCheckedIso']),
    );
  }
}

class UagReleaseReadinessSnapshot {
  const UagReleaseReadinessSnapshot({
    required this.generatedAtIso,
    required this.checks,
  });

  final String generatedAtIso;
  final List<UagReleaseReadinessCheck> checks;

  int get readyCount => checks
      .where((check) => check.state == UagReleaseReadinessState.ready)
      .length;
  int get blockerCount => checks.where((check) => check.blocksRelease).length;
  int get configurationRequiredCount => checks
      .where(
        (check) =>
            check.state == UagReleaseReadinessState.configurationRequired,
      )
      .length;
  int get manualQaCount => checks
      .where(
        (check) => check.state == UagReleaseReadinessState.manualQaRequired,
      )
      .length;
  int get deferredCount => checks
      .where((check) => check.state == UagReleaseReadinessState.deferred)
      .length;

  bool get canCallClosedBetaReady => blockerCount == 0;

  factory UagReleaseReadinessSnapshot.fromMap(Map<String, dynamic> map) {
    final incomingChecks =
        (map['checks'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => UagReleaseReadinessCheck.fromMap(
                item.cast<String, dynamic>(),
              ),
            )
            .where((check) => check.id.isNotEmpty)
            .toList(growable: false) ??
        const <UagReleaseReadinessCheck>[];

    final merged = <String, UagReleaseReadinessCheck>{
      for (final check in defaultChecks) check.id: check,
      for (final check in incomingChecks) check.id: check,
    };

    return UagReleaseReadinessSnapshot(
      generatedAtIso: _readString(map['generatedAtIso']),
      checks: merged.values.toList(growable: false),
    );
  }

  static const defaultChecks = <UagReleaseReadinessCheck>[
    UagReleaseReadinessCheck(
      id: 'firebase_rules',
      label: 'Firestore rules',
      state: UagReleaseReadinessState.ready,
      owner: 'Codex',
      detail: 'Repository rules are present and validated by automated checks.',
    ),
    UagReleaseReadinessCheck(
      id: 'storage_rules',
      label: 'Storage rules',
      state: UagReleaseReadinessState.ready,
      owner: 'Codex',
      detail: 'Storage rules are versioned and deployable from firebase.json.',
    ),
    UagReleaseReadinessCheck(
      id: 'java_21',
      label: 'Java 21 Firebase emulator runtime',
      state: UagReleaseReadinessState.deferred,
      owner: 'Mike/dev machine',
      detail:
          'Local Firebase emulator tooling only. Android Studio may already bundle a suitable JBR; verify JAVA_HOME when emulator-suite testing is scheduled. This does not block device beta testing.',
    ),
    UagReleaseReadinessCheck(
      id: 'moderation_provider',
      label: 'External moderation provider',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Firebase/Google Cloud',
      detail:
          'Provider selected: Google Cloud Natural Language. Deterministic local checks remain active; enable the Cloud API and UAG_MODERATION_PROVIDER_ENABLED for beta/production before claiming external moderation coverage.',
    ),
    UagReleaseReadinessCheck(
      id: 'ocr_provider',
      label: 'OCR provider',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Firebase/Google Cloud',
      detail:
          'Provider selected: Google Cloud Vision. Enable the API and server-side OCR configuration before claiming cloud OCR success. Existing Blueprint recognition/scanner logic remains separate.',
    ),
    UagReleaseReadinessCheck(
      id: 'stripe_products',
      label: 'Stripe web billing',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Stripe',
      detail:
          'Stripe Checkout, Customer Portal, webhook secrets and plan bindings already exist in the web/function pipeline. Verify the deployed test/live secret and price bindings before accepting web payments.',
    ),
    UagReleaseReadinessCheck(
      id: 'google_play_billing',
      label: 'Google Play Billing',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Google Play Console',
      detail:
          'The Play Console app is now created and verified. Android remains Google Play Billing for paid digital access; create the subscription product IDs/base plans and wire provider-confirmed server verification before accepting Android payments.',
    ),
    UagReleaseReadinessCheck(
      id: 'device_push_qa',
      label: 'Real-device push QA',
      state: UagReleaseReadinessState.manualQaRequired,
      owner: 'Mike',
      detail:
          'Verify foreground, background, terminated, notification-tap and deep-link flows on the Sony. Web push QA is deferred until the web beta is ready.',
    ),
    UagReleaseReadinessCheck(
      id: 'legal_operator',
      label: 'Operator and legal details',
      state: UagReleaseReadinessState.ready,
      owner: 'MobCorp Limited',
      detail:
          'MobCorp Limited / Michael Marsh / contact@mobcorp.co.uk and the registered service address are configured. Public Terms, Privacy, Subscriptions & Refunds and Support URLs are defined for Firebase Hosting.',
    ),
    UagReleaseReadinessCheck(
      id: 'legal_self_audit',
      label: 'UK legal/compliance self-audit',
      state: UagReleaseReadinessState.ready,
      owner: 'MobCorp Limited',
      detail:
          'Operational policies have been self-audited against current UK government, ICO and Google Play guidance for beta readiness. This is an internal compliance control, not formal legal advice or solicitor sign-off.',
    ),
    UagReleaseReadinessCheck(
      id: 'account_deletion',
      label: 'Account deletion',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'UAG / Google Play',
      detail:
          'The public support page now provides an external deletion-request route. Google Play also requires an in-app account-deletion path for apps that create accounts; verify or implement that path and associated-data deletion before Play release.',
    ),
    UagReleaseReadinessCheck(
      id: 'legal_review',
      label: 'Independent UK legal review',
      state: UagReleaseReadinessState.deferred,
      owner: 'MobCorp Limited',
      detail:
          'Independent professional legal review is planned once UAG begins generating revenue or before material commercial/international scale. It is advisory for risk reduction and does not block internal or closed-beta testing.',
    ),
  ];
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
