enum UagModerationState {
  allowed,
  warned,
  quarantined,
  blocked,
  escalated,
  underReview,
  restored,
  actioned,
  appealed,
  overturned,
}

extension UagModerationStateX on UagModerationState {
  static UagModerationState fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagModerationState.values.firstWhere(
      (state) => state.name == normalized,
      orElse: () => UagModerationState.underReview,
    );
  }
}

enum UagModerationAction {
  deliver,
  warnAndAllowEdit,
  quarantine,
  blockAndEscalate,
  humanReview,
}

class UagUserBlock {
  const UagUserBlock({
    required this.id,
    required this.blockerUid,
    required this.blockedUid,
    this.reason = '',
    this.createdAtIso = '',
  });

  final String id;
  final String blockerUid;
  final String blockedUid;
  final String reason;
  final String createdAtIso;

  static String idFor(String blockerUid, String blockedUid) {
    return '${_cleanId(blockerUid)}_${_cleanId(blockedUid)}';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'blockerUid': blockerUid,
      'blockedUid': blockedUid,
      'reason': reason,
      'createdAtIso': createdAtIso,
    };
  }
}

class UagMessageOutboxRequest {
  const UagMessageOutboxRequest({
    required this.id,
    required this.senderUid,
    required this.recipientUid,
    required this.body,
    this.conversationId = '',
    this.contextType = 'direct_message',
    this.contextId = '',
    this.clientRequestId = '',
  });

  final String id;
  final String senderUid;
  final String recipientUid;
  final String body;
  final String conversationId;
  final String contextType;
  final String contextId;
  final String clientRequestId;

  Map<String, dynamic> toCreateMap() {
    return <String, dynamic>{
      'id': id,
      'senderUid': senderUid,
      'recipientUid': recipientUid,
      'body': body,
      'conversationId': conversationId,
      'contextType': contextType,
      'contextId': contextId,
      'clientRequestId': clientRequestId,
      'status': 'queued',
    };
  }
}

class UagModerationDecision {
  const UagModerationDecision({
    required this.state,
    required this.action,
    required this.score,
    required this.triggeredRules,
    required this.reason,
    this.providerConfigured = false,
  });

  final UagModerationState state;
  final UagModerationAction action;
  final double score;
  final List<String> triggeredRules;
  final String reason;
  final bool providerConfigured;

  bool get canDeliver => action == UagModerationAction.deliver;
  bool get needsQueue =>
      action == UagModerationAction.quarantine ||
      action == UagModerationAction.blockAndEscalate ||
      action == UagModerationAction.humanReview;
}

class UagMessageModerationEngine {
  const UagMessageModerationEngine({
    this.blockedDomains = const <String>[
      'bit.ly',
      'tinyurl.com',
      't.me',
      'discord.gg',
    ],
  });

  final List<String> blockedDomains;

  UagModerationDecision classify(String body) {
    final normalized = body.trim().toLowerCase();
    final rules = <String>[];
    var score = 0.0;

    void add(String rule, double value) {
      if (!rules.contains(rule)) rules.add(rule);
      score += value;
    }

    if (normalized.isEmpty) {
      add('empty_message', 0.45);
    }
    if (RegExp(
      r'\b(kill yourself|kys|i will kill|death threat)\b',
    ).hasMatch(normalized)) {
      add('threat_or_self_harm_abuse', 0.95);
    }
    if (RegExp(
      r'\b(child|minor|underage)\b.*\b(sex|nude|meet)\b',
    ).hasMatch(normalized)) {
      add('sexual_or_grooming_risk', 1.0);
    }
    if (RegExp(
      r'\b(password|2fa|verification code|login code)\b',
    ).hasMatch(normalized)) {
      add('credential_phishing', 0.65);
    }
    if (RegExp(
      r'\b(paypal|bank transfer|crypto|wallet address|cashapp)\b',
    ).hasMatch(normalized)) {
      add('off_platform_payment_request', 0.3);
    }
    if (RegExp(r'\b\d{3,}[- .]?\d{3,}[- .]?\d{3,}\b').hasMatch(normalized)) {
      add('phone_or_private_number', 0.25);
    }
    if (RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}').hasMatch(normalized)) {
      add('email_address', 0.25);
    }
    if (RegExp(r'https?://|www\.').hasMatch(normalized)) {
      add('external_url', 0.15);
    }
    for (final domain in blockedDomains) {
      if (domain.trim().isNotEmpty && normalized.contains(domain)) {
        add('blocked_domain:$domain', 0.35);
      }
    }
    if (_repeatScore(normalized) >= 5) {
      add('spam_repetition', 0.35);
    }

    final severe = rules.any(
      (rule) =>
          rule == 'threat_or_self_harm_abuse' ||
          rule == 'sexual_or_grooming_risk',
    );
    if (severe && score >= 0.95) {
      return UagModerationDecision(
        state: UagModerationState.blocked,
        action: UagModerationAction.blockAndEscalate,
        score: score.clamp(0, 1).toDouble(),
        triggeredRules: rules,
        reason: 'Severe automated safety rule triggered.',
      );
    }
    if (score >= 0.7) {
      return UagModerationDecision(
        state: UagModerationState.quarantined,
        action: UagModerationAction.quarantine,
        score: score.clamp(0, 1).toDouble(),
        triggeredRules: rules,
        reason: 'Message withheld for moderation review.',
      );
    }
    if (score >= 0.35) {
      return UagModerationDecision(
        state: UagModerationState.warned,
        action: UagModerationAction.warnAndAllowEdit,
        score: score.clamp(0, 1).toDouble(),
        triggeredRules: rules,
        reason: 'Message should be edited or confirmed before delivery.',
      );
    }
    return UagModerationDecision(
      state: UagModerationState.allowed,
      action: UagModerationAction.deliver,
      score: score.clamp(0, 1).toDouble(),
      triggeredRules: rules,
      reason: 'No blocking safety rule triggered.',
    );
  }

  int _repeatScore(String normalized) {
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 0;
    final counts = <String, int>{};
    for (final word in words) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
    return counts.values.fold<int>(
      0,
      (best, value) => value > best ? value : best,
    );
  }
}

String _cleanId(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
