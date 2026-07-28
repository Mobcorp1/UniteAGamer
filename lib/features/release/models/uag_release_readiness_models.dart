enum UagReleaseReadinessState {
  ready,
  configurationRequired,
  manualQaRequired,
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
      label: 'Java 21 emulator runtime',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Mike',
      detail:
          'Install a Java 21 JDK and set JAVA_HOME/PATH for Firebase emulator tests.',
    ),
    UagReleaseReadinessCheck(
      id: 'moderation_provider',
      label: 'External moderation provider',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Firebase/Google Cloud',
      detail:
          'Set UAG_MODERATION_PROVIDER_ENABLED and Google Cloud Natural Language access.',
    ),
    UagReleaseReadinessCheck(
      id: 'ocr_provider',
      label: 'OCR provider',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Firebase/Google Cloud',
      detail:
          'Local matching is gated; Cloud Vision or ML Kit OCR must be configured before claiming OCR success.',
    ),
    UagReleaseReadinessCheck(
      id: 'stripe_products',
      label: 'Stripe products and webhooks',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Stripe',
      detail:
          'Configure Essential, Premium and Founding Supporter price IDs plus webhook secret.',
    ),
    UagReleaseReadinessCheck(
      id: 'google_play_billing',
      label: 'Google Play Billing',
      state: UagReleaseReadinessState.configurationRequired,
      owner: 'Google Play Console',
      detail:
          'Create subscription products and connect server verification before Play distribution.',
    ),
    UagReleaseReadinessCheck(
      id: 'device_push_qa',
      label: 'Real-device push QA',
      state: UagReleaseReadinessState.manualQaRequired,
      owner: 'Mike',
      detail:
          'Verify foreground, background and terminated notification flows on physical devices.',
    ),
    UagReleaseReadinessCheck(
      id: 'legal_operator',
      label: 'Operator and legal details',
      state: UagReleaseReadinessState.blocked,
      owner: 'Mike/legal',
      detail:
          'Production legal identity, support contacts and policy review are still required.',
    ),
  ];
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
