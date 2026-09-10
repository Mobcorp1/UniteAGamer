import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_beta_founder_pricing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_wall_of_legends_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagBetaFounderAdminPanel extends StatefulWidget {
  const UagBetaFounderAdminPanel({super.key});

  @override
  State<UagBetaFounderAdminPanel> createState() =>
      _UagBetaFounderAdminPanelState();
}

class _UagBetaFounderAdminPanelState extends State<UagBetaFounderAdminPanel> {
  final _firestore = FirebaseFirestore.instance;
  final _wallRepository = ArcWallOfLegendsRepository();
  final _searchController = TextEditingController();
  final _legendNameController = TextEditingController();
  final _legendTitleController = TextEditingController();
  final _legendBadgeController = TextEditingController();
  final _legendReasonController = TextEditingController();

  _CommercialAdminTarget? _target;
  ArcWallOfLegendsCategory _legendCategory =
      ArcWallOfLegendsCategory.closedBetaRaiders;
  bool _busy = false;
  String _message = '';
  bool _messageIsError = false;

  @override
  void dispose() {
    _searchController.dispose();
    _legendNameController.dispose();
    _legendTitleController.dispose();
    _legendBadgeController.dispose();
    _legendReasonController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _busy) return;
    _setBusy(true);
    try {
      final target = await _findTarget(query);
      if (!mounted) return;
      if (target == null) {
        setState(() {
          _target = null;
          _message = 'No UAG account matched that UID, UAG ID, email or name.';
          _messageIsError = true;
        });
        return;
      }
      _applyTarget(target);
      setState(() {
        _target = target;
        _message =
            'Account loaded. Commercial recognition is admin-controlled.';
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Could not load that account. Check the identifier and retry.';
        _messageIsError = true;
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<_CommercialAdminTarget?> _findTarget(String rawQuery) async {
    final query = rawQuery.trim();
    final direct = await _firestore.collection('users').doc(query).get();
    if (direct.exists) return _loadTarget(direct.id);

    final uagQuery = query.toUpperCase();
    final lookups = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      _firestore
          .collection('public_profiles')
          .where('uagId', isEqualTo: uagQuery)
          .limit(1)
          .get(),
      _firestore
          .collection('users')
          .where('uagId', isEqualTo: uagQuery)
          .limit(1)
          .get(),
      _firestore
          .collection('users')
          .where('basicProfile.email', isEqualTo: query.toLowerCase())
          .limit(1)
          .get(),
      _firestore
          .collection('users')
          .where('basicProfile.displayName', isEqualTo: query)
          .limit(1)
          .get(),
      _firestore
          .collection('public_profiles')
          .where('displayName', isEqualTo: query)
          .limit(1)
          .get(),
      _firestore
          .collection('public_profiles')
          .where('uagName', isEqualTo: query)
          .limit(1)
          .get(),
    ];

    for (final lookup in lookups) {
      final snapshot = await lookup;
      if (snapshot.docs.isNotEmpty) {
        return _loadTarget(snapshot.docs.first.id);
      }
    }
    return null;
  }

  Future<_CommercialAdminTarget> _loadTarget(String uid) async {
    final results = await Future.wait<dynamic>([
      _firestore.collection('users').doc(uid).get(),
      _firestore.collection('public_profiles').doc(uid).get(),
      _firestore.collection('uag_commercial_recognition').doc(uid).get(),
      _wallRepository.getEntry(uid),
    ]);
    final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final publicSnapshot = results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final recognitionSnapshot =
        results[2] as DocumentSnapshot<Map<String, dynamic>>;
    final legend = results[3] as ArcWallOfLegendsEntry?;
    final user = userSnapshot.data() ?? const <String, dynamic>{};
    final public = publicSnapshot.data() ?? const <String, dynamic>{};
    final recognition = recognitionSnapshot.data() ?? const <String, dynamic>{};

    return _CommercialAdminTarget(
      uid: uid,
      displayName: _firstText([
        public['displayName'],
        public['uagName'],
        _nested(user, 'basicProfile', 'displayName'),
        _nested(user, 'traderProfile', 'uagName'),
        user['displayName'],
      ], fallback: uid),
      uagId: _firstText([
        public['uagId'],
        _nested(user, 'traderProfile', 'uagId'),
        user['uagId'],
      ]),
      email: _firstText([
        _nested(user, 'basicProfile', 'email'),
        user['email'],
      ]),
      recognition: UagBetaFounderStatus.fromRecognitionDoc(recognition),
      legend: legend,
    );
  }

  void _applyTarget(_CommercialAdminTarget target) {
    final legend = target.legend;
    _legendNameController.text = legend?.displayName ?? target.displayName;
    _legendTitleController.text = legend?.title ?? '';
    _legendBadgeController.text =
        legend?.badgeLabel ??
        (target.recognition.isFoundingRaider
            ? 'FOUNDING RAIDER'
            : 'BETA RAIDER');
    _legendReasonController.text = legend?.reason ?? '';
    _legendCategory =
        legend?.category ??
        (target.recognition.isFoundingRaider
            ? ArcWallOfLegendsCategory.founders
            : ArcWallOfLegendsCategory.closedBetaRaiders);
  }

  Future<void> _setBetaTester(bool enabled) async {
    final target = _target;
    if (target == null || _busy) return;
    await _writeRecognition(
      recognitionPatch: <String, dynamic>{
        'betaTester': enabled,
        'closedBetaParticipant': enabled,
        'beta': <String, dynamic>{
          'participant': enabled,
          'pricingEligible': enabled,
          if (enabled) 'pricingGrantedAt': FieldValue.serverTimestamp(),
        },
        if (enabled) 'betaPricingGrantedAt': FieldValue.serverTimestamp(),
      },
      userPatch: <String, dynamic>{
        'closedBetaParticipant': enabled,
        'betaParticipant': enabled,
        'beta': <String, dynamic>{
          'participant': enabled,
          'pricingEligible': enabled,
          if (enabled) 'pricingGrantedAt': FieldValue.serverTimestamp(),
        },
        if (enabled) 'betaPricingGrantedAt': FieldValue.serverTimestamp(),
      },
      success: enabled
          ? 'Closed Beta pricing granted.'
          : 'Closed Beta pricing removed.',
    );
  }

  Future<void> _setFoundingRaider(bool enabled) async {
    final target = _target;
    if (target == null || _busy) return;
    await _writeRecognition(
      recognitionPatch: <String, dynamic>{
        'foundingRaider': enabled,
        'founder': enabled,
        'founderStatus': <String, dynamic>{
          'active': enabled,
          if (enabled) 'grantedAt': FieldValue.serverTimestamp(),
        },
        if (enabled) 'founderGrantedAt': FieldValue.serverTimestamp(),
      },
      userPatch: <String, dynamic>{
        'foundingRaider': enabled,
        'founder': enabled,
        'founderEligible': enabled,
        'founderStatus': <String, dynamic>{
          'active': enabled,
          if (enabled) 'grantedAt': FieldValue.serverTimestamp(),
        },
        if (enabled) 'founderGrantedAt': FieldValue.serverTimestamp(),
      },
      success: enabled
          ? 'Founding Raider status granted. £29.99 annual rate is available unless previously forfeited.'
          : 'Founding Raider commercial status removed.',
    );
  }

  Future<void> _setWallEligible(bool enabled) async {
    final target = _target;
    if (target == null || _busy) return;
    await _writeRecognition(
      recognitionPatch: <String, dynamic>{
        'wallOfLegendsEligible': enabled,
        'founderStatus': <String, dynamic>{'wallOfLegendsEligible': enabled},
      },
      userPatch: <String, dynamic>{
        'wallOfLegendsEligible': enabled,
        'founderStatus': <String, dynamic>{'wallOfLegendsEligible': enabled},
      },
      success: enabled
          ? 'Wall of Legends eligibility granted.'
          : 'Wall of Legends eligibility removed.',
    );
  }

  Future<void> _restoreFounderRate() async {
    final target = _target;
    if (target == null || _busy) return;
    await _writeRecognition(
      recognitionPatch: <String, dynamic>{
        'founderRateForfeited': false,
        'founderStatus': <String, dynamic>{'rateForfeited': false},
        'founderRateRestoredAt': FieldValue.serverTimestamp(),
      },
      userPatch: <String, dynamic>{
        'founderRateForfeited': false,
        'founderStatus': <String, dynamic>{'rateForfeited': false},
        'monetisation': <String, dynamic>{'founderRateForfeited': false},
        'founderRateRestoredAt': FieldValue.serverTimestamp(),
      },
      success: '£29.99 Founding Raider annual rate restored by admin.',
    );
  }

  Future<void> _writeRecognition({
    required Map<String, dynamic> recognitionPatch,
    required Map<String, dynamic> userPatch,
    required String success,
  }) async {
    final target = _target;
    if (target == null) return;
    _setBusy(true);
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('uag_commercial_recognition').doc(target.uid),
        <String, dynamic>{
          ...recognitionPatch,
          'uid': target.uid,
          'updatedByUid': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('users').doc(target.uid),
        <String, dynamic>{
          ...userPatch,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      final refreshed = await _loadTarget(target.uid);
      if (!mounted) return;
      _applyTarget(refreshed);
      setState(() {
        _target = refreshed;
        _message = success;
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Commercial recognition update failed. No price entitlement was changed.';
        _messageIsError = true;
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _inductLegend() async {
    final target = _target;
    if (target == null || _busy) return;
    final displayName = _legendNameController.text.trim();
    final reason = _legendReasonController.text.trim();
    if (displayName.isEmpty || reason.isEmpty) {
      setState(() {
        _message =
            'Wall of Legends requires a display name and induction reason.';
        _messageIsError = true;
      });
      return;
    }

    _setBusy(true);
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final existing = target.legend;
      await _wallRepository.upsertEntry(
        ArcWallOfLegendsEntry(
          id: target.uid,
          category: _legendCategory,
          displayName: displayName,
          profileUid: target.uid,
          uagId: target.uagId,
          title: _legendTitleController.text.trim(),
          badgeLabel: _legendBadgeController.text.trim(),
          reason: reason,
          seasonId: existing?.seasonId ?? '',
          publicSocialLinks:
              existing?.publicSocialLinks ?? const <ArcProfileSocialLink>[],
          approved: true,
          sortOrder: existing?.sortOrder ?? 0,
          createdAt: existing?.createdAt,
          updatedAt: DateTime.now(),
        ),
        inductedByUid: adminUid,
      );
      await _writeWallRecognition(target.uid, inducted: true, eligible: true);
      final refreshed = await _loadTarget(target.uid);
      if (!mounted) return;
      _applyTarget(refreshed);
      setState(() {
        _target = refreshed;
        _message = 'Immortalised on the UAG Wall of Legends.';
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Wall of Legends induction failed. No entry was published.';
        _messageIsError = true;
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _removeLegend() async {
    final target = _target;
    if (target == null || target.legend == null || _busy) return;
    _setBusy(true);
    try {
      await _wallRepository.deleteEntry(target.uid);
      await _writeWallRecognition(target.uid, inducted: false, eligible: true);
      final refreshed = await _loadTarget(target.uid);
      if (!mounted) return;
      _applyTarget(refreshed);
      setState(() {
        _target = refreshed;
        _message =
            'Wall of Legends entry removed. Eligibility remains available.';
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not remove the Wall of Legends entry.';
        _messageIsError = true;
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _writeWallRecognition(
    String uid, {
    required bool inducted,
    required bool eligible,
  }) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('uag_commercial_recognition').doc(uid),
      <String, dynamic>{
        'uid': uid,
        'wallOfLegendsEligible': eligible,
        'wallOfLegendsInducted': inducted,
        'founderStatus': <String, dynamic>{
          'wallOfLegendsEligible': eligible,
          'wallOfLegendsInducted': inducted,
        },
        'updatedByUid': adminUid,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(_firestore.collection('users').doc(uid), <String, dynamic>{
      'wallOfLegendsEligible': eligible,
      'wallOfLegendsInducted': inducted,
      'founderStatus': <String, dynamic>{
        'wallOfLegendsEligible': eligible,
        'wallOfLegendsInducted': inducted,
      },
      'updatedAt': now,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  void _setBusy(bool value) {
    if (!mounted) return;
    setState(() => _busy = value);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return ArcTacticalPanel(
      icon: Icons.military_tech_rounded,
      title: 'BETA // FOUNDERS // WALL OF LEGENDS',
      subtitle:
          'Grant protected Beta pricing, Founding Raider rates and permanent UAG network recognition.',
      accent: ArcUiTokens.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  enabled: !_busy,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: 'UID, UAG ID, email or exact display name',
                    prefixIcon: Icon(Icons.manage_search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: ArcUiTokens.gapM),
              FilledButton.icon(
                onPressed: _busy ? null : _search,
                icon: const Icon(Icons.search_rounded),
                label: const Text('LOAD RAIDER'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: ArcUiTokens.gapM),
            const LinearProgressIndicator(),
          ],
          if (_message.isNotEmpty) ...[
            const SizedBox(height: ArcUiTokens.gapM),
            _statusMessage(_message, error: _messageIsError),
          ],
          if (target != null) ...[
            const SizedBox(height: ArcUiTokens.gapL),
            _identityCard(target),
            const SizedBox(height: ArcUiTokens.gapM),
            _recognitionControls(target),
            const SizedBox(height: ArcUiTokens.gapM),
            _legendEditor(target),
          ],
        ],
      ),
    );
  }

  Widget _identityCard(_CommercialAdminTarget target) {
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.26,
      ),
      child: Wrap(
        spacing: ArcUiTokens.gapL,
        runSpacing: ArcUiTokens.gapS,
        children: [
          _metric('RAIDER', target.displayName),
          _metric(
            'UAG ID',
            target.uagId.isEmpty ? 'Not assigned' : target.uagId,
          ),
          _metric('EMAIL', target.email.isEmpty ? 'Not stored' : target.email),
          _metric('UID', target.uid),
        ],
      ),
    );
  }

  Widget _recognitionControls(_CommercialAdminTarget target) {
    final recognition = target.recognition;
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.base,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMERCIAL RECOGNITION',
            style: ArcUiTokens.cardTitle(color: ArcUiTokens.secondaryAccent),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            'Checkout verifies these grants against the admin-only recognition collection. Profile mirrors are display-only and cannot authorise a discounted payment.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: recognition.isBetaTester,
            onChanged: _busy ? null : _setBetaTester,
            title: const Text('Closed Beta Tester'),
            subtitle: const Text(
              'Unlocks £6.99 monthly, £49.99 annual and Beta pass pricing.',
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: recognition.isFoundingRaider,
            onChanged: _busy ? null : _setFoundingRaider,
            title: const Text('Founding Raider'),
            subtitle: const Text(
              'Unlocks £29.99/year Premium while the Founder subscription remains continuous.',
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: recognition.wallOfLegendsEligible,
            onChanged: _busy ? null : _setWallEligible,
            title: const Text('Wall of Legends Eligible'),
            subtitle: const Text(
              'Marks this Raider as eligible for permanent UAG network recognition.',
            ),
          ),
          if (recognition.founderRateForfeited) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            OutlinedButton.icon(
              onPressed: _busy ? null : _restoreFounderRate,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('RESTORE £29.99 FOUNDER RATE'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendEditor(_CommercialAdminTarget target) {
    final hasEntry = target.legend != null;
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.warning,
        borderOpacity: 0.26,
        glow: hasEntry,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: ArcUiTokens.warning),
              const SizedBox(width: ArcUiTokens.gapS),
              Expanded(
                child: Text(
                  hasEntry
                      ? 'WALL OF LEGENDS // INDUCTED'
                      : 'WALL OF LEGENDS // INDUCTION',
                  style: ArcUiTokens.cardTitle(color: ArcUiTokens.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Wrap(
            spacing: ArcUiTokens.gapM,
            runSpacing: ArcUiTokens.gapM,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _legendNameController,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
              ),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<ArcWallOfLegendsCategory>(
                  initialValue: _legendCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ArcWallOfLegendsCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _legendCategory = value);
                          }
                        },
                ),
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _legendTitleController,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Legend title (optional)',
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _legendBadgeController,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Badge label (optional)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          TextField(
            controller: _legendReasonController,
            enabled: !_busy,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Why they are being immortalised',
              hintText:
                  'Permanent contribution citation shown on the Wall of Legends.',
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Wrap(
            spacing: ArcUiTokens.gapM,
            runSpacing: ArcUiTokens.gapS,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _inductLegend,
                icon: const Icon(Icons.military_tech_rounded),
                label: Text(hasEntry ? 'UPDATE LEGEND' : 'IMMORTALISE RAIDER'),
              ),
              if (hasEntry)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _removeLegend,
                  icon: const Icon(Icons.person_remove_alt_1_rounded),
                  label: const Text('REMOVE WALL ENTRY'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 430),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: ArcUiTokens.body(
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage(String message, {required bool error}) {
    final accent = error ? ArcUiTokens.danger : ArcUiTokens.success;
    return Container(
      width: double.infinity,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.base,
        accent: accent,
        borderOpacity: 0.28,
      ),
      child: Text(message, style: ArcUiTokens.bodySmall(color: accent)),
    );
  }

  static dynamic _nested(
    Map<String, dynamic> source,
    String parent,
    String child,
  ) {
    final nested = source[parent];
    if (nested is Map<String, dynamic>) return nested[child];
    if (nested is Map) return nested[child];
    return null;
  }

  static String _firstText(Iterable<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}

class _CommercialAdminTarget {
  const _CommercialAdminTarget({
    required this.uid,
    required this.displayName,
    required this.uagId,
    required this.email,
    required this.recognition,
    required this.legend,
  });

  final String uid;
  final String displayName;
  final String uagId;
  final String email;
  final UagBetaFounderStatus recognition;
  final ArcWallOfLegendsEntry? legend;
}
