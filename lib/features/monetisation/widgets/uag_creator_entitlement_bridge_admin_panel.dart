import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_text_sanitizer.dart';

import '../models/uag_creator_reward_models.dart';
import '../repositories/uag_creator_entitlement_bridge_repository.dart';

class UagCreatorEntitlementBridgeAdminPanel extends StatefulWidget {
  const UagCreatorEntitlementBridgeAdminPanel({super.key});

  @override
  State<UagCreatorEntitlementBridgeAdminPanel> createState() =>
      _UagCreatorEntitlementBridgeAdminPanelState();
}

class _UagCreatorEntitlementBridgeAdminPanelState
    extends State<UagCreatorEntitlementBridgeAdminPanel> {
  final _repository = UagCreatorEntitlementBridgeRepository();
  final _recipientController = TextEditingController();
  bool _busy = false;
  String _message = '';

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _grant(DocumentReference<Map<String, dynamic>> claimRef) async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final result = await _repository.grantValidatedReward(claimRef);
      if (!mounted) return;
      setState(() {
        _recipientController.text = result.recipientUid;
        final date = result.expiresAt.toLocal().toString().split('.').first;
        _message = result.alreadyGranted
            ? 'Reward was already granted. Existing entitlement retained until $date.'
            : '${result.tier.publicName} reward granted until $date.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not update entitlement bridge. Try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: .28),
        ),
        color: Colors.black.withValues(alpha: .16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Temporary Entitlement Bridge',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Validated Community Arsenal rewards become temporary Essential or Premium access here. Grants are additive, idempotent and expire automatically back to the underlying commercial tier.',
          ),
          const SizedBox(height: 14),
          _pendingClaims(),
          const Divider(height: 28),
          _recipientInspector(),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_message),
          ],
        ],
      ),
    );
  }

  Widget _pendingClaims() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.watchValidatedRewardClaims(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final pending = docs
            .where(
              (doc) =>
                  doc.data()['recordType'] == 'creator_giveaway_redemption' &&
                  doc.data()['status'] == 'validated_entitlement_pending',
            )
            .take(30)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VALIDATED REWARDS AWAITING ACCESS',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const Text('No validated creator rewards awaiting entitlement.'),
            for (final doc in pending) _claimRow(doc),
          ],
        );
      },
    );
  }

  Widget _claimRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = data['recipientUid']?.toString().trim().isNotEmpty == true
        ? data['recipientUid'].toString()
        : doc.reference.parent.parent?.id ?? '';
    final reward = UagCreatorRewardType.fromValue(
      data['rewardType']?.toString(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ArcTextSanitizer.metadataLine([
                data['code']?.toString(),
                reward?.label ?? 'Reward',
                'user $uid',
              ]),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => _grant(doc.reference),
            child: const Text('GRANT ACCESS'),
          ),
        ],
      ),
    );
  }

  Widget _recipientInspector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECIPIENT ENTITLEMENT INSPECTOR',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient UID',
                  hintText: 'Paste a user UID',
                ),
                onSubmitted: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text('INSPECT'),
            ),
          ],
        ),
        if (_recipientController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _repository.watchRecipient(
              _recipientController.text.trim(),
            ),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              if (data == null) {
                return const Text('Recipient record not loaded.');
              }
              final grants = data['creatorRewardEntitlements'];
              if (grants is! Map || grants.isEmpty) {
                return const Text(
                  'No creator reward entitlements recorded for this user.',
                );
              }
              final rows = grants.entries
                  .map((entry) {
                    final raw = entry.value;
                    final map = raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : const <String, dynamic>{};
                    final expiry = map['expiresAt'];
                    final expiryDate = expiry is Timestamp
                        ? expiry.toDate().toLocal()
                        : null;
                    final state =
                        expiryDate != null && expiryDate.isAfter(DateTime.now())
                        ? 'ACTIVE'
                        : 'EXPIRED';
                    final expiryText =
                        expiryDate?.toString().split('.').first ??
                        'unknown expiry';
                    return ArcTextSanitizer.metadataLine([
                      entry.key,
                      map['tier']?.toString(),
                      state,
                      expiryText,
                    ]);
                  })
                  .toList(growable: false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final row in rows) Text(row)],
              );
            },
          ),
        ],
      ],
    );
  }
}
